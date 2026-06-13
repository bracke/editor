Pass1256 implements Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration.

This pass feeds the RM-completed generic/shared-state semantic chain into the diagnostic/feed boundary after Pass1255 dataflow/initialization completion. Accepted RM-completed rows are withheld as current semantic evidence. Blocking rows are emitted with their original blocker-family identity preserved: cross-unit RM completion, elaboration, accessibility/lifetime, exception/finalization, predicate/invariant, dataflow, overload/type, representation/freezing, tasking/protected, coverage-proven AST repair, stale source or substitution fingerprints, view barriers, multiple blockers, and indeterminate states.

The pass also extends Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Generic_Shared_State_RM_Completion_Diagnostics so stale RM-completion input rejects the feed rather than exposing outdated semantic conclusions.

Added regression: Test_Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration_Pass1256.
