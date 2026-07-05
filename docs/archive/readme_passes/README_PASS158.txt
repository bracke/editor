IDE-grade Outline/Semantic Colouring — pass 158

This pass tightens the shared Ada language model overload-scope API for generic formal packages.

Changes:
- `Editor.Ada_Language_Model.Valid_Scope` now treats `Symbol_Generic_Formal_Package` as a declaration-owning scope.
- This preserves the pass 157 guard against value-like/non-owner symbols while allowing nested declarations retained below generic formal package symbols to expose deterministic overload sets.
- Added `Test_Language_Model_Generic_Formal_Package_Owns_Overload_Scope`.
- Updated Outline and semantic-colouring documentation.
- Extended `tools/release_check.adb` guards.

Validation:
- No Python or shell scripts were added.
- GNAT/gprbuild is not available in this environment, so the Ada build and AUnit suite were not executed here.
