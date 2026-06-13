# Commands

Commands are registered through stable `Editor.Commands.Command_Id` values, descriptor metadata, stable persisted names, bindability policy, command-palette projection, availability checks, and executor routing.

The outline command family is a current daily-use product surface:

| Stable name | Label | Category | Current behavior |
| --- | --- | --- | --- |
| `outline.refresh` | Refresh Outline | Panels | Requires an active buffer, snapshots current in-memory text, extracts parser-backed Ada language-model declaration rows, replaces outline items on success, projects them into the feature panel, shows the panel, and does not focus it. |
| `outline.clear` | Clear Outline | Panels | Clears outline items and feature-panel rows. |
| `outline.show` | Show Outline | Panels | Shows the feature panel without refreshing outline data; unavailable when already shown. |
| `outline.focus` | Focus Outline | Panels | Focuses the visible feature panel; unavailable when hidden or already focused. |
| `outline.open-selected` | Open Selected Outline Item | Panels | Requires a visible feature panel and selected row mapping to the current outline projection; validates the active-buffer target, returns focus to text, moves the caret, and reveals the target declaration. |
| `outline.select-next` / `outline.filter.next-match` | Select Next Outline Symbol | Panels | Moves Outline selection to the next visible selectable row and requests reveal in the feature panel. |
| `outline.select-previous` / `outline.filter.previous-match` | Select Previous Outline Symbol | Panels | Moves Outline selection to the previous visible selectable row and requests reveal in the feature panel. |

These commands are executable without default keybindings and can be bound by user keybinding configuration through their stable names.

Canonical messages include `Outline refreshed`, `Outline cleared`, `Outline shown`, `Outline focused`, `Outline current symbol revealed`, and `Outline item has no target`. Canonical unavailable reasons include `No active buffer`, `No outline items`, `No outline item selected`, `Feature panel hidden`, `Feature panel already shown`, `Feature panel already focused`, and `Outline belongs to another buffer`.

Availability checks must be side-effect-free: they do not refresh outline state, project rows, show/focus panels, mutate selection, emit messages, inspect source text, parse files, or repair stale feature-panel rows. Command palette, keybinding dispatch, direct executor calls, and feature-panel Enter routing must all dispatch outline command-like actions through `Command_Id` and `Editor.Executor` without adapter messages.

Descriptor text may describe the parser-backed Ada language-model extractor and selected-row navigation, but it must not claim GNAT-equivalent legality checking, automatic background project scans, LSP semantics, or refactoring support.

## Phase 385 current-line indentation commands

Phase 385 adds two narrow Edit commands for active-buffer current-line indentation only:

| Stable name | Label | Category | Phase 385 behavior |
| --- | --- | --- | --- |
| `edit.indent.increase` | Indent Line | Edit | Inserts one hardcoded two-space indentation unit at the start of the caret's current logical line. Empty buffers report `Nothing to indent` and create no undo entry. |
| `edit.indent.decrease` | Outdent Line | Edit | Removes one leading two-space unit, partial leading spaces below one unit, or one literal leading tab from the caret's current logical line. Lines without removable indentation report `Nothing to outdent` and create no undo entry. |

Both commands are stable-name, bindable, Command Palette visible text-edit commands routed through `Editor.Executor` and `Editor.Input_Bridge`.  Text-changing execution uses the canonical active-buffer replace-batch mutation path, creates one undoable edit, updates dirty state, invalidates active Find/Replace state through the existing text-edit hook, collapses selection through the canonical mutation policy, and preserves Clipboard and Navigation History boundaries.

Phase 385 deliberately does not add selected-line indentation, block indentation, smart indentation, auto-indent, formatting, tab-width settings, tabs/spaces conversion commands, indentation guides, language-aware behavior, diagnostics, LSP integration, file watching, or any new persistence domain.  Workspace, settings, and recent-project persistence do not store indentation command status, last indented line, availability state, or indentation unit overrides; keybindings may only persist the stable command names if the user binds them.

## Phase 579 IDE-grade language commands

The Ada language-analysis command surface is canonical and intentionally uses dot-form product names only:

- `outline.refresh-project-index` refreshes the transient Ada language index from known project Ada source files, using the active buffer snapshot for the current file when applicable.
- `outline.goto-declaration` opens the validated declaration target for the selected Outline row.
- `outline.goto-body` opens an indexed package, ordinary subprogram, or generic subprogram body target for the selected Outline row when an explicit project language-index refresh has retained a matching body.
- `outline.goto-spec` opens an indexed package, ordinary subprogram, or generic subprogram spec target for the selected body Outline row when an explicit project language-index refresh has retained a matching spec.
- `semantic.refresh-buffer` rebuilds active-buffer semantic-colouring data from the parser-owned Ada language model.
- `semantic.refresh-project-index` refreshes known project Ada source files in the transient language index and updates active-buffer semantic data from its immutable snapshot.
- `language.index.clear` clears the transient in-memory Ada language index.
- `language.index.status` reports indexed file count, symbol count, overflow state, and fingerprint.

These commands do not add aliases, do not save or reload files, and do not perform rendering-side parsing.

Pass 176 completes generic subprogram spec/body navigation for the canonical Outline commands by stripping `generic subprogram` labels and accepting `Symbol_Generic_Subprogram` project-index targets with parser-owned `Is_Body` metadata.

### pass 177 separate-body `outline.goto-spec`

`outline.goto-spec` now handles selected `separate body` Outline rows when the transient Ada project index contains both the subunit body and its retained parent declaration. The command resolves the selected separate-body row, reads the parser-owned parent `Target_Name`, resolves that parent in the project index, and navigates only to a non-body parent declaration.

### pass 178 validated separate-body parent targets

`outline.goto-spec` for `separate body ...` rows now validates the resolved parent candidate with `Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target`. The command remains unavailable when the retained parent name resolves only to objects, components, literals, body rows, or another separate body.

### Phase 579 pass 179 edit invalidation

Language-index commands remain explicit, but ordinary text edits now invalidate the active source path and buffer token inside the transient Ada project index. Navigation commands such as `outline.goto-body` and `outline.goto-spec` therefore require a refreshed index after edits before they can use parser-owned cross-file targets again.

### Phase 579 pass 180 visible-range semantic rebuild

The `semantic.refresh-buffer` command and automatic visible-range syntax preparation now share the same parser-owned Ada language-model semantic source. Automatic preparation does not use the command dispatcher and does not mutate files, but it rebuilds the bounded semantic map from `Editor.Ada_Declaration_Parser.Parse` for the active snapshot when semantic ownership stamps are stale.

### Phase 579 pass 181 completeness: semantic lookup prefix safety

The semantic refresh commands continue to build bounded in-memory maps. Pass 181 ensures those maps reject overlong lookup tokens as well as overlong declarations, preventing prefix-collision colouring after `semantic.refresh-buffer` or `semantic.refresh-project-index`.

### Phase 579 pass 182 completeness: language index lifecycle safety

The language-index commands remain explicit refresh operations. Pass 182 completes their lifecycle safety by invalidating indexed rows after active-buffer rename/move/delete and File Tree create/rename/delete. `outline.goto-body`, `outline.goto-spec`, and semantic refresh commands therefore cannot reuse project-index entries for files that were moved, deleted, or rebased through editor workflows.

Phase 579 pass 183 completeness: language-index lifecycle commands and file lifecycle hooks now share normalized exact-path invalidation. `language.index.status` therefore cannot report stale indexed Ada rows after reload/revert/save-as/rename/move only because the invalidation path used `\` separators or a trailing separator while the project refresh stored `/` separators.

### Phase 579 pass 184 open-buffer project-index overlay

`outline.refresh-project-index` and `semantic.refresh-project-index` now index
known project Ada source files and then overlay open file-backed Ada buffers from
editor-owned snapshots.  Inactive open buffers with unsaved text are therefore
part of explicit project-wide language refresh without saving, reloading, or
mutating dirty state.

### Phase 579 pass 185 open-buffer project-index priority

`outline.refresh-project-index` and `semantic.refresh-project-index` now index open Ada buffers before scanning remaining project files from disk. The commands still use explicit bounded refresh only, but open-buffer snapshots have priority over filesystem contents and normalized path containment prevents a later disk row from replacing an already indexed editor-owned buffer row.

### Phase 579 pass 186 profile-aware `outline.goto-body` / `outline.goto-spec`

`outline.goto-body` and `outline.goto-spec` now use retained callable profile summaries as an overload disambiguation filter when available. The commands remain conservative and do not claim compiler-grade overload resolution, but indexed procedure/function targets with a different parser-owned profile from the selected Outline row are no longer accepted as body/spec targets.

### Phase 579 pass 187 profiled callable target safety

`outline.goto-body` and `outline.goto-spec` are now stricter for selected
callable rows that include parser-owned profile summaries.  A profiled selected
row requires the indexed callable target to retain a matching profile; an
unprofiled same-name candidate is treated as ambiguous and is not used as the
navigation target.


## Phase 579 pass 188 semantic scope retention

Pass 188 does not add new commands. It strengthens the behaviour behind `semantic.refresh-buffer`, `semantic.refresh-project-index`, and normal visible-range rendering by retaining parser-owned analysis in transient editor state and using conservative token-position scopes for semantic lookup.

### Phase 579 pass 189 semantic scope-range safety

The semantic refresh and visible-range preparation paths continue to retain parser-owned analysis, and scoped lookup now honours retained source-range ends. Language-index and Outline navigation commands therefore share the same conservative degradation model when a parser-owned owner no longer contains the queried token position.

### Phase 579 pass 190 scoped semantic bounded-name safety

No command surface changes were added. `semantic.refresh-buffer`, `semantic.refresh-project-index`, and visible-range rendering now share the same conservative overlong-identifier policy: scoped language-model lookup refuses overlong token names and falls back to lexical identifier classification instead of resolving parser-retained overlong symbols.

### Phase 579 pass 193 unique indexed navigation targets

`outline.goto-body` and `outline.goto-spec` now use a shared project-index helper that returns a target only when the retained name/kind/body-side/profile filters identify exactly one indexed symbol.  If duplicate package or callable candidates still match after filtering, the command remains unavailable instead of choosing the first indexed row.

### Phase 579 pass 196 overflow-safe indexed Outline commands

`outline.goto-body` and `outline.goto-spec` remain unavailable when the Ada language index is over budget or contains an overflowed per-file analysis, even if one retained target appears to match. Separate-body parent navigation also rejects overflow and duplicate parent candidates. The commands therefore keep the previous deterministic target policy without guessing from an incomplete index.

## Phase 579 pass 200 completeness: body/spec command target revalidation

`outline.goto-body` and `outline.goto-spec` revalidate the exact project-index target key at execution time. If the language index was cleared, refreshed, overflow-invalidated, or stale due to an open-buffer revision/lifecycle change after availability was computed, the commands degrade to unavailable instead of navigating to the old target.

### Phase 579 pass 201 declaration navigation availability

`outline.goto-declaration` and `outline.open-selected` now use the same live-target validation during command availability that execution already used during activation. A selected Outline row is not advertised as available unless its retained declaration target still maps to a live buffer and an in-range source position. Stale or out-of-range declaration rows therefore degrade before execution instead of appearing available and then failing at activation time.

### Phase 579 pass 202 normalized indexed navigation execution

`outline.goto-body` and `outline.goto-spec` now use normalized path comparison when executing an already validated project-index target. Target-key revalidation still rejects stale or wrong-buffer targets, but a live target is no longer rejected only because the active editor path and the indexed path use different separator spellings.

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
