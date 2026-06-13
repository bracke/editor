Pass1038 - Generic contract diagnostics projection

Implemented a projection-only diagnostics layer for the generic-contract semantic models.

Added:
- Editor.Ada_Generic_Contract_Diagnostics
- Diagnostic kinds for formal type mismatches/unresolved cases
- Diagnostic kinds for formal package nested actual mismatches/unresolved cases
- Diagnostic kinds for generic renaming and nested instantiation errors
- Diagnostic kinds for formal object default/actual type mismatches, static range errors, and unknowns
- Stable severity, node, generic instance/formal, span, message, counter, and fingerprint metadata
- Test_Ada_Generic_Contract_Diagnostics_Projection_Pass1038

This pass keeps diagnostics model-owned and projection-only: no reparsing, file IO, editor mutation, command registration, rendering work, or workspace leakage.
