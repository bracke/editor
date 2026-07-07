# Testing

Run all Ada build and test commands through Alire so the pinned
`gnat_native = "=15.2.1"` compiler is selected. Do not use plain system GNAT or
plain system GPRBuild from `PATH`; use `alr exec -- gprbuild ...`, `alr build`,
or the repository's `tools/bin/*` wrappers.

Run only the test slice that matches the changed surface during development.
The full `All_Suites` aggregate is for release validation. `tools/bin/unit_tests all`
prints a release-only warning unless `EDITOR_RELEASE_VALIDATION=1` is set.

## Release-Gate Slice Rule

Development changes must build and run the relevant `tools/bin/unit_tests <slice>`
suite selected by `tools/bin/test_slice_for` or `tools/bin/test_commands_for`.
Do not build or run `tools/bin/unit_tests all` for routine changes. The full
`All_Suites` aggregate is a release-only gate and belongs in the release command
sequence, release checklist, or explicit release-validation work.

## Slice Commands

| Slice | Command | Covers |
| --- | --- | --- |
| editor-core | `tools/bin/unit_tests editor-core` | buffers, files, editing, clipboard, search, selection, history, navigation |
| executor-diagnostics | `tools/bin/unit_tests executor-diagnostics` | focused Executor Diagnostics and quick-fix routes |
| executor-search | `tools/bin/unit_tests executor-search` | focused Executor search/find/replace routes |
| executor-navigation | `tools/bin/unit_tests executor-navigation` | focused Executor navigation/history routes |
| executor-buffer-switcher | `tools/bin/unit_tests executor-buffer-switcher` | focused Executor buffer-switcher routes |
| executor-buffer-prune | `tools/bin/unit_tests executor-buffer-prune` | focused Executor buffer-switcher prune routes |
| executor-lifecycle | `tools/bin/unit_tests executor-lifecycle` | focused Executor close/save/project lifecycle routes |
| editor-ui | `tools/bin/unit_tests editor-ui` | render model, palette, keybindings, panels, gutter, status, input, focus, product surface |
| project-workspace | `tools/bin/unit_tests project-workspace` | projects, file tree, project search, workspace persistence, lifecycle/configuration |
| build-tools | `tools/bin/unit_tests build-tools` | diagnostics, build UI, terminal tasks, producers, command-extension surfaces |
| ada-parser-outline | `tools/bin/unit_tests ada-parser-outline` | Ada parser, outline, syntax cache, syntax semantics |
| ada-language-service | `tools/bin/unit_tests ada-language-service` | Ada language service integration |
| ada-language | `tools/bin/unit_tests ada-language` | Ada semantic legality and language model |
| ada-rm-validation | `tools/bin/unit_tests ada-rm-validation` | Ada RM audit, burn-down, remediation, and release-readiness validation |
| text | `tools/bin/unit_tests text` | text buffer primitives |

Suite ownership is intentionally narrow. Parser, outline, syntax cache, and
syntax-semantics changes belong to `ada-parser-outline`; language-service
integration belongs to `ada-language-service`; semantic legality and the Ada
language model remain in `ada-language`; RM audit/remediation validation belongs
to `ada-rm-validation`. Executor changes start with `editor-core`, then add the
companion slices reported by `tools/bin/test_commands_for --why` when the route
projects Diagnostics, Build UI, Search Results, or product-smoke behavior.
`executor-search`, `executor-diagnostics`, `executor-navigation`,
`executor-buffer-switcher`, `executor-buffer-prune`, and `executor-lifecycle`
are physically split into focused test packages and shared support. New
`editor-executor-*_tests.adb` packages must route to a focused slice; the
repository hygiene gate rejects focused executor test packages that fall back to
`editor-core`. Changes to shared executor support expand to all physical
executor slices through `tools/bin/test_commands_for`.

Use `tools/bin/test_slice_for <changed-path>` when the relevant slice is not
obvious. The helper is conservative and returns one primary slice per path.
Use `tools/bin/test_commands_for <changed-path>...` in CI-style checks to print
the deduplicated commands for a change set. It always prints the relevant
`tools/bin/unit_tests <slice>` commands for code changes and may also print
focused product smoke or workflow-gate commands when the changed paths touch
those surfaces. Documentation-only paths map to a `docs` pseudo-slice and do not
print a unit-test command.
`tools/bin/unit_tests <slice>` reports elapsed time for the selected slice and
fails if the runner registers zero tests, so focused slices cannot silently rot
into empty checks.
Successful runs append tab-separated timing records to
`/tmp/editor_unit_test_timings.tsv`; use `tools/bin/unit_test_timings` to print
the latest successful timing per slice when deciding what to split next.
Use `tools/bin/test_commands_for --changed` to resolve the current
`git diff --name-only` set directly, without an external pipeline. This is the
preferred local pre-commit check when the worktree contains a coherent change
set.
Pass `-` to read changed paths from standard input, for example
`git diff --name-only | tools/bin/test_commands_for --why -`.
Multiple explicit paths are accepted too, for example
`tools/bin/test_commands_for --why src/core/editor-feature_diagnostics.adb src/core/editor-render_packet.adb`.
For diagnostic quick-fix and Build UI action changes, use a combined example
such as `tools/bin/test_commands_for --why src/core/editor-executor.adb src/core/editor-build_ui_actions.adb tests/src/editor-build_ui-tests.adb`;
the expected routine output includes the focused editor-core/build-tools slices
and the diagnostic quick-fix or Build UI product smoke when those workflows are
touched.
Common focused examples:

| Surface | Example command |
| --- | --- |
| Current changed files | `tools/bin/test_commands_for --why --changed` |
| Executor quick-fix routing | `tools/bin/test_commands_for --why src/core/editor-executor.adb` |
| Build UI actions | `tools/bin/test_commands_for --why src/core/editor-build_ui_actions.adb tests/src/editor-build_ui-tests.adb` |
| Build UI keyboard/input bridge | `tools/bin/test_commands_for --why src/core/editor-input_bridge.adb tests/src/editor-input_bridge-tests.adb` |
| Diagnostics projection/review | `tools/bin/test_commands_for --why src/core/editor-feature_diagnostics.adb tests/src/editor-diagnostics_review_ux-tests.adb` |
| Render model | `tools/bin/test_commands_for --why src/core/editor-render_model.adb tests/src/editor-render_model-tests.adb` |
| Product smoke driver | `tools/bin/test_commands_for --why tests/e2e/editor_product_smoke.adb` |

For tight reruns after a slice has already been built, append `--no-build` to
skip GPRbuild and execute the existing slice binary.
Run slice builds serially; the GNAT static-library archive update is shared
within each project build directory.

Some surfaces intentionally add companion slices. Diagnostics projection changes
run their primary diagnostics slice plus editor-ui, and now add build-tools when
Build UI diagnostic rows can change. Build UI action changes run build-tools,
add diagnostics-problems for diagnostic routing, and add editor-ui for input and
render-surface coverage. `tools/bin/test_commands_for --why` prints these as
`companion=` and `additional=` entries so the extra coverage is visible.

## Focused Smoke Commands

Routine development should prefer the focused smoke command that matches the
changed workflow instead of running the full product smoke by habit:

| Workflow | Command |
| --- | --- |
| Quick Open and File Tree navigation | `tools/bin/product_smoke_quick_open_file_tree` |
| Edit and save workflow | `tools/bin/product_smoke_edit_save` |
| Daily editing workflow | `tools/bin/product_smoke_daily_editing` |
| Workspace session save/restore/clear | `tools/bin/product_smoke_workspace_session` |
| Dirty lifecycle and persistence guards | `tools/bin/product_smoke_dirty_lifecycle_persistence` |
| Build UI interaction | `tools/bin/product_smoke_build_ui_interaction` |
| Command Palette ranking and execution | `tools/bin/product_smoke_command_palette_ranking` |
| Diagnostics and Problems filters | `tools/bin/product_smoke_diagnostics_problems` |
| Diagnostic quick-fix workflow | `tools/bin/product_smoke_diagnostic_quick_fix` |
| Build and Diagnostics navigation | `tools/bin/product_smoke_build_diagnostics` |
| Render packet non-empty/ABI boundedness | `tools/bin/product_smoke_render_packet` |
| Focused smoke wrapper isolation | `tools/bin/product_smoke_focus_selftest` |
| Dogfood editor workflow gate | `tools/bin/editor_workflow_gate --quick` |

`tools/bin/product_smoke` remains the combined product workflow smoke and is
part of the release gate. Each focused smoke command forwards a scenario name to
`tests/bin/editor_product_smoke` and stops after that workflow's marker, so these
are the normal development entry points when only one product workflow changed.
Run `tools/bin/product_smoke_focus_selftest` after changing the focused smoke
wrappers or slice resolver so wrapper marker isolation stays covered without
running the full release gate.
Run `tools/bin/editor_workflow_gate --quick` when a change crosses normal editor
workflows; it chains the focused product smokes for project opening, Quick Open,
editing, workspace restore, command palette, Problems, Build UI, diagnostics, and
render packet coverage while keeping `tools/bin/unit_tests all` release-only.

Use `tools/bin/test_commands_for --why <changed-path>...` when a change crosses
several areas. It prints the selected focused commands and a short reason for
each path so the relevant slice, focused smoke, and workflow gate are visible.
It also prints a compact `# run next:` block and recommends
`tools/bin/editor_workflow_gate --quick` when changed paths cross multiple
slices or focused smokes.

When scanning live code for follow-up work, exclude generated and archived
material such as `docs/archive`, `obj`, `bin`, `tools/bin`, `lib`, and
`README_PASS*.txt`. Those paths can contain historical or generated text that is
useful for release records but noisy for day-to-day editor work.
Active Ada units must stay free of historical numbered pass names. Follow
`docs/legacy_pass_migration.md` when touching migrated RM validation units; the
case-style names must remain coherent across files, packages, tests, and source
lists.
Use `tools/bin/source_status` for a filtered source-oriented status view when
the raw Git status includes generated artifacts or archived release evidence.
For example, `tools/bin/source_status --only tools` shows only tool changes.
The first two lines report total actionable entries, generated artifact filters,
archive-only filters, and per-category counts, so large dirty worktrees can be
reviewed without scrolling through every path.
Add `--only source`, `--only tests`, `--only tools`, `--only docs`,
`--only project`, `--only other`, `--only renames`, `--only generated`, or
`--only archive` to display one category while keeping the same
actionable/generated summary counts.

## Focused Validation Matrix

Use this matrix as the human-readable companion to
`tools/bin/test_commands_for`. The helper should print these same routine
development gates for matching changed paths.

| Changed surface | Routine validation |
| --- | --- |
| Core editing, buffers, files, navigation | `tools/bin/unit_tests editor-core` |
| UI rendering, palette, keybindings, panels, focus | `tools/bin/unit_tests editor-ui` |
| Project, file tree, project search, workspace lifecycle | `tools/bin/unit_tests project-workspace` |
| Problems, diagnostics, diagnostics review UX | `tools/bin/unit_tests diagnostics-problems` |
| Build UI, terminal tasks, producers, command extensions | `tools/bin/unit_tests build-tools` |
| Ada parser, outline, syntax | `tools/bin/unit_tests ada-parser-outline` and `tools/bin/language_validation_check` |
| Ada language service integration | `tools/bin/unit_tests ada-language-service` |
| Ada semantic legality and language model | `tools/bin/unit_tests ada-language` |
| Ada RM audit/remediation/release validation | `tools/bin/unit_tests ada-rm-validation` |
| Text buffer primitives | `tools/bin/unit_tests text` |
| Build UI product workflow | `tools/bin/product_smoke_build_ui_interaction` |
| Command Palette ranking and execution workflow | `tools/bin/product_smoke_command_palette_ranking` |
| Diagnostics Problems product workflow | `tools/bin/product_smoke_diagnostics_problems` |
| Diagnostic quick-fix product workflow | `tools/bin/product_smoke_diagnostic_quick_fix` |
| Executor diagnostic quick-fix routing | `tools/bin/product_smoke_diagnostic_quick_fix` |
| Build UI input bridge keyboard routing | `tools/bin/product_smoke_build_ui_interaction` |
| Focused smoke wrappers or slice resolver | `tools/bin/product_smoke_focus_selftest` |
| Documentation/testing policy | `tools/bin/check_docs` |
| Generated artifacts or smoke fixtures in status | `tools/bin/check_repo_hygiene` |

## Development Gates

For ordinary changes:

1. Build the changed target or tool.
2. Run `tools/bin/test_commands_for --why <changed-path>...` for the changed files.
3. Run the printed unit-test slice commands and any printed focused smoke or
   workflow-gate commands.
4. Run `tools/bin/check_repo_hygiene` when generated artifact or smoke fixture
   paths appear in status output, or after adding focused executor test
   packages.
5. Run any additional dedicated gate for that surface, such as
   `tools/bin/language_validation_check` for Ada language work.

Do not run `tools/bin/unit_tests all` for routine development changes.

Generated Ada build artifacts are not release evidence. Keep `.ali`, `.o`,
`.a`, `lib/`, `obj/`, `bin/`, `tools/bin/`, and historical `README_PASS*.txt`
files out of normal changes; rebuild them locally as needed.

## Release Gates

For release validation:

1. Run `tools/bin/release_commands` to print the release-only command sequence.
2. Build `tools/editor_tools.gpr`.
3. Run `tools/bin/unit_tests all`.
4. Run `tools/bin/language_validation_check`.
5. Run `tools/bin/release_check`.
6. Run the runtime/product smoke gates required by the release checklist.

`tools/bin/release_check` invokes the full AUnit aggregate through
`tools/bin/unit_tests all`; that is the intended full-suite path.
