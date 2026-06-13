Pass1219 - Shared-state recheck eligibility legality

This pass adds Editor.Ada_Shared_State_Recheck_Eligibility_Legality.

The package consumes the Pass1218 shared-state remediation worklist and converts ordered prerequisite work into bounded recheck eligibility rows.  It prevents downstream shared-state semantic consumers from accepting conclusions while cross-unit dependencies, view barriers, generic backmapping, abstract-state visibility, abstract/refined-state evidence, volatile/atomic/shared-variable evidence, overload/type evidence, representation/freezing evidence, tasking/protected evidence, source fingerprints, multiple prerequisites, or indeterminate states remain unresolved.

The pass preserves the original blocker family, node, unit/dependency/state names, source spans, source fingerprints, worklist fingerprints, and eligibility fingerprints.  Accepted shared-state evidence remains current and is not rechecked.  Blocking prerequisites remain explicit recheck blockers and are counted/queryable by status, action, family, and node.

Added regression:

  Test_Ada_Shared_State_Recheck_Eligibility_Legality_Pass1219

This is a semantic dependency/convergence pass, not a UI projection pass.
