Editor Phase 579 IDE-grade outline/semantic language model — pass 366

This pass tightens cross-file Ada unit relationship indexing so the first-class unit table contains only top-level library units. Nested package and subprogram declarations remain available through ordinary symbol lookup, but they no longer appear as spec/body/separate unit rows for cross-file navigation.

Implemented changes:
- Added Is_Library_Unit_Symbol in Editor.Ada_Project_Index.
- Rebuild_Units now appends only library unit symbols with root ownership.
- Preserved dotted library child-unit indexing for top-level units such as Parent.Child.
- Added Test_Project_Index_Unit_Table_Excludes_Nested_Declarations.
- Updated README, outline/syntax docs, release checklist, validation guard, and release-check guard notes.

Conservative behavior:
- Nested declarations are still retained by the language model and ordinary project symbol index.
- Nested declarations are not treated as separate cross-file Ada compilation units.
- No external compiler, LSP, parser generator, Python, or shell tooling was added.
