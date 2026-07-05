Pass1063 — Nested body/spec diagnostics projection

This pass extends Editor.Ada_Cross_Unit_Diagnostics so nested body/spec declaration conformance results from Editor.Ada_Nested_Body_Spec_Conformance can enter the normal cross-unit diagnostics projection.

Implemented:
- Adds Build_With_Nested to Editor.Ada_Cross_Unit_Diagnostics.
- Projects nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs.
- Preserves nested conformance identity, nested conformance status, declaration name, source/target unit names, spans, severity, message payload, and deterministic fingerprints.
- Adds nested diagnostic counters for total nested body/spec diagnostics, missing nested declarations, extra nested declarations, and nested mismatch/unknown cases.
- Leaves the existing Build path unchanged for older cross-unit diagnostic consumers.
- Adds Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063.

Invariant notes:
- The pass is projection-only and consumes snapshot-owned semantic metadata.
- It performs no parsing, file IO, save/reload, dirty-state mutation, command registration, workspace mutation, rendering-side parsing, or edit application.
- Existing diagnostic paths remain deterministic and bounded.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
