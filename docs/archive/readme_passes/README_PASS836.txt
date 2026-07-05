# Editor Pass836

Pass836 improves Ada token-cursor structural grammar coverage for attribute
argument parts.

Implemented changes:

- Added `Production_Attribute_Argument_List_Open_Delimiter`.
- Added `Production_Attribute_Argument_List_Close_Delimiter`.
- Added `Production_Attribute_Argument_Association_Separator`.
- Added `Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary`.
- Updated ordinary attribute argument-list parsing to record delimiter,
  separator, and bounded missing-close metadata.
- Updated Ada 2022 reduction attribute argument parsing to share the same
  delimiter/separator/missing-close metadata while preserving reducer and
  initial-value productions.
- Added AUnit regression
  `Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836`.
- Updated parser coverage docs, syntax-colouring notes, release checklist, and
   validation guard markers.

This improves structural grammar coverage for Ada attribute argument lists. It
is not compiler-grade attribute legality checking, reduction profile conformance,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.
