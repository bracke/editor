Pass1407 - Remaining array slice writable alias call edge remediation

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1407.

This pass remediates Remaining_Array_Slice_Writable_Alias_Call_Edge, a concrete remaining call/array/alias edge where overlapping array slices or components are passed to writable call formals. The pass forces call actual association, parameter mode legality, array slice/index bounds, writable alias evidence, volatile/atomic ordering, runtime-check preservation, and semantic consumer surfacing to share one canonical result.

The new model rejects writable slice/component alias overlap, constant-view writable actuals, mode mismatch, static slice out of range, volatile/atomic ordering conflicts, stale alias evidence, missing alias evidence, private/full-view indeterminate blockers, unbalanced regression evidence, missing Pass1366 inventory ownership, missing concrete subrule ownership, unconsumed results, consumer disagreement, and stale source/AST/type/profile/alias/effect/consumer fingerprints.

Added Test_Ada_RM_Remaining_Gap_Remediation_Pass1407 and registered it in Core_Suite. The tests cover legal, illegal, runtime-check, warning-only, indeterminate, inventory-gate, consumer-gate, and fingerprint scenarios.
