Pass1218 - shared-state remediation worklist legality

This pass adds Editor.Ada_Shared_State_Remediation_Worklist_Legality.

The package consumes Pass1217 shared-state stabilized diagnostic rows and derives a deterministic semantic remediation worklist.  Accepted shared-state rows remain current semantic evidence; blocking rows become ordered prerequisite work items before downstream semantic re-analysis may trust abstract/refined state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, dependency, view, generic-backmapping, or fingerprint-sensitive evidence.

The worklist preserves the original blocker family and source identity.  It distinguishes current evidence, dependency closure, view barrier resolution, generic backmapping repair, state visibility repair, abstract-state repair, volatile/atomic repair, overload/type repair, representation repair, tasking/protected repair, fingerprint refresh, multiple-blocker split, and indeterminate recheck actions.

Added regression:
  Test_Ada_Shared_State_Remediation_Worklist_Legality_Pass1218

This pass is semantic integration work, not a projection/status layer.
