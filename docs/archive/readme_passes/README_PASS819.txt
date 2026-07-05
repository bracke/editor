Pass819 - Record representation delimiter and recovery depth

Pass819 deepens Ada record representation clause metadata. Record representation clauses now retain explicit record-block open/close delimiter productions, separator metadata for component/mod clauses, and a bounded missing-close recovery production when a record representation clause reaches a bare end without the required record keyword. Existing mod-clause, component-clause, position, first-bit, last-bit, and component recovery metadata remains intact.

Changed:
- Added `Production_Record_Representation_List_Open_Delimiter`.
- Added `Production_Record_Representation_List_Close_Delimiter`.
- Added `Production_Record_Representation_Component_Separator`.
- Added `Production_Record_Representation_Missing_Close_Recovery_Boundary`.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Record_Representation_Delimiters_Pass819`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, and validation guards.

This improves structural grammar coverage for Ada record representation clause delimiters, component separators, and missing-close recovery. It is not compiler-grade record layout legality checking, component-position validation, bit-range validation, representation value validation, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
