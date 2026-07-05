Pass1261 — Generic/shared-state RM-completion recheck convergence legality

This pass adds one compiler-grade building block for detecting convergence of the RM-completed generic/shared-state semantic recheck chain.

New package:
  Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality

Purpose:
  Consume Pass1260 RM-completion recheck application rows and classify whether each RM-completed generic/shared-state conclusion has converged as current evidence, converged as not required, remained stably withheld by the same prerequisite blocker, remained indeterminate, or changed relative to a prior application fingerprint.  This prevents repeated RM-completion semantic rechecks from cycling when overload/type, representation/freezing, tasking/protected, cross-unit, elaboration, accessibility, exception/finalization, predicate/invariant, dataflow, AST repair, source, and substitution evidence has not changed.

Consumed evidence:
  * Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality
  * Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality
  * Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality
  * Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration

Convergence statuses preserve blocker families for stale/fingerprint, AST/coverage, cross-unit, generic substitution, prior dataflow, volatile/atomic, overload/type, representation/freezing, tasking/protected, elaboration, accessibility/lifetime, discriminants/variants, exception/finalization, renaming/aliasing, predicates/invariants, dataflow, multiple prerequisites, indeterminate evidence, and changed application fingerprints.

Added regression:
  Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality_Pass1261

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
