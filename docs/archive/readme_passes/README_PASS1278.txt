Pass1278: RM-completion closure consumer recheck convergence

This pass adds Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality.
It consumes Pass1276 direct RM-completion closure consumer recheck application rows and classifies whether each result has converged as current evidence, converged as not-required non-diagnostic evidence, remained stably withheld by its preserved prerequisite blocker, remained indeterminate, or changed relative to a previous application fingerprint.

The convergence model preserves direct consumer blocker-family identity for cross-unit closure, elaboration, accessibility/lifetime, exception/finalization, overload/type, representation/freezing, tasking/protected, dataflow/initialization, predicate/invariant, AST/coverage, generic substitution, source/substitution fingerprint mismatch, multiple prerequisites, and indeterminate state.

Added AUnit coverage in Test_Ada_RM_Completion_Closure_Consumer_Recheck_Convergence_Legality_Pass1278 and registered it in Core_Suite.
