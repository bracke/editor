# Product Workflow

Phase 579 defines the daily editor loop as one connected product path. This document is the concrete reference for command discovery, prompts, status wording, focus transitions, persistence behavior, and integrated workflow tests. It describes existing supported behavior and the intended product surface; it is not a new runtime subsystem.

## Status vocabulary

Use these user-facing messages for normal workflow results and precondition failures:

- Project opened.
- Project closed.
- Project switch cancelled.
- Workspace restored.
- No project open.
- File opened.
- File saved.
- File reloaded.
- File reverted.
- File created.
- Directory created.
- File or directory renamed.
- File or directory deleted.
- Buffer closed.
- Dirty buffer preserved.
- Operation cancelled.
- Search complete.
- No search results.
- Outline unavailable.
- Build started.
- Build completed.
- Build failed.
- Build Output shown.
- No build output captured.
- Diagnostics updated.
- No diagnostics.
- External modification detected.
- Backing file missing.
- Permission denied.

Normal status output must describe the user-visible condition and next action. It must not expose runtime implementation identifiers, generated object names, test-only wording, or internal implementation terms.

Product command IDs listed below are the daily-use command vocabulary where the workflow is command-driven. Text entry is handled by the editor input path rather than a palette command, and quit is a host application lifecycle action protected by the dirty-close readiness workflow. The product surface should use these names in keybindings, palette references, tests, and user-facing help. Alternate accepted names must resolve to the same command implementation, descriptor label, prompt behavior, status behavior, focus result, and dirty-buffer handling as the primary command they name.

## Core command inventory

These command names are the daily-use product surface. Selection-accept commands are primarily invoked from their owning panel, but they still resolve through the same command resolver so keybindings, palette help, and tests refer to a single command vocabulary.

| Command ID | Product label | Normal discovery |
|---|---|---|
| command-palette.show-command-help | Show Command Help | command palette |
| project.open | Open Project | command palette |
| project.close | Close Project | command palette |
| project.switch | Switch Project | command palette |
| project.reopen-recent | Open Selected Recent Project | Recent Projects panel action |
| file.open | Open File | command palette / explicit path input |
| file.save | Save File | command palette / keybinding |
| file.save-as | Save File As | command palette / prompt |
| file.reload | Reload File | command palette |
| file.revert | Revert File | command palette / confirmation when dirty |
| file-tree.refresh | Refresh File Tree | command palette / File Tree |
| file-tree.open-selected | Open Selected File | File Tree action |
| file-tree.create-file | Create File | command palette / File Tree prompt |
| file-tree.create-directory | Create Directory | command palette / File Tree prompt |
| file-tree.rename | Rename File or Directory | command palette / File Tree prompt |
| file-tree.delete | Delete File or Directory | command palette / confirmation |
| quick-open.show | Quick Open | command palette / keybinding |
| quick-open.open-selected | Open Selected Quick Open Result | Quick Open action |
| search.project | Search Project | command palette / search bar |
| search.open-selected | Open Selected Project Search Result | search results action |
| outline.show | Show Outline | command palette |
| build.run | Run Build | command palette |
| build.cancel | Cancel Build | command palette |
| build.output.show | Show Build Output | command palette |
| build.output.toggle | Toggle Build Output | command palette |
| build.output.hide | Hide Build Output | command palette |
| build.output.focus | Focus Build Output | command palette |
| diagnostics.show | Show Diagnostics | command palette |
| buffer.switch-next | Next Buffer | command palette / keybinding |
| buffer.switch-previous | Previous Buffer | command palette / keybinding |
| buffer.close | Close Buffer | command palette / keybinding |
| buffer.close-all-clean | Close All Clean Buffers | command palette |
| workspace.restore | Restore Workspace | command palette / startup recovery |

## Prompt policy

Every product prompt has a title, short help text, accepted input shape, validation failure message, confirm action, cancel action, post-cancel status, and focus restoration rule. Cancelling a prompt preserves existing text, dirty state, selection, and the previously focused surface.

| Prompt | Accepted input | Confirm | Cancel result |
|---|---|---|---|
| Open Project | project directory path | opens the project through project lifecycle handling | Project open cancelled.; previous focus restored |
| Create File | project-relative file path | creates the file, refreshes File Tree/project file discovery | Create file cancelled.; File Tree focus restored |
| Create Directory | project-relative directory path | creates the directory, refreshes File Tree/project file discovery | Create directory cancelled.; File Tree focus restored |
| Rename File or Directory | new item name or safe relative target supported by current workflow | renames the selected file or directory and updates open-buffer backing path where applicable | Rename cancelled.; File Tree focus restored |
| Delete File or Directory | explicit confirmation | deletes only after lifecycle and dirty-buffer checks | Delete cancelled.; File Tree focus restored |
| Save As | target file path | writes text to the explicit target and associates the buffer | Operation cancelled.; editor focus restored |
| Reload or Revert File | explicit confirmation when dirty | reloads or reverts only after confirmation | Dirty buffer preserved.; editor focus restored |
| External Modification Decision | keep buffer, reload, overwrite, or cancel | applies the selected file lifecycle decision | Dirty buffer preserved.; editor focus restored |
| Dirty Close Review | save, discard, or cancel | closes only after a safe decision | Dirty buffer preserved.; previous focus restored |
| Project Switch Dirty Review | save, discard, or cancel | switches only after a safe decision | Project switch cancelled.; previous focus restored |
| Quit Dirty Review | save, discard, or cancel | quits only after a safe decision | Dirty buffer preserved.; previous focus restored |
| Build Configuration Missing | acknowledgement or configuration action | keeps build output state coherent and actionable | Operation cancelled.; previous focus restored |

## Daily workflow matrix

| Workflow | Command ID | Palette label | Default keybinding | Preconditions | Prompt behavior | Success status | Failure status | Focus result | Workspace persistence effect | Dirty-buffer behavior | Diagnostic/build-output effect |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Empty editor state | command-palette.show-command-help | Show Command Help | none | none | no prompt | Command Palette available. | No command selected. | originating surface | no change | preserves dirty buffers | no change |
| Open project | project.open | Open Project | implementation default if bound | valid project path | Open Project prompt or explicit path input | Project opened. | Project open cancelled. | File Tree, or editor when a restored active file is valid | saves/restores active project identity through workspace rules | blocks if dirty project switch review is required | clears stale project-scoped diagnostics/build state unless intentionally refreshed |
| Open file from File Tree | file-tree.open-selected | Open Selected File | Enter from File Tree | project open and file node selected | no prompt | File opened. | No file selected. | editor buffer | active file may be persisted | focuses existing buffer or opens file-backed buffer; preserves other dirty buffers | no change |
| Open file from Quick Open | quick-open.show / quick-open.open-selected | Quick Open / Open Selected Quick Open Result | implementation default if bound | project open and result selected | query input belongs to Quick Open | File opened. | No file selected. | editor buffer | active file may be persisted | focuses existing buffer or opens file-backed buffer | no change |
| Edit buffer | text input path | Edit Buffer | text input | active editable buffer | no prompt | Buffer edited. | No active buffer. | editor buffer | dirty state is not persisted as text | marks active buffer dirty | marks Outline/Search/Diagnostics stale only where current implementation already tracks it |
| Save buffer | file.save | Save File | implementation default if bound | active file-backed or saveable buffer | Save As prompt only when no backing path exists | File saved. | File could not be saved. | editor buffer | active file remains persisted; dirty text is not persisted separately | clears dirty state on success | no build output change; diagnostics remain explicit |
| Reload buffer | file.reload | Reload File | none | active file-backed buffer | confirmation when dirty | File reloaded. | File could not be reloaded. | editor buffer | no new transient persistence | cancellation preserves dirty text | dependent panels become stale/cleared according to existing policy |
| Revert buffer | file.revert | Revert File | none | active file-backed buffer | confirmation when dirty | File reverted. | Revert cancelled. | editor buffer | no new transient persistence | cancellation preserves dirty text | dependent panels become stale/cleared according to existing policy |
| Create file | file-tree.create-file | Create File | none | project open | Create File prompt | File created. | File could not be created. | File Tree, or new file buffer if current implementation opens it | project file discovery updates after refresh | preserves dirty buffers | Quick Open/Search require refresh; diagnostics for old targets remain explicit/stale |
| Create directory | file-tree.create-directory | Create Directory | none | project open | Create Directory prompt | Directory created. | Directory could not be created. | File Tree | project file discovery updates after refresh | preserves dirty buffers | Quick Open/Search require refresh |
| Rename file/directory | file-tree.rename | Rename File or Directory | none | selected File Tree item | Rename File or Directory prompt | File or directory renamed. | File or directory could not be renamed. | renamed open file buffer if open, otherwise File Tree | workspace active path updates only when active buffer target changes | updates backing path for open clean file; dirty targets require explicit lifecycle decision | marks stale targets in Search/Quick Open/Diagnostics visibly |
| Delete file/directory | file-tree.delete | Delete File or Directory | none | selected File Tree item | Delete File or Directory confirmation | File or directory deleted. | Delete cancelled. | next valid File Tree item, or editor if the active buffer closes | deleted active path is not silently recreated | dirty open target requires explicit decision; cancellation preserves text | marks stale targets visibly; no silent repair |
| Search project | search.project | Search Project | implementation default if bound | project open and query available | Project Search query prompt/bar | Search complete. | No project open. | Project Search Results | query/results are transient unless already intentionally supported | preserves dirty buffers | no build output change |
| Navigate search result | search.open-selected | Open Selected Project Search Result | Enter from results | selected fresh result | no prompt | Opened search result. | No search result selected. | editor buffer at match | active file may be persisted | focuses existing/opened file; preserves dirty buffers | stale/missing result reports a clear status |
| View outline | outline.show | Show Outline | implementation default if bound | active buffer with supported outline behavior | no prompt | Outline shown. | Outline unavailable. | Outline | outline rows remain transient | preserves dirty buffers | no build output change |
| Run build | build.run | Run Build | none by default | project open and configured build request ready | build configuration/confirmation prompt when needed | Build started. | Build command is not configured. | Build Output | build result/output are transient unless already intentionally supported | preserves dirty buffers | updates build output and diagnostics consistently when results exist |
| Cancel active build | build.cancel | Cancel Build | none by default | active public build job | no prompt | Build cancellation requested. | No active build job. | Build Output | cancellation state is transient active-job state only | preserves dirty buffers | latest build result/output mark cancellation as partial until the runner/job acknowledges completion |
| Inspect build output | build.output.show | Show Build Output | none | build output panel available | no prompt | Build Output shown. | No build output captured. | Build Output | no new persistence | preserves dirty buffers | empty state explains there is no build output |
| Inspect diagnostics | diagnostics.show | Show Diagnostics | implementation default if bound | none | no prompt | Diagnostics shown. | No diagnostics. | Diagnostics panel | diagnostics are transient unless already intentionally supported | preserves dirty buffers | empty state is useful; populated state opens targets through normal navigation |
| Switch buffers | buffer.switch-next / buffer.switch-previous | Next Buffer / Previous Buffer | implementation default if bound | another buffer exists | no prompt | Buffer switched. | No other buffer. | editor buffer | active buffer may be persisted | preserves dirty buffers | no change |
| Close active buffer | buffer.close | Close Buffer | implementation default if bound | active buffer exists | dirty close review when needed | Buffer closed. | Cannot close buffer while dirty changes need review. | next buffer or empty editor state | closed active file removed from active workspace selection | cancellation preserves dirty text | clears buffer-owned transient target state where applicable |
| Close project | project.close | Close Project | none | project open | dirty close review when needed | Project closed. | Cannot close project while dirty buffers need review. | Empty editor state | current project removed from active workspace state | cancellation preserves dirty buffers | project-scoped Search/Quick Open/Outline/Diagnostics/Build state cleared |
| Switch project | project.switch | Switch Project | none | target project path | dirty project switch review when needed | Project opened. | Project switch cancelled. | File Tree, or restored editor buffer when valid | new project identity persisted by workspace rules | cancellation preserves dirty buffers and previous project | clears previous project-scoped transient state |
| Restore workspace | workspace.restore | Restore Workspace | none | workspace file exists and references valid state | no prompt except existing recovery UI | Workspace restored. | Workspace could not be restored. | restored active editor buffer when valid, otherwise File Tree/empty state | restores valid project/buffers/focus only | does not persist or recreate dirty state | does not restore stale build/diagnostic transient state unless explicitly supported |
| Quit | host quit lifecycle | Quit | implementation default if bound | none | dirty quit review when needed | Ready to quit. | Dirty buffers need review before quitting. | previous focus restored if cancelled | no invalid state recreated | cancellation preserves dirty buffers | no change |

## Cross-surface rules

File Tree opening always opens or focuses the matching buffer. Renaming an open file updates the buffer backing path. Deleting a clean open file follows the existing file-safety policy; deleting a dirty open file requires an explicit decision. File Tree refresh never mutates buffers silently, and stale/missing state is visible rather than repaired by render code.

Quick Open, Project Search, Outline, and Diagnostics all navigate by opening/focusing the target buffer and moving to the target location when one exists. Missing or stale targets fail gracefully with user-facing status and leave focus on the surface that needs correction.

Build has one execution entry point, `build.run`, and one process-control entry point, `build.cancel`, which is available only while the transient active build-job model reports an active job. Build output and Diagnostics must describe the same result state: empty build output means there is no captured build output, and empty Diagnostics means there are no diagnostic rows. A populated build result may update both surfaces, but neither surface should contradict the other.

Workspace restore must continue the previous session only when the referenced project, files, and focus target are valid. Dirty text, prompts, stale conflicts, build output, diagnostics, search results, Quick Open results, and outline rows remain transient unless a feature explicitly owns persistence for them.



## Integrated workflow coverage

The current dogfood suite covers the supported daily loop end to end: command discovery, project open, File Tree navigation, editing, save/save-as/reload/revert, Quick Open, Project Search, Outline, build execution, Build Output, Diagnostics, buffer switching, clean and dirty buffer close, project close/switch, workspace restore, and host quit readiness. These scenarios are behavior coverage for existing commands; they must not add duplicate command families or surface-only command vocabulary.

Dirty-buffer lifecycle decisions are shared across active-buffer close, project close, project switch, and quit readiness. Cancelling a destructive decision must preserve text, dirty state, active buffer identity, project identity, and focus. Discard/save paths may proceed only after the relevant guard accepts the decision.

Workspace restore is valid only when the referenced project, files, and focus target still exist. Invalid restore input falls back to a safe empty/project state and must not recreate dirty text, prompts, stale conflicts, build output, diagnostics, search rows, Quick Open rows, or Outline rows.

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
