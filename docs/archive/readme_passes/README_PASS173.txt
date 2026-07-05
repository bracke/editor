IDE-grade Outline/Semantic Language Model — pass 173

This pass implements missing item 3: richer Outline navigation.

Changes:
- Added indexed Outline body/spec target discovery in Editor.Executor.
- outline.goto-body now resolves a selected package Outline row to a retained Symbol_Package_Body in the transient Ada project language index.
- outline.goto-spec now resolves a selected package-body Outline row to a retained Symbol_Package in the transient Ada project language index.
- Both commands validate the selected Outline projection row before lookup.
- Both commands route through the normal file-open/focus path and then navigate to the parser-owned source range.
- Missing, stale, absent, or over-budget index data degrades to unavailable instead of fabricating a target.
- Updated command-surface regression checks, docs, and release guards.

Limitations:
- This pass implements package spec/body pairs. Subprogram body/spec and separate-body parent navigation remain future work because the current public language-model metadata does not yet distinguish subprogram specs from bodies strongly enough for safe cross-file navigation.

Verification:
- GNAT/gprbuild/AUnit were not available in this environment, so the Ada build and test suite were not executed here.
- No Python or shell scripts were added to the project.
