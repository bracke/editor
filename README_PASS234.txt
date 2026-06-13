Pass 234 — abstract declaration detail projection

This pass retains parser-owned abstract declaration metadata in Outline details. The Ada language model already preserves Is_Abstract; Outline now projects that flag so abstract procedures/functions and abstract type forms are visible in navigation rows without adding duplicate symbols or parser-side legality checks.

Updated areas:
- src/core/editor-outline_extractor.adb
- tests/src/editor-outline-tests.adb
- tools/phase579_language_validation_check.adb
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- README.md
