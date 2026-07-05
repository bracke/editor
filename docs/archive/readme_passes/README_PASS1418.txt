Pass1418 - Remaining_Entry_Family_Barrier_Index_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1418 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1418.

The concrete remaining gap remediated by this pass is entry-family barrier and index legality in protected/tasking contexts.  The pass ties together entry family index subtype evidence, barrier Boolean evidence, queue/requeue target evidence, protected-action effect evidence, runtime barrier-check preservation, warning-only queue diagnostics, stale entry-queue evidence, consumer surfacing, final readiness, and fingerprint freshness into one stable blocker family:

RM.Protected.Entry_Family.Barrier_Index

Covered source-shaped cases include:

* legal entry-family index and barrier resolution;
* legal entry queue/requeue target resolution;
* illegal non-discrete entry-family index rejection;
* illegal non-Boolean barrier rejection;
* illegal entry index constraint mismatch rejection;
* illegal requeue target index mismatch rejection;
* illegal queue-policy conflict rejection;
* runtime barrier-check preservation without promoting it to static illegality;
* warning-only queue diagnostics without converting a warning into illegality;
* private/full-view protected type indeterminate blockers;
* missing entry-family evidence blockers;
* missing barrier evidence blockers;
* stale entry queue/requeue evidence blockers;
* diagnostic consumer agreement for entry-family barrier/index state;
* final-readiness gap removal;
* source, AST, type, profile, entry-family, barrier, effect, and consumer fingerprint freshness gates.

The pass is registered in Core_Suite and advances the Remaining Gap Remediation series beyond pass1417 without adding a broad audit/status/projection layer.
