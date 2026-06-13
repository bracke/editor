Pass1079 — Diagnostic workspace/session projection model

This pass adds Editor.Ada_Diagnostic_Workspace_Projection.

The new layer consumes Editor.Ada_Diagnostic_Keybinding_Hint_Projection and projects diagnostic hint/action metadata into deterministic workspace/session-facing UI state descriptors. It is deliberately projection-only: it does not persist state, mutate workspace/session records, register commands, create aliases, mutate keybindings, invoke commands, apply edits, parse, save or reload files, mutate buffers, or perform rendering-side semantic work.

The model provides:
- stable diagnostic workspace entries
- persistable diagnostic/action keys derived from source span and fingerprints
- selected-entry state
- restore-candidate state
- diagnostic/feed/index identity preservation
- command kind and keybinding hint preservation
- no buffer-internal identifier exposure in persisted keys
- stale/rejected input withholding with rejected-entry totals
- deterministic fingerprints

Regression coverage:
- Test_Ada_Diagnostic_Workspace_Projection_Pass1079

This pass adds one compiler-grade building block for workspace/session-facing diagnostic UI state projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
