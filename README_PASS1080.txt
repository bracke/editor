Pass1080 - Diagnostic render projection

This pass adds Editor.Ada_Diagnostic_Render_Projection.

The package consumes Editor.Ada_Diagnostic_Workspace_Projection and projects accepted diagnostic workspace entries into render-safe immutable rows and badges.  It preserves stable diagnostic identity, feed/index identity, source span, severity, source family, token kind, syntax node, command kind, selection state, persistable keys, display text, sort keys, source/workspace fingerprints, and deterministic row/model fingerprints.

The projection supports selected-row lookup, diagnostic lookup, row-kind lookup, severity row counters, badge counters, selected/restore/rejected/editable counters, and stale-model withholding.  Rejected/stale workspace projections expose zero active render rows while preserving rejected-row totals.

The package is projection-only: it does not render, parse, register commands, create aliases, mutate keybindings, invoke commands, apply edits, save/reload files, mutate buffers, or change workspace/session state.

Regression added:
Test_Ada_Diagnostic_Render_Projection_Pass1080
