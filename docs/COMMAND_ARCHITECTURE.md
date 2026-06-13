# Command Architecture Overview

The editor command system is intentionally descriptor-driven. A command should be added in one place as a stable `Editor.Commands.Command_Id`, then wired through metadata, availability, execution, routing, keybindings, command-palette projection, side-effect tests, and message policy. Phase 112 adds audit helpers so future command drift fails with the command id and the missing contract rather than as a vague command-palette or executor regression.

## Registry invariants

* `No_Command` is the only sentinel and is excluded from concrete traversal.
* `First_Concrete_Command`, `Concrete_Command_Count`, and `For_Each_Command` are the preferred audit traversal helpers.
* Descriptor metadata is the source of command-palette label, category, visibility, bindability, and classification.
* Stable command names are persistence identifiers. They are not labels and must not be derived from command-palette rows.
* Hidden commands may be bindable when they represent intentional user-invokable behavior. Internal/sentinel commands must not be bindable.

## Descriptor contract

Each concrete command must have:

1. A descriptor whose `Id` equals the enum value.
2. A non-empty, trimmed, non-placeholder label.
3. A non-empty, trimmed description.
4. A non-empty category label.
5. Explicit visibility and bindability.
6. Explicit destructive/lifecycle/configuration classification where applicable.

`Make_Command_Descriptor` exists for tests and future cleanup work where explicit descriptor construction is clearer than handwritten aggregates. It deliberately receives a `Stable_Name` argument only as an audit-facing reminder: persisted names remain owned by `Stable_Command_Name` and `Command_Id_From_Stable_Name`.

## Executor handling contract

`Editor.Executor` is the single audited boundary for user command execution. Command-like UI paths should dispatch a stable command id into the executor instead of mutating subsystems directly. Domain helpers should return status/summary values where possible; the executor maps those values to command results and transient messages.

Execution outcomes must distinguish:

* unavailable command: availability prevented execution before mutation;
* failed command: execution was attempted and failed cleanly;
* no-op command: explicitly documented no-change success case;
* executed command: command completed normally.

Unhandled commands are not no-ops.

## Availability contract

Availability checks must be side-effect-free. They may inspect editor state, but they must not emit messages, mutate focus, update settings/keybindings, touch project state, or repair invalid state. Visible commands need availability results in empty, project-open, and project-with-buffer fixtures where practical.

## Message policy

The executor decides when to emit command outcome messages. Subsystem helpers should avoid emitting duplicate command messages for command-called paths. Critical wording for settings, keybindings, workspace, recent-project, dirty/pending, file save/discard, and unavailable workflows should remain centralized enough that tests catch accidental drift.

## Route policy

Command-like routes include keybindings, command palette, pending bar, file tree, recent-project picker, search results, problems panel, tab bar, and other UI actions that represent editor commands. Route audit helpers classify failures such as wrong command dispatch, duplicate dispatch, executor bypass, availability bypass, dirty-guard bypass, duplicate messages, and stale keybinding table usage.

## Save-command distinctions

These commands intentionally write different domains:

| Command | Domain written | Notes |
| --- | --- | --- |
| Save File | Active file contents | Writes active file-backed buffer contents. |
| Save All | File contents | Writes dirty file-backed buffers. |
| Save Workspace State | Workspace/session structure | Writes structural project/session state, not file contents. |
| Save Settings | Global settings file | Writes editor preferences. |
| Save Keybindings | Global keybinding file | Writes command keybinding mappings. |

Descriptions, command-palette details, messages, and side-effect tests should keep these distinctions visible.

## New command checklist

1. Add `Command_Id`.
2. Add descriptor metadata: label, description, category, visibility, bindability, and classifications.
3. Confirm stable name if bindable.
4. Add availability handling.
5. Add executor handling or explicitly mark the command internal/non-executable.
6. Add default keybinding or intentionally skip one.
7. Add command-palette projection tests if visible.
8. Add route tests for any UI source that invokes it.
9. Add side-effect and message tests if it mutates state.
10. Add failure-before-mutation tests for high-risk lifecycle, destructive, save, settings, keybinding, workspace, or dirty/pending commands.
11. Run command audit and future-command guard tests.

## Representative command classes

### Simple global view toggle

* id: a `Command_Toggle_*` enum value
* category: `View_Category`
* visible: usually yes
* bindable: yes when user-invokable
* availability: usually always available
* executor: toggles only the relevant runtime/view setting
* message policy: at most one outcome message
* tests: descriptor, availability side-effect-free, palette projection, setting/view side effect

### File-content command

* id: e.g. `Command_Save_File`
* category: `File_Category`
* lifecycle/configuration: false
* availability: requires an active file-backed dirty/clean buffer depending on command
* executor: owns save attempt and result-message mapping
* tests: failure-before-mutation, dirty-state update, file identity preserved, message baseline

### Dirty-guarded lifecycle command

* id: e.g. `Command_Close_Project`
* category: `Project_Category`
* lifecycle: true
* destructive: true if it can discard/close unsaved state
* availability: project/pending state dependent
* executor: must use dirty guards and pending-transition workflow
* tests: blocked transition, retry/cancel route, no persisted pending transition

### Configuration command

* id: e.g. `Command_Save_Settings` or `Command_Reload_Keybindings`
* category: `Settings_Category`
* configuration: true
* availability: available without a project
* executor: writes/loads/validates only the intended global configuration domain
* tests: settings/keybindings separation, message baseline, repeated reload/reset stability

### Destructive command

* id: e.g. `Command_Clear_Recent_Projects`
* destructive: true
* executor: explicit side effect and one canonical message
* tests: domain isolation, no unrelated buffer/project mutation

### Panel/navigation command

* category: `Panel_Category`, `Navigation_Category`, or `Search_Category`
* availability: panel/result dependent where relevant
* executor: changes focus/selection/navigation only
* tests: route dispatch, panel state mutation, editor text unchanged

### Hidden bindable command

* visible: hidden
* bindable: true
* use when command is intended for keybindings but not command-palette discovery
* tests: stable name exists, keybinding config can target it, palette omits it

### Hidden non-bindable internal command

* visible: hidden
* bindable: false
* use for sentinel/internal-only actions only
* tests: cannot be bound and never appears in palette

## Side-effect matrix guidance

Phase 112 keeps the side-effect matrix test-owned. High-risk commands should declare expected mutation domains using names such as buffers, dirty state, project, workspace file, settings file, keybindings file, recent projects, pending transition, messages, keybindings runtime, settings runtime, project-scoped UI, search state, panel state, and no domain.

# Phase 113 command extension readiness

Phase 113 prepares the command system for the next feature arc without reserving unfinished production commands. New functionality should be integrated through templates, test fixtures, and audit helpers first; production placeholder command ids should be avoided unless the command already has intentional descriptor, availability, executor, visibility, bindability, and message semantics.

## Architecture map

`Command_Id` is the static identity used by the whole command system. `Command_Descriptor` owns label, description, category, palette visibility, bindability, and high-risk classification. `Stable_Command_Name` is the persisted keybinding id and must not change when labels change. `Command_Availability` is a side-effect-free state check. `Execute_Command` and `Execute_Command_With_Result` are the central mutation boundary. `Command_Palette` projects descriptor metadata, executor availability, and active runtime keybindings. `Keybindings` resolves active chords to command ids. `Input_Bridge` preserves input priority and dispatches command ids. `Messages` presents one primary command outcome.

Subsystems may own domain logic, but they should not know command-palette row layout, parse keybinding files, emit duplicate command outcomes for executor-called paths, or mutate editor-global command domains outside the executor route.

## Route policy map

Command-routed interactions:

* keybinding command chords;
* command-palette accept;
* pending bar action buttons;
* settings, keybinding, workspace, project, recent-project, save, discard, reset, clear, reload, and validate commands;
* panel result openings where the action is command-owned;
* file tree keyboard open/refresh actions;
* quick-open accept;
* find/replace and project-search actions that execute editor commands.

Local interactions that may remain direct:

* text insertion into an input field;
* raw editor text insertion before it becomes an editor command;
* mouse caret placement and drag selection;
* scrollbar, minimap, splitter, hover, hit testing, and render projection mechanics;
* local list selection movement when it does not open, save, discard, clear, reload, reset, or mutate a command-owned lifecycle domain.

The rule of thumb is: local pointer/list mechanics may stay local; opening files/projects, clearing state, saving, discarding, reloading, resetting, and guarded lifecycle transitions must route through a stable command id and the executor.

## Domain side-effect map

| Domain | Mutated by |
| --- | --- |
| File contents | save, save-as, save-all, edit/cut/paste/replace commands |
| Dirty state | file open/save/save-as/save-all/discard/edit commands |
| Project lifecycle | open/close/clear project, retry pending project transitions |
| Project-scoped UI | file tree, quick open, project search, search-results project views |
| Workspace structural session | save/restore/clear workspace-state commands only |
| Global settings runtime | settings toggle/set/reset/reload commands only |
| Global settings file | save settings command only |
| Global keybindings runtime | reload/reset/apply keybinding commands only |
| Global keybindings file | save keybindings command only |
| Recent projects | successful project-open/recent-project clear/remove commands |
| Pending transitions | dirty-guarded lifecycle block/retry/cancel commands |
| Panel/search UI state | explicit search, project-search, focus, result navigation commands |
| Messages | executor command outcome helpers |

Future tests should declare expected domains before mutating command tests pass. A command that accidentally changes a non-allowed domain should fail with the command id, domain name, and test context.

## Command-family templates

Each template below is intentionally concrete enough to copy. Replace the example id/name while preserving the checklist shape.

### Simple view toggle command

* `Command_Id`: add `Command_Toggle_<Feature>` only when the feature already exists.
* Descriptor: label `Toggle <Feature>`, stable name `toggle-<feature>`, `View_Category`, `Palette_Command`, `Bindable => True`, no destructive/lifecycle/configuration classification.
* Availability: usually `Available`; it must not inspect renderer timing, hover, blink, atlas, or pointer state.
* Executor handler: call the smallest stable view/settings helper under `Editor.Executor`; invalidate render projection if needed; do not mutate buffers, project, workspace, recent projects, or keybindings.
* Message policy: zero or one concise outcome message. Do not let both the subsystem and executor report the same toggle.
* Side-effect domain: `Domain_Settings_Runtime` or `Domain_Render_Projection` only, plus `Domain_Messages` if a message is emitted.
* Keybinding default: optional. If provided, target the stable command name, not the label.
* Palette expectation: row label/category/description come from `Editor.Commands.Descriptor`; availability comes from executor; keybinding display comes from active runtime keybindings.
* Route audit: keybinding and palette routes must dispatch the command id once and then enter the executor.
* Tests to add: descriptor completeness, availability read-only, metadata fingerprint unchanged, focused side-effect domain assertion, palette projection source assertion.

### Configuration command

* `Command_Id`: `Command_Save_Settings`, `Command_Reload_Keybindings`, `Command_Reset_*`, or equivalent.
* Descriptor: `Settings_Category`, `Palette_Command`, `Bindable => True` only for deliberate user commands, `Configuration => True`; add `Destructive => True` for resets/clears that discard user configuration state.
* Availability: independent of project/buffer state unless the config command genuinely requires an active context.
* Executor handler: load/save/reset/validate exactly one configuration domain. Settings commands must not mutate keybindings; keybinding commands must not mutate settings.
* Message policy: executor maps status to one message such as saved, reloaded, reset, invalid, unsupported version, read/write error, or partial load.
* Side-effect domain: settings commands use `Domain_Settings_Runtime`/`Domain_Settings_File`; keybinding commands use `Domain_Keybindings_Runtime`/`Domain_Keybindings_File`; both may use `Domain_Messages`.
* Keybinding default: conservative; avoid defaults for destructive reset commands unless there is a strong reason.
* Palette expectation: visible commands are descriptor-driven and disabled only by executor availability.
* Route audit: command palette and keybinding dispatch must not parse config files directly.
* Tests to add: partial-load preservation, hard-failure preservation, separation from workspace/recent/project/dirty state, normalized save drops invalid future entries.

### File-content command

* `Command_Id`: `Command_Save_File`, `Command_Save_File_As`, `Command_Save_All`, or future file-content operations.
* Descriptor: `File_Category`, `Palette_Command` for discoverable commands, usually bindable; not `Configuration`; not workspace save.
* Availability: active buffer/file-backed/dirty criteria must be explicit and side-effect-free.
* Executor handler: perform file IO or delegate to file helpers, then update file identity, dirty flag, dirty-line baseline, buffers, and one message.
* Message policy: success/failure wording comes from executor/file command helpers, not from the command palette or keybindings.
* Side-effect domain: `Domain_Buffers`, `Domain_Dirty_State`, file-content side effects, and `Domain_Messages`; never `Domain_Workspace_File`, `Domain_Settings_File`, or `Domain_Keybindings_File`.
* Keybinding default: common file-content commands may get defaults, but they must target stable names.
* Palette expectation: save-file/save-all/save-workspace/save-settings/save-keybindings descriptions must remain distinct.
* Route audit: save-like UI actions route to the proper command id and respect availability.
* Tests to add: dirty state transition, failure-before-mutation for failed save, file identity preserved, save domains are not confused.

### Dirty-guarded lifecycle command

* `Command_Id`: `Command_Open_Project`, `Command_Close_Project`, `Command_Clear_Project`, `Command_Restore_Workspace_State`, or future guarded lifecycle commands.
* Descriptor: lifecycle commands set `Lifecycle => True`; commands that may close/discard/clear state also set `Destructive => True`.
* Availability: project/pending/recent/workspace existence checks only; no dirty guard mutation here.
* Executor handler: call dirty guards before lifecycle mutation; if blocked, create a pending transition and return one blocked-transition message. Retry/cancel must route through command ids.
* Message policy: one primary message: blocked, cancelled, retried, opened, closed, cleared, restored, or failed.
* Side-effect domain: `Domain_Project`, `Domain_Project_Scoped_UI`, `Domain_Buffers`, `Domain_Dirty_State`, `Domain_Pending_Transition`, `Domain_Recent_Projects`, `Domain_Messages` as explicitly required.
* Keybinding default: conservative; destructive lifecycle commands usually do not need aggressive defaults.
* Palette expectation: disabled reason comes from availability; dirty-blocking is execution-time guard behavior.
* Route audit: pending bar, recent picker, file tree, quick open, and palette routes must not mutate lifecycle state before executor entry.
* Tests to add: clean path, dirty-blocked path, pending retry, pending cancel, stale target invalidation, route enters executor exactly once.

### Destructive command

* `Command_Id`: clear, discard, close, reset, remove, or delete-like command.
* Descriptor: `Destructive => True`; description must mention the concrete clear/discard/reset/close/remove effect.
* Availability: side-effect-free and precise enough to disable impossible destructive actions.
* Executor handler: mutation must occur only after availability/dirty guard checks; high-risk failures must happen before mutation.
* Message policy: executor emits exactly one outcome message.
* Side-effect domain: explicit and narrow; destructive does not imply permission to mutate unrelated domains.
* Keybinding default: avoid unless conventional or already established.
* Palette expectation: destructive classification is explicit metadata, not inferred from strings.
* Route audit: routes must respect availability and dirty guards.
* Tests to add: classification check, description wording check, side-effect domain isolation, failure-before-mutation.

### Navigation command

* `Command_Id`: cursor, diagnostic, bookmark, result-list, or file-tree navigation command.
* Descriptor: `Navigation_Category`, `Diagnostics_Category`, `Bookmarks_Category`, `Search_Category`, or panel-specific category.
* Availability: active buffer/result/panel checks where needed.
* Executor handler: move selection/caret/result cursor/focus only; do not mutate file contents unless the command is an explicit open/accept action.
* Message policy: usually no message unless unavailable or wrapping behavior is intentionally user-visible.
* Side-effect domain: panel/search state or caret/navigation state only.
* Keybinding default: appropriate for common movement commands.
* Palette expectation: hidden movement commands may be bindable; visible navigation commands need complete descriptions.
* Route audit: list selection movement may remain local; opening the selected item is command-routed.
* Tests to add: no buffer text mutation, availability changes after state changes, hidden bindable behavior where applicable.

### Panel/focus command

* `Command_Id`: focus editor/file tree/problems/search results, toggle panel, move result selection.
* Descriptor: `Panel_Category`, bindable for focus commands, visible for discoverable panel commands.
* Availability: panel existence/result availability checks only.
* Executor handler: update `Editor.Panel_Focus`, panel visibility, or panel-local selection. Do not open files directly from panel code; use command-routed open-selected actions.
* Message policy: usually no message for focus-only commands.
* Side-effect domain: `Domain_Panel_State`, optionally `Domain_Search_State` for result selections.
* Keybinding default: useful for focus switching where stable.
* Palette expectation: focus commands can be visible; low-level move commands may stay hidden but bindable.
* Route audit: panel open-selected routes dispatch exactly one command id to the executor.
* Tests to add: focus state changes, active buffer unchanged, route equivalence from keyboard/palette/panel.

### Hidden bindable command

* `Command_Id`: low-level movement/edit/focus action useful for keybindings but not palette discovery.
* Descriptor: `Hidden_Command`, `Bindable => True`, stable name required, complete label/description still required for audits and future keybinding UI.
* Availability: side-effect-free as for visible commands.
* Executor handler: complete handling required; hidden is not a shortcut around executor coverage.
* Message policy: same as visible command family.
* Keybinding default: allowed when the command is user-invokable.
* Palette expectation: omitted from command-palette traversal.
* Tests to add: stable name, bindability accepted by keybinding config, palette omission, executor handling exists.

### Hidden non-bindable internal command

* `Command_Id`: avoid production ids unless there is an actual internal route. Prefer test fixtures for future placeholders.
* Descriptor: `Hidden_Command`, `Bindable => False`, `Internal_Category` only when genuinely internal.
* Availability: if executable, still covered. If not executable, do not add it as a normal production command.
* Executor handler: either explicit no-op/unavailable behavior with documentation, or no production id.
* Message policy: no user-facing messages unless it can be user-invoked through a documented route.
* Keybinding default: none; keybinding config must reject it.
* Palette expectation: never visible.
* Route audit: internal routes must still not bypass executor for command-owned domains.
* Tests to add: keybinding rejection, palette omission, no accidental default binding.

## Future-command sentinels

Use test-only fake descriptors, fake route audit results, and keybinding files containing unknown stable names. Do not add incomplete production command ids just to reserve names. Sentinel tests should prove these failure classes remain actionable:

* missing descriptor;
* missing stable command name;
* missing availability;
* missing executor handling;
* non-bindable command in keybinding config;
* destructive command missing destructive classification;
* configuration command routed through the wrong domain;
* route bypasses executor.

Unknown command names in keybinding files must be diagnosed/ignored, must not create placeholder commands, and must not corrupt the active runtime table. A partial file may still load valid entries.

## New-command checklist enforcement

A new user command is not done until these checks pass:

1. concrete `Command_Id` exists and is traversed;
2. descriptor is complete and unique enough for audits;
3. bindable commands have stable names and keybinding acceptance tests;
4. availability handler exists and is side-effect-free;
5. executor handling exists and produces one primary outcome;
6. visible commands have descriptor-driven palette rows;
7. UI routes dispatch command ids and enter executor once;
8. high-risk commands have explicit classification;
9. side-effect domain tests permit only intended domains;
10. failure-before-mutation tests exist for destructive/lifecycle/configuration/file IO commands.

## Executor extension boundaries

`Execute_Command_With_Result` remains the public command execution boundary. Internal grouping comments may divide command families into file, edit, search, project, workspace, settings, keybinding, pending, panel, and navigation sections, but those helpers must stay under executor ownership. They must not become public mutation bypasses, and availability functions must remain read-only.

When the current executor section is readable enough, prefer comments and tests over mechanical churn. Refactor only when helper extraction makes side effects easier to audit.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
