Editor pass935

This pass deepens structural subprogram contract/aspect placement parsing in the Ada token cursor.

Changed:
- Added specific contract placement productions for:
  - subprogram bodies before `is`
  - null procedure completions after `is null`
  - abstract subprogram completions after `is abstract`
  - expression-function completions after the expression
- Added contract-specific missing-value recovery when `=>` is followed by a delimiter or boundary before a value expression.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth_Pass935`.
- Updated parser coverage, syntax-colouring notes, release guards, and README.

Scope:
This improves structural grammar coverage for subprogram contract/aspect placement. It is not compiler-grade aspect legality checking, contract conformance checking, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
