Pass 462 - Visibility clause legality pass

Implemented another bounded Ada legality/completeness increment.

Focus:
- Duplicate context/use visibility clause diagnostics.

Changes:
- Added Legality_Duplicate_Visibility_Clause.
- Added legality checking over retained Visibility_Clause_Info metadata.
- The pass now flags repeated visibility clauses with the same clause kind,
  normalized name, and retained scope.
- Covered duplicate ordinary with clauses, use package clauses, and use type
  clauses without conflating distinct clause kinds such as use versus use type.
- Added AUnit regression coverage:
  Test_Language_Model_Legality_Visibility_Clause_Pass.

This remains intentionally bounded legality checking. Full Ada visibility legality
(private/limited-with semantics, elaboration, accessibility, and semantic use-type
validity) remains resolver/type-inference work.
