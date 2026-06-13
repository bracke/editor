Pass1378 - Remaining exception handler/reraise/finalization edge remediation

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1378 and a focused
AUnit suite.  It burns down the concrete remaining gap
Remaining_Exception_Handler_Reraise_Finalization_Edge instead of adding a broad
meta-audit layer.

The remediation requires one canonical exception/finalization result for handler
choices, reraise legality, exception propagation, controlled finalization,
task/abort finalization hazards, runtime propagation checks, indeterminate
private-view/missing-handler/stale-finalization evidence, and semantic consumer
surfacing.

The pass rejects duplicate or unreachable handler choices, reraise outside a
handler, handler-kind mismatch, controlled Finalize profile mismatch,
finalization ordering hazards, task/abort finalization hazards, consumer
surface disagreement, missing Pass1366 inventory evidence, vague subrule names,
missing candidate ownership, unbalanced regression evidence, unconsumed results,
and stale source/AST/type/exception/finalization/consumer fingerprints.
