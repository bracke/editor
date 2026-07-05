Pass1403 - Remaining Gap Remediation Pass 37

Selected concrete remaining gap:

Remaining_Formal_Derived_Interface_Private_View_Edge

This pass remediates a generic/tagged/interface edge where a formal derived type with private/full-view evidence implements an interface and is later consumed by dispatching/profile/contract/effect consumers.

It enforces agreement across:

- formal derived parent compatibility
- private/full-view availability
- interface primitive implementation
- abstract primitive implementation
- private-view leak rejection
- dispatching profile compatibility
- runtime tag-check preservation
- warning-only preservation
- generic formal type family evidence
- tagged/interface dispatching evidence
- contract/effect consumer agreement
- semantic consumer surfacing
- final readiness gap removal
- source/AST/type/profile/substitution/interface/effect/consumer fingerprint freshness

Added:

- src/core/editor-ada_rm_remaining_gap_remediation_pass1403.ads
- src/core/editor-ada_rm_remaining_gap_remediation_pass1403.adb
- tests/src/test_ada_rm_remaining_gap_remediation_pass1403.ads
- tests/src/test_ada_rm_remaining_gap_remediation_pass1403.adb

Registered in Core_Suite.
