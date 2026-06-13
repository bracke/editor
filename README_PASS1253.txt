# Pass1253 — Exception/finalization generic/shared-state RM completion legality

This pass adds one compiler-grade building block for exception propagation and finalization legality over the completed generic/shared-state RM chain.

It creates `Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality` and consumes completed cross-unit RM closure, prior exception/finalization generic/shared-state evidence, completed elaboration, completed accessibility/lifetime, overload/type RM completion, representation/freezing RM completion, tasking/protected RM completion, and coverage-proven AST repair evidence.

The pass classifies raise statements, raise expressions, reraise paths, handlers, exception propagation, controlled initialization/adjust/finalize, master finalization, cleanup actions, abort-deferred finalization, task termination, no-return paths, generic replay finalization, cross-unit finalization, dispatching exception effects, renamed handler sources, predicate finalization checks, dataflow cleanup edges, and accessibility master finalization.

Accepted rows become current only when every required completed RM prerequisite is accepted and source/substitution fingerprints still match. Blocked rows preserve their prerequisite blocker family: cross-unit RM completion, prior exception/finalization, elaboration RM completion, accessibility RM completion, overload RM completion, representation RM completion, tasking RM completion, AST repair, local exception propagation, handler resolution, finalization ordering, controlled operations, abort/deferred finalization, task termination, no-return, cleanup paths, generic body availability, view barriers, fingerprint mismatches, multiple blockers, and indeterminate state.

Added regression: `Test_Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality_Pass1253`.

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
