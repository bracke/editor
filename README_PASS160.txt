Phase 579 IDE-grade outline/semantic language model pass 160

Source changes:
- Hardened Editor.Ada_Project_Index qualified-name construction.
- Project-index selected-name lookup now bounds Parent_Symbol walking by the retained analysis size.
- Cyclic or impossible parent-symbol chains degrade to local spelling instead of recursing indefinitely or fabricating dotted targets.

Tests/docs/release guards:
- Added Test_Project_Index_Cyclic_Parent_Chain_Degrades.
- Updated Outline and semantic-colouring documentation with pass 160 notes.
- Extended tools/release_check.adb guards for the project-index hardening, regression test, and docs.

Validation:
- GNAT/gprbuild is not available in this environment, so the Ada build/AUnit suite was not run here.
- No Python or shell scripts were added to the project.
