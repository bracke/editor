Pass1160 - Generic replay representation-flow consumer legality

Implemented Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality.

This pass feeds representation/freezing tasking/elaboration/contract-flow evidence from Pass1159 back into generic instance body semantic replay. Instantiated generic body replay rows for declarations, statements, expressions, nested instances, representation clauses, operational attributes, stream attributes, record layouts, private/full-view timing, and tasking representation effects can no longer remain confidently legal when their replayed representation/freezing evidence is missing, blocked, or indeterminate.

The model classifies accepted replay contexts, base generic replay errors, source/instance mapping errors, expansion/overload/flow/predicate/accessibility/representation replay errors, missing representation-flow rows, base freezing errors, Refined_Global and Refined_Depends blockers, unpropagated call effects, coverage feedback blockers, linked contract-flow/elaboration/tasking blockers, multiple matching representation-flow blockers, and indeterminate representation-flow states.

Added AUnit regression:
Test_Ada_Generic_Replay_Representation_Flow_Consumer_Legality_Pass1160

Updated core_suite registration and project notes.
