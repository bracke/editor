Editor Phase 579 pass1096

This pass adds Editor.Ada_Diagnostic_Recovery_Render_Final_Projection.

Scope:
- Consume Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection.
- Produce immutable final render-safe recovery-render rows and badges.
- Preserve stable diagnostic identities, feed/index identity, source span, severity, source family, token kind, syntax node, command kind, binding state, selection state, recovery headline, lifecycle row status, persistable keys, previous/current diagnostic fingerprints, and deterministic fingerprints.
- Expose selected row, restore-candidate row, diagnostic lookup, row-kind lookup, recovery-headline lookup, lifecycle-status lookup, badge counters, row-kind counters, headline counters, lifecycle counters, severity counters, rejected-row totals, editable-row totals, and model fingerprint.
- Rejected/stale recovery-render workspace inputs expose zero active final render rows while preserving rejected-row totals.

Invariant:
The package is projection-only. It does not render, parse, register commands, create aliases, mutate keybindings, invoke commands, apply edits, save/reload files, mutate buffers, mutate workspace/session state, or perform rendering-side semantic work.

Regression:
- Test_Ada_Diagnostic_Recovery_Render_Final_Projection_Pass1096

Compiler-grade note:
This pass adds one compiler-grade building block for final render-safe diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
