Phase 579 IDE-grade outline / semantic colouring pass 141

This pass hardens project language-index fingerprinting for bounded file-table overflow.

Changes:
- Updated Editor.Ada_Project_Index.Recompute so aggregate fingerprints include Index_Overflow.
- Updated Put_Analysis to recompute the project-index fingerprint when a new file is rejected because Max_Index_Files has been reached.
- Added Test_Project_Index_Fingerprint_Includes_Index_Overflow, which fills the index, attempts one over-budget insertion, and verifies that the index remains bounded, reports overflow, and changes fingerprint.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 141 notes.
- Extended tools/release_check.adb guards for the new source/test/doc coverage.

No Python or shell scripts were added.
