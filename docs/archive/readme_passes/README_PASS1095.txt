Pass1095 — Diagnostic recovery-render workspace projection

This pass adds Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection.

The new package consumes Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection and projects recovery-render keybinding hints into deterministic workspace/session-facing UI state descriptors.

The projection preserves:
- diagnostic identity
- recovery-render hint, palette, command, action, status, lifecycle, and render identities
- feed/index identity
- source span
- severity
- semantic source family
- token kind
- syntax node
- recovery headline
- lifecycle row status
- command kind
- binding state
- selected/restore-candidate state
- stable diagnostic/action/command keys
- previous/current diagnostic fingerprints
- hint fingerprint
- deterministic workspace fingerprints

Rejected/stale recovery-render hint models expose zero active workspace entries while preserving rejected-entry totals.

The layer is projection-only. It does not persist workspace state, mutate workspace/session records, register commands, create aliases, mutate keybindings, invoke commands, apply edits, parse, save/reload files, mutate buffers, render, or perform rendering-side semantic work.

Regression coverage:
Test_Ada_Diagnostic_Recovery_Render_Workspace_Projection_Pass1095
