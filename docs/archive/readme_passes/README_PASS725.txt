# Editor pass725 — Number declaration grammar depth

This pass deepens the token-cursor Ada grammar for named-number declarations.
It is a narrow grammar/metadata pass over pass724 and does not change the editor
architecture.

## Parser/token cursor

The token cursor now retains number declaration internals with dedicated
productions:

* `Production_Number_Defining_Name`
* `Production_Number_Defining_Name_Separator`
* `Production_Number_Constant_Keyword`
* `Production_Number_Declaration_Recovery_Boundary`

Grouped named-number declarations such as `A, B, C : constant := 1 + 2;` now
retain each defining identifier and comma separator explicitly.  The `constant`
keyword in named-number declarations is also retained distinctly from object
constant qualifiers.  Malformed named-number declarations such as missing `:=` or
missing initialization expressions expose bounded recovery markers and continue
into following declarations.

## Tests

Added AUnit coverage:

* `Test_Language_Model_Token_Cursor_Number_Declaration_Depth_Grammar_Completeness`

The validation guard now requires the new productions, parser path markers, and
regression coverage.

## Scope

This improves structural grammar coverage for Ada named-number declarations. It
is not compiler-grade legality checking for named-number staticness, universal
numeric resolution, duplicate visibility, expected type, constant-expression
legality, or declaration-region semantics.
