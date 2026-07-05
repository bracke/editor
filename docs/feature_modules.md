# Feature modules

`Editor.Feature_Panel` is the reference generic feature host. `Editor.Outline` is a current content-bearing feature that uses that host for parser-backed Ada language-model declaration outlines.

A feature-content module owns domain data and deterministic audit helpers. The display scaffold owns visibility, focus, selection, generic rows, and row rendering. The executor owns command effects, projection coordination, availability, route-equivalent dispatch, and user-visible messages. Render code consumes snapshots only.

Outline rows come from the explicit `outline.refresh` command path. The executor snapshots the active in-memory buffer, runs the shared Ada declaration parser through the Outline extractor, applies the result to `Editor.Outline`, and projects the accepted rows into `Editor.Feature_Panel`. `Editor.Outline` does not scan projects, save files, reload files, or mutate the project language index from rendering or availability checks. Selected-row navigation is executor-owned and validates the active-buffer target before moving the caret. `Editor.Feature_Panel` does not generate outline items and does not own outline semantics.

The outline projection adapter replaces current feature-panel rows with outline-derived rows and mirrors valid Outline selection into the visible panel projection. Projection does not show, hide, or focus the panel; those effects are owned by commands. Generic `clear-feature-panel` clears displayed rows only; `outline.clear` clears both outline state and displayed outline rows.

Selection mapping is deliberately stale-safe. A feature-panel selected row is treated as an outline row only when it maps to the current outline item projection, with matching row kind, label, detail, and current projection generation where supplied. Generic or stale feature-panel rows do not become outline navigation targets merely because outline state exists.

This establishes the stable pattern for later content features: keep feature semantics in the feature module, keep generic display mechanics in the panel host, keep mutation at the executor boundary, keep availability side-effect-free, and keep persistence/rendering side-effect-free.

## Outline extraction seam ownership

`Editor.Feature_Panel` remains a generic row host. It owns row storage, visibility, focus, selection, summaries, and render snapshots. It does not own outline extraction, source parsing, target navigation, command messages, availability policy, or provider selection.

The outline extraction seam is owned by `Editor.Outline` as data/model/status and by `Editor.Executor` as command orchestration. Extractor packages convert explicit source snapshots into outline items, but they must not know command-palette row layout, emit transient messages, mutate `Feature_Panel`, write workspace/settings/keybinding/recent files, change dirty state, or run from render/availability/input mechanics.

## Outline Extractor Provider Boundary

`Editor.Outline_Extractor` is a provider module, not a display module. It owns deterministic conversion from immutable active-buffer text snapshots to parser-backed Outline rows and returns an extraction result object. It does not own feature-panel rows, feature-panel focus, command messages, rendering, lifecycle policy, settings, keybindings, workspace persistence, dirty state, or buffer mutation.

`Editor.Outline` stores transient outline items and exposes replacement/projection helpers. `Editor.Feature_Panel` remains a generic display host: it receives projected rows after a successful Executor-owned refresh and has no knowledge of extraction grammar or provider status.

Future parser-backed or semantic providers must preserve the same ownership split: explicit snapshot input, result-before-mutation, no render/availability/palette/input invocation, no persistence of runtime extraction output, and no direct Feature_Panel mutation from the provider.

## Extracted Outline Hardening

`Editor.Feature_Panel` remains a generic row host. It does not know about extractor snapshots, provider statuses, Ada declaration parser output, buffer text, parser failures, or target activation. The only allowed outline display integration is projection from already-applied `Editor.Outline` state into generic feature rows.

Projection is deterministic: outline labels map to row labels, details map to row details, order is preserved, `Outline_Header` and `Outline_Section` map to `Feature_Row_Header`, and other extracted kinds map to `Feature_Row_Item`. Projection reconciles stale selection but does not show/focus the panel or emit messages. Executor decides when projection happens after a successful `outline.refresh` command.

Feature modules must continue to treat extraction as command-owned. Availability checks, render snapshots, local panel selection movement, command-palette projection, input routing, lifecycle reset, configuration commands, and persistence code must never trigger extraction.

Case 1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Case 1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Case 1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Case 1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Case 1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Case 1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Case 1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Case 1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.


Case 1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Case 1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.


Case 1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Case 1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Case 1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Case 1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.


Case 1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Case 1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
