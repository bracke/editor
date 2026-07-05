Pass1357 - RM Gap Burn-Down Pass 15

Added Editor.Ada_RM_Gap_Burn_Down_Pass1357.

This pass burns down the predefined-operation / numeric-model / universal-resolution composition gap.  It enforces a single canonical source-shaped result across predefined operators, user-defined operators, use-type operator visibility, universal integer/real resolution, expected-type propagation, static expression evaluation, modular/fixed/floating arithmetic, array/string/access/tagged equality, enumeration ordering, generic formal operator substitution, callable profile agreement, assignment/conversion consumers, subtype/range/predicate consumers, generic replay consumers, contract/predicate consumers, runtime-check classification, indeterminate evidence preservation, and semantic consumer surfacing.

The pass rejects disagreement between static evaluation and overload resolution, missing predefined operators, incorrect use-type operator visibility, ambiguous user-defined operators, no-visible-operator cases, lost primitive operator preference, callable-profile disagreement, lost generic formal operator substitution, incompatible numeric operand families, static divide-by-zero, illegal exponentiation exponents, static overflow, runtime-check evidence loss, stale source/AST/operator/type/expected-type/static/overload/profile/substitution/effect/consumer fingerprints, and consumer-local numeric interpretations.

Added Test_Ada_RM_Gap_Burn_Down_Pass1357 and registered it in Core_Suite.  The AUnit coverage includes legal, illegal, legal-with-runtime-check, indeterminate, cross-slice consumer, and stale-fingerprint source-shaped rows.
