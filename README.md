# AngelScript Debugger Example

A tiny Sven Co-op plugin you can debug from VS Code. It has three runtime errors on purpose, so you can see the debugger stop on each one and show you the state of the script.

![Debugger stopped on an array index error](docs/debugger.gif)

## What you need

- [Visual Studio Code](https://code.visualstudio.com/) and the [Angelscript extension](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman).
- Sven Co-op running the [asdebugger](https://github.com/Gaftherman/asdebugger) plugin, which listens on port `9002`.

## Try it

1. Copy `scripts/plugins/DebugExample.as` into your game's `scripts/plugins` folder and register it in `default_plugins.txt`.
2. Open this folder in VS Code. The `.vscode/` folder already holds the debug configuration and the Sven Co-op stub.
3. Open `scripts/plugins/DebugExample.as` and press `F9` on a line marked `BREAK HERE`.
4. Start the game, then press `F5` and pick **Attach to Game (asdebugger)**.
5. When the script reaches that line, VS Code stops there. Look at **Variables**, **Call Stack** and **Watch**.

## The three errors

| Function | What goes wrong | What you will see in the debugger |
| :--- | :--- | :--- |
| `CheckScores` | Index `3` on an array of 3 items | `index = 3`, `g_Scores` with 3 entries, then an out-of-range exception |
| `ShowLastPlayer` | Reads a member of a null handle | `g_pLastPlayer` shown as `null`, then a null pointer exception |
| `AveragePerPlayer` | Divides by `players = 0` | `players = 0` in Variables, then a divide by zero exception |

## The launch configuration

```json
{
  "name": "Attach to Game (asdebugger)",
  "type": "angelscript",
  "request": "attach",
  "host": "127.0.0.1",
  "port": 9002,
  "protocol": "dap"
}
```

`.vscode/launch.json` also has a **Launch Game and Debug** entry that starts your game executable first. Change `executable` to the path of your game.

## Recording the demo

`docs/debugger.gif` is recorded with the game running. The steps are in [docs/RECORDING.md](docs/RECORDING.md).

[Español](README.es.md)
