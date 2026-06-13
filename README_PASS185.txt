Phase 579 pass 185 completeness pass

This pass tightens the explicit project language-index refresh introduced in pass 184.

Changes:
- Adds Editor.Ada_Project_Index.Contains_Path with normalized path comparison.
- Makes Contains_Current and current-stamped lookup path checks use normalized path comparison.
- Changes Refresh_Project_Language_Index so active/open Ada buffers are indexed before disk/project-file rows.
- Skips disk rows whose normalized path is already represented by an editor-owned open-buffer snapshot.
- Adds regression coverage for normalized current/path containment and current symbol lookup.
- Updates Outline, semantic-colouring, commands documentation, and release_check guards.

Rationale:
Open buffers may contain unsaved source. Explicit project-index refresh must not let a large disk project fill the bounded index before unsaved open-buffer analyses are inserted, and must not later replace those rows with stale disk contents.

Build note:
GNAT/gprbuild/AUnit were not available in this environment, so the Ada suite was not executed here.
