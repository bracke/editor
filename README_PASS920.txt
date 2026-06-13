Editor Phase 579 — IDE-grade Outline / Semantic Colouring / Ada Parser
Pass920 — Range constraint reserved-boundary recovery

This pass improves structural Ada grammar recovery for malformed range constraints
where reserved statement/declaration boundary tokens appear where lower or upper
bound expressions would otherwise be parsed.

Implemented changes:

* Added Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary.
* Extended Parse_Range_Constraint so reserved boundaries after `range` or after
  the `..` separator do not get consumed as lower/upper bound expressions.
* Preserved existing missing-lower-bound, missing-upper-bound,
  constraint-recovery, generic recovery, and valid following range-bound
  metadata.
* Added AUnit coverage:
  Test_Language_Model_Token_Cursor_Range_Constraint_Reserved_Boundary_Recovery_Pass920.
* Updated validation guard comments, parser coverage docs, syntax-colouring docs,
  release checklist, and README.

Representative malformed forms covered:

   subtype Missing_Lower is Integer range else;
   subtype Missing_Upper is Integer range 1 .. else;

This improves structural grammar coverage for malformed Ada range constraints at
reserved boundaries. It is not compiler-grade range-expression legality checking,
subtype legality checking, static expression validation, overload resolution,
compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.
