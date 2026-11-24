import assert from 'node:assert/strict';
import { once } from 'node:events';
import { readFileSync } from 'node:fs';
import { createConnection } from 'node:net';
import { basename, normalize } from 'node:path';
import { fileURLToPath } from 'node:url';

async function* readMessages(socket) {
    let buffer = Buffer.alloc(0);
    for await (const chunk of socket) {
        buffer = Buffer.concat([buffer, chunk]);
        let headerEnd;
        while ((headerEnd = buffer.indexOf('\r\n\r\n')) !== -1) {
            const header = buffer.subarray(0, headerEnd).toString('ascii');
            const length = Number(/^Content-Length:[ \t]*(\d+)[ \t]*$/im.exec(header)?.[1]);
            assert.ok(length > 0 && length <= 16 * 1024 * 1024, 'Invalid DAP Content-Length');
            const bodyStart = headerEnd + 4;
            const bodyEnd = bodyStart + length;
            if (buffer.length < bodyEnd) break;
            const message = JSON.parse(buffer.subarray(bodyStart, bodyEnd).toString('utf8'));
            buffer = buffer.subarray(bodyEnd);
            yield message;
        }
    }
}

class DapClient {
    constructor(socket) {
        this.socket = socket;
        this.messages = readMessages(socket);
        this.events = [];
        this.seq = 0;
    }

    async receive() {
        const next = await this.messages.next();
        assert.ok(!next.done, 'DAP connection closed before the expected message');
        return next.value;
    }

    async request(command, args) {
        const seq = ++this.seq;
        const body = Buffer.from(JSON.stringify({ seq, type: 'request', command, arguments: args }));
        this.socket.write(Buffer.concat([Buffer.from(`Content-Length: ${body.length}\r\n\r\n`), body]));
        for (;;) {
            const message = await this.receive();
            if (message.type === 'response') {
                assert.equal(message.request_seq, seq, 'DAP response request sequence');
                assert.equal(message.command, command);
                assert.ok(message.success, `${command} failed: ${message.message ?? 'unknown error'}`);
                return message.body;
            }
            this.events.push(message);
        }
    }

    async event(name) {
        const index = this.events.findIndex(message => message.event === name);
        if (index !== -1) return this.events.splice(index, 1)[0].body;
        for (;;) {
            const message = await this.receive();
            if (message.event === name) return message.body;
            this.events.push(message);
        }
    }
}

function script(name) {
    const path = fileURLToPath(new URL(`scripts/${name}`, import.meta.url));
    return { path, lines: readFileSync(path, 'utf8').split(/\r?\n/) };
}

function bpLine(source, statement) {
    const index = source.lines.findIndex(line => line.trim() === `${statement} // BP`);
    assert.notEqual(index, -1, `Breakpoint marker for ${statement}`);
    return index + 1;
}

function findVariable(variables, name) {
    const variable = variables.find(item => item.name === name);
    assert.ok(variable, `Missing variable "${name}" in ${variables.map(item => item.name).join(', ')}`);
    return variable;
}

async function variables(client, container) {
    assert.ok(container.variablesReference > 0, `${container.name} must be expandable`);
    return (await client.request('variables', { variablesReference: container.variablesReference })).variables;
}

async function locals(client, frame) {
    const { scopes } = await client.request('scopes', { frameId: frame.id });
    const scope = scopes.find(item => item.presentationHint === 'locals');
    assert.ok(scope, 'Missing Locals scope');
    return variables(client, scope);
}

async function setBreakpoints(client, source, lines) {
    const { breakpoints } = await client.request('setBreakpoints', {
        source: { name: basename(source.path), path: source.path },
        lines,
        breakpoints: lines.map(line => ({ line })),
        sourceModified: false,
    });
    assert.deepEqual(breakpoints.map(({ line, verified }) => ({ line, verified })),
        lines.map(line => ({ line, verified: true })));
}

async function stackAt(client, reason, source, line) {
    const stop = await client.event('stopped');
    assert.equal(stop.reason, reason);
    assert.ok(stop.threadId > 0, 'Missing stopped thread ID');
    const { stackFrames } = await client.request('stackTrace', { threadId: stop.threadId });
    // Native add-ons can report exceptions above the first script frame.
    const frame = reason === 'exception' ? stackFrames.find(item => item.source?.path) : stackFrames[0];
    assert.ok(frame?.source?.path, 'Missing script frame source path');
    assert.equal(normalize(frame.source.path), normalize(source.path));
    assert.equal(frame.line, line, 'Script frame line');
    return { threadId: stop.threadId, frame, frames: stackFrames };
}

async function run(client, port, sessionRequest, step) {
    const basic = script('basic.as');
    const advanced = script('advanced.as');
    const bonus = bpLine(basic, 'total = addBonus(total, hasBonus ? 2 : 0);');
    const format = bpLine(basic, 'string message = formatProgress(total);');
    const prefix = bpLine(basic, 'string prefix = "Total: ";');
    const callback = bpLine(advanced, 'int result = callback(3);');
    const exception = bpLine(advanced, 'print("Score: " + scores[invalidIndex]);');

    await step('initialize and receive initialized', async () => {
        const capabilities = await client.request('initialize', {
            clientID: 'vscode', adapterID: 'angelscript', pathFormat: 'path',
            linesStartAt1: true, columnsStartAt1: true,
        });
        assert.equal(capabilities.supportsConfigurationDoneRequest, true);
        assert.equal(capabilities.supportsExceptionInfoRequest, true);
        assert.ok(capabilities.exceptionBreakpointFilters.some(filter => filter.filter === 'all'));
        await client.event('initialized');
    });

    await step(`${sessionRequest} over DAP`, async () => {
        const config = { type: 'angelscript', request: sessionRequest, protocol: 'dap', host: '127.0.0.1', port };
        if (sessionRequest === 'launch') {
            Object.assign(config, {
                executable: fileURLToPath(new URL('build/bin/Release/angelscript-demo.exe', import.meta.url)),
                args: ['--wait', '--port', String(port)],
                cwd: fileURLToPath(new URL('.', import.meta.url)),
            });
        }
        await client.request(sessionRequest, config);
    });

    await step('verify the basic and advanced breakpoints', async () => {
        await setBreakpoints(client, basic, [bonus]);
        await setBreakpoints(client, advanced, [callback]);
    });
    await step('enable exception stops and finish configuration', async () => {
        await client.request('setExceptionBreakpoints', { filters: ['all'] });
        assert.ok(!client.events.some(message => message.event === 'stopped'), 'Stopped before configurationDone');
        await client.request('configurationDone', {});
    });

    const basicStop = await step('stop in basic.as and verify its top frame', async () => {
        const stopped = await stackAt(client, 'breakpoint', basic, bonus);
        assert.match(stopped.frames[0].name, /\bshowProgress\(/);
        assert.match(stopped.frames[1]?.name ?? '', /\bmain\(/);
        return stopped;
    });
    await step('read basic locals (total = 7)', async () => {
        const values = await locals(client, basicStop.frames[0]);
        assert.equal(findVariable(values, 'total').value, '7');
        assert.equal(findVariable(values, 'hasBonus').value, 'true');
    });
    await step('step over addBonus (total = 9)', async () => {
        await client.request('next', { threadId: basicStop.threadId });
        const stopped = await stackAt(client, 'step', basic, format);
        assert.equal(findVariable(await locals(client, stopped.frames[0]), 'total').value, '9');
    });
    await step('step into formatProgress', async () => {
        await client.request('stepIn', { threadId: basicStop.threadId });
        const stopped = await stackAt(client, 'step', basic, prefix);
        assert.match(stopped.frames[0].name, /\bformatProgress\(/);
        assert.match(stopped.frames[1]?.name ?? '', /\bshowProgress\(/);
        await setBreakpoints(client, basic, []);
    });
    await step('step over the string initializer (prefix = "Total: ")', async () => {
        await client.request('next', { threadId: basicStop.threadId });
        const { frame } = await stackAt(client, 'step', basic, prefix + 1);
        assert.match(frame.name, /\bformatProgress\(/);
        const values = await locals(client, frame);
        assert.equal(findVariable(values, 'prefix').value, '"Total: "');
    });

    const advancedStop = await step('continue to advanced.as and verify its top frame', async () => {
        await client.request('continue', { threadId: basicStop.threadId });
        const stopped = await stackAt(client, 'breakpoint', advanced, callback);
        assert.match(stopped.frames[0].name, /\binspectParty\(/);
        return stopped;
    });
    const values = await step('read the advanced locals and scopes', () => locals(client, advancedStop.frames[0]));
    await step('expand Scout (rank = 3, inherited name = "Rook")', async () => {
        const scout = await variables(client, findVariable(values, 'scout'));
        assert.equal(findVariable(scout, 'rank').value, '3');
        assert.equal(findVariable(scout, 'name').value, '"Rook"');
    });
    await step('verify integer and Player handle arrays', async () => {
        const scores = findVariable(values, 'scores');
        assert.equal(scores.value, '3 elements');
        const elements = await variables(client, scores);
        assert.equal(elements.length, 3);
        assert.equal(findVariable(elements, '[1]').value, '13');

        const party = findVariable(values, 'party');
        assert.equal(party.value, '2 elements');
        const player = findVariable(await variables(client, party), '[0]');
        const members = await variables(client, player);
        assert.equal(findVariable(members, 'name').value, '"Ada"');
        assert.equal(findVariable(members, 'health').value, '90');
    });
    await step('expand the dictionary (round = 2, leader = "Rook")', async () => {
        const stats = await variables(client, findVariable(values, 'stats'));
        assert.equal(findVariable(stats, 'round').value, '2');
        assert.equal(findVariable(stats, 'leader').value, '"Rook"');
    });
    await step('stop on the out-of-range exception and inspect the exception info', async () => {
        await client.request('continue', { threadId: advancedStop.threadId });
        const { threadId, frame } = await stackAt(client, 'exception', advanced, exception);
        assert.match(frame.name, /\bdemonstrateException\(/);
        const info = await client.request('exceptionInfo', { threadId });
        assert.match(info.description, /out of (range|bounds)/i);
    });
    await step('continue through the exception and stop again in Tick', async () => {
        await client.request('continue', { threadId: advancedStop.threadId });
        const stopped = await stackAt(client, 'breakpoint', advanced, callback);
        assert.match(stopped.frames[1]?.name ?? '', /\bTick\(/);
    });
    await step('disconnect', () => client.request('disconnect', { terminateDebuggee: false }));
}

let currentStep = 'validate arguments';
let socket;
let timeout;
try {
    const port = Number(process.argv[2] ?? 9002);
    const request = process.argv[3] ?? 'attach';
    assert.ok(Number.isInteger(port) && port >= 1 && port <= 65535, 'Expected a port from 1 to 65535');
    assert.ok(['attach', 'launch'].includes(request), 'Expected attach or launch');

    currentStep = `connect to 127.0.0.1:${port}`;
    socket = createConnection({ host: '127.0.0.1', port });
    socket.setTimeout(5000, () => socket.destroy(new Error('Timed out waiting for DAP traffic')));
    timeout = setTimeout(() => socket.destroy(new Error('DAP test exceeded 30 seconds')), 30_000);
    await once(socket, 'connect');
    console.log(`PASS ${currentStep}`);
    currentStep = 'read script breakpoint markers';
    await run(new DapClient(socket), port, request, async (name, check) => {
        currentStep = name;
        const result = await check();
        console.log(`PASS ${name}`);
        return result;
    });
} catch (error) {
    console.error(`FAIL ${currentStep}: ${error.message}`);
    process.exitCode = 1;
} finally {
    clearTimeout(timeout);
    socket?.destroy();
}
