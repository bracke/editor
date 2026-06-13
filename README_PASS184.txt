Phase 579 pass 184 - project index open-buffer overlay

Changes:
- `Refresh_Project_Language_Index` now overlays every open file-backed Ada buffer
  after the explicit project-file scan.
- Inactive open buffers are indexed from `Editor.State.Current_Text` on the
  buffer snapshot rather than from disk.
- Existing disk-indexed rows are invalidated by path before open-buffer overlay
  insertion to avoid stale duplicates caused by path spelling differences.
- The active buffer continues to use the active-state path, revision, token, and
  lifecycle generation.
- Updated Outline, semantic-colouring, command docs, and release_check guards.

Verification:
- GNAT/gprbuild/AUnit were not available in this environment, so the Ada build
  and tests were not executed here.
- No Python or shell scripts were added to the project.
