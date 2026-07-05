# Implementation Checklist

## Goal

Make the editor core interactive and visible.

By the end of , the editor should:

- open in a real window
- display buffer contents
- display caret
- display selection
- accept real keyboard input
- support undo/redo through live key bindings

is **integration and visibility**, not new editor theory.

---

## Ground Rules

- Do not change semantics unless absolutely necessary.
- Do not add CRDT, rope, multi-cursor, syntax highlighting, or advanced layout.
- Keep renderer simple and ugly if necessary.
- Keep input mapping thin.
- Treat `Editor.Executor` and its tests as the stable core.

---

## Architecture

```text
Platform Input
  -> Runtime input translation
  -> Editor.Input
  -> Editor.Instance / Executor
  -> Editor.Render_Model
  -> Runtime renderer
```

### Work Packages

1. Input Mapping Layer

Goal

Translate platform key/input events into editor commands.

Create
- Editor.Input

Responsibilities
- map left/right keys to Move_Left / Move_Right
- map shift-left/right to movement with Shift => True
- map character input to Insert_Char
- map delete/backspace to Delete_Char
- map undo/redo shortcuts to Undo / Redo

Tasks
- define minimal input event type
- define mapping function from input event -> optional Command
- handle printable character input separately from control keys
- keep platform-specific details outside editor core

Done when
- every required key path produces the expected command
- no editor logic leaks into runtime input code

⸻

2. Live Command Application Path

Goal

Route real input into the current editor state.

Use / update
- Editor.Instance
- Editor.Executor

Tasks
- ensure editor instance owns current state
- ensure instance can apply one command from live input
- ensure undo/redo go through the same live path
- verify replay still deterministic after integration

Done when
- runtime can apply one command at a time to current state
- tests still pass unchanged

⸻

3. Render Model Layer

Goal

Project editor state into something trivial to draw.

Create
- Editor.Render_Model

Responsibilities

Convert state into:
- visible characters
- caret position
- selection span

Keep it simple

Single line only is acceptable at first.

Suggested API
- buffer text as flat sequence
- caret column
- optional selection range

Tasks
- expose renderable text
- expose caret x position
- expose selection start/end in render space
- keep it independent of platform rendering

Done when
- runtime renderer can draw entirely from render model output

⸻

4. Text Rendering

Goal

Show the current buffer contents in the window.

Runtime-side tasks
- choose a monospace debug font path / glyph system already available
- render ASCII characters in one row
- position characters with fixed cell width
- leave advanced text shaping out of scope

Done when
- typed text visibly appears in the window
- text order matches buffer contents exactly

⸻

5. Caret Rendering

Goal

Show current caret position.

Tasks
- render caret as vertical line, block, or debug rectangle
- place caret using render model column
- ensure caret still visible at start and end positions
- verify caret at 0 and Length + 1 renders correctly

Done when
- left/right movement is visible and matches tests

⸻

6. Selection Rendering

Goal

Show active selection.

Tasks
- use min(Start_Pos, End_Pos) / max(Start_Pos, End_Pos) only in render layer
- render selection background or inverse cells
- support reversed selection naturally
- verify selection collapses correctly when inactive

Done when
- shift-left/right visibly highlights the expected span
- reverse selection renders correctly

⸻

7. Character Input

Goal

Type into the live editor.

Tasks
- wire printable character events to Insert_Char
- ensure inserts happen at visible caret position
- verify replace-selection path works live
- verify caret updates visually after insertion

Done when
- typing abc visibly produces abc
- replacing a selection with one character works live

⸻

8. Delete / Backspace Input

Goal

Delete live text correctly.

Tasks
- map runtime delete/backspace behavior explicitly
- decide whether Delete_Char means forward delete or backspace in UI layer
- if both are needed, add mapping carefully without changing core semantics accidentally
- verify delete with and without active selection

Done when
- deleting text behaves predictably in the live window
- selection delete works visually

⸻

9. Undo / Redo Input

Goal

Use the already-tested history model live.

Tasks
- wire Ctrl+Z to Undo
- wire Ctrl+Y or Ctrl+Shift+Z to Redo
- ensure visual state updates after undo/redo
- confirm selection restoration is visible and correct

Done when
- typed text can be undone/redone live
- selection restore is visible and correct

⸻

10. End-to-End Smoke Validation

Goal

Prove the whole chain works.

Manual smoke scenario
- start editor
- type abc
- move left twice with shift
- replace selection with X
- undo
- redo

Expected visible states:
- abc
- selection over expected span
- aX
- undo restores abc
- redo restores aX