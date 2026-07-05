Editor — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass875

Pass875 improves structural Ada token-cursor grammar coverage for use-clause recovery.

Implemented changes:

* Added Production_Use_Clause_Missing_Name_Recovery_Boundary.
* Added Production_Use_Clause_Trailing_Separator_Recovery_Boundary.
* Added Production_Use_Clause_Missing_Terminator_Recovery_Boundary.
* Extended Parse_Visibility_Name_List / Parse_Use_Clause so malformed ordinary use clauses, use type clauses, and use all type clauses expose use-clause-specific recovery metadata while preserving the older generic Production_Recovery_Point metadata.
* Added AUnit regression Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery_Pass875.
* Updated validation guards and release documentation.

Covered forms include:

   use ;
   use type Interfaces.Unsigned_32, ;
   use all type ;

The pass preserves following declaration visibility after malformed use clauses so outline, diagnostics, resolver, and semantic-colouring consumers remain bounded to parser-owned metadata.

This is structural parser metadata only. It is not compiler-grade visibility legality checking, subtype legality checking, name resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project parsing, or dirty-state mutation.
