Pass1047 implements the Ada diagnostic status-line summary model.

Added package:
- Editor.Ada_Diagnostic_Status_Line

Implemented behavior:
- consumes Editor.Ada_Semantic_Diagnostic_Index
- summarizes accepted snapshot-guarded semantic diagnostics for status-line consumers
- exposes total/error/warning/info counts
- exposes highest-severity status-line kind
- exposes deterministic compact summary text
- counts diagnostics on the current line and exact current position
- preserves nearest diagnostic metadata and fingerprint
- preserves source-family counters
- withholds stale rejected indexes while preserving rejected diagnostic totals

Regression coverage:
- Test_Ada_Diagnostic_Status_Line_Pass1047

This pass adds one compiler-grade building block for IDE-facing diagnostic status presentation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
