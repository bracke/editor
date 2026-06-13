# Phase 537 Milestone Startup and Dogfood Readiness

Phase 537 packages the current dogfood editor workflow as a repeatable local milestone. It keeps startup and reload behavior understandable while preserving the existing transient-state boundaries.

## Start the editor

Start from a clean checkout/package using the normal editor launcher for the project. Fresh startup is a real empty state: no project is open, no active buffer exists, File Tree/Quick Open/Project Search are unavailable until a project is opened, Outline is unavailable until a buffer is active, Build is unavailable until a project-backed request is prepared, Diagnostics starts empty, and Command Palette remains available for discovery.

Startup does not create project data, demo rows, placeholder content, build candidates, search results, quick-open matches, outline rows, diagnostics rows, or persisted command-palette state. Startup also does not run build/search/outline refresh and does not write settings, keybindings, workspace, or recent-project files unless an explicit save/reset command is invoked.

## Open an Ada project

Use `Open Project` from the Command Palette or the retained project-open route. Recent-project entries are project references only; opening one routes through the same canonical project lifecycle as a normal project open. Project-scoped surfaces may refresh only through the normal lifecycle hooks.

## Browse and open files

After a project is open, show or refresh the File Tree to browse real project files. Activating a file-tree node opens the file through the canonical file-open path. No placeholder file-tree rows are shown in product startup or normal project flows.

## Use Quick Open

Open Quick Open after a project is available, type a file-name fragment, select a real project match, and accept it to open the file through the canonical file-open path. Quick Open matches are transient and are not restored by workspace reload or recent-project reopen.

## Search project text

Use Project Search after a project is available. Search results are bounded, project-scoped, and transient. Activating a result navigates through existing buffer/location behavior. Workspace reload and recent-project reopen do not restore old search rows.

## Refresh and navigate Outline

Open an Ada source buffer, then refresh Outline from the active-buffer snapshot. Outline rows are extracted from the current buffer and can be selected/activated through the existing Outline navigation workflow. Outline content is transient and is not stored in workspace, settings, keybindings, or recent projects.

## Use Build UI

Show Build UI, refresh build candidates from the open project, select a candidate, review the resulting request/working context, and explicitly acknowledge consent before invoking `build.run`. Build UI state is request-preparation state only. Candidate lists, selected candidate, consent, latest result, and bounded output details are not restored by workspace reload or recent-project reopen.

## Inspect build output

After a represented build result exists, use the Build UI result/output details surfaces to inspect the latest bounded output. The current editor also supports bounded active-job output streaming into Build Output. There is still no build history, rerun-last-build action, terminal, or shell command language in this milestone.

## Review Diagnostics

When Diagnostics-owned ingestion has produced diagnostics, show Diagnostics to review them and activate valid targets through the existing Diagnostics navigation workflow. Diagnostics rows are not persisted as workspace state outside the retained Diagnostics-owned policy.

## Workspace reload

Workspace reload may restore retained structural session state such as project reference, open file references, active file reference, and retained structural panel visibility. It deliberately does not restore unsaved buffer text, Build candidates, selected Build candidate, Build consent, latest Build result/output, Outline rows, Project Search results, Quick Open matches, File Tree data rows, Command Palette query/results, or dogfood transient state.

Expected reload messages include `Workspace loaded.`, `Workspace saved.`, `Workspace contains no project to restore.`, `Some files could not be reopened.`, and `Unsupported workspace fields ignored.`

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
