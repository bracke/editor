Pass1091 adds diagnostic recovery render action projection.

New package:
- Editor.Ada_Diagnostic_Recovery_Render_Action_Projection

The package consumes Editor.Ada_Diagnostic_Recovery_Render_Status and projects retained, changed, missing, stale, and restore-candidate recovery-render status rows into deterministic non-mutating IDE action descriptors.  It preserves diagnostic identity, recovery render lifecycle/render/status identities, feed/index identity, source spans, severity, source family, token kind, syntax node, recovery headline, lifecycle row status, render row kind, render badges, persistent diagnostic/action keys, previous/current diagnostic fingerprints, and deterministic action fingerprints.

The layer remains projection-only: no command registration, no command aliases, no command invocation, no keybinding mutation, no workspace/session mutation, no edits, no parsing, no buffer mutation, no file save/reload, and no rendering-side semantic work.

Regression added:
- Test_Ada_Diagnostic_Recovery_Render_Action_Projection_Pass1091
