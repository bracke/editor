Pass1287 - Remaining RM edge recheck eligibility

This pass adds Editor.Ada_Remaining_RM_Edge_Recheck_Eligibility_Legality.

It consumes the Pass1286 remaining RM edge remediation worklist and converts
ordered prerequisite blockers into bounded recheck eligibility rows. Accepted
remaining-edge rows stay current non-recheck evidence; unresolved blockers remain
withheld and continue to block downstream semantic trust until the matching
prerequisite family is resolved.

Preserved blocker families include remaining RM edge blockers, stabilized closure
blockers, source/substitution fingerprint blockers, multiple prerequisites,
recheck-required rows, and indeterminate rows.

Added AUnit coverage:
  tests/src/test_ada_remaining_rm_edge_recheck_eligibility_legality_pass1287.ads
  tests/src/test_ada_remaining_rm_edge_recheck_eligibility_legality_pass1287.adb
