Pass1050 - Ada diagnostic suppression / baseline metadata model

This pass adds Editor.Ada_Diagnostic_Suppression_Baseline, a projection-only model that consumes Editor.Ada_Semantic_Diagnostic_Index and records deterministic suppression/baseline metadata for IDE consumers.

Implemented scope:
- Diagnostic suppression/baseline rule set with stable rule ids, rule kinds, reasons, and fingerprints.
- Rule kinds for suppression by index id, source family, severity, and baselines by diagnostic fingerprint or source/severity.
- Diagnostic metadata entries classified as active, suppressed, or baselined while preserving the underlying diagnostic identity and payload.
- Stale/rejected diagnostic indexes expose no active entries and preserve rejected-entry totals.
- Counters for active, suppressed, baselined, rejected, severity, and source-family totals.
- Queries for first diagnostic entry by diagnostic identity and entries by suppression/baseline status.
- Deterministic model fingerprinting.
- AUnit coverage through Test_Ada_Diagnostic_Suppression_Baseline_Pass1050.

Invariant notes:
- The model does not parse source text.
- The model does not perform file IO.
- The model does not save, reload, or mutate dirty state.
- The model does not apply source edits.
- The model does not register commands or mutate workspace/render state.
- Suppression/baseline classification is metadata-only and does not conceal stale-analysis rejection.
