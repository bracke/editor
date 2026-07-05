Pass1086 — Diagnostic recovery keybinding hint projection

This pass adds Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection.

The package consumes Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection and exposes deterministic, projection-only keybinding/invocation hints for diagnostic lifecycle/recovery commands.  It preserves recovery command identity, command-palette entry identity, diagnostic/feed/index identity, recovery status/lifecycle/render identities, source span, severity, source family, token kind, syntax node, render row kind, lifecycle status, recovery headline, persistent diagnostic/action keys, previous/current diagnostic fingerprints, palette fingerprints, and deterministic hint fingerprints.

Supported hint kinds:
- review recovery status
- navigate retained diagnostic
- review changed diagnostic
- review missing diagnostic
- review rejected stale diagnostic UI state
- restore selection candidate

Supported binding states:
- no binding
- bindable
- unavailable target
- stale-only
- rejected stale

The layer remains projection-only and performs no command registration, command aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, or rendering-side semantic work.

Regression: Test_Ada_Diagnostic_Recovery_Keybinding_Hint_Projection_Pass1086.
