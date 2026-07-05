IDE-grade Outline/Semantic Language Model - pass 192

Completeness focus:
- Removed the extension/heuristic Ada-like gate from Outline extraction.
- `Editor.Outline_Extractor.Extract` now calls `Editor.Ada_Declaration_Parser.Parse` for every non-empty snapshot.
- Parser-owned symbols still take precedence over manual markers.
- Parser-empty snapshots preserve only explicit `@outline` manual rows.
- Added an extensionless-buffer regression test proving normal Ada declarations are parsed by the language model before marker fallback.
- Extended release_check guards so the old `Ada_Like` gate and duplicate line-scanner fallback cannot silently reappear.

Validation available in this environment:
- Static source inspection for the changed Outline path and release guard markers.
- No Python or shell files were added.

Validation not available in this environment:
- GNAT/gprbuild/AUnit execution, because the Ada toolchain is not installed here.
