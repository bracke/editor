Pass1406 - Remaining Gap Remediation Pass 40

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1406.

Selected concrete remaining gap:

Remaining_Array_Slice_Index_Constraint_Edge

This remediates an array slice/index constraint semantic edge requiring agreement across:

- array prefix legality
- multidimensional index-count compatibility
- index subtype compatibility
- static index out-of-range rejection
- slice bound discreteness checks
- runtime index-check preservation
- warning-only preservation
- private/full-view indeterminate blockers
- missing index-subtype evidence blockers
- stale array/index evidence rejection
- aggregate, assignment, array indexing, slice, and diagnostic consumer agreement
- final readiness gap removal
- source/AST/type/static/index/effect/consumer fingerprint freshness

Added AUnit coverage:

Test_Ada_RM_Remaining_Gap_Remediation_Pass1406

Registered the new test in Core_Suite.
