Phase 579 IDE-grade Outline/Semantic Colouring - pass 147

This pass hardens the Ada language model child traversal API.

Changes:
- Editor.Ada_Language_Model.Child_Count now rejects parent ids that are not
  symbols owned by the current Analysis_Result.
- Editor.Ada_Language_Model.Child_At now applies the same invalid-parent guard
  and degrades to No_Symbol.
- Added AUnit coverage for malformed child metadata attached to an invalid
  parent id.
- Updated outline and semantic-colouring documentation.
- Extended tools/release_check.adb guards for the source, test, and docs.

No Python or shell scripts were added to the project.
