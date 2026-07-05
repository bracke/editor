Pass1067 — Exact record layout diagnostics projection

This pass extends Editor.Ada_Representation_Diagnostics so exact record-layout validation results from Editor.Ada_Record_Layout_Exact_Validation can enter the normal representation/freezing diagnostic model.

Added/changed:
- New diagnostic kinds for exact record layout Size exceeded, padded Size, Alignment errors, and propagated component errors.
- New Build_With_Exact_Layout entry point.
- New Build_With_Selected_Targets_And_Exact_Layout entry point for callers that also consume selected-name representation target diagnostics.
- New exact record-layout diagnostic counters for total exact-layout diagnostics, Size errors, Alignment errors, and component errors.
- Regression coverage in Test_Ada_Representation_Diagnostics_Exact_Record_Layout_Pass1067.

The implementation remains projection-only and consumes already-built snapshot-owned semantic models. It performs no parsing, file IO, editor mutation, command registration, workspace mutation, or rendering-side semantic work.

This pass adds one compiler-grade building block for exact record layout diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
