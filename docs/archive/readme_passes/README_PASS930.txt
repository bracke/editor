Editor — Pass930

This pass deepens structural Ada grammar recovery for access-definition edge cases adjacent to pass929.

Implemented:
- Added `Production_Access_Mode_Missing_Subtype_Recovery_Boundary` for `access all` / `access constant` declarations whose designated subtype is missing at a boundary.
- Added `Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary` for malformed general-access modes followed by `procedure`, `function`, or `protected`.
- Added `Production_Access_Protected_Missing_Subprogram_Boundary_Token` so malformed `access protected` retains the actual boundary token after the missing subprogram keyword.
- Added `Production_Access_Result_Missing_Subtype_Recovery_Boundary` for access-to-function `return` clauses that reach an aspect/declaration boundary before a result subtype.
- Added AUnit coverage in `Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth_Pass930`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, and  validation guards.

Scope:
- This improves structural grammar coverage for malformed access definitions.
- It is not compiler-grade access-type legality checking, designated-subtype legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
