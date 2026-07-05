Pass1155 - Flow refinement consumer legality

This pass adds Editor.Ada_Flow_Refinement_Consumer_Legality.

The new semantic layer consumes the existing flow-effect graph and Refined_Global / Refined_Depends conformance rows, then decides whether a flow fact may be accepted by downstream consumers.  A local read/write/Depends/call/generic/task flow edge is no longer considered confidently consumable merely because it is a well-formed flow-graph edge.  It also needs a matching refined body/spec conformance row.

The pass classifies accepted flow edges, accepted Depends edges, accepted call propagation, accepted generic effects, accepted task/protected effects, null effects, flow graph blockers, missing refinement rows, missing Refined_Global reads/writes, Refined_Global mode mismatches and extra items, missing/extra Refined_Depends edges, source/target mode errors, unpropagated call effects, repaired coverage feedback blockers, linked refinement/flow errors, multiple matching refinement blockers, and indeterminate results.

This is a semantic-depth pass, not a diagnostic/projection/status pass.  Its purpose is to keep downstream assignment, return, call, generic instance, tasking/protected, elaboration, representation, and integrated-closure consumers from accepting flow facts that fail the body/spec refinement layer.

AUnit coverage was added in Test_Ada_Flow_Refinement_Consumer_Legality_Pass1155 and registered in tests/src/core_suite.adb.
