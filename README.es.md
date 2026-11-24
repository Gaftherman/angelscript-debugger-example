# Ejemplo del depurador de AngelScript

Ejecuta y depura AngelScript en una pequeña aplicación anfitriona escrita en C++.

[English](README.md)

<p align="center"><img src="media/debugger.gif" alt="Conexión desde VS Code y ejecución paso a paso de AngelScript para inspeccionar las variables y la pila de llamadas" width="880"></p>
<p align="center"><em>Conéctate desde VS Code, ejecuta AngelScript paso a paso e inspecciona las variables y la pila de llamadas.</em></p>

## Inicio rápido

Para ejecutar la demo necesitas Windows, Visual Studio 2022 o posterior (o Build Tools) con **Desarrollo para el escritorio con C++**, CMake 3.21+, Ninja, Git y VS Code con la [extensión de AngelScript](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman). Node.js 18+ solo hace falta para las pruebas automáticas.

Obtén el código con Git (una descarga ZIP no incluye las dependencias):

```powershell
git clone --recursive https://github.com/Gaftherman/angelscript-debugger-example.git
cd angelscript-debugger-example
.\run-demo.cmd
```

`run-demo.cmd` localiza Visual Studio, inicializa los submódulos que falten y compila la demo. Déjalo activo cuando aparezca `DAP listening on 127.0.0.1:9002`.

Abre esta carpeta en VS Code y pulsa **F9** en una línea marcada con `// BP` en `scripts/basic.as`. Abre **Ejecutar y depurar**, elige **Attach to AngelScript Demo** en la lista desplegable junto al botón verde de reproducción y pulsa **F5**. El editor se detiene en la línea del punto de interrupción y se llenan **Variables** y **Pila de llamadas**.

## Qué muestra cada script

| Script | Qué probar |
| --- | --- |
| [`basic.as`](scripts/basic.as) | Ejecuta `addBonus` en un solo paso y entra en `formatProgress` para inspeccionar las variables locales y la pila de llamadas. |
| [`advanced.as`](scripts/advanced.as) | Inspecciona miembros heredados, arreglos y un diccionario, sigue una llamada recursiva o activa **All Exceptions** para detenerte cuando un índice se salga de rango. |
| [`engine.as`](scripts/engine.as) | Ejecuta llamadas al anfitrión de C++ y detente en `OnPlayerSpawn` cuando el anfitrión la invoque. |

Para usar el depurador en tu propia aplicación, consulta el [README de asdebugger](https://github.com/Gaftherman/asdebugger).

Sven Co-op usa el mismo depurador mediante el complemento de Metamod.

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

Ejecuta `.\run-demo.cmd --test` o `.\run-demo.cmd --test-launch` para probar la conexión DAP.
