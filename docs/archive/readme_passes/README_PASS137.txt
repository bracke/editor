Editor pass 137 — project-index lifecycle invalidation hardening

Scope
- Continue the IDE-grade Outline / semantic-colouring language-analysis phase from pass 136.
- Keep the change source-backed and bounded: no new parser surface, no placeholders, no UI/rendering coupling.

Implemented
- Fixed Editor.Ada_Project_Index.Invalidate_Lifecycle so it deletes exactly one matching element per loop iteration and then rechecks the shifted vector position.
- Removed the erroneous second Delete(I), which could remove an unrelated survivor entry or fail when the matching lifecycle entry was the last indexed file.
- Added Test_Project_Index_Lifecycle_Invalidation_Removes_All_Matching_Files covering two adjacent stale lifecycle files plus one survivor generation.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 137 lifecycle-index invalidation notes.
- Extended tools/release_check.adb guards for the source fix, test, and docs.

Validation
- The archive contains no added Python or shell scripts.
- Ada build/AUnit execution was not run in this environment because GNAT/gprbuild is unavailable.
