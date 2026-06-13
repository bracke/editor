Pass1389 - Remaining record-layout / variant-component representation remediation

Adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1389 and its AUnit
coverage.  The pass remediates the concrete remaining gap
Remaining_Record_Layout_Variant_Component_Edge.

The new source-shaped remediation gate keeps record representation clauses,
variant-dependent components, discriminant-dependent layout, controlled
component layout hazards, runtime range/predicate checks, private/full-view
indeterminate states, and consumer surfacing in one canonical result.

It rejects variant component overlap, illegal discriminant-dependent layout,
controlled/finalized component layout hazards, stale representation evidence,
missing component/full-view evidence, unbalanced regression evidence, and stale
source/AST/type/representation/discriminant/consumer fingerprints.

The pass is registered in Core_Suite through
Test_Ada_RM_Remaining_Gap_Remediation_Pass1389.
