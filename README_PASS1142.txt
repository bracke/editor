Pass1142 - Discriminant-dependent legality

This pass adds Editor.Ada_Discriminant_Dependent_Legality, a widened semantic
legality package for discriminated records, discriminant constraints/defaults,
variant presence, and discriminant-dependent use-site checks.

The pass connects discriminant facts to assignment, conversion, return,
allocator, aggregate, generic actual, private/full-view, and coverage-gated
semantic contexts.  It preserves linked blockers from record/variant aggregate
legality, assignment legality, conversion/access/aggregate legality, return
legality, generic instance body semantic replay, and widened legality coverage
gate enforcement.

New AUnit coverage:

* Test_Ada_Discriminant_Dependent_Legality_Pass1142

The package is deterministic and snapshot-owned.  It performs no rendering-side
parsing, file IO, compiler invocation, workspace mutation, command mutation, or
render mutation.
