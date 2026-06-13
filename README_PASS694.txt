# Editor Phase 579 - Pass 694

This pass deepens structural Ada tasking/protected-object grammar coverage in
`Editor.Ada_Token_Cursor` while preserving the existing parser-owned,
snapshot-owned language-intelligence architecture.

Implemented in this pass:

- Added protected-operation and protected-entry barrier productions:
  - `Production_Protected_Operation_Declaration`
  - `Production_Protected_Operation_Aspect_Specification`
  - `Production_Protected_Entry_Barrier`
- Added explicit entry-family index subtype retention via
  `Production_Entry_Family_Index_Subtype` in addition to the existing entry
  family and discrete-subtype productions.
- Added accept-body and selective-accept/asynchronous-select markers:
  - `Production_Accept_Do_Part`
  - `Production_Select_Or_Alternative`
  - `Production_Select_Then_Abort_Part`
- Extended bounded task/protected scans so protected body operations, protected
  operation aspects, entry barriers, entry-family declarations, accept do-parts,
  select `or` alternatives, and `then abort` alternatives remain visible to
  syntax-tree, Outline, and semantic-colouring consumers.
- Added AUnit regression coverage for protected operation/aspect retention,
  entry-family index subtype retention, protected entry barriers, accept
  do-parts, select-or alternatives, then-abort alternatives, requeue-with-abort
  retention, and recovery into following declarations.
- Updated validation guards, README notes, Outline docs, semantic-colouring
  docs, and release checklist.

This improves structural grammar coverage for Ada task/protected constructs.
It is not compiler-grade legality checking for protected operation legality,
entry-family contracts, barrier semantics, selective-accept legality,
asynchronous transfer of control, requeue legality, visibility, conformance,
accessibility, or runtime tasking semantics.
