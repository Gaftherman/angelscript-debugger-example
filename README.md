# AngelScript Debugger Example

**[English](README.md)** | **[Español](docs/README.es.md)**

A small C++ host to run and debug AngelScript from VS Code.

<p align="center"><img src="media/debugger.gif" alt="Attaching in VS Code and stepping through AngelScript while inspecting variables and the call stack" width="880"></p>
<p align="center"><em>Attach in VS Code, step through AngelScript, and inspect variables and the call stack.</em></p>

## Quick start
```text
> git clone --recursive https://github.com/Gaftherman/angelscript-debugger-example.git
> cd angelscript-debugger-example
```
```text
> .\run-demo.cmd --build-only
```
Builds `angelscript-demo.exe`.

```text
> code .
> F5
```
Set a breakpoint on a `// BP` line in [`scripts/basic.as`](scripts/basic.as), select **Launch AngelScript Demo**, and press **F5**.

## Launch from VS Code
<p align="center"><img src="media/debugger-launch.gif" alt="Launching the host with F5, pausing at a breakpoint, and reading script output in the Debug Console" width="960"></p>
<p align="center"><em>Launch with F5, inspect the score, and continue to see the final total.</em></p>

## Attach to a running host
```text
> .\run-demo.cmd
> F5
```
Wait for `DAP listening`, then select **Attach to AngelScript Demo** in VS Code, and press **F5**.

## Project layout
```text
└── 📁 angelscript-debugger-example
    ├── 📁 .vscode
    │   ├── 📄 launch.json         Attach and Launch configurations
    │   ├── 📄 settings.json       Predefined stub setting
    │   └── 📄 tasks.json          Build task for Launch
    ├── 📁 host
    │   └── 📄 main.cpp            C++ host, print, Player, and the DAP server
    ├── 📁 scripts
    │   ├── 📄 basic.as            Score calculation and function calls
    │   ├── 📄 advanced.as         Objects, collections, and exceptions
    │   ├── 📄 engine.as           Host calls and callbacks
    │   └── 📄 host.as.predefined  Host API declarations
    ├── 📁 external
    │   ├── 📁 angelscript         AngelScript engine (submodule)
    │   └── 📁 angelscript-dap     Debugger core (submodule)
    ├── 📁 media
    └── 📄 run-demo.cmd            Build and run the demo
```

## Requirements
Windows, Git, CMake 3.21+, Ninja, Visual Studio 2022+ or Build Tools with **Desktop development with C++** (MSVC x64, C++20), and VS Code with the [AngelScript extension](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman).

## Use the debugger in your own host
The debugger is the [angelscript-dap](https://github.com/Gaftherman/angelscript-dap) repository, included here as a submodule. [`host/main.cpp`](host/main.cpp) shows the calls a host makes, and the angelscript-dap README lists the CMake options.

```cmake
add_subdirectory(external/angelscript-dap)  # after your AngelScript target
target_link_libraries(my_host PRIVATE angelscript_dap)
```

## Related projects

| Project | Use |
| --- | --- |
| [angelscript-dap](https://github.com/Gaftherman/angelscript-dap) | The debugger core and its support |
| [angelscript-cli](https://github.com/Gaftherman/angelscript-cli) | Run, check and debug scripts from the terminal |
| [angelscript-lsp](https://github.com/Gaftherman/angelscript-lsp) | Editor support for VS Code |
| [asdebugger](https://github.com/Gaftherman/asdebugger) | The Sven Co-op plugin built on the same core |

## License
[MIT](LICENSE). See also [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/THIRD_PARTY.md](docs/THIRD_PARTY.md).
