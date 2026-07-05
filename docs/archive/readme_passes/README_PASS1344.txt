Pass1344 - RM Gap Burn-Down Pass 2

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1344 and its AUnit suite.

The pass burns down the generic substitution/body replay/callable profile/flow gap that remained after the broad semantic vertical slices and the first RM gap burn-down pass.  It is intentionally not another audit wrapper: it models a concrete source-shaped generic-instantiation legality result that must be shared by generic contract checking, generic body replay, callable profile conformance, overload/expected-type resolution, contract/aspect propagation, Global/Depends and refined-flow propagation, volatile/atomic ordering, dispatching effect joins, remediation evidence, regression balance, and real semantic consumers.

Implemented rule evidence includes:

- required formal-to-actual bindings;
- formal/actual kind compatibility for formal types, objects, subprograms, packages, access types, and private formals;
- type substitution compatibility;
- object mode compatibility;
- callable profile compatibility;
- defaulted formal, null-exclusion, convention, and access-to-subprogram profile compatibility;
- overload result and callable profile agreement in replayed calls/operators;
- rejection of generic body replay that still uses formal placeholders instead of substituted actuals;
- nested instantiation cycle and replay-depth overflow rejection;
- preservation of Pre/Post-style contracts through substitution;
- preservation of Global/Depends and refined-flow evidence;
- volatile/atomic ordering preservation;
- dispatching effect join preservation;
- preservation of runtime accessibility, range, and predicate checks;
- private, limited, incomplete, missing-full-view, and missing-cross-unit indeterminate blockers;
- remediation state promotion to Covered only when coverage, balanced corpus, consumer, and fingerprint evidence agree.

The AUnit suite adds balanced legal, illegal, legal-with-runtime-check, and indeterminate scenarios plus enforcement tests for substitution/body replay, callable profile/overload/convention agreement, contract/flow preservation, remediation/consumer evidence, classification mismatches, and stale fingerprints.
