Pass1366 - Final RM Remaining-Gap Extraction Burn-Down

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1366 and its AUnit suite.

The pass uses the final semantic readiness gate from Pass1365 to extract the
remaining Ada RM gaps as deterministic, source-shaped, owned inventory rows.
It is intentionally not another broad readiness wrapper: it separates concrete
missing RM implementation from missing evidence, project/recovery blockers,
stale/cancelled/budget states, and consumer surfacing disagreement.

The extraction model classifies a snapshot or RM family as:

* Ready
* Ready_With_Runtime_Checks
* Ready_With_Warnings
* Blocked_By_Evidence
* Blocked_By_Project_State
* Blocked_By_Missing_RM_Checker
* Blocked_By_Partial_RM_Coverage
* Blocked_By_Consumer_Disagreement

It rejects:

* partial rows without concrete missing subrules
* missing checker rows without candidate package/pass ownership
* missing checker rows not mapped to an Ada RM family
* indeterminate evidence misclassified as missing implementation
* stale, cancelled, or budget-exceeded state counted as RM incompleteness
* consumer surfacing gaps hidden behind covered RM status
* final clean readiness while partial/missing entries remain
* non-source-shaped or nondeterministic reports
* stale source/AST/type/profile/unit/project-index/closure/substitution/effect/
  policy/recovery/consumer/request fingerprints

The AUnit suite covers balanced extraction, partial/missing gap ownership,
separation of evidence/project/cancelled/budget states, consumer surfacing
visibility, and report/fingerprint enforcement.
