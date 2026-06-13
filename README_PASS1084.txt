Pass1084 — Diagnostic recovery command projection

This pass adds Editor.Ada_Diagnostic_Recovery_Command_Projection.

The package consumes Editor.Ada_Diagnostic_Recovery_Action_Projection and projects recovery actions into deterministic command-facing descriptors. It supports review-status, navigate-retained, review-changed, review-missing, review-rejected-stale, and restore-selection-candidate command kinds.

The model preserves diagnostic identity, recovery-action identity, recovery-status/lifecycle/render identities, feed/index identity, stable source spans, severity, source family, token kind, syntax node, render row kind, lifecycle status, recovery headline, persistable diagnostic/action keys, previous/current diagnostic fingerprints, action fingerprints, and deterministic descriptor/model fingerprints.

Rejected/stale recovery-action models expose no active command descriptors while preserving rejected-command totals.

The layer is projection-only. It does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, or perform rendering-side semantic work.

Regression added:
Test_Ada_Diagnostic_Recovery_Command_Projection_Pass1084
