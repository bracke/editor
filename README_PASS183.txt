Editor Phase 579 - IDE-grade outline/semantic language model pass 183

Completeness pass focused on Ada project-index lifecycle invalidation.

Changes:
- Hardened Editor.Ada_Project_Index.Invalidate_Path.
- Exact path invalidation now normalizes path separators and trailing separators,
  matching the existing subtree invalidation behavior.
- Added Same_Path helper around the existing normalized path predicate.
- Added regression coverage to Test_Project_Index_Invalidates_Buffer_And_Path.
- Updated outline, syntax-colouring, commands docs, and release_check guards.

Rationale:
Active-buffer lifecycle hooks may pass platform-native path spellings while
explicit project index refresh may retain normalized project/file spellings.
The exact invalidation path must still remove stale indexed Ada analysis rows.

Verification:
- GNAT/gprbuild/AUnit were not available in this environment, so the Ada build
  and test suite were not run here.
- No Python or shell scripts were added to the project.
