Pass1043 adds Editor.Ada_Semantic_Diagnostic_Feed, a unified snapshot-guarded semantic diagnostics feed for IDE-facing Ada consumers.

The feed consumes the already-guarded semantic diagnostic projection from Editor.Ada_Semantic_Diagnostic_Snapshot_Guards and flattens accepted semantic-colouring diagnostic entries into one deterministic API with source family, severity, token kind, stable span, message, source fingerprint, and feed fingerprint metadata.

Rejected stale snapshots expose no diagnostic entries and retain the rejected-entry count, so stale expression, generic-contract, cross-unit, representation/freezing, and colouring diagnostics cannot leak into IDE consumers after buffer identity, revision, lifecycle generation, request-token, or analysis-fingerprint changes.

Regression coverage is in Test_Ada_Semantic_Diagnostic_Feed_Pass1043.
