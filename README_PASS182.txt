Phase 579 pass 182 - file lifecycle language-index integration

This pass completes the remaining file-lifecycle integration item for the Ada
project language index.

Changes:
- Added Editor.Ada_Project_Index.Invalidate_Path_Subtree.
- Active-buffer rename/move/delete now invalidate the previous backing path as
  well as the current association/token-derived language-index state.
- File Tree create/rename/delete now invalidate exact and descendant indexed
  source paths so moved/deleted/rebased project files cannot leave stale
  Outline/body/spec/semantic targets behind.
- Active semantic stamps are cleared when a File Tree mutation affects the
  active file.
- Added regression coverage for exact/descendant subtree invalidation.
- Updated docs and release guards.

No Python or shell scripts were added.
