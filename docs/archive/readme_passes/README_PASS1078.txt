Pass1078 -- Diagnostic keybinding hint projection

This pass adds Editor.Ada_Diagnostic_Keybinding_Hint_Projection, a projection-only IDE layer that consumes diagnostic command-palette entries and exposes deterministic keybinding/invocation hints without registering commands, creating aliases, changing keybindings, applying edits, parsing, saving/reloading files, mutating buffers, touching workspace state, or performing rendering-side semantic work.

The model preserves diagnostic/feed/index identity, palette entry identity, command descriptor identity, source span, severity, source family, token kind, syntax node, command kind, availability, display text, binding-state metadata, palette fingerprints, and deterministic hint fingerprints.

Rejected/stale diagnostic command-palette models expose no active hints while preserving rejected-hint totals.

Regression added:
- Test_Ada_Diagnostic_Keybinding_Hint_Projection_Pass1078
