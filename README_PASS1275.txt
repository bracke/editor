Pass1275: RM-completion closure consumer recheck eligibility

This pass implements Editor.Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality.

It consumes the Pass1274 direct RM-completion closure consumer remediation worklist and turns ordered prerequisite work into bounded recheck eligibility rows. Accepted rows remain current semantic evidence. Unresolved prerequisite blockers remain blocked before downstream semantic consumers may trust the conclusion.

Preserved blocker families include cross-unit closure, elaboration, accessibility/lifetime, exception/finalization, overload/type, representation/freezing, tasking/protected, dataflow/initialization, predicate/invariant, AST/coverage, generic substitution, source/substitution fingerprint mismatch, multiple prerequisites, and indeterminate state.

Added AUnit coverage:
- Test_Ada_RM_Completion_Closure_Consumer_Recheck_Eligibility_Legality_Pass1275
