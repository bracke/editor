# Feature Panel Architecture Freeze

Phase 158 freezes the feature-panel architecture after four real feature-panel-backed features: Outline, Messages, Search Results, and Diagnostics. The feature panel remains an explicit built-in subsystem; it is not a dynamic plugin host and it does not load feature descriptors dynamically.

## Descriptor contract

`Editor.Feature_Panel` owns the descriptor table. The table is the single source of truth for stable feature ids, stable names, display labels, and generic capabilities.

Current registered features, in frozen descriptor order:

1. `Outline_Feature`: active-buffer outline extraction, navigation, current-symbol projection, and filtering.
2. `Messages_Feature`: session-local editor-originated messages posted through a producer-style API.
3. `Search_Results_Feature`: active-buffer synchronous literal search query/results.
4. `Diagnostics_Feature`: session-local diagnostic-like rows posted through a producer-style API.

Descriptors are read-only during normal operation. Labels are static metadata and must not depend on current query text, message severity filters, diagnostic source filters, outline source class, row count, or selection.

`Unknown_Feature` is a rejection sentinel. It must never become a valid active feature and must not be treated as a registered descriptor.

## Ownership boundary

Feature panel infrastructure owns active feature selection, feature descriptors, projection tokens, visible-row mapping, reveal requests, mouse hit-testing, focus mechanics, and the generic dispatch shape.

Each feature owns its source rows, source-specific state, filters or query state, selection semantics where needed, row action affordances, target validation, command behavior, and lifecycle cleanup.

Generic feature-panel code must not know about Outline extraction, Messages retention, Search query state, or Diagnostics severity/source filters. It may operate only on `Feature_Id`, `Feature_Descriptor`, `Feature_Projection_Token`, projection generation, visible row indexes, generic row labels/details, generic row action flags, feature-neutral severity/emphasis metadata, selection, reveal, focus, and visibility state.

## Finalized feature scopes

- Outline owns active-buffer outline extraction/navigation/filtering. Filtering is projection-only, current-symbol state is cursor-derived, and open-selected uses selected outline target metadata only.
- Messages owns session-local editor-originated messages. Retention is bounded, filters compose with row changes, and actions use `Message_Id` plus validated projection/source mapping.
- Search Results owns active-buffer synchronous literal search. Query input never edits the buffer, query history is bounded and non-persistent, and stale results never bypass target validation.
- Diagnostics owns session-local diagnostic-like rows. Retention is bounded, severity/source/filter state composes with row changes, and actions use `Diagnostic_Id` plus validated projection/source mapping.

## Dispatch requirements

Every registered `Feature_Id` must have explicit entries for:

- descriptor lookup;
- projection rebuild;
- clear-active-feature behavior;
- open-selected behavior;
- row action dispatch coverage;
- buffer-close lifecycle cleanup;
- project-close lifecycle cleanup;
- workspace-close lifecycle cleanup;
- command registration and availability tests;
- command audit coverage;
- cross-feature projection-token tests.

Known-feature dispatch should use explicit `case` alternatives. A `when others` alternative is acceptable only at an external defensive boundary where unknown values are rejected, not in the internal four-feature dispatch matrix.

## Projection-token contract

Projection tokens are feature-scoped:

```ada
type Feature_Projection_Token is record
   Feature    : Feature_Id;
   Generation : Natural;
end record;
```

A token is valid only when:

- its feature is known;
- its feature equals the current active feature;
- its generation is nonzero;
- its generation equals the current active projection generation;
- the visible row index is live in the current projection;
- the owning feature validates the mapped source identity.

Stale tokens and cross-feature tokens must be rejected by reveal, mouse hit handling, activation, context actions, and generic open.

## External-producer readiness boundary

Messages and Diagnostics expose synchronous, session-local producer-style APIs. Producers may post rows through those APIs and may provide validated target metadata. Producers must not mutate feature storage, projection rows, selection, feature-panel tokens, or row-action metadata directly.

The current producer boundary deliberately excludes compiler invocation, build-output parsing, LSP protocol handling, file watching, background queues, asynchronous producers, project-wide analysis, and persistent logs.

## Future feature checklist

Before a future feature-panel-backed feature can pass architecture tests, add:

1. a new `Feature_Id` without reordering existing ids;
2. a descriptor-table entry with unique stable/display names;
3. a feature-owned state package;
4. a projection provider;
5. show and clear commands;
6. open/action handlers if rows are activatable;
7. buffer/project/workspace lifecycle reset hooks;
8. command registration and command-palette tests;
9. command-surface audit coverage;
10. projection-token and stale-token tests;
11. cross-feature isolation tests;
12. no-active-buffer, project-close, and workspace-close tests.

Do not add persistence for transient feature-panel state unless a later phase explicitly changes the architecture.

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
