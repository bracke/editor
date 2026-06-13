Pass1300 implements Editor.Ada_Accessibility_Lifetime_Vertical_Slice_Legality.

This is a vertical semantic pass, not another closure/provenance/recheck wrapper. It adds concrete accessibility/lifetime mechanics over source-shaped scope, entity, and access-flow evidence:

* scope/master depth modelling, with lower levels representing longer-lived masters;
* static access-value escape rejection for assignments, returns, aggregate components, generic actual substitution, renamings, discriminant-dependent components, and protected/task shared state;
* dynamic/runtime accessibility-check acceptance when the access context explicitly permits it;
* access-to-subprogram profile fingerprint conformance;
* generic substitution freshness and private source/target freshness checks;
* missing source/target and stale fingerprint blockers.

The pass includes AUnit tests with source-shaped accessibility scenarios instead of synthetic closure-state transitions. It targets actual Ada RM accessibility progress and reduces the recurring compiler-grade gap around access values escaping through returns, assignments, aggregates, generics, renamings, discriminants, protected/task shared state, and access-to-subprogram profiles.
