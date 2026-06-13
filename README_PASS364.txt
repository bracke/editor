Editor Phase 579 — IDE-grade outline/semantic language model pass 364

Implemented direct child-unit listing in the cross-file Ada unit table.

Changes:
- Added Editor.Ada_Project_Index.Resolve_Child_Units.
- The API returns direct indexed child units for a validated parent unit through the normalized Ada unit table.
- Added optional Indexed_Unit_Role filtering so callers can request only child specs, bodies, separate bodies, etc.
- Grandchildren are intentionally excluded to support deterministic one-level-at-a-time unit tree/navigation views.
- Overflowed file analyses, index overflow, and unit-table overflow degrade through Unit_Resolution_Result.Overflow rather than returning potentially stale/partial child rows.
- Added regression coverage: Test_Project_Index_Parent_Lists_Direct_Child_Units.

No Python, shell scripts, .pyc files, parser generators, rendering-side parsing, external compiler integration, or LSP integration were added.
