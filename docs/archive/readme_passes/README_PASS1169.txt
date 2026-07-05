Pass1169: Tasking Contract Predicate/Dataflow Consumer Legality

This pass adds Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality.

The new semantic layer feeds Pass1168 elaboration contract predicate/dataflow
evidence into tasking/protected effect legality.  Task activation, task
termination, protected reads/writes, protected function/procedure/entry calls,
entry queues and barriers, accept bodies, requeue, select guards and
alternatives, abortable parts, delay alternatives, and terminate alternatives
may remain confidently legal only when matching elaboration evidence also
accepts predicate/invariant propagation, definite-initialization object state,
refined Global/Depends flow, lifetime/accessibility, discriminant/variant,
representation/freezing, generic flow, tasking/protected flow, and repaired
coverage conditions.

The pass preserves base tasking/protected effect failures, missing elaboration
contract predicate/dataflow evidence, missing contract predicate/dataflow rows,
base contract and elaboration errors, predicate propagation blockers,
read-before-write and partial-initialization blockers, missing out-parameter
assignment, conditional in out assignment, return-object initialization,
branch/loop merge blockers, exception/finalization path blockers,
use-after-finalization blockers, lifetime/accessibility blockers,
discriminant/variant blockers, representation/freezing blockers,
Global/Depends blockers, call-propagation blockers, generic-flow blockers,
tasking/protected-flow blockers, coverage blockers, multiple matching blockers,
and indeterminate evidence as explicit semantic statuses.

Added regression:
  Test_Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality_Pass1169

This pass adds one compiler-grade building block for tasking/protected effect
legality consumer integration. Full compiler-grade Ada analysis remains
incomplete until the remaining Ada legality, overload/type resolution, generic,
representation/freezing, accessibility/lifetime, flow, tasking/protected,
parser/AST coverage, and cross-unit semantic closure layers are fully
integrated.
