Pass1182 - Discriminant/variant consumer integration legality

This pass adds Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality.

The new layer feeds discriminant and variant legality into the hard consumers that still depend on discriminated type semantics: record layout, record and extension aggregates, assignments, conversions, returns, allocators, access discriminants, representation clauses, freezing effects, generic replay, and private/full-view discriminant consistency.

A consumer row cannot remain confidently legal unless it has accepted discriminant/variant semantic evidence, repaired discriminant/variant AST coverage evidence, representation/freezing CPD evidence where required, and generic replay source/instance backmapping evidence where required.

The pass preserves direct blockers for missing discriminant rows, variant coverage gaps, private/full-view discriminant mismatches, record-layout discriminant blockers, aggregate discriminant blockers, access-discriminant lifetime blockers, freezing/representation discriminant blockers, unrepaired AST coverage, representation/freezing CPD failures, generic replay backmapping failures, duplicate matches, and indeterminate consumer evidence.

Regression: Test_Ada_Discriminant_Variant_Consumer_Integration_Legality_Pass1182.
