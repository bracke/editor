Pass1166 - Predicate/invariant dataflow-initialization consumer legality

This pass adds Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality.

The pass feeds Pass1165 dataflow plus definite-initialization consumer evidence
back into predicate and invariant propagation.  Predicate/invariant propagation
rows can no longer remain confidently legal when the state used to preserve or
propagate the predicate/invariant is read before write, partially initialized,
missing out-parameter assignment, lost on exception/loop/branch paths, used
after finalization, blocked by exact lifetime/accessibility evidence, blocked by
Global/Depends or Refined_Global/Refined_Depends flow evidence, or blocked by
coverage repair gates.

The package classifies accepted static predicates, dynamic predicates,
invariants, dynamic invariants, generic substitutions, derived invariants,
private/full-view invariant propagation, and flow-effect propagation.  It also
preserves base predicate propagation errors and separates missing dataflow
initialization evidence, Global blockers, Depends blockers, call propagation
blockers, generic and task/protected flow blockers, initialization blockers,
lifetime blockers, discriminant/representation blockers, coverage blockers,
multiple blockers, and indeterminate rows.

Added regression:
Test_Ada_Predicate_Dataflow_Initialization_Consumer_Legality_Pass1166
