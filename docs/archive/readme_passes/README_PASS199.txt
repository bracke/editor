Editor IDE-grade Outline/Semantic Language Model pass 199

Implemented fix nr 6: release-guard maintainability.

Changes:
- Refactored tools/release_check.adb so language-intelligence regression protection is delegated to tools/language_validation_check.adb.
- Removed the broad duplicated marker wall from release_check.
- Expanded language_validation_check into grouped static checks for architecture, parser/model metadata, resolver/index behavior, regression test coverage, and documentation freshness.
- Kept strict GNAT/AUnit validation behavior through EDITOR_REQUIRE_LANGUAGE_VALIDATION=1.
- Updated README.md and docs/release/RELEASE_CHECKLIST.md.

Validation in this environment:
- Static marker verification for the new language_validation_check was performed.
- Confirmed release_check delegates to language_validation_check.
- Confirmed no Python or shell scripts were added.
- GNAT/AUnit could not be run because gprbuild/GNAT are unavailable here.
