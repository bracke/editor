Pass1328 adds Editor.Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality.

This is a vertical Ada semantic slice for iterator, loop, and parallelism legality. It models source-shaped discrete subtype loops, discrete range loops, array component iteration, generalized iterators, container element and cursor iteration, parallel discrete/iterator loops, and reduction contexts.

The slice checks loop-parameter identity and constant-view semantics, discrete subtype requirements, static/range-bound compatibility, iterator First/Next and reversible profile evidence, container Element/Has_Element and cursor profile evidence, expected element type compatibility, reduction result/seed/profile compatibility, parallel permission, shared-state restrictions, tampering blockers and runtime tampering checks, private/limited/incomplete/generic-formal view barriers, and source/AST/type/profile/effect fingerprint freshness.

AUnit coverage is added in Test_Ada_Iterator_Loop_Parallel_Vertical_Slice_Legality_Pass1328 and registered in Core_Suite.
