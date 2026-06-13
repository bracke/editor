Editor Phase 579 — Pass1020

Pass1020 adds one compiler-grade expression-analysis building block: dispatching-call inference metadata.

Implemented scope:

- `Editor.Ada_Expression_Types` now stages dispatching-call metadata for call-shaped expression and statement nodes.
- Calls retain primitive target classification when the resolved declaration is subprogram-like and carries callable profile metadata.
- Class-wide controlling operand and controlling-result shapes are recognized from callable profile text and actual-expression subtype metadata where available.
- Static binding, dynamic dispatch, ambiguous targets, unresolved targets, and controlling-unknown cases are preserved explicitly instead of being collapsed into generic call-resolution statuses.
- Deterministic counters were added for resolved, dynamic, static, ambiguous, and unknown dispatching-call cases.
- Dispatching-call metadata contributes to expression-type fingerprints.
- AUnit coverage was added in `Test_Ada_Expression_Dispatching_Call_Inference_Pass1020`.

This pass adds one compiler-grade building block for expression type analysis. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
