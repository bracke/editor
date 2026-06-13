Editor Phase 579 pass390

Implemented another bounded executable expression/name binding completeness pass.

Changes:
- Added Binding_Range_Bound to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains names used as range bounds in executable contexts:
  * for-loop discrete ranges, e.g. for I in First .. Last loop
  * array slice ranges, e.g. Values (First .. Last)
- Range-bound bindings are distinct from Binding_Iteration_Source and Binding_Array_Slice.
- Unknown/non-name bounds remain unbound; no guessed symbols are introduced.
- Added Test_Language_Model_Executable_Range_Bound_Bindings.
- Updated docs and release/static guards.

Still conservative:
- No GNAT-equivalent discrete range legality checking.
- No full subtype/range static evaluation for executable ranges.
- No rendering-side parsing, external compiler/LSP integration, Python, shell scripts, .pyc, or parser generators.
