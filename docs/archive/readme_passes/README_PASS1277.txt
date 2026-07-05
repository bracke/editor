Pass1277: Remaining Ada RM edge precision legality

This pass adds Editor.Ada_Remaining_RM_Edge_Precision_Legality and an AUnit regression test.

The pass consumes the Pass1276 applied direct RM-completion closure-consumer boundary and validates the remaining hard Ada RM edge categories directly:

* dispatching calls with abstract-state effects
* renamed primitives
* inherited/private-extension primitive hiding
* access-to-subprogram effect profiles
* generic formal subprogram calls
* universal numeric ambiguity under stateful expected contexts
* volatile/atomic representation clauses
* protected action reentrancy
* entry-family queues
* requeue/select paths
* abort/deferred-finalization
* controlled/finalized discriminant-dependent components

Accepted rows are exposed only when the applied RM-completion consumer boundary is current or not required, source/substitution fingerprints match, and the specific RM edge has no local legality mismatch. Blocking rows preserve their real blocker family rather than collapsing into generic expression diagnostics.
