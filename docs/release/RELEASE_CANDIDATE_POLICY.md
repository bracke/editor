# Release-candidate policy

The source tree is either a development snapshot or a release candidate. The
state is declared in:

```text
 docs/release/RELEASE_STATE.txt
```

Allowed values are:

```text
RELEASE_STATE=DEVELOPMENT_SNAPSHOT
RELEASE_STATE=RELEASE_CANDIDATE
```

`DEVELOPMENT_SNAPSHOT` is the default for ordinary implementation archives. It
may carry an unrecorded shader toolchain manifest and may omit final runtime
validation evidence.

`RELEASE_CANDIDATE` is an evidence-backed state. A tree must not be marked as a
release candidate until the supported release validation machine has produced:

```text
build/release-validation/release-check-validation.md
build/release-validation/strict-runtime-validation.md
```

and both reports contain their final PASS markers. The shader toolchain manifest
must also be recorded with the chosen release `glslangValidator`.

Build and run the Ada gate before publishing or labeling an archive as a release
candidate:

```text
alr exec -- gprbuild -P tools/editor_tools.gpr
EDITOR_REQUIRE_RELEASE_CANDIDATE=1 tools/bin/release_candidate_check
```

The normal `tools/bin/release_check` run also invokes
`tools/bin/release_candidate_check`. In `DEVELOPMENT_SNAPSHOT` state the gate
prints that release-candidate evidence is not required. In
`RELEASE_CANDIDATE` state, or when `EDITOR_REQUIRE_RELEASE_CANDIDATE=1` is set,
it fails unless final release validation evidence is present and passing.


### Case 953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

Case 1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Case 1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Case 1138 note: Global/Depends flow-effect graph legality is now represented by
`Editor.Ada_Flow_Effect_Graph_Legality`, including object read/write edges, call
propagation, generic formal/actual effect substitution, protected/task effects,
refined Global/Depends body/spec checks, coverage-gate blockers, deterministic
lookups, counters, and fingerprints.

Case 1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Case 1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Case 1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Case 1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Case 1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Case 1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
