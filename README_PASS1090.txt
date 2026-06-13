Pass1090 adds Editor.Ada_Diagnostic_Recovery_Render_Status.

This pass consumes Editor.Ada_Diagnostic_Recovery_Render_Lifecycle and produces a compact IDE-facing status surface for diagnostic recovery render lifecycle rows. It summarizes retained, changed, missing, and rejected-stale recovery render rows while preserving diagnostic identity, feed/index identity, source span, severity/source/token metadata, recovery render row kind, primary/secondary/recovery badges, source recovery headline, source lifecycle status, persistent diagnostic/action keys, previous/current diagnostic fingerprints, and deterministic result fingerprints.

The layer is projection-only. It performs no rendering-side parsing, no rendering-side semantic work, no command registration, no command aliases, no command invocation, no keybinding mutation, no workspace/session mutation, no edits, no buffer mutation, and no file save/reload.
