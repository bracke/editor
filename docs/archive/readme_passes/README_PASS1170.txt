Pass1170: Representation Tasking Contract Predicate/Dataflow Consumer Legality

This pass adds Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality.

The new semantic layer feeds Pass1169 tasking/protected contract predicate/dataflow
evidence into representation/freezing exact propagation.  Representation clauses,
operational attributes, stream attributes, record layouts, generic-instance
representation effects, private/full-view representation timing, task activation
and termination representation effects, protected read/write/call effects, entry
barriers, accept bodies, requeue/select effects, and abortable finalization effects
may remain confidently legal only when matching tasking/protected evidence also
accepts predicate/invariant propagation, definite-initialization object state,
refined Global/Depends flow, lifetime/accessibility, discriminant/variant,
representation/freezing, generic-flow, tasking/protected-flow, and repaired
coverage conditions.

The pass preserves base representation/freezing failures, missing tasking contract
predicate/dataflow evidence, missing elaboration or contract predicate/dataflow
rows, base contract/elaboration/tasking errors, predicate propagation blockers,
read-before-write and partial-initialization blockers, missing out-parameter
assignment, conditional in out assignment, return-object initialization,
branch/loop merge blockers, exception/finalization path blockers,
use-after-finalization blockers, lifetime/accessibility blockers,
discriminant/variant blockers, representation/freezing blockers,
Global/Depends blockers, call-propagation blockers, generic-flow blockers,
tasking/protected-flow blockers, repaired coverage blockers, multiple matching
blockers, and indeterminate tasking evidence as explicit representation/freezing
consumer statuses.

Added regression:
  Test_Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality_Pass1170

This pass adds one compiler-grade building block for representation/freezing
consumer integration. Full compiler-grade Ada analysis remains incomplete until
the remaining Ada legality, overload/type resolution, generic,
representation/freezing, accessibility/lifetime, flow, tasking/protected,
parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
