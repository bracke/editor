Pass866 - Case statement missing-is recovery depth

This pass adds token-cursor metadata for malformed or in-progress Ada case statements where the required `is` keyword is missing after the selector.

Implemented changes:
- Added `Production_Case_Statement_Missing_Is_Recovery_Boundary`.
- Updated case statement parsing so `case Kind` followed by `when` alternatives records bounded case-specific missing-`is` recovery.
- Preserved selector metadata, case alternatives, end-case metadata, and following statement visibility.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866`.
- Updated parser coverage, semantic-colouring notes, release guards, and validation guard markers.

This improves structural grammar coverage only. It does not add compiler-grade case-choice coverage checking, discrete-choice legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
