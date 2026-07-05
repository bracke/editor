IDE-grade outline / semantic colouring pass 140

Implemented in this archive:

- Hardened Editor.Ada_Project_Index.Fingerprint so aggregate project-index stamps include the indexed file path.
- Added a deterministic local Hash_String helper for project-index path contribution.
- Added Test_Project_Index_Fingerprint_Includes_Path, proving that two path-distinct indexed analyses with identical buffer token, revision, lifecycle generation, and analysis fingerprint no longer collapse to the same project-index fingerprint.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 140 notes.
- Extended tools/release_check.adb guards for the source, test, and documentation changes.

Rationale:

Before this pass, Recompute only mixed buffer token, buffer revision, lifecycle generation, and per-analysis fingerprint. Path-distinct indexed files with identical source and ownership counters could produce the same aggregate index fingerprint. That weakened stale-target/status/navigation detection because the project index did not fully represent the file identity it stored.

Validation note:

GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here. No Python or shell scripts were added to the project.
