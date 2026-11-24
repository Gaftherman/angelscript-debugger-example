# Ejemplo del depurador de AngelScript

**[English](README.md)** | **[Español](README.es.md)**

Un pequeño programa anfitrión en C++ para ejecutar y depurar AngelScript desde VS Code.

<p align="center"><img src="media/debugger.gif" alt="Conexión desde VS Code y ejecución paso a paso de AngelScript para inspeccionar las variables y la pila de llamadas" width="880"></p>
<p align="center"><em>Conéctate desde VS Code, ejecuta AngelScript paso a paso e inspecciona las variables y la pila de llamadas.</em></p>

## Inicio rápido
```text
> git clone --recursive https://github.com/Gaftherman/angelscript-debugger-example.git
> cd angelscript-debugger-example
```
```text
> .\run-demo.cmd --build-only
```
Compila `angelscript-demo.exe`.

```text
> code .
> F5
```
Pon un punto de interrupción en una línea marcada con `// BP` en [`scripts/basic.as`](scripts/basic.as), elige **Launch AngelScript Demo** y pulsa **F5**.

## Iniciar desde VS Code
<p align="center"><img src="media/debugger-launch.gif" alt="Inicio con F5, pausa en un punto de interrupción y salida del script en la consola de depuración" width="960"></p>
<p align="center"><em>Inicia con F5, inspecciona el puntaje y continúa para ver el total.</em></p>

## Conectarse a un anfitrión en ejecución
```text
> .\run-demo.cmd
> F5
```
Cuando aparezca `DAP listening`, elige **Attach to AngelScript Demo** en VS Code y pulsa **F5**.

## Estructura del proyecto
```text
└── 📁 angelscript-debugger-example
    ├── 📁 .vscode
    │   ├── 📄 launch.json         Configuraciones para conectar e iniciar
    │   ├── 📄 settings.json       Ajuste de las declaraciones predefinidas
    │   └── 📄 tasks.json          Tarea de compilación previa al inicio
    ├── 📁 host
    │   └── 📄 main.cpp            Anfitrión en C++, print, Player y servidor DAP
    ├── 📁 scripts
    │   ├── 📄 basic.as            Cálculo del puntaje y llamadas a funciones
    │   ├── 📄 advanced.as         Objetos, colecciones y excepciones
    │   ├── 📄 engine.as           Llamadas al anfitrión y sus callbacks
    │   └── 📄 host.as.predefined  Declaraciones de la API del anfitrión
    ├── 📁 media
    └── 📄 run-demo.cmd            Compila, ejecuta y prueba la demo
```

## Requisitos
Windows, Git, CMake 3.21+, Ninja, Visual Studio 2022+ o Build Tools con **Desarrollo para el escritorio con C++** (MSVC x64, C++20), VS Code con la [extensión de AngelScript](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman) y Node.js 18+ para las pruebas.

## Pruebas
```text
> .\run-demo.cmd --test
```
Prueba la conexión mediante DAP.

```text
> .\run-demo.cmd --test-launch
```
Prueba el inicio de la sesión mediante DAP.

Para usar el depurador en tu propia aplicación, consulta el [README de asdebugger](https://github.com/Gaftherman/asdebugger). Sven Co-op usa el mismo depurador mediante el complemento de Metamod.
