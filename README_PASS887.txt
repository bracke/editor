Editor Phase 579 Pass887
========================

This pass improves structural Ada parser coverage for broader aspect placement.

Implemented:

* Production_Package_Declaration_Aspect_Specification
* Production_Package_Body_Aspect_Specification
* Production_Task_Declaration_Aspect_Specification
* Production_Task_Body_Aspect_Specification
* Production_Protected_Declaration_Aspect_Specification
* Production_Protected_Body_Aspect_Specification
* Production_Private_Type_Aspect_Specification
* Production_Generic_Declaration_Aspect_Specification
* Test_Language_Model_Token_Cursor_Aspect_Placement_Breadth_Pass887

The new metadata distinguishes where an attached aspect specification appears
without changing the existing aspect association, aspect mark, contract aspect,
or value-expression productions.

This improves structural grammar coverage for Ada aspect placement families. It
is not compiler-grade aspect legality checking, representation aspect
validation, contract legality checking, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.
