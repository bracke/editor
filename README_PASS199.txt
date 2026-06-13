Editor Phase 579 IDE-grade Outline/Semantic Language Model pass 199

Implemented fix nr 6: release-guard maintainability.

Changes:
- Refactored tools/release_check.adb so Phase 579 language-intelligence regression protection is delegated to tools/phase579_language_validation_check.adb.
- Removed the broad duplicated Phase 579 marker wall from release_check.
- Expanded phase579_language_validation_check into grouped static checks for architecture, parser/model metadata, resolver/index behavior, regression test coverage, and documentation freshness.
- Kept strict GNAT/AUnit validation behavior through EDITOR_REQUIRE_PHASE579_LANGUAGE_VALIDATION=1.
- Updated README.md and docs/release/RELEASE_CHECKLIST.md.

Validation in this environment:
- Static marker verification for the new phase579_language_validation_check was performed.
- Confirmed release_check delegates to phase579_language_validation_check.
- Confirmed no Python or shell scripts were added.
- GNAT/AUnit could not be run because gprbuild/GNAT are unavailable here.
