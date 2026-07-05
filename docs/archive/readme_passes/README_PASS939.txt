Editor pass939

Implemented expression grammar recovery refinements for conditional expressions, case expressions, and parallel-reduction argument recovery.

Changed:
- Added Production_If_Expression_Condition_Reserved_Boundary.
- Added Production_Case_Expression_Missing_Selector_Recovery_Boundary.
- Added Production_Case_Expression_Missing_Is_Recovery_Boundary.
- Added Production_Parallel_Reduction_Argument_Recovery_Boundary.
- Added Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939.
- Updated parser coverage, syntax-colouring notes, release guards, and README.

Scope:
This improves structural grammar coverage for malformed expression recovery. It is not compiler-grade expression legality checking, expected-type resolution, static-expression validation, overload resolution, reduction profile conformance checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
