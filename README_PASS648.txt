Editor Phase 579 pass648 focused parser coverage update.

Implemented structural loop-statement grammar coverage in Editor.Ada_Token_Cursor.

Changes:
- Added dedicated productions for for-loop iteration schemes, parameters, and domains.
- Added dedicated productions for iterator-loop iteration schemes, element names, and iterable domains.
- Added a dedicated production for while-loop conditions.
- Added a dedicated loop statement-sequence production while preserving existing generic statement-sequence markers.
- Added AUnit regression coverage for reverse discrete loops, reverse iterator loops, while-loop conditions, nested exit-when statements, and recovery into following statements.
- Updated README and release checklist notes.

This improves structural grammar coverage for Ada loop statements. It is not compiler-grade legality checking for iterator legality, discrete subtype legality, boolean typing, or control-flow semantics.
