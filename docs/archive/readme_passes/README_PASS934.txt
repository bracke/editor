# Editor Pass934

Pass934 improves structural Ada grammar recovery for representation and operational items.

The token cursor now records `Production_Representation_Target_Reserved_Boundary_Recovery_Boundary` when a representation target reaches a declaration boundary before `use` or an attribute designator, `Production_Representation_Clause_Missing_Use_Recovery_Boundary` for ordinary `for ...` items without `use`, and `Production_Attribute_Definition_Missing_Designator_Recovery_Boundary` for malformed attribute-definition clauses such as `for Obj' use ...`. Address clauses now reuse the existing missing-value recovery at broader reserved boundaries after `use at`, and enumeration representation clauses now record `Production_Enumeration_Representation_Reserved_Association_Recovery_Boundary` when an association list reaches a declaration/private boundary before a valid association or closing delimiter.

The regression test is `Test_Language_Model_Token_Cursor_Representation_Item_Recovery_Depth_Pass934`.

This improves structural grammar coverage for representation and operational item recovery. It is not compiler-grade representation legality checking, freezing-rule checking, layout validation, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
