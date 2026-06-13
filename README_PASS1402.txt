Pass1402: Remaining Gap Remediation Pass 36

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1402.

Selected concrete remaining gap:

Remaining_Formal_Package_Nested_Instance_Edge

This remediation closes a generic formal-package / nested-instantiation edge that requires generic contract matching, formal-package actual evidence, nested instance body replay, private/full-view barriers, runtime instantiation checks, warning-only policy preservation, semantic consumers, and the final readiness gate to agree on one canonical result.

The pass enforces:

- formal package actual contract legality
- nested generic instance actual presence
- formal package private-view leak rejection
- nested instantiation cycle rejection
- runtime instantiation-check preservation
- warning-only preservation
- private/full-view indeterminate blockers
- missing nested-instance evidence blockers
- stale generic and instance evidence rejection
- generic replay and diagnostic consumer agreement
- final readiness gap removal
- source/AST/type/generic/instance/consumer fingerprint freshness

Added AUnit coverage in Test_Ada_RM_Remaining_Gap_Remediation_Pass1402 and registered it in Core_Suite.
