Pass1025 - body/spec declaration conformance

This pass adds one compiler-grade building block for cross-unit semantic
closure: body/spec declaration conformance.

Implemented:

- Added Editor.Ada_Body_Spec_Conformance.
- Projects cross-unit spec/body consistency metadata into lookup-facing
  declaration-conformance records.
- Confirms package spec/body pairs.
- Confirms subprogram spec/body pairs when their retained profile summaries
  match.
- Preserves profile mismatches separately from missing, ambiguous, overflow,
  role-mismatch, and name-mismatch counterpart cases.
- Records spec/body unit names, roles, paths, profile summaries, candidate
  counts, conformance status, and deterministic fingerprints.
- Added counters for confirmed packages, confirmed subprogram profiles,
  missing counterparts, ambiguous counterparts, overflow, role mismatches,
  name mismatches, profile mismatches, profile unknowns, and model
  fingerprint.
- Added AUnit regression:
  Test_Ada_Body_Spec_Declaration_Conformance_Pass1025.

The model remains snapshot-owned and consumes only the project index plus the
already-built cross-unit closure. It performs no file IO, parsing, rendering
mutation, dirty-state mutation, command-palette mutation, keybinding mutation,
or workspace mutation.

Full compiler-grade Ada analysis remains incomplete until the remaining layers
such as overload resolution, type checking, generic contracts,
freezing/representation legality, and cross-unit semantic closure are fully
integrated.
