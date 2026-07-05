Pass1088 — Diagnostic recovery render projection

This pass adds Editor.Ada_Diagnostic_Recovery_Render_Projection.

Scope:
- Consume Editor.Ada_Diagnostic_Recovery_Workspace_Projection.
- Project recovery workspace/session state into immutable render-safe recovery rows and badges.
- Preserve diagnostic identity, recovery workspace identity, feed/index identity, source span, severity, semantic source family, token kind, syntax node, command kind, binding state, selection state, recovery headline, lifecycle row status, previous/current diagnostic fingerprints, persistent keys, display text, sort keys, and deterministic fingerprints.
- Add render row kinds for review status, navigate retained diagnostic, review changed diagnostic, review missing diagnostic, review rejected stale diagnostic UI state, and restore selection candidate.
- Add render badges for error/warning/info, retained/changed/missing/rejected-stale recovery state, selected, restore candidate, unbound, bindable, unavailable target, and stale-only.
- Expose lookups by diagnostic, render row kind, recovery headline, and lifecycle row status.
- Expose deterministic counters for severity rows, selected rows, restore-candidate rows, rejected rows, editable rows, badges, row kinds, recovery headlines, lifecycle status, and model fingerprint.
- Keep rejected/stale recovery workspace projections from exposing active render rows while preserving rejected-row totals.

Invariants:
- No rendering-side parsing.
- No rendering-side semantic work.
- No command registration or aliases.
- No command invocation.
- No keybinding mutation.
- No workspace/session mutation.
- No edits.
- No parsing.
- No buffer mutation.
- No file save/reload.

Regression:
- Test_Ada_Diagnostic_Recovery_Render_Projection_Pass1088

This pass adds one compiler-grade building block for render-safe diagnostic recovery projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
