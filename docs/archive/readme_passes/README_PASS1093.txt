Pass1093 adds Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection.

The pass consumes Editor.Ada_Diagnostic_Recovery_Render_Command_Projection and produces deterministic command-palette-facing entries for recovery-render diagnostic commands. It covers review recovery-render status, navigate retained recovery-render diagnostics, review changed diagnostics, review missing diagnostics, review stale recovery-render UI state, and restore recovery-render selection candidate commands.

The model preserves diagnostic identity, recovery-render command/action/status/lifecycle/render identities, feed/index identity, source span, severity, semantic source family, token kind, syntax node, recovery headline, lifecycle row status, render row kind, command kind, command availability, command name, palette title/subtitle/search/sort payloads, persistent diagnostic/action keys, previous/current diagnostic fingerprints, descriptor fingerprints, and deterministic palette-entry fingerprints.

The layer is projection-only. It performs no command registration, adds no aliases, invokes no commands, mutates no keybindings, mutates no workspace/session state, applies no edits, performs no parsing, mutates no buffers, saves/reloads no files, and performs no rendering-side semantic work.

Regression coverage: Test_Ada_Diagnostic_Recovery_Render_Command_Palette_Projection_Pass1093.
