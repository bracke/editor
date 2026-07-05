Editor IDE-grade outline/semantic language model — pass394

Focus
- Continue bounded executable expression/name binding completeness after pass393.

Implemented
- Added Binding_Case_Expression_Selector and Binding_Case_Expression_Choice to Editor.Ada_Language_Model.
- Parser-owned executable expression scanning now retains simple Ada case-expression selector and choice names, e.g.:
  X := (case State is when Ready => Count, when Done => Last, when others => 0);
- Case-expression selector/choice metadata is distinct from statement-level Binding_Case_Choice.
- Semantic colouring can consume retained selector/choice names as safe value-like executable metadata.
- Added Test_Language_Model_Executable_Case_Expression_Bindings.

Conservative limits
- No full Ada case-expression legality checking.
- No full expression AST construction.
- Complex choice expressions remain source metadata only when they cannot be reduced to a leading name.
- others choices are deliberately not turned into symbols.
