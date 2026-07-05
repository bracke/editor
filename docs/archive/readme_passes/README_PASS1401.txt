Pass1401: Remaining Gap Remediation Pass 35

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1401.

Selected concrete remaining gap:

Remaining_Null_Record_Aggregate_Box_Default_Edge

This remediation closes a null-record aggregate and box-default edge that requires aggregate legality, discriminant/default evidence, component default availability, runtime default checks, private/full-view blockers, aggregate/assignment consumers, diagnostics, and the final readiness gate to agree on one canonical result.

The pass enforces:

- null record aggregate legality
- box/defaulted component evidence
- missing box default rejection
- discriminant default mismatch rejection
- limited component default availability rejection
- runtime default/range/predicate check preservation
- warning-only preservation
- private/full-view indeterminate blockers
- missing component-default evidence blockers
- stale aggregate/default evidence rejection
- aggregate and diagnostic consumer agreement
- final readiness gap removal
- source/AST/type/aggregate/default/consumer fingerprint freshness

Added AUnit coverage in Test_Ada_RM_Remaining_Gap_Remediation_Pass1401 and registered it in Core_Suite.
