Pass1348 -- RM Gap Burn-Down Pass 6: tasking / protected / parallel / shared-state legality

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1348 and its AUnit suite.

The pass burns down the tasking/protected/parallel/shared-state RM gap by requiring one canonical source-shaped legality result across:

* protected action reentrancy;
* protected access-mode compatibility;
* protected entry barrier side-effect rejection;
* protected shared-state write effects;
* entry-family index/range checks;
* entry queue discipline;
* accept-body effect evidence;
* requeue target compatibility;
* select-path coverage;
* terminate alternative dependency safety;
* abort/finalization ordering;
* abortable-select finalization safety;
* task termination finalization blockers;
* controlled-object finalization evidence;
* parallel-loop shared-state restrictions;
* container iterator tampering checks;
* reduction profile and seed compatibility;
* Global/Depends and refined-flow preservation;
* volatile and atomic ordering preservation;
* dispatching effect joins through synchronized interfaces;
* synchronized-interface effect agreement;
* runtime tampering/bounds/accessibility check preservation;
* private, limited, incomplete, generic-formal, cross-unit, and missing-effect indeterminate states;
* diagnostics, semantic colouring, outline, navigation, hover/details, and build-diagnostic bridge consumer agreement;
* source, AST, type, profile, substitution, effect, flow, and consumer fingerprint freshness.

The tests are source-shaped regression rows that cover legal, illegal, legal-with-runtime-check, indeterminate, consumer-surfaced, and audit-gate scenarios.  They verify that the gap cannot be promoted to Covered unless the semantic result is consumed, balanced, fingerprint-fresh, source-shaped, and backed by stable blocker-family identity.
