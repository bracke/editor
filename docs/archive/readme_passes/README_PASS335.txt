Editor pass335 — token-cursor grammar completeness pass

Starting point:
- editor_ide_grade_outline_semantic_language_model_pass334.zip

Implemented:
- Expanded Editor.Ada_Token_Cursor with detailed Ada grammar production events for parameter profiles/specifications, generic formal declarations, discriminant parts/specifications, enumeration definitions/literals, record definitions, component declarations, variant parts/variants, selected names, indexed components/calls, attribute references, aggregates, conditional expressions, case expressions, quantified expressions, and qualified-expression markers.
- Improved tokenization of apostrophe so Ada attribute references such as Obj'Length are not mis-tokenized as character literals; character literals such as 'X' remain character-literal tokens.
- Added token-cursor parsing for type discriminant parts, enumeration literal lists, record component declarations, variant parts, variant alternatives, and object-default expressions.
- Added token-cursor parsing for subprogram parameter profiles and parameter specifications.
- Added generic-formal production retention in generic formal parts.
- Added AUnit coverage: Test_Language_Model_Token_Cursor_Grammar_Completeness_Details.
- Extended tools/language_validation_check.adb guards for the detailed token-cursor grammar productions.
- Updated documentation markers for the broader token-cursor grammar layer.

Validation notes:
- Output zip validates cleanly.
- Node_Kind has no duplicate enumerators.
- No .py, .pyc, or .sh files are present.
