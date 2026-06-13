Pass1190 -- nested generic replay cycle closure legality

Added Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality.

This pass closes the cross-unit nested generic replay gap after source/instance
backmapping and final overload/type RM consumers.  It accepts nested generic
replay closure only when generic source/instance backmapping, final overload/type
consumer evidence, cross-unit final semantic closure evidence, generic body
availability, view/child visibility state, dependency bounds, cycle state, and
source/substitution fingerprints all agree.

The pass preserves blockers for missing backmapping, mapping and overload
backmapping failures, missing/blocked/ambiguous final RM overload consumers,
missing/blocked cross-unit final closure, private and limited view barriers,
child visibility blockers, unavailable generic bodies, source-instance and
substitution fingerprint mismatches, nested dependency cycles, recursive
instantiation cycles, bounded cycle-depth overflow, dependency overflow, stale
dependencies, multiple blockers, and indeterminate closure.

Added AUnit coverage:

* Test_Ada_Generic_Replay_Nested_Cycle_Closure_Legality_Pass1190

The test verifies that accepted nested generic replay requires all final evidence,
that nested/recursive/cycle-depth blockers remain first-class statuses, and that
missing backmap, final overload/type, and cross-unit closure evidence block
confidence instead of being flattened.
