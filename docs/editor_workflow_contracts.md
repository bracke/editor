# Editor Workflow Contracts

This file records the small contracts that routine editor work should preserve.
The contracts are backed by focused unit slices and product smoke scenarios.

## Status Surfaces

Status-bar summaries are immutable render snapshots. They may expose typed
message kinds and stable action IDs, but they must not carry command payloads,
copy feature rows, mutate editor state, or persist workflow state.

Current typed action surfaces cover Workspace, Quick Open, Outline,
Search/Replace, File Tree, and Recent Projects. New status surfaces should use
the same pattern: a scalar summary, typed message kind when classification is
needed, and stable command IDs for visible actions.

## Pending Transitions

Pending transitions are explicit confirmation state. The pending bar model owns
the visible operation kind, destructive-confirmation metadata, and action-to-
command mapping. Input integration must route pointer and keyboard activation
through those audited command IDs instead of duplicating action handling.

## Render Packets

Render packets are observational output. Status bars, pending bars, diagnostics,
and build summaries must render on dedicated layers without mutating editor
state. Render-packet tests should assert layer presence, bounded glyph/rectangle
counts, and non-overlap/viewport bounds where the workflow depends on them.

## Focused Smoke

`tools/bin/product_smoke` is the combined release smoke. Routine development uses
the focused smoke command that matches the changed workflow:

- `tools/bin/product_smoke_quick_open_file_tree`
- `tools/bin/product_smoke_edit_save`
- `tools/bin/product_smoke_daily_editing`
- `tools/bin/product_smoke_workspace_session`
- `tools/bin/product_smoke_dirty_lifecycle_persistence`
- `tools/bin/product_smoke_build_ui_interaction`
- `tools/bin/product_smoke_command_palette_ranking`
- `tools/bin/product_smoke_diagnostics_problems`
- `tools/bin/product_smoke_diagnostic_quick_fix`
- `tools/bin/product_smoke_build_diagnostics`
- `tools/bin/product_smoke_render_packet`
- `tools/bin/product_smoke_focus_selftest`
- `tools/bin/editor_workflow_gate --quick`

Each focused command forwards a scenario name to `tests/bin/editor_product_smoke`
and stops after that workflow marker. The focus selftest runs the wrappers and
checks that each report contains only the marker for its selected workflow.

Live workflow scans exclude generated and archived paths: `docs/archive`, `obj`,
`bin`, `tools/bin`, `lib`, and `README_PASS*.txt`.
`tools/bin/check_repo_hygiene` flags common live-root artifact leaks and product
smoke fixture directories left behind by interrupted runs.
`tools/bin/source_status` prints a filtered source-oriented status view without
modifying the worktree. Use `tools/bin/source_status --only tools` or another
`--only` category when reviewing one validation surface. Its summary lines
include actionable, filtered, and per-category counts before path details.

## Test Selection

Use `tools/bin/test_commands_for <changed-path>...` before validation. It prints
the unit slices and focused smoke/gate commands for the changed paths. The full
`tools/bin/unit_tests all` aggregate remains release-only.
Problems and core Diagnostics changes should use
`tools/bin/unit_tests diagnostics-problems` before broader build-tool slices.
