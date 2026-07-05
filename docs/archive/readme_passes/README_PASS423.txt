Editor IDE-grade Outline/Semantic Language Model - Pass 423

This pass extends Ada token-cursor grammar coverage for abort statements.

Changes:
- Added Production_Abort_Target to Editor.Ada_Token_Cursor.
- Replaced opaque abort-statement semicolon skipping with structural parsing of task-name target lists.
- Preserved selected-name, indexed-component, and explicit-dereference suffixes inside abort targets.
- Added AUnit regression coverage for:
  abort Worker, Pool.Tasks (Index), Controller.Current.all;
- Updated validation guards, release-check comments, README, outline docs, syntax-colouring docs, and release checklist.

Limits:
- This remains syntax retention only.
- It does not validate task identity, abortability, master/activation legality, accessibility, or runtime tasking semantics.
