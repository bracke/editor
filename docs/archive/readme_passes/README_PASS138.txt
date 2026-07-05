IDE-grade outline/semantic colouring pass 138

Focus:
- Tighten project language-index overflow reporting.

Changes:
- Updated Editor.Ada_Project_Index.Overflowed to include per-file Ada_Language_Model.Overflowed values, not only the file-table overflow flag.
- Added Test_Project_Index_Overflowed_Includes_Analysis_Overflow to prove aggregate overflow is visible without first resolving a name.
- Updated outline and syntax-colouring documentation with pass 138 notes.
- Extended release_check guards for the new source/test/doc coverage.

Validation note:
- GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here.
- No Python or shell scripts were added to the project.
