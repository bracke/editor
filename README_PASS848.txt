Editor Phase 579 Pass848 — Loop iteration domain recovery depth

This pass improves structural grammar coverage for Ada loop iteration schemes.

Implemented:
- Added Production_For_Loop_Missing_Domain_Recovery_Boundary.
- Added Production_Iterator_Loop_Missing_Domain_Recovery_Boundary.
- Updated for-loop iteration-scheme parsing so missing discrete ranges before `when`, `loop`, or `;` produce bounded domain-specific recovery metadata.
- Updated iterator-loop iteration-scheme parsing so missing iterable names before `when`, `loop`, or `;` produce bounded domain-specific recovery metadata.
- Preserved existing loop filter, loop begin, statement sequence, and following statement visibility.
- Added AUnit regression Test_Language_Model_Token_Cursor_Loop_Iteration_Domain_Recovery_Pass848.
- Updated README, parser coverage matrix, syntax-colouring notes, release checklist, and validation guard markers.

This is structural parser/token-cursor metadata only. It is not compiler-grade loop legality checking, iterator legality checking, discrete-range validation, subtype conformance, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
