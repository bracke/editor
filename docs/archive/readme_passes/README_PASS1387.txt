Pass1387 - Remaining Gap Remediation Pass 21

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1387.

Selected concrete remaining gap:

  Remaining_Recovered_Context_Clause_Project_Index_Edge

This pass remediates a recovered-source/project-index edge where partial or
recovered context clauses must not be promoted into the project semantic index,
must not leak private-child visibility, and must be surfaced as indeterminate
evidence until source shape, target unit identity, and project-index closure are
fresh and complete.

The remediation enforces agreement across:

* recovered ordinary/private/limited with clauses
* partial use clauses and missing context targets
* open-buffer/project-index source precedence
* duplicate library-unit rejection after recovery
* private-child visibility barrier preservation
* stale project-index and closure fingerprint rejection
* runtime-check and warning-only preservation
* diagnostics, semantic colouring, outline/navigation, hover/details, and build
  bridge consumer surfacing
* final readiness gap removal

Added AUnit coverage in Test_Ada_RM_Remaining_Gap_Remediation_Pass1387 and
registered it in Core_Suite.
