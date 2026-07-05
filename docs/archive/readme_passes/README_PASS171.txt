pass 171 — project-wide language-index workflow integration

This pass implements missing item 2 from the status analysis: project-wide indexing is no longer only package-level or active-buffer-only.

Changes:
- Added Executor.Refresh_Project_Language_Index.
- outline.refresh-project-index now refreshes known project Ada files (.ads/.adb) using Editor.Project.Refresh_Known_Files.
- semantic.refresh-project-index now refreshes the same project index and updates active-buffer semantic colouring from the immutable active snapshot.
- Project file reads use Editor.Files.Open_File and do not save, reload, or dirty buffers.
- The active file uses the active immutable buffer text when its project path matches, so unsaved edits are indexed for the current buffer without writing to disk.
- Non-Ada files are skipped; read errors are counted and reported instead of aborting the full refresh.
- The transient index is cleared before explicit refresh and remains bounded by Editor.Ada_Project_Index.Max_Index_Files.
- Command descriptions, command-surface tests, docs, and release_check guards were updated.

No Python or shell scripts were added.
