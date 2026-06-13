Editor Phase 579 Pass1085

This pass adds Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection.

The package consumes Editor.Ada_Diagnostic_Recovery_Command_Projection and projects diagnostic lifecycle/recovery command descriptors into deterministic command-palette-facing entries. It preserves descriptor/action/status/lifecycle/render/index identities, stable spans, severity, source family, token kind, syntax node, command kind, availability, recovery headline, persistent diagnostic/action keys, command names, display/search/sort payloads, and deterministic fingerprints.

The layer remains projection-only. It does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, save or reload files, mutate buffers, or perform rendering-side semantic work.

Regression coverage:

Test_Ada_Diagnostic_Recovery_Command_Palette_Projection_Pass1085

This pass adds one compiler-grade building block for command-palette-facing diagnostic recovery projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
