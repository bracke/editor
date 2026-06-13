Pass1359 - RM Gap Burn-Down Pass 17: Source Unit Semantic Closure

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1359 and its AUnit
coverage.  It is the first burn-down pass that stops validating one
feature family at a time and instead requires whole source-shaped Ada
units to converge to one final semantic verdict.

The pass covers whole package spec/body closure, whole generic unit
closure, tagged/interface hierarchy closure, task/protected/concurrent
closure, representation/interfacing closure, and consumer-visible final
verdicts.  It checks context clauses, private/full views, body/spec
conformance, elaboration, representation/freezing, contracts/flow,
generic substitution/body replay, overload/profile/literal/operator
agreement, dispatching effect joins, shared-state effects, parallel
iterator interaction, finalization/abort evidence, RM coverage and
remediation evidence, balanced regression evidence, precision-state
preservation, and canonical consumer agreement.

The AUnit suite exercises legal, illegal, legal-with-runtime-check, and
indeterminate rows.  It rejects stale source/AST/type/profile/unit/
substitution/effect/policy/consumer fingerprints, non-source-shaped
rows, unconsumed results, missing remediation coverage, lost precision,
and conflicting consumer final verdicts.
