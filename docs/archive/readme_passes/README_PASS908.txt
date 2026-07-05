Editor Pass908

This pass improves Ada token-cursor grammar recovery for malformed assignment
statements at reserved statement-sequence boundaries.

Changes:
- Added Production_Assignment_Reserved_Boundary_Recovery_Boundary.
- Refined assignment parsing so `Value := else;` and equivalent reserved-boundary
  forms preserve assignment missing-expression recovery without fabricating the
  boundary keyword as an expression.
- Added AUnit regression
  Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery_Pass908.
- Updated validation guard markers, parser coverage notes, syntax-colouring notes,
  release checklist, and README.

This improves structural grammar coverage only. It is not compiler-grade
assignment-expression legality checking, expression type checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.
