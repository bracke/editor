Pass 362 — cross-file Ada unit relationship indexing

Implemented a first-class Ada unit table in Editor.Ada_Project_Index.

Changes:
- Added bounded unit-index state keyed by normalized Ada unit name.
- Added Indexed_Unit_Role and Indexed_Unit records for package specs, private package specs, package bodies, subprogram specs, subprogram bodies, and separate bodies.
- Added Resolve_Unit, Resolve_Unique_Unit_Target, Resolve_Related_Unit_Target, Resolve_Separate_Parent_Target, and Unit_Count.
- Rebuilt unit rows deterministically from retained file analyses after every index mutation so path/buffer/revision/lifecycle invalidation clears stale unit targets with their source file row.
- Unit lookup is case-insensitive and role-aware; duplicate unit targets degrade through the existing Unique_Target_Result ambiguity path.
- Separate bodies are indexed by their retained parent unit name so a separate subunit can resolve back to the indexed parent package/subprogram declaration when present.
- Added AUnit regression coverage through Test_Project_Index_Cross_File_Unit_Relationship_Table.
- Extended phase579_language_validation_check and release_check guard comments for the new unit relationship architecture.

Still conservative:
- No automatic project-wide source discovery is added.
- Duplicate Ada unit names remain ambiguous instead of guessed.
- Unit pairing only uses retained parser/index data; missing unindexed files remain unavailable.
- This does not implement GNAT-equivalent visibility, legality checking, or build-configuration-specific unit selection.
