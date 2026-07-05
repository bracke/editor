# Pass834 - Digits/delta constraint expression recovery depth

Pass834 improves structural grammar coverage for Ada `digits` and `delta`
constraints in subtype indications and allocator subtype constraints.

Changed:
- Added `Production_Digits_Constraint_Expression`.
- Added `Production_Digits_Constraint_Missing_Expression_Recovery_Boundary`.
- Added `Production_Delta_Constraint_Expression`.
- Added `Production_Delta_Constraint_Missing_Expression_Recovery_Boundary`.
- Updated digits/delta constraint parsing so well-formed operands are explicitly
  tagged and malformed/in-progress constraints recover at bounded declaration,
  constraint, and aspect boundaries.
- Added AUnit regression
  `Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions_Pass834`.
- Updated docs, syntax-colouring notes, release checklist, and validation guards.

This improves structural grammar coverage for Ada digits/delta constraint
operands. It is not compiler-grade fixed/floating-point legality checking,
static expression validation, subtype conformance validation, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.
