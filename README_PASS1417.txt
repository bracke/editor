Pass1417 - Remaining_Volatile_Atomic_Protected_Component_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1417 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1417.

The concrete remaining gap remediated by this pass is volatile and atomic component legality in protected and synchronized contexts.  The pass ties together component evidence, aspect evidence, protected-operation access evidence, shared-update/effect evidence, runtime synchronization-check preservation, warning-only preservation, stale synchronization evidence, consumer surfacing, final readiness, and fingerprint freshness into one stable blocker family:

RM.Protected.Volatile_Atomic.Component

Covered source-shaped cases include:

* legal volatile/atomic protected component resolution;
* legal protected-operation component access resolution;
* illegal atomic component by-copy treatment rejection;
* illegal volatile/atomic aspect conflict rejection;
* illegal protected component/discriminant conflict rejection;
* illegal nonvolatile shared update rejection;
* illegal component mode conflict rejection;
* runtime synchronization-check preservation without promoting it to static illegality;
* warning-only preservation without converting a warning into an illegality;
* private/full-view protected type indeterminate blockers;
* missing component evidence blockers;
* missing volatile/atomic aspect evidence blockers;
* stale synchronization/effect evidence blockers;
* diagnostic consumer agreement for volatile/atomic protected component state;
* final-readiness gap removal;
* source, AST, type, profile, component, aspect, effect, and consumer fingerprint freshness gates.

The pass is registered in Core_Suite and advances the Remaining Gap Remediation series beyond pass1416 without adding a broad audit/status/projection layer.
