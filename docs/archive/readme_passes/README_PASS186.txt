pass 186

Implemented profile-aware indexed Outline callable body/spec navigation.

Changes:
- Added conservative Outline row profile extraction in Editor.Executor.
- Added profile matching for procedure/function body/spec target selection when both selected row and indexed candidate retain parser-owned profile summaries.
- Preserved previous conservative name/kind/body behavior when profile metadata is absent.
- Added project-index regression coverage proving overloaded subprogram spec/body rows retain distinct profile metadata for navigation disambiguation.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and tools/release_check.adb.

Build note:
- GNAT/gprbuild/AUnit were not available in this environment, so compile and test execution were not run here.
