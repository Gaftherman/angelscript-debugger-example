# Recording docs/debugger.gif

1. Start Sven Co-op with asdebugger loaded and `DebugExample.as` registered.
2. Open this folder in VS Code, set the font size to about 22 (`editor.fontSize`) and hide the minimap.
3. Put a breakpoint on the `CheckScores` line marked `BREAK HERE` and attach with `F5`.
4. Record the VS Code window (ScreenToGif or OBS) from the moment the script stops: the yellow line, the Variables pane with `index = 3`, then the Call Stack.
5. Export at 960 px wide, 15 fps, under 3 MB, and save it as `docs/debugger.gif`. Animated GIF is the format the VS Code Marketplace renders; WebP is not.
