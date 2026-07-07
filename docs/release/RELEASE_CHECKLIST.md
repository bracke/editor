# Release Checklist

Use this file as the current release gate. Historical pass-heavy validation
notes live in `docs/release/RELEASE_VALIDATION_HISTORY.md`.

Keep `docs/release/RELEASE_STATE.txt` as
`RELEASE_STATE=DEVELOPMENT_SNAPSHOT` until the release-candidate and final
validation evidence gates pass.

## Command Sequence

Run `tools/bin/release_commands` to print the release-only validation sequence.
The sequence must be run from an Alire environment that selects the pinned
GNAT 15 compiler. Confirm the selected compiler first:

```sh
alr exec -- gnatls --version
```

The sequence currently includes:

```sh
alr exec -- gprbuild -P tools/editor_tools.gpr
tools/bin/outline_static_sanity
tools/bin/ada_keyword_identifier_check
tools/bin/runtime_compile_check
tools/bin/runtime_link_check
tools/bin/runtime_smoke
tools/bin/runtime_missing_asset_check
tools/bin/shader_toolchain_manifest_check
tools/bin/release_candidate_check
tools/bin/strict_runtime_preflight
tools/bin/shader_freshness_check
tools/bin/unit_tests all
tools/bin/language_validation_check
tools/bin/product_smoke
tools/bin/real_build_runner_smoke
tools/bin/release_check
EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 tools/bin/final_release_validation_check
```

The full `tools/bin/unit_tests all` aggregate is release-only. Routine
development uses the relevant slice from `docs/testing.md`.

## Strict Gates

On release validation machines, use strict environment variables for gates that
can otherwise skip when host dependencies are missing:

- `EDITOR_REQUIRE_LANGUAGE_VALIDATION=1 tools/bin/language_validation_check`
- `EDITOR_REQUIRE_RUNTIME_COMPILE=1 tools/bin/runtime_compile_check`
- `EDITOR_REQUIRE_RUNTIME_LINK=1 tools/bin/runtime_link_check`
- `EDITOR_REQUIRE_RUNTIME_SMOKE=1 tools/bin/runtime_smoke`
- `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1 tools/bin/runtime_missing_asset_check`
- `EDITOR_REQUIRE_SHADER_FRESHNESS=1 tools/bin/shader_freshness_check`
- `EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT=1 tools/bin/strict_runtime_preflight`
- `EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 tools/bin/final_release_validation_check`

`runtime_smoke` must use the runtime's internal bounded smoke timeout, not an
external timeout utility. Release-tool evidence uses merged stdout/stderr
capture through the Ada release-tool helpers.

## Required Confirmation

- `tools/bin/release_commands` matches the actual release-check gate surface.
- `tools/bin/release_check` passes.
- `tools/bin/unit_tests all` passes only as part of release validation.
- `tools/bin/language_validation_check` passes in strict mode.
- Runtime compile/link/smoke and missing-asset checks pass in strict mode on the
  runtime validation machine.
- `tools/bin/product_smoke` and `tools/bin/real_build_runner_smoke` pass.
- `tools/bin/release_candidate_check` passes before changing release state.
- `tools/bin/final_release_validation_check` passes after recording evidence.
- Build process-control support remains explicitly POSIX-scoped through
  `Native_Process_Control_POSIX` until another backend is implemented.
- Source archives include source/docs/tools/tests, and exclude generated `obj/`,
  `bin/`, root-level Ada build artifacts, and `lib/` build products.

## Historical Detail

Use `docs/release/RELEASE_VALIDATION_HISTORY.md` for historical parser,
language-model, runtime, and remediation validation notes. Those notes are
evidence, not the current release command sequence.
