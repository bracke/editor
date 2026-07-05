Pass1082 adds Editor.Ada_Diagnostic_Recovery_Status.

This package consumes Editor.Ada_Diagnostic_Lifecycle_Recovery and projects retained,
changed, missing, and rejected-stale diagnostic UI lifecycle rows into a compact
IDE-facing recovery/status surface.  The model preserves diagnostic identity,
lifecycle/render/index identities, source span, severity, source family, token
kind, syntax node, persistent keys, row status, headline classification, summary
text, and deterministic fingerprints.

The pass adds lookup helpers for diagnostic identity, lifecycle row status,
headline, and render row kind, plus counters for retained, changed, missing,
rejected, severity, lifecycle status, headline, render row kind, and fingerprint.

The layer is projection-only: it performs no parsing, rendering, command
registration, keybinding mutation, workspace/session mutation, buffer mutation,
edits, or file save/reload.

Regression added:

  Test_Ada_Diagnostic_Recovery_Status_Pass1082
