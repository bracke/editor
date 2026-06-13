Editor Phase 579 pass 179

Completeness pass focused on stale analysis after ordinary text edits.

Changes:
- Ordinary text edits now invalidate transient Ada project-index rows for the active source path.
- Ordinary text edits also invalidate indexed rows for the active buffer token.
- Parser-derived semantic maps are cleared and their ownership stamps reset after a real text change.
- Outline indexed navigation and semantic colouring can no longer reuse pre-edit language analysis for a changed active buffer.
- Documentation and release guards were updated.

Build note:
- GNAT/gprbuild/AUnit were not available in this environment, so the Ada test suite was not executed here.
