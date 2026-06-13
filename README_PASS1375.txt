Pass1375 - Remaining fixed-point conversion/rounding gap remediation

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1375.

Selected concrete Pass1366-style remaining gap:

  Remaining_Fixed_Point_Conversion_Rounding_Edge

This pass remediates a fixed-point semantic edge where decimal/ordinary
fixed-point conversions, universal-real resolution, delta/digits evidence,
rounding classification, static overflow, runtime range/predicate checks,
assignment/conversion consumers, predicate/contract consumers, and diagnostics
must share one canonical result.

The model rejects static fixed-point failures as hard illegality, preserves
runtime range/predicate checks as legal-with-runtime-check, and reports missing
fixed target, delta/digits, or stale static evidence as indeterminate instead
of inventing a legal or illegal result.

Added AUnit coverage in:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1375

The tests cover legal, illegal, runtime-check, indeterminate, inventory-gate,
final-gate, corpus-balance, consumer, and fingerprint cases.
