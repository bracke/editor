Pass1342 -- Semantic regression corpus balance audit

This pass adds Editor.Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342.

The pass is the eighth post vertical-slice integration/audit pass. It checks that covered Ada RM semantic families are backed by balanced source-shaped regression evidence instead of one-sided positive or negative tests.

The audit requires, where applicable, that each covered family has:

* a legal source-shaped scenario,
* an illegal source-shaped scenario with stable blocker-family identity,
* a legal-with-runtime-check scenario,
* an indeterminate/blocked scenario,
* and a scenario that reaches a real semantic consumer.

It rejects covered families with only positive tests, only negative tests, missing runtime-check scenarios, missing indeterminate scenarios, missing consumer-surfaced scenarios, runtime-check cases collapsed into hard illegal diagnostics, indeterminate cases collapsed into legal or illegal results, non-source-shaped corpus rows, stale corpus/source/AST/type/profile/substitution/effect/consumer fingerprints, duplicate rows that add no rule coverage, unstable blocker families, and partial/missing families treated as balanced.

The pass adds AUnit coverage in Test_Ada_Semantic_Regression_Corpus_Balance_Audit_Pass1342 and registers it in Core_Suite.
