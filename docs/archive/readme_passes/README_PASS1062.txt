Pass1062 - Nested body/spec declaration conformance

This pass adds Editor.Ada_Nested_Body_Spec_Conformance, a deterministic semantic layer that compares direct nested declarations inside already-matched body/spec unit pairs.

Implemented:
- Consumes Editor.Ada_Project_Index and Editor.Ada_Body_Spec_Conformance.
- Projects nested declaration conformance for direct child declarations of matching package/subprogram body/spec pairs.
- Classifies confirmed declarations, profile-confirmed subprograms, package confirmations, missing body declarations, extra body declarations, ambiguous body declarations, kind mismatches, profile mismatches, profile-unknown cases, and nonconforming unit pairs.
- Preserves unit conformance identity, spec/body unit names, spec/body paths, spec/body symbol identities, declaration name, normalized name, symbol kinds, profile summaries, source ranges, candidate counts, and deterministic fingerprints.
- Adds lookup by nested declaration name and counters for confirmed, missing, extra, ambiguous, kind mismatch, profile mismatch, profile unknown, and nonconforming unit-pair cases.
- Adds regression coverage in Test_Ada_Nested_Body_Spec_Conformance_Pass1062.
- Keeps the pass projection-only: no rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or compiler invocation.

This pass adds one compiler-grade building block for nested body/spec semantic conformance. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
