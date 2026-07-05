Pass1081 - Diagnostic lifecycle recovery projection

This pass adds Editor.Ada_Diagnostic_Lifecycle_Recovery.

The new package consumes Editor.Ada_Diagnostic_Render_Projection and Editor.Ada_Semantic_Diagnostic_Index and compares immutable render-facing diagnostic rows against a fresh snapshot-guarded semantic diagnostic index.  It classifies diagnostic UI rows as retained, changed, missing, or rejected stale without mutating buffers, workspace/session state, command registration, keybindings, rendering, or files.

The model preserves diagnostic identity, feed/index identity, render row identity, source span, severity, source family, token kind, syntax node, render row kind, persistable keys, diagnostic fingerprints, render/index fingerprints, and deterministic recovery fingerprints.

Rejected/stale render or index inputs expose zero active recovery rows while retaining rejected-row counts and stale status.

Regression coverage:

Test_Ada_Diagnostic_Lifecycle_Recovery_Pass1081

This pass adds one compiler-grade building block for diagnostic lifecycle recovery and stable IDE diagnostic UI state validation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
