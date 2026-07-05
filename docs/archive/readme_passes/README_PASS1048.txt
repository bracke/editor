Pass1048 - Ada diagnostic quick-fix skeleton model

This pass adds Editor.Ada_Diagnostic_Quick_Fix_Skeleton, a projection-only quick-fix candidate model over Editor.Ada_Semantic_Diagnostic_Index.

Implemented scope:
- Consumes only snapshot-guarded semantic diagnostic index models.
- Exposes deterministic non-mutating action candidates for each diagnostic.
- Provides navigation, explanation, and source-family review skeletons.
- Preserves diagnostic identity, feed/index identity, source span, severity, source family, token kind, syntax node, message payload, and fingerprints.
- Exposes candidate lookup by diagnostic identity.
- Exposes counters for candidate totals, severity totals, action-kind totals, source-family totals, editable candidates, rejected stale candidates, and fingerprints.
- Rejected/stale diagnostic indexes expose zero active candidates while retaining rejected-candidate totals.
- Adds AUnit regression coverage through Test_Ada_Diagnostic_Quick_Fix_Skeleton_Pass1048.

The model deliberately does not apply edits or produce text changes. It is an IDE-facing skeleton layer for future quick-fix UI integration.
