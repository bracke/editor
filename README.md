## Ada release tools

Release and validation tooling is implemented as Ada programs in `tools/` and
built through `tools/editor_tools.gpr`. Shell and Python release wrappers are
not part of the shipped tool surface; use the corresponding `tools/bin/*`
commands after building the tool project. Release evidence reports use bounded
merged stdout/stderr capture through the shared Ada helpers.
The language-analysis release guard is `tools/bin/language_validation_check`.

The AUnit tests are split into explicit slices. During normal development, run
only the slice that matches the changed surface, for example
`tools/bin/unit_tests editor-core`, `tools/bin/unit_tests editor-ui`,
`tools/bin/unit_tests project-workspace`, `tools/bin/unit_tests build-tools`,
`tools/bin/unit_tests ada-language`, or `tools/bin/unit_tests text`. The full
`tools/bin/unit_tests all` aggregate is reserved for release validation through
`All_Suites`.

The graphical runtime smoke gate is bounded inside the runtime: `tools/bin/runtime_smoke`
passes `--runtime-smoke-max-seconds` to `bin/editor` instead of relying on an
external timeout utility.

Build process-control platform scope is documented in
`docs/release/BUILD_PROCESS_PLATFORM_SUPPORT.md`.

Testing policy and slice selection are documented in `docs/testing.md`.
Use `tools/bin/test_commands_for <changed-path>...` to choose the relevant
development unit-test slices and focused smoke gates. Historical pass notes are
archived under `docs/archive/`; current release gates are documented in
`docs/release/RELEASE_CHECKLIST.md`. Editor workflow contracts for status
surfaces, pending transitions, render packets, focused smokes, and test
selection are documented in `docs/editor_workflow_contracts.md`.
