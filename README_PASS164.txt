Editor Phase 579 pass 164

This pass consolidates declaration-owner classification in the Ada language model.

Changes:
- Added Editor.Ada_Language_Model.Is_Declaration_Owner.
- Refactored language-model child traversal and overload scope validation to use the shared predicate.
- Refactored project-index qualified-name construction to use the shared predicate instead of its own private owner-kind list.
- Added Test_Language_Model_Declaration_Owner_Predicate_Is_Canonical.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 164 notes.
- Extended tools/release_check.adb guards.

The pass does not add Python or shell scripts.
