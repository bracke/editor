Pass1089 diagnostic recovery render lifecycle validation

This pass adds Editor.Ada_Diagnostic_Recovery_Render_Lifecycle. The package consumes immutable diagnostic recovery render rows together with a fresh snapshot-guarded semantic diagnostic index and classifies recovery render UI rows as retained, changed, missing, or rejected stale. It preserves diagnostic identity, recovery render identity, source span, severity/source/token metadata, recovery row kind, recovery headline, source lifecycle status, badges, persistent keys, previous/current diagnostic fingerprints, and deterministic lifecycle fingerprints.

The layer is projection-only and validation-only. It does not render, parse, perform rendering-side semantic work, register commands, add command aliases, mutate keybindings, invoke commands, edit buffers, save/reload files, or mutate workspace/session state.

Regression added:
- Test_Ada_Diagnostic_Recovery_Render_Lifecycle_Pass1089
