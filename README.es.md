# Ejemplo de depurador de AngelScript

Un plugin pequeño de Sven Co-op que puedes depurar desde VS Code. Tiene tres errores de ejecución a propósito, para que veas cómo el depurador se detiene en cada uno y te muestra el estado del script.

![Depurador detenido en un error de índice](docs/debugger.gif)

## Qué necesitas

- [Visual Studio Code](https://code.visualstudio.com/) y la [extensión Angelscript](https://marketplace.visualstudio.com/items?itemName=Gaftherman.angelscript-gaftherman).
- Sven Co-op con el plugin [asdebugger](https://github.com/Gaftherman/asdebugger), que escucha en el puerto `9002`.

## Pruébalo

1. Copia `scripts/plugins/DebugExample.as` a la carpeta `scripts/plugins` de tu juego y regístralo en `default_plugins.txt`.
2. Abre esta carpeta en VS Code. La carpeta `.vscode/` ya trae la configuración de depuración y el stub de Sven Co-op.
3. Abre `scripts/plugins/DebugExample.as` y pulsa `F9` en una línea marcada `BREAK HERE`.
4. Inicia el juego, pulsa `F5` y elige **Attach to Game (asdebugger)**.
5. Cuando el script llegue a esa línea, VS Code se detiene allí. Mira **Variables**, **Call Stack** y **Watch**.

## Los tres errores

| Función | Qué falla | Qué verás en el depurador |
| :--- | :--- | :--- |
| `CheckScores` | Índice `3` en un array de 3 elementos | `index = 3`, `g_Scores` con 3 entradas y luego una excepción de rango |
| `ShowLastPlayer` | Lee un miembro de un handle nulo | `g_pLastPlayer` aparece como `null` y luego una excepción de puntero nulo |
| `AveragePerPlayer` | Divide entre `players = 0` | `players = 0` en Variables y luego una excepción de división por cero |

## La configuración de lanzamiento

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

`.vscode/launch.json` también trae **Launch Game and Debug**, que arranca primero el ejecutable de tu juego. Cambia `executable` por la ruta de tu juego.

## Grabar la demo

`docs/debugger.gif` se graba con el juego en marcha. Los pasos están en [docs/RECORDING.md](docs/RECORDING.md).

[English](README.md)
