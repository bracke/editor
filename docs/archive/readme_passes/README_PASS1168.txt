Pass1168: Elaboration Contract Predicate/Dataflow Consumer Legality

This pass adds Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality.

The new semantic layer feeds Pass1167 contract predicate/dataflow evidence into
elaboration graph closure.  Elaboration-time direct, indirect, and dispatching
calls; default expressions; aspect expressions; representation items; generic
instances; task activation contexts; and Preelaborate/Pure/Remote_Types/
Shared_Passive policy contexts may remain confidently legal only when the
matching contract predicate/dataflow row accepts predicate or invariant
propagation, initialized object-state evidence, refined Global/Depends dataflow,
lifetime/accessibility, discriminant/representation, and repaired coverage
conditions.

The pass preserves base elaboration graph failures, missing contract-predicate
rows, multiple matching blockers, base contract errors, predicate propagation
errors, initialization/read-before-write failures, lifetime blockers,
discriminant/representation blockers, coverage blockers, Global/Depends/call
propagation/generic/tasking flow blockers, linked dataflow blockers, and
indeterminate evidence as explicit semantic statuses.

Added regression:
  Test_Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality_Pass1168

This pass adds one compiler-grade building block for elaboration legality
consumer integration. Full compiler-grade Ada analysis remains incomplete until
the remaining Ada legality, overload/type resolution, generic, representation/
freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage,
and cross-unit semantic closure layers are fully integrated.
