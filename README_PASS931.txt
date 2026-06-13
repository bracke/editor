Editor Phase 579 — Pass931

This pass improves structural Ada grammar coverage for generic formal subprogram declarations.

Implemented:
- Added `Production_Formal_Subprogram_Default_Abstract_Name` so `with function F return T is abstract Defaults.F;` retains the default designator after `abstract`.
- Added `Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary` so malformed `with procedure P is;` and equivalent declaration/aspect-boundary cases stop locally without consuming the next formal declaration.
- Added AUnit coverage in `Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery_Pass931`.
- Updated parser coverage, syntax-colouring notes, validation guards, release checklist, and README.

Scope:
- Improves structural grammar coverage for generic formal declarations.
- Does not implement compiler-grade generic contract checking, default conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
