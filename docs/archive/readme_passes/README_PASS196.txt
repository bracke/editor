pass 196 - completeness pass

Focus:
- Close the indexed Outline navigation overflow gap.

Changes:
- Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target now reports overflow and returns no available target when project-index or per-file analysis overflow is present.
- Separate-body outline.goto-spec parent lookup now rejects overflowed index results and duplicate retained parent candidates instead of returning the first match.
- Added Test_Project_Index_Unique_Navigation_Target_Rejects_Overflow.
- Extended release_check guards and updated Outline, syntax-colouring, command, and release checklist documentation.

Validation in this environment:
- Static source/marker checks only.
- GNAT/AUnit were not available here.
- No Python or shell project files were added.
