Phase 579 IDE-grade Outline/Semantic Language Model - Pass 163

This pass hardens Ada language-model child traversal:

- `Editor.Ada_Language_Model.Child_Count` and `Child_At` now validate that
  the requested parent id is not only current/in-range, but also a
  declaration-owning symbol.
- Malformed parser/test data that attaches children below value-like symbols
  such as objects/components/literals is no longer exposed as an Outline or
  semantic ownership hierarchy.
- Valid declaration-owning parents such as packages still expose deterministic
  direct children.
- Added `Test_Language_Model_Non_Owner_Parent_Child_Lookup_Degrades`.
- Updated Outline and semantic-colouring documentation and release-check guards.

The Ada build/AUnit suite was not run in this environment because GNAT/gprbuild
is not installed here.
