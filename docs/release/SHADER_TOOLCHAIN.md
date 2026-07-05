# Shader toolchain contract

The runtime ships checked-in SPIR-V binaries under `src/runtime/shaders/`.
Those binaries are release artifacts generated from the adjacent GLSL shader
sources with `glslangValidator`.

The freshness gate is intentionally a **byte-for-byte** check:

```sh
EDITOR_REQUIRE_SHADER_FRESHNESS=1 tools/bin/shader_freshness_check
```

The gate recompiles each shader to a temporary directory and compares the result
with the checked-in `.spv` files. This is a strong release check, but it also
means the result is tied to the shader compiler toolchain used for the release.
Different `glslangValidator` versions may produce byte-different SPIR-V for the
same GLSL source even when the shaders are semantically equivalent.

## Recorded release toolchain manifest

The release archive carries a small manifest:

```text
docs/release/SHADER_TOOLCHAIN_VERSION.txt
```

The manifest carries an explicit state line:

```text
SHADER_TOOLCHAIN_MANIFEST_STATE=UNRECORDED | RECORDED
```

`UNRECORDED` is valid for development/source snapshots only. Strict release validation treats it as a failure before shader freshness can be accepted.

Strict shader freshness validation compares the first line of
`glslangValidator --version` against this manifest. A release candidate must not
ship with:

```text
SHADER_TOOLCHAIN_MANIFEST_STATE=UNRECORDED
GLSLANG_VALIDATOR_VERSION_FIRST_LINE=UNRECORDED
```

To regenerate shaders and record the chosen release shader toolchain in one step, run:

```sh
tools/bin/compile_shaders --record-toolchain-manifest
```

This updates both the checked-in SPIR-V files and the toolchain manifest. Commit
all changed shader outputs and `docs/release/SHADER_TOOLCHAIN_VERSION.txt`
together.

If the shader binaries are already current and only the release toolchain
manifest needs to be recorded, run the Ada manifest recorder on the release
validation machine:

```sh
tools/bin/record_shader_toolchain_manifest --from-glslang
```

For CI systems that capture tool versions before invoking release gates, the
same tool can record the first line from a captured file:

```sh
glslangValidator --version > build/glslangValidator-version.txt
tools/bin/record_shader_toolchain_manifest --version-file build/glslangValidator-version.txt
```

The recorder refuses empty, `UNRECORDED`, unknown, or placeholder values. Do not
edit `docs/release/SHADER_TOOLCHAIN_VERSION.txt` by hand for a release candidate.

Release policy:

1. Choose one release shader toolchain for the release candidate.
2. Run `tools/bin/compile_shaders --record-toolchain-manifest` with that toolchain
   after editing shader sources, or run `tools/bin/record_shader_toolchain_manifest --from-glslang`
   when the checked-in shader binaries are already current and only the manifest
   needs to be recorded.
3. Commit the regenerated `.spv` files, when any changed, and the updated
   toolchain manifest together.
4. Run `EDITOR_REQUIRE_SHADER_FRESHNESS=1 tools/bin/shader_freshness_check`
   with the same release toolchain before publishing the archive.
5. If the freshness gate fails because the shader compiler version changed,
   either switch back to the recorded release toolchain or intentionally
   regenerate shaders and the manifest with the new chosen release toolchain and
   review the diff.

`tools/bin/compile_shaders` and `tools/bin/shader_freshness_check` both print
the detected `glslangValidator --version` output so a maintainer can identify
which toolchain produced or rejected the checked-in binaries.

This check is not a substitute for runtime smoke validation. Runtime validation
still needs `tools/bin/runtime_smoke` on a machine with GLFW, Vulkan, and a
usable display session.


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
