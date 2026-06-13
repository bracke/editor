Pass1274: RM-completion closure consumer remediation worklist

This pass adds Editor.Ada_RM_Completion_Closure_Consumer_Remediation_Worklist_Legality.

It consumes Pass1273 direct RM-completion closure consumer diagnostics and converts blocking diagnostics into deterministic, prerequisite-ordered semantic re-analysis work. Accepted rows remain current semantic evidence; blockers preserve their original cross-unit, elaboration, accessibility/lifetime, exception/finalization, overload/type, representation/freezing, tasking/protected, dataflow, predicate/invariant, AST/coverage, generic-substitution, stale/fingerprint, multiple, and indeterminate family identities.

The pass is the first step in the remediation/recheck/stabilization loop for the direct RM-completion closure consumers. It does not add UI/status/projection behavior and does not flatten semantic blocker families.

Added files:
- src/core/editor-ada_rm_completion_closure_consumer_remediation_worklist_legality.ads
- src/core/editor-ada_rm_completion_closure_consumer_remediation_worklist_legality.adb
- tests/src/test_ada_rm_completion_closure_consumer_remediation_worklist_legality_pass1274.ads
- tests/src/test_ada_rm_completion_closure_consumer_remediation_worklist_legality_pass1274.adb

Updated:
- tests/src/core_suite.adb
