Editor Phase 579 Pass886
========================

Pass886 improves structural Ada grammar coverage for malformed address and
attribute-definition representation clauses.

The token cursor now records clause-specific recovery boundaries for:

* attribute-definition clauses missing `use`, for example `for T'Size 8;`;
* attribute-definition clauses missing the value expression after `use`, for
  example `for T'Alignment use;`;
* address clauses missing the address expression, both in `for X'Address use;`
  and old-style `for X use at;` forms.

Added productions:

* `Production_Attribute_Definition_Missing_Use_Recovery_Boundary`
* `Production_Attribute_Definition_Missing_Value_Recovery_Boundary`
* `Production_Address_Clause_Missing_Value_Recovery_Boundary`

Added AUnit regression:

* `Test_Language_Model_Token_Cursor_Attribute_Address_Clause_Recovery_Pass886`

This is structural editor parser coverage only. It is not compiler-grade
representation legality checking, address expression legality checking, static
expression validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.
