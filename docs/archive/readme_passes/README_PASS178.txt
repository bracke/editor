Editor IDE-grade Outline/Semantic Colouring - pass 178

This pass completes a safety gap in the separate-body Outline navigation path.

Changes:
- Added Editor.Ada_Language_Model.Is_Separate_Body_Parent_Target.
- Refactored outline.goto-spec separate-body parent navigation to use that shared predicate.
- Rejects object/component/literal/body/separate-body rows as parent targets even when Target_Name matches.
- Added AUnit coverage for valid and invalid separate-body parent target kinds.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and release_check guards.

GNAT/gprbuild/AUnit were not available in this environment, so build execution was not performed here.
