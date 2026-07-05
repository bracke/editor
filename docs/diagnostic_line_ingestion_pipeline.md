# Diagnostic-line ingestion pipeline

freezes the synchronous command-facing diagnostic-line ingestion path.
Already-provided diagnostic text may enter the editor only through this layered
pipeline:

1. raw diagnostic lines are parsed by the side-effect-free line parser;
2. accepted compiler/build diagnostic records are normalized through the
   producer normalization helpers;
3. normalized records are ingested through Diagnostics-owned ingestion APIs;
4. command-facing feedback is derived from the aggregate parser, normalization,
   and ingestion result counts.

Future build/compiler execution must produce raw diagnostic lines or structured
compiler diagnostic records and pass them through the existing parser,
normalizer, and Diagnostics ingestion seams. Build runners must not append
Diagnostics rows, rebuild feature-panel projections, switch active features, or
bypass producer result accounting directly.

Forbidden shortcuts for future runner work:

* process output must not mutate Diagnostics rows directly;
* build commands must not parse and ingest inside Executor without producer
  helpers;
* tool execution must not bypass target validation;
* future asynchronous output must be marshalled through an explicit run and
  lifecycle boundary;
* build runners must not read editor buffers or scan projects merely to satisfy
  diagnostic ingestion;
* transient Diagnostics rows, diagnostic-line command state, producer output,
  and feature-panel projection state must remain non-persistent.

The current implementation remains synchronous-only: it stores no diagnostic-line
run id, no pending process output, no retained raw line buffer, and no live buffer
handle outside Diagnostics-owned row metadata. Project and workspace lifecycle
cleanup therefore has no command-ingestion state to drain, cancel, or replay.

Command surface status: keeps diagnostic-line ingestion helper-owned.
No palette-visible user command and no default keybinding are registered for raw
line ingestion. If a future internal command is added, it must use the existing
command-facing helper and pass command descriptor, availability, route, result,
keybinding, and duplication audits before becoming executable.

Case 1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Case 1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Case 1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Case 1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Case 1217: shared-state stabilized diagnostic integration preserves cross-unit shared-state blocker families at the stabilized diagnostic boundary without adding UI projection behavior.

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
