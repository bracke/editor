Editor IDE-grade outline/semantic language-model pass363

Starting point: pass362.

Implemented child-unit parent relationship indexing on top of the cross-file Ada unit table.

Changes:
- Added Editor.Ada_Project_Index.Resolve_Parent_Unit_Target.
- Added a bounded Parent_Unit_Name helper in the project-index body.
- Parent lookup derives the parent name from the indexed unit identity, e.g. Parent.Child -> Parent.
- Parent lookup resolves through Resolve_Unique_Unit_Target with Unit_Package_Spec, so missing, duplicate, stale, or overflowed parent rows degrade conservatively.
- Added Test_Project_Index_Child_Unit_Parent_Relationship_Target.
- Updated README/docs/release guards.

No Python, shell scripts, .pyc files, parser generators, rendering-side parsing, or external compiler/LSP integration were added.
