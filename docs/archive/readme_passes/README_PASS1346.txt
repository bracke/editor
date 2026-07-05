Pass1346 - RM Gap Burn-Down Pass 4

Implemented Editor.Ada_RM_Gap_Burn_Down_Pass1346.

This pass burns down the tagged/interface/dispatching/contract-effect gap by enforcing one canonical source-shaped legality result across tagged type extension rules, interface implementation, overriding and callable profile conformance, dispatching resolution, class-wide/view/access conversions, contract and flow/effect propagation, runtime-check preservation, indeterminate view/cross-unit evidence, semantic consumer agreement, and coverage/remediation promotion.

Concrete legality evidence now covers:

* tagged parent taggedness and parent visibility;
* ordinary, limited, task, protected, and synchronized interface implementation;
* abstract primitive implementation requirements;
* null procedure profile conformance;
* overriding indicator and profile conformance;
* parameter mode, result type, default, null-exclusion, convention, and access-to-subprogram profile agreement;
* ambiguous dispatching candidate sets;
* static calls in dispatching-required contexts;
* controlling operand and controlling result compatibility;
* dispatching through interface targets;
* class-wide, tagged-view, and access-to-class-wide conversion legality;
* Pre/Post, Global/Depends, Refined_Global/Refined_Depends, abstract-state constituent, dispatching-effect-join, and volatile/atomic effect propagation;
* runtime accessibility, class-wide conversion, and dispatching predicate checks;
* private, limited, incomplete, generic-formal, missing-full-view, and missing-cross-unit indeterminate blockers;
* diagnostics/colouring/outline/navigation/hover/build bridge consumer agreement via canonical tagged/interface/dispatching/profile/effect evidence.

Added AUnit coverage in Test_Ada_RM_Gap_Burn_Down_Pass1346 and registered it in Core_Suite.
