Editor IDE-grade Outline / semantic-colouring language-model pass 197

Focus
- Implemented nr 5 from the remaining-gap list: make GNAT/AUnit verification explicit and repeatable inside the project instead of leaving it only as an external manual note.

Changes
- Added tools/language_validation_check.adb.
- Added the new Ada tool to tools/editor_tools.gpr.
- Extended tools/release_check.adb to require, program-error-guard, document, and run the new gate.
- Documented the strict validation command in docs/release/RELEASE_CHECKLIST.md.
- Added pass notes to README.md, docs/outline.md, and docs/syntax_colouring.md.

Behavior
- Non-strict mode: performs phase-specific static contract checks and skips the GNAT/AUnit execution step when gprbuild is unavailable.
- Strict mode: EDITOR_REQUIRE_LANGUAGE_VALIDATION=1 requires gprbuild, builds tests/tests.gpr, and runs tests/bin/tests.
- No shell scripts, Python scripts, external parser generators, or rendering-side parsing were added.

Local validation in this environment
- Static file checks were performed.
- GNAT/AUnit execution could not be performed here because gprbuild/GNAT are not installed.
