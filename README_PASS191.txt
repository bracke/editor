Editor Phase 579 IDE-grade outline/semantic language-model pass 191

Focus: narrow Outline_Extractor's parser-empty fallback so normal Ada declaration recognition remains owned by Editor.Ada_Declaration_Parser / Editor.Ada_Language_Model.

Changes:
- Refactored Editor.Outline_Extractor fallback scanning to preserve only explicit @outline marker rows when the Ada parser returns no symbols.
- Removed fallback calls into the legacy declaration-leading Ada line recognizer from Extract.
- Updated Outline_Extractor package documentation to describe parser-owned Ada extraction and marker-only manual fallback.
- Added AUnit regression coverage for marker-only fallback on Ada-like buffer labels.
- Added release_check guards to reject reintroduction of Append_Source_Line / fallback Append_Ada_Line calls.
- Updated docs/outline.md with pass 191 marker-only fallback note.

Validation in this environment:
- Static grep confirmed no Append_Source_Line remains in src/core/editor-outline_extractor.adb.
- Static grep confirmed no fallback Append_Ada_Line(Result, State, ...) call remains.
- Static grep confirmed no Python or shell scripts were added.
- GNAT/gprbuild/AUnit were not available in this container, so compile/test execution must be run in the normal GNAT/Alire environment.
