Pass1377 — Remaining Gap Remediation Pass 11

Selected concrete remaining gap:

  Remaining_Access_Discriminant_Return_Object_Finalization_Edge

This pass remediates a lifetime/accessibility edge left by the remaining-gap
inventory.  It forces access discriminants, returned aggregate components,
allocator-created objects, generic access actual substitution, and
controlled/finalized return ownership to use one canonical master/lifetime and
accessibility result.

The new package is:

  Editor.Ada_RM_Remaining_Gap_Remediation_Pass1377

The pass distinguishes:

  * legal access-discriminant/return-object lifetime agreement,
  * static access-discriminant escapes,
  * returned component escapes,
  * controlled finalization owner mismatches,
  * allocator finalization hazards,
  * static accessibility escapes,
  * generic substitution lifetime mismatches,
  * runtime accessibility checks,
  * missing master evidence,
  * private/full-view blockers,
  * stale lifetime evidence,
  * consumer-surface disagreement.

It also keeps the remediation gates from Pass1366/Pass1365 intact: concrete
subrule ownership, source-shaped evidence, balanced legal/illegal/runtime/
indeterminate tests, semantic consumer surfacing, final readiness removal, and
fresh source/AST/type/accessibility/lifetime/consumer fingerprints.

Added AUnit coverage:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1377

The suite covers legal, illegal, runtime-check, indeterminate, inventory-gate,
consumer, and fingerprint scenarios for this concrete remaining gap.
