# Build runner process management

The guarded public `build.run` path uses a structured-argv process runner. It
never shell-splits opaque command text and keeps output bounded before build
output is forwarded into Diagnostics.

## Current execution model

- `build.run` starts a transient worker-backed public build job and returns
  control to the editor command loop instead of running the native child on the
  command frontdoor. The state-owned job id remains in `State_Type`; the
  copied request, gates, worker snapshot, and final result cross the task
  boundary through a bounded protected slot registry instead of package-level pending globals or a single unnamed handoff.
- The public active build-job model owns a runtime-only process-control handle
  when the selected runner can provide a cancellable process id; the native
  worker publishes that handle so `build.cancel` can signal the live child while
  the worker is running.
- The public active build-job model owns a bounded incremental output stream
  used by UI/test seams to publish stdout/stderr chunks before the final result.
  The native worker publishes active stdout/stderr stream snapshots through the
  synchronized process-control handoff so editor polling can observe bounded
  output deltas before completion. `editor_tick` calls
  `Editor.Input_Bridge.Tick_Async_Build_Jobs`, so idle frames poll queued build
  jobs and can refresh Build Output/completion state without waiting for the
  next user command.
- The real runner uses the native process supervisor for execution. The child
  process redirects stdout and stderr into separate bounded capture files before
  `execvp`, so final real-runner results carry separated stdout/stderr
  provenance instead of merged fallback provenance.
- Diagnostics prefer stderr when it is present while keeping stdout visible.
  Supplied/test results may still carry merged-output provenance for result-model
  coverage, but real build execution must not collapse stderr into stdout.
- A positive timeout is enforced by the native process supervisor in the real
  runner. The runner starts the process directly, polls for completion, sends
  `SIGTERM` at the deadline, escalates to `SIGKILL` if needed, and maps the
  result to the build timed-out status while preserving bounded partial output.
- `tools/bin/real_build_runner_smoke` builds and runs a real gprbuild fixture
  when `gprbuild` is available. The smoke executable checks the success path,
  failure path, separated-output provenance, Diagnostics ingestion, Build Output
  detail projection, and the native timeout branch when `/bin/sleep` is
  available.

## Current limits

`build.cancel` signals the active process-control handle when the worker/native
runner has registered one; the async worker/result handoff is synchronized by a
protected object keyed by the state-owned build-job id rather than unsynchronized
package globals. Active process handle publication, cancellation requests, and
active stdout/stderr stream snapshots are also synchronized through the
process-control handoff, so the editor side does not read ad hoc worker globals.
When no handle is registered, the command reports cancellation unsupported
rather than pretending termination occurred. The real-runner output path
captures stdout and stderr separately and updates the active Build Output stream
with bounded source-tagged chunks while the native child is running. It does not
provide terminal emulation or unbounded output.
The native process-control implementation is POSIX-backed (`fork`, `execvp`,
`waitpid`, `kill`, `dup2`, `SIGTERM`, `SIGKILL`). The backend is exposed as
`Native_Process_Control_POSIX`; the product does not claim Windows
`CreateProcess` support until a separate backend is implemented and
release-gated. See `docs/release/BUILD_PROCESS_PLATFORM_SUPPORT.md`.


Async build behavioral coverage includes protected handoff state-machine checks plus a POSIX real-process cancellation integration check that starts a live `/bin/sleep` child when available, requests `build.cancel`, and verifies cancelled finalization.


Async build ownership note: each editor state receives a stable `State_Type.Public_Build_Async_Slot_Id`. A bounded protected build-job registry plus worker pool stores transient request/result payloads by slot and job id, so the implementation no longer has a single unnamed worker/handoff. The pool supports `Max_Public_Build_Async_Slots` simultaneous occupied async slots; a ninth simultaneous occupied slot is rejected with `Build unavailable: async build slot pool exhausted.` instead of silently colliding through modulo worker routing. Release checks reject the previous single-worker/single-handoff names and require the slot-exhaustion guard.
Async build slot lifetime: `State_Type.Public_Build_Async_Slot_Id` is stable for the editor state after its first public build job. It is not reset on build completion. Each new build uses a new `Public_Build_Job_Id` within the same state slot, while transient request/result payloads are cleared from the protected job registry. This keeps worker-pool routing stable without treating the slot id as per-build state.


Lifecycle shutdown note: project open, project switch, and project close request cancellation of any active async public build before mutating project-scoped state. The transition is deferred until later polling finalizes the build result, so close/switch/open cannot leave a live build process attached to a stale project context.

Async worker shutdown/drain: application shutdown can call `Drain_Public_Build_Worker_For_Shutdown` for the active editor state. The function first requests lifecycle cancellation through the same synchronized cancellation handoff used by project close/switch, then rendezvous-drains the state slot's build worker before final polling/cleanup. The worker tasks remain application-lifetime services; the shutdown contract drains active work deterministically and clears the active process handoff instead of leaving a live child attached to a stale editor state.



## Async worker stop/termination

The async build worker pool has two shutdown levels. `Drain_Public_Build_Worker_For_Shutdown` requests cancellation and waits for the active slot work to become idle without terminating the app-lifetime worker. `Stop_Public_Build_Workers_For_Application_Exit` is the final application-exit path: it sets the worker lifecycle stop flag, rejects new async build starts with `Build unavailable: async build worker pool is stopping.`, rendezvous-stops each worker task, and marks the pool stopped. The stop path is intended for final process shutdown and is tested last because it terminates the worker pool for the test process.


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
