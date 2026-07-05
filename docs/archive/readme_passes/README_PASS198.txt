pass 198 — documentation/validation consistency completeness pass

Changes:
- Updated docs/syntax_colouring.md so the main semantic-colouring section describes parser-owned Ada_Language_Model analysis as the preferred product source instead of saying semantic colouring primarily performs local declaration extraction.
- Updated docs/outline.md known limits so representation clauses and generated/conditional source awareness match the current bounded metadata implementation from pass 195.
- Extended tools/language_validation_check.adb to reject stale local-only/safe-skip documentation wording.
- Updated README.md with the pass 198 note.

Validation performed in this environment:
- Confirmed the stale phrases are absent from docs/src/tools.
- Confirmed no Python or shell scripts were added.
- Confirmed archive integrity after packaging.

GNAT/AUnit were not run here because gprbuild/GNAT are unavailable in this environment. Use the pass 197 strict gate on a proper Ada toolchain host:

EDITOR_REQUIRE_LANGUAGE_VALIDATION=1 tools/bin/language_validation_check
