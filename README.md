# AngelScript Debugger Example

[Español](README.es.md)

Run and debug AngelScript in a standalone C++20 host. The host embeds
AngelScript 2.39.0, links the asdebugger core, and listens for a Debug Adapter
Protocol (DAP) client at `127.0.0.1:9002`.

<p align="center"><img src="media/debugger.gif" alt="Setting a breakpoint, attaching with F5, then stepping with F10 and F11 while Variables and Call Stack update" width="880"></p>

## Requirements

- Visual Studio 2022 or later, or its Build Tools, with the **Desktop development with C++** workload and MSVC x64 tools.
- CMake 3.21+, Ninja, Git, and Python 3. The first build needs network access for dependencies.
- VS Code with the AngelScript extension for interactive debugging. [AngelScript extension](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman)
- Node.js 18+ for the automated DAP test.

## Quick start

From the repository root in PowerShell:

```powershell
git submodule update --init --recursive
.\run-demo.cmd
```

The debugger entry in `.gitmodules` is a placeholder while the
`refactor/host-agnostic-core` branch awaits publication. At present, the
submodule command populates AngelScript. Use a local checkout containing the
host core for the debugger:

```powershell
.\run-demo.cmd --asdebugger-dir "..\asdebugger"
```

Replace `..\asdebugger` with the checkout's path. This sets the CMake
`ASDEBUGGER_DIR` cache entry. Once the debugger commit has been published and
its gitlink added to this repository, `git submodule update --init --recursive`
will populate both dependencies. To switch an existing build to the submodule,
pass `--asdebugger-dir .\external\asdebugger`.

1. Open the repository in VS Code. Open `scripts/basic.as` and set a breakpoint with **F9** on a line ending in `// BP`.
2. Select **Attach to AngelScript Demo** and press **F5**. The host waits for the client to finish configuring breakpoints before it runs the scripts.
3. Use **Step Over**, **Step Into**, or **Continue**. Stop the host with **Ctrl+C** when you finish.

To build and start the host from VS Code, select **Launch AngelScript Demo**
instead. If you are using a local debugger checkout, first run
`run-demo.cmd --build-only --asdebugger-dir <path>` to set the build's cached
path. The launch task uses that cache.

## What you'll see

- In `basic.as`, inspect `total` before and after stepping over `addBonus`. Step into `formatProgress` and see the caller in the call stack.
- In `advanced.as`, expand the inherited `Scout` members, the integer and `Player@` arrays, and the dictionary in **Variables**. A callback invokes a recursive function.
- Enable **All Exceptions** in the **Breakpoints** panel before starting. The demo triggers one out-of-range exception during startup. Continue to see the host log the error and keep running.
- Both scripts run `Tick()` roughly every 250 ms, so you can set new breakpoints after startup.

## Run the automated test

```powershell
.\run-demo.cmd --test
.\run-demo.cmd --test-launch
```

The runner starts a fresh host in wait mode, runs the dependency-free DAP
client, stops the host, and returns the test's exit code. The second command
exercises the DAP `launch` request used by the VS Code launch configuration.
Pass `--asdebugger-dir <path>` on the first build when using a local checkout.

## Use the core in your own host

Start with the example under **Using the core in your own host**. It shows how
to link `asdebugger_core`, use `StdHostAdapter` with the vanilla add-ons, attach
contexts, and poll between executions. For custom bindings, implement
`asIDBHostAdapter`. [asdebugger README](https://github.com/Gaftherman/asdebugger#using-the-core-in-your-own-host)

## Sven Co-op

For a Sven Co-op server, use the Metamod plugin from the same debugger project.
[asdebugger plugin](https://github.com/Gaftherman/asdebugger)

## Troubleshooting

- **Missing core or SDK.** Initialize the submodules. While the debugger gitlink is pending, pass `--asdebugger-dir` or configure CMake with `-DASDEBUGGER_DIR=<path>`.
- **Cannot bind port 9002.** Stop any previous demo host or pass `--port N` and set the same port in VS Code. In a launch configuration, also pass `--port N` in the executable's `args`.
- **Breakpoints never hit.** Open this folder as the VS Code workspace, select the `dap` configuration, and use an executable line marked `// BP`.
- **Custom scripts.** Build with `run-demo.cmd --build-only` and run `build\bin\Release\angelscript-demo.exe --wait scripts/basic.as` from the repository root. You can pass several script files. Each must define `void main()`. The host uses `void Tick()` when present and repeats `main()` otherwise.
