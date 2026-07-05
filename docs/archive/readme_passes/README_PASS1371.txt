Pass1371 - Remaining Gap Remediation Pass 5

Selected concrete Pass1366 inventory gap:

  Remaining_Private_Child_Renaming_Visibility_Edge

This pass remediates a specific name/visibility edge where a private-child
entity is reached through a renaming or alias. The remediation requires one
canonical result across direct/selected visibility, private-child barriers,
renamed target visibility, alias-cycle detection, profile/type/view
preservation, use-visible homographs, runtime accessibility checks, and real
semantic consumer surfacing.

Added package:

  Editor.Ada_RM_Remaining_Gap_Remediation_Pass1371

Added tests:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1371

The tests cover legal, illegal, runtime-check, indeterminate, inventory-gate,
final-gate, corpus-balance, consumer, and fingerprint cases. The selected gap
may be promoted only when Pass1366 inventory ownership is present, concrete
subrule ownership is named, coverage/remediation reaches Covered, the final gate
no longer reports the gap, and diagnostics/navigation/hover-style consumers use
the same canonical visibility/renaming evidence.
