Pass1379 - Remaining Gap Remediation Pass 13

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1379.

Selected concrete remaining gap:

  Remaining_Preelaborate_Restriction_Allocator_Edge

This pass remediates a policy/access/allocation edge where configuration pragmas,
Restrictions/Restriction_Warnings, preelaborable initialization, allocator/access
legality, assertion/suppression runtime checks, and semantic consumers must share
one canonical policy result.

The remediation preserves and checks:

* configuration pragma placement evidence;
* categorization conflict evidence;
* No_Allocators hard restriction violations;
* Restriction_Warnings warning-only allocator evidence;
* preelaborable initialization access-object blockers;
* runtime assertion/suppression check preservation;
* private/full-view indeterminate blockers;
* stale policy evidence rejection;
* consumer surfacing for diagnostics, hover/details, colouring, outline/navigation,
  and build bridge paths;
* final readiness gap removal; and
* source/AST/type/profile/policy/consumer fingerprint freshness.

Added AUnit coverage:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1379

The tests cover legal, illegal, runtime-check, warning-only, indeterminate,
inventory-gate, final-gate, corpus-balance, consumer, and fingerprint cases.
