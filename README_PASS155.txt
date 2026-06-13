Editor Phase 579 — IDE-grade Outline/Semantic Language Model Pass 155

Base archive:
editor_phase579_ide_grade_outline_semantic_language_model_pass154.zip

Changes in this pass:
- Hardened Editor.Ada_Language_Model.Child_Count.
- Hardened Editor.Ada_Language_Model.Child_At.
- Malformed self-parent edges are no longer exposed as real child rows.
- Real nested children under the same parent remain visible in deterministic declaration order.
- Added Test_Language_Model_Self_Parent_Child_Lookup_Degrades.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 155 notes.
- Extended tools/release_check.adb guards for the pass 155 source, test, and documentation.

Validation note:
- GNAT/gprbuild are not available in this environment, so the Ada build and AUnit suite were not executed here.
- No Python or shell scripts were added to the project.
