Pass1347 - RM gap burn-down pass 5: representation/freezing/interfacing

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1347 and the corresponding
AUnit suite Test_Ada_RM_Gap_Burn_Down_Pass1347.

The pass burns down the representation/freezing/interfacing cross-slice gap by
forcing one source-shaped semantic result across representation clauses,
operational stream attributes, freezing evidence, record and enumeration layout,
Convention/Import/Export/External_Name/Link_Name evidence, callable/profile
conventions, aggregate layout consumption, assignment/conversion representation
barriers, dispatching convention evidence, generic body replay representation
freshness, remediation state, balanced regression evidence, semantic consumers,
and source/AST/type/profile/substitution/representation/freezing/effect/consumer
fingerprints.

Concrete legality/remediation blockers include late representation and aspect
items after freezing, missing or wrong-kind representation targets, private/full
view freezing disagreement, nonstatic component positions, invalid first/last
bit ranges, record component overlap, record/component size overflow, alignment
and storage-order conflicts, incomplete or malformed enumeration representation
clauses, stream profile/view/external-representation conflicts, incompatible
Convention/C profiles, import/export target and duplicate/conflict errors,
External_Name/Link_Name legality, access-to-subprogram convention mismatches,
address/storage conflicts, cross-slice evidence loss, runtime-check evidence
loss, private/limited/incomplete/generic/missing cross-unit indeterminate states,
consumer model disagreement, unstable blockers, and stale fingerprints.

This continues the RM gap burn-down phase by closing a real compiler-grade
composition gap instead of adding another generic audit/provenance layer.
