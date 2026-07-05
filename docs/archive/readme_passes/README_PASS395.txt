Pass 395 - executable conditional-expression binding completeness

Implemented one more bounded executable expression/name binding pass.

Changes:
- Added Binding_Conditional_Expression_Condition to Editor.Ada_Language_Model.
- Added Binding_Conditional_Expression_Branch to Editor.Ada_Language_Model.
- Parser-owned executable expression scanning now retains simple Ada conditional-expression metadata such as:

     X := (if Ready then Count else Last);

- Conditional-expression condition and branch names remain distinct from statement-level Binding_Condition_Target entries.
- Semantic colouring can consume the new conditional-expression metadata where safe.
- Added Test_Language_Model_Executable_Conditional_Expression_Bindings.
- Updated README, outline/syntax-colouring docs, release checklist, and release/validation guard notes.

Still conservative:
- No GNAT-equivalent conditional-expression legality checking.
- No full expression AST construction.
- Complex or unresolved condition/branch expressions degrade without guessed targets.
