Pass1097 adds Editor.Ada_Diagnostic_Recovery_Render_Final_Lifecycle.

This pass validates immutable final diagnostic recovery-render rows against a fresh snapshot-guarded semantic diagnostic index. It classifies final render rows as retained, changed, missing, or rejected stale while preserving diagnostic identity, feed/index identity, source spans, severity, semantic source family, token kind, syntax node, recovery headline, source lifecycle status, final render badges, persistent diagnostic/action keys, previous/current diagnostic fingerprints, final-render fingerprints, index fingerprints, and deterministic lifecycle fingerprints.

The pass remains projection-only. It performs no parsing, rendering-side semantic work, command registration, command aliases, keybinding mutation, workspace/session mutation, command invocation, edits, buffer mutation, file save/reload, or renderer mutation.

Regression added:
- Test_Ada_Diagnostic_Recovery_Render_Final_Lifecycle_Pass1097

This pass adds one compiler-grade building block for final diagnostic recovery-render lifecycle validation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
