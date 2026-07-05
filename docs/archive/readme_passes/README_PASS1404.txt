Pass1404 -- Remaining access-to-subprogram convention/default remediation edge

Adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1404 and
Test_Ada_RM_Remaining_Gap_Remediation_Pass1404.

The pass remediates the concrete remaining gap
Remaining_Access_Subprogram_Convention_Default_Edge.  It forces a single
source-shaped result for access-to-subprogram calls and defaulted access
formals where callable profile conformance, convention compatibility,
null-exclusion legality, protected-access profile evidence, static versus
runtime accessibility classification, generic substitution, renaming, and
consumer-visible final readiness must agree.

The remediation gate rejects missing Pass1366 inventory ownership, unnamed
subrules, missing candidate packages, unpromoted coverage, unbalanced
regression evidence, unconsumed semantic results, unstable blocker families,
stale source/AST/type/profile/substitution/convention/effect/consumer
fingerprints, explicit or defaulted null actuals for null-excluding formals,
convention mismatches, default-expression profile mismatches, protected access
profile mismatches, static accessibility escapes, and missing or stale
access-to-subprogram evidence.
