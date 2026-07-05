Pass 165 - child parent/scope consistency guard

This pass hardens Editor.Ada_Language_Model child traversal.

Changes:
- Added a private Is_Direct_Child helper in editor-ada_language_model.adb.
- Child_Count and Child_At now require both Parent_Symbol and Enclosing_Scope to agree for direct child enumeration.
- Malformed rows with Parent_Symbol pointing at one declaration but Enclosing_Scope pointing at another are no longer exposed as Outline/semantic child rows.
- Added Test_Language_Model_Child_Lookup_Requires_Matching_Scope.
- Updated outline and semantic-colouring documentation.
- Extended tools/release_check.adb guards.

No Python or shell scripts were added to the project.
