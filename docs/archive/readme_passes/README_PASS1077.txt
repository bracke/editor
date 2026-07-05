Pass1077 adds Editor.Ada_Diagnostic_Command_Palette_Projection.

The new package consumes Editor.Ada_Diagnostic_Command_Projection and projects command-facing diagnostic descriptors into deterministic command-palette entries. Entries preserve diagnostic identity, descriptor identity, feed/index identity, source span, severity, semantic source family, token kind, syntax node, command name, title, subtitle, search text, sort key, availability, edit flag, descriptor fingerprint, and palette fingerprint.

The layer is projection-only. It does not register command aliases, mutate keybindings, invoke commands, apply edits, parse, save or reload files, mutate buffers, touch workspace state, or perform rendering-side semantic work.

Rejected/stale command projection models expose zero active palette entries while preserving rejected-entry totals.

Regression coverage:
- Test_Ada_Diagnostic_Command_Palette_Projection_Pass1077
