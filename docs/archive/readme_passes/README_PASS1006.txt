Editor Pass1006

This pass adds one compiler-grade expression-type inference building block for conditional, quantified, declare, and reduction expression forms.

Implemented:
- Editor.Ada_Expression_Types now records Conditional_Type_Inference_Status metadata.
- Conditional/case expressions retain branch counts, compatible-branch counts, mismatch counts, unknown counts, and inferred result subtype metadata.
- Quantified expressions are classified as Boolean-result expressions.
- Declare expressions retain explicit declare-result metadata, using expected subtype context when available and preserving result-unknown status otherwise.
- Reduction expressions retain explicit reduction-result metadata, using expected subtype context when available and preserving result-unknown status otherwise.
- Conditional/reduction/declare metadata contributes to deterministic expression-type fingerprints.
- Added counters for resolved conditional expressions, branch mismatches, unknown branches, reduction expressions, and declare expressions.
- Added AUnit regression Test_Ada_Expression_Conditional_Declare_Reduction_Inference_Pass1006.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper expression type inference, overload resolution, private-view semantic closure, generic contracts, freezing and representation legality, and cross-unit semantic closure are fully integrated.
