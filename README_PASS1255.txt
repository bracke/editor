Pass1255 adds Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality.

This pass completes definite-initialization and dataflow legality over the completed generic/shared-state RM chain. It consumes prior generic/shared-state dataflow evidence together with completed cross-unit RM closure, elaboration, accessibility/lifetime, exception/finalization, predicate/invariant, overload/type, representation/freezing, tasking/protected, and coverage-proven AST repair evidence.

The pass preserves blocker families for missing or blocked prior dataflow evidence, cross-unit RM completion, elaboration, accessibility, exception/finalization, predicate/invariant, overload, representation, tasking, AST repair, read-before-write, partial component initialization, out/return-object rules, branch/loop merge, exception paths, finalization, access escape, variant components, volatile/atomic effects, generic substitution, dispatching effects, view barriers, fingerprint mismatches, multiple blockers, and indeterminate states.

Added AUnit regression Test_Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality_Pass1255 and registered it in tests/src/core_suite.adb.
