Editor — Pass925

This pass improves structural Ada grammar recovery for malformed named-number declarations where the required initialization expression after `:=` is replaced by a reserved/aspect boundary.

Implemented:
- Added `Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary`.
- Added parser-owned boundary detection for named-number initialization expressions.
- Avoided treating `with`, `then`, `else`, `elsif`, `or`, `when`, `exception`, `do`, `end`, punctuation separators, and delimiters as named-number initialization expressions.
- Preserved number declaration metadata, valid following initializer metadata, broader recovery metadata, and generic recovery metadata.
- Added AUnit regression coverage in `Test_Language_Model_Token_Cursor_Number_Initialization_Reserved_Boundary_Recovery_Pass925`.
- Updated validation guard comments, parser coverage documentation, syntax-colouring notes, release checklist, and README.

This improves structural grammar coverage for malformed Ada named-number initialization expressions. It is not named-number legality checking, static-expression validation, universal type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
