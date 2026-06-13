Pass1441: Phase579 legacy projection tower removal

This pass implements the second legacy-cleanup project-scale item after the pass1440 scaffold inventory.

Removed from the active tree:

* Editor.Ada_Diagnostic_Command_Palette_Projection
* Editor.Ada_Diagnostic_Keybinding_Hint_Projection
* Editor.Ada_Diagnostic_Workspace_Projection
* Editor.Ada_Diagnostic_Render_Projection
* Editor.Ada_Diagnostic_Lifecycle_Recovery
* Editor.Ada_Diagnostic_Recovery_Status
* Editor.Ada_Diagnostic_Recovery_Action_Projection
* Editor.Ada_Diagnostic_Recovery_Command_Projection
* Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection
* Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection
* Editor.Ada_Diagnostic_Recovery_Workspace_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Lifecycle
* Editor.Ada_Diagnostic_Recovery_Render_Status
* Editor.Ada_Diagnostic_Recovery_Render_Action_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Command_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection
* Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection

Matching obsolete tests from pass1077 through pass1095 were also removed.

Added:

* Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441
* Test_Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441
* docs/release/LEGACY_PROJECTION_TOWER_REMOVAL_PASS1441.md

The new pass rejects active source/test references to the removed tower, lingering Core_Suite references, dangling dependent source, noncanonical replacements, reopened Remaining_* gaps, and stale removal fingerprints.
