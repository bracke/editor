Editor Phase 579 pass 365
=========================

Focus
-----
Completeness pass for cross-file Ada unit relationship indexing.

Implemented
-----------
- Added Editor.Ada_Project_Index.Resolve_Unit_Family.
- The new API returns all indexed rows for the normalized Ada unit identity of a validated starting unit target.
- Supports role filtering for callers that want only specs, bodies, separate bodies, etc.
- Uses the first-class Ada unit table rather than file-path scans or leaf-name symbol scans.
- Preserves duplicate family rows for caller-side disambiguation.
- Propagates index/unit overflow through Unit_Resolution_Result.

Tests
-----
- Added Test_Project_Index_Unit_Family_Lists_Validated_Targets.

Docs/checks
-----------
- Updated README.md.
- Updated docs/outline.md.
- Updated docs/syntax_colouring.md.
- Updated docs/release/RELEASE_CHECKLIST.md.
- Updated tools/phase579_language_validation_check.adb.
- Updated tools/release_check.adb guard tokens.

Constraints
-----------
No Python, shell scripts, .pyc files, parser generators, rendering-side parsing,
external compiler integration, or LSP integration were added.
