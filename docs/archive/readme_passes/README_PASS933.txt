# Editor Pass933

Pass933 improves structural Ada grammar recovery for use clauses.

The token cursor now records `Production_Use_All_Missing_Type_Recovery_Boundary` when a malformed `use all ...;` clause omits the required `type` keyword, while still retaining subtype-mark list metadata for the following name. It also records `Production_Use_Clause_Reserved_Name_Recovery_Boundary` when a use-clause name list reaches a reserved declaration/package boundary where a package name or subtype mark was expected.

The regression test is `Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth_Pass933`.

This improves structural grammar coverage for use-clause recovery. It is not compiler-grade visibility legality checking, subtype-mark legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.
