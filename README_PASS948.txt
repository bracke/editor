Editor Phase 579 pass948 — call-candidate overload foundation

This pass adds Editor.Ada_Call_Candidates, a compiler-grade semantic building
block for overload resolution.  The model consumes parser-owned syntax trees,
declarative regions, direct visibility, use visibility, and use-type primitive
visibility, then records call-shaped syntax nodes and their pre-filter callable
candidates.

Covered in this pass:
- Node_Function_Call and Node_Call_Statement candidate collection.
- deterministic call-name normalization.
- direct/enclosing visibility lookup.
- ordinary package-use visibility through Editor.Ada_Use_Visibility.
- primitive operator candidates through Editor.Ada_Use_Type_Operators.
- found, ambiguous, unresolved, and missing-designator status metadata.
- deterministic fingerprints for stale-result guards and regression checks.

AUnit coverage:
- Test_Ada_Call_Candidate_Foundation_Pass948

This is a compiler-grade foundation layer.  Full overload resolution still needs
expected-type propagation, profile conformance, type checking, implicit
conversion legality, static-expression evaluation, generic contracts,
freezing/representation legality, and cross-unit semantic closure.
