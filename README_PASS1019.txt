Editor Phase 579 — Pass1019

Pass1019 adds one compiler-grade expression-analysis building block: string and array concatenation result inference.

Implemented scope:

- `Editor.Ada_Expression_Types` now stages concatenation-specific metadata for `&` operator expressions.
- String/string, string/character, character/string, and expected-context character/character concatenations are classified separately from generic operator inference.
- Array-family concatenations are classified when both operands have matching array subtype shape or when an expected array context supplies the result subtype.
- Mismatched and unknown concatenation operands are preserved explicitly instead of being silently accepted.
- Deterministic counters were added for resolved, string-result, array-result, mismatch, and unknown concatenation cases.
- Concatenation metadata contributes to expression-type fingerprints.
- AUnit coverage was added in `Test_Ada_Expression_Concatenation_Inference_Pass1019`.

This pass adds one compiler-grade building block for expression type analysis. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
