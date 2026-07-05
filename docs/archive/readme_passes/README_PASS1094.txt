Pass1094 — Diagnostic recovery-render keybinding hint projection

This pass adds Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection.

The new layer consumes Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection and projects recovery-render command-palette entries into deterministic keybinding/invocation hint metadata. It preserves diagnostic identity, recovery-render command/action/status/lifecycle/render identities, feed/index identity, source span, severity, semantic source family, token kind, syntax node, recovery headline, lifecycle row status, command kind, availability state, persistent diagnostic/action keys, previous/current diagnostic fingerprints, palette-entry fingerprints, binding-state metadata, and deterministic hint fingerprints.

Supported hint kinds:
- review recovery render status
- navigate retained recovery render diagnostic
- review changed recovery render diagnostic
- review missing recovery render diagnostic
- review rejected stale recovery render diagnostic UI state
- restore recovery render selection candidate

Supported binding states:
- no binding
- bindable
- unavailable target
- stale-only
- rejected stale

The layer is projection-only. It does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, render, or perform rendering-side semantic work.

Regression coverage:
Test_Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection_Pass1094

This pass adds one compiler-grade building block for keybinding-facing diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
