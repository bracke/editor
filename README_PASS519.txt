Pass 519 - Named value-bearing representation pragma target/value unification

This pass tightens the pragma side of the unified representation/operational
property model.

Implemented:
- Added named-target extraction for value-bearing pragmas whose entity argument
  is not necessarily the first positional argument.
- pragma Attach_Handler now binds Handler => as the declaration target even
  when Interrupt => appears first.
- pragma Linker_Section now binds Entity => as the declaration target even
  when Section => appears before Entity =>.
- pragma Machine_Attribute now binds Entity => as the declaration target even
  when Attribute_Name => appears before Entity =>.
- pragma Linker_Section now explicitly accepts Section => and Section_Name =>
  as the retained value argument before falling back to positional/value forms.
- pragma Machine_Attribute now explicitly accepts Attribute_Name => and
  Attribute => as the retained value argument before falling back to
  positional/value forms.

Regression coverage:
- Added named/out-of-order Linker_Section coverage proving Entity => is the
  target and Section => is retained as Item_Text.
- Added named/out-of-order Machine_Attribute coverage proving Entity => is the
  target and Attribute_Name => is retained as Item_Text.

Files changed:
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
