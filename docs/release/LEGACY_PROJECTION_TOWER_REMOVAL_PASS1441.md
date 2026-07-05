# Legacy Projection Tower Removal Case 1441

Case 1441 continues the finite legacy cleanup after the case 1440 scaffold inventory.

## Removed active surfaces

The pass removes the obsolete diagnostic command/palette/keybinding/workspace/render projection tower and the corresponding recovery/render recovery tower. These packages were historical projection scaffolds from the pre-closure diagnostic phase and are superseded by the canonical semantic diagnostic/feed consumers and the project-scale closure gates through case 1436.

Removed source packages:

- `Editor.Ada_Diagnostic_Command_Palette_Projection`
- `Editor.Ada_Diagnostic_Keybinding_Hint_Projection`
- `Editor.Ada_Diagnostic_Workspace_Projection`
- `Editor.Ada_Diagnostic_Render_Projection`
- `Editor.Ada_Diagnostic_Lifecycle_Recovery`
- `Editor.Ada_Diagnostic_Recovery_Status`
- `Editor.Ada_Diagnostic_Recovery_Action_Projection`
- `Editor.Ada_Diagnostic_Recovery_Command_Projection`
- `Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection`
- `Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection`
- `Editor.Ada_Diagnostic_Recovery_Workspace_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Lifecycle`
- `Editor.Ada_Diagnostic_Recovery_Render_Status`
- `Editor.Ada_Diagnostic_Recovery_Render_Action_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Command_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection`
- `Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection`

Matching obsolete AUnit packages from case 1077 through case 1095 were removed with the source tower.

## Cleanup gates

`Editor.Ada_Legacy_Projection_Tower_Removal_Case 1441` records a deterministic removal ledger. It rejects:

- active source files that still expose a removed projection package,
- active test files for the removed packages,
- lingering suite registrations,
- dangling dependent source units,
- noncanonical replacement projection surfaces,
- reopened `Remaining_*` gaps after case 1428,
- stale source/test/removal fingerprints.

## Canonical replacement

No new command-palette/keybinding/workspace/render semantic projection layer is introduced by this pass. Canonical production surfaces remain the semantic model, diagnostic feed, and project-scale validation/closure gates established before case 1441.
