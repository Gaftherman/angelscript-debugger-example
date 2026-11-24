# Ejemplo del depurador de AngelScript

Ejecuta y depura AngelScript en una pequeña aplicación anfitriona escrita en C++. [English](README.md)

<p align="center"><img src="media/debugger.gif" alt="Conexión desde VS Code y ejecución paso a paso de AngelScript para inspeccionar las variables y la pila de llamadas" width="880"></p>
<p align="center"><em>Conéctate desde VS Code, ejecuta AngelScript paso a paso e inspecciona las variables y la pila de llamadas.</em></p>

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

## Inicio rápido

Necesitas Windows, Visual Studio 2022 o posterior (o Build Tools) con **Desarrollo para el escritorio con C++**, CMake 3.21+, Ninja, Git y VS Code con la [extensión de AngelScript](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman). Node.js 18+ solo hace falta para las pruebas automáticas. Clona el repositorio con Git para incluir las dependencias.

```powershell
git clone --recursive https://github.com/Gaftherman/angelscript-debugger-example.git
cd angelscript-debugger-example
.\run-demo.cmd
```

`run-demo.cmd` localiza Visual Studio, inicializa los submódulos que falten y compila la demo. Déjalo activo cuando aparezca `DAP listening on 127.0.0.1:9002`. Abre esta carpeta en VS Code, pulsa **F9** en una línea marcada con `// BP` en `scripts/basic.as`, elige **Attach to AngelScript Demo** en **Ejecutar y depurar** y pulsa **F5** para inspeccionar **Variables** y **Pila de llamadas**.

## Iniciar desde VS Code

Detén cualquier instancia de la demo, coloca un punto de interrupción en una línea marcada con `// BP` en `scripts/basic.as` y elige **Launch AngelScript Demo** en **Ejecutar y depurar**. Pulsa **F5** para compilar e iniciar el anfitrión, detenerte en el punto de interrupción y ver la salida de `print` en la **Consola de depuración**.

<p align="center"><img src="media/debugger-launch.gif" alt="Inicio con F5, pausa en un punto de interrupción y salida del script en la consola de depuración" width="960"></p>
<p align="center"><em>Inicia con F5, inspecciona el puntaje y continúa para ver el total.</em></p>

## Qué muestra cada script

- Con [`basic.as`](scripts/basic.as), ejecuta `addBonus` en un solo paso y entra en `formatProgress` para inspeccionar las variables locales y la pila de llamadas.
- Con [`advanced.as`](scripts/advanced.as), inspecciona miembros heredados, arreglos y un diccionario, sigue una llamada recursiva o activa **All Exceptions** para detenerte cuando un índice se salga de rango.
- Con [`engine.as`](scripts/engine.as), ejecuta llamadas al anfitrión de C++ y detente en `OnPlayerSpawn` cuando el anfitrión la invoque.

Para usar el depurador en tu propia aplicación, consulta el [README de asdebugger](https://github.com/Gaftherman/asdebugger). Sven Co-op usa el mismo depurador mediante el complemento de Metamod.

## Funciones del motor

<p align="center"><img src="media/debugger-engine.gif" alt="Ejecución de una llamada nativa, inspección de Player y pausa en OnPlayerSpawn" width="960"></p>
<p align="center"><em>Despliega un <code>Player</code> del anfitrión, ejecuta la llamada a <code>print</code> y detente en <code>OnPlayerSpawn</code>.</em></p>

- Al pulsar **F11** sobre `print` o `player.heal`, se ejecuta la llamada nativa y el depurador se detiene en la siguiente línea de AngelScript. En esas pausas, la pila solo muestra marcos del script.
- El anfitrión invoca `OnPlayerSpawn` en cada ciclo. Al detenerte ahí, esa función ocupa el único marco de la **Pila de llamadas** y puedes desplegar `player` en **Variables**.
- [`host.as.predefined`](scripts/host.as.predefined) ofrece información al pasar el cursor y sugerencias de autocompletado. Como sus declaraciones carecen de líneas ejecutables, el punto de interrupción queda sin verificar. Para probarlo, activa **Debug: Allow Breakpoints Everywhere** en VS Code.

## Solución de problemas

- Si la primera compilación no puede descargar las dependencias, revisa tu conexión a internet y vuelve a ejecutar `.\run-demo.cmd`.
- Si el puerto `9002` está ocupado, detén la instancia anterior o ejecuta `.\run-demo.cmd --port N` y usa el mismo puerto en la configuración de conexión de VS Code.
- Si el depurador no se detiene, abre esta carpeta como espacio de trabajo en VS Code y coloca el punto de interrupción en una línea marcada con `// BP`.
- Ejecuta `.\run-demo.cmd --test` o `.\run-demo.cmd --test-launch` para probar la conexión DAP.
