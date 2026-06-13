Pass410 parser-completeness update

Scope:
- Continue extending Ada token-cursor grammar coverage for IDE-grade Outline and semantic colouring.

Implemented:
- Quantified expressions now parse the quantified loop scheme instead of skipping it as opaque text.
- `(for all I in 1 .. 10 => ...)` retains `Production_Quantified_Expression`, `Production_Defining_Name`, and `Production_Loop_Parameter_Specification`.
- `(for some Element of reverse Items => ...)` retains `Production_Quantified_Expression`, `Production_Defining_Name`, and `Production_Iterator_Specification`.
- Missing `=>` in quantified expressions now produces a recovery point instead of silent loss.

Tests/guards:
- Added `Test_Language_Model_Token_Cursor_Quantified_Expression_Grammar_Completeness`.
- Extended phase validation/release guards so quantified-expression loop-scheme grammar cannot regress to old opaque skipping.

Still conservative:
- This is grammar recognition only. It does not validate iterator legality, quantified-domain type legality, subtype constraints, predicate legality, or GNAT-equivalent semantic legality.
