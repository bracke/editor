Editor Phase 579 — Pass882

Implemented a bounded select-statement alternative statement-sequence recovery
pass.

Changes:
- Added Production_Select_Alternative_Missing_Statement_Recovery_Boundary.
- Added Production_Select_Else_Missing_Statement_Recovery_Boundary.
- Added Production_Select_Abortable_Missing_Statement_Recovery_Boundary.
- Refined select/or alternative handling so an immediate select boundary after a
  guard arrow records select-specific missing-statement recovery.
- Refined select else-part and asynchronous then-abort handling so empty bodies
  record branch-specific recovery before end select or other select boundaries.
- Added AUnit regression coverage in
  Test_Language_Model_Token_Cursor_Select_Alternative_Statement_Recovery_Pass882.
- Updated validation guards, parser coverage docs, syntax-colouring notes,
  release checklist, and README.

This improves structural grammar coverage for Ada select-statement alternative
statement sequences. It is not compiler-grade tasking legality checking,
selective-accept legality checking, statement legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.
