Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser
Pass921 — Digits/delta constraint reserved-boundary recovery

This pass continues from pass920 and narrows one remaining subtype-constraint
recovery gap.

Implemented changes:

* Added Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary.
* Added Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary.
* Refined digits/delta constraint parsing so reserved statement/declaration
  boundaries after digits or delta are not fabricated as constraint expressions.
* Added AUnit coverage:
  Test_Language_Model_Token_Cursor_Digits_Delta_Reserved_Boundary_Recovery_Pass921.
* Updated validation guard comments, parser coverage documentation, syntax
  colouring notes, release checklist, and README.

Covered malformed forms include:

   subtype Missing_Digits is Float digits else;
   subtype Missing_Delta is Fixed delta else;

This improves structural grammar coverage for malformed Ada digits/delta
constraints at reserved boundaries. It is not compiler-grade floating/fixed-point
subtype legality checking, static expression validation, overload resolution,
compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.
