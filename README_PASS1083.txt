Pass1083 adds Editor.Ada_Diagnostic_Recovery_Action_Projection.

This pass consumes Editor.Ada_Diagnostic_Recovery_Status and projects retained,
changed, missing, and rejected-stale diagnostic recovery states into deterministic
non-mutating IDE-facing recovery actions.

The projection preserves diagnostic identity, lifecycle/render/index identity,
source span, severity, source family, token kind, syntax node, lifecycle status,
recovery headline, persistent diagnostic/action keys, previous/current diagnostic
fingerprints, and deterministic action fingerprints.

All actions are metadata only.  The package does not register commands, invoke
commands, create command aliases, mutate keybindings, mutate workspace/session
state, parse, render, edit buffers, or save/reload files.

Added regression coverage:
- Test_Ada_Diagnostic_Recovery_Action_Projection_Pass1083
