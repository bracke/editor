Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 157

This pass hardens overload-set enumeration in Editor.Ada_Language_Model.

Changes:
- Valid_Scope now accepts Root_Scope or retained declaration-owning symbols only.
- Numerically valid but non-owner symbol ids such as objects no longer expose malformed overload rows.
- Added Test_Language_Model_Non_Owner_Scope_Overload_Lookup_Degrades.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 157 notes.
- Extended tools/release_check.adb guards for the source/test/doc coverage.

The change keeps overload traversal bounded and deterministic while degrading malformed analysis metadata conservatively to zero overloads / No_Symbol.
