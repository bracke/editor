Pass1220 - Shared-state recheck application legality

This pass adds Editor.Ada_Shared_State_Recheck_Application_Legality.

The package consumes Pass1219 shared-state recheck eligibility rows and applies them back into the shared-state final closure / stabilized diagnostic boundary.  Shared-state semantic conclusions become current only when the prerequisite recheck chain is eligible or when accepted stabilized evidence is explicitly carried forward as current non-diagnostic evidence.  Cross-unit dependency, view barrier, generic backmapping, state visibility, abstract/refined-state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, source fingerprint, stale eligibility, multiple-prerequisite, and indeterminate blockers are preserved as withheld-current application rows.

The pass preserves blocker family, source node, unit/dependency/state names, source spans, source fingerprints, worklist fingerprints, eligibility fingerprints, and deterministic application fingerprints.  It exposes Count, Accepted_Count, Withheld_Count, Current_Count, Indeterminate_Count, Count_By_Status, Count_By_Blocker_Family, Find_By_Node, Find_By_Source_Fingerprint, and Stable_Fingerprint.

Added regression:

  Test_Ada_Shared_State_Recheck_Application_Legality_Pass1220

This is a shared-state semantic convergence/application pass, not a UI projection pass.
