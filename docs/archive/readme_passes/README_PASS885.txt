Editor — Pass885

This pass improves structural grammar coverage for Ada pragma recovery.

Changes:

* Added Production_Pragma_Identifier_Missing_Recovery_Boundary.
* Added Production_Pragma_Argument_List_Empty_Recovery_Boundary.
* Added Production_Pragma_Argument_Trailing_Separator_Recovery_Boundary.
* Added Production_Pragma_Argument_Missing_Expression_Recovery_Boundary.
* Added Production_Pragma_Missing_Terminator_Recovery_Boundary.
* Refined Parse_Pragma and Parse_Pragma_Argument_List so malformed pragma
  forms retain pragma-specific recovery metadata instead of only generic
  recovery points.
* Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Pragma_Recovery_Depth_Pass885.
* Updated validation guard markers, README, parser coverage notes, syntax
  colouring notes, and the release checklist.

Covered malformed forms include:

   pragma ();
   pragma Assert ();
   pragma Suppress (Range_Check,);
   pragma Import (Convention => );
   pragma Pure
   Next : Integer;

This improves structural grammar coverage for Ada pragmas.  It is not
compiler-grade pragma legality checking, implementation-defined pragma
validation, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state
mutation.
