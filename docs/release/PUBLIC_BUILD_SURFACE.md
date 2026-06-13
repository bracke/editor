# Public build command surface

The build feature exposes `build.run` as a guarded public product command.

`build.run` is:

- descriptor-owned and command-palette visible;
- Executor-routed;
- structured-argv validated, with no shell execution or command-string splitting;
- working-context validated;
- explicit-consent gated for the exact current request identity;
- connected to the bounded non-shell real process runner;
- routed through Build Output and Diagnostics ingestion.

The internal `build.run-user-opt-in-test-seam` command remains hidden and unavailable as a bare palette/action command. Deterministic supplied process results are used only by tests and product smoke fixtures.

## Implemented Build UI profiles

For selected GPRbuild candidates, the Build UI exposes implemented fixed-token profiles:

- `default`: use the discovered candidate argv unchanged;
- `debug`: add `-g`;
- `release`: add `-O2 -gnatp`;
- `validation`: add `-gnata -gnatwa`.

For selected Alire candidates, the Build UI uses fixed root-crate profile switches:

- `default`: `alr build`;
- `debug`: `alr build --development`;
- `release`: `alr build --release`;
- `validation`: `alr build --validation`.

Profile changes are material request changes: they update the structured argv deterministically, invalidate consent, and require the user to acknowledge the new request before `build.run` can execute. The UI must not silently guess unsupported tool flags or execute a mutated argv without review.


### Pass953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
