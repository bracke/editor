# Editor Phase 579 Pass837 - Membership choice-list separator and recovery depth

Pass837 improves Ada membership choice-list grammar coverage in the token cursor.
Membership tests now retain explicit `|` separator metadata and bounded
missing-choice recovery metadata for malformed/in-progress choice lists.

Implemented productions:

- `Production_Membership_Choice_Separator`
- `Production_Membership_Choice_Missing_Choice_Recovery_Boundary`

Covered examples include:

- `A in B | C`
- `A not in B | C`
- malformed/in-progress `A in B | ;`

Regression coverage is in
`Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837`.

This improves structural grammar coverage for Ada membership choice lists. It is
not compiler-grade membership legality checking, duplicate-choice validation,
static range evaluation, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.
