Editor — Pass896
==========================

This pass improves structural Ada grammar coverage for malformed generic actual
association lists.

Changed productions:

* Added Production_Generic_Actual_Missing_Actual_Recovery_Boundary.
* Added Production_Generic_Actual_Trailing_Separator_Recovery_Boundary.
* Added Production_Generic_Actual_Empty_List_Recovery_Boundary.

Parser/token-cursor changes:

* `new G ()` now records empty generic actual-list recovery metadata.
* `new G (T =>, Default => 1)` now records missing generic actual value
  recovery metadata.
* `new G (Integer,)` now records trailing separator recovery metadata.
* Existing generic actual part, association, separator, close delimiter,
  generic recovery, and following declaration metadata are preserved.

Regression coverage:

* Added Test_Language_Model_Token_Cursor_Generic_Actual_Association_Recovery_Pass896.

This improves structural grammar coverage only. It is not compiler-grade generic
contract legality checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.
