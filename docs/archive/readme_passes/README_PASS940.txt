Editor pass940 — Name grammar recovery depth

Implemented structural name grammar recovery refinements in the Ada token cursor.

Changed:
- Added Production_Selected_Name_Reserved_Selector_Recovery_Boundary for selected-name dots followed by reserved/declaration boundaries.
- Added Production_Allocator_Missing_Subtype_Recovery_Boundary for allocators that reach a boundary immediately after `new`.
- Added Production_Qualified_Expression_Missing_Operand_Recovery_Boundary for qualified-expression and allocator-qualified-expression operand lists that are empty or begin at a boundary.
- Preserved selected operator-symbol and character-literal selector metadata through the new recovery paths.
- Added AUnit regression Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth_Pass940.
- Updated parser coverage, syntax-colouring notes, validation guard notes, release checklist, and README.

Scope:
This improves structural grammar coverage for selected names, allocator forms, and qualified-expression recovery. It is not compiler-grade selected-name legality checking, allocator subtype legality checking, qualified-expression operand legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.
