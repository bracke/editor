# CI runtime validation

The canonical runtime release gate remains a real graphics validation run:

```sh
tools/bin/strict_runtime_validation
```

That gate requires the runtime C syntax/header check, the runtime link/build
check, the canonical `bin/editor_app` executable, the shader freshness check,
the graphical GLFW/Vulkan smoke, and the missing-shader negative asset check.
It should be run on at least one release validation machine with a working GLFW
and Vulkan stack.

CI can run a narrower runtime validation path when the CI image provides a
virtual display and a software Vulkan implementation. This is useful for
catching packaging regressions, but it is not a substitute for the release
machine smoke because CI drivers and virtual displays do not cover all swapchain,
monitor, resize, minimize, and presentation behaviours.

## Linux CI prerequisites

Package names vary by distribution, but the CI image must provide the same
classes of dependencies as the release machine:

- GNAT/GPRbuild or Alire with a GNAT toolchain;
- a C compiler;
- GLFW development headers and library;
- Vulkan headers and loader;
- `glslangValidator` for shader freshness checks;
- a virtual display, commonly Xvfb;
- a Vulkan ICD. For software validation this is commonly Mesa llvmpipe/lavapipe.

Common environment variables for a software Vulkan CI lane include:

```sh
export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
```

Some distributions require selecting the lavapipe ICD explicitly, for example:

```sh
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json
```

The exact ICD path is distribution-specific. Do not hard-code it in project
scripts; configure it in CI image setup.

## Example CI command sequence

A typical Linux CI lane can start a virtual display, then run the strict runtime
gates:

```sh
Xvfb :99 -screen 0 1280x720x24 >/tmp/editor-xvfb.log 2>&1 &
XVFB_PID=$!
trap 'kill "$XVFB_PID" 2>/dev/null || true' EXIT

export DISPLAY=:99
export LIBGL_ALWAYS_SOFTWARE=1
# Optional, distro-specific:
# export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json

tools/bin/strict_runtime_validation
```

If the CI image cannot provide a usable Vulkan ICD, keep the runtime gates in
non-strict mode for source-structure validation and run the strict gates on the
release validation machine instead.

## Validation split

Use these lanes deliberately:

- Source-only CI: `tools/bin/release_check` in non-strict mode.
- Runtime-capable CI: `tools/bin/strict_runtime_validation` with Xvfb and a
  configured Vulkan ICD.
- Final release validation: `tools/bin/strict_runtime_validation` on real
  supported graphics hardware or the project’s chosen release graphics machine.

Runtime smoke remains a smoke gate. Manual resize, minimize/restore,
multi-monitor, long-running interaction, and driver-specific checks are still
release validation tasks outside the automated CI lane.


### Pass953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

- Phase 579 pass973: include the generic default-expression legality regression so static-aware generic-contract checks continue to classify static, illegal, and unresolved object-formal expressions without introducing rendering-side parsing or mutable editor state.

Pass1038 validation note: generic contract diagnostics are projection-only over snapshot-owned semantic models and must not perform parsing, file IO, rendering, workspace mutation, or command registration.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1138 note: Global/Depends flow-effect graph legality is now represented by
`Editor.Ada_Flow_Effect_Graph_Legality`, including object read/write edges, call
propagation, generic formal/actual effect substitution, protected/task effects,
refined Global/Depends body/spec checks, coverage-gate blockers, deterministic
lookups, counters, and fingerprints.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1257: added RM-completed generic/shared-state remediation worklist legality. The pass is semantic-only and orders prerequisite blockers for the completed RM chain before recheck eligibility may trust downstream conclusions.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
