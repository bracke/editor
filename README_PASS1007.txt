Editor Phase 579 pass1007 — expression membership/range inference

This pass adds one compiler-grade building block for Ada expression type inference: membership, range, and short-circuit/range-adjacent Boolean result refinement.

Implemented:
- Extended Editor.Ada_Expression_Types with Membership_Range_Inference_Status.
- Added per-expression metadata for membership test subtype, choice subtype, range low/high subtype, compatibility counts, mismatch counts, and unknown counts.
- Membership expressions now infer Boolean result metadata while retaining operand/choice compatibility state.
- Range expressions now retain bound subtype compatibility metadata instead of remaining plain indeterminate expressions.
- Universal numeric compatibility is applied for integer/real-family membership and range bounds.
- Deterministic counters were added for membership resolved/mismatch/unknown and range resolved/mismatch/unknown cases.
- Expression fingerprints now include membership/range inference metadata.
- Added AUnit regression Test_Ada_Expression_Membership_Range_Inference_Pass1007.

Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-complete expression resolution, full aggregate component association typing, generic contract closure, private-view consumers, representation legality, freezing interactions, and cross-unit semantic closure are fully integrated.
