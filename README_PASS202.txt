Editor Phase 579 pass 202

Completeness focus: normalized execution-time path handling for indexed Outline body/spec navigation.

Changes:
- `Navigate_To_Indexed_Outline_Target` now compares the active editor file path and the retained indexed target path using normalized root-path spelling.
- Exact `Editor.Ada_Project_Index.Indexed_File_Key` revalidation remains mandatory before navigation.
- Open-buffer target revalidation still checks buffer token, revision, lifecycle generation, retained analysis fingerprint, and normalized path.
- Extended the target-key regression test with equivalent path spelling coverage.
- Extended the Phase 579 validation gate and documentation.

Validation in this environment:
- Static checks only; GNAT/gprbuild/AUnit are unavailable here.
- Archive integrity was checked.
- No Python or shell scripts were added to the project.
