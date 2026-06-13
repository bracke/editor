Pass1087 — Diagnostic recovery workspace/session projection

This pass adds Editor.Ada_Diagnostic_Recovery_Workspace_Projection.

Scope:
- Consume Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection.
- Project recovery hints into deterministic workspace/session-facing UI state descriptors.
- Preserve diagnostic identity, recovery action/status identity, lifecycle/render identity, feed/index identity, source span, severity, semantic source family, token kind, syntax node, recovery headline, lifecycle row status, command kind, binding state, persistent keys, previous/current diagnostic fingerprints, and deterministic result fingerprints.
- Support selected diagnostic recovery action and restore-candidate metadata through stable keys.
- Expose lookups by persist key, diagnostic, command kind, recovery headline, and lifecycle status.
- Expose deterministic counters for selected, restore-candidate, rejected, editable, kind, headline, lifecycle status, and model fingerprint.
- Keep rejected/stale hint models from exposing active workspace entries while preserving rejected-entry totals.

Invariants:
- No workspace/session mutation.
- No command registration or aliases.
- No command invocation.
- No keybinding mutation.
- No edits.
- No parsing.
- No buffer mutation.
- No file save/reload.
- No rendering-side semantic work.
- Persistable keys do not expose buffer-internal identifiers.

Regression:
- Test_Ada_Diagnostic_Recovery_Workspace_Projection_Pass1087

This pass adds one compiler-grade building block for workspace/session-facing diagnostic recovery projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
