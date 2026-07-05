Pass1042 — semantic diagnostic snapshot guards

Implemented a deterministic guard layer for semantic diagnostics and semantic-colouring overlays.

Added package:
- Editor.Ada_Semantic_Diagnostic_Snapshot_Guards

The guard records and validates:
- path
- buffer token
- buffer revision
- lifecycle generation
- request token
- analysis fingerprint

It classifies stale projections as:
- path mismatch
- buffer mismatch
- revision mismatch
- lifecycle mismatch
- request-token mismatch
- analysis-fingerprint mismatch

Accepted projections preserve semantic-colouring entries and severity counters. Rejected projections expose no entries, retain a rejection status, and count the withheld stale entries. The package performs no parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering work.

Regression:
- Test_Ada_Semantic_Diagnostic_Snapshot_Guards_Pass1042

This pass adds one compiler-grade building block for stale-analysis rejection in diagnostics and semantic-colouring integration. Full compiler-grade Ada analysis remains incomplete until the remaining overload resolution, type checking, generic-contract, freezing/representation, and cross-unit semantic-closure layers are fully integrated.
