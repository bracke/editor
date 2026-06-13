Pass1167 - Contract predicate/dataflow consumer legality

This pass adds Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality.

The new semantic package consumes Pass1166 predicate/invariant propagation plus dataflow and definite-initialization evidence and feeds it back into contract/aspect legality.  Precondition, postcondition, predicate, invariant, assertion, contract-case, Global, Depends, Refined_Global, and Refined_Depends conclusions cannot remain confident when the matching propagated predicate/invariant, initialized object-state, refined-flow, lifetime, discriminant/representation, or repaired coverage evidence is missing, blocked, or indeterminate.

The pass classifies accepted contract predicates/aspects, preserved base contract errors, missing predicate/dataflow evidence, propagation errors, read-before-write, partial initialization, out-parameter, conditional in out, return-object initialization, exception/finalization path, use-after-finalization, lifetime, discriminant/representation, coverage, Global/Depends/call/generic/tasking flow blockers, multiple blockers, and indeterminate contract predicate/dataflow states.

Added regression: Test_Ada_Contract_Predicate_Dataflow_Consumer_Legality_Pass1167.
