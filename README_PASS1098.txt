Pass1098 adds Editor.Ada_Diagnostic_Recovery_Render_Final_Status.

This pass projects Editor.Ada_Diagnostic_Recovery_Render_Final_Lifecycle rows into a compact IDE-facing final recovery-render lifecycle status surface. It classifies final lifecycle state as clean, retained, changed, missing, or rejected stale while preserving diagnostic identity, final lifecycle identity, final render row identity, feed/index identity, source spans, severity, semantic source family, token kind, syntax node, final render row kind, recovery headline, source lifecycle status, source render row kind, final render badges, persistent diagnostic/action keys, previous/current diagnostic fingerprints, final lifecycle fingerprints, and deterministic status fingerprints.

The package exposes deterministic lookup helpers for first diagnostic row, status, headline, final row kind, and source lifecycle status, plus counters for retained, changed, missing, rejected, severity, status, headline, final row kind, source lifecycle status, and model fingerprint.

Rejected/stale final lifecycle inputs expose zero active status rows while preserving rejected-row totals. The package remains projection-only and performs no parsing, rendering-side semantic work, command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, buffer mutation, dirty-state mutation, rendering, or file save/reload.

Regression coverage:
- Test_Ada_Diagnostic_Recovery_Render_Final_Status_Pass1098

This pass adds one compiler-grade building block for final diagnostic recovery-render lifecycle status projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
