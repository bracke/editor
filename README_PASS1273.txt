Pass1273 implements Editor.Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration.

This pass adds diagnostic/feed integration for the direct RM-completion closure consumer chain after the concrete semantic consumers have been added for cross-unit closure, elaboration, accessibility/lifetime, exception/finalization, predicate/invariant, overload/type, representation/freezing, tasking/protected, and dataflow/initialization.

Accepted direct-consumer rows are withheld as current semantic evidence. Blocking rows are emitted as diagnostics while preserving their original blocker family: cross-unit, elaboration, accessibility, exception/finalization, overload/type, representation/freezing, tasking/protected, dataflow, predicate, stale/fingerprint, AST/coverage, generic substitution, multiple blockers, and indeterminate state.

The semantic diagnostic feed now exposes Build_With_RM_Completion_Closure_Consumer_Diagnostics, preserving stale-input rejection and blocker-family-aware source classification.

Added Test_Ada_RM_Completion_Closure_Consumer_Diagnostic_Integration_Pass1273.
