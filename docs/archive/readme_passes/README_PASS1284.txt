Pass1284 implements Editor.Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality.

This pass connects the Pass1277 remaining Ada RM edge precision model to the stabilized direct RM-completion closure-consumer boundary from Pass1280 and the stabilized diagnostic/provenance/search chain from Pass1281-Pass1283.

The new consumer accepts a remaining hard RM edge only when the local remaining-edge legality row is accepted, a matching stabilized direct-consumer closure row exists, that closure row is accepted current or accepted not-required, and source/substitution fingerprints agree. Blocked rows preserve the original remaining-edge blocker family and the stabilized closure family rather than flattening into a generic expression blocker.

The pass covers remaining hard RM edges such as dispatching calls with abstract-state effects, renamed primitives, inherited/private-extension primitive hiding, access-to-subprogram effect profiles, generic formal subprogram calls, universal numeric ambiguity under stateful expected contexts, volatile/atomic representation clauses, protected action reentrancy, entry-family queues, requeue/select paths, abort/deferred-finalization, and controlled/finalized discriminant-dependent components.

Added AUnit coverage in Test_Ada_Remaining_RM_Edge_Stabilized_Closure_Consumer_Legality_Pass1284.
