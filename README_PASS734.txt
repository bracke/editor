# Editor Phase 579 pass734 — Expression/name edge-case grammar recovery

This pass continues the IDE-grade Outline / semantic-colouring Ada language-model work from pass733.

## Implemented

* Deepened token-cursor expression/name grammar metadata for edge cases around:
  * allocators that use qualified-expression initialization;
  * qualified-expression / conversion ambiguity points;
  * selected operator-literal expression names;
  * chained attributes after qualified expressions and reduction attributes;
  * slice-vs-index/call suffix ambiguity;
  * malformed reduction argument parts.
* Added explicit bounded productions:
  * `Production_Allocator_Nested_Qualified_Expression`
  * `Production_Conversion_Or_Qualified_Expression`
  * `Production_Chained_Attribute_Reference`
  * `Production_Call_Or_Indexed_Component`
  * `Production_Reduction_Argument_Recovery_Boundary`
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Expression_Name_Edge_Recovery`
* Updated validation guards to require the new productions and regression marker.

## Non-goals

This improves structural grammar coverage for Ada expression/name edge cases. It is not compiler-grade overload resolution, expected-type resolution, conversion legality checking, accessibility checking, reduction callable conformance checking, or static-expression validation.
