- Keep `Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery_Pass875` in the AUnit syntax/semantics suite.
- Keep pass875 use-clause recovery productions guarded: `Production_Use_Clause_Missing_Name_Recovery_Boundary`, `Production_Use_Clause_Trailing_Separator_Recovery_Boundary`, and `Production_Use_Clause_Missing_Terminator_Recovery_Boundary`.
- Verify malformed `use ;`, `use type T, ;`, and `use all type ;` forms preserve following declaration visibility and do not create rendering-side parser dependencies.

- Keep `Production_Exception_Handler_Missing_Statement_Recovery_Boundary` and `Production_Exception_Handler_End_Statement_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Exception_Handler_Statement_Recovery_Pass874` in the AUnit syntax/semantics suite.
- Verify exception-handler statement-sequence recovery remains parser-owned structural metadata only.
- Keep `Production_Formal_Package_Actual_Empty_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery_Pass873` in the AUnit syntax/semantics suite.
- Keep `Production_Case_Alternative_End_Case_Statement_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Case_Alternative_End_Case_Statement_Recovery_Pass872` in the AUnit syntax/semantics suite.
- Treat terminal case-alternative missing-statement recovery as parser-owned structural metadata only; do not turn it into compiler-grade case coverage, statement legality, LSP, or render-side parsing.

- Keep `Production_Case_Alternative_Missing_Statement_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Case_Alternative_Statement_Recovery_Pass868` in the AUnit syntax/semantics suite.
- Treat case alternative missing-statement recovery as parser-owned structural metadata only; do not turn it into compiler-grade statement legality, case coverage, LSP, or render-side parsing.

- Keep `Production_Case_Choice_Missing_Choice_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery_Pass867` in the AUnit syntax/semantics suite.
- Treat case choice-list missing-choice recovery as structural parser metadata only; do not market it as case-choice coverage or legality checking.

### Pass866 - Case statement missing-is recovery guard

- Keep `Production_Case_Statement_Missing_Is_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866` registered in the syntax/semantics AUnit suite.
- Preserve bounded recovery for malformed `case ...` statements that omit `is` without hiding following `when` alternatives or later statements.
- Do not replace this structural metadata with compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Keep `Production_Extended_Return_Missing_Do_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865` registered in the syntax/semantics AUnit suite.
- Treat extended return missing-`do` recovery as structural parser metadata only; do not turn it into compiler-grade return-object legality checking, compiler invocation, LSP behavior, render-side parsing, or dirty-state mutation.

### Pass864 - Requeue statement missing-target recovery guard

- Keep `Production_Requeue_Missing_Target_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Requeue_Target_Recovery_Pass864` registered in the syntax/semantics AUnit suite.
- Preserve bounded recovery for malformed `requeue ;` without borrowing following statement tokens as targets.
- Do not replace this structural metadata with compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass863 - Accept statement missing-entry-name recovery guard

- Keep `Production_Accept_Missing_Entry_Name_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863` registered in the syntax/semantics AUnit suite.
- Do not replace this structural recovery with compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass834 - Digits/delta constraint expression recovery depth

Pass834 improves structural grammar coverage for Ada `digits` and `delta`
constraints by recording operand-expression metadata and bounded
missing-expression recovery metadata. This helps the token cursor distinguish
well-formed subtype constraints such as `digits 6 range ...` and `delta 0.1
 digits 4` from malformed or in-progress constraints such as `digits ;` or
`delta ;` without consuming following declarations.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions_Pass834`.
This remains structural parser metadata only; it is not compiler-grade
fixed/floating-point legality checking, static expression validation, subtype
conformance validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

## Pass830 qualified-expression operand delimiter guard

- Confirm `tools/phase579_language_validation_check.adb` requires the qualified-expression operand delimiter/recovery productions and regression test.
- Confirm AUnit includes `Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830`.
- Confirm the parser remains structural only and does not claim compiler-grade type conversion disambiguation, qualified-expression legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass829 aggregate delimiter guard

- Confirm `tools/phase579_language_validation_check.adb` requires the aggregate delimiter/separator/recovery productions and regression test.
- Confirm AUnit includes `Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829`.
- Confirm the parser remains structural only and does not claim compiler-grade aggregate legality, component-choice validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

Pass373: representation-clause static evaluation now treats Ada based literal exponents using the literal base, while decimal exponents remain decimal; unsupported expressions remain conservative.

# Release checklist

A snapshot is release-candidate material only after all required checks below pass from a clean checkout.
The release state is declared in `docs/release/RELEASE_STATE.txt`; keep it as
`RELEASE_STATE=DEVELOPMENT_SNAPSHOT` until final validation evidence exists.
Only change it to `RELEASE_STATE=RELEASE_CANDIDATE` after
`tools/bin/release_candidate_check` passes in strict mode.

## Required local checks

```sh
tools/bin/release_check
```

This Ada release tool verifies the expected release-facing files and runs all available build/test gates, including the Ada keyword identifier gate, the dependency-aware runtime C entrypoint/Ada backend gate, the dependency-aware runtime link/build gate, the dependency-aware graphical runtime smoke gate, the supplied-result product-smoke gate, and the real process-runner smoke gate when `gprbuild` is available. Set `EDITOR_REQUIRE_RUNTIME_COMPILE=1`, `EDITOR_REQUIRE_RUNTIME_LINK=1`, `EDITOR_REQUIRE_RUNTIME_EXE=1`, `EDITOR_REQUIRE_SHADER_FRESHNESS=1`, `EDITOR_REQUIRE_RUNTIME_SMOKE=1`, and `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1` on release validation machines to make missing GLFW/Vulkan/build/display/runtime dependencies or a missing canonical `bin/editor` executable fail the check. For final runtime validation on a supported graphics machine, run `tools/bin/strict_runtime_validation`; it forces the entrypoint/backend, link/build, canonical executable, shader freshness, graphical smoke, and missing-shader negative asset gates into required mode.



## Pass719 derived/tagged type extension grammar guard

- Confirm `tools/phase579_language_validation_check.adb` requires the derived/tagged extension productions and regression test.
- Confirm AUnit includes `Test_Language_Model_Token_Cursor_Derived_Tagged_Extension_Depth_Grammar_Completeness`.
- Confirm the parser remains structural only and does not claim compiler-grade tagged-type, dispatching, interface, private-completion, visibility, or freezing legality.

## Phase 579 language-model validation gate

The IDE-grade Outline and semantic-colouring phase has a dedicated Ada validation gate:

```sh
tools/bin/phase579_language_validation_check
EDITOR_REQUIRE_PHASE579_LANGUAGE_VALIDATION=1 tools/bin/phase579_language_validation_check
```

The gate is intentionally Ada-native. It performs static contract checks for the shared Ada language model, declaration parser, resolver, project index, parser-backed Outline extraction, scoped semantic-colouring path, and the phase-specific AUnit regression tests. When `gprbuild` is available it also builds `tests/tests.gpr` and runs `tests/bin/tests`. In strict mode, missing `gprbuild`, a failed test build, or a failed AUnit run is a release failure rather than a skip. This provides a repeatable GNAT/AUnit validation entry point for the phase without adding shell or Python tooling.

## Manual confirmation

- `alr build` succeeds from the repository root.
- `gprbuild -P editor.gpr` succeeds when dependencies are already available.
- `gprbuild -P tests/tests.gpr` succeeds.
- `tests/bin/tests` passes.
- `EDITOR_REQUIRE_PHASE579_LANGUAGE_VALIDATION=1 tools/bin/phase579_language_validation_check` passes on the GNAT/AUnit validation machine.
- `tools/bin/product_smoke` passes.
- `tools/bin/real_build_runner_smoke` passes.
- `tools/bin/ada_keyword_identifier_check` passes and finds no case-insensitive Ada reserved word used as an object, field, parameter, type, package, entry, procedure, or function identifier.
- `EDITOR_REQUIRE_RUNTIME_COMPILE=1 tools/bin/runtime_compile_check` passes on a machine with GLFW and Vulkan development headers installed. This is a entrypoint syntax check only.
- `EDITOR_REQUIRE_RUNTIME_LINK=1 tools/bin/runtime_link_check` passes and builds/links the runtime application through `alr build` or `gprbuild -P editor.gpr`.
- `EDITOR_REQUIRE_SHADER_FRESHNESS=1 tools/bin/shader_freshness_check` passes on a machine with `glslangValidator`; it recompiles shaders to a temporary directory and proves the checked-in `.spv` files are current.
- `EDITOR_REQUIRE_RUNTIME_SMOKE=1 tools/bin/runtime_smoke` passes on a machine with GLFW, Vulkan, and a usable display session, and logs bounded presented frames plus a verified resize-triggered swapchain recreation.
- `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1 tools/bin/runtime_missing_asset_check` passes on the release validation machine; it must force `EDITOR_SHADER_DIR_ONLY=1`, point `EDITOR_SHADER_DIR` at an empty directory, capture bounded command output with the Ada release-tool helpers, and require both a nonzero exit and diagnostic text containing `runtime asset error` and `EDITOR_SHADER_DIR_ONLY`.
- `tools/bin/strict_runtime_validation` passes on the release graphics-validation machine.
- The runtime can launch on a machine with GLFW and Vulkan installed.
- Runtime resize/minimize does not abort the process.
- Build-command execution remains behind the explicit real-execution gate.
- Workspace persistence files do not contain source-buffer text.
- No generated `obj/`, `bin/`, `lib/`, or temporary smoke directories are included in release source archives.

## Packaging contents

Source archives should include:

- `alire.toml`
- `editor.gpr`
- `editor_core.gpr`
- `src/core/`
- `src/textrender/`
- `src/runtime/`
- `src/runtime/shaders/`
- `tests/`
- `tools/`
- `README.md`
- `docs/release/RELEASE_CHECKLIST.md`
- `docs/release/SHADER_TOOLCHAIN.md`

Source archives should not include generated build products, root-level `PHASE*.md` files, `docs/history/phase-notes/`, or the old duplicate project `editor_app.gpr`; `editor.gpr` is the single release-facing runtime application project. Phase-history notes belong in a separate development-history bundle, not in the release archive.



## Runtime asset layout

The Vulkan backend must not assume that the current working directory is the repository root. Shader lookup is release-contractual and must match `README.md` and `src/runtime/render_backend_vulkan.adb`. The supported lookup order is:

1. `EDITOR_SHADER_DIR`, when set.
2. The executable directory itself, for minimal colocated bundles.
3. `shaders/` below the executable directory.
4. `../share/editor/shaders/` relative to the executable directory, for prefix-style installs.
5. `src/runtime/shaders/` for source-tree launches from the checkout root.
6. `./shaders/` for current-working-directory developer bundles.
7. `../share/editor/shaders/` relative to the current working directory.
8. `/usr/local/share/editor/shaders/`.
9. `/usr/share/editor/shaders/`.

If a shader is missing, the runtime asset check must fail with a clear `runtime asset error` naming the missing shader and the supported lookup locations. `EDITOR_SHADER_DIR_ONLY=1` is the packaging-validation mode that disables fallback lookup so `tools/bin/runtime_missing_asset_check` can verify the negative path deterministically through the display-independent `--runtime-check-shaders` path. The Ada gate captures bounded command output and fails if the expected `runtime asset error` or `EDITOR_SHADER_DIR_ONLY` diagnostic text is absent. Font atlas data is produced by the Ada/Textrender bridge and should fail with the existing explicit `font atlas not initialized` message when the bridge has not initialized it. Runtime smoke also requires the deterministic text path to trigger at least one dirty font-atlas upload and clear cycle before reporting success.


## Shader regeneration tool

The release archive ships checked-in SPIR-V shader binaries under `src/runtime/shaders/`. When shader sources change, regenerate them with:

```sh
tools/bin/compile_shaders
```

`tools/bin/compile_shaders` is an Ada release tool. It must check for `glslangValidator`, print the detected shader-toolchain version, regenerate all checked-in SPIR-V outputs, and report a clear error when the Vulkan shader toolchain is unavailable.

Freshness is checked separately by:

```sh
tools/bin/shader_freshness_check
EDITOR_REQUIRE_SHADER_FRESHNESS=1 tools/bin/shader_freshness_check
```

The freshness gate recompiles each shader to a temporary directory and byte-compares the generated SPIR-V with the checked-in `.spv` files. In non-strict mode it skips cleanly when `glslangValidator` is unavailable. In strict mode, missing `glslangValidator` or stale checked-in binaries fail the release gate.
The byte comparison is intentionally release-toolchain based. Use one chosen `glslangValidator` version for a release candidate, regenerate shader binaries with `tools/bin/compile_shaders`, and run the strict freshness gate with that same release toolchain. See `docs/release/SHADER_TOOLCHAIN.md`.

## Runtime entrypoint/backend gate

Run the runtime entrypoint/backend gate on a machine with the C compiler installed:

```sh
EDITOR_REQUIRE_RUNTIME_COMPILE=1 tools/bin/runtime_compile_check
```

The gate checks:

- `src/runtime/main.c`;
- `src/runtime/runtime_glfw.adb`;
- `src/runtime/render_backend_vulkan.ads`;
- `src/runtime/render_backend_vulkan.adb`.

The gate syntax-checks the small C entrypoint, verifies that the Ada GLFW runtime
and Ada `df_vulkan` backend files are present, and rejects the removed C backend
files if they reappear. Without `EDITOR_REQUIRE_RUNTIME_COMPILE=1`, missing C
compiler/runtime dependencies are reported as an explicit skipped check so
ordinary source-structure validation can still run on machines without graphics
development packages.


## Runtime graphical smoke gate

Run the graphical runtime smoke on a machine with GLFW, Vulkan runtime support, and a usable display session:

```sh
EDITOR_REQUIRE_RUNTIME_SMOKE=1 tools/bin/runtime_smoke
```

The smoke gate builds or reuses `bin/editor`, starts the runtime with `--runtime-smoke`, primes deterministic Ada-like text to exercise Textrender glyph acquisition and atlas upload/clear behavior, renders a bounded number of successfully presented frames, requests a resize through `--runtime-smoke-resize --runtime-smoke-resize-count=3`, verifies that the backend swapchain recreation counter advances, and exits through the normal runtime loop. Without `EDITOR_REQUIRE_RUNTIME_SMOKE=1`, missing build tools, executable, or display/session dependencies are reported as explicit skipped checks so source-structure validation can still run on headless machines.

## Strict runtime validation driver

Run the strict validation driver on the release graphics-validation machine:

```sh
tools/bin/strict_runtime_validation
```

The validation driver exports `EDITOR_REQUIRE_RUNTIME_COMPILE=1`, `EDITOR_REQUIRE_RUNTIME_LINK=1`, `EDITOR_REQUIRE_RUNTIME_EXE=1`, `EDITOR_REQUIRE_SHADER_FRESHNESS=1`, `EDITOR_REQUIRE_RUNTIME_SMOKE=1`, and `EDITOR_REQUIRE_RUNTIME_MISSING_ASSET=1`, then runs `tools/bin/runtime_compile_check`, `tools/bin/runtime_link_check`, `tools/bin/runtime_smoke`, and `tools/bin/runtime_missing_asset_check`. Missing compiler, GLFW headers, Vulkan headers, build tool, display session, Vulkan loader, executable, launch failure, render failure, resize failure, or smoke timeout therefore fails the gate instead of being reported as a dependency-aware skip.



For CI environments, `docs/release/CI_RUNTIME_VALIDATION.md` documents the
optional Xvfb + software Vulkan/lavapipe path. That CI path is allowed to catch
packaging regressions, but final runtime release validation still requires the
strict runtime validation driver on a supported graphics validation machine.

## Runtime resize gate

Before release, manually verify the Vulkan runtime resize path on a machine with Vulkan and GLFW development/runtime support:

1. Start `editor`.
2. Resize the window repeatedly, including very small sizes.
3. Minimize and restore the window.
4. Move the window between monitors if available.
5. Confirm the process does not abort, deadlock, or stop presenting after restore.

The runtime now recreates swapchain image views, framebuffers, and command buffers after out-of-date/suboptimal acquire/present results.

## Build-runner verification

- Run `tools/bin/real_build_runner_smoke` on a machine with `gprbuild`; it must build a valid temporary fixture, fail an invalid temporary fixture, capture compiler output, and ingest diagnostics. Use `EDITOR_REQUIRE_REAL_BUILD_SMOKE=1 tools/bin/real_build_runner_smoke` on release validation machines so missing `gprbuild` fails instead of skipping.
- Confirm real build execution uses explicit user consent and structured argv only.
- Confirm shell execution remains rejected.
- Confirm a positive timeout request is enforced by the native process supervisor, terminates the child process at the deadline, returns the canonical timed-out status, and preserves bounded partial output.
- Confirm the real build-runner smoke tool covers success, failure, captured output, Diagnostics ingestion, merged-output Build Output detail projection, native timeout handling, and strict-mode failure when `gprbuild` is missing. When `/bin/sleep` is present, the smoke must exercise the real native timeout branch.
- Confirm the timeout audit uses a valid structured-argv request and does not rely on opaque shell text.
- Confirm per-run build output capture files are cleaned up after success, failure, and spawn errors.
- Confirm diagnostics are ingested from captured build output after process completion.
- Confirm real-runner output capture uses separated bounded stdout/stderr streams. Supplied/test merged-output results may still be parsed through the merged fallback, but real build execution must not collapse stderr into stdout.
- Confirm `build.cancel` is advertised, palette-visible, and unavailable without an active public build job; the native real runner must register the forked child process id as the live process-control handle while the job is active, clear it on every completion/error path, and request cancellation through that handle. Jobs without a registered cancellable handle must report cancellation unsupported. No process handles, rerun payloads, or output logs may be persisted.
- Confirm `build.run` starts through the worker-backed asynchronous public build-job lifecycle instead of blocking the command route, that completion polling is non-blocking while the worker is still running, that async request/gate/result transfer uses a bounded protected slot registry keyed by the state-owned async slot and build-job id rather than package-level pending globals or a single unnamed worker payload, and that `build.cancel` can signal the published live process handle before final completion.
- Confirm `editor_tick` calls `Editor.Input_Bridge.Tick_Async_Build_Jobs` so queued async build jobs are polled on idle frames; Build Output and completion state must not depend solely on later user commands.
- Confirm project open, project switch, and project close request async build cancellation before mutating project-scoped state. The transition must defer until polling finalizes the active build, and the lifecycle shutdown path must use the same synchronized cancellation handoff as `build.cancel`.
- Confirm active build jobs append bounded source-tagged stdout/stderr chunks to Build Output while the real child process is running. Terminal emulation and unbounded output remain out of scope.
- Confirm the build-process platform contract remains explicit: the current real runner is `Native_Process_Control_POSIX` / `POSIX/fork-exec-waitpid-kill`, and the release must not claim Windows `CreateProcess` support unless a separate backend, tests, docs, and release gates are added.

- Active source/tests/release docs must use build test-seam naming, not old build-scaffold identifiers.
- Public build command guardrails must use surface entry terminology, not placeholder terminology. `build.run` is the guarded public product command; internal supplied-result/test-seam paths remain hidden and non-bindable.

## Product/test seam hygiene

- Production feature-panel APIs must not expose deterministic placeholder row population helpers.
- Synthetic outline population must remain test-fixture-only; production specs/source must not expose placeholder-specific refresh sources, target kinds, or item-population helpers.
- Product-surface cleanup audits may still detect demo/placeholder text, but they must not be the source of demo rows.


- Messages demo row population is test-only: production `Editor.Feature_Messages` exposes only real message producer/projection APIs; deterministic rows live in `tests/src/editor-feature_messages-fixtures.*`.

- Confirm synthetic outline row population remains isolated in `Editor.Outline.Fixtures`; production specs/source must not expose placeholder-specific refresh sources, source classes, target kinds, or item-population helpers, and docs must describe the active-buffer Ada extractor, selected-row navigation, stale snapshot guards, reload/revert invalidation, close-buffer navigation blocking, filtered selection boundary tests, the Ada construct matrix for child packages, separate bodies, abstract/null/overriding/operator subprograms, entries and instantiations, and current limits rather than old marker-only or navigation-disabled scaffolding.


### Generated/stale verification artifacts

The release tree intentionally excludes old Phase 577/578 verification scripts, `phase577_verification_attempt.log`, and generated Textrender atlas dumps such as `tests/atlas.pgm`. Use `tools/bin/release_check` plus the smoke gates for current verification.

## Phase 579 fix 33: public build surface promotion

The previous non-product public build command surface entries have been promoted into the actual guarded public `build.run` command surface. `build.run` is descriptor-owned, visible in the command palette, Executor-routed, structured-argv only, consent-gated, working-context validated, and connected to the bounded real build runner. The deterministic supplied-result path remains a test seam and is not a public command.


## Build UI profile implementation

- GPRbuild debug/release/validation profiles must be implemented as fixed structured argv mappings, not unsupported UI labels.
- Debug maps to `-g`; release maps to `-O2 -gnatp`; validation maps to `-gnata -gnatwa`.
- Changing a profile must invalidate consent and require the user to acknowledge the updated request identity before `build.run`.
- Non-default profiles are implemented for selected GPRbuild and Alire candidates with fixed structured argv mappings. GPRbuild uses compiler switches; Alire uses `alr build` root-crate profile switches `--development`, `--release`, and `--validation`.

- Review `docs/release/BUILD_RUNNER_PROCESS_MANAGEMENT.md` when changing process execution, timeout, or output-capture behavior.


## Syntax colouring status

The editor uses incremental Ada lexical and conservative local semantic highlighting with deterministic overlay precedence for diagnostics, search matches, and selection. Release validation must keep the syntax cache runtime-only, buffer-identity guarded, render-model consumed, and safely degrading when fixed line/token budgets are exceeded. Semantic colouring must also expose fixed-symbol-budget degradation, reuse `Editor.Ada_Syntax_Core` for declaration-learning lexical safety, consume validated Outline rows for child packages/generic formals/operator functions, and fall back to ordinary identifiers when the local symbol map overflows. `Editor.Syntax_Semantics` must not depend on `Editor.Outline_Extractor` for Ada lexical parsing, and `Editor.Outline_Extractor` must consume the shared syntax core. Core syntax tests are runtime-independent and must not require GLFW/Vulkan. See `docs/syntax_colouring.md`.

## Runtime validation split

`run_runtime_compile_check` is entrypoint syntax-only and uses `gcc -fsyntax-only`; it does not prove linker flags, GLFW/Vulkan libraries, or Ada-exported C symbols. `run_runtime_link_check` is the runtime build/link gate and must pass on release validation machines before graphical runtime smoke is considered release evidence.


Runtime smoke font-atlas validation: deterministic text must trigger atlas upload, the recorded upload must have non-zero dimensions and at least `EDITOR_RUNTIME_SMOKE_ATLAS_MIN_NONZERO_BYTES` non-zero rasterized glyph bytes, `Atlas_Dirty` must be cleared after upload, a later cache-hit frame must not redundantly upload the atlas, and the upload dimensions/non-zero-byte count/checksum must remain stable during that cache-hit frame.

Runtime smoke resize validation is multi-resize by default: `tools/bin/runtime_smoke` passes `--runtime-smoke-resize-count` using `EDITOR_RUNTIME_SMOKE_RESIZE_COUNT` (default `3`) and the runtime requires the swapchain recreation counter to advance for every requested transition. The smoke also enables deterministic zero-framebuffer smoke validation by default through `--runtime-smoke-zero-framebuffer` / `EDITOR_RUNTIME_SMOKE_ZERO_FRAMEBUFFER=1`: it calls the backend frame API with a zero framebuffer size, verifies that the skipped frame is not counted as rendered, then requires the following restore path to recreate the swapchain. This covers the minimize/zero-framebuffer recovery path that hidden GLFW smoke windows cannot exercise reliably through OS iconification alone. It complements, but does not replace, manual minimize/restore and monitor-move validation on release hardware.

Runtime smoke font-atlas summary: deterministic text must produce non-zero rasterized glyph pixels, avoid redundant atlas upload on cache-hit frames, honor EDITOR_RUNTIME_SMOKE_ATLAS_MIN_NONZERO_BYTES, and the checksum must remain stable during cache-hit validation.


## Strict runtime validation record

For final release evidence, run:

```sh
tools/bin/strict_runtime_validation_record
```

The validation driver forces the strict runtime compile, link, executable, shader freshness, graphical smoke, and missing-shader gates, then writes platform/toolchain information and per-gate logs under `build/release-validation/`. See `docs/release/STRICT_RUNTIME_VALIDATION_RECORD.md`. A report with skipped gates is not final runtime release approval.

### Runtime visual render-contract smoke


Runtime smoke execution is bounded by the runtime itself. `tools/bin/runtime_smoke` passes `--runtime-smoke-max-seconds` to `bin/editor`; the runtime loop fails with a clear smoke-timeout diagnostic if the requested frames, resize transitions, zero-framebuffer recovery, visual contract, and atlas checks do not complete within `EDITOR_RUNTIME_SMOKE_TIMEOUT_SECONDS` seconds (default `30`). This removes the release gate's dependency on an external `timeout` utility while still preventing normal smoke-loop hangs from being reported as successful validation.

Runtime smoke now enables a deterministic visual render-contract check by default through `--runtime-smoke-visual-contract` / `EDITOR_RUNTIME_SMOKE_VISUAL_CONTRACT=1`.  The backend records the most recent rendered frame's visible rectangle count, glyph count, geometry checksum, and colour checksum from the packet that was actually recorded into Vulkan command buffers.  The smoke requires at least `EDITOR_RUNTIME_SMOKE_VISUAL_MIN_RECTS` visible rectangle commands and `EDITOR_RUNTIME_SMOKE_VISUAL_MIN_GLYPHS` visible glyph commands, requires nonzero geometry/colour checksums, and keeps the strongest observed metrics across rendered smoke frames so resize-driven layout changes do not cause false failures.  This is a deterministic renderer-contract gate; it complements, but does not replace, future framebuffer readback or golden-image testing.


Shader release toolchain manifest:

```text
docs/release/SHADER_TOOLCHAIN_VERSION.txt
```

Final strict shader freshness validation requires the manifest to record the chosen release `glslangValidator --version` first line. Regenerate shaders and the manifest with:

```sh
tools/bin/compile_shaders --record-toolchain-manifest
# or, if shader binaries are already current:
tools/bin/record_shader_toolchain_manifest --from-glslang
```

A release candidate must not ship with `GLSLANG_VALIDATOR_VERSION_FIRST_LINE=UNRECORDED`.
The manifest recorder must use the selected release shader toolchain and refuses
placeholder values.


## Shell/Python tooling exclusion

Release automation is implemented as Ada tools under `tools/` and built by `tools/editor_tools.gpr`. The release source archive must not contain shell-script files, Python source files, Python bytecode, or Python cache directories.


Release tooling note: Ada release tools share bounded command-output capture helpers in `tools/editor_tool_common.*`; gates that need diagnostics should capture output through these helpers rather than depending on shell redirection. The Ada release-tool capture contract is **merged stdout/stderr**: evidence reports contain one bounded combined output stream with merged provenance, not separate stdout and stderr. Do not document these release-tool reports as two-stream captures unless the Ada helper layer grows a real two-stream process runner.


Strict runtime validation record note: `tools/bin/strict_runtime_validation_record` captures bounded per-gate command output and toolchain probe output into `build/release-validation/strict-runtime-validation.md`; console-only PASS/FAIL records are not sufficient final runtime evidence.


## Release check record

Use the Ada release evidence driver to capture a bounded `tools/bin/release_check` run:

```text
tools/bin/release_check_record
```

The report is written to `build/release-validation/release-check-validation.md` by default. Set `EDITOR_RELEASE_CHECK_REPORT_DIR` to choose another output directory.


Shader toolchain manifest note: `docs/release/SHADER_TOOLCHAIN_VERSION.txt` must carry `SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED` and a real `GLSLANG_VALIDATOR_VERSION_FIRST_LINE=...` before final strict runtime validation. Record it with `tools/bin/compile_shaders --record-toolchain-manifest` or `tools/bin/record_shader_toolchain_manifest --from-glslang`, not by hand. `UNRECORDED` is allowed only for development/source snapshots and causes strict release validation to fail.


Strict runtime preflight: final runtime validation includes the Ada `tools/bin/strict_runtime_preflight` gate before compile/link/smoke execution. In non-strict structural checks it reports missing runtime-machine requirements without failing; with `EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT=1` it fails if required tools or environment are missing. The preflight checks for `gcc`, an Ada build tool (`alr` or `gprbuild`), `glslangValidator`, a graphical session (`DISPLAY` or `WAYLAND_DISPLAY`), required runtime sources, shader binaries, and the shader toolchain manifest. `vulkaninfo` is reported as optional diagnostic context; the graphical smoke remains the authoritative Vulkan runtime gate.

## Release-candidate state gate

Before publishing or labeling an archive as release-candidate material, verify
its declared state and evidence:

```text
EDITOR_REQUIRE_RELEASE_CANDIDATE=1 tools/bin/release_candidate_check
```

The gate reads `docs/release/RELEASE_STATE.txt`. `DEVELOPMENT_SNAPSHOT` is valid
for normal source archives. `RELEASE_CANDIDATE` requires a recorded shader
manifest and passing final validation reports. This prevents a source snapshot
from being promoted by wording alone.

## Final release validation evidence gate

After the release validation machine has produced both evidence reports, run the
Ada final-evidence gate:

```text
EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1 tools/bin/release_check
```

or run the gate directly:

```text
tools/bin/final_release_validation_check
```

The gate is intentionally evidence-based. It requires:

- `docs/release/SHADER_TOOLCHAIN_VERSION.txt` to contain
  `SHADER_TOOLCHAIN_MANIFEST_STATE=RECORDED` and a real
  `GLSLANG_VALIDATOR_VERSION_FIRST_LINE=...` value.
- `build/release-validation/release-check-validation.md` to contain
  `PASS: release_check completed successfully.`
- `build/release-validation/strict-runtime-validation.md` to contain
  `PASS: strict runtime validation completed successfully.`
- Neither evidence report may contain `Result: FAIL`, `Result: TOOL NOT FOUND`,
  or `Result: NONZERO`.

Normal source-snapshot `tools/bin/release_check` runs do not require this gate;
set `EDITOR_REQUIRE_FINAL_RELEASE_VALIDATION=1` only for the final release
validation pass after the reports have been recorded on the supported runtime
machine.

- Async build worker communication must keep result-ready state, active cancellation, and active stdout/stderr snapshots behind protected handoffs (`Public_Build_Job_Registry` and `Active_Build_Process_State`), including `Publish_Active_Output_Stream` / `Active_Output_Stream`.


Async build behavioral coverage includes protected handoff state-machine checks plus a POSIX real-process cancellation integration check that starts a live `/bin/sleep` child when available, requests `build.cancel`, and verifies cancelled finalization.


Async build ownership note: each editor state receives a stable `State_Type.Public_Build_Async_Slot_Id`. A bounded protected build-job registry plus worker pool stores transient request/result payloads by slot and job id, so the implementation no longer has a single unnamed worker/handoff. The pool supports `Max_Public_Build_Async_Slots` simultaneous occupied async slots; a ninth simultaneous occupied slot is rejected with `Build unavailable: async build slot pool exhausted.` instead of silently colliding through modulo worker routing. Release checks reject the previous single-worker/single-handoff names and require the slot-exhaustion guard.
Async build slot lifetime: `State_Type.Public_Build_Async_Slot_Id` is stable for the editor state after its first public build job. It is not reset on build completion. Each new build uses a new `Public_Build_Job_Id` within the same state slot, while transient request/result payloads are cleared from the protected job registry. This keeps worker-pool routing stable without treating the slot id as per-build state.

- Async build shutdown: `Drain_Public_Build_Worker_For_Shutdown` requests cancellation, drains the state slot worker, polls final completion, and clears active process handoff state for deterministic application-exit cleanup.


- Async build workers must support both lifecycle drain and final application-exit stop. The release gate requires `entry Stop`, `Stop_Public_Build_Workers_For_Application_Exit`, and the worker-stop behavioral test.


## Ada language intelligence guards

- `release_check` requires and runs the dedicated Ada `phase579_language_validation_check` gate.
- `phase579_language_validation_check` owns the Phase 579 source, test, documentation, and strict GNAT/AUnit checks so the release orchestrator does not duplicate brittle marker walls.
- Outline and syntax-colouring documentation must describe the implemented language-model path and must not regress to the old local-only wording.


Pass 3 hardening: the Ada declaration parser now distinguishes real scope-closing `end` statements from non-declaration constructs such as `end if`, `end loop`, `end case`, and `end select`; this prevents control-flow syntax inside bodies from invalidating lexical parent stamps used by Outline and semantic colouring. Same-line record discriminants are parented to the record type symbol, matching multi-line discriminants and components. `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` resolves from an actual parent-symbol chain and returns the nearest lexical overload set before falling back to enclosing scopes.

Pass 4 hardening: the Ada declaration parser now records private-section metadata for declarations following a package `private` marker, carries parent-unit metadata from standalone `separate (...)` clauses to the following body declaration, and the project language index exposes `Contains_Current` so callers can reject stale path/token/revision/lifecycle/fingerprint combinations before using indexed navigation targets. `Invalidate_Lifecycle` clears analyses associated with a closed or switched project generation.

Pass 5 hardening: enumeration literals are parented to their defining type symbol, including character enumeration literals, so scope-aware semantic colouring and Outline metadata do not flatten enumeration members into the enclosing package. The Ada resolver also resolves selected names by exact dotted match first and then by resolving the prefix scope before resolving the leaf declaration, covering in-buffer names such as `Pkg.Name` without claiming compiler-grade visibility rules.

### Ada language model profile/formal-object guard

- Release validation must keep direct parser support for generic formal object declarations.
- Subprogram, generic-formal-subprogram, and operator-function symbols must retain bounded profile summaries in `Editor.Ada_Language_Model` for outline disambiguation metadata.
- Tests must cover both formal-object classification and profile-summary retention.

Pass 7 hardening: the Ada project index must keep bounded cross-file symbol lookup with source path/key metadata, and the declaration parser must preserve generic formal package `is new` target metadata. Release validation should keep these as real parser/index APIs with tests, not documentation-only claims.

- Ada language-intelligence checks must confirm project-index qualified lookup rejects unrelated same-leaf matches by using parser-owned parent chains.

- Ada parser guards cover private child package canonical names and representation-clause `end record;` terminators so they cannot close the enclosing package scope.

- Ada parser guards must cover multi-line enumeration literals, including character literals, parented to the defining type without corrupting the enclosing package scope.

Pass 11 hardening: same-line record discriminant extraction now uses a discriminant-specific slice of the parenthesized type header. This prevents the parser from learning the `type` keyword or the record type name itself as `Symbol_Discriminant` when parsing declarations such as `type Rec (Id : Natural) is record`; only the actual discriminant identifiers are added under the record type.


- Same-line record discriminant ranges preserve original source columns for outline navigation and semantic diagnostics.

- Pass 13 guard: semantic colouring must retain parser-owned value-like symbols from `Editor.Ada_Language_Model` instead of dropping objects, constants, exceptions, record components, discriminants, and enumeration literals to ordinary identifiers.

### Ada language model subprogram-parameter guard

- `Editor.Ada_Declaration_Parser` must retain same-line callable profile parameters through `Add_Profile_Parameter_Names` or an equivalent parser-owned routine.
- Tests must cover procedure/operator parameter parenting and semantic-map classification from `Build_Map_From_Analysis`.
- Parameter extraction must remain bounded and parser-owned; it must not reintroduce outline-specific line recognizers.

### Ada language model multi-line profile-parameter guard

- `Editor.Ada_Declaration_Parser` must retain parser-owned pending profile state for callable profiles split across lines.
- Continuation-line parameter names must be parented to the owning callable symbol and preserve source line metadata.
- Tests must cover multi-line procedure profile parameter parenting and semantic-map classification from `Build_Map_From_Analysis`.
- Confirm split type-header record parsing remains covered by `Test_Language_Model_Split_Type_Header_Record` and guarded by `release_check`.

- Verify scope-aware semantic colouring keeps using `Editor.Syntax_Semantics.Kind_For_Identifier_In_Scope` and `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` for validated parser-owned analysis, with regression coverage for shadowed identifiers.

### Ada language model multi-name generic formal object guard

- `Editor.Ada_Declaration_Parser` must keep all names from generic formal object declarations, including `with`-prefixed formal object declarations.
- Tests must cover non-leading names and confirm they carry generic metadata and classify as semantic generic formals.

### Ada split-profile body scope guard

- `Editor.Ada_Declaration_Parser` must open the owning callable scope when pending callable-profile parsing consumes a later body-opening `is` line.
- Tests must cover local declaration parenting inside a split-profile body through `Test_Language_Model_Split_Profile_Body_Opens_Callable_Scope` or equivalent.

### Ada separate body semantic-kind guard

- `Editor.Ada_Declaration_Parser` must upgrade validated `separate (...)` body
  declarations to `Symbol_Separate_Body` while preserving `Flags.Is_Separate`
  and target metadata.
- `Editor.Ada_Language_Model.Kind_To_Syntax_Kind` must keep
  `Symbol_Separate_Body` in the callable/subprogram semantic token bucket.
- AUnit coverage must include `Test_Language_Model_Separate_Body_Kind_And_Semantics`
  or equivalent.

Pass 21 hardening: `Editor.Ada_Project_Index` now exposes current-stamped symbol resolution (`Resolve_Current`, `First_Current_Match`, and `Has_Current_Match`) in addition to broad project lookup. Callers that already validated a buffer path/token/revision/lifecycle/fingerprint can ask the index to return only symbols from that exact current analysis, so navigation and semantic consumers do not need to broad-resolve first and filter stale targets afterwards.

- Pass 22 hardening: Ada language-model tests cover ordinary, limited-private, and generic formal private type declarations carrying `Is_Private` without losing their type or formal-type symbol kind.

### Ada derived type non-instantiation guard

- `Editor.Ada_Declaration_Parser` must not set `Flags.Is_Instantiation` merely because a type declaration contains the Ada keyword `new`.
- Derived ordinary types and record extensions must remain type/record-type symbols.
- Package/procedure/function instantiations must still retain instantiation kind/metadata.
- AUnit coverage must include `Test_Language_Model_Derived_Types_Are_Not_Instantiations` or equivalent.


### Ada variant record component guard

- `Editor.Ada_Declaration_Parser` must keep variant-record component extraction sliced after the last choice arrow before the component colon.
- AUnit coverage must include `Test_Language_Model_Variant_Record_Components_Strip_Choices` or equivalent, verifying that `when`, `others`, and choice expressions are not learned as record components.
- Verify split procedure and split function body forms keep local declarations under the callable symbol after profile/return-continuation lines.

### Ada entry-family profile-parameter guard

- `Editor.Ada_Declaration_Parser` must scan multiple same-line callable profile groups so entry-family declarations retain parameters from the second profile.
- Tests must cover `Test_Language_Model_Entry_Family_Profile_Parameters` or equivalent, including rejection of unnamed family-index subtype names as parameter symbols.

- Release checks require parser/test coverage for generic formal type discriminants, including split formal type headers.

### Ada entry body barrier guard

- `Editor.Ada_Declaration_Parser` must keep entry body barriers out of callable profile summaries while still opening the entry body scope at `is`.
- Tests must cover entry-body barrier profile trimming, entry parameter retention, and local declaration parenting inside the entry body.
- Confirm task/protected type discriminants remain parser-owned symbols and are covered by semantic-colouring tests.
- Verify multi-name discriminant groups keep every declared name, including non-leading task/protected discriminants.
- Verify access-to-subprogram type profiles are not learned as discriminants or callable parameters, and that following declarations remain in the enclosing scope.

### Ada split concurrent type header guard

- Confirm split task/protected type headers retain parser-owned discriminants and open the concurrent type scope at the later `is` line.
- Release checks require `Test_Language_Model_Split_Concurrent_Type_Discriminants_And_Scope` or equivalent coverage.

- Verify derived type and record-extension declarations retain parent target metadata and are not flagged as generic instantiations.

### Ada subtype target metadata guard

- Verify subtype declarations retain subtype-mark target metadata, including `not null` access subtypes where the null-exclusion keywords are skipped before storing the target type name.

- Verify parser coverage includes split `type T is` / `record` record-scope opening and component parenting.

- Verify object, constant, and exception rename declarations keep value-like symbol kinds, `Is_Rename`, and target metadata via `Test_Language_Model_Object_Renames_Keep_Value_Kinds`.

### Ada generic formal derived type target guard

- `Editor.Ada_Declaration_Parser` must preserve parent subtype targets for generic formal derived type declarations such as `type Child is new Root with private;`.
- Tests must verify the symbol remains a generic formal type, keeps generic/private metadata, records the parent target, and is not flagged as an instantiation.

### Ada composite type target metadata guard

- Verify array type declarations retain component subtype target metadata without learning index constraints as child symbols.
- Verify access-to-object declarations retain designated subtype target metadata while access-to-subprogram profile names remain metadata-only.

- Verify subtype, array component, and access-object target metadata preserves class-wide/base subtype marks such as `Root'Class` instead of truncating at the apostrophe.

- Pass 39: Ada body stubs (`procedure P is separate;`, `package body P is separate;`) retain `Is_Separate` metadata without opening parser scopes that capture following declarations.


Phase 579 language-model pass 40 note: package/subprogram renames keep their package/callable semantic kinds while carrying `Is_Rename` and `Target_Name`; they no longer collapse to a generic rename-only bucket.

- Phase 579 language-model pass 41: verify aspected subprogram declarations keep aspect clauses out of profile summaries while retaining parameter child symbols.

### Ada object/component target metadata guard

- Verify `Object_Target_After_Colon` remains in `Editor.Ada_Declaration_Parser` and that object, constant, record-component, discriminant, generic-formal-object, and profile-parameter symbols retain subtype target metadata when a subtype mark is available.
- Verify exception declarations keep empty target metadata and do not treat the `exception` keyword as a subtype target.
- Keep `Test_Language_Model_Object_And_Component_Target_Metadata` as direct regression coverage.

### Ada interface type target metadata guard

- Verify interface type declarations remain type-like symbols and do not open parser scopes.
- Verify parent-interface targets are retained for `interface and Parent` and `limited interface and Parent` forms.
- Keep `Test_Language_Model_Interface_Type_Target_Metadata` as direct regression coverage.

- Keep `Test_Language_Model_Access_Subprogram_Objects_Do_Not_Use_Procedure_Target` as regression coverage for anonymous access-to-subprogram object declarations.
- Keep `Test_Language_Model_Anonymous_Array_Object_Target_Metadata` as regression coverage for anonymous array object target metadata.

- Keep `Test_Language_Model_Function_Return_Target_Metadata` as regression coverage for function and generic formal function result subtype target metadata.

### Ada generic formal composite type target guard

- `Editor.Ada_Declaration_Parser` must preserve target metadata for generic formal array, access-to-object, and interface-extension types.
- Access-to-subprogram formal types must not invent `procedure`/`function` target metadata or anonymous profile child symbols.
- Tests must cover all of those cases through the shared language model.

- Keep `Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata` as regression coverage that anonymous access-to-subprogram function result profiles are retained as callable metadata without creating target names or child parameter symbols.


Phase 579 language-analysis pass 50 guard: release checks require coverage for task/protected headers that contain inline discriminants before a later `is`, ensuring concurrent type scope ownership is not lost after discriminant extraction.

Phase 579 language-analysis pass 49 note: the Ada declaration parser now retains designated subtype target metadata for split access-to-object type declarations, including generic formal access types such as `type Ref is access` followed by `all Element;`, by using parser-owned pending target state rather than opening a false type scope.
Phase 579 language-analysis pass 51 note: the Ada declaration parser now retains element subtype target metadata for split array type declarations, including generic formal arrays such as `type Element_Array is array` followed by `(Positive range <>) of Element;`, by using parser-owned pending array target state rather than opening a false type scope.

- Verify split function return-line target metadata: multi-line function specs and bodies must retain the result subtype in the shared Ada language model, and local declarations after a later `is` must remain parented to the function body.

Phase 579 language-analysis pass 53 note: the Ada declaration parser now retains element subtype target metadata for split anonymous-array object and constant declarations such as `Values : array` followed by `(Positive range <>) of Element;`. Parser-owned pending object-array target state stamps the already-emitted object/constant symbols when the continuation supplies the `of <subtype>` clause, without opening a false scope. This pass also removed an accidental duplicate nested `Skip_Blanks` declaration in `Skip_Component_Qualifiers`.

- Keep `Test_Language_Model_Split_Anonymous_Access_Object_Target_Metadata` as regression coverage for split anonymous access-to-object declarations that retain designated subtype target metadata without opening false scopes.
- Keep `Test_Language_Model_Split_Object_And_Component_Target_Metadata` as regression coverage for ordinary split object, constant, and record-component declarations that retain subtype target metadata from their header line without learning continuation metadata as false declarations.
- Keep `Test_Language_Model_Split_Subtype_Target_Metadata` as regression coverage for split subtype declarations that retain class-wide/range base target metadata without learning continuation metadata as false declarations.
- Keep `Test_Language_Model_Split_Rename_And_Instantiation_Target_Metadata` as regression coverage for split package instantiations and package/subprogram renames that retain continuation-line target metadata without learning false declarations.
- Keep `Test_Language_Model_Split_Derived_Type_Target_Metadata` as regression coverage for split derived type, generic formal derived type, and derived record extension target metadata without false scopes.

- Keep `Test_Language_Model_Split_Generic_Formal_Object_Target_Metadata` as regression coverage for split `with`-formal object declarations that retain generic formal kind/flags and continuation subtype target metadata without learning ordinary object declarations from metadata lines.

- Keep `Test_Language_Model_Split_Interface_Type_Target_Metadata` as regression coverage for ordinary and generic formal split interface declarations that carry their parent interface target on a continuation line without opening false scopes.


- Keep `Test_Language_Model_Generic_Formal_Subprogram_Default_Target_Metadata` as regression coverage for generic formal subprogram defaults. Same-line and split `with procedure ... is Default_Name`, `is <>`, and `is null` forms must retain explicit target metadata, and split formal defaults must not open a false subprogram body scope.

- Keep `Test_Split_Generic_Formal_Package_Target_Metadata` as regression coverage for split generic formal package declarations that retain formal-package kind, generic/instantiation flags, and continuation target metadata whether `is` or `new` appears on a later line.

- Keep `Test_Language_Model_Split_Access_Function_Result_Target_Metadata` as regression coverage for split anonymous access-to-object function results that retain designated subtype target metadata without corrupting following declarations.


- Keep `Test_Language_Model_Split_Access_Subprogram_Type_Profile_Metadata` as regression coverage for split access-to-subprogram type declarations. The parser must retain the callable profile summary on the type/formal-type symbol while preventing anonymous profile parameter names from leaking into Outline or semantic colouring.
- Keep `Test_Language_Model_Split_Access_Subprogram_Object_Profile_Metadata` as regression coverage for anonymous access-to-subprogram object/constant declarations. The parser must retain callable profile summaries on the object symbols and must not leak anonymous profile parameters into Outline or semantic colouring.

- Keep the pass 65 split object/exception renaming coverage in `Test_Language_Model_Split_Rename_And_Instantiation_Target_Metadata`: value-like renames split before their target continuation must keep `Is_Rename`, semantic kind, and continuation-line `Target_Name` without opening false scopes.

- Keep `Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata` and `Test_Language_Model_Split_Access_Function_Result_Target_Metadata` as regression coverage for anonymous access-to-subprogram function results. The parser must retain callable result-profile summaries on the function symbol and must not leak anonymous result-profile parameters into Outline or semantic colouring.
- Keep protected access-to-subprogram profile coverage in `Test_Language_Model_Split_Access_Subprogram_Type_Profile_Metadata` and `Test_Language_Model_Split_Access_Subprogram_Object_Profile_Metadata`; the parser must preserve the `protected` prefix without learning anonymous profile parameters as symbols.

- Keep protected anonymous access-to-subprogram function-result coverage in `Test_Language_Model_Function_Access_Subprogram_Result_Profile_Metadata` and `Test_Language_Model_Split_Access_Function_Result_Target_Metadata`; the parser must preserve the `protected` callable profile prefix without stamping `protected` as `Target_Name` or learning anonymous result-profile parameters as symbols.

- Keep `Test_Language_Model_Generic_Formal_Access_Subprogram_Object_Profile_Metadata` as regression coverage for same-line and split generic formal access-to-subprogram object declarations. They must remain `Symbol_Generic_Formal_Object`, retain generic flags, store callable profile summaries, keep empty target names, and avoid leaking anonymous profile parameters into Outline or semantic colouring.

- Keep `Test_Language_Model_Profile_Access_Subprogram_Parameter_Metadata` as regression coverage for subprogram/entry parameters declared as anonymous access-to-subprogram values. The parser must retain callable profile metadata on the parameter symbol without leaking nested callback-profile parameters into Outline or semantic colouring.

- Keep `Test_Language_Model_Split_Access_Object_Parameter_Target_Metadata` as regression coverage for callable parameters declared as split anonymous access-to-object values. The parser must keep the parameter under the callable symbol, stamp the continuation-line designated subtype target, and avoid learning the continuation as a standalone declaration.


Phase 579 pass 195 representation-clause note: Ada representation clauses such as `for T use record ... end record;` and address/size clauses are retained as bounded declaration metadata on the referenced symbol when the declaration is present in the current analysis. They do not create standalone Outline rows, they do not open or close language-model scopes, and unresolved representation targets are ignored rather than guessed. Generated-source and conditional-source markers are retained as bounded awareness metadata; interpreting or expanding generated/conditional source remains a conservative non-goal.

- Phase 579 pass 196: verify indexed `outline.goto-body` / `outline.goto-spec` refuse apparent unique targets when the Ada project index or any retained per-file analysis overflowed. Separate-body `outline.goto-spec` must also reject overflowed or duplicate parent candidates rather than picking the first retained parent.

Phase 579 pass 198 documentation consistency guard: Outline and syntax-colouring docs must describe parser-owned language-model semantic/outline analysis as the preferred product path. They must not regress to stale wording that says representation clauses are only safely skipped, generated/conditional awareness is completely absent, or semantic colouring primarily performs local declaration extraction.


Phase 579 pass 199 release-guard maintainability note: `release_check` now delegates the IDE-grade Ada language-model regression surface to `phase579_language_validation_check` instead of retaining a long duplicated source-string guard. The dedicated gate groups checks by architecture, parser/model metadata, resolver/index behavior, regression tests, documentation freshness, and optional strict GNAT/AUnit execution.

- Phase 579 pass 200: body/spec Outline navigation must revalidate exact project-index target keys at execution time. Open-buffer targets must match buffer token, revision, lifecycle generation, and analysis fingerprint; stale projected targets must degrade to unavailable.


Phase 579 pass 201: the language validation gate also requires regression coverage proving declaration-navigation availability rejects stale or out-of-range Outline targets before execution.

- Phase 579 pass 202: strict language validation must continue to guard normalized indexed navigation execution. `outline.goto-body` / `outline.goto-spec` execution must revalidate exact project-index keys and compare active target paths through the normalized path handoff rather than raw string equality.

### Phase 579 pass 203 command surface check

- Confirm Outline command documentation exposes canonical dotted stable names for the daily-use Outline surface: `outline.refresh`, `outline.clear`, `outline.show`, `outline.focus`, `outline.open-selected`, `outline.select-current-symbol`, `outline.reveal-current-symbol`, `outline.select-next`, `outline.select-previous`, and the `outline.filter.*` commands.
- Confirm removed legacy spellings such as `refresh-outline` and `open-selected-outline-item` remain rejected and absent from user-facing documentation. The compatibility aliases `select-current-outline-symbol`, `select-next-outline-item`, and `select-previous-outline-item` may remain accepted only to preserve existing keybinding files; exported defaults and docs must use the canonical dotted names.

Phase 579 pass 204 parser-completeness check: the language-model validation gate requires aspect-specification metadata support, parser detection, and tests proving that package/type/subprogram aspect clauses are retained as declaration metadata without polluting callable profiles or symbol scopes.

- Phase 579 pass 205: run `phase579_language_validation_check` to confirm entity pragmas are retained as declaration metadata (`Has_Pragma_Metadata`) without polluting the language-model symbol table.


Pass 206 parser-completeness update: Ada context `with` clauses and `use` / `use type` / `use all type` clauses are retained as bounded analysis metadata. They do not create Outline rows, do not create declaration symbols for imported package names, and do not change scope ownership; they only stamp the parser-owned analysis so caches, docs, and conservative language consumers can distinguish source that depends on context/use visibility clauses.

- Phase 579 pass 207: confirm `tools/phase579_language_validation_check.adb` guards null-exclusion declaration metadata and the regression test `Test_Language_Model_Null_Exclusions_Are_Metadata` remains present.

- Phase 579 pass 208: confirm `tools/phase579_language_validation_check.adb` guards aliased declaration metadata and the regression test `Test_Language_Model_Aliased_Metadata_Does_Not_Pollute_Symbols` remains present.

- Phase 579 pass 209: verify bounded type-qualifier metadata (`Has_Limited_Metadata`, `Has_Tagged_Metadata`, `Has_Interface_Metadata`) and the `Test_Language_Model_Type_Qualifier_Metadata` regression remain present.

- Phase 579 pass 210: verify bounded synchronized interface metadata (`Has_Synchronized_Metadata`) and the `Test_Language_Model_Synchronized_Metadata` regression remain present.

- Phase 579 pass 211: verify access/array declaration-form metadata remains parser/model-owned and does not add `access` or `array` as semantic symbols.

- Phase 579 pass 212: confirm derived type declaration metadata is present in `Editor.Ada_Language_Model`, parsed by `Editor.Ada_Declaration_Parser`, exposed in Outline details, and covered by `Test_Language_Model_Derived_Type_Metadata`.

- Phase 579 pass 213: confirm scalar numeric declaration-form metadata is present in `Editor.Ada_Language_Model`, parsed by `Editor.Ada_Declaration_Parser`, exposed in Outline details, and covered by `Test_Language_Model_Scalar_Type_Metadata` without adding `range`, `mod`, `digits`, or `delta` as semantic symbols.


Pass 214 extends parser-owned Ada declaration metadata with bounded access-to-subprogram awareness. Access procedure/function and access protected procedure/function declarations retain `access-subprogram` metadata on the owning symbol without learning anonymous profile names as declarations.

- Phase 579 pass 215: run the language validation gate and confirm variant-record metadata coverage remains present (`Has_Variant_Record_Metadata`, `Test_Language_Model_Variant_Record_Metadata`) without adding variant `case`/`when` syntax as semantic symbols.

- Phase 579 pass 216: confirm default-expression declaration metadata is present in `Editor.Ada_Language_Model`, parsed by `Editor.Ada_Declaration_Parser`, exposed in Outline details, and covered by `Test_Language_Model_Default_Expression_Metadata` without adding default-expression syntax as semantic symbols.

- Phase 579 pass 217: confirm entry-family declaration metadata is present in `Editor.Ada_Language_Model`, parsed by `Editor.Ada_Declaration_Parser`, exposed in Outline details, and covered by `Test_Language_Model_Entry_Family_Metadata` without adding entry-family index subtype names as declaration symbols.


Pass 218 parser-completeness note: incomplete type declarations (`type T;` and `type T is tagged;`) are retained as bounded language-model metadata (`incomplete-type`) on the owning type symbol. They do not open scopes, create completion targets, or learn syntax keywords as semantic identifiers.

- Pass 219: run the Phase 579 validation gate with profile-mode metadata markers present in the language model, parser, Outline detail projection, and regression tests.

- Pass 220: run the Phase 579 validation gate with entry-barrier metadata markers present in the language model, parser, Outline detail projection, and regression tests.

- Pass 221 language validation requires `Has_Box_Metadata`, parser detection, and `Test_Language_Model_Box_Metadata` so Ada box (`<>`) syntax remains bounded declaration metadata rather than a semantic-name source.

- Phase 579 pass 222: verify access-mode declaration metadata remains present (`Has_Access_All_Metadata`, `Has_Access_Constant_Metadata`) and covered by `Test_Language_Model_Access_Mode_Metadata` without adding `all` or `constant` access-mode keywords as semantic symbols.


- Phase 579 pass 223: verify class-wide subtype-mark metadata remains present (`Has_Class_Wide_Metadata`) and covered by `Test_Language_Model_Class_Wide_Metadata` without adding `Class` attribute designators as semantic symbols.


Pass 224 parser completeness note: Ada private extension forms such as `type T is new Parent with private;` are retained as bounded declaration metadata (`private-extension`) on the owning symbol. The parser does not infer completion legality or expose `with private` syntax as separate symbols.

Pass 225 parser completeness note: language validation requires `Has_Named_Number_Metadata`, parser detection, and `Test_Language_Model_Named_Number_Metadata` so Ada named-number declarations remain bounded declaration metadata rather than expression-symbol sources.

- Pass 226 language parser metadata: confirm null subprogram and expression-function markers remain parser-owned metadata (`Has_Null_Subprogram_Metadata`, `Has_Expression_Function_Metadata`) and remain covered by `Test_Language_Model_Null_Subprogram_And_Expression_Function_Metadata`.

- Pass 227 language parser metadata: confirm `Has_Null_Record_Metadata`, parser detection, Outline detail projection, and `Test_Language_Model_Null_Record_Metadata` remain present so Ada `null record` forms stay bounded declaration metadata rather than synthetic components.

- Pass 228: confirm discriminant-part metadata remains parser-owned and bounded. `Has_Discriminant_Part_Metadata` must be present in the language model, parser detection, Outline detail projection, validation guard, and AUnit coverage (`Test_Language_Model_Discriminant_Part_Metadata`).

- Pass 229: confirm body-stub metadata remains parser-owned and bounded. `Has_Body_Stub_Metadata` must be present in the language model, parser detection, Outline detail projection, validation guard, and AUnit coverage (`Test_Language_Model_Body_Stub_Metadata`).


- Phase 579 pass 230: verify overriding/not-overriding indicator metadata remains parser-owned, covered by regression tests, and projected only as declaration detail.

- Pass 231: confirm deferred-constant metadata remains parser-owned and bounded. `Has_Deferred_Constant_Metadata` must be present in the language model, parser detection, Outline detail projection, validation guard, and AUnit coverage (`Test_Language_Model_Deferred_Constant_Metadata`).


Pass 232: the Ada declaration parser retains bounded subtype/discriminant/index constraint metadata on owning declarations. Constraint expressions, bounds, and generic actual lists remain non-declarative and do not create Outline rows or semantic symbols.

- Pass 233: verify child library-unit metadata remains parser-owned and covered by `Test_Language_Model_Child_Unit_Metadata`; dotted package/subprogram unit names must not introduce parent-name segment symbols or bypass project-index lifecycle checks.

- Phase 579 pass 234: verify Outline detail projection includes parser-owned abstract declaration metadata and rejects regressions that hide `abstract` from navigation details.

- Pass 235: verify access-protected metadata remains parser-owned and covered by `Test_Language_Model_Access_Protected_Metadata`; `access protected procedure` / `access protected function` forms must not create extra Outline rows or semantic declarations for callable-profile syntax.

- Pass 236: verify task/protected interface metadata remains parser-owned and covered by `Test_Language_Model_Task_And_Protected_Interface_Metadata`; `task interface` and `protected interface` forms must not create extra Outline rows or semantic declarations for qualifier keywords.

Phase 579 pass 237 note: the Ada parser now retains bounded `task type` and `protected type` declaration-form metadata separately from single task/protected declarations. Outline details may show `task-type` or `protected-type`; the keywords remain non-symbol metadata and do not affect scope legality analysis.

- Pass 238: verify generic-instantiation actual-part metadata remains bounded: instantiation symbols may carry `generic-actuals`, while actual expressions do not create Outline rows or semantic symbols.

- Phase 579 pass 239: verify split Ada aspect clauses are stamped on the owning language-model declaration and do not create context-clause awareness or semantic symbols for aspect names.

Phase 579 pass 240: release validation now requires parser-owned statement awareness metadata in `Editor.Ada_Language_Model`, parser recognition for common Ada executable statements, AUnit coverage for body statement counting, and documentation that distinguishes statement awareness from declaration Outline rows.  This closes the first major gap toward broader Ada syntax support without claiming compiler-grade statement/expression AST completeness.

Phase 579 pass 241: release validation and tests cover the expanded statement-awareness set for conditional alternatives, case/exception `when` alternatives, exception sections, and select `terminate` alternatives.  The guard remains intentionally scoped to parser-owned metadata rather than a full statement AST.

Phase 579 pass 242: release validation now guards the labelled-statement path by requiring `Statement_Label`, label stripping in the declaration parser, and statement-awareness tests that prove labelled calls/assignments are classified without creating Outline declarations.

Phase 579 pass 243: release validation now guards named block/loop statement awareness by requiring `Statement_Named_Block`, `Statement_Named_Loop`, parser normalization of `Name : declare/begin/loop/for/while ... loop`, and AUnit coverage proving named statements retain their underlying statement kind without polluting Outline or semantic declarations.

Phase 579 pass 244: release validation now guards select-alternative statement awareness by requiring `Statement_Or_Alternative` and `Statement_Then_Abort_Alternative` in the language model plus AUnit coverage for ordinary selective accept and asynchronous select syntax.

Phase 579 pass 245: release validation now guards structured statement terminator awareness by requiring `Statement_End_If`, `Statement_End_Case`, `Statement_End_Loop`, and `Statement_End_Select` in the language model, parser recognition, and AUnit coverage.  Record variant `end case` must remain excluded from executable statement metadata.

Phase 579 pass 246: release validation now guards extended-return statement awareness by requiring `Statement_Extended_Return`, `Statement_End_Return`, parser markers, and statement-awareness tests for `return Obj : T do ... end return;` plus initialized extended returns.

Phase 579 pass 247: release validation now guards accept-body and delay-form statement awareness by requiring `Statement_Accept_Body`, `Statement_Delay_Relative`, `Statement_Delay_Until`, parser markers, and AUnit coverage for accept statements with `do` parts plus relative `delay` and `delay until` forms.

Phase 579 pass 248: release validation now guards conditional exit, raise-with-message, and requeue-with-abort statement awareness by requiring `Statement_Exit_When`, `Statement_Raise_With_Message`, and `Statement_Requeue_With_Abort` in the language model, parser recognition, and AUnit coverage.

Phase 579 pass 249: release validation now guards Ada code-statement awareness by requiring `Statement_Code`, parser-side `Looks_Like_Code_Statement`, and AUnit coverage proving qualified-expression code statements are not flattened into call-statement metadata.

Phase 579 pass 250: release validation now guards procedure-call argument awareness by requiring `Statement_Call_With_Arguments`, `Statement_Call_With_Named_Association`, parser-side named-association recognition, and AUnit coverage proving named-association calls are retained as calls while code statements stay separate.

Phase 579 pass 251: release validation now guards stacked labelled-statement awareness by requiring parser-side `Leading_Statement_Label_Count` and `Mark_Leading_Statement_Labels`, with AUnit coverage proving multiple leading labels are counted individually while the labelled call remains classified.

Phase 579 pass 252: release validation now guards selected-name call statement awareness by requiring `Statement_Call_Selected_Name`, parser-side `Call_Has_Selected_Name`, and AUnit coverage proving selected calls remain ordinary calls while retaining selected-call metadata.

Phase 579 pass 253: release validation guards `Statement_Null_Alternative`, parser recognition of executable null alternatives, and AUnit coverage proving record variant null alternatives are not misclassified as executable statement metadata.

Phase 579 pass 254: release validation guards alternative-action statement metadata (`Statement_Alternative_Raise`, `Statement_Alternative_Return`, `Statement_Alternative_Assignment`, and `Statement_Alternative_Call`) and AUnit coverage for simple actions following executable alternative arrows.

Phase 579 pass 255: release validation guards the expanded alternative-action statement set (`Statement_Alternative_Exit`, `Statement_Alternative_Goto`, `Statement_Alternative_Delay`, `Statement_Alternative_Requeue`, and `Statement_Alternative_Abort`) plus AUnit coverage for control/tasking actions following executable alternative arrows.

Phase 579 pass 256: executable alternative-action metadata now preserves the same bounded call/code shape used for ordinary statements.  Calls after `=>` can retain argument-list, named-association, and selected-name metadata, while qualified-expression code actions are counted as `Statement_Alternative_Code` plus `Statement_Code` and are deliberately not flattened into call metadata.

- Phase 579 pass 257: verify compact same-line statement sequences remain parser-owned metadata only.  Tests must cover inline null actions and inline terminators without creating Outline rows or semantic symbols.

Phase 579 pass 258: release validation now guards Ada `for` loop iteration-scheme statement awareness by requiring `Statement_For_In_Loop`, `Statement_For_Of_Loop`, `Statement_For_Reverse_Loop`, parser-side marking, and AUnit coverage for discrete, container, and reverse loop forms.

- Phase 579 pass 259 guard: release validation requires named loop terminator statement-awareness support (`Statement_End_Named_Loop`) in the language model, parser, and AUnit coverage.

- Phase 579 pass 260 guard: release validation requires return-expression statement-awareness support (`Statement_Return_With_Expression` and `Statement_Alternative_Return_With_Expression`) in the language model, parser, and AUnit coverage.

- Phase 579 pass 261 guard: release validation requires assignment target-shape statement-awareness support (`Statement_Assignment_Selected_Target`, `Statement_Assignment_Indexed_Target`, and `Statement_Assignment_Slice_Target`) in the language model, parser, and AUnit coverage.

- [ ] Pass 262: verify statement-awareness coverage still includes selected-name and comma-separated abort target metadata, and that abort target syntax does not create Outline rows, semantic declaration symbols, scopes, or navigation targets.

- [ ] Pass 263: verify statement-awareness coverage still includes selected-name and argument/index requeue target metadata, and that requeue target syntax does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

- [ ] Pass 264: verify statement-awareness coverage still includes accept profile and accept entry-family/index metadata, and that accept statement syntax does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

- [ ] Pass 265: verify statement-awareness coverage still includes explicit access dereference call and assignment-target metadata, and that `.all` statement syntax does not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

- Pass 266 language-model guard: parser-owned statement awareness must retain entry-family shaped call metadata (`Statement_Call_Entry_Family_Index`) for direct and alternative call actions without creating Outline rows or semantic symbols.

- Pass 267: verify statement-awareness coverage includes raise-form metadata (`Statement_Raise_Reraise`, `Statement_Raise_Exception_Name`, and `Statement_Raise_With_Message`) and that raise statements remain parser metadata only, not Outline rows or semantic declaration symbols.

- Pass 268: verify statement-awareness coverage includes named-loop exit metadata (`Statement_Exit_Named_Loop`) for ordinary and alternative exit statements, and that exit target names are not promoted into Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 269 guard: parser statement-awareness coverage includes selective-accept delay alternatives (`or delay ...;` and `or delay until ...;`) as metadata only, with tests and release-check markers.

- Pass 270 guard: parser statement-awareness coverage includes same-line selective-accept alternatives (`Statement_Accept_Alternative`) while ensuring embedded accept/profile/family/body syntax remains parser metadata only and does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 271 language-model guard: parser-owned statement awareness must retain same-line asynchronous-select `then abort` action metadata (`Statement_Then_Abort_Action`) and AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 272 language-model guard: parser-owned statement awareness must retain compact same-line `if ... then` action metadata (`Statement_Then_Action`) and AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 273 language-model guard: parser-owned statement awareness must retain compact same-line `if ... else` action metadata (`Statement_Else_Action`) and AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 274 language-model guard: parser-owned statement awareness must retain compact same-line `if ... elsif ... then` action metadata (`Statement_Elsif_Action`) and AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 275 language-model guard: parser-owned statement awareness must retain compact same-line loop-body action metadata (`Statement_Loop_Action`) and AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 276 language-model guard: parser-owned statement awareness must retain compact same-line case alternative action metadata (`Statement_Case_Alternative_Action`) with AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 277 language-model guard: parser-owned statement awareness must retain compact same-line exception handler action metadata (`Statement_Exception_Handler_Action`) with AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 278 language-model guard: parser-owned statement awareness must retain compact same-line handled-sequence `begin` action metadata (`Statement_Begin_Action`) with AUnit coverage, without creating Outline rows or semantic symbols.

- Pass 279 language-model guard: parser-owned statement awareness must retain Ada `goto` label-target metadata (`Statement_Goto_Label_Target`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 280 language-model guard: parser-owned statement awareness must retain compact conditional entry-call select metadata (`Statement_Select_Entry_Call`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 281 language-model guard: parser-owned statement awareness must retain compact conditional entry-call select else-action metadata (`Statement_Select_Else_Action`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.


Pass 282 parser update: compact timed entry-call select statements now retain select-delay fallback metadata (`Statement_Select_Delay_Fallback`, including relative and `delay until` forms) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 283 parser update: compact asynchronous select statements now retain select-level then-abort fallback metadata (`Statement_Select_Then_Abort_Fallback`) while preserving the embedded abortable action shape. This remains bounded parser-owned statement awareness only and does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 285 parser update: compact selective-accept terminate fallbacks and compact asynchronous-select abortable triggering calls now retain explicit parser-owned metadata (`Statement_Select_Terminate_Fallback` and `Statement_Select_Abortable_Call`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 286 language-model guard: parser-owned statement awareness must retain compact same-line declare-block action metadata (`Statement_Declare_Action`) with AUnit coverage, without creating Outline rows or semantic symbols.

- Phase 579 pass 287 guard: release validation requires anonymous block terminator statement-awareness support (`Statement_End_Block`) in the language model, parser, and AUnit coverage.  The guard verifies metadata retention only; block terminators must not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.


Pass 288 update: the Ada declaration parser now preserves attribute-reference procedure-call statement shape as bounded language-model metadata. Calls such as `Buffer_Type'Write (Stream, Buffer);` and `Buffer_Type'Read (Stream, Buffer);` remain ordinary call statements, retain argument metadata, and additionally stamp `Statement_Call_Attribute_Name`. Qualified-expression code statements remain separate from call metadata, and attribute names are not projected into Outline rows, semantic symbols, scopes, or navigation targets.

Pass 289 update: the Ada declaration parser now preserves pragma statements that appear inside executable statement sequences or executable alternatives as bounded language-model metadata. `pragma Assert (Ready);` and `when A => pragma Assert (Ready);` stamp `Statement_Pragma`, pragmas with parenthesized argument lists also stamp `Statement_Pragma_With_Arguments`, and pragma names/arguments are not projected into Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 290 update: the Ada declaration parser now distinguishes pragma statements used as executable alternative actions. `when A => pragma Assert (Ready);` still stamps `Statement_Pragma` and `Statement_Pragma_With_Arguments` where applicable, and now also stamps `Statement_Alternative_Pragma`. This remains parser-owned statement metadata only: pragma names and arguments are not projected into Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

- Pass 291 language-model guard: parser-owned statement awareness must retain compact conditional entry-call select else fallback action-shape metadata (`Statement_Select_Else_Null`, `Statement_Select_Else_Return`, `Statement_Select_Else_Raise`, `Statement_Select_Else_Assignment`, `Statement_Select_Else_Call`, `Statement_Select_Else_Code`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 292 language-model guard: parser-owned statement awareness must retain compact conditional entry-call select else fallback control/tasking/pragma metadata (`Statement_Select_Else_Exit`, `Statement_Select_Else_Goto`, `Statement_Select_Else_Delay`, `Statement_Select_Else_Requeue`, `Statement_Select_Else_Abort`, `Statement_Select_Else_Pragma`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 293 language-model guard: parser-owned statement awareness must retain refined compact conditional entry-call select else fallback subform metadata (`Statement_Select_Else_Delay_Until`, `Statement_Select_Else_Delay_Relative`, `Statement_Select_Else_Requeue_With_Abort`, `Statement_Select_Else_Pragma_With_Arguments`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.
Pass 295 parser update: compact timed entry-call select delay fallbacks now retain the simple fallback body action shape (`Statement_Select_Delay_Fallback_Action`, including null, call, assignment, return, raise, and code-action forms) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.
Pass 296 parser update: compact timed entry-call select delay fallback bodies now retain additional control/tasking/pragma action shape metadata (`Statement_Select_Delay_Fallback_Exit`, `..._Goto`, `..._Delay`, `..._Requeue`, `..._Abort`, `..._Pragma`, and `..._Pragma_With_Arguments`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.
Pass 297 parser update: compact timed entry-call select delay fallback bodies now refine nested delay and requeue action metadata (`Statement_Select_Delay_Fallback_Delay_Until`, `..._Delay_Relative`, and `..._Requeue_With_Abort`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 298 language-model guard: parser-owned statement awareness must retain refined compact timed entry-call select delay fallback call-shape metadata (`Statement_Select_Delay_Fallback_Call_With_Arguments`, `Statement_Select_Delay_Fallback_Call_With_Named_Association`, `Statement_Select_Delay_Fallback_Call_Selected_Name`, `Statement_Select_Delay_Fallback_Call_Access_Dereference`, and `Statement_Select_Delay_Fallback_Call_Entry_Family_Index`) with AUnit coverage, without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

- Pass 299: verify `Editor.Ada_Syntax_Tree` is present, parser-owned, and attached through `Editor.Ada_Language_Model.Set_Syntax_Tree`; verify tests cover the compilation-unit root, node count, child ownership, and syntax-tree fingerprint.

Phase 579 pass 300: completeness pass for the Ada syntax-tree foundation.  `Editor.Ada_Syntax_Tree.Parse` now assigns nested parent/child ownership using a bounded source-shape scope stack instead of attaching every parsed node directly to the compilation-unit root.  Package bodies own nested subprogram bodies, subprogram bodies own begin/statement/end nodes, and `end` nodes pop the parser-owned tree stack.  This is still a conservative syntax-tree foundation, not a full Ada grammar AST, and it does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets from statement syntax.

- Pass 301 guard: release validation requires `Editor.Ada_Syntax_Tree` to retain explicit `Node_Elsif_Part`, `Node_Else_Part`, `Node_When_Alternative`, and `Node_Exception_Section` nodes, plus parser-side alternative scope tracking through `Is_Alternative_Node` and `Pop_Alternative_Scope`.

### Phase 579 pass 302 checks

- `Editor.Ada_Syntax_Tree` must retain expression/name node kinds such as `Node_Expression`, `Node_Name`, `Node_Selected_Name`, `Node_Attribute_Reference`, `Node_Function_Call`, `Node_Operator_Expression`, `Node_Conditional_Expression`, `Node_Case_Expression`, and `Node_Quantified_Expression`.
- `phase579_language_validation_check` must guard the expression/name parser helpers and AUnit coverage marker.

### Phase 579 pass 303 expression/name syntax-tree guard

- `Editor.Ada_Syntax_Tree.Node_Kind` must remain unique and include the pass 303 expression/name node kinds: `Node_Membership_Expression`, `Node_Short_Circuit_Expression`, `Node_Unary_Expression`, `Node_Parenthesized_Expression`, `Node_Explicit_Dereference`, `Node_Allocator`, `Node_Named_Association`, and `Node_Positional_Association`.
- `phase579_language_validation_check` must guard these node kinds and the expression/name AUnit fixture must exercise them.


### Phase 579 pass 304 control-statement syntax-tree guard

- `Editor.Ada_Syntax_Tree.Node_Kind` must include explicit control/tasking source-shape nodes for `Node_Label`, `Node_Delay_Statement`, `Node_Exit_Statement`, `Node_Goto_Statement`, and `Node_Requeue_Statement`.
- `phase579_language_validation_check` must guard those node kinds and the `Test_Language_Model_Syntax_Tree_Control_Statement_Nodes` AUnit fixture.
- The syntax-tree detail attachment path must not contain duplicate case alternatives for the same node kind group.

Phase 579 pass 305 release guard note:
- Verify `Editor.Ada_Syntax_Tree` still contains structured statement-detail nodes for statement sequences, actions, alternatives, targets, conditions, selectors, arguments, messages, and modes.
- Verify compact executable actions and alternatives are represented as syntax-tree nodes, not only aggregate statement counters.
- Verify executable statement nodes still do not create Outline declaration rows, semantic declaration symbols, scopes, or navigation targets.

- [ ] Phase 579 pass 306 verified: ordinary executable statement syntax-tree nodes own structured detail children directly, compact alternatives split into nested action nodes, and no duplicate same-kind child statement regression is present.

### Phase 579 pass 307 compact control-flow syntax-tree guard

- Verify compact executable tails classify embedded `if`, `case`, loop, block, select, alternative, and exception-handler segments as structured `Editor.Ada_Syntax_Tree` nodes rather than generic call-statement fallbacks.
- Verify `phase579_language_validation_check` still requires direct AUnit coverage for compact embedded control-flow statement nodes.

- Phase 579 pass 308 guard: verify compact `select ... then abort ...` syntax-tree parsing keeps both triggering and abortable statement sequences, and keeps AUnit coverage for `Test_Language_Model_Syntax_Tree_Select_Then_Abort_Details`.

- Pass 309 guard: release validation requires `Node_Select_Alternative`, parser classification returning `Node_Select_Alternative`, and AUnit coverage for structured select `or`/`else` alternatives so select alternative ownership does not regress to generic compact action text.

- Confirm the Ada syntax-tree regression suite covers line-level select `then abort`, select `else`, and `terminate` alternatives as structured select-alternative metadata.

- Pass 311 guard: release validation requires `Node_Exception_Handler`, parser reclassification of exception-section `when ... =>` lines, and AUnit coverage proving exception handlers are owned by `Node_Exception_Section` instead of collapsing into generic case `Node_When_Alternative` nodes.


- Pass 312 guard: select entry-call alternatives must remain first-class syntax-tree nodes and must not regress to generic call-only statement metadata.

- Pass 313: verify `tools/bin/phase579_language_validation_check` guards structured aspect, pragma-argument, representation-clause, and generic-actual syntax-tree nodes and their AUnit coverage.

- Pass 314: verify `phase579_language_validation_check` guards `Node_Representation_Component_Clause`, the component-clause detail extractor, reclassification under record representation clauses, and AUnit coverage for component targets/ranges.

- Pass 315: verify `phase579_language_validation_check` requires domain-specific syntax-tree child nodes for aspect names/values, named pragma arguments, and generic actual formal/value pairs, and that AUnit coverage exercises split aspect and split generic-actual ownership.


Pass 316 note: the Ada syntax-tree declaration grammar now represents the remaining Ada declaration families structurally, including generic formal declarations, incomplete types, private extensions, named numbers, task/protected declarations and bodies, entries, record components, discriminants, private parts, and body stubs. Declaration nodes expose shared declaration-name/subtype/default/mode child metadata for Outline and semantic-colouring consumers.

- [ ] Pass 317 Ada declaration grammar guards pass: abstract subprograms, null procedures, expression functions, declaration profiles, and function result child nodes remain first-class syntax-tree structures.

- [ ] Pass 318 declaration grammar guards pass: enumeration literal declarations, record variant parts/variants, entry bodies, entry body stubs, and renaming declaration targets remain first-class parser-owned syntax-tree structures with AUnit coverage.

- [ ] Pass 319 declaration grammar guards pass: typed constant declarations, deferred constant declarations, named numbers, and executable assignment statements remain distinct syntax-tree node families with regression coverage.

- [ ] Pass 320 declaration grammar guards pass: task type, single task, protected type, and single protected declarations remain distinct syntax-tree node families with declaration-mode metadata and regression coverage.

- Pass 321: verify grammar-aware syntax-tree recovery remains present (`Node_Missing_End`, `Node_Unexpected_End`, `Node_Mismatched_End`, `Node_Recovery_Point`) and that malformed Ada units synchronize at known grammar boundaries instead of swallowing following declarations or statement nodes into stale scopes.

- Phase 579 pass 322: verify named `end` target recovery retains `Node_End_Target` and `Node_Expected_End_Target` details and does not expose recovery diagnostics as Outline symbols or semantic-colouring declarations.

Pass 323 note: grammar-aware recovery now distinguishes true missing explicit Ada endings from implicit closure of handled statement parts at enclosing body/block end boundaries. The syntax tree exposes Node_Implicit_End for this bounded parser-owned recovery case, while preserving Node_Missing_End for malformed nesting.

Pass 324 note: grammar-aware recovery now closes generic formal parts at the grammar boundary where the generic package/subprogram unit starts.  The syntax tree emits `Node_Implicit_End` for this parser-owned closure, keeps formal declarations under `Node_Generic_Declaration`, and avoids false end-of-file `Node_Missing_End` diagnostics for well-formed generic declarations.

- Phase 579 pass 325: keep malformed-header recovery coverage so missing `then`, `is`, and `loop` tokens are represented by `Node_Expected_Token` children under `Node_Recovery_Point` nodes, without creating Outline symbols or semantic identifiers.

- Phase 579 pass 326: keep malformed-alternative recovery coverage so missing `=>` in case alternatives, record variants, and exception handlers is represented with `Node_Expected_Token` under parser recovery points while preserving structured alternative node kinds. Also verify variant parts synchronize on `end case;` before the enclosing `end record;`.

- Phase 579 pass 327: keep malformed-declaration recovery coverage so missing `is` and `;` in Ada declarations are represented by `Node_Expected_Token` children under parser recovery points, while declaration-shaped lines with `:`/`:=` do not regress to assignment nodes.

- Phase 579 pass 328: keep malformed delimited-list and end-boundary recovery coverage so missing `)`, unexpected `(`, and missing `;` in pragmas/aspects/representation clauses/generic actuals/end lines are represented by `Node_Expected_Token` children without demoting those constructs to generic unknown nodes.

- Phase 579 pass 329: keep implicit-begin recovery coverage so executable statements appearing before an explicit handled-sequence `begin` create `Node_Implicit_Begin`, retain `Node_Expected_Token` = `begin`, and close with `Node_Implicit_End` without becoming Outline symbols.

Pass330 note: the Ada syntax-tree layer now performs grammar-aware recovery for malformed subprogram and concurrent declaration headers. It preserves the declaration node shape for malformed subprogram/task/protected declarations and attaches expected-token recovery metadata for missing `is` or missing `;` boundaries.

- Pass331: confirm grammar-aware recovery retains `Node_Unexpected_Declaration` diagnostics for declarations after handled-sequence `begin`, including expected `declare` metadata and follow-on statement parsing.

- Pass332: confirm EOF grammar recovery emits `Node_Implicit_End` for unterminated handled statement parts at end-of-file before reporting the enclosing body with `Node_Missing_End`, and that these recovery nodes remain parser metadata only.

- Phase 579 pass333: keep private-part ownership coverage so declarations after `private` are children of `Node_Private_Part`, visible declarations remain outside that scope, and the private section closes structurally with `Node_Implicit_End` at the enclosing `end`.


### Pass 334 — token-cursor Ada grammar layer

Added `Editor.Ada_Token_Cursor`, a UI-free token stream and cursor grammar package. The syntax tree now records a bounded `Node_Token_Cursor_Grammar` subtree with `Node_Grammar_Production` events for compilation units, declarations, statements, association lists, and expression-precedence productions. The previous structured syntax-tree path remains as a compatibility projection while the new grammar layer becomes the parser substrate for further IDE-grade Outline and semantic-colouring work.

Pass 335 note: the internal Ada token-cursor grammar now retains detailed declaration and expression production events for parameter profiles, generic formals, discriminants, enumeration literals, records/components/variants, selected names, indexed components, attribute references, and conditional/case/quantified expression forms. These productions are parser-owned metadata for Outline/semantic-colouring integration and remain bounded/conservative rather than compiler legality checks.

Pass 336 note: the internal Ada token-cursor grammar now retains explicit statement production events for handled statement sequences, elsif/else branches, case/select alternatives, loop-parameter specifications, extended returns, null/exit/goto/delay/requeue/abort statements, exception sections, and entry/call actual parts. The events are parser-owned metadata for later Outline/semantic-colouring integration and remain bounded/conservative rather than GNAT-equivalent legality checks.


- Pass 337: verify token-cursor grammar coverage for array/access/derived/private/interface/integer/modular/floating/fixed type definitions, subtype indications, index constraints, and range constraints.

### Pass338 token-cursor metadata grammar update

The Ada token-cursor grammar now retains structured productions for pragma argument associations, aspect associations, generic actual parts/associations, record representation clauses, and representation component clauses. This keeps metadata-heavy Ada declarations from being treated as opaque declaration tails in the grammar layer.



- Pass 339: verify token-cursor grammar coverage for with/use/use type/use all type clauses and labeled statements via `Test_Language_Model_Token_Cursor_Context_And_Label_Grammar_Completeness`.

### Pass 340 — token-cursor separate/body-stub grammar

- Verify token-cursor grammar coverage for separate subunits and package/subprogram/task/protected/entry body stubs via `Test_Language_Model_Token_Cursor_Separate_And_Body_Stub_Grammar_Completeness`.
- Verify release guards require `Production_Separate_Subunit` and body-stub production markers.


Pass 341 note: the token-cursor Ada grammar now retains task definitions, protected definitions, entry-family definitions, and entry-body barriers as first-class productions. Task/protected definitions with nested entries or protected operations are no longer skipped as a single semicolon-delimited header in the token-cursor grammar layer.

### Pass 342 — token-cursor expression grammar completeness

- Verify token-cursor grammar coverage for allocator expressions, raise expressions, membership choice lists, short-circuit `and then`/`or else`, delta aggregates, reduction attributes, and unary expressions via `Test_Language_Model_Token_Cursor_Expression_Grammar_Completeness`.

Pass 343 update: the Ada token-cursor grammar now distinguishes generic formal declaration families, including formal objects, formal private/derived/discrete/scalar/composite/access/interface types, formal subprograms, and formal packages with actual parts.

Pass 344 parser note: the token-cursor Ada grammar now retains subprogram modifier/declaration distinctions for overriding indicators, abstract subprogram declarations, null procedures, expression functions, and defaulted formal subprograms. These productions are parser metadata available to the language model and do not imply compiler-grade dispatch or overload legality checking.


Pass 345 note: the token-cursor Ada grammar now records defining names explicitly, including quoted operator symbols for operator functions and generic formal operator subprograms.


- Pass 346: token-cursor grammar validates limited/private with-clause productions and guards against regressing modified context clauses to unrecognized tokens.

### Pass 347 — token-cursor representation-clause grammar

- Verify `Editor.Ada_Token_Cursor` still exposes `Production_Attribute_Definition_Clause`, `Production_Enumeration_Representation_Clause`, `Production_Address_Clause`, and `Production_Record_Representation_Clause`.
- Verify AUnit coverage includes `Test_Language_Model_Token_Cursor_Representation_Clause_Grammar_Completeness`.
- Verify non-record representation clauses do not regress to opaque semicolon skipping.

- Pass 348: confirm the Ada syntax-tree projection pass is present and that
  `Editor.Ada_Declaration_Parser` merges structured syntax-tree declarations and
  metadata into `Editor.Ada_Language_Model.Analysis_Result` before Outline and
  semantic-colouring consumers read it.

- Pass 358: verify `Editor.Ada_Symbol_Resolver` still exposes expression-aware overload helpers (`Infer_Expression_Type_In_Scope`, `Resolve_Call_Expression_In_Scope`) and that regression coverage keeps unknown expression actuals from behaving as wildcard overload matches.

- Pass 359: verify expression-aware overload tests cover parenthesized actuals, signed numeric literals, operator-expression inference, comparison-to-Boolean inference, and the non-wildcard behavior for unknown operator operands.

- Pass 360: verify expression-aware overload tests cover unary `not`, unary `abs`, membership expressions (`in`/`not in`), exponentiation, and the non-wildcard behavior for unknown unary operands.

- Pass 361: verify expression-aware overload tests cover conditional expressions, Boolean conditions, compatible branch type inference, and the non-wildcard behavior for unknown conditions or incompatible branches.
- Pass 362: verify `Editor.Ada_Project_Index` retains bounded cross-file Ada unit rows (`Indexed_Unit_Role`, `Resolve_Unit`, `Resolve_Related_Unit_Target`, `Resolve_Separate_Parent_Target`) and that `Test_Project_Index_Cross_File_Unit_Relationship_Table` covers package spec/body and separate-parent relationships with stale-target-safe keys.

- Pass 363: verify `Editor.Ada_Project_Index.Resolve_Parent_Unit_Target` resolves indexed child units such as `Parent.Child` back to their indexed parent unit through the Ada unit table, and that `Test_Project_Index_Child_Unit_Parent_Relationship_Target` covers the conservative stale-safe target result.
- Pass 364: verify `Editor.Ada_Project_Index.Resolve_Child_Units` lists only direct indexed child units for a parent unit, supports unit-role filtering, excludes grandchildren, and is covered by `Test_Project_Index_Parent_Lists_Direct_Child_Units`.
- Pass 365: verify `Editor.Ada_Project_Index.Resolve_Unit_Family` lists validated spec/body/separate rows for a normalized Ada unit identity, supports unit-role filtering, preserves duplicate family rows for disambiguation, and is covered by `Test_Project_Index_Unit_Family_Lists_Validated_Targets`.

- Pass 366: verify the Ada unit table indexes only top-level library units, keeps nested declarations in ordinary symbol lookup, and is covered by `Test_Project_Index_Unit_Table_Excludes_Nested_Declarations`.


### Pass 367 generic semantic expansion

The Ada language model now retains generic actual associations and the resolver exposes a bounded expanded view for selected names through generic package instances. Calls such as `Instance.Operation (...)` can use retained generic actuals to substitute formal type names during overload filtering and expected-result checks. This remains conservative: it does not clone full instance bodies or perform GNAT-equivalent generic legality checking.

- Pass 368: verify generic instance expression inference substitutes retained actuals for selected instance object and function result types, and that unresolved generic mappings remain conservative.


Phase 579 pass 369: IDE navigation ambiguity handling now has a first-class candidate API in `Editor.Ada_Project_Index`. Unique goto commands can continue to require a single validated target, while chooser-style UI can request the full validated candidate set for declaration/body/spec/unit-family navigation and distinguish unavailable, unique, ambiguous, and overflow states without falling back to unsafe first-match jumps.


- Pass 370: verify ambiguity-aware navigation candidate formatters remain present (`Navigation_Candidate_Display_Label`, `Navigation_Candidate_Detail_Label`) and are covered by `Test_Project_Index_Navigation_Candidate_Labels_Are_Presentable`.


Pass371: representation-clause interpretation now covers bounded non-record metadata, including enumeration representation associations and attribute clauses such as Size, Alignment, Bit_Order, Address, Storage_Size, and Storage_Pool. The model retains raw source text and parses simple Ada integer literal values, while leaving legality checking and full arbitrary static-expression evaluation out of scope.

### Pass 372 — representation static-expression interpretation

- `Test_Language_Model_Representation_Static_Expressions_Are_Evaluated` covers bounded arithmetic evaluation for enumeration, attribute, and record representation metadata.
- Unsupported representation expressions must remain preserved as source text without guessed numeric values.
- This is not a full Ada static-expression legality checker.

Pass 374 note: representation-clause metadata includes bounded numeric interpretation of prior named-number constants for enumeration representation associations, attribute representation clauses, and record component layout clauses. This remains conservative and does not perform compiler-grade legality or arbitrary static-expression evaluation.


Pass 375 adds bounded executable-statement semantic binding metadata for loop parameters, declare-block objects, exception choices, assignment/call targets, selected components, labels, and goto targets. Semantic colouring consumes these parser-owned bindings where targets are known and degrades unresolved executable expressions to ordinary identifiers.

Pass 376 release note: release validation should preserve executable expression call-target binding coverage so the language model does not regress to standalone-call-only executable semantic metadata.

Pass 377 release note: release validation should preserve executable selected-component binding coverage so semantic metadata does not regress to assignment-target-only component handling.

Pass 378 release note: release validation should preserve executable case-choice binding coverage (`Binding_Case_Choice` and `Test_Language_Model_Executable_Case_Choices_Are_Distinct`) so case alternatives do not regress to exception-handler metadata.


Pass 379: executable statement semantic binding now retains deeper expression/name binding metadata for array indexing and slicing, explicit dereference, allocator targets, named aggregate associations, and qualified-expression targets. These bindings remain bounded and conservative; unresolved expressions still degrade rather than being guessed.

Pass 380: executable expression/name binding now retains Ada attribute prefixes such as `Obj'Length`, `X'Size`, and `T'Image (...)` as parser-owned `Binding_Attribute_Prefix` metadata. Qualified expressions such as `T'(...)` remain distinct qualified-expression target bindings, so attribute prefix binding improves semantic colouring/navigation without turning attributes into guessed calls or rendering-side parsing.

Pass 381: executable expression/name binding now retains transfer/tasking targets as parser-owned metadata: `raise E;` becomes `Binding_Raise_Target`, `requeue Start;` becomes `Binding_Requeue_Target`, and `accept Start;` becomes `Binding_Accept_Entry`. These bindings preserve source spelling, scope/range, expression text, and optional local targets without performing tasking or exception legality checking.

- Pass 382: confirm executable block-label and exit-target bindings remain parser-owned (`Binding_Block_Label`, `Binding_Exit_Target`) and covered by `Test_Language_Model_Executable_Block_And_Exit_Targets`.

Phase 579 pass383: release validation should preserve executable return binding coverage. The language model must retain `Binding_Return_Target` and `Binding_Return_Object`, and tests must cover ordinary and extended return forms without reclassifying function specifications as executable statements.

- Pass 384: executable delay/abort target bindings remain parser-owned metadata (`Binding_Delay_Target`, `Binding_Abort_Target`) and must not be reimplemented in rendering/projection code.

- Pass 385: executable condition/selector and iteration-source bindings are retained as parser-owned metadata through `Binding_Condition_Target`, `Binding_Iteration_Source`, and `Test_Language_Model_Executable_Condition_And_Iteration_Bindings`.

- Pass 386: confirm executable select-statement bindings remain parser-owned (`Binding_Select_Guard`, `Binding_Select_Entry_Call`) and covered by `Test_Language_Model_Executable_Select_Bindings`; select guards must not regress to ordinary case-choice metadata.

- Pass 387: confirm timed select alternatives remain parser-owned (`Binding_Select_Delay_Target`) and covered by `Test_Language_Model_Executable_Select_Bindings`; select delay alternatives must not regress to entry-call metadata or disappear because `delay` is a keyword.

- Pass 388: confirm select terminate alternatives remain parser-owned executable metadata (`Binding_Select_Terminate`) and are covered by `Test_Language_Model_Executable_Select_Bindings`; they must not regress to entry-call/case-choice metadata.

- Pass 389: confirm protected entry barrier bindings remain parser-owned executable metadata (`Binding_Entry_Barrier`) and are covered by `Test_Language_Model_Executable_Entry_Barrier_Bindings`; entry barriers must not regress to select-guard or declaration-only metadata.

- Pass 390: confirm executable range-bound bindings remain parser-owned metadata (`Binding_Range_Bound`) and are covered by `Test_Language_Model_Executable_Range_Bound_Bindings`; range endpoints must not regress to only iteration-source or slice-prefix metadata.

- Pass 391: confirm executable assertion-style pragma arguments remain parser-owned metadata (`Binding_Pragma_Argument`) and are covered by `Test_Language_Model_Executable_Pragma_Argument_Bindings`; non-executable pragmas such as `Import` must not become fallback call targets.


Pass 392 update: executable semantic binding now retains bounded quantified-expression metadata. `for all` / `for some` parameters are stored as local executable bindings and simple quantified domains are retained as source bindings for semantic colouring/navigation consumers. This remains conservative and does not perform compiler-grade quantified-expression legality or domain type checking.

- Pass 393: confirm executable named actual associations remain parser-owned metadata (`Binding_Named_Actual`) and are covered by `Test_Language_Model_Executable_Named_Actual_Bindings`; named call actuals must not regress to aggregate-component-only metadata or fallback call guesses.


Pass394 update: executable expression binding now distinguishes Ada case-expression selectors and choices from statement case alternatives, retaining simple selector/choice names as bounded semantic metadata without compiler-grade case-expression legality checking.

- Pass 395: confirm executable conditional-expression metadata remains parser-owned and covered by `Test_Language_Model_Executable_Conditional_Expression_Bindings`; condition/branch bindings must not regress into statement-level condition metadata or fallback call guesses.

- Pass 396 guard: executable raise expressions must remain represented as `Binding_Raise_Expression_Target` and covered by `Test_Language_Model_Executable_Raise_Expression_Bindings`, distinct from statement-level `Binding_Raise_Target`.

- Pass 397: confirm executable delta aggregate bindings remain parser-owned metadata (`Binding_Delta_Aggregate_Base`, `Binding_Delta_Aggregate_Component`) and are covered by `Test_Language_Model_Executable_Delta_Aggregate_Bindings`; delta aggregate components must not regress to named-call actuals or generic aggregate-component-only metadata.

Pass398 release guard: executable expression binding coverage includes Binding_Type_Conversion_Target and its regression test.

Pass399 release guard: executable binding coverage includes
`Binding_Aspect_Expression` and a regression test for contract/assertion aspect
expressions on declaration lines.


Pass 400 note: executable semantic binding now retains accept statement formal parameters as bounded `Binding_Accept_Parameter` metadata, distinct from accept entry targets. This lets semantic-colouring/navigation consumers treat accept-body formals as local value-like names where safe.
Pass 401 note: executable semantic binding now retains exception occurrence identifiers, such as `when Occ : Constraint_Error =>`, as bounded `Binding_Exception_Occurrence` metadata distinct from exception-handler choices.


- Pass 402: verify iterator-filter executable bindings remain parser-owned (`Binding_Iteration_Filter`) and distinct from iteration-source/range-bound metadata.

- Pass 403: confirm asynchronous select abort alternatives remain parser-owned executable metadata (`Binding_Select_Abort`) and are covered by `Test_Language_Model_Executable_Select_Bindings`; `then abort` must not regress to fallback call metadata.

- Pass410 guard: quantified-expression loop schemes (`for all ... in`, `for some ... of`) are covered by token-cursor regression tests and must not regress to opaque skip-to-arrow parsing.

- Pass411 guard: Ada 2022 declare expressions must remain covered by `Test_Language_Model_Token_Cursor_Declare_Expression_Grammar_Completeness` and `Production_Declare_Expression`; they must not regress to opaque parenthesized aggregate parsing.

- Pass413 guard: aggregate iterated component associations must remain covered by `Test_Language_Model_Token_Cursor_Aggregate_Iterator_Grammar_Completeness` and `Production_Iterated_Component_Association`; aggregate `for ... in/of ... =>` syntax must not regress to `Production_Quantified_Expression`.

- Pass414 guard: unconstrained array index subtype definitions must remain covered by `Test_Language_Model_Token_Cursor_Array_Index_Subtype_Grammar_Completeness` and `Production_Index_Subtype_Definition`; `array (Positive range <>) of T` must not regress to an opaque expression/index-constraint parse.

- Pass415 guard: null exclusions before access definitions and anonymous access subtypes must remain covered by `Test_Language_Model_Token_Cursor_Null_Exclusion_Access_Grammar_Completeness` and `Production_Null_Exclusion`; `not null access all T` and formal `not null access procedure` must not regress to opaque expression recovery.

- Pass416 guard: membership choices with explicit and subtype ranges must remain covered by `Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness`, `Production_Membership_Choice`, and `Production_Range_Expression`; `in 1 .. 10` and `Natural range 20 .. 30` must not regress to opaque expression recovery.

- Pass417 guard: Ada 2022 target-name expressions must remain covered by `Test_Language_Model_Token_Cursor_Target_Name_Grammar_Completeness` and `Production_Target_Name`; `Value := @ + Next;` must not regress to stray-operator recovery.

- Pass418 guard: parameter and discriminant profile items must remain covered by `Test_Language_Model_Token_Cursor_Profile_Item_Grammar_Completeness` and the productions `Production_Aliased_Part`, `Production_Parameter_Mode`, and `Production_Default_Expression`; profile parsing must not regress to opaque `Skip_Balanced_To` handling.

- Pass419 guard: keep modified type-definition grammar coverage for `Production_Type_Modifier` and `Test_Language_Model_Token_Cursor_Type_Modifier_Grammar_Completeness`.

- Pass420 guard: delay statement grammar alternatives must remain covered by `Test_Language_Model_Token_Cursor_Delay_Statement_Grammar_Completeness`, `Production_Delay_Until_Statement`, and `Production_Delay_Relative_Statement`; `delay until Expr;` must not regress to opaque semicolon skipping.

- Pass421 guard: extended return grammar must remain covered by `Test_Language_Model_Token_Cursor_Extended_Return_Grammar_Completeness`, `Production_Return_Object_Declaration`, and `Production_Extended_Return_Initializer`; `return Result : aliased constant Item := Make_Item (1) do` must not regress to opaque header skipping.

- Pass422 guard: requeue statement grammar must remain covered by `Test_Language_Model_Token_Cursor_Requeue_Grammar_Completeness`, `Production_Requeue_Target`, and `Production_Requeue_With_Abort`; `requeue Server.Queue (Index) with abort;` must not regress to opaque semicolon skipping.

- Pass423 guard: abort statement grammar must remain covered by `Test_Language_Model_Token_Cursor_Abort_Statement_Grammar_Completeness` and `Production_Abort_Target`; `abort Worker, Pool.Tasks (Index), Controller.Current.all;` must not regress to opaque semicolon skipping.

Pass424 parser guard: exception-handler choice parameters and exception choice lists must remain structural token-cursor productions, with regression coverage for `when Failure : Constraint_Error | Program_Error =>`.


- Pass425 parser guard: token-cursor grammar must retain bare re-raise and raise-with-message statement forms (`Production_Reraise_Statement`, `Production_Raise_With_Message`) with AUnit coverage.

- Pass426 parser guard: token-cursor grammar must retain exit targets, exit `when` conditions, and goto targets (`Production_Exit_Target`, `Production_Exit_When_Condition`, `Production_Goto_Target`) with AUnit coverage.
- Pass427 parser guard: token-cursor grammar must retain select guards, select else parts, terminate alternatives, and asynchronous then-abort parts (`Production_Select_Guard`, `Production_Select_Else_Part`, `Production_Terminate_Alternative`, `Production_Abortable_Part`) with AUnit coverage.

- Pass428: token-cursor grammar now retains attribute argument parts on attribute references (`Values'First (1)`, `Integer'Image (Value)`, reduction attributes) instead of misclassifying them as ordinary indexed-component suffixes.


Pass 429 note: the Ada token-cursor parser now retains Ada box expressions (`<>`) as `Production_Box_Expression`, including aggregate associations such as `others => <>` and generic actual associations such as `Element => <>`. This is syntactic grammar retention, not compiler-grade legality or expected-type validation.

Pass 430 note: the Ada token-cursor parser now retains plain, discriminated, and tagged incomplete type declarations through `Production_Incomplete_Type_Declaration` and `Production_Tagged_Incomplete_Type_Declaration`, with AUnit regression coverage. This guards grammar recovery only; compiler-grade incomplete-type completion legality remains out of scope.

Pass 431 note: object declaration qualifiers must remain structurally parsed. Guard `Production_Object_Qualifier`, `Production_Aliased_Part`, and `Test_Language_Model_Token_Cursor_Object_Qualifier_Grammar_Completeness` so `Obj : aliased constant T := ...` and `Handle : aliased not null access T;` do not regress to opaque subtype parsing.

Pass 432 note: Ada unknown discriminant parts are now retained structurally by the token-cursor parser. Forms such as `type T (<>) is private;` and `type Deferred (<>);` produce `Production_Unknown_Discriminant_Part` under `Production_Discriminant_Part` instead of treating the box token as a malformed discriminant specification. This remains parser grammar retention only, not compiler-grade private/full-view matching or discriminant legality validation.

Pass 433 note: numeric subtype constraints must remain structurally parsed. Guard `Production_Digits_Constraint`, `Production_Delta_Constraint`, and `Test_Language_Model_Token_Cursor_Subtype_Constraint_Grammar_Completeness` so floating- and fixed-point subtype indications with `digits`, `delta`, and optional `range` constraints do not regress to opaque recovery.

Pass 434 note: record component definitions must remain structurally parsed. Guard `Production_Component_Definition` and `Test_Language_Model_Token_Cursor_Component_Definition_Grammar_Completeness` so component definitions with defining-name lists, `aliased`, `not null access`, and default expressions do not regress to opaque recovery.


Pass 435 note: named discriminant constraints are now retained structurally by the Ada token-cursor parser. Subtype indications such as `Bounds (Low => 1, High => 10)` produce `Production_Discriminant_Constraint` and `Production_Discriminant_Association`, while ordinary array index constraints such as `Table (1 .. 5)` continue to use `Production_Index_Constraint`. This is syntactic grammar retention only; positional discriminant-vs-index disambiguation, discriminant legality, and subtype conformance remain compiler-grade semantic checks.

Pass 436 note: Ada aspect marks are now retained structurally by the token-cursor parser. Aspect specifications such as `with Preelaborate` and `Type_Invariant'Class => Is_Valid (Item)` produce `Production_Aspect_Mark` and, for class-wide marks, `Production_Classwide_Aspect_Mark` instead of being flattened into generic expression or attribute-reference recovery. This remains parser grammar retention only, not compiler-grade aspect placement, inheritance, freezing, staticness, or type legality validation.

Pass 437 note: record representation clauses now retain optional `at mod <expression>;` mod clauses structurally through `Production_Mod_Clause`, while preserving following component clauses such as `Field at 0 range 0 .. 7;`. This is parser grammar retention only, not compiler-grade alignment, storage-unit, layout-conflict, or target-specific representation legality validation.


Pass 439 parser-completeness note: generic formal subprogram defaults are now retained as concrete token-cursor grammar alternatives. The parser distinguishes box defaults (`is <>`), null defaults (`is null`), abstract defaults (`is abstract`), and default-name expressions (`is Some.Default`) instead of treating everything after `is` as opaque recovery. This remains bounded grammar retention, not compiler-grade generic contract legality checking.

- Pass440 guard: generic actual association grammar must retain `Production_Generic_Actual_Formal_Selector`, `Production_Generic_Actual_Box`, and `Test_Language_Model_Token_Cursor_Generic_Actual_Box_Grammar_Completeness`; named instantiation actuals and `Formal => <>` must not regress to expression-only actual parsing.
- Pass441 guard: pragma argument association grammar must retain `Production_Pragma_Argument_Identifier` and `Test_Language_Model_Token_Cursor_Pragma_Argument_Identifier_Grammar_Completeness`; named pragma arguments must not regress to expression-only parsing before `=>`.

- Pass442 guard: aggregate component-association grammar must retain `Production_Component_Association` and `Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness`; choice lists before `=>`, range choices, `others`, and `<>` values must not regress to expression-only aggregate parsing.

- Pass443 guard: parenthesized aggregate primaries and delta aggregates must continue to route first-item and update associations through `Production_Component_Association`; guard `Test_Language_Model_Token_Cursor_Parenthesized_Aggregate_Association_Grammar_Completeness` so `(A | B => ...)` and `(Base with delta A | B => ...)` do not regress to expression-only parsing.

- Pass444 guard: discriminant constraint grammar must retain `Production_Discriminant_Selector_Name`, `Parse_Discriminant_Selector_Name_List`, and `Test_Language_Model_Token_Cursor_Discriminant_Constraint_Grammar_Completeness`; selector-name lists such as `Bounds (Low | High => 1)` must not regress to expression-only parsing or recovery at `|`.

- Pass445 guard: formal package declarations must retain `Production_Formal_Package_Generic_Name`, `Production_Formal_Package_Actual_Part`, `Production_Formal_Package_Actual_Box`, and `Test_Language_Model_Token_Cursor_Formal_Package_Actual_Part_Grammar_Completeness`; forms such as `with package Defaults is new Generic_Defaults (<>);`, selected generic package names, named actual parts, `others => <>`, and declarations without explicit actual parts must not regress to opaque skip-to-parenthesis recovery.

- Pass446 guard: use-clause grammar must retain `Production_Use_Package_Name`, `Production_Use_Type_Subtype_Mark`, `Parse_Visibility_Name_List`, and `Test_Language_Model_Token_Cursor_Use_Clause_Name_List_Grammar_Completeness`; ordinary `use A, B.C;`, `use type T, U;`, and `use all type T'Class, U;` forms must not regress to expression-only context parsing.

- Pass448 guard: renaming declarations must retain distinct token-cursor productions for package, subprogram, object, exception, generic package, and generic subprogram renames; every form must emit `Production_Renamed_Entity`, and `Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness` must remain registered.


- [x] Pass 450: deep generic formal type grammar retains scalar boxes, private/interface modifiers, derived/interface lists, array domains/components, and formal access callable/result forms.
- [x] Pass 451: attached aspect specifications are retained before declaration semicolons and before body/definition `is` keywords across generic formals, package specs/bodies, type/subtype/object/exception declarations, subprograms, task/protected/entry declarations, and instantiations.

- Pass 476: attribute-specific representation legality checks added for Machine_Radix, Aft, Atomic, Volatile, Independent, Suppress_Initialization, positive-valued attributes, and Storage_Pool value shape.

- Pass535 guard: syntax-tree pragma nodes must preserve literal text in retained pragma argument children while still stripping comments; `Test_Language_Model_Representation_Pragma_Unification_Pass` must keep asserting quoted operator target retention through both language-model metadata and `Node_Pragma_Argument` labels.

## Pass 545 semantic static-evaluation guard

- Confirm chained scalar Base attributes (`T'Base'First`, `T'Base'Last`) remain covered by semantic regression tests.
- Confirm `T'Base'(Expr)` is range-checked before feeding representation-clause static values.
- Confirm numeric-only representation properties such as `Small` continue to accept valid Base attribute arithmetic and reject nonstatic/out-of-range expressions.

## Pass 576 semantic static-evaluation guard

- Confirm scalar integer `Value` attributes over retained static strings remain wired into both natural-valued representation expressions and signed range metadata.
- Confirm `Natural'Value` and constrained subtype `Value` results are range-checked before becoming reusable static constants.
- Confirm out-of-range string-fed integer `Value` forms continue to produce `Legality_Representation_Static_Value_Required` when used by representation clauses.


## Pass 581 semantic static-evaluation guard

- Confirm retained Character constants remain one-character operands in static string concatenation.
- Confirm Character constants initialized through Character'Val/Character'Pos retain Character-compatible metadata before string projection.
- Confirm named Character-built strings continue to feed scalar Value attributes and String'Length representation expressions without generalizing arbitrary discrete constants to strings.


## Pass 582 semantic static-evaluation guard

- Confirm direct Character-valued static expressions remain one-character operands in static String concatenation.
- Confirm Character'Val, Character'Succ/Pred, and qualified Character expressions reuse the discrete static evaluator and retain Character range checks before string projection.
- Confirm expression-built static strings continue to feed scalar Value attributes and String'Length representation expressions without projecting arbitrary non-Character discrete constants to strings.

## Pass 583 semantic static-evaluation guard

- Confirm String-compatible qualified expressions such as `String'("Gr" & "een")` remain static string sources.
- Confirm constrained String subtype qualifications retain root String compatibility before initializing reusable static string constants.
- Confirm qualified static strings continue to feed scalar `Value` attributes and `String'Length` representation expressions without broadening non-String qualified expressions.

## Pass 584 semantic static-evaluation guard

- Confirm direct static String expressions expose bounded `Length`, `First`, and `Last` values in representation-expression evaluation.
- Confirm qualified String expressions and sliced direct String expressions continue to feed scalar `Value` and String-bound paths without requiring an intermediate named constant.

## Pass 585 semantic static-evaluation guard

- Qualified static String prefixes remain valid for direct indexing/slicing in representation evaluation.
- `String'("Green") (1)` must produce a static Character-compatible value when used through `Character'Pos`.
- `String'("Green") (1 .. 2) & "een"` must remain a static String expression accepted by scalar `Value`.
- Out-of-range retained string index/slice cases must continue to stay nonstatic and emit the existing static-value diagnostic when used in representation clauses.

## Pass 586 semantic static-evaluation guard

- Confirm simple constrained String subtype bounds remain retained for static qualification and constant retention.
- Confirm constrained String qualification checks component count, rejecting length-mismatched static values while preserving valid bound-sliding cases.
- Confirm rejected constrained String constants do not feed later `Length`/`Value` representation expressions and still produce static-value diagnostics at their use sites.

## Pass 587 semantic static-evaluation guard

- Confirm constrained String subtype attributes expose retained `First`, `Last`, and `Length` values in static representation expressions.
- Confirm non-1 lower bounds retain their actual `First`/`Last` values while `Length` remains component-count based.
- Confirm constrained String qualification length checks from pass586 continue to reject mismatched values.

## Pass 588 semantic static-evaluation guard

- Confirm constrained String qualified expressions preserve retained subtype bounds when used as prefixes of `First`, `Last`, and `Length`.
- Confirm `Offset_Name'("Green")'First` / `Last` report the subtype lower/upper bounds, while `Length` reports the component count.
- Confirm constrained qualification still validates component count before exposing bounds, and unconstrained `String'(...)` keeps first bound 1.

## Pass 589 semantic static-evaluation guard

- Confirm qualified constrained String prefixes retain their subtype lower bound during indexing and slicing.
- Confirm `Offset_Name'("Green") (2)` resolves to the first component when the subtype is `String (2 .. 6)`.
- Confirm out-of-range qualified constrained String indexes/slices remain nonstatic and continue to emit static-value diagnostics when used by representation clauses.

## Pass 590 semantic static-evaluation guard

- Confirm constrained String subtype bounds spelled as subtype indications, such as `String (Positive range 2 .. 6)`, retain their low/high bounds.
- Confirm subtype-indication String bounds feed `First`, `Last`, and `Length` static representation expressions through the same metadata as simple `String (2 .. 6)` bounds.
- Confirm the low-bound normalization does not broaden arbitrary identifiers containing `range`; it only strips a standalone `range` token before evaluating the bounded expression.

## Pass 591 semantic static-evaluation guard

- Confirm simple subtype aliases of constrained String subtypes inherit retained `First`, `Last`, and `Length` metadata.
- Confirm alias-qualified static strings still apply the inherited component-count check before feeding representation expressions.
- Confirm constrained String alias handling does not broaden unconstrained `String` aliases or unrelated scalar subtype aliases.

## Pass 592 semantic static-evaluation guard

- Confirm named constants declared with constrained String subtypes retain declared `First`, `Last`, and `Length` bounds.
- Confirm these retained object bounds are used before image-derived 1-based bounds for static representation expressions.
- Confirm existing unconstrained String constants still expose image-derived `First = 1`, `Last = Length`, and `Length` behavior.

## Pass 593 semantic static-evaluation guard

- [ ] Confirm spaced String qualifications remain static in the bounded evaluator, including `String' ("Gr" & "een")` feeding scalar `Value`.
- [ ] Confirm constrained String qualified bounds such as `Offset_Name' ("Green")'Last` preserve retained subtype bounds.
- [ ] Confirm the stricter length-mismatch diagnostics for constrained String qualifications are unchanged.


## Pass 594 semantic static-evaluation guard

- [ ] Confirm bounded static-expression parsers treat Ada separator whitespace such as HT as whitespace, not syntax.
- [ ] Confirm tab-separated String qualifications feed scalar `Value` through the retained static String evaluator.
- [ ] Confirm tab-separated qualified String indexing still feeds `Character'Pos` while existing out-of-range diagnostics remain unchanged.

## Pass 595 semantic static-evaluation guard

- [ ] Confirm constrained String subtype attributes (`First`, `Last`, `Length`) are accepted as operands in later String index constraints.
- [ ] Confirm derived constrained String subtypes retain bounds from earlier constrained String subtype attributes.
- [ ] Confirm existing scalar static-integer attribute handling and constrained String qualification mismatch diagnostics remain unchanged.

## Pass 596 semantic static-evaluation guard

- [ ] Confirm constrained String object attributes (`First`, `Last`, `Length`) are accepted as operands in later String index constraints.
- [ ] Confirm derived constrained String subtypes retain bounds from earlier constrained String object attributes.
- [ ] Confirm existing constrained String object representation attributes and mismatch diagnostics remain unchanged.

## Pass 597 semantic static-evaluation guard

- [ ] Confirm constrained String subtype range attributes (`Range`) are accepted in later String index constraints.
- [ ] Confirm constrained String object range attributes (`Range`) are accepted in later String index constraints.
- [ ] Confirm `Range`-derived constrained String subtypes preserve retained `First`, `Last`, and `Length` metadata and still reject unrelated or unknown range sources.

## Pass 598 semantic static-evaluation guard

- [ ] Confirm spaced qualified String prefixes such as `String' ("Gr" & "een")'Length` are parsed as qualified String expressions before the final bound attribute.
- [ ] Confirm the static String bound scanner skips Ada separator characters after a qualification apostrophe without changing character-literal handling.
- [ ] Confirm compact qualified String bound expressions and existing constrained-qualification mismatch diagnostics remain unchanged.


## Pass 599 semantic static-evaluation guard

- [ ] Confirm direct static String bound attributes tolerate separator whitespace after the final apostrophe, for example `String' ("Gr" & "een")' Length`.
- [ ] Confirm spaced qualified prefixes are still classified before the final bound attribute is parsed.
- [ ] Confirm compact `String'(...)'Length`, character literal handling, and constrained qualification mismatch diagnostics remain unchanged.

## Pass 606 semantic static-evaluation guard

- [ ] Confirm fully qualified `Standard.String (Low .. High)` constrained subtypes retain `First`, `Last`, and `Length` metadata.
- [ ] Confirm `Standard.String` constrained subtype bounds feed representation-expression static values through the same path as unqualified `String` bounds.
- [ ] Confirm the broader recognition does not admit unrelated dotted names as String-compatible constrained subtypes.

## Pass 612 semantic static-evaluation guard

- [ ] Confirm copied String `Range` attribute dimension scanning skips Ada string literals and character literals while matching parentheses.
- [ ] Confirm dimension expressions containing character literals such as `Character'Pos (')')` are evaluated by the bounded static integer evaluator when they reduce to dimension `1`.
- [ ] Confirm copied String `Range` constraints still reject dimensions other than `1` and preserve existing named subtype/object/inline-qualified range behavior.

- [ ] Pass 613 regression: copied String `Range` constraint scanning selects the real top-level `Range` attribute when direct qualified prefixes and Character'Pos-bearing dimension expressions contain additional apostrophes.

## Pass 615 semantic static-evaluation guard

- [ ] Confirm direct qualified `Standard.String` bound attributes such as `Standard.String'("Green")'Length` feed bounded static representation-expression arithmetic.
- [ ] Confirm the qualified String bound evaluator uses canonical String subtype roots rather than accepting arbitrary dotted names.
- [ ] Confirm existing constrained String qualification, copied `Range`, and dimension checks remain unchanged.

## Pass 616 semantic static-evaluation guard

- Confirm qualified discrete constants with separator whitespace after the apostrophe, such as `Character' ('B')`, are retained as static constants.
- Confirm those retained constants feed later `Character'Pos` / scalar `T'Pos` representation-expression static values.
- Confirm compact qualified discrete constant spelling remains unchanged.

## Pass 617 - Separator-spaced discrete attribute defaults

- Confirm typed discrete constants initialized through spaced attribute designators, such as `Character' Succ (Letter)` and `Subtype' First`, are retained as static constants.
- Confirm these constants feed later `Character'Pos` / `T'Pos` representation expressions.
- Confirm compact attribute designator spelling remains unchanged.

## Pass 618 - Nested discrete Min/Max argument splitting

- Confirm `T'Min` / `T'Max` static attribute functions split their two operands only at a top-level comma.
- Confirm nested forms such as `Color'Max (Color'Min (Red, Green), Blue)` are retained as typed discrete static constants.
- Confirm string and character literals inside operands do not interfere with Min/Max comma detection.

## Pass 619 - Direct nested discrete Pos operands

- [x] `T'Pos` static integer evaluation scans nested static discrete operands at the outer argument level.
- [x] Direct `Color'Pos (Color'Max (Color'Min (...), ...))` representation expressions are regression-covered.
- [x] Literal skipping for Ada strings and character literals is preserved while locating the outer `T'Pos` close parenthesis.

## Pass 620 - Nested discrete operands in direct Min/Max arithmetic

- [x] Direct scalar Min/Max static-integer operand fallback is delimiter-aware at nesting depth zero only.
- [x] Operand fallback skips Ada string literals and character literals before matching comma/right-parenthesis delimiters.
- [x] Direct nested Min/Max expressions can feed representation-expression Size arithmetic without an intermediate constant or outer Pos call.
- [x] Direct qualified Succ operands can feed representation-expression Size arithmetic without truncating at the qualified operand close.
- [x] Regression coverage added for `Color'Max (Color'Min (Red, Green), Blue) * 8` and `Color'Succ (Color'(Green)) * 8`.

## Pass 621 - Nested scalar Value operand scanning

- [x] Direct scalar `Value` static-integer operands scan to the outer argument close while skipping nested parentheses and Ada literals.
- [x] `Color'Pos (Color'Value (Color'Image (Green))) * 8` feeds representation static arithmetic without an intermediate constant.
- [x] `T'Base'Value (...)` uses the same literal-aware operand scan for direct Base-Image-fed Value expressions.

## Pass 622 - Base Value nested operand scanner parity

- [x] Chained scalar `T'Base'Value (...)` reuses the same literal-aware outer-argument scanner as direct `T'Value`.
- [x] Nested string operands such as `Color'Base'Image (Blue)` are preserved intact before static `Value` resolution.
- [x] Direct Base-Value representation expressions remain covered in the discrete `Value` regression pass.
- [x] Bad named-string Value diagnostics remain explicitly declared and checked in the same regression harness.

## Pass 624 - Base-qualified compatible subtype discrete constants

- [x] `Subtype'Base'(...)` qualified discrete defaults evaluate their operand against the scalar root rather than the constrained subtype.
- [x] The declared object subtype range check still rejects retained values outside a constrained object subtype.
- [x] Regression coverage guards both accepted base-object and rejected constrained-object cases.

## Pass 625 - Separator-spaced Base-qualified discrete constants

- [x] Bounded static prefix normalization accepts separator whitespace between an attribute apostrophe and `Base`.
- [x] `Color' Base'(Blue)` and `Primary_Color' Base'(Blue)` feed retained discrete constants and later `T'Pos` representation expressions.
- [x] A constrained object initialized with an out-of-range `Subtype' Base'(...)` value remains nonstatic.

## Pass 626 - Static-expression operands for retained T'Val defaults

- [x] Retained discrete constant evaluation accepts bounded natural static expressions as `T'Val` operands.
- [x] `Color'Val (1 + 0)`-style constants are retained and can feed later `Color'Pos` representation arithmetic.
- [x] Declared object subtype range checks remain applied after Val operand evaluation.
- [x] Regression coverage added in the qualified discrete constant static-evaluation pass.

## Pass 627 - Literal-aware scalar attribute-default call scanner

- [x] Scalar attribute-function default parsing locates the outer call opening parenthesis while skipping Ada string and character literals.
- [x] `T'Val` defaults with character-derived static integer arithmetic remain retained discrete constants.
- [x] Regression coverage verifies the retained value feeds later `T'Pos` representation arithmetic.

## Pass 628 - Root-range chained Base scalar attributes

- [x] Direct representation-expression evaluation of `Subtype'Base'Val (...)` uses the scalar root range, not the constrained subtype range.
- [x] Direct `Subtype'Base'Succ (...)` and `Subtype'Base'Last` arithmetic can yield root values outside the constrained subtype when the base type permits them.
- [x] Regression coverage guards direct Base Val/Succ/Last arithmetic feeding static `Size` values.

## Pass 629 - Reduction attribute argument grammar

- [x] Token-cursor grammar emits dedicated reducer and initial-value productions for `Reduce`-style attribute calls.
- [x] `Reduce`, `Parallel_Reduce`, and `Map_Reduce` stay classified as reduction expressions while retaining their attribute argument part.
- [x] Selected operator-name reducers such as `Math."+"` retain selected-name structure inside the reduction reducer position.
- [x] Non-reduction attribute calls remain on the existing bounded attribute argument path.

## Pass 630 - Selected literal selector grammar

- [x] Selected-name suffix parsing retains ordinary selectors as dedicated selector productions.
- [x] Operator-symbol selectors such as `Math."+"` are no longer flattened into ordinary string-literal expression nodes.
- [x] Character-literal selectors are retained for selected enumeration-literal style names.
- [x] Representation targets continue to stop before attribute designators while retaining selected-name literal selectors.
- [x] `.all` explicit dereferences remain represented after the shared selected-suffix parser refactor.

## Pass 631 - Pragma identifier grammar

- [x] Token-cursor grammar emits a dedicated pragma-identifier production after the `pragma` keyword.
- [x] Nullary pragmas such as `pragma Elaborate_Body;` are parsed structurally without requiring a parenthesized argument list.
- [x] Pragmas with named argument associations retain both the pragma argument association and the pragma argument identifier.
- [x] Declaration and statement-sequence pragma placement remains parser-owned and bounded.
- [x] Regression coverage was added for declaration pragmas and a statement-sequence `Assert` pragma.

## Pass 632 - Declarative use-clause grammar ownership

- [x] Token-cursor use-clause grammar is shared between context and declarative parsing paths.
- [x] Declarative use clauses are not reported as context clauses.
- [x] `use`, `use type`, and `use all type` declarative item coverage has AUnit regression tests.
- [x] This remains structural grammar coverage, not compiler-grade visibility legality checking.

## Pass 633 - Subprogram completion aspect grammar

- [x] `is null` completion tails consume the `null` keyword before attached aspect parsing.
- [x] `is abstract` completion tails consume the `abstract` keyword before attached aspect parsing.
- [x] Contract aspects after null and abstract completions remain explicit token-cursor aspect productions.
- [x] Expression-function trailing aspects remain covered on the completion-tail regression surface.
- [x] Regression coverage verifies parser recovery into a following declaration after completion aspects.
- [x] This remains structural grammar coverage, not compiler-grade contract or aspect legality checking.

## Pass 634 - Formal package actual-part box grammar

- [x] Formal package `(<>)` actual parts are parsed as dedicated formal-package box productions.
- [x] Box-only formal package actual parts no longer create generic actual association nodes.
- [x] Non-box formal package actual parts still retain named generic actual selectors and `others => <>` box defaults.
- [x] Regression coverage includes box, named-association, `others => <>`, and no-actual-part formal package declarations.
- [x] This remains structural grammar coverage, not compiler-grade generic contract legality checking.

## Pass 635 - Selected subtype-mark selector grammar

- [x] `Parse_Subtype_Mark` uses the shared selected-name suffix parser for dotted subtype marks.
- [x] Ordinary selected subtype marks still leave following range/index/discriminant constraints to subtype-indication parsing.
- [x] Operator-symbol and character-literal selectors are retained as selected-name selector productions in subtype-mark contexts.
- [x] AUnit coverage guards selected subtype-mark selectors and parser recovery into a later declaration.
- [x] Scope remains structural grammar coverage only; no selector visibility, denotation, overload, or subtype-compatibility legality is claimed.

## Pass 636 - Address attribute-clause grammar classification

- [x] Token-cursor grammar classifies `for X'Address use ...;` as both an attribute-definition clause and an address clause.
- [x] Attribute designator structure remains visible for `Address`.
- [x] Regression coverage verifies parser recovery after the address clause.
- [x] Scope remains structural grammar coverage only; address legality and freezing legality are outside this pass.

## Pass 637 - Access-to-subprogram profile/result grammar

- [x] Access-to-subprogram parameter profiles are retained as dedicated grammar production events.
- [x] Access-to-function result subtype indications are retained as dedicated grammar production events.
- [x] Existing protected and null-excluded access definition coverage remains guarded by AUnit regression tests.
- [x] Scope remains structural grammar coverage only; callable conformance, accessibility, and result-subtype legality are outside this pass.

## Pass 638 - Qualified-expression part grammar

- [x] Token-cursor grammar emits a dedicated production for the qualifier subtype mark in qualified expressions.
- [x] Token-cursor grammar emits a dedicated production for the parenthesized operand in qualified expressions.
- [x] Allocator qualified expressions share the same part-level productions while preserving allocator-specific classification.
- [x] Regression coverage guards ordinary, nested, aggregate-like, allocator, and selected-name qualifier forms.
- [x] Scope remains structural grammar coverage only; subtype compatibility, aggregate legality, and qualification legality are outside this pass.

## Pass 639 - Raise construct exception/message grammar

- [x] Raise statements retain dedicated exception-name grammar production events.
- [x] Raise expressions retain dedicated exception-name grammar production events.
- [x] Raise `with` parts retain dedicated message-expression grammar production events.
- [x] Bare re-raise statement coverage remains intact.
- [x] Regression coverage guards both statement and expression forms.
- [x] Scope remains structural grammar coverage only; exception legality and message typing are outside this pass.

## Pass 640 - Case-expression dependent-expression grammar

- [x] Token-cursor grammar emits a dedicated production for the dependent-expression side of each case-expression alternative.
- [x] Existing case-expression selector and alternative productions remain intact.
- [x] Regression coverage includes nested conditional, qualified, and raise expressions in case alternatives.
- [x] Parser recovery after case-expression declarations remains covered.
- [x] Scope remains structural grammar coverage only; no case-choice coverage, overlap, expected-type, or conformance legality is claimed.

## Pass 641 - Extension aggregate grammar

- [x] Token-cursor grammar emits `Production_Extension_Aggregate` for parenthesized aggregate forms with a top-level non-delta `with`.
- [x] Extension aggregate ancestor parts are retained separately from component associations.
- [x] `with null record` and component associations after `with` remain structurally parsed.
- [x] `with delta` remains classified as a delta aggregate, not as an extension aggregate.
- [x] Regression coverage includes ordinary, null-record, and qualified-expression ancestor extension aggregates and parser recovery after them.
- [x] Scope remains structural grammar coverage only; no tagged-type ancestry, component conformance, or aggregate completeness legality is implied.

## Pass 642 - Iterated component association domain/filter grammar

- [x] Token-cursor grammar emits `Production_Iterated_Component_Domain` for the domain side of aggregate iterated component associations.
- [x] Token-cursor grammar emits `Production_Iterated_Component_Iterator_Filter` for optional `when` filters.
- [x] Token-cursor grammar emits `Production_Iterated_Component_Expression` for the component-expression side after `=>`.
- [x] Discrete ranges in aggregate iterator domains remain visible through range-expression productions.
- [x] Regression coverage includes for-in, for-of-reverse, filtered, and mixed aggregate association forms.
- [x] Scope remains structural grammar coverage only; no aggregate legality, iterator legality, filter type, or component conformance legality is implied.

## Pass 643 - Delta aggregate base/association grammar

- [x] Token-cursor grammar emits `Production_Delta_Aggregate_Base` for the base expression before top-level `with delta`.
- [x] Token-cursor grammar emits `Production_Delta_Aggregate_Association` for each association after `with delta`.
- [x] Existing component-association and discrete-choice-list parsing remains active inside delta aggregate associations.
- [x] Extension aggregate classification continues to reject `with delta` forms.
- [x] Regression coverage includes simple, qualified-base, choice-list, and target-name delta aggregate forms.
- [x] Scope remains structural grammar coverage only; no delta aggregate legality or component conformance is implied.

## Pass 644 - Conditional-expression else dependent-expression grammar

- [x] Token-cursor grammar emits `Production_If_Expression_Else_Dependent_Expression` for conditional-expression else branches.
- [x] Condition, then-dependent, elsif, and else-part productions remain intact.
- [x] Regression coverage includes nested case and raise expressions inside else dependent expressions.
- [x] Parser recovery after conditional-expression declarations remains covered.
- [x] Scope remains structural grammar coverage only; no expected-type or branch-conformance legality is implied.

## Pass 645 - Declare-expression part grammar

- [x] Token-cursor grammar emits `Production_Declare_Expression_Declarative_Part` for declarations before `begin` in Ada 2022 declare expressions.
- [x] Token-cursor grammar emits `Production_Declare_Expression_Body_Expression` for the expression after `begin`.
- [x] Existing nested declaration parsing inside declare expressions remains active.
- [x] Regression coverage includes declare expressions in object initializers and assignment statements.
- [x] Scope remains structural grammar coverage only; no declaration legality, lifetime, subtype, or expected-type conformance is implied.

## Pass 646 - Conditional-expression elsif branch grammar

- [x] Token-cursor grammar emits `Production_Elsif_Expression_Condition` for conditional-expression `elsif` branch conditions.
- [x] Token-cursor grammar emits `Production_Elsif_Expression_Then_Dependent_Expression` for conditional-expression `elsif ... then` dependent expressions.
- [x] Existing initial-if condition, then-dependent, and else-dependent productions remain intact.
- [x] Regression coverage includes multiple elsif branches with nested qualified, case, and raise expressions.
- [x] Scope remains structural grammar coverage only; no expected-type, branch-conformance, or staticness legality is implied.

## Pass 647 - If-statement branch structure grammar

- [x] Token-cursor grammar emits `Production_If_Statement_Condition` for initial if-statement conditions.
- [x] Token-cursor grammar emits `Production_If_Statement_Then_Statements` for initial then branches.
- [x] Token-cursor grammar emits `Production_Elsif_Statement_Condition` and `Production_Elsif_Statement_Then_Statements` for statement-level elsif branches.
- [x] Token-cursor grammar emits `Production_Else_Statement_Sequence` for statement-level else branches.
- [x] Regression coverage includes multiple elsif branches, short-circuit conditions, branch-local raise statements with messages, and recovery after the if statement.
- [x] Scope remains structural grammar coverage only; no boolean typing, reachability, statement legality, or control-flow legality is implied.

## Pass 648 - Loop-statement iteration-scheme grammar

- [x] Token-cursor grammar emits `Production_For_Loop_Iteration_Scheme` for discrete `for ... in ... loop` statements.
- [x] Token-cursor grammar emits `Production_For_Loop_Parameter` and `Production_For_Loop_Iteration_Domain` for for-loop parameter/domain structure.
- [x] Token-cursor grammar emits `Production_Iterator_Loop_Iteration_Scheme`, `Production_Iterator_Loop_Element`, and `Production_Iterator_Loop_Domain` for `for ... of ... loop` statements.
- [x] Token-cursor grammar emits `Production_While_Loop_Condition` for while-loop conditions.
- [x] Token-cursor grammar emits `Production_Loop_Statement_Sequence` while preserving generic statement-sequence markers.
- [x] Regression coverage includes reverse discrete loops, reverse iterator loops, while-loop short-circuit conditions, nested exit-when statements, and recovery into following statements.
- [x] Scope remains structural grammar coverage only; no iterator legality, discrete subtype legality, boolean typing, or control-flow legality is implied.

## Pass 649 - Case-statement selector/alternative statement grammar

- [x] Token-cursor grammar emits `Production_Case_Statement_Selector` for statement-level case selectors.
- [x] Token-cursor grammar emits `Production_Case_Alternative_Statement_Sequence` for statements after `when ... =>`.
- [x] Existing generic statement-sequence markers remain intact for current consumers.
- [x] Regression coverage includes choice lists, range choices, nested alternative contents, and recovery after the case statement.
- [x] Scope remains structural grammar coverage only; no selector type, choice coverage, overlap, or statement legality is implied.

## Pass 650 - Block-statement declarative/handled/exception part grammar

- [x] Token-cursor grammar emits `Production_Block_Declarative_Part` for block declarative parts.
- [x] Token-cursor grammar emits `Production_Block_Statement_Sequence` for handled statement sequences after `begin`.
- [x] Token-cursor grammar emits `Production_Block_Exception_Part` for block exception parts.
- [x] Existing generic statement-sequence markers remain intact for current consumers.
- [x] Regression coverage includes labelled nested blocks, local declarations, exception handlers, raise-message statements, and recovery after the block.
- [x] Scope remains structural grammar coverage only; no block legality, handler legality, reachability, or control-flow legality is implied.

## Pass 651 - Exception-handler statement-sequence grammar

- [x] Token-cursor grammar emits `Production_Exception_Handler_Statement_Sequence` for statements after exception-handler arrows.
- [x] Parameterized exception handlers continue to retain choice parameters and exception choice lists.
- [x] Unparameterized handlers in exception parts are classified as exception handlers rather than only generic case alternatives.
- [x] Existing generic statement-sequence markers remain intact for current consumers.
- [x] Regression coverage includes parameterized handlers, `when others`, nested raise-message statements, and block exception-part integration.
- [x] Scope remains structural grammar coverage only; no exception-choice legality, handler reachability, exception resolution, or control-flow legality is implied.

## Pass 652 - Accept-statement entry/index/profile grammar

- [x] Token-cursor grammar emits `Production_Accept_Entry_Name` for accepted entry names.
- [x] Token-cursor grammar emits `Production_Accept_Entry_Index` for entry-family accept index expressions.
- [x] Token-cursor grammar emits `Production_Accept_Parameter_Profile` for optional accept parameter profiles.
- [x] Token-cursor grammar emits `Production_Accept_Statement_Sequence` for `accept ... do` handled statement sequences while retaining generic statement-sequence markers.
- [x] Regression coverage includes guarded select alternatives, indexed entry-family accepts, parameter profiles, accept do-parts, and existing select recovery paths.
- [x] Scope remains structural grammar coverage only; no tasking legality, profile conformance, entry-family resolution, or rendezvous semantics are implied.

## Pass 653 - Delay-statement expression grammar

- [x] Token-cursor grammar emits `Production_Delay_Relative_Expression` for relative-duration delay operands.
- [x] Token-cursor grammar emits `Production_Delay_Until_Expression` for absolute-time delay operands.
- [x] Existing delay statement productions remain intact.
- [x] Regression coverage includes relative and absolute delays, nested qualified/selected-name expressions, and recovery after delay statements.
- [x] Scope remains structural grammar coverage only; no time expression type conformance, tasking legality, or real-time semantic checking is implied.

## Pass 654 - Select-statement alternative/guard/body grammar

- [x] Token-cursor grammar emits `Production_Select_Guard_Condition` for guarded select alternative conditions.
- [x] Token-cursor grammar emits `Production_Select_Alternative_Statement_Sequence` for statements belonging to each select alternative.
- [x] Token-cursor grammar emits `Production_Select_Else_Statement_Sequence` for conditional-select else parts.
- [x] Token-cursor grammar emits `Production_Abortable_Statement_Sequence` for asynchronous-select abortable parts.
- [x] Existing generic statement-sequence markers remain intact for current consumers.
- [x] Regression coverage includes guarded alternatives, timed alternatives, conditional-select else parts, terminate alternatives, and asynchronous-select abortable parts.
- [x] Scope remains structural grammar coverage only; no select-kind legality, guard typing, tasking legality, or abortable-part semantics are implied.

## Pass 655 - Return-statement expression/do-part grammar

- [x] Token-cursor grammar emits `Production_Return_Expression` for ordinary return-statement operands.
- [x] Token-cursor grammar emits `Production_Extended_Return_Statement_Sequence` for extended-return do-parts.
- [x] Existing generic statement-sequence markers remain intact for current consumers.
- [x] Regression coverage includes simple return expressions with nested qualified, case, and raise expressions and recovery after return statements.
- [x] Scope remains structural grammar coverage only; no return type conformance, extended-return object legality, function/procedure context, accessibility, or control-flow legality is implied.

## Pass 656 - Requeue-statement target/index grammar

- [x] Token-cursor grammar emits `Production_Requeue_Entry_Name` for requeue target names.
- [x] Token-cursor grammar emits `Production_Requeue_Entry_Index` for optional requeue entry-family indexes.
- [x] Selected entry names remain structural through the shared selected-name suffix parser.
- [x] `Production_Requeue_With_Abort` remains emitted after target/index parsing for `with abort` modifiers.
- [x] Regression coverage includes simple requeue statements, selected entry-family targets, entry indexes, and `with abort` modifiers.
- [x] Scope remains structural grammar coverage only; no tasking context legality, callable target resolution, entry-family conformance, or abortability legality is implied.

## Pass 657 - Call/entry-call target and actual-part grammar

- [x] Token-cursor grammar emits `Production_Call_Target` for statement-level call targets.
- [x] Token-cursor grammar emits `Production_Call_Actual_Part` for call statements carrying apparent actual parts.
- [x] Entry-call-shaped statements emit `Production_Entry_Call_Target` and `Production_Entry_Call_Actual_Part` when selected/indexed suffixes or actuals make the statement entry-call-shaped.
- [x] Selected-name and indexed-component suffix parsing remains delegated to the existing primary/name grammar path.
- [x] Regression coverage includes bare calls, selected calls with named actuals, entry-family-shaped calls, and recovery into a following assignment.
- [x] Scope remains structural grammar coverage only; no callable target resolution, entry conformance, overload resolution, parameter-mode legality, or dispatching semantics are implied.

## Pass 658 - Abort-statement target-list grammar

- [x] Token-cursor grammar emits `Production_Abort_Target_List` for abort-statement task-name lists.
- [x] Token-cursor grammar emits `Production_Abort_Target_Name` for each abort target name.
- [x] Existing abort-statement and abort-target productions remain intact for current consumers.
- [x] Regression coverage includes multiple abort targets, selected task names, indexed task-name components, explicit dereference suffixes, and statement grammar integration.
- [x] Scope remains structural grammar coverage only; no task-name resolution, tasking legality, abortability, accessibility, or runtime task semantics are implied.

## Pass 659 - Assignment target/expression grammar

- [x] Token-cursor grammar emits `Production_Assignment_Target` for assignment left-hand sides.
- [x] Token-cursor grammar emits `Production_Assignment_Expression` for assignment right-hand side expressions.
- [x] Existing selected-name, indexed-component, slice, and explicit-dereference suffix parsing remains intact for assignment targets.
- [x] Regression coverage includes nested qualified, case, conditional, and raise expressions in assignment operands.
- [x] Scope remains structural grammar coverage only; no assignability, parameter-mode, expected-type, accessibility, or target legality checking is implied.

## Pass 660 - Label-name structural grammar

- [x] Token-cursor grammar emits `Production_Label_Name` for explicit label statements.
- [x] Statement identifiers before compound statements retain explicit label-name positions.
- [x] Existing label and labeled-statement productions remain intact for current consumers.
- [x] Regression coverage includes both `<<Label>>` labels and statement identifiers before compound statements.
- [x] Scope remains structural grammar coverage only; no label/goto resolution, duplicate-label checking, or control-flow legality is implied.

## Pass 661 - Goto/exit target-name grammar

- [x] Token-cursor grammar emits `Production_Exit_Loop_Name` for optional exit loop names.
- [x] Token-cursor grammar emits `Production_Goto_Label_Name` for goto target label names.
- [x] Existing exit/goto target and condition productions remain intact for current consumers.
- [x] Regression coverage includes named exits, exit conditions, goto targets, explicit labels, and statement recovery.
- [x] Scope remains structural grammar coverage only; no label/goto resolution, loop-name matching, duplicate-label checking, reachability, or control-flow legality is implied.

## Pass 662 - Entry-barrier condition grammar

- [x] Token-cursor grammar emits `Production_Entry_Barrier_Condition` for entry body barrier operands after `when`.
- [x] Existing entry body and entry barrier productions remain intact.
- [x] Regression coverage includes short-circuit barrier conditions and recovery after entry body stubs.
- [x] Scope remains structural grammar coverage only; no protected/tasking context legality, barrier type conformance, or rendezvous semantics are implied.

## Pass 663 - Generic instantiation internal-name grammar

- [x] Token-cursor grammar emits `Production_Generic_Instance_Name` for the instance defining name in package/procedure/function instantiations.
- [x] Token-cursor grammar emits `Production_Generic_Instantiated_Unit_Name` for the generic unit name after `is new`.
- [x] Token-cursor grammar emits `Production_Generic_Instantiation_Actual_Part` while preserving the existing generic actual-part and association productions.
- [x] Regression coverage includes package, procedure, and function instantiations with selected generic names, named actuals, selected operator actuals, attached aspects, and recovery after instantiations.
- [x] Scope remains structural grammar coverage only; no generic contract matching, visibility, overload resolution, or generic-instance legality checking is implied.

## Pass 664 - Entry declaration internal grammar

- [x] Token-cursor grammar emits `Production_Entry_Identifier` for entry declaration/body identifiers.
- [x] Token-cursor grammar emits `Production_Entry_Family_Discrete_Subtype_Definition` for entry-family declarations.
- [x] Token-cursor grammar emits `Production_Entry_Parameter_Profile` while preserving ordinary parameter-profile productions.
- [x] Regression coverage includes task/protected entries, entry families, parameter profiles, barriers, and recovery through following declarations.
- [x] Scope remains structural grammar coverage only; no entry-family matching, entry profile conformance, barrier typing, or tasking legality checking is implied.

## Pass 665 - Subprogram body internal grammar

- [x] Token-cursor grammar emits `Production_Subprogram_Defining_Designator` for subprogram defining designators.
- [x] Token-cursor grammar emits `Production_Function_Result_Subtype` for function result subtype positions.
- [x] Token-cursor grammar emits dedicated subprogram body declarative-part, statement-sequence, and exception-part productions.
- [x] Existing parameter-profile, subtype-indication, statement-sequence, and exception-handler productions remain intact for current consumers.
- [x] Regression coverage includes function/procedure bodies, result subtype retention, declarative parts, handled statement sequences, exception parts, and recovery after bodies.
- [x] Scope remains structural grammar coverage only; no body/spec conformance, result subtype legality, declaration legality, handler legality, or control-flow semantics are implied.

## Pass 666 - Package body internal grammar

* Added dedicated token-cursor productions for package body names, declarative parts, statement sequences, and exception parts.
* Package body parsing now keeps selected body names such as `Parent.Child` structural before parsing the `is` boundary.
* Added AUnit regression coverage for package body declarations, begin sections, exception parts, nested raise messages, and recovery into following declarations.
* This improves structural grammar coverage for Ada package body internals; it is not compiler-grade legality checking.


## Pass 667 - Task and protected body internal grammar

- [x] Added explicit task body name/declarative/statement/exception productions.
- [x] Added explicit protected body name/operation-part productions.
- [x] Extended token-cursor parsing for task and protected body internals.
- [x] Added AUnit regression coverage for concurrent body internals and recovery.
- [x] Documented that this is structural grammar coverage, not compiler-grade legality checking.

## Pass 668 - Task and protected definition part grammar

- [x] Added explicit task definition public/private part productions.
- [x] Added explicit protected definition public/private part productions.
- [x] Preserved existing task/protected declaration and nested entry/profile grammar productions.
- [x] Added AUnit regression coverage for concurrent specification internals and recovery.
- [x] Documented that this is structural grammar coverage, not compiler-grade legality checking.

## Pass 669 - Generic formal object internal grammar

- [x] `Production_Formal_Object_Defining_Name_List` is emitted for generic formal object declaration name lists.
- [x] `Production_Formal_Object_Subtype_Indication` is emitted for generic formal object subtype positions.
- [x] Existing mode/default and subtype parsing paths remain compatible with current consumers.
- [x] AUnit coverage exercises grouped formal names, selected subtype indications, access-to-subprogram subtype indications, defaults, and recovery.
- [x] Release notes state that this is structural grammar coverage, not generic formal legality checking.

## Pass 670 - Generic formal subprogram internal grammar

- [x] `Production_Formal_Subprogram_Defining_Designator` is emitted for generic formal procedure/function designators.
- [x] `Production_Formal_Subprogram_Result_Subtype` is emitted for generic formal function result subtype positions.
- [x] Existing formal subprogram defaults, parameter profiles, aspects, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises formal designators, result subtype positions, defaults, and recovery.
- [x] Release notes state that this is structural grammar coverage, not generic formal subprogram legality checking.

## Pass 671 - Generic formal type declaration-head grammar

- [x] `Production_Formal_Type_Defining_Name` is emitted for generic formal type defining names.
- [x] `Production_Formal_Type_Discriminant_Part` is emitted before known and unknown formal type discriminant parts.
- [x] Existing formal type definition, discriminant specification, unknown discriminant, aspect, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises formal type declaration heads, known/unknown discriminants, aspects, and recovery.
- [x] Release notes state that this is structural grammar coverage, not generic formal type legality checking.

## Pass 672 - Subtype declaration internal grammar

- [x] `Production_Subtype_Defining_Name` is emitted for subtype declaration defining identifiers.
- [x] `Production_Subtype_Declaration_Subtype_Indication` is emitted for the subtype-indication side after `is`.
- [x] Existing subtype mark, selected-name, range-constraint, aspect, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises subtype defining names, subtype indications, selected operator subtype marks, aspects, and recovery.
- [x] Release notes state that this is structural grammar coverage, not subtype declaration legality checking.

## Pass 673 - Object declaration internal grammar

- [x] `Production_Object_Defining_Name_List` is emitted for object declaration defining-name-list positions.
- [x] `Production_Object_Subtype_Indication` is emitted before object declaration subtype/access parsing.
- [x] `Production_Object_Initialization_Expression` is emitted before object declaration initializer expressions.
- [x] Existing object declaration qualifier, subtype-indication, aspect, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises object declaration internals, selected operator subtype marks, initializer expressions, aspects, and recovery.
- [x] Release notes state that this is structural grammar coverage, not object declaration legality checking.

## Pass 674 - Number and exception declaration internal grammar

- [x] `Production_Number_Defining_Name_List` is emitted for named-number declaration defining-name-list positions.
- [x] `Production_Number_Initialization_Expression` is emitted before named-number initializer expression parsing.
- [x] `Production_Exception_Defining_Name_List` is emitted for exception declaration defining-name-list positions.
- [x] Grouped defining-name lists before `:` are retained structurally for object, number, and exception declarations.
- [x] Existing exception renaming, aspect-specification, object declaration, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises grouped named numbers, qualified number initializers, grouped exceptions, exception renamings, attached aspects, and recovery.
- [x] Release notes state that this is structural grammar coverage, not number/exception declaration legality checking.

## Pass 675 - Type declaration internal grammar

- [x] `Production_Type_Defining_Name` is emitted for type declaration defining identifiers.
- [x] `Production_Type_Discriminant_Part` is emitted before known and unknown type discriminant parts.
- [x] Existing full, incomplete, tagged incomplete, enumeration, record, and private type parsing remains compatible with current consumers.
- [x] AUnit coverage exercises type defining names, known/unknown discriminants, incomplete declarations, tagged incomplete declarations, enumeration definitions, and recovery.
- [x] Release notes state that this is structural grammar coverage, not type declaration legality checking.

## Pass 676 - Component declaration internal grammar

- [x] `Production_Component_Defining_Name_List` is emitted for record component declaration defining-name-list positions.
- [x] `Production_Component_Subtype_Indication` is emitted before component subtype-indication parsing.
- [x] `Production_Component_Default_Expression` is emitted before component default-expression parsing.
- [x] Existing component declaration, component definition, aliased-part, subtype-indication, default-expression, aspect, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises grouped components, aliased component definitions, selected operator subtype marks, qualified defaults, and recovery.
- [x] Release notes state that this is structural grammar coverage, not component declaration legality checking.

## Pass 677 - Discriminant specification internal grammar

- [x] `Production_Discriminant_Defining_Name_List` is emitted for grouped discriminant defining-name-list positions.
- [x] `Production_Discriminant_Subtype_Indication` is emitted before discriminant subtype-indication parsing.
- [x] `Production_Discriminant_Default_Expression` is emitted before discriminant default-expression parsing.
- [x] Existing discriminant-part, unknown-discriminant, subtype-indication, default-expression, and declaration recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises grouped discriminants, selected subtype indications, selected default expressions, default-expression retention, and recovery.
- [x] Release notes state that this is structural grammar coverage, not discriminant specification legality checking.

## Pass 678 - Variant part internal grammar

- [x] `Production_Variant_Part_Discriminant_Name` is emitted for record variant-part selector names.
- [x] `Production_Variant_Choice_List` is emitted before each variant alternative discrete choice list.
- [x] `Production_Variant_Component_Part` is emitted after `=>` for each variant alternative component part.
- [x] Existing record-definition, component-declaration, discrete-choice-list, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises variant selectors, alternative choice lists, component parts, component declarations, and recovery.
- [x] Release notes state that this is structural grammar coverage, not variant-part legality checking.

## Pass 679 - Renaming declaration internal grammar

- [x] `Production_Renaming_Defining_Name` is emitted for renaming declaration defining names.
- [x] `Production_Renaming_Subtype_Indication` is emitted for object renaming subtype-indication positions.
- [x] `Production_Renaming_Parameter_Profile` is emitted for subprogram renaming parameter-profile positions.
- [x] `Production_Renaming_Result_Subtype` is emitted for function renaming result subtype positions.
- [x] Existing renamed-entity and selected-name parsing remains compatible with current consumers.
- [x] AUnit coverage exercises package, subprogram, object, exception, and generic renaming internals.
- [x] Release notes state that this is structural grammar coverage, not renaming legality checking.

## Pass 680 - Array type definition internal grammar

- [x] `Production_Array_Index_Subtype_Definition` is emitted for ordinary array index subtype definitions.
- [x] `Production_Array_Component_Definition` is emitted before component subtype-indication parsing after `of`.
- [x] Aliased array component definitions retain the `Production_Aliased_Part` marker.
- [x] Existing formal-array, index-constraint, range, and subtype-indication parsing remains compatible with current consumers.
- [x] AUnit coverage exercises unconstrained array indexes, constrained array ranges, component definitions, aliased components, and declaration recovery.
- [x] Release notes state that this is structural grammar coverage, not array type legality checking.

## Pass 681 - Scalar type definition operand grammar

- [x] `Production_Signed_Integer_Range` is emitted before signed integer range parsing.
- [x] `Production_Modular_Modulus_Expression` is emitted before modular modulus expression parsing.
- [x] `Production_Floating_Digits_Expression` is emitted before floating-point digits expression parsing.
- [x] `Production_Fixed_Delta_Expression` and `Production_Fixed_Digits_Expression` are emitted for fixed-point operand positions.
- [x] Existing signed/modular/floating/fixed type-definition classifications and range-constraint parsing remain compatible with current consumers.
- [x] AUnit coverage exercises scalar type operand retention and declaration recovery.
- [x] Release notes state that this is structural grammar coverage, not scalar type legality checking.

## Pass 682 - Derived type definition internal grammar

- [x] `Production_Derived_Parent_Subtype` is emitted before parsing the parent subtype after `new`.
- [x] `Production_Derived_Interface_List` is emitted when ordinary derived type definitions contain an `and` interface list.
- [x] `Production_Derived_Interface_Subtype` is emitted for each interface subtype in the derived interface list.
- [x] Existing derived type, private extension, record extension, subtype-indication, selected-name, and recovery paths remain compatible with current consumers.
- [x] AUnit coverage exercises parent subtype retention, interface-list retention, interface subtype retention, private extensions, record extensions, and declaration recovery.
- [x] Release notes state that this is structural grammar coverage, not derived type legality checking.

## Pass 683 - Interface type parent-list internal grammar

- [x] `Production_Interface_Parent_List` is emitted when ordinary interface type definitions contain an `and` parent list.
- [x] `Production_Interface_Parent_Subtype` is emitted for each parent subtype in the ordinary interface parent list.
- [x] Existing interface type, type-modifier, subtype-indication, selected-name, and attribute-reference parsing remains compatible with current consumers.
- [x] AUnit coverage exercises limited/synchronized interface forms, parent-list retention, individual parent subtype retention, attribute suffix preservation, and declaration recovery.
- [x] Release notes state that this is structural grammar coverage, not interface type legality checking.

### Pass 684 generic formal type modifier and parent grammar guard

- [x] `Production_Formal_Type_Modifier` is emitted for modifiers on generic formal private, derived, and interface type definitions.
- [x] `Production_Formal_Interface_Subtype` is emitted for each subtype in formal derived/interface `and` lists.
- [x] `Production_Formal_Private_Extension_Definition` is emitted for formal derived `with private` extensions.
- [x] Formal array component definitions retain `aliased` as `Production_Aliased_Part` before component subtype parsing.
- [x] AUnit coverage exercises formal modifiers, formal parent subtype lists, attribute suffixes on formal parent subtype marks, aliased formal array components, and recovery into the generic unit.
- [x] Scope remains structural grammar coverage only; no generic contract legality, interface legality, visibility, freezing, staticness, or conformance checking is implied.

- Pass 685: generic formal package declaration grammar now retains formal package defining names, formal-package-specific actual associations, named/operator selectors, whole-part `(<>)` boxes, association-level `=> <>` boxes, and malformed-actual-list recovery into following generic formals. This is structural grammar coverage only; do not market it as compiler-grade generic formal package legality checking.

- Pass 686: pragma grammar now retains nullary pragma markers, pragma-specific argument-list markers, argument-expression markers, named argument selectors, and malformed argument recovery into following declarations/statements. This is structural grammar coverage only; do not market it as compiler-grade pragma legality or implementation-defined pragma validation.

## Pass 687 - Use-clause grammar guard

- [x] Ordinary `use P, Q;` clauses retain `Production_Use_Package_Name_List` and per-name `Production_Use_Package_Name` markers.
- [x] `use type T, U;` and `use all type T, U;` clauses retain `Production_Use_Type_Subtype_Mark_List` and per-mark `Production_Use_Type_Subtype_Mark` markers.
- [x] `use all type` retains `Production_Use_All_Type_Prefix` explicitly.
- [x] Comma separators in use-clause lists are retained with `Production_Use_Clause_Separator`.
- [x] Empty and trailing-comma use-clause lists recover into following declarations without context-clause ownership leakage.
- [x] The grammar remains structural only and does not claim compiler-grade visibility or legality checking.

## Pass 688 - Representation and operational item grammar guard

- [x] Class-wide operational attributes such as `T'Class'Input` retain `Production_Classwide_Attribute_Prefix` before the final attribute designator.
- [x] Stream attribute-definition clauses retain `Production_Stream_Attribute_Definition_Clause` in addition to the generic operational item markers.
- [x] Representation and operational item values retain `Production_Representation_Value_Expression` markers before expression parsing.
- [x] Address clauses retain `Production_Address_Value_Expression` markers separate from ordinary representation values.
- [x] Named enumeration representation associations retain `Production_Enumeration_Representation_Choice_List` before `=>`, while positional associations continue to parse as value expressions.
- [x] AUnit coverage exercises the new markers and confirms recovery through following record representation component clauses.
- [x] Release wording remains structural grammar coverage only, not compiler-grade representation or operational item legality checking.

## Pass 689 - Subprogram contract/aspect grammar guard

- [x] Contract aspects retain `Production_Contract_Aspect_Association` in addition to generic aspect associations.
- [x] Contract aspect marks and value positions retain `Production_Contract_Aspect_Mark` and `Production_Contract_Aspect_Value`.
- [x] `Global` and `Refined_Global` payloads retain `Production_Global_Aspect_Expression` before expression parsing.
- [x] `Depends` and `Refined_Depends` payloads retain `Production_Depends_Aspect_Expression` before expression parsing.
- [x] Malformed missing contract aspect values produce bounded recovery and continue into following declarations.
- [x] AUnit coverage exercises type/subprogram/protected-operation contract aspects, class-wide marks, Global/Depends payload markers, and malformed-value recovery.
- [x] Release wording remains structural grammar coverage only, not compiler-grade contract, aspect-placement, refinement, staticness, visibility, freezing, or flow legality checking.

## Pass 690 - Package declarative item boundary guard

- [x] `Editor.Ada_Token_Cursor` exposes package visible-part, private-part, and package-body declarative-item productions.
- [x] Package-boundary scanning treats nested package specifications as bounded declarative items so nested `private`/`end` tokens do not leak into the enclosing package part.
- [x] AUnit coverage exercises visible package items, private package items, nested package recovery, package-body declarative items, and recovery into the body statement sequence.
- [x] Release wording remains structural grammar coverage only, not compiler-grade package visibility, private completion, body/spec conformance, freezing, elaboration, or declaration-order legality checking.

## Pass 691 - Anonymous access-to-subprogram profile guard

- [x] `Editor.Ada_Token_Cursor` exposes `Production_Access_Subprogram_Profile` for anonymous callable access profiles.
- [x] `Editor.Ada_Token_Cursor` exposes `Production_Access_Subprogram_Kind` for procedure/function profile kind retention.
- [x] `Editor.Ada_Token_Cursor` exposes `Production_Access_Subprogram_Result_Profile` for anonymous access-to-function result profiles.
- [x] Protected anonymous access-to-subprogram forms retain the protected-prefix marker without introducing target-name leaks.
- [x] AUnit coverage exercises named access types, anonymous access-to-subprogram parameters, anonymous access result profiles, protected profiles, and continuation into following declarations.
- [x] Release wording remains structural grammar coverage only, not compiler-grade profile conformance, accessibility, protected-operation legality, null-exclusion legality, visibility, dispatching, or overload-resolution checking.

## Pass 692 - Expression-family grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes branch-expression markers for conditional expression dependent expressions.
- [x] Case-expression alternatives retain explicit choice-list and arrow productions.
- [x] Quantified expressions retain the predicate arrow marker before predicate parsing.
- [x] Parallel and map reductions are distinguishable from ordinary reductions while preserving the shared reduction marker.
- [x] AUnit coverage exercises nested conditional/case/quantified/allocator/reduction expressions and verifies recovery into following declarations.
- [x] Release wording remains structural grammar coverage only, not compiler-grade expression typing, overload resolution, allocator legality, quantified-expression legality, reduction conformance, or execution semantics.

## Pass 693 - Name-family grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes `Production_Selected_Name_Prefix` for selected-name prefix/selector boundaries.
- [x] Selected operator-symbol and character-literal selectors retain the shared `Production_Selected_Literal_Selector` marker plus their specific selector markers.
- [x] Allocators retain `Production_Allocator_Subtype_Mark` for named subtype allocators and `Production_Allocator_Access_Subtype` for `new access ...` forms.
- [x] Qualified expressions retain `Production_Qualified_Expression_Apostrophe` at the subtype-mark/operand boundary.
- [x] AUnit coverage exercises selected operator/character literal names, qualified-expression apostrophe boundaries, access-subtype allocators, and recovery into following declarations.
- [x] Release wording remains structural grammar coverage only, not compiler-grade selected-name legality, visibility, overload resolution, allocator accessibility, subtype-mark legality, or qualified-expression typing.

## Pass 694 - Task/protected grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes `Production_Protected_Operation_Declaration`, `Production_Protected_Operation_Aspect_Specification`, and `Production_Protected_Entry_Barrier`.
- [x] Entry-family index subtype syntax is retained with `Production_Entry_Family_Index_Subtype` without replacing existing entry-family/discrete-subtype markers.
- [x] Accept bodies, select `or` alternatives, and `then abort` alternatives retain `Production_Accept_Do_Part`, `Production_Select_Or_Alternative`, and `Production_Select_Then_Abort_Part`.
- [x] AUnit coverage exercises protected operations/aspects, entry-family index subtypes, protected barriers, accept do-parts, select-or alternatives, then-abort alternatives, requeue-with-abort retention, and declaration recovery.
- [x] Release wording remains structural grammar coverage only, not compiler-grade protected operation legality, barrier semantics, selective-accept legality, asynchronous transfer semantics, requeue legality, visibility, accessibility, or conformance checking.

- [ ] Pass695: verify conservative duplicate callable profile parameter
      diagnostics remain bounded, local, and non-compiler-grade; confirm no LSP,
      compiler, parser-generator, rendering-side parsing, file save/reload, or
      dirty-state mutation is introduced.

## Pass 696 - Formal package generic-contract edge cases

- [x] Formal package actual parsing retains nested actual/call association parts without terminating the enclosing actual list at inner commas or close parentheses.
- [x] Association-level `=> <>` boxes and whole-part `(<>)` boxes remain distinct formal-package productions.
- [x] Trailing comma and missing-close-parenthesis cases emit a formal-package actual recovery-boundary marker and resume at following generic formals.
- [x] AUnit coverage guards nested actual associations, box defaults, association boxes, malformed actual-list recovery, and continuation into following formal type declarations.
- [x] Scope remains structural grammar coverage only; no generic contract matching, visibility, conformance, staticness, box legality, or elaboration checking is implied.

### Pass 697 local duplicate declaration-family diagnostics

- Verify that `Legality_Duplicate_Record_Component_Name`,
  `Legality_Duplicate_Discriminant_Name`,
  `Legality_Duplicate_Enumeration_Literal_Name`, and
  `Legality_Duplicate_Generic_Formal_Name` remain present in the language model.
- Verify that the parser retains the local declaration-family duplicate scan.
- Verify that AUnit coverage exercises duplicate record components,
  discriminants, enumeration literals, and generic formals.
- Confirm that these diagnostics remain local/structural and do not claim
  compiler-grade visibility, overload, generic-contract, or cross-unit legality.

- Pass 698: discriminant grammar depth regression coverage must retain known vs
  unknown discriminant markers, access-discriminant markers, discriminant default
  markers, named discriminant-constraint expression markers, and recovery into
  following declarations.

## Pass 699 - Variant record grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes `Production_Variant_Choice_Arrow`, `Production_Variant_Others_Choice`, `Production_Variant_Choice_Separator`, `Production_Nested_Variant_Part`, and `Production_Variant_Recovery_Boundary`.
- [x] Variant record parsing retains `when ... =>` arrow positions, `others` alternatives, `|` choice separators, and nested variant parts.
- [x] Malformed variant alternatives with missing `=>` emit a bounded recovery marker and continue into following declarations.
- [x] AUnit coverage exercises nested variants, `others` choices, multi-choice alternatives, missing-arrow recovery, and declaration recovery.
- [x] Release wording remains structural grammar coverage only, not compiler-grade discriminant dependence, choice coverage, duplicate-choice, component legality, representation, visibility, or staticness checking.

### Phase 579 pass 700 note

Entry/select grammar coverage now retains tasking-specific structural markers
for select entry-call alternatives, timed entry-call delay alternatives,
conditional entry-call else alternatives, select delay/terminate alternatives,
entry-call target names, and indexed entry-call prefixes. Consumers must treat
these as parser-owned structural metadata only; they do not imply compiler-grade
entry resolution, guard legality, timed/conditional entry-call legality, or
runtime tasking semantics.

### Phase 579 pass 701 exception grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes exception-depth productions for
  renaming targets, handler-local names, choice separators/arrows, `others`
  choices, raise-statement targets, and raise-expression target/message
  positions.
- [x] Exception handlers retain multi-choice lists and `others` choices without
  flattening them into generic case alternatives.
- [x] Malformed exception handlers emit bounded recovery markers and do not stop
  subsequent parsing.
- [x] AUnit coverage exercises exception declarations, exception renaming,
  choice-parameter handlers, multi-choice handlers, `others` handlers, raise
  statements with messages, bare re-raise, and malformed-handler recovery.
- [x] Release wording remains structural grammar coverage only, not compiler-grade
  exception visibility, handler ordering, reachability, raise typing, or message
  expression legality.

### Phase 579 pass 702 loop/block/declare grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes productions for statement identifiers,
  named loops, named blocks, loop iterator filters, loop/block end names,
  declare-block statements, declare-block declarative items, and bounded block
  recovery boundaries.
- [x] Named loop and named declare-block forms retain both the statement
  identifier and the following executable grammar family.
- [x] Loop iterator filters retain a structural marker before the loop body.
- [x] `end loop Name;` and `end Name;` suffixes are retained without mutating
  editor state or requiring compiler semantic information.
- [x] AUnit coverage exercises named loops, named declare blocks, iterator
  filters, block exception parts, explicit end-name suffixes, and recovery into
  nested declarations.
- [x] Release wording remains structural grammar coverage only, not compiler-grade
  label matching, iterator legality, control-flow semantics, or exception
  propagation analysis.


### Phase 579 pass 703 body-stub / separate-subunit grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes productions for separate parent unit
  names, separate nested body declarations, separate package/subprogram/task/
  protected/entry body classification, and explicit body-stub `separate`
  completion keywords.
- [x] Body stubs retain a stub-specific marker instead of being represented only
  as ordinary body declarations.
- [x] Separate subunits retain the parent name and classify the following body
  family without rendering-side parsing or compiler invocation.
- [x] AUnit coverage exercises package, subprogram, task, protected, and entry
  body stubs plus package/subprogram/task/protected/entry separate subunit bodies.
- [x] Release wording remains structural grammar coverage only, not compiler-grade
  parent resolution, stub/subunit matching, body/spec conformance, visibility,
  ordering, or elaboration checking.

### Phase 579 pass 704 renaming-target grammar guard

- [x] `Editor.Ada_Token_Cursor` exposes productions for renamed object, package,
  subprogram, and generic-unit target positions.
- [x] Selected renamed targets and operator-symbol renamed targets retain
  explicit structural markers.
- [x] Malformed `renames ;` tails emit a bounded recovery marker and continue
  into following declarations.
- [x] AUnit coverage exercises object, package, subprogram, operator-function,
  generic package, generic function, selected-target, operator-target, and
  malformed-tail renaming forms.
- [x] Release wording remains structural grammar coverage only, not compiler-grade
  visibility, overload, profile conformance, generic-renaming, operator-symbol,
  subtype-conformance, or elaboration legality checking.

### Phase 579 pass 705 attribute grammar-depth guard

- [x] `Editor.Ada_Token_Cursor` exposes productions for attribute designator
  names, class-wide attribute-reference chains, subtype-mark attribute references,
  attribute argument associations, attribute argument expressions, and bounded
  attribute recovery boundaries.
- [x] Argument-bearing attributes such as `A'First (1)` and `T'Image (X)` retain
  attribute-owned argument structure rather than being flattened into ordinary
  indexed-component syntax.
- [x] Class-wide chains such as `T'Class'Object_Size` retain an explicit marker
  useful to later resolver and semantic-colouring consumers.
- [x] Malformed attribute argument lists emit bounded recovery markers and
  continue into following declarations.
- [x] AUnit coverage exercises argument-bearing attributes, class-wide chains,
  subtype-mark attributes, malformed argument recovery, and declaration recovery.
- [x] Release wording remains structural grammar coverage only, not compiler-grade
  attribute availability, staticness, dimensionality, prefix-category, subtype/
  expression resolution, or result-typing legality checking.

## Pass706 note - semantic-colouring precision

Pass706 refines parser-owned Ada semantic-colouring fallback classification for executable bindings. Callable-shaped bindings such as call targets, select entry calls, requeue targets, and accept entries now use the subprogram token bucket when unresolved; type-shaped qualified-expression, conversion, and allocator targets use the type token bucket. Ambiguous unresolved reference-only forms such as selected components and attribute prefixes intentionally degrade to ordinary identifiers to reduce false positives. This remains structural language-model colouring, not compiler-grade name or overload resolution.


### Phase 579 pass 707 Outline precision guard

- [x] Outline labels distinguish variant record types from ordinary record types
  when the language model supplies variant-record metadata.
- [x] Outline labels distinguish entry-family declarations from ordinary entries
  when the language model supplies entry-family metadata.
- [x] Generic formal detail text distinguishes formal package/subprogram/type/
  object rows instead of flattening all formal declarations to one detail form.
- [x] AUnit coverage exercises generic formal packages, variant records, entry
  families, exceptions, and body stubs through the Outline extractor.
- [x] Release wording remains structural presentation coverage only, not
  compiler-grade generic, tasking, exception, separate-body, visibility, overload,
  or elaboration legality checking.


## Pass708 release guard - aggregate association grammar depth

- Ensure `Production_Aggregate_Positional_Component`,
  `Production_Aggregate_Named_Component_Association`,
  `Production_Aggregate_Component_Choice_List`,
  `Production_Aggregate_Component_Arrow`, `Production_Aggregate_Others_Choice`,
  `Production_Null_Record_Aggregate`, and
  `Production_Aggregate_Recovery_Boundary` remain present.
- Keep `Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness`
  registered.
- Treat this as structural grammar coverage, not compiler-grade aggregate legality
  checking.

## Pass709 release guard - range/index constraint grammar depth

- Ensure `Production_Range_Lower_Bound`, `Production_Range_Upper_Bound`,
  `Production_Range_Attribute_Reference`, `Production_Range_Attribute_Prefix`,
  `Production_Index_Constraint_Item`, and `Production_Constraint_Recovery_Boundary`
  remain present.
- Keep `Test_Language_Model_Token_Cursor_Range_Constraint_Depth_Grammar_Completeness`
  registered.
- Treat this as structural grammar coverage, not compiler-grade range/index
  constraint legality checking.

- Pass710 guard: case-statement choice grammar must retain
  `Production_Case_Choice_List`, `Production_Case_Others_Choice`,
  `Production_Case_Choice_Separator`, `Production_Case_Choice_Arrow`,
  `Production_Case_Alternative_Recovery_Boundary`, and
  `Test_Language_Model_Token_Cursor_Case_Statement_Choice_Depth_Grammar_Completeness`.
  Case alternatives such as `when 1 | 2 =>`, `when others =>`, and malformed
  missing-arrow alternatives must not regress to opaque statement recovery.

- Pass711 guard: if-statement grammar must retain explicit `then`, `elsif`,
  `else`, `end if`, and missing-`then` recovery markers with AUnit coverage.

- Pass712 guard: assignment/call statement ambiguity must retain
  `Production_Statement_Name_Suffix`, selected/indexed/slice/dereference
  assignment-target markers, selected/actual-bearing call-target markers, and
  `Test_Language_Model_Token_Cursor_Assignment_Call_Ambiguity_Grammar_Completeness`.
  This is structural grammar coverage only and must not be described as
  compiler-grade call resolution or assignment legality checking.


- [ ] Pass713 return statement grammar-depth guard remains present: return-object defining names, subtype/initializer markers, extended-return `do`/`end return` boundaries, recovery boundaries, and AUnit coverage.

## Pass714 exit/goto/null/delay statement refinement guard

- Token cursor exposes `Production_Null_Statement_Terminator`,
  `Production_Exit_When_Keyword`, `Production_Exit_Recovery_Boundary`,
  `Production_Goto_Recovery_Boundary`, `Production_Delay_Mode_Keyword`, and
  `Production_Delay_Recovery_Boundary`.
- AUnit regression coverage includes malformed `exit when;`, `goto;`, and
  `delay;` recovery plus successful continuation into a following assignment.
- Scope remains structural grammar coverage only, not compiler-grade control-flow
  or tasking legality checking.

## Pass715 subprogram body declarative-part depth guard

- Token cursor exposes `Production_Subprogram_Body_Declarative_Item`,
  `Production_Subprogram_Body_Begin_Keyword`,
  `Production_Subprogram_Body_End_Keyword`, and
  `Production_Subprogram_Body_Recovery_Boundary`.
- AUnit regression coverage keeps nested declarations before `begin`, explicit
  exception/end boundaries, malformed missing-`begin` recovery, and continuation
  into following declarations covered.
- Scope remains structural grammar coverage only, not compiler-grade body/spec,
  completion, elaboration, visibility, or control-flow legality checking.

### Pass716 generic instantiation grammar depth

- Token cursor exposes generic package/procedure/function instantiation markers.
- Generic actual parts expose positional associations, named selectors,
  association boxes, nested actual association lists, and recovery boundaries.
- Regression coverage includes package/procedure/function instantiations,
  nested actual associations, named boxes, and recovery into a following
  declaration after a malformed actual list.
- Validation guard checks the new productions and regression name.
- Scope remains structural parser coverage, not compiler-grade generic legality.

## Pass717 array type definition grammar-depth guard

- Confirm `Production_Unconstrained_Array_Index_Part`,
  `Production_Constrained_Array_Index_Part`,
  `Production_Array_Index_Subtype_Name`,
  `Production_Array_Index_Range_Box`,
  `Production_Array_Component_Subtype_Indication`, and
  `Production_Array_Component_Access_Definition` remain present in the token
  cursor.
- Confirm `Test_Language_Model_Token_Cursor_Array_Type_Depth_Grammar_Completeness`
  remains registered in the AUnit suite.
- Confirm malformed array index definitions recover into following declarations
  without dirty-state, renderer, command-palette, keybinding, workspace, LSP, or
  compiler-invocation side effects.

### Pass718 - access type definition grammar depth

- The Ada token cursor now retains deeper structural markers for pool-specific access objects, general access objects, access object subtype marks, access-to-subprogram definitions, protected callable access profiles, and malformed access-type recovery boundaries.
- This improves parser-owned metadata available to Outline and semantic-colouring consumers without adding compiler-grade legality checking, external parser generators, LSP, rendering-side parsing, or dirty-state mutation.

### Phase 579 Pass 720

- Confirm local duplicate-choice diagnostics remain parser-owned and bounded.
- Confirm duplicate case, variant, exception, aggregate, and delta-aggregate
  selector diagnostics do not mutate dirty state or trigger rendering-side
  parsing.
- Confirm the new diagnostics are documented as structural legality-adjacent
  checks, not compiler-grade choice coverage or expected-type analysis.

### Pass 721 Outline type-family precision guard

- [x] Outline labels distinguish array, access, access-to-subprogram, derived,
      private-extension, null-extension, interface, and tagged type families
      when parser metadata is available.
- [x] Generic formal type rows use matching formal type-family labels.
- [x] Existing detail metadata remains available for filtering and inspection.
- [x] AUnit coverage exercises the new Outline labels without requiring
      compiler-grade type legality checks.

## Pass 722 — Semantic colouring precision after grammar expansion

Pass 722 refines parser-owned Ada semantic-colouring metadata after the grammar-depth passes.  It adds explicit binding roles for generic actual selectors, aggregate component selectors, and extended-return object defining names.  Unresolved selector-like roles now degrade to ordinary identifiers, while assignment targets, labels, and extended-return objects remain value-like local bindings and call targets remain callable bindings.  This improves colouring precision without adding compiler-grade resolution or rendering-side parsing.



## Pass 723 subtype-indication grammar depth

Pass 723 adds explicit token-cursor markers for subtype marks, subtype-context null exclusions, and subtype range/digits/delta/index/discriminant constraints. This improves parser-owned structure used by Outline and semantic-colouring consumers while remaining structural only, not compiler-grade subtype legality checking.

- [x] Phase 579 pass724 object declaration grammar-depth guard updated: grouped
      object defining names, aliased/constant qualifiers, anonymous access object
      definitions, malformed declaration recovery, and AUnit coverage are
      represented without compiler invocation or rendering-side parsing.

- [x] Pass725 retains named-number declaration internals structurally: grouped defining names, separators, number-specific `constant` keyword, initializer expression markers, malformed missing-initializer recovery, AUnit coverage, and validation-guard markers.

- Pass727 guard: use-clause projection must retain `Use_Clause_Count`,
  `Use_Clause_At`, and `Test_Language_Model_Use_Clauses_Project_Individual_Metadata`.
  Ordinary `use`, `use type`, and `use all type` names must remain individual
  language-model visibility metadata entries with distinct clause kinds. This is
  structural parser/index metadata, not compiler-grade use-clause legality.

## Phase 579 pass728 — formal package actual resolver view

- [x] Formal package symbols with known generic targets feed selected-name resolver metadata.
- [x] Formal package named actuals are substituted during expression type inference through selected template children.
- [x] Regression coverage includes `Test_Language_Model_Formal_Package_Actuals_Feed_Resolver_View`.
- [x] No synthetic declarations, rendering-side parsing, dirty-state mutation, or compiler-backed semantic lookup were introduced.

## Phase 579 pass729 — pragma placement metadata projection

- [x] `Editor.Ada_Language_Model` retains bounded pragma metadata through
  `Pragma_Metadata_Count` and `Pragma_Metadata_At`.
- [x] Pragma placement distinguishes configuration, declarative, statement,
  and alternative pragmas structurally.
- [x] Pragma metadata retains first target/argument text, total argument count,
  named argument association count, scope, and range.
- [x] Regression coverage includes
  `Test_Language_Model_Pragma_Placement_And_Target_Metadata`.
- [x] Pragmas remain metadata only and must not create outline or resolver
  declaration symbols.

This guard covers structural pragma projection only; it is not a compiler-grade
pragma legality or implementation-defined pragma semantics check.

## Phase 579 pass730 — aspect placement grammar depth

- [x] Token-cursor grammar exposes placement productions for generic formal,
      concurrent type, entry, protected-operation, body-stub,
      private-completion-style, and body aspect specifications.
- [x] Existing aspect association, aspect mark, contract-aspect, and aspect
      value productions remain the canonical representation of the aspect list.
- [x] Regression coverage extends
      `Test_Language_Model_Token_Cursor_Aspect_Placement_Grammar_Completeness`.
- [x] Aspects remain parser/language-model metadata only; no compiler-backed
      legality, rendering-side parsing, dirty-state mutation, or synthetic
      declaration symbols were introduced.

## Phase 579 pass731 — representation / operational projection consistency

- [x] `Representation_Source_Form` is present in the Ada language model.
- [x] Representation clauses retain source-form metadata for attribute,
      aspect, pragma, address, enumeration, and record representation forms.
- [x] Record component representation rows retain component-clause source form
      and existing static bit-position metadata.
- [x] Regression coverage includes
      `Test_Language_Model_Representation_Operational_Projection_Metadata`.
- [x] The pass remains structural parser/model coverage only; no compiler-backed
      representation legality, stream profile conformance, rendering-side
      parsing, or dirty-state mutation was introduced.

## Phase 579 pass732 — package declarative-item recovery depth

* Keep package recovery parser-owned and bounded; no rendering-side parsing,
  compiler invocation, LSP, or external parser generator.
* Retain recovery productions:
  * `Production_Package_Declarative_Recovery_Boundary`
  * `Production_Package_Unexpected_Begin_Boundary`
  * `Production_Package_Body_Unexpected_Private_Boundary`
* Keep regression coverage:
  * `Test_Language_Model_Token_Cursor_Package_Declarative_Item_Hostile_Recovery`
* This pass improves structural package/spec/body declarative-item recovery only;
  it is not compiler-grade package legality, private conformance, generic
  conformance, or freezing-rule validation.

## Phase 579 pass733 — anonymous access-to-subprogram edge grammar

* Keep anonymous access-to-subprogram parsing token-cursor-owned and bounded; no
  rendering-side parsing, compiler invocation, LSP, or external parser generator.
* Retain edge productions:
  * `Production_Access_Subprogram_Null_Exclusion`
  * `Production_Access_Subprogram_Parameter_Default`
  * `Production_Access_Subprogram_Result_Null_Exclusion`
  * `Production_Access_Subprogram_Result_Constraint`
  * `Production_Access_Subprogram_Profile_Recovery_Boundary`
* Keep regression coverage:
  * `Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery`
* This pass improves structural anonymous access-to-subprogram grammar coverage
  only; it is not compiler-grade accessibility, profile conformance, overload,
  or null-exclusion legality checking.

## Pass734 release guard — expression/name edge-case grammar recovery

* Keep the token-cursor productions `Production_Allocator_Nested_Qualified_Expression`, `Production_Conversion_Or_Qualified_Expression`, `Production_Chained_Attribute_Reference`, `Production_Call_Or_Indexed_Component`, and `Production_Reduction_Argument_Recovery_Boundary`.
* Keep the AUnit regression `Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery`.
* Do not replace this structural metadata with rendering-side parsing, compiler calls, LSP queries, external parser generators, Python, or shell scripts.
* This guard covers editor-owned grammar recovery only.  It is not compiler-grade overload, conversion, reduction, accessibility, or expected-type legality checking.

## Phase 579 pass735 — validation guard cleanup

* Keep `Check_Recent_Grammar_Pass_Guards` in
  `tools/phase579_language_validation_check.adb` as the pass-ordered guard
  matrix for pass724 through pass734.
* The grouped matrix must continue to cover object declarations, number
  declarations, formal package actual projection, use-clause projection, formal
  package resolver views, pragma placement metadata, aspect placement
  productions, representation source forms, package recovery, anonymous
  access-to-subprogram profiles, and expression/name edge recovery.
* Keep the validation helper routines for language-model API, parser
  projection, resolver-body, token-cursor production, and syntax-regression
  markers so new guard entries remain categorized.
* The validation flow must not invoke `Check_Parser_And_Model_Features` twice.
* This guard cleanup is release-validation maintainability only; it does not
  imply compiler-grade legality checking or add new grammar recognition.

## Phase 579 pass736 — Ada parser coverage matrix consolidation

* Keep `docs/ada_parser_coverage_matrix.md` as the canonical coverage-status
  table for current Ada parser/language-model work.
* The matrix must retain columns for token-cursor coverage, syntax-tree/parser
  coverage, language-model projection, resolver/semantic-colouring use, and
  explicit non-goals.
* The matrix must cover the current grammar/model families: context clauses,
  packages, subprograms, declarations, types, generics, pragmas, aspects,
  representation/operational items, statements, expressions, names, anonymous
  access-to-subprogram definitions, recovery, and validation guards.
* Do not use the matrix to claim complete Ada grammar or compiler-grade legality
  checking.
* This guard covers documentation/release-validation consolidation only; it does
  not add grammar recognition, compiler invocation, LSP integration,
  rendering-side parsing, or dirty-state mutation.

## Phase 579 pass737 — case-statement alternative depth grammar

* Confirm `Production_Case_Statement_Is_Keyword`, `Production_Case_Choice`,
  `Production_Case_Range_Choice`, and
  `Production_Case_Alternative_Null_Statement` remain present in
  `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Case_Statement_Alternative_Depth`
  remains registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.

## Phase 579 pass738 — select-statement alternative depth grammar

* Confirm `Production_Select_First_Alternative`,
  `Production_Select_Accept_Alternative`,
  `Production_Select_Delay_Until_Alternative`,
  `Production_Select_Delay_Relative_Alternative`,
  `Production_Select_Terminate_Alternative`, and
  `Production_Select_Guard_Arrow` remain present in `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Select_Statement_Alternative_Depth`
  remains registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.


## Phase 579 pass739 — exception-handler choice depth grammar

* Confirm `Production_Exception_Named_Choice`,
  `Production_Exception_Selected_Choice`, and
  `Production_Exception_Handler_Null_Statement` remain present in
  `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth`
  remains registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.

## Phase 579 pass740 — loop iteration-scheme metadata depth

* Confirm `Production_While_Loop_Keyword`,
  `Production_For_Loop_Reverse_Iteration`,
  `Production_For_Loop_Range_Iteration`,
  `Production_Iterator_Loop_Reverse_Iteration`,
  `Production_Loop_Iterator_Filter_Condition`, and
  `Production_Loop_Begin_Keyword` remain present in `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Loop_Iteration_Scheme_Metadata`
  remains registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.


## Phase 579 pass741 — entry family/index metadata depth

* Confirm `Production_Entry_Family_Range_Definition`,
  `Production_Entry_Body_Index_Identifier`,
  `Production_Entry_Body_Index_Subtype`,
  `Production_Entry_Barrier_When_Keyword`,
  `Production_Accept_Entry_Index_Expression`,
  `Production_Entry_Call_Selected_Target`,
  `Production_Entry_Call_Selected_Entry_Name`, and
  `Production_Entry_Call_Family_Index` remain present in
  `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Entry_Family_Index_Depth` remains
  registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.

## Pass742 note

Pass742 deepens structural Ada variant-record component alternative metadata. The token cursor now retains explicit markers for individual variant choices, range choices, variant component declarations, and `null;` component alternatives, with AUnit and validation guard coverage. This is structural parser metadata only, not compiler-grade discriminant legality or variant coverage checking.

## Phase 579 pass743 — aggregate association depth metadata

* Confirm `Production_Aggregate_Index_Choice`,
  `Production_Aggregate_Range_Choice`, `Production_Aggregate_Box_Component`,
  and `Production_Extension_Aggregate_Component_Association` remain present in
  `Editor.Ada_Token_Cursor`.
* Confirm `Test_Language_Model_Token_Cursor_Aggregate_Association_Depth_Grammar_Completeness`
  remains registered with the syntax/semantics AUnit suite.
* Confirm the pass remains structural only: no compiler invocation, no LSP, no
  rendering-side parsing, and no dirty-state mutation.

## Phase 579 pass744 release guard

- Run the language validation guard and ensure the pass744 markers for
  `Profile_Parameter_Info`, `Profile_Parameter_Mode`, `Profile_Parameter_Count`,
  `Profile_Parameter_At`, parser projection via `Add_Profile_Parameter_Metadata`,
  and `Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata` remain
  present.
- Treat this as structural profile-parameter metadata only; do not claim
  compiler-grade parameter legality, mode conformance, accessibility, or overload
  resolution.

- [ ] Pass745 generic formal type detail metadata remains guarded: `Generic_Formal_Type_Info`, `Generic_Formal_Type_Family`, metadata count/index accessors, parser projection, and `Test_Language_Model_Generic_Formal_Type_Detail_Metadata` must remain present.

- [ ] Pass746: verify conservative syntax-recovery diagnostics remain
      recovery-node driven and do not introduce compiler invocation, LSP usage,
      rendering-side parsing, dirty-state mutation, or broad semantic legality
      claims.


## Phase 579 pass747 note

Pass747 adds hostile-source recovery regression coverage for mixed malformed Ada
constructs. The parser must retain bounded recovery metadata for malformed
generic formal package actuals, variants, aggregates, select alternatives, and
exception handlers, while resuming into later declarations and bodies. This is
structural recovery coverage only, not compiler-grade legality checking.

- [x] Pass748 retains extended return object qualifiers and constraints structurally: aliased/constant qualifiers, access definitions, null exclusions, constrained subtype indications, AUnit coverage, and validation-guard markers.

- Pass749 guard: abort-statement target-shape productions and regression coverage must remain present (`Production_Abort_Selected_Target`, `Production_Abort_Indexed_Target`, `Production_Abort_Dereferenced_Target`, `Production_Abort_Target_Separator`, `Production_Abort_Recovery_Boundary`).

- Pass750 guard: verify raise statement/expression metadata retains selected
  exception-name productions, explicit `with` message keyword boundaries, and
  bounded malformed-message recovery markers without compiler invocation or
  render-side parsing.

## Phase 579 pass751 release guard

* Confirm the validation guard still requires standalone delay-statement markers:
  `Production_Delay_Until_Keyword`,
  `Production_Delay_Selected_Time_Expression`,
  `Production_Delay_Qualified_Time_Expression`, and
  `Production_Delay_Statement_Terminator`.
* Confirm the delay-statement AUnit regression covers selected and qualified
  delay expressions while preserving bounded malformed-delay recovery.


## Phase 579 pass752 release guard

* Confirm validation requires `Production_Requeue_Selected_Target`,
  `Production_Requeue_Indexed_Target`, and
  `Production_Requeue_Target_Recovery_Boundary`.
* Confirm the requeue AUnit regression covers selected targets, indexed
  entry-family targets, `with abort`, and malformed empty `requeue;` recovery.

## Phase 579 pass753 release guard

* Confirm validation requires `Production_Label_Open_Delimiter`,
  `Production_Label_Close_Delimiter`, `Production_Label_Recovery_Boundary`,
  `Production_Goto_Terminator`, and `Production_Goto_Label_Recovery_Boundary`.
* Confirm `Test_Language_Model_Token_Cursor_Label_Goto_Metadata_Depth` remains
  registered and covers label delimiters, malformed label recovery, goto
  terminators, goto label-name recovery, executable label metadata, and
  conservative same-scope missing-goto diagnostics.
* Do not describe this as compiler-grade goto legality, reachability, or
  control-flow analysis.

## Phase 579 pass754 release guard

- [x] Token-cursor grammar retains block declarative-part depth with `Production_Block_Declare_Keyword`, `Production_Block_Declarative_Item_Start`, `Production_Block_Declarative_Begin_Boundary`, `Production_Block_Exception_Keyword`, and `Production_Block_Label_Name`.
- [x] AUnit coverage extends `Test_Language_Model_Token_Cursor_Block_Statement_Grammar_Completeness` for block labels, declare keywords, declarative item starts, begin boundaries, and exception keyword metadata.
- [x] This remains structural grammar/recovery metadata only, not compiler-grade block legality or control-flow analysis.


## Phase 579 pass755

Task/protected body internals now retain deeper structural metadata. Task bodies expose declarative-item starts plus explicit `begin`/`end` boundaries, and protected bodies expose operation-body `begin`/`end` markers plus bounded recovery for misplaced `private` sections. Consumers must continue treating this as structural parser metadata, not tasking legality or synchronization analysis.

- [ ] Pass756 guard: entry/procedure call ambiguity metadata remains covered by token-cursor productions and AUnit regression.

## Pass757 separate subunit / body-stub depth

Pass757 deepens structural token-cursor metadata for Ada `separate` subunits and body stubs. Dotted parent-unit names retain separator and child-name markers; package, subprogram, task, and protected subunit bodies retain body-kind and local unit-name markers; body stubs retain conservative subunit-link hint metadata. This is grammar/model metadata only, not compiler-grade subunit legality or cross-file conformance checking.


- Pass758 guard: context-clause detail projection must retain root context ownership, `limited`/`private` modifier flags, comma-separated context names, and context/declarative use-clause separation. This is structural metadata only, not compiler-grade context-clause legality checking.

- [ ] Pass759: local duplicate representation-clause diagnostics require resolved same-symbol targets and retain no rendering-side parsing, compiler invocation, LSP integration, or dirty-state mutation.

## Phase 579 pass760 release guard

- [ ] Keep `docs/ada_parser_coverage_matrix.md` titled as the pass760 canonical coverage matrix.
- [ ] Confirm the matrix includes rows for case/select/exception alternatives, loop iteration schemes, entry/tasking statements, call-shaped statements, separate subunits/body stubs, recovery diagnostics, context clauses, and local representation diagnostics.
- [ ] Confirm the validation tool requires the refreshed pass760 matrix markers.
- [ ] Do not describe the matrix as compiler-grade Ada legality coverage; it is structural parser/model documentation and release-guard consolidation only.

## Phase 579 pass761 release guard

- Verify that semantic colouring consumption remains parser-owned through
  `Build_Map_From_Analysis`.
- Verify `Test_Syntax_Semantics_New_Metadata_Consumers_Pass761` remains present.
- Verify context/use clause names, generic formal type metadata, profile
  parameter metadata, pragma metadata, and representation/operational metadata
  are covered by the semantic-colouring documentation.
- Do not treat these display tokens as compiler-grade visibility, overload,
  tasking, or representation legality results.


## Phase 579 pass762 release guard

- Run the Phase 579 language validation guard and keep the pass762 markers for `Binding_Call_Selected_Prefix`, `Binding_Call_Entry_Family_Candidate`, the call ambiguity hint scanner, the AUnit regression `Test_Language_Model_Call_Ambiguity_Resolver_Hints`, and the coverage-matrix row `Call/entry-call resolver hints`.
- Verify that the feature remains syntax/model metadata only and does not introduce compiler invocation, LSP, render-side parsing, overload resolution, dirty-state mutation, or tasking semantic validation.

## Phase 579 pass763 release guard

- [ ] Keep subprogram and entry body-stub aspect placement covered by `Production_Body_Stub_Aspect_Specification` and the AUnit regression `Test_Language_Model_Token_Cursor_Body_Stub_Aspect_Placement_Depth`.
- [ ] Confirm `docs/ada_parser_coverage_matrix.md` remains titled for pass763 and documents body-stub aspect placement as structural grammar coverage only.
- [ ] Do not treat body-stub aspect placement metadata as compiler-grade subunit conformance, body-stub legality, contract legality, tasking semantic validation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Phase 579 pass764 release guard

- [ ] Keep `Production_Formal_Package_Actual_Positional_Association` in the token-cursor grammar so formal package positional actuals are not only visible as generic instantiation actuals.
- [ ] Keep `Test_Language_Model_Token_Cursor_Formal_Package_Positional_Actuals` registered with the syntax semantics suite.
- [ ] Confirm mixed formal package actual parts with positional actuals, named operator selectors, `others => <>`, and association-level boxes remain structural.
- [ ] Do not market this as compiler-grade generic contract conformance, formal package matching, overload resolution, generic semantic expansion, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass765 guard: keep `Production_Formal_Package_Defaulted_Actual_Part` and `Test_Language_Model_Token_Cursor_Formal_Package_Defaulted_Actuals` so omitted formal package actual parts such as `with package P is new G;` and aspect-bearing forms after the generic package name remain distinct from explicit `(<>)` box defaults and ordinary parenthesized actual lists.

- Pass766 guard: keep `Production_Representation_Pragma`, `Production_Operational_Pragma`, and `Test_Language_Model_Token_Cursor_Representation_Pragma_Item_Depth` so pragma aliases such as `pragma Pack`, `pragma Atomic`, `pragma Import`, and operational pragmas such as `pragma Priority` retain dedicated structural metadata while preserving ordinary pragma identifier and argument-list parsing.

- [x] Pass767 pragma argument association depth: named, positional, and box pragma arguments are structurally tagged in token-cursor regressions without adding pragma legality semantics.


- [x] Pass768 qualified-expression selected subtype-mark depth: keep `Production_Qualified_Expression_Selected_Subtype_Mark` exercised for ordinary selected subtype marks, selected operator-literal subtype marks, and allocator qualified-expression selected subtype marks without adding subtype-resolution or conversion legality semantics.


## Phase 579 pass769 release guard

- [x] Keep `Production_Package_Body_Declarative_Recovery_Boundary` and `Production_Subprogram_Body_Declarative_Recovery_Boundary` in the token cursor.
- [x] Keep `Test_Language_Model_Token_Cursor_Body_Declarative_Item_Recovery_Depth` registered so malformed package/subprogram body declarative regions synchronize without losing following declarations.
- [x] Treat the metadata as bounded structural recovery only, not compiler-grade declaration legality, visibility, body/spec conformance, elaboration analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Phase 579 pass770 release guard

- [x] Keep `Production_Access_Protected_Subprogram_Definition`, `Production_Access_Protected_Procedure_Profile`, and `Production_Access_Protected_Function_Profile` in the token cursor.
- [x] Keep `Test_Language_Model_Token_Cursor_Anonymous_Access_Protected_Profile_Depth` registered so protected anonymous access-to-subprogram profiles and dangling `access protected` recovery stay covered.
- [x] Treat the metadata as bounded structural grammar coverage only, not compiler-grade protected-operation legality, accessibility analysis, profile conformance, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Phase 579 pass771 semantic-colouring projection guard

- Keep `Test_Syntax_Semantics_Metadata_Does_Not_Downgrade_Symbols_Pass771` registered in `Editor.Syntax_Semantics.Tests`.
- `Build_Map_From_Analysis` must preserve concrete parser-owned symbol kinds over metadata-only fallback roles from visibility, pragma, profile, representation, and unresolved executable-binding metadata.
- Unknown or ambiguous metadata must continue to degrade conservatively rather than overwriting resolved declaration classifications.


## Phase 579 pass772 call association diagnostic guard

- Keep `Legality_Positional_Call_Actual_After_Named` in `Editor.Ada_Language_Model.Legality_Diagnostic_Kind`.
- Keep `Test_Language_Model_Legality_Call_Positional_After_Named_Pass772` registered in `Editor.Syntax_Semantics.Tests`.
- Preserve the local-only diagnostic boundary: report retained top-level positional actuals after named call associations without adding overload resolution, callable profile matching, default-parameter legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Phase 579 pass773 selected-name grammar-depth guard

- Keep `Production_Selected_Name_Separator`, `Production_Selected_Name_Chain_Component`, and `Production_Selected_Name_Missing_Selector` in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Name_Grammar_Refinement_Completeness` covering selected-name separators, selector chain components, operator/character selectors, and dangling-selector recovery.
- Preserve the local structural boundary: this metadata is for parser/model consumers only and must not become compiler-grade name resolution, selector legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Phase 579 pass774 release guard

- Confirm `Production_Allocator_Null_Exclusion`, allocator constraint productions, and `Test_Language_Model_Token_Cursor_Allocator_Constraint_Depth_Pass774` remain present.
- Confirm allocator constraint metadata remains structural and does not imply compiler-grade allocator legality, subtype compatibility, accessibility, or overload resolution.

## Phase 579 pass775 release guard

- Confirm `Production_Renaming_Aspect_Specification` and `Test_Language_Model_Token_Cursor_Renaming_Aspect_Placement_Pass775` remain present.
- Confirm renaming aspect metadata remains structural parser placement metadata and does not imply compiler-grade renaming legality, renamed-entity resolution, aspect legality, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Phase 579 pass776 release guard

- Confirm `Production_Formal_Scalar_Box_Recovery_Boundary`, `Production_Formal_Derived_Interface_List`, and `Production_Formal_Interface_Ancestor_List` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Generic_Formal_Type_Edge_Depth_Pass776` registered in the syntax semantics AUnit suite.
- Confirm malformed generic formal scalar definitions synchronize without consuming declaration semicolons or trailing aspect introducers.
- Confirm derived/interface formal ancestor-list metadata remains structural and does not imply compiler-grade generic contract conformance, formal matching, private-extension legality checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass777 attribute-definition clause detail depth

- Confirm `Production_Size_Attribute_Definition_Clause`, `Production_Alignment_Attribute_Definition_Clause`, `Production_External_Tag_Attribute_Definition_Clause`, and `Production_Storage_Attribute_Definition_Clause` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Attribute_Definition_Detail_Pass777` registered in the syntax semantics AUnit suite.
- Treat these markers as structural parser metadata only; do not claim compiler-grade attribute legality checking, static-expression validation, stream profile conformance, or representation layout validation.


### Pass778 protected body operation-depth guard

- Confirm `Production_Protected_Procedure_Body`, `Production_Protected_Function_Body`, `Production_Protected_Entry_Body`, and `Production_Protected_Entry_Barrier_Condition` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Protected_Body_Operation_Depth_Pass778` registered in the syntax semantics AUnit suite.
- Treat these markers as structural parser metadata only; do not claim compiler-grade protected-operation legality checking, barrier semantics, body/spec conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass779 parallel loop grammar-depth guard

- Confirm `parallel` remains tokenized as an Ada keyword in `Editor.Ada_Token_Cursor`.
- Confirm `Production_Parallel_Loop_Statement`, `Production_Parallel_Loop_Chunk_Specification`, and `Production_Parallel_Loop_Iteration_Scheme` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Parallel_Loop_Depth_Pass779` registered in the syntax semantics AUnit suite.
- Treat these markers as structural parser metadata only; do not claim compiler-grade parallel execution legality, chunk staticness, data-race analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass780 asynchronous select grammar-depth guard

- Confirm `Production_Asynchronous_Select_Statement`, `Production_Asynchronous_Select_Triggering_Alternative`, `Production_Asynchronous_Select_Delay_Trigger`, and `Production_Asynchronous_Select_Abortable_Part` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Asynchronous_Select_Depth_Pass780` registered in the syntax semantics AUnit suite.
- Treat these markers as structural parser metadata only; do not claim compiler-grade tasking legality checking, triggering-statement legality checking, abort completion semantics, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass781 if-expression recovery-depth guard

- Confirm `Production_If_Expression_Missing_Else_Recovery_Boundary` remains present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_If_Expression_Else_Recovery_Pass781` registered in the syntax semantics AUnit suite.
- Treat this marker as bounded structural parser recovery only; do not claim compiler-grade conditional-expression legality checking, expected-type analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass782 case-expression recovery-depth guard

- Confirm `Production_Case_Expression_Missing_Arrow_Recovery_Boundary` and `Production_Case_Expression_Missing_Alternative_Recovery_Boundary` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Case_Expression_Recovery_Pass782` registered in the syntax semantics AUnit suite.
- Treat these markers as bounded structural parser recovery only; do not claim compiler-grade case-expression legality checking, choice coverage, expected-type analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass783 quantified-expression recovery-depth guard

- Confirm `Production_Quantified_Missing_Domain_Recovery_Boundary` and `Production_Quantified_Missing_Arrow_Recovery_Boundary` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Quantified_Recovery_Pass783` registered in the syntax semantics AUnit suite.
- Treat these markers as bounded structural parser recovery only; do not claim compiler-grade quantified-expression legality checking, iterator legality checking, expected-type analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass784 formal package hostile recovery guard

- Confirm `Production_Formal_Package_Missing_Generic_Name`, `Production_Formal_Package_Missing_Generic_Recovery_Boundary`, and `Production_Formal_Package_Actual_Missing_Arrow_Recovery_Boundary` remain present in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Formal_Package_Hostile_Recovery_Pass784` registered in the syntax semantics AUnit suite.
- Treat these markers as bounded structural parser recovery only; do not claim compiler-grade generic contract conformance, formal package matching, association legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass785 record representation recovery guard

- Keep `Test_Language_Model_Token_Cursor_Record_Representation_Recovery_Pass785` registered in the syntax semantics AUnit suite.
- Keep `Production_Representation_Component_Missing_At_Recovery_Boundary`, `Production_Representation_Component_Missing_Range_Recovery_Boundary`, and `Production_Record_Representation_Missing_End_Record_Recovery_Boundary` available to the token cursor.
- Do not reinterpret these recovery markers as compiler-grade representation legality, layout validation, target resolution, static-expression validation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass786 exception handler missing-arrow recovery guard

- Keep `Production_Exception_Handler_Missing_Arrow_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Arrow_Pass786` registered in the syntax semantics AUnit suite.
- Treat this marker as bounded structural parser recovery only; do not claim compiler-grade exception-handler legality checking, exception choice resolution, duplicate-choice analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass787 select guard missing-arrow recovery guard

- Keep `Production_Select_Guard_Missing_Arrow_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Select_Guard_Missing_Arrow_Pass787` registered in the syntax semantics AUnit suite.
- Treat this marker as bounded structural parser recovery only; do not claim compiler-grade tasking legality checking, guard-expression legality checking, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass788 accept statement end/recovery guard

- Keep `Production_Accept_End_Keyword`, `Production_Accept_End_Name`, `Production_Accept_Terminator`, and `Production_Accept_Missing_End_Recovery_Boundary` available in `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Accept_End_Recovery_Pass788` registered in the syntax semantics AUnit suite.
- Treat these markers as bounded structural parser recovery only; do not claim compiler-grade tasking legality checking, accept-body conformance checking, entry-call matching, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Phase 579 pass789: verify timed/conditional entry-call select metadata remains token-cursor-owned and covered by `Test_Language_Model_Token_Cursor_Timed_Conditional_Entry_Call_Pass789`; no tasking legality, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- Phase 579 pass790: verify requeue terminator and missing-`abort` recovery metadata remains token-cursor-owned and covered by `Test_Language_Model_Token_Cursor_Requeue_Recovery_Pass790`; no tasking legality, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- Phase 579 pass791: verify terminate-alternative terminator and missing-terminator recovery metadata remains token-cursor-owned and covered by `Test_Language_Model_Token_Cursor_Terminate_Alternative_Recovery_Pass791`; no tasking legality, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- Phase 579 pass792: verify abort statement terminator and missing-terminator recovery metadata remains token-cursor-owned and covered by `Test_Language_Model_Token_Cursor_Abort_Terminator_Recovery_Pass792`; no tasking legality, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- Phase 579 pass793: verify delay statement terminator and missing-terminator recovery metadata remains token-cursor-owned and covered by `Test_Language_Model_Token_Cursor_Delay_Terminator_Recovery_Pass793`; no delay legality, real-time semantics, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass794 return-statement terminator/recovery guard updated: `Production_Return_Terminator` and `Production_Extended_Return_Missing_End_Recovery_Boundary` are covered by AUnit and validation guards.

- [x] Pass795 raise-statement terminator/recovery guard updated: `Production_Raise_Terminator`, `Production_Raise_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Raise_Terminator_Recovery_Pass795` are covered by validation guards. This remains bounded parser metadata only; no exception legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.


- [x] Pass796 exit-statement terminator/recovery guard updated: `Production_Exit_Terminator`, `Production_Exit_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Exit_Terminator_Recovery_Pass796` are covered by validation guards. This remains bounded parser metadata only; no loop-name resolution, condition legality checking, control-flow legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.


- [x] Pass797 goto-statement terminator/recovery guard updated: `Production_Goto_Terminator`, `Production_Goto_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Goto_Terminator_Recovery_Pass797` are covered by validation guards. This remains bounded parser metadata only; no label resolution, control-flow legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass798 null-statement terminator/recovery guard updated: `Production_Null_Statement_Terminator`, `Production_Null_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Null_Terminator_Recovery_Pass798` are covered by validation guards. This remains bounded parser metadata only; no statement legality checking, reachability analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass799 assignment-statement terminator/recovery guard updated: `Production_Assignment_Terminator`, `Production_Assignment_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Assignment_Terminator_Recovery_Pass799` are covered by validation guards. This remains bounded parser metadata only; no assignment legality checking, type compatibility checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass800 call-statement terminator/recovery guard updated: `Production_Call_Terminator`, `Production_Call_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Call_Terminator_Recovery_Pass800` are covered by validation guards. This remains bounded parser metadata only; no callable resolution, parameter profile matching, entry-call legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass801 compound-statement end terminator/recovery guard updated: `Production_If_End_Terminator`, `Production_If_Missing_End_Terminator_Recovery_Boundary`, `Production_Loop_End_Terminator`, `Production_Loop_Missing_End_Terminator_Recovery_Boundary`, `Production_Block_End_Terminator`, `Production_Block_Missing_End_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery_Pass801` are covered by validation guards. This remains bounded parser metadata only; no compound-statement legality checking, end-name matching, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.
- [x] Pass802 case statement end terminator/recovery guard updated: `Production_Case_Statement_End_Keyword`, `Production_Case_End_Terminator`, `Production_Case_Missing_End_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery_Pass802` are covered by validation guards. This remains bounded parser metadata only; no case statement legality checking, choice coverage checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass803 case alternative missing-arrow recovery guard updated: `Production_Case_Alternative_Missing_Arrow_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Case_Alternative_Missing_Arrow_Pass803` are covered by validation guards. This remains bounded parser metadata only; no case statement legality checking, choice coverage checking, duplicate-choice analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass804 if/elsif missing-then recovery guard updated: `Production_If_Statement_Missing_Then_Recovery_Boundary`, `Production_Elsif_Statement_Missing_Then_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_If_Missing_Then_Recovery_Pass804` are covered by validation guards. This remains bounded parser metadata only; no condition legality checking, expected Boolean type analysis, control-flow analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass805 loop missing-loop recovery guard updated: `Production_For_Loop_Missing_Loop_Recovery_Boundary`, `Production_Iterator_Loop_Missing_Loop_Recovery_Boundary`, `Production_While_Loop_Missing_Loop_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Loop_Missing_Loop_Recovery_Pass805` are covered by validation guards. This remains bounded parser metadata only; no loop legality checking, iterator legality checking, condition legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass806 package/subprogram body end terminator recovery guard updated: `Production_Package_Body_End_Keyword`, `Production_Package_Body_End_Name`, `Production_Package_Body_End_Terminator`, `Production_Package_Body_Missing_End_Terminator_Recovery_Boundary`, `Production_Subprogram_Body_End_Name`, `Production_Subprogram_Body_End_Terminator`, `Production_Subprogram_Body_Missing_End_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Body_End_Terminator_Recovery_Pass806` are covered by validation guards. This remains bounded parser metadata only; no body/spec conformance checking, end-name matching, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass807 task/protected body end terminator recovery guard updated: `Production_Task_Body_End_Name`, `Production_Task_Body_End_Terminator`, `Production_Task_Body_Missing_End_Terminator_Recovery_Boundary`, `Production_Protected_Body_End_Keyword`, `Production_Protected_Body_End_Name`, `Production_Protected_Body_End_Terminator`, `Production_Protected_Body_Missing_End_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Concurrent_Body_End_Terminator_Recovery_Pass807` are covered by validation guards. This remains bounded parser metadata only; no tasking legality checking, protected-operation conformance checking, body/spec conformance checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass808 entry declaration terminator recovery guard updated: `Production_Entry_Terminator`, `Production_Entry_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Entry_Declaration_Terminator_Recovery_Pass808` are covered by validation guards. This remains bounded parser metadata only; no entry-family legality checking, protected/task conformance checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass809 entry body end/recovery guard updated: `Production_Entry_Body_Begin_Keyword`, `Production_Entry_Body_End_Keyword`, `Production_Entry_Body_End_Name`, `Production_Entry_Body_End_Terminator`, `Production_Entry_Body_Missing_End_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Entry_Body_End_Recovery_Pass809` are covered by validation guards. This remains bounded parser metadata only; no tasking legality checking, entry/body conformance checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- [x] Pass810 subprogram declaration terminator recovery guard updated: `Production_Subprogram_Declaration_Terminator`, `Production_Subprogram_Declaration_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Subprogram_Declaration_Terminator_Pass810` are covered by validation guards. This remains bounded parser metadata only; no body/spec conformance checking, callable resolution, aspect legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation is introduced.

- Pass811: Object declaration terminator recovery depth is guarded by `Production_Object_Declaration_Terminator`, `Production_Object_Declaration_Missing_Terminator_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Object_Declaration_Terminator_Pass811`.

### Pass812 - Type/subtype declaration terminator recovery guard

- [x] Token cursor exposes `Production_Type_Declaration_Terminator` and `Production_Type_Declaration_Missing_Terminator_Recovery_Boundary`.
- [x] Token cursor exposes `Production_Subtype_Declaration_Terminator` and `Production_Subtype_Declaration_Missing_Terminator_Recovery_Boundary`.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Type_Subtype_Declaration_Terminator_Pass812`.
- [x] Validation guard checks the new productions and regression marker.
- [x] Scope remains bounded structural parsing; no compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass813 - Package declaration end terminator recovery guard

- [x] Token cursor exposes `Production_Package_Declaration_End_Keyword`, `Production_Package_Declaration_End_Name`, and `Production_Package_Declaration_End_Terminator`.
- [x] Token cursor exposes `Production_Package_Declaration_Missing_End_Terminator_Recovery_Boundary`.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Package_Declaration_End_Terminator_Pass813`.
- [x] Validation guard checks the new productions and regression marker.
- [x] Scope remains bounded structural parsing; no compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass814 - Formal package actual-part delimiter guard

- [x] Keep `Production_Formal_Package_Actual_Part_Open_Delimiter`, `Production_Formal_Package_Actual_Part_Close_Delimiter`, `Production_Formal_Package_Actual_Association_Separator`, and `Production_Formal_Package_Actual_Part_Missing_Close_Recovery_Boundary` in the token-cursor grammar.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Formal_Package_Actual_Delimiters_Pass814`.
- [x] Treat this as bounded structural metadata only; do not claim compiler-grade generic contract conformance, formal package matching, association legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass815 - Exception declaration terminator guard

- [x] Keep `Production_Exception_Declaration_Terminator` and `Production_Exception_Declaration_Missing_Terminator_Recovery_Boundary` in the token-cursor grammar.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Exception_Declaration_Terminator_Pass815`.
- [x] Treat this as bounded structural metadata only; do not claim compiler-grade exception renaming legality, aspect legality checking, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass816 - Number declaration terminator guard

- [x] Keep `Production_Number_Declaration_Terminator` and `Production_Number_Declaration_Missing_Terminator_Recovery_Boundary` in the token-cursor grammar.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Number_Declaration_Terminator_Pass816`.
- [x] Number declaration terminator recovery remains parser-owned, bounded, and non-semantic; it must not perform static-expression evaluation, universal numeric resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Pass817 - Generic formal declaration terminator recovery depth

- [x] Keep `Production_Generic_Formal_Declaration_Terminator` in the token-cursor grammar.
- [x] Keep `Production_Generic_Formal_Declaration_Missing_Terminator_Recovery_Boundary` in the token-cursor grammar.
- [x] Keep `Test_Language_Model_Token_Cursor_Generic_Formal_Declaration_Terminator_Pass817` registered in syntax/semantic regression coverage.
- [x] Preserve `Production_Generic_Formal_Aspect_Specification` while recording formal-declaration-specific terminator metadata.
- [x] Treat the pass as structural grammar metadata only, not compiler-grade generic contract conformance, formal declaration legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass818 - Enumeration representation delimiter and recovery depth

- [x] Keep `Production_Enumeration_Representation_List_Open_Delimiter` and `Production_Enumeration_Representation_List_Close_Delimiter` in the token-cursor grammar.
- [x] Keep `Production_Enumeration_Representation_Association_Separator` in the token-cursor grammar.
- [x] Keep `Production_Enumeration_Representation_Missing_Close_Recovery_Boundary` in the token-cursor grammar.
- [x] Keep `Test_Language_Model_Token_Cursor_Enumeration_Representation_Delimiters_Pass818` registered in syntax/semantic regression coverage.
- [x] Treat these productions as structural parser metadata only, not compiler-grade representation legality checking.

### Pass819 - Record representation delimiter and recovery depth

- [x] Keep `Production_Record_Representation_List_Open_Delimiter` and `Production_Record_Representation_List_Close_Delimiter` in the token-cursor grammar.
- [x] Keep `Production_Record_Representation_Component_Separator` for component/mod clause separator metadata.
- [x] Keep `Production_Record_Representation_Missing_Close_Recovery_Boundary` for bounded missing-close recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Record_Representation_Delimiters_Pass819`.
- [x] Preserve parser-owned analysis only: no compiler invocation, LSP integration, render-side parsing, dirty-state mutation, or save/reload side effects.


## Pass820 pragma argument delimiter/recovery guard

- [x] Keep `Production_Pragma_Argument_List_Open_Delimiter` and `Production_Pragma_Argument_List_Close_Delimiter` in the token-cursor grammar.
- [x] Keep `Production_Pragma_Argument_Association_Separator` for comma-separated pragma argument associations.
- [x] Keep `Production_Pragma_Argument_List_Missing_Close_Recovery_Boundary` for in-progress pragma argument lists ending at a semicolon.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Pragma_Argument_Delimiters_Pass820`.
- [x] Keep validation markers in `tools/phase579_language_validation_check.adb`.
- [x] Keep the scope precise: this is structural pragma argument-list metadata, not compiler-grade pragma legality checking, aspect/pragma semantic equivalence, implementation-defined pragma validation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass821 call and entry-call actual delimiter/recovery guard

- [x] Token cursor exposes call actual-list open/close delimiter productions.
- [x] Token cursor exposes call actual association separator and missing-close recovery productions.
- [x] Token cursor exposes matching entry-call actual-list delimiter/separator/recovery productions.
- [x] Bounded recovery preserves the following statement after malformed call actual lists.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Call_Actual_Delimiters_Pass821`.
- [x] This pass is structural grammar coverage only, not overload resolution or callable legality checking.

## Pass822 generic instantiation actual delimiter/recovery guard

- [x] Keep `Production_Generic_Actual_Part_Open_Delimiter` and `Production_Generic_Actual_Part_Close_Delimiter` in token-cursor grammar metadata.
- [x] Keep `Production_Generic_Actual_Association_Separator` for top-level separators in generic instantiation actual parts.
- [x] Keep `Production_Generic_Actual_Part_Missing_Close_Recovery_Boundary` for bounded malformed/in-progress actual parts.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters_Pass822`.
- [x] Preserve editor invariants: no compiler invocation, no LSP, no render-side parsing, no dirty-state mutation, and no broad semantic legality claims.

## Pass823 protected operation body end-name/terminator guard

- [x] Keep `Production_Protected_Body_Operation_End_Name` in token-cursor grammar metadata.
- [x] Keep `Production_Protected_Body_Operation_End_Terminator` in token-cursor grammar metadata.
- [x] Keep `Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary` for bounded malformed/in-progress protected operation bodies.
- [x] Keep nested statement closes from being classified as protected operation body ends.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail_Pass823`.

## Pass824 exception handler choice-list recovery guard

- [x] Keep exception handler choice-list recovery structural and bounded.
- [x] Retain separator metadata before missing-choice recovery.
- [x] Do not consume the following handler arrow or surrounding handler boundary during recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice_Pass824`.
- [x] Do not add compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass825 package declarative item recovery guard

- [x] Keep `Production_Package_Visible_Declarative_Item_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep `Production_Package_Private_Declarative_Item_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep package visible/private declarative-item recovery bounded and section-specific.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Package_Declarative_Item_Recovery_Pass825`.
- [x] Preserve editor invariants: no compiler invocation, no LSP, no render-side parsing, no dirty-state mutation, and no broad semantic legality claims.

## Pass826 parameter profile delimiter/recovery guard

- [x] Keep token-cursor productions for parameter-profile open/close delimiters, separators, and missing-close recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters_Pass826`.
- [x] Keep validation markers for the parser paths and production names.
- [x] Do not treat this as parameter-mode legality checking, subtype conformance, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass827 discriminant part delimiter/recovery guard

- [x] Keep token-cursor productions for discriminant-part open/close delimiters, discriminant-specification separators, and missing-close recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827`.
- [x] Keep validation guard markers in `tools/phase579_language_validation_check.adb`.
- [x] Preserve unknown discriminant part `(<>)` handling while adding delimiter metadata.
- [x] Do not promote this to compiler-grade discriminant legality, discriminant conformance, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass828 release guard - constraint delimiters and recovery

- Token-cursor production list includes index-constraint delimiter/separator and
  missing-close recovery productions.
- Token-cursor production list includes discriminant-constraint delimiter,
  association-separator, and missing-close recovery productions.
- Parser body records the new metadata without consuming the surrounding
  declaration terminator when a constraint is missing `)`.
- AUnit regression
  `Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828` remains
  registered.
- Scope remains structural grammar coverage only, not compiler-grade subtype
  constraint legality, static evaluation, subtype conformance, LSP integration,
  render-side parsing, or dirty-state mutation.

## Pass831 parenthesized-expression delimiter/recovery guard

- [x] Keep token-cursor productions for parenthesized-expression open/close delimiters and missing-close recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831`.
- [x] Keep validation guard markers in `tools/phase579_language_validation_check.adb`.
- [x] Preserve bounded recovery so malformed parenthesized expressions do not consume following declaration terminators.
- [x] Do not promote this to compiler-grade expression legality checking, aggregate-vs-parenthesized semantic disambiguation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass832 discrete choice-list separator/recovery guard

- [x] Keep token-cursor productions for discrete-choice separators and missing-choice recovery.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832`.
- [x] Preserve bounded recovery so malformed choice lists do not consume enclosing `=>` arrows or following statements.
- [x] Do not promote this to compiler-grade discrete-choice legality checking, duplicate-choice validation, static range evaluation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass833 enumeration type delimiter/recovery guard

- [x] Keep enumeration type delimiter/separator/missing-close productions in the token cursor.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters_Pass833`.
- [x] Treat the pass as structural grammar coverage only, not compiler-grade enumeration legality checking.

## Pass835 range constraint bound/separator recovery guard

- [x] Keep `Production_Range_Constraint_Range_Separator` in token-cursor grammar metadata.
- [x] Keep range-specific missing lower/upper bound recovery productions in token-cursor grammar metadata.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Range_Constraint_Bounds_Pass835`.
- [x] Preserve bounded recovery so malformed range constraints do not consume following declarations.
- [x] Do not promote this to compiler-grade static range validation, subtype legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass836 attribute argument delimiter/recovery guard

- [x] Keep attribute argument-list delimiter/separator/missing-close productions in the token cursor.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836`.
- [x] Preserve bounded recovery so malformed attribute argument parts do not consume following declarations.
- [x] Preserve Ada 2022 reduction attribute reducer and initial-value metadata.
- [x] Do not promote this to compiler-grade attribute legality checking, reduction profile conformance, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

## Pass837 membership choice-list separator/recovery guard

- [x] Keep `Production_Membership_Choice_Separator` in token-cursor grammar metadata.
- [x] Keep `Production_Membership_Choice_Missing_Choice_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837`.
- [x] Preserve bounded recovery so malformed membership choice lists do not consume following declaration terminators.
- [x] Do not promote this to compiler-grade membership legality checking, duplicate-choice validation, static range evaluation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Pass838 case-expression alternative separator/recovery guard

- [x] Keep token-cursor production `Production_Case_Expression_Alternative_Separator`.
- [x] Keep bounded recovery via `Production_Case_Expression_Missing_Alternative_Recovery_Boundary`.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838`.
- [x] Do not convert this structural metadata into compiler-grade legality checking.

- [x] Pass839: declare-expression begin keyword and missing-begin recovery
      metadata are documented and covered by
      `Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery_Pass839`.
      This remains bounded structural parsing only and does not introduce
      compiler invocation, LSP integration, render-side parsing, dirty-state
      mutation, or compiler-grade legality checking.

## Pass840 quantified-expression missing-quantifier recovery guard

- [x] Keep `Production_Quantified_Missing_Quantifier_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier_Pass840`.
- [x] Preserve bounded recovery so malformed quantified expressions still leave following declarations visible.
- [x] Do not promote this to compiler-grade quantified-expression legality checking, loop-scheme legality checking, predicate type checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Pass841 if-expression missing-then recovery guard

- [x] Keep `Production_If_Expression_Missing_Then_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep `Production_Elsif_Expression_Missing_Then_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep AUnit coverage in `Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery_Pass841`.
- [x] Preserve bounded recovery so malformed conditional expressions still leave following declarations visible.
- [x] Do not promote this to compiler-grade conditional-expression legality checking, branch type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


## Pass842 release guard

- [x] Keep `Production_Selected_Name_Missing_Selector_Recovery_Boundary` in token-cursor grammar metadata.
- [x] Keep AUnit coverage for dangling selected-name dots and following-declaration recovery.
- [x] Do not reinterpret selected-name recovery as compiler-grade name resolution or selector legality checking.

- [ ] Pass843: delta aggregate keyword/separator/missing-association recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- [ ] Pass844: extension aggregate keyword/separator/missing-association recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- [ ] Pass845: null-record aggregate keyword and missing-record recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- [ ] Pass847: iterated component association missing-domain recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- [ ] Pass846: iterated component association arrow and missing-arrow recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- [ ] Pass848: loop iteration missing-domain recovery metadata is covered by token-cursor regression tests and remains bounded, snapshot-owned, and render-side-parse-free.

- Pass849 guard: iterator-filter missing-condition recovery remains token-cursor-owned for loop filters, quantified-expression filters, and aggregate iterated component filters. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass850 guard: exit-when missing-condition recovery remains token-cursor-owned through `Production_Exit_When_Missing_Condition_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Exit_When_Condition_Recovery_Pass850`. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


- Pass851 guard: delay statement missing-expression recovery remains token-cursor-owned through `Production_Delay_Until_Missing_Expression_Recovery_Boundary`, `Production_Delay_Relative_Missing_Expression_Recovery_Boundary`, and `Test_Language_Model_Token_Cursor_Delay_Expression_Recovery_Pass851`. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass852 guard: requeue statement missing-terminator recovery remains token-cursor-owned through `Production_Requeue_Missing_Terminator_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery_Pass852`. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


- Pass853 guard: accept statement missing-terminator recovery remains token-cursor-owned through `Production_Accept_Missing_Terminator_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853`. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass854 guard: select guard missing-condition recovery remains token-cursor-owned through `Production_Select_Guard_Missing_Condition_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Select_Guard_Condition_Recovery_Pass854`. It must not introduce compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass855 guard: abort statement missing-target recovery remains token-cursor-owned through `Production_Abort_Missing_Target_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Abort_Target_Recovery_Pass855`. It must not introduce compiler invocation, LSP integration, render-side parsing, dirty-state mutation, task-name resolution, or compiler-grade tasking legality checking.

- Pass856 guard: return statement missing-terminator recovery remains token-cursor-owned through `Production_Return_Missing_Terminator_Recovery_Boundary` and `Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass856`. It must not introduce compiler invocation, LSP integration, render-side parsing, dirty-state mutation, return type conformance validation, or compiler-grade return legality checking.

- Pass857: verify raise-expression `with` message recovery remains parser-owned,
  bounded, snapshot-owned, and does not introduce compiler invocation, LSP,
  render-side parsing, or dirty-state mutation.

- Pass858: verify raise-statement `with` message recovery remains parser-owned,
  bounded, snapshot-owned, and does not introduce compiler invocation, LSP,
  render-side parsing, dirty-state mutation, exception visibility analysis, or
  compiler-grade raise-statement legality checking.

- Pass859: verify malformed labels with missing `>>` record
  `Production_Label_Missing_Close_Recovery_Boundary`, stop recovery at the line
  boundary, and leave following statements visible. This remains structural
  parser metadata only and must not add compiler invocation, LSP integration,
  render-side parsing, or dirty-state mutation.

- Pass860: verify malformed assignments with missing right-hand expressions
  record `Production_Assignment_Missing_Expression_Recovery_Boundary`, preserve
  well-formed assignment expression metadata, and leave following statements
  visible. This remains structural parser metadata only and must not add
  compiler invocation, LSP integration, render-side parsing, dirty-state
  mutation, assignment legality checking, expression type checking, or overload
  resolution.

- Pass861: verify malformed `goto` statements with missing label targets record
  `Production_Goto_Missing_Target_Recovery_Boundary`, preserve well-formed goto
  target and terminator metadata, and leave following labels/statements visible.
  This remains structural parser metadata only and must not add compiler
  invocation, LSP integration, render-side parsing, dirty-state mutation, label
  resolution, or compiler-grade goto legality checking.

- Pass862: verify raise statements with a message introducer but no exception name record
  `Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary`; verify the parser does
  not tag `with` as `Production_Raise_Exception_Name` in that malformed shape and that following
  statements remain visible.

- [x] Pass 869: If statement branch recovery metadata is covered by AUnit regression and validation guard entries; no render-side parsing, LSP integration, compiler invocation, or dirty-state mutation was introduced.

- Pass870: confirm loop body missing-statement recovery metadata is present in
  the parser/token-cursor validation guard and AUnit regression list.

- Pass871: confirm block statement-sequence missing-statement recovery metadata
  is present in the parser/token-cursor validation guard and AUnit regression
  list, and that the feature remains structural parser metadata only with no
  compiler invocation, LSP integration, render-side parsing, or dirty-state
  mutation.

- Pass876: confirm enumeration representation empty-list, trailing-separator, and missing-value recovery metadata is present in token-cursor validation guard entries and AUnit regression coverage. This remains structural grammar metadata only and must not add compiler invocation, LSP integration, render-side parsing, dirty-state mutation, or compiler-grade representation legality checking.

- Pass877: verify that subprogram declarations and subprogram bodies with
  `with Pre =>`, `Post =>`, `Global =>`, and `Depends =>` retain
  subprogram-specific aspect placement metadata and existing contract aspect
  association metadata.  This is structural grammar coverage, not contract
  legality checking or compiler-grade validation.

- Pass878: verify that package declaration/body declarative-item recovery records
  nested item recovery plus `private`, `begin`, and `end` boundary metadata while
  preserving visible/private/body declarative-item productions and generic
  package recovery metadata.

- Pass879: verify that anonymous access-to-subprogram recovery records specific
  boundaries for dangling `access protected`, missing access-function `return`,
  and missing result subtype after `return`, while preserving existing
  access-definition/profile metadata and following declaration visibility. This
  remains structural grammar coverage, not callable-profile legality checking,
  result subtype legality checking, overload resolution, compiler invocation,
  LSP integration, render-side parsing, or dirty-state mutation.

- Pass880: verify that conditional-expression recovery records specific
  boundaries for missing conditions, missing then-dependent expressions, and
  missing else-dependent expressions while preserving conditional-expression
  metadata and following declaration visibility. This remains structural grammar
  coverage, not expression type checking, Boolean legality checking, overload
  resolution, compiler invocation, LSP integration, render-side parsing, or
  dirty-state mutation.

- Pass881: verify that selected names with operator-symbol and character-literal
  selectors remain visible through generic selected-selector metadata, and that
  selected literal subtype-mark metadata is retained in qualified-expression and
  allocator contexts. This remains structural grammar coverage, not subtype
  legality checking, operator legality checking, overload resolution, compiler
  invocation, LSP integration, render-side parsing, or dirty-state mutation.

- Pass882: verify that select alternatives with empty/malformed statement
  sequences before `or`, `else`, `then abort`, `terminate`, and `end select`
  retain select-specific recovery metadata and continue exposing following
  declarations without render-side parsing or dirty-state mutation.

### Pass883 accept-body statement recovery release guard

- Keep `Production_Accept_Body_Missing_Statement_Recovery_Boundary` and
  `Production_Accept_Body_End_Statement_Recovery_Boundary` available in
  `Editor.Ada_Token_Cursor`.
- Keep `Test_Language_Model_Token_Cursor_Accept_Body_Statement_Recovery_Pass883`
  registered in the syntax/semantics AUnit suite.
- Preserve accept statement-sequence, accept end, malformed terminator, select
  alternative, and following-declaration metadata after accept-body recovery.
- Do not add compiler invocation, LSP integration, render-side parsing,
  background whole-project scanning, or dirty-state mutation to satisfy this
  recovery guard.

### Pass884 generic formal incomplete type release guard

- Keep `Production_Formal_Incomplete_Type_Declaration`,
  `Production_Formal_Incomplete_Tagged_Type_Definition`, and
  `Production_Formal_Incomplete_Type_Recovery_Boundary` available in the token
  cursor production enum.
- Keep `Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type_Pass884`
  in the AUnit syntax/semantics suite.
- Preserve bounded recovery: `type T;`, `type T (<>);`, and
  `type T is tagged;` must remain visible as formal incomplete type grammar;
  malformed `type T is;` must not consume the following formal item or package
  declaration.

- [ ] Pass885 pragma recovery guard: confirm missing pragma identifiers, empty
      argument lists, trailing argument separators, missing argument
      expressions, and missing terminators remain parser-owned structural
      recovery metadata only.


### Pass886 release guard

- [ ] Keep `Production_Attribute_Definition_Missing_Use_Recovery_Boundary`,
      `Production_Attribute_Definition_Missing_Value_Recovery_Boundary`, and
      `Production_Address_Clause_Missing_Value_Recovery_Boundary` wired through
      token-cursor grammar metadata.
- [ ] Keep `Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery_Pass886`
      in the AUnit suite.
- [ ] Preserve the invariant that malformed representation clauses do not cause
      rendering-side parsing, background whole-project scanning, compiler
      invocation, or dirty-state mutation.

### Pass887 — broader aspect placement regression guard

- [x] Keep package, package body, task, task body, protected, protected body,
      private type, and generic declaration aspect placement metadata covered by
      `Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth_Pass887`.
- [x] Treat the new productions as parser-owned structural metadata only; do
      not use them as compiler-grade aspect legality or representation legality
      results.

### Pass888 — case-expression dependent-expression recovery guard

- [x] Keep `Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary`
      available in `Editor.Ada_Token_Cursor`.
- [x] Keep `Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery_Pass888`
      registered in the syntax/semantics AUnit suite.
- [x] Preserve case-expression, arrow, well-formed dependent-expression, generic
      recovery, and following-declaration metadata after malformed alternatives.
- [x] Do not add expression type checking, compiler invocation, LSP integration,
      render-side parsing, background whole-project scanning, or dirty-state
      mutation for this recovery path.

### Pass889 — name/attribute refinement release guard

- [x] Keep `Production_Attribute_Selected_Prefix` and
      `Production_Attribute_Complex_Prefix` available in `Editor.Ada_Token_Cursor`.
- [x] Keep `Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark`
      and `Production_Allocator_Incomplete_Selected_Subtype_Mark` available in
      `Editor.Ada_Token_Cursor`.
- [x] Keep `Test_Language_Model_Token_Cursor_Name_Attribute_Refinement_Pass889`
      registered in the syntax/semantics AUnit suite.
- [x] Preserve generic selected-name missing-selector recovery and following
      declaration visibility after context-specific name recovery.
- [x] Do not add attribute legality checking, subtype legality checking,
      compiler invocation, LSP integration, render-side parsing, background
      whole-project scanning, or dirty-state mutation for this parser metadata.

### Pass890 — task/protected body declarative recovery release guard

- [x] Keep parsing deterministic and snapshot-owned.
- [x] Keep task/protected body recovery independent of rendering and dirty state.
- [x] Keep malformed declarative items before `begin` from consuming following body statements.
- [x] Preserve enclosing body and package end metadata after recovery.
- [x] Keep `Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery_Pass890` in the language-model regression suite.

### Pass891 — recovered semantic metadata suppression guard

- [x] Keep `Test_Syntax_Semantics_Recovered_Metadata_Suppressed_Pass891`
      registered in the syntax/semantics AUnit suite.
- [x] Keep unresolved recovered partial names from seeding the bounded semantic
      map as package/type/value symbols.
- [x] Preserve concrete target-symbol colouring for resolved bindings.
- [x] Do not add compiler invocation, LSP integration, render-side parsing,
      background whole-project scanning, or dirty-state mutation for this
      semantic-colouring recovery guard.

### Pass892 — reduction attribute argument recovery guard

- [x] Keep `Production_Reduction_Missing_Reducer_Recovery_Boundary`,
      `Production_Reduction_Missing_Initial_Value_Recovery_Boundary`, and
      `Production_Reduction_Trailing_Separator_Recovery_Boundary` available in
      `Editor.Ada_Token_Cursor`.
- [x] Keep `Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery_Pass892`
      registered in the syntax/semantics AUnit suite.
- [x] Preserve reduction-expression, parallel-reduction, map-reduction,
      attribute-argument delimiter, missing-close, generic recovery, and
      following-declaration metadata after malformed reduction arguments.
- [x] Do not add callable conformance checking, expression type checking,
      compiler invocation, LSP integration, render-side parsing, background
      whole-project scanning, or dirty-state mutation for this parser metadata.

### Pass893 — quantified-expression predicate recovery guard

- [x] Keep `Production_Quantified_Missing_Predicate_Recovery_Boundary`
      available in `Editor.Ada_Token_Cursor`.
- [x] Keep `Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery_Pass893`
      registered in the syntax/semantics AUnit suite.
- [x] Preserve quantified-expression, quantified-arrow, generic recovery, and
      following-declaration metadata after malformed quantified predicates.
- [x] Do not add Boolean predicate legality checking, iterator legality
      checking, compiler invocation, LSP integration, render-side parsing,
      background whole-project scanning, or dirty-state mutation for this parser
      metadata.

### Pass894 — declare-expression missing-body recovery guard

- [x] Keep `Production_Declare_Expression_Missing_Body_Recovery_Boundary`
      available in `Editor.Ada_Token_Cursor`.
- [x] Keep `Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery_Pass894`
      registered in the syntax/semantics AUnit suite.
- [x] Preserve declare-expression, begin-keyword, generic recovery, and
      following-declaration metadata after malformed declare-expression bodies.
- [x] Do not add declare-expression legality checking, expression type checking,
      compiler invocation, LSP integration, render-side parsing, background
      whole-project scanning, or dirty-state mutation for this parser metadata.

### Pass895 — iterated component association expression recovery

- [x] Keep `Production_Iterated_Component_Missing_Expression_Recovery_Boundary`
      available for malformed aggregate iterated component associations after
      `=>`.
- [x] Keep `Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery_Pass895`
      registered with the syntax/semantics regression suite.
- [x] Preserve generic recovery metadata and following declaration visibility.
- [x] Do not reinterpret this structural recovery as aggregate legality,
      iterator legality, overload resolution, compiler invocation, LSP
      integration, render-side parsing, background whole-project scanning, or
      dirty-state mutation.

### Pass896 — generic actual association recovery

- [x] Keep `Production_Generic_Actual_Empty_List_Recovery_Boundary`,
      `Production_Generic_Actual_Missing_Actual_Recovery_Boundary`, and
      `Production_Generic_Actual_Trailing_Separator_Recovery_Boundary` stable
      for malformed generic actual part metadata.
- [x] Keep `Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery_Pass896`
      registered with the parser regression suite.
- [x] Do not reinterpret recovered actual-list metadata as compiler-grade
      generic contract legality checking.

### Pass897 — renaming target recovery

- [x] Preserve renaming declaration metadata when `renames` has no following
      renamed entity.
- [x] Preserve renaming aspect metadata for aspect-only recovery after
      `renames`.
- [x] Keep valid following renamed package targets visible after malformed
      renaming declarations.
- [x] Keep `Test_Language_Model_Token_Cursor_Renaming_Target_Recovery_Pass897`
      in the language validation guard set.
- [x] Confirm this is structural parser recovery only, not renamed-entity
      legality checking, visibility checking, compiler invocation, LSP
      integration, render-side parsing, or dirty-state mutation.

### Pass898 — entry-body statement-sequence recovery

- [x] Keep `Production_Entry_Body_Statement_Sequence` and
      `Production_Entry_Body_Missing_Statement_Recovery_Boundary` parser-owned.
- [x] Keep `Test_Language_Model_Token_Cursor_Entry_Body_Statement_Recovery_Pass898`
      in the language-model regression suite.
- [x] Verify entry-body recovery preserves begin/end metadata, generic recovery
      metadata, and valid non-empty entry body statement-sequence metadata.
- [x] Do not reinterpret this as tasking legality checking, entry barrier
      legality checking, overload resolution, compiler invocation, LSP
      integration, render-side parsing, background whole-project scanning, or
      dirty-state mutation.

- [x] Pass899 entry-barrier condition recovery guard updated:
  `Production_Entry_Barrier_Missing_Condition_Recovery_Boundary`,
  `Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary`, and
  `Test_Language_Model_Token_Cursor_Entry_Barrier_Condition_Recovery_Pass899`
  are covered by validation markers. This remains bounded parser metadata only;
  no tasking legality checking, barrier condition type checking, compiler
  invocation, LSP integration, render-side parsing, background whole-project
  scanning, or dirty-state mutation is introduced.

### Pass900 — entry-family empty-definition recovery

- [x] Keep `Production_Entry_Family_Empty_Definition_Recovery_Boundary`
      parser-owned and recovery-only.
- [x] Keep `Test_Language_Model_Token_Cursor_Entry_Family_Empty_Definition_Recovery_Pass900`
      registered with the language-model regression suite.
- [x] Verify empty entry-family definitions preserve following valid entry
      family and parameter-profile metadata.
- [x] Do not reinterpret this as entry-family legality checking, discrete
      subtype validation, compiler invocation, LSP integration, render-side
      parsing, background whole-project scanning, or dirty-state mutation.


- [x] Pass901: abort target-list reserved-boundary recovery is documented and guarded by `Test_Language_Model_Token_Cursor_Abort_Target_Reserved_Boundary_Recovery_Pass901`.


- [x] Pass902: requeue target reserved-boundary recovery is documented and guarded by `Test_Language_Model_Token_Cursor_Requeue_Target_Reserved_Boundary_Recovery_Pass902`.

- [x] Pass903: delay expression reserved-boundary recovery is documented and guarded by `Test_Language_Model_Token_Cursor_Delay_Expression_Reserved_Boundary_Recovery_Pass903`.

- [ ] Pass904 goto target reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Goto_Target_Reserved_Boundary_Recovery_Pass904`; verify malformed `goto else;` exposes `Production_Goto_Target_Reserved_Boundary_Recovery_Boundary` without treating `else` as a label name.

- [ ] Pass905 return expression reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Return_Expression_Reserved_Boundary_Recovery_Pass905`; verify malformed `return else;` exposes `Production_Return_Reserved_Boundary_Recovery_Boundary` without treating `else` as a return expression.

- [ ] Pass906 raise target reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Raise_Target_Reserved_Boundary_Recovery_Pass906`; verify malformed `raise else;` exposes `Production_Raise_Target_Reserved_Boundary_Recovery_Boundary` without treating `else` as a raise exception name.

- [ ] Pass907 exit target reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Exit_Target_Reserved_Boundary_Recovery_Pass907`; verify malformed `exit else;` exposes `Production_Exit_Target_Reserved_Boundary_Recovery_Boundary` without treating `else` as an exit loop name.

- [ ] Pass908 assignment expression reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Assignment_Expression_Reserved_Boundary_Recovery_Pass908`; verify malformed `Value := else;` exposes `Production_Assignment_Reserved_Boundary_Recovery_Boundary` without treating `else` as an assignment expression.

- [ ] Pass909 call actual association-list recovery is covered by `Test_Language_Model_Token_Cursor_Call_Actual_Association_Recovery_Pass909`; verify malformed `Call ();`, `Call (Item =>, Other => 1);`, and `Call (1,);` expose call-actual-specific recovery metadata without treating delimiters or separators as actual expressions.

- [ ] Pass910 if/elsif missing-condition recovery is covered by `Test_Language_Model_Token_Cursor_If_Elsif_Condition_Recovery_Pass910`; verify malformed `if then` and `elsif then` expose condition-specific recovery metadata without treating `then` as a condition expression, while preserving following valid conditions and `end if` terminators.

- [ ] Pass911 while-loop missing-condition recovery is covered by `Test_Language_Model_Token_Cursor_While_Condition_Recovery_Pass911`; verify malformed `while loop` exposes condition-specific recovery metadata without treating `loop` as a condition expression, while preserving following valid while conditions and loop terminators.

- [ ] Pass912 for/iterator loop domain reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_For_Iterator_Domain_Reserved_Boundary_Recovery_Pass912`; verify malformed `for I in else loop` and `for C of else loop` expose loop-domain-specific recovery metadata without treating reserved boundaries as iteration domains, while preserving following valid loop domains and loop terminators.

- [ ] Pass913 case selector reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery_Pass913`; verify malformed `case is` exposes `Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary` without treating `is` as a selector expression, while preserving following valid case selectors and case terminators.

- Pass914: extended return object initializer reserved-boundary recovery keeps
  `do`/`end return` visible and avoids treating reserved boundaries as
  initializer expressions.

- [ ] Pass915 raise message reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Raise_Message_Reserved_Boundary_Recovery_Pass915`; verify malformed `raise Program_Error with else;` exposes `Production_Raise_Message_Reserved_Boundary_Recovery_Boundary` without treating `else` as a raise message expression.

- [ ] Pass916 exit-when condition reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Exit_When_Reserved_Boundary_Recovery_Pass916`; verify malformed `exit when else;` exposes `Production_Exit_When_Reserved_Boundary_Recovery_Boundary` without treating `else` as an exit-when condition expression.
- [ ] Pass917 null-statement reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Null_Reserved_Boundary_Recovery_Pass917`; verify malformed `null else` exposes `Production_Null_Reserved_Boundary_Recovery_Boundary` without treating `else` as a valid terminator or following statement payload.

- [ ] Pass918 aggregate component expression reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Aggregate_Component_Reserved_Boundary_Recovery_Pass918`; verify malformed `(1 => else, 2 => 10)` exposes `Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary` without treating `else` as a component expression.

- [ ] Pass919 object initialization reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Object_Initialization_Reserved_Boundary_Recovery_Pass919`; verify malformed `Broken : Integer := with Volatile;` exposes `Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary` without treating the aspect boundary as an initializer expression.

- [ ] Pass920 range constraint reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery_Pass920`; verify malformed range constraints such as `subtype Missing_Lower is Integer range else;` and `subtype Missing_Upper is Integer range 1 .. else;` expose `Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary` without treating reserved boundary keywords as bound expressions.

- [ ] Pass921 digits/delta constraint reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery_Pass921`; verify malformed constraints such as `subtype Missing_Digits is Float digits else;` and `subtype Missing_Delta is Fixed delta else;` expose `Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary` and `Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary` without treating reserved boundary keywords as constraint expressions.

- [ ] Pass922 index/discriminant constraint reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Index_Discriminant_Constraint_Reserved_Boundary_Recovery_Pass922`; verify malformed constraints such as `Vector (else)`, `Vector (1 .. else)`, and `Rec (D => else)` expose index/discriminant-specific recovery metadata without treating reserved boundary keywords as constraint expressions.

- [ ] Pass923 profile default reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Profile_Default_Reserved_Boundary_Recovery_Pass923`; verify malformed defaults such as `Item : Integer := )`, `Item : Integer := ;`, and `Item : Integer := with Inline` expose `Production_Profile_Default_Reserved_Boundary_Recovery_Boundary` without treating boundary tokens as default expressions.

- [ ] Pass924 object subtype reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Object_Subtype_Reserved_Boundary_Recovery_Pass924`; verify malformed object declarations such as `Missing_With : with Volatile;` and `Missing_Then : then;` expose `Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary` without treating boundary tokens as subtype marks.

- [ ] Pass925 number initialization reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery_Pass925`; verify malformed named-number declarations such as `Missing_With : constant := with Volatile;` and `Missing_Then : constant := then;` expose `Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary` without treating boundary tokens as initialization expressions.

- [ ] Pass926 component default reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Component_Default_Reserved_Boundary_Recovery_Pass926`; verify malformed component declarations such as `Missing_With : Integer := with Volatile;` and `Missing_Then : Integer := then;` expose `Production_Component_Default_Reserved_Boundary_Recovery_Boundary` without treating boundary tokens as default expressions.

- [ ] Pass927 discriminant default reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Discriminant_Default_Reserved_Boundary_Recovery_Pass927`; verify malformed discriminant specifications such as `D : Integer := with Volatile` and `D : Integer := then` expose `Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary` without treating boundary tokens as default expressions.

- [ ] Pass928 array index reserved-boundary recovery is covered by `Test_Language_Model_Token_Cursor_Array_Index_Reserved_Boundary_Recovery_Pass928`; verify malformed array type definitions such as `array (else) of Integer` and `array (1 .. else) of Integer` expose `Production_Array_Index_Reserved_Boundary_Recovery_Boundary` without treating reserved boundary tokens as index expressions.

### Pass929 — Access-object missing subtype recovery

- [x] Token cursor records `Production_Access_Object_Missing_Subtype_Recovery_Boundary` for access-to-object definitions whose designated subtype is replaced by a reserved/declaration boundary.
- [x] Regression coverage includes aspect, private, and delimiter boundary examples plus recovery into a following declaration.
- [x] Validation guard requires the new production and pass929 regression test.
- [x] This is editor-grade structural grammar coverage, not compiler-grade access-type legality checking, designated-subtype legality checking, subtype resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass930 — Access-definition recovery depth

- [x] Token cursor records `Production_Access_Mode_Missing_Subtype_Recovery_Boundary` for `access all` / `access constant` definitions that reach a boundary before a designated subtype.
- [x] Token cursor records `Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary` when a general-access object mode is followed by an access-to-subprogram head.
- [x] Token cursor records `Production_Access_Protected_Missing_Subprogram_Boundary_Token` to retain the actual boundary token after malformed `access protected`.
- [x] Token cursor records `Production_Access_Result_Missing_Subtype_Recovery_Boundary` when an access-to-function `return` reaches an aspect/declaration boundary before a result subtype.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth_Pass930`.
- [x] This remains editor-grade structural grammar coverage only, not compiler-grade access-type legality checking, designated-subtype legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass931 — Generic formal subprogram default recovery

- [x] Token cursor records `Production_Formal_Subprogram_Default_Abstract_Name` for `is abstract Name` formal subprogram defaults.
- [x] Token cursor records `Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary` for missing formal subprogram default targets at declaration/aspect boundaries.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery_Pass931`.
- [x] This improves structural generic formal declaration coverage only; it is not compiler-grade generic contract checking, default conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass932 — Formal package declaration header recovery

- [x] Token cursor records formal package missing-`is` and missing-`new` recovery boundaries.
- [x] Token cursor records formal package named-to-positional actual-order recovery.
- [x] AUnit coverage includes `Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery_Pass932`.
- [x] Parser coverage matrix, syntax-colouring notes, validation guards, and README document the structural-only scope.

### Pass933 — Use-clause recovery depth

- [x] Added structural recovery metadata for malformed `use all ...;` clauses that omit `type`.
- [x] Added structural recovery metadata for reserved declaration/package boundaries encountered where a use-clause package name or subtype mark was expected.
- [x] Added AUnit coverage through `Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth_Pass933`.
- [x] Confirmed the change remains parser metadata only and does not add compiler-grade visibility legality checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

- Pass934: representation/operational item recovery depth is covered by `Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth_Pass934`; verify that this remains structural parser metadata only and does not introduce compiler invocation, LSP integration, render-side parsing, dirty-state mutation, or background whole-project scanning.

### Pass935 parser guard

- Confirm `Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth_Pass935` remains registered.
- Confirm contract aspects on subprogram bodies, null completions, abstract completions, and expression functions retain specific placement productions.
- Confirm malformed contract aspect values retain `Production_Contract_Aspect_Missing_Value_Recovery_Boundary` and generic recovery metadata.
- Confirm this remains bounded parser-owned structural coverage and does not introduce compiler invocation, LSP integration, rendering-side parsing, background scans, or dirty-state mutation.

### Pass936 parser guard

- Confirm `Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families_Pass936` remains registered.
- Confirm class-wide contract aspect marks and contract value-family productions remain parser-owned metadata only.
- Confirm this pass does not add compiler invocation, LSP integration, rendering-side parsing, background scanning, or dirty-state mutation.

### Pass937 parser guard

- Confirm `Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth_Pass937` remains registered.
- Confirm `Production_Package_Duplicate_Private_Boundary`, `Production_Package_Private_Begin_Recovery_Boundary`, and `Production_Package_Body_Private_Declarative_Recovery_Boundary` remain in the token cursor production list.
- Confirm package section recovery remains parser-owned and does not introduce compiler invocation, LSP integration, render-side parsing, whole-project scanning, or dirty-state mutation.

### Pass938 parser guard

- Confirm `Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refinement_Depth_Pass938` remains registered.
- Confirm `Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary` and `Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary` remain in the token cursor production list.
- Confirm anonymous access-to-subprogram recovery remains parser-owned and does not introduce compiler invocation, LSP integration, render-side parsing, whole-project scanning, or dirty-state mutation.

### Pass939 parser guard

- Confirm `Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939` remains registered.
- Confirm expression recovery remains snapshot-owned and does not introduce render-side parsing, compiler invocation, LSP integration, background scanning, dirty-state mutation, or command/workspace/render state leaks.

### Pass940 parser guard

- [x] Name grammar recovery depth remains snapshot-owned and parser-bounded.
- [x] `Production_Selected_Name_Reserved_Selector_Recovery_Boundary`, `Production_Allocator_Missing_Subtype_Recovery_Boundary`, and `Production_Qualified_Expression_Missing_Operand_Recovery_Boundary` are covered by `Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth_Pass940`.
- [x] The pass improves structural grammar coverage only; it does not add compiler-grade name legality, allocator subtype legality, qualified-expression operand legality, overload resolution, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass941 parser guard

- [x] Protected entry-body barrier recovery remains snapshot-owned and parser-bounded.
- [x] `Production_Entry_Body_Missing_Barrier_Recovery_Boundary` and `Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary` are covered by `Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery_Pass941`.
- [x] The pass improves structural grammar coverage only; it does not add compiler-grade tasking legality checking, protected-operation conformance checking, barrier expression legality checking, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

- [x] Pass942 compiler-grade grammar foundation guard updated: syntax-tree node families for Ada 2022 declare expressions, delta aggregates, container aggregates, reduction expressions, iterator specifications, and target-name `@` expressions are covered by `Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage_Pass942` and validation markers. This is grammar-model infrastructure for later compiler-grade semantics; it does not yet complete name resolution, overload resolution, type checking, static evaluation, generic contracts, freezing, representation legality, or cross-unit analysis.

- [x] Pass943 compiler-grade semantic foundation guard updated: `Editor.Ada_Declarative_Regions` now builds stable declarative regions from the parser-owned Ada syntax tree and is covered by `Test_Ada_Declarative_Region_Model_Foundation_Pass943`. The pass records region identity, owner nodes, parentage, depth, and fingerprints for compilation, generic, package, subprogram, task/protected, entry, record, and block regions. This enables later compiler-grade name-resolution and visibility work; it does not yet perform lookup, overload resolution, type checking, static evaluation, generic contract checking, freezing, or representation legality.

- [x] Pass944 compiler-grade direct-visibility foundation guard updated: `Editor.Ada_Direct_Visibility` records declarations directly owned by parser-derived declarative regions and supports deterministic case-insensitive direct/enclosing-region lookup. Covered by `Test_Ada_Direct_Visibility_Foundation_Pass944`. This enables later direct-name resolution, ambiguity diagnostics, and use-clause integration; it does not yet perform overload resolution, expected-type analysis, type checking, freezing, representation legality, or cross-unit semantic closure.

- [x] Pass945: use-clause visibility foundation added with deterministic
      package-use lookup, ambiguity metadata, direct-declaration precedence, and
      AUnit regression coverage.

- Phase 579 pass947: validate `Editor.Ada_Use_Type_Operators` is included with the language-intelligence sources and that `Test_Ada_Use_Type_Operator_Visibility_Foundation_Pass947` remains registered.  The pass adds compiler-grade semantic foundation for `use type` primitive operator visibility, not full overload/type legality.

- Phase 579 pass948: validate `Editor.Ada_Call_Candidates` is included with the language-intelligence sources and that `Test_Ada_Call_Candidate_Foundation_Pass948` remains registered.  The pass adds a compiler-grade overload-resolution foundation for pre-filter call candidates; it does not complete expected-type/profile/type legality.

- Phase 579 pass949: validate `Editor.Ada_Call_Profile_Shapes` remains included with the language-intelligence sources and that `Test_Ada_Call_Profile_Shape_Foundation_Pass949` remains registered.  The pass adds compiler-grade call-profile and actual-argument shape metadata for later overload filtering; it does not complete expected-type propagation, full profile conformance, type checking, generic contracts, freezing, representation legality, or cross-unit semantic closure.

- Phase 579 pass950: validate `Editor.Ada_Call_Profile_Filters` remains included with the language-intelligence sources and that `Test_Ada_Call_Profile_Filter_Foundation_Pass950` remains registered.  The pass adds compiler-grade call-profile filtering for arity and named-actual shape metadata; it does not complete formal-name matching, defaulted-formal legality, expected-type propagation, full profile conformance, type checking, generic contracts, freezing, representation legality, or cross-unit semantic closure.

- [x] Phase 579 pass951: `Editor.Ada_Call_Profile_Shapes` and `Editor.Ada_Call_Profile_Filters` retain formal-name, defaulted-formal, and named-actual metadata. `Test_Ada_Call_Profile_Formal_Name_Filter_Pass951` covers matched named actuals, unknown named actuals, missing required formals, and deterministic fingerprints. This is an overload-resolution foundation; it does not complete expected-type propagation, full profile conformance, type checking, generic contracts, freezing/representation legality, or cross-unit closure.
- [x] Phase 579 pass952: `Editor.Ada_Call_Resolution` classifies call-shaped syntax nodes after candidate collection and profile filtering. `Test_Ada_Call_Resolution_Profile_Result_Pass952` covers unique profile matches, no-viable-profile calls, unresolved designators, pre-profile ambiguity, and deterministic fingerprints. This is an overload-resolution staging layer; expected-type propagation, full profile conformance, type checking, implicit conversions, generic contracts, freezing/representation legality, and cross-unit semantic closure remain later work.


### Pass953 expected-type context foundation

Release guard: expected-type context metadata is snapshot-owned and derived from parser-owned syntax/semantic models only. It must not invoke the compiler, LSP, render-side parsing, background whole-project scans, or dirty-state mutation.

- [ ] Pass954 expected-call result-subtype filtering remains registered through `Test_Ada_Expected_Call_Filter_Foundation_Pass954`, with `Editor.Ada_Expected_Call_Filters` kept snapshot-owned and free of compiler invocation, LSP integration, renderer-side parsing, background scans, file mutation, and dirty-state mutation.

- [ ] Pass955 subtype-compatibility foundation remains registered through `Test_Ada_Subtype_Compatibility_Foundation_Pass955`, with `Editor.Ada_Subtype_Compatibility` and the expected-call compatibility hook kept snapshot-owned and free of compiler invocation, LSP integration, renderer-side parsing, background scans, file mutation, and dirty-state mutation.
- [ ] Pass956 type-graph foundation remains registered through `Test_Ada_Type_Graph_Foundation_Pass956`, with `Editor.Ada_Type_Graph` kept snapshot-owned and free of compiler invocation, LSP integration, renderer-side parsing, background scans, file mutation, and dirty-state mutation.

- [ ] Pass957 type-graph-aware expected-call compatibility remains registered through `Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957`, with `Editor.Ada_Subtype_Compatibility`, `Editor.Ada_Type_Graph`, and `Editor.Ada_Expected_Call_Filters` kept snapshot-owned and free of compiler invocation, LSP integration, renderer-side parsing, background scans, file mutation, and dirty-state mutation.

- [ ] Pass958: retain AUnit coverage for private/full-view type graph links, interface classification, and class-wide expected-call compatibility.
- [ ] Pass959: retain AUnit coverage for expected-call implicit-conversion classification after subtype/type-graph compatibility.
- [ ] Pass960: retain AUnit coverage for `Editor.Ada_Static_Expressions` named-number/static-constant integer evaluation and unresolved-name preservation.


### Pass961 - static attribute expression foundation

- [ ] Retain AUnit coverage for `Editor.Ada_Static_Expressions` scalar subtype-bound staging.
- [ ] Confirm `T'First`, `T'Last`, `T'Pos`, and `T'Val` static-expression metadata remains deterministic and snapshot-owned.
- [ ] Confirm unsupported attributes are retained as unsupported metadata rather than guessed as static values.
- [ ] Do not treat this as complete Ada static-expression legality, enumeration-position legality, modular overflow handling, compiler invocation, LSP integration, render-side parsing, background scanning, file save/reload, or dirty-state mutation.

### Pass962 - enumeration-position static-expression foundation

- [ ] Retain AUnit coverage through `Test_Ada_Static_Enumeration_Position_Foundation_Pass962`.
- [ ] Confirm enumeration literal position metadata remains derived only from parser-owned syntax-tree snapshots and declarative regions.
- [ ] Confirm `T'Pos (Literal)` and `T'Val (Position)` keep deterministic metadata and preserve unresolved operands for diagnostics.
- [ ] Do not treat this as complete Ada static-expression legality, complete discrete-type legality, generic contract matching, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.

### Pass963 - modular-integer static-expression foundation

- [ ] Retain AUnit coverage through `Test_Ada_Static_Modular_Integer_Foundation_Pass963`.
- [ ] Confirm modular type modulus expressions remain snapshot-owned, deterministic, and staged without compiler invocation.
- [ ] Confirm `Reduce_Modular_Integer` preserves unresolved modular type names and non-static/malformed modulus cases for later diagnostics.
- [ ] Do not treat this as complete Ada modular arithmetic legality, complete discrete-type legality, generic contract matching, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.

### Pass964 - real/universal numeric static-expression foundation

- [ ] Retain AUnit coverage through `Test_Ada_Static_Real_Numeric_Foundation_Pass964`.
- [ ] Confirm real static-expression metadata remains snapshot-owned and deterministic.
- [ ] Confirm integer-only static clients continue to reject real-valued expressions explicitly.
- [ ] Confirm no compiler invocation, LSP, external parser generator, renderer parsing, background whole-project scan, file save/reload, or dirty-state mutation is introduced.

### Pass965 - fixed-point static-expression foundation

- [ ] Retain AUnit coverage through `Test_Ada_Static_Fixed_Point_Foundation_Pass965`.
- [ ] Confirm fixed-point delta/range metadata remains snapshot-owned, deterministic, and parser/static-model owned.
- [ ] Confirm fixed-point quantization preserves explicit delta-mismatch and range-error statuses for later diagnostics instead of silently accepting or guessing values.

### Pass966 - generic contract model foundation

- [ ] Retain AUnit coverage through `Test_Ada_Generic_Contract_Foundation_Pass966`.
- [ ] Confirm `Editor.Ada_Generic_Contracts` records formal type/object/subprogram/package declarations from snapshot-owned direct-visibility metadata.
- [ ] Confirm generic instantiation actual-shape metadata preserves positional/named actual counts and named-actual names deterministically.
- [ ] Do not treat this as complete Ada generic contract conformance, overload matching, private-view legality, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.

### Pass967 - generic formal/actual matching foundation

- [x] Retain `Editor.Ada_Generic_Contracts.Generic_Actual_Match_Info` and the actual-match enumeration/query APIs.
- [x] Retain AUnit coverage through `Test_Ada_Generic_Actual_Matching_Foundation_Pass967`.
- [x] Validate that generic actual matching remains snapshot-owned and built from parser/direct-visibility/declarative-region data only.
- [ ] Do not treat this as complete Ada generic conformance, formal subprogram profile conformance, formal package contract matching, overload resolution, private-view legality, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.

### Pass968 - generic formal/actual kind conformance foundation

- [x] Retain `Editor.Ada_Generic_Contracts.Generic_Actual_Kind` and kind-mismatch metadata in actual-match records.
- [x] Retain AUnit coverage through `Test_Ada_Generic_Formal_Actual_Kind_Conformance_Pass968`.
- [x] Validate that kind conformance remains deterministic, snapshot-owned, and parser/visibility-model owned.
- [ ] Do not treat this as complete Ada generic conformance, formal subprogram profile conformance, formal package contract matching, overload resolution, private-view legality, freezing/representation legality, compiler invocation, LSP integration, renderer-side parsing, background scanning, file mutation, or dirty-state mutation.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

- Phase 579 pass971: verify generic body contract-visibility metadata remains deterministic, snapshot-owned, and does not introduce rendering-side parsing or editor dirty-state mutation.

- Phase 579 pass972: verify overloaded generic subprogram actual selection remains deterministic, bounded, snapshot-owned, and isolated from rendering, command, workspace, and dirty-state mutation paths.

- Phase 579 pass973: verify static-aware generic default-expression legality remains deterministic, snapshot-owned, and isolated from rendering, command, workspace, file lifecycle, and dirty-state mutation paths.
\nPass974: Generic-contract analysis now retains formal subprogram parameter mode vectors and classifies declaration-shaped subprogram actuals with same arity/subtypes but nonconforming modes as deterministic mode mismatches. Regression coverage: Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974.

### Phase 579 pass975

- Verify `Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance_Pass975` with the generic contract suite.
- Confirm callers that need stricter generic profile conformance use `Build_With_Type_Graph` or `Build_With_Static_And_Type_Graph`.
- Confirm legacy `Build` behavior remains conservative for text-only profile matching.


Pass976 adds a compiler-grade generic profile-conformance building block for formal subprogram null-exclusion and anonymous access-to-subprogram profile matching. Generic actual matching now records and reports null-exclusion mismatches and access-profile mismatches separately from generic profile mismatches, with deterministic counters and regression coverage in Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing, representation legality, cross-unit closure, and full expression type inference are fully integrated.

- Pass976: verify formal subprogram null-exclusion/access-profile conformance metadata and counters remain deterministic and snapshot-owned.

- Pass987: verify enumeration representation legality metadata remains deterministic and stale-analysis safe.
- Pass988: verify Address clause target/value legality metadata remains deterministic and stale-analysis safe.

- Pass989: Size/Alignment/Storage_Size representation legality regression and deterministic counters are present.

Pass992: verify stream attribute profile conformance remains deterministic, snapshot-owned, and covered by `Test_Ada_Stream_Attribute_Profile_Conformance_Pass992`.

- Pass995: cross-unit semantic closure exposes explicit resolved/missing/ambiguous/overflow link statuses for unit-family relationships.

## Pass997 cross-unit spec/body consistency

Pass997 extends the cross-unit semantic-closure model with deterministic spec/body consistency metadata. The model now records confirmed package/subprogram spec/body pairs and missing, ambiguous, overflow, role-mismatch, and name-mismatch conditions with stable fingerprints. This is parser/index-owned semantic data and does not require rendering-side parsing, file reloads, dirty-state mutation, or compiler invocation.

Pass998: cross-unit closure now includes deterministic child-unit and private-child legality metadata. Child library units are classified as resolved public children, resolved private children, missing-parent children, ambiguous-parent children, overflowed children, or parent-role mismatches, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`.

Pass999: cross-unit closure now includes deterministic separate-body legality metadata. Separate bodies are classified separately from raw separate-parent links as resolved parent bodies, missing parents, ambiguous parents, overflow, parent-role mismatches, or missing parent-name text, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`.

Pass1000: expression type inference foundation added. Verify expression-type metadata remains snapshot-owned, deterministic, bounded, and independent of renderer/editor mutation paths.

Pass1001 note: expression type inference now has an opt-in expected-type propagation layer. Declaration-default contexts and existing expected-context metadata are staged into deterministic expression records with compatible/propagated/mismatch/unknown statuses for later diagnostics and overload/type checking.

Pass1002 note: expression type inference now records deterministic operator operand/result metadata for predefined numeric, Boolean, short-circuit, relational, and membership-shaped operators. Operand mismatch and unknown cases remain explicit for later diagnostics and overload-aware typing.

Pass1003: expression aggregate context inference adds context-sensitive aggregate/container-aggregate metadata, component-shape counters, and deterministic unknown/mismatch preservation to the Ada expression-type model.

Pass1004 update: expression type inference now includes conversion and qualified-expression target/operand metadata. The model exposes deterministic counters for resolved conversion targets, compatible operands, explicit-conversion operands, mismatches, and unknown conversion cases, with regression coverage in `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`.

Pass1005 update: attribute-reference expression type inference metadata added with deterministic counters and regression coverage in `Test_Ada_Expression_Attribute_Reference_Inference_Pass1005`.


Pass1007: Added expression membership/range inference metadata. Membership expressions now retain Boolean result plus operand/choice compatibility state; range expressions retain bound subtype compatibility state; deterministic counters and fingerprints cover resolved, mismatch, and unknown cases.

Pass1008: Added expression target-name/update inference metadata. Ada 2022 target-name @ expressions now preserve context-required versus context-propagated status, delta/update aggregates retain expected/source subtype compatibility metadata, and deterministic counters/fingerprints expose compatible, mismatch, and unknown update-expression cases.


Pass1009: verify indexed component/slice inference metadata and counters remain deterministic.

Pass1014 release note: operator-overload expression metadata is staged in Editor.Ada_Expression_Types with deterministic counters and AUnit coverage; no rendering, command, workspace, file-save, or dirty-state mutation path is introduced.

Pass1015 release note: universal numeric final-resolution metadata is staged in Editor.Ada_Expression_Types with deterministic counters and AUnit coverage; no rendering, command, workspace, file-save, or dirty-state mutation path is introduced.

Pass1016 release note: aggregate type-graph validation metadata is staged in Editor.Ada_Expression_Types with deterministic counters and AUnit coverage; no rendering, command, workspace, file-save, or dirty-state mutation path is introduced.

Pass1017: Expression type inference now includes raise-expression/no-return metadata with exception target, message shape, expected result context, deterministic counters, and AUnit coverage.

### Pass1018 — Boolean-context expression inference

- [x] Boolean-context inference metadata is staged by `Editor.Ada_Expression_Types`.
- [x] Short-circuit and condition-shaped expressions preserve compatible/mismatched/unknown Boolean operand metadata.
- [x] Regression coverage is provided by `Test_Ada_Expression_Boolean_Context_Inference_Pass1018`.

### Pass1019 — string and array concatenation inference

- [x] Concatenation inference metadata is staged by `Editor.Ada_Expression_Types`.
- [x] String-family and array-family result cases are classified separately from generic operator inference.
- [x] Mismatched and unknown concatenation operands remain deterministic metadata.
- [x] `Test_Ada_Expression_Concatenation_Inference_Pass1019` covers the new model layer.

### Pass1020
Pass1020 adds dispatching-call inference metadata to `Editor.Ada_Expression_Types`, including primitive target, static binding, dynamic dispatch candidate, controlling-result, ambiguous, unresolved, and unknown classifications with deterministic counters and fingerprints.
### Pass1021
Pass1021 adds expression diagnostics projection from expression-type metadata with stable spans, severity/kind classification, counters, and deterministic fingerprints.
- Pass1022: verified cross-unit visibility metadata remains snapshot-owned and deterministic for ordinary/limited/private with and context use dependencies.

- Pass1023: verified limited-with incomplete-view metadata remains snapshot-owned and deterministic, preserving full-view-hidden status without renderer or workspace mutation.

- [x] Pass1026 child-unit visibility guard added: `Editor.Ada_Child_Unit_Visibility` projects child-unit legality into public/private-child context visibility metadata with deterministic counters and fingerprints, preserving missing/ambiguous/overflow/role-mismatch parent states without rendering-side parsing, file IO, compiler invocation, LSP integration, dirty-state mutation, or command/workspace/render mutation leaks.

- Pass1035: verify generic formal package nested actual conformance metadata remains deterministic and projection-only.
- Pass1036: verify generic renaming and nested generic instantiation visibility metadata remains deterministic and projection-only.

- Pass1037: verify generic object default-expression type conformance metadata remains deterministic, bounded, and projection-only.

- Pass1038: generic contract diagnostics projection added for formal-type, formal-package, renaming/nested-instantiation, and formal-object default/actual conformance metadata.

Pass1039 update:
- Added Editor.Ada_Cross_Unit_Diagnostics to project cross-unit visibility and closure metadata into deterministic diagnostics.
- Covers missing/ambiguous dependencies, limited-view full-view restrictions, private-with visible-part restrictions, body/spec conformance failures, private-child visibility restrictions, child-parent errors, and separate-body stub/parent errors.
- Added Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039.

Pass1041: Semantic-colouring diagnostics projection added for expression, generic-contract, cross-unit, and representation/freezing diagnostics. Rendering remains projection-only.

Pass1042: Semantic diagnostic snapshot guards added for expression/generic/cross-unit/representation diagnostic colouring projections. Stale overlays are rejected by path, buffer token, revision, lifecycle generation, request token, and analysis fingerprint.

## Pass1045 release checklist note

- Diagnostic navigation is implemented by `Editor.Ada_Diagnostic_Navigation` over the guarded semantic diagnostic index.
- The navigation model is deterministic and projection-only, with first/last and next/previous target lookup plus severity filtering.
- Rejected stale indexes expose zero navigation targets and preserve rejected-target counts.

## Pass1046 release checklist note

- Diagnostic panel projection is implemented by `Editor.Ada_Diagnostic_Panel_Projection` over the guarded semantic diagnostic index.
- Confirm panel rows preserve stable identity, spans, severity, source family, token kind, syntax node, message payload, file/unit grouping metadata, selected-row state, and fingerprints.
- Confirm stale/rejected indexes expose zero panel rows and preserve rejected-row totals.

## Pass1047 release checklist note

- Verify diagnostic status-line summaries remain deterministic and projection-only.
- Verify stale semantic diagnostic indexes produce no active status-line targets.


## Pass1048 release checklist note

`Editor.Ada_Diagnostic_Quick_Fix_Skeleton` is projection-only. It exposes deterministic non-mutating quick-fix action skeletons from accepted semantic diagnostic indexes and withholds stale candidates.

## Pass1049 release checklist note

- Confirm `Editor.Ada_Diagnostic_Provenance` remains projection-only and consumes only `Editor.Ada_Semantic_Diagnostic_Index`.
- Confirm rejected stale indexes expose zero provenance items while preserving rejected-item totals.
- Confirm `Test_Ada_Diagnostic_Provenance_Pass1049` remains registered in the syntax semantics AUnit suite.

## Pass1050 release checklist note

- Confirm `Editor.Ada_Diagnostic_Suppression_Baseline` remains a projection-only consumer of `Editor.Ada_Semantic_Diagnostic_Index`.
- Confirm suppression and baseline rules classify diagnostics without applying source edits or mutating buffers/workspace state.
- Confirm stale/rejected indexes expose no active suppression entries and preserve rejected-entry totals.
- Confirm `Test_Ada_Diagnostic_Suppression_Baseline_Pass1050` remains registered in the syntax semantics AUnit suite.

Pass1051 note:
- Added overload ambiguity diagnostics over expression-type metadata. The model explains call/operator/universal-numeric ambiguity, mismatch, and unknown causes without adding rendering-side parsing, source mutation, file IO, command registration, workspace mutation, or compiler invocation.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.


### Pass1063 — Nested body/spec diagnostics projection

Pass1063 extends `Editor.Ada_Cross_Unit_Diagnostics` with `Build_With_Nested`, projecting `Editor.Ada_Nested_Body_Spec_Conformance` results into the cross-unit diagnostics model. Diagnostics now cover nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs while preserving nested conformance identity/status, declaration names, spans, severity, messages, counters, and deterministic fingerprints. The existing `Build` path remains unchanged for first-order cross-unit diagnostics. Regression coverage is in `Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063`.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1064 — Selected-name representation target resolution

Pass1064 adds `Editor.Ada_Selected_Representation_Targets`, a deterministic representation-target consumer that combines `Editor.Ada_Cross_Unit_Representation_Targets` with `Editor.Ada_Selected_Name_Resolution`. Representation clauses whose targets are selected names now preserve selected-name identity/status, prefix/selector text, visible cross-unit target unit/path, candidate counts, classification counters, and deterministic fingerprints. The layer distinguishes local selected targets, cross-unit visible selected targets, use-visible selected targets, limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, and non-selected targets without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work. Regression coverage is in `Test_Ada_Selected_Representation_Targets_Pass1064`.

Pass1073 note: unified diagnostic provenance now accepts overload-ranking provenance through Editor.Ada_Diagnostic_Provenance.Build_With_Overload_Ranking.  The layer is projection-only, snapshot-guarded, and keeps overload-ranking explanation metadata out of rendering, command, workspace, and buffer mutation paths.

Pass1074 note: diagnostic quick-fix skeletons now accept overload-ranking provenance through Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build_With_Overload_Ranking.  The layer is projection-only, preserves ranked overload evidence for IDE explanation actions, and does not parse, apply edits, mutate buffers, touch workspace state, or perform rendering-side semantic work.

- Pass1078: confirm diagnostic keybinding hint projection exposes only deterministic metadata and performs no command/keybinding/workspace/render mutation.

- Pass1085 diagnostic recovery command-palette projection: confirm entries are stable, deterministic, and projection-only.

- Pass1086 diagnostic recovery keybinding hints: confirm recovery palette entries project deterministic bindable/unavailable/stale-only/rejected hint states without command registration or keybinding mutation.

### Pass1091 diagnostic recovery render action projection

Added `Editor.Ada_Diagnostic_Recovery_Render_Action_Projection` as a deterministic projection-only consumer of diagnostic recovery render status.  It exposes retained/changed/missing/stale/restore-candidate recovery-render actions for IDE consumers while preserving stable diagnostic identities, source spans, severity/source metadata, persistent keys, and fingerprints.  No parsing, command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, buffer mutation, file save/reload, or rendering-side semantic work is introduced.

Pass1092: Added Editor.Ada_Diagnostic_Recovery_Render_Command_Projection as a projection-only command-facing layer for diagnostic recovery-render actions. It preserves stable recovery render/action/diagnostic identities and availability metadata while avoiding command registration, aliases, keybinding/workspace mutation, edits, parsing, file save/reload, and rendering-side semantic work. Regression: Test_Ada_Diagnostic_Recovery_Render_Command_Projection_Pass1092.

Pass1094 note: added `Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection` as a projection-only bridge from recovery-render command-palette entries to deterministic keybinding/invocation hint metadata. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent keys, previous/current diagnostic fingerprints, and hint fingerprints while avoiding command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, rendering, or rendering-side semantic work.

Pass1095 note: added `Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection` as a projection-only bridge from recovery-render keybinding hints to deterministic workspace/session-facing UI state descriptors. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent diagnostic/action/command keys, previous/current diagnostic fingerprints, selected/restore-candidate metadata, and workspace fingerprints while avoiding workspace/session mutation, command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, rendering, or rendering-side semantic work.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

- Pass1098: Verify `Editor.Ada_Diagnostic_Recovery_Render_Final_Status` remains a projection-only final lifecycle status consumer, withholds active rows for rejected stale final lifecycle inputs, preserves rejected-row totals/fingerprints, and introduces no parser, renderer, command, keybinding, workspace, buffer, dirty-state, or file lifecycle mutation.

Pass1099 note: Added `Editor.Ada_Assignment_Legality` as a semantic rule-completion pass for assignment and object-initialization legality.  The pass is snapshot-owned and projection-free: it consumes existing expression, subtype, static, type/view metadata and classifies target/source compatibility, constant/in-formal target errors, null-exclusion violations, static range violations, private/limited view barriers, unresolved universal numeric cases, and indeterminate cases without render-side parsing or editor mutation.

Pass1100 note: added `Editor.Ada_Return_Legality`, a snapshot-owned semantic legality layer for Ada return statements. It consumes assignment/object-initialization legality results and classifies legal procedure/function/extended returns plus illegal expression shape, incompatible result subtype, private/limited view barriers, unresolved result metadata, static range violations, unresolved universal numeric returns, and No_Return subprogram return statements. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, or mutable IDE-surface side effect is introduced.

Pass1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

Pass1102: Added `Editor.Ada_Control_Flow_Legality`, a wide snapshot-owned semantic legality layer for Ada control-flow and statement rules.  The pass classifies Boolean condition legality, case choice staticness/coverage/duplicates, exit/goto/label target legality, exception handler choices, raise targets, select/accept/requeue target checks, and return-path completeness without render-side parsing or editor mutation.

Pass1103 update: added `Editor.Ada_Tasking_Protected_Legality`, a snapshot-owned semantic legality layer for Ada task/protected type and body matching, entry declarations/bodies/families, protected barriers, accept/requeue legality, protected operation restrictions, select integration, and linked control-flow legality propagation. Added and registered `Test_Ada_Tasking_Protected_Legality_Pass1103`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

- Pass1104: verify `Editor.Ada_Tagged_Derived_Legality` preserves snapshot-owned tagged/derived/private/interface legality analysis, deterministic counters/lookups/fingerprints, and no projection-chain or IDE-mutation side effects.

- Pass1105: Confirm generic instance/freezing/representation semantic closure regression coverage (`Test_Ada_Generic_Instance_Freezing_Representation_Legality_Pass1105`) and no diagnostic projection-chain or mutable UI-surface expansion.

- Pass1106: Confirm cross-unit semantic closure regression coverage (`Test_Ada_Cross_Unit_Semantic_Closure_Pass1106`) and no diagnostic projection-chain or mutable UI-surface expansion.

Pass1107: wide semantic legality diagnostics bridge added for Pass1099-Pass1106 compiler-grade legality layers, preserving snapshot ownership and deterministic fingerprints.

Pass1108 update:
- Integrated the Pass1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108 and registered it in Core_Suite.

Pass1109 update: added Editor.Ada_Overload_Resolution_Legality as a compiler-grade overload/operator legality building block. It classifies exact and preference-based selections, expected-type and universal numeric preferences, primitive operator preference, implicit/class-wide/access conversion evidence, named/defaulted profile evidence, visibility failures, view barriers, cross-unit unresolved states, linked semantic errors, ambiguity, unknown, and indeterminate states. The layer is snapshot-owned and deterministic, with AUnit coverage in Test_Ada_Overload_Resolution_Legality_Pass1109.

Pass1110: added Editor.Ada_Staticness_Range_Predicate_Legality, a snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, predicate metadata, linked assignment/return/conversion/access/aggregate/overload legality, deterministic lookup helpers, counters, and fingerprints. No diagnostic UI projection chain, rendering-side parser, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration is introduced.

Pass1111 update: added `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned Ada accessibility/lifetime/aliasing legality layer covering accessibility levels, dynamic checks, null exclusion, access kind mismatches, aliased-object requirements, allocator/access-conversion/return-accessibility checks, anonymous access parameter escapes, access discriminant lifetime checks, dangling renaming risk metadata, and linked assignment/return/conversion/staticness failures. Added and registered `Test_Ada_Accessibility_Lifetime_Legality_Pass1111`.


- Pass1112: contract/aspect legality layer added and covered by AUnit regression.


- Pass1113: review elaboration/dependence legality diagnostics and ensure no render-side parsing or workspace mutation is introduced.


Pass1114: Added Editor.Ada_Unit_Completion_Order_Legality for compiler-grade unit/body completion and declaration-order legality, including package/subprogram/task/protected/generic body completion, private/deferred/incomplete completion, body-stub/separate-body completion, declaration-before-use, private-part ordering, frozen-before-completion, view barriers, and linked semantic blockers. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Pass1115 update: added Editor.Ada_Renaming_Alias_Visibility_Legality as a widened semantic legality layer for Ada renaming declarations, alias views, direct/use/use-type visibility, selected-name targets, homograph hiding, private/limited-view barriers, aliased-target requirements, self/circular renames, dangling rename risks, invalid/duplicate use clauses, and linked accessibility/overload/cross-unit/completion blockers. Added and registered Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1116 update: added Editor.Ada_Exception_Finalization_Legality as a widened semantic legality layer for Ada exception, raise, handler, propagation, cleanup/finalization, task termination, controlled primitive, and No_Return contexts. It consumes control-flow, accessibility/lifetime, contract/aspect, elaboration/dependence, renaming/visibility, and unit completion/order legality metadata; classifies legal raise/reraise/handler/renaming/propagation/finalization/No_Return cases; and reports unresolved/ambiguous/non-exception raise targets, reraise outside handlers, handler choice errors, raise-expression result issues, invalid exception renaming targets, controlled finalization primitive/profile/order/propagation/abort/master errors, No_Return violations, private/limited view barriers, and linked semantic blockers. Added and registered Test_Ada_Exception_Finalization_Legality_Pass1116. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1117 update: added Editor.Ada_Representation_Layout_Stream_Integration_Legality. The pass integrates representation legality, exact record layout, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime, staticness/range/predicate, completion/order, contract/aspect, and exception/finalization legality into one deterministic snapshot-owned semantic model. It adds Test_Ada_Representation_Layout_Stream_Integration_Legality_Pass1117 and keeps the analysis non-mutating, bounded, and independent of rendering, command, keybinding, workspace, save/reload, file IO, compiler invocation, LSP, and external parser generators.

Pass1118 update: added Editor.Ada_Integrated_Semantic_Closure as a widened semantic closure layer. It folds wide semantic legality diagnostics with overload, staticness/range/predicate, accessibility/lifetime, contract/aspect, elaboration/dependence, unit completion/order, renaming/alias/visibility, exception/finalization, and representation/layout/stream integration blockers into one deterministic snapshot-owned closure model. It classifies local/cross-unit/with-use legal closure, limited/private-view barriers, missing/ambiguous/overflow/stale/rejected dependencies, individual legality blockers, multiple blockers, and indeterminate closure. Added and registered Test_Ada_Integrated_Semantic_Closure_Pass1118 with counters, lookups, and fingerprints. The pass remains non-mutating and introduces no rendering-side parser, save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Pass1119 update:
- Integrated semantic closure diagnostics now flow into the unified snapshot-guarded semantic diagnostic feed through Build_With_Integrated_Closure.
- Non-legal integrated closure rows become indexed semantic diagnostics; legal closure rows remain non-diagnostic.
- Stale integrated closure inputs and rejected base diagnostic guards expose zero active rows while preserving rejected-entry totals.
- This is a semantic integration pass, not a UI projection-chain extension.

Pass1120: Added integrated semantic closure provenance in `Editor.Ada_Diagnostic_Provenance`. Indexed diagnostics from `Editor.Ada_Integrated_Semantic_Closure` now retain explainable links to closure status, blocker family, dependency state, fingerprints, and diagnostic/index identity. The pass is deterministic, bounded, snapshot-owned, and non-mutating.

Pass1121 update: added `Editor.Ada_Definite_Initialization_Flow_Legality` with snapshot-owned definite-initialization and flow-sensitive object-state legality for read-before-write, component coverage, out-parameter obligations, return-object initialization, branch/loop merge failures, exception/finalization initialization effects, and linked semantic blockers. Regression: `Test_Ada_Definite_Initialization_Flow_Legality_Pass1121`.

- Pass1122: verify definite-initialization/flow legality is routed through integrated semantic closure, unified diagnostics, diagnostic index, and provenance using `Test_Ada_Integrated_Closure_Definite_Initialization_Pass1122`.

- Pass1123: verify Global/Depends dataflow legality consumes contract-aspect flow facts and definite-initialization object-state facts, then routes non-legal rows through integrated semantic closure, unified diagnostics, diagnostic index, and provenance using `Test_Ada_Dataflow_Global_Depends_Legality_Pass1123`.

- Pass1124: predicate/invariant use-site legality added for assignments, returns, conversions, aggregates, call actuals, defaults, and generic actuals. Verify future release gates continue routing these semantic blockers through the Ada semantic diagnostic path rather than UI projection-only layers.

- Pass1125: generic instance body semantic expansion added. Verify instantiated generic body actual/formal substitutions continue feeding overload, accessibility, contract/aspect, dataflow, definite-initialization, predicate/invariant, and representation legality instead of regressing into projection-only diagnostics.

- Pass1132: verify parser/AST semantic coverage audit rows are generated from snapshot-owned parser/semantic facts and that missing grammar coverage is not surfaced through render, command, palette, workspace, or keybinding mutation paths.

Pass1133 note: parser/AST semantic coverage audit gaps now feed integrated semantic closure through `Editor.Ada_Integrated_Semantic_Closure.AST_Coverage`. Uncovered Ada 2022 constructs are actionable semantic blockers rather than passive audit findings.

Pass1134 update: semantic coverage gates consume parser/AST coverage audit rows and prevent downstream Ada legality layers from treating incomplete parser structure, missing semantic metadata, missing cross-unit metadata, or non-integrated semantic consumers as confident legal conclusions.

Pass1138 note: Global/Depends flow-effect graph legality is now represented by
`Editor.Ada_Flow_Effect_Graph_Legality`, including object read/write edges, call
propagation, generic formal/actual effect substitution, protected/task effects,
refined Global/Depends body/spec checks, coverage-gate blockers, deterministic
lookups, counters, and fingerprints.

- Pass1139 predicate/invariant propagation legality: verify use-site predicate/invariant rows flow through calls, generic instances, derived/private views, visible state updates, flow-effect graph blockers, and coverage-gate enforcement.

Pass1142: Added discriminant-dependent legality for constraints/defaults, variant presence, constrained-object checks, and assignment/conversion/return/allocator/generic actual use sites.


## Pass1143 - Accessibility / lifetime scope graph legality

Added `Editor.Ada_Accessibility_Scope_Graph_Legality` and AUnit coverage for master/scope hierarchy, anonymous access levels, allocator and return masters, access discriminants, generic substitutions, discriminant aggregates, finalization masters, and coverage-gated lifetime blockers.

## Pass1144 - Elaboration graph closure legality

* Added `Editor.Ada_Elaboration_Graph_Closure_Legality`.
* Added `Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144`.
* Verified the pass remains snapshot-owned and does not introduce rendering-side parsing, file IO, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, external parser generation, Python, or shell-script dependencies.

Pass1146 note: added Editor.Ada_Representation_Freezing_Exact_Propagation_Legality, which propagates implicit freezing from semantic uses and ties representation timing to generic body replay, discriminant/variant representation, operational/stream/finalization effects, flow-effect graphs, predicate/invariant propagation, accessibility scope graphs, elaboration graph closure, tasking/protected effects, and coverage-gated semantic blockers.

- Pass1152: repaired coverage semantic feedback must remain analysis-owned. A repaired parser/AST/metadata/consumer row may be consumed by widened legality engines only through `Editor.Ada_Repaired_Coverage_Semantic_Feedback.Is_Eligible_For_Engine`; stale, partial, mismatched, cross-unit-required, indeterminate, and original-error rows must not be treated as confident semantic inputs.

Pass1153 update: Refined_Global / Refined_Depends body/spec conformance is represented as a deterministic semantic legality layer consuming flow-effect graph rows and repaired coverage feedback.

Pass1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.

Pass1156 release note: verify Global/Depends and Refined_Global/Refined_Depends contract legality consumes refined-flow consumer blockers before exposing confident semantic conclusions.

Pass1186 update:
- Added Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality.
- Final cross-unit semantic closure now preserves blocker families from integrated closure, overload/type-edge precision, generic replay backmapping, discriminant/variant consumers, final accessibility master/scope evidence, final elaboration evidence, final tasking/protected effects, representation/freezing CPD evidence, contract/predicate/dataflow evidence, Refined_Global/Depends conformance, unit completion/order, renaming/alias/visibility, and exception/finalization legality.
- Added Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality_Pass1186 and registered it in the core AUnit suite.

Pass1187 note: Added Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality. Renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions now have construct-specific parser/AST repair legality rows. These rows require parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers before repaired coverage can restore confident semantic conclusions.

### Pass1194 final semantic diagnostic integration

Pass1194 adds blocker-preserving final semantic diagnostic integration. It consumes final semantic closure and consumer evidence, withholds legal rows as non-diagnostics, and keeps stale, AST repair, coverage-gate, view-barrier, indeterminate, and multiple-blocker states distinct. It does not add UI projection, render parsing, command routing, keybinding routing, workspace mutation, or file lifecycle mutation.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1216: Added Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality. The final shared-state semantic chain now has cross-unit closure across abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, and tasking/protected shared-state evidence. Dependency, view, state-visibility, generic body/backmapping, volatile/atomic ordering, shared-variable, representation-effect, tasking-effect, fingerprint, multiple-blocker, and indeterminate states remain distinct blocker families.

Pass1220 note: shared-state recheck application now gates current shared-state conclusions on eligible prerequisite evidence or explicitly current non-diagnostic stabilized evidence.  Dependency, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers stay withheld with blocker-family identity preserved.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.
### Pass1225 - Volatile/atomic representation consumer legality

Pass1225 adds `Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality`. It connects volatile/atomic/shared-state legality to representation consumers for volatile full-access objects, atomic components, independent components, representation clauses, record layout, stream and operational attributes, protected/task shared-object representation, and shared-passive layout. It preserves blocker-family identity for volatile/atomic evidence, representation/freezing evidence, abstract-state consumers, stabilized closure, local volatile/atomic representation errors, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225`.


### Pass1226 - Dispatching Global/Depends refinement legality

Pass1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226`.

Pass1227: Added generic abstract/refined-state replay legality for generic bodies and nested instantiations, preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family identity.


Pass1229: Representation/generic/shared-state final legality

Adds Editor.Ada_Representation_Generic_Shared_State_Final_Legality. The pass consumes final representation/freezing hard-case evidence, representation/shared-state evidence, generic abstract-state replay, overload/generic shared-state final evidence, volatile/atomic representation consumers, and stabilized shared-state closure before accepting representation/freezing conclusions. It preserves blocker-family identity for final representation, representation/shared-state, generic replay, overload/generic shared state, volatile/atomic representation, stabilized closure, private/full-view freezing, generic formal freezing, stream/operational attributes, variant layout, independent components, task/protected representation, fingerprint mismatches, multiple blockers, and indeterminate states.
Pass1230: Added Editor.Ada_Tasking_Generic_Shared_State_Final_Legality, a tasking/protected generic shared-state final legality layer that consumes deep tasking, tasking shared-state, generic abstract replay, overload/generic shared-state, representation/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving blocker-family identity.

Pass1231: Confirm cross-unit generic/shared-state final closure keeps dependency, view, generic-backmapping, overload, representation, tasking, abstract-state, stabilized-closure, fingerprint, multiple-blocker, and indeterminate blocker families distinct.


### Pass1241 release checklist item

Confirm generic/shared-state final recheck eligibility preserves blocker-family identity and deterministic fingerprints.

Pass1246: overload/generic/shared-state RM edge completion adds semantic coverage for renamed primitive visibility, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric expected-context state ambiguity, and class-wide controlling-result state joins. The pass consumes stabilized generic/shared-state final closure and prior overload/generic shared-state evidence, and preserves blocker-family identity for unresolved prerequisites and fingerprints.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1257: added RM-completed generic/shared-state remediation worklist legality. The pass is semantic-only and orders prerequisite blockers for the completed RM chain before recheck eligibility may trust downstream conclusions.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1263 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality. Stable RM-completion rows from the generic/shared-state stabilization gate now become first-class closure evidence, while blocked rows remain closure blockers with the original blocker-family identity preserved.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
