Pass1092 — Diagnostic recovery-render command projection

Pass1092 adds Editor.Ada_Diagnostic_Recovery_Render_Command_Projection.

The package consumes Editor.Ada_Diagnostic_Recovery_Render_Action_Projection and turns recovery-render action descriptors into deterministic command-facing descriptors for:

- review recovery render status
- navigate retained recovery render diagnostic
- review changed recovery render diagnostic
- review missing recovery render diagnostic
- review stale recovery render diagnostic UI state
- restore recovery render selection candidate

The projection preserves diagnostic identity, recovery render status/lifecycle/render identities, feed/index identity, source spans, severity, semantic source family, token kind, syntax node, render row kind, lifecycle row status, recovery headline, source recovery headline, render badges, persistent diagnostic/action keys, previous/current diagnostic fingerprints, recovery-render action fingerprints, command names, availability, and deterministic descriptor fingerprints.

The layer remains projection-only. It does not register commands, add command aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, render, or perform rendering-side semantic work.

Regression coverage:

- Test_Ada_Diagnostic_Recovery_Render_Command_Projection_Pass1092

This pass adds one compiler-grade building block for command-facing diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
