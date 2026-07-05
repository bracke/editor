# Dogfood Scenario

defines one deterministic Ada project workflow over `tests/fixtures/dogfood_project`.

The scenario exercises normal product routes and existing models only:

1. Open `tests/fixtures/dogfood_project` as the project root.
2. Refresh known project files and scan the File Tree.
3. Use Quick Open to find `src/dogfood_demo.adb`.
4. Open the file through the canonical file-open path.
5. Edit the active buffer, observe dirty state, save, and verify dirty state clears.
6. Refresh Ada Outline from an explicit active-buffer snapshot and navigate a real extracted row target.
7. Run Project Search for `Dogfood_Known_Token` and activate the selected result target.
8. Show Build UI, refresh candidates from the project root, explicitly select a candidate, review request preview and working context, and acknowledge consent.
9. Invoke `build.run` through the Executor route. The current product uses the structured bounded process runner when the runtime execution policy and consent model allow it; deterministic dogfood fixtures may still supply a bounded process result when host build tools are not available.
10. Exercise the bounded runner/output/diagnostics seam with a deterministic supplied process result and ingest diagnostics through Diagnostics-owned APIs.
11. Save and reload a workspace snapshot that retains only structural session data.
12. Assert that transient Build UI candidates/selection/consent, latest result/output details, Outline rows, Project Search results, Quick Open matches, and Diagnostics rows are not encoded in workspace persistence.

The fixture is intentionally small, has no network dependency, uses no Ada tools, and does not rely on placeholder/demo rows.

## Repeatability Check

For the milestone package, run the same scenario from a clean startup, save a structural workspace, reload it, confirm transient rows/results/output are absent, and run the scenario again. The second run should produce the same project-scoped surfaces from real refresh/open/search/outline/build-preparation routes rather than from persisted workflow state.

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
