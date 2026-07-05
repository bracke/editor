# Build process platform support

The current real build-process backend is explicitly POSIX-scoped.

Supported native process-control backend:

```text
POSIX/fork-exec-waitpid-kill
```

The implementation uses the following primitives for real build execution,
timeout handling, live cancellation, and stdout/stderr capture:

```text
fork
execvp
waitpid
kill
dup2
SIGTERM
SIGKILL
```

The product must not imply native Windows build-process support until a separate
backend is implemented and release-gated. In particular, the current backend does
not claim support for:

```text
CreateProcess
TerminateProcess
Windows job objects
Windows handle inheritance rules
Windows pipe/event-loop integration
```

Tests and release tooling expose this scope through the `Editor.External_Producers`
backend contract:

```text
Native_Process_Control_POSIX
Current_Native_Process_Control_Backend
Native_Process_Control_Backend_Label
Native_Process_Control_Is_POSIX
Native_Process_Control_Platform_Audit_Passes
```

Release validation must continue to treat the real build runner as POSIX-backed
unless a future platform backend adds explicit API, tests, documentation, and
release-check coverage for another operating system.


### Case 953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

Case 1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Case 1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Case 1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Case 1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Case 1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Case 1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Case 1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Case 1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
