Pass1302: Tasking/protected vertical semantic slice

This pass adds Editor.Ada_Tasking_Protected_Vertical_Slice_Legality.

It is a concrete semantic pass rather than another diagnostic/provenance/recheck
wrapper.  The pass models source-shaped tasking and protected-object evidence and
checks protected action reentrancy, callback reentrancy, protected entry barrier
side effects, entry-family index and queue discipline, requeue/select path
coverage, accept-body effect evidence, terminate alternatives, abort/deferred
finalization ordering, abortable-select finalization safety, protected/shared
state access, access-mode compatibility, abstract/refined-state evidence, and
source/effect fingerprint freshness.

The AUnit coverage uses task/protected entities, operation rows, and event rows
that correspond to Ada tasking constructs rather than synthetic closure-state
transitions.
