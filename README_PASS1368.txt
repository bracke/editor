Pass1368 - Remaining Gap Remediation Pass 2

Selected Pass1366 remaining inventory gap:

  Remaining_Generic_Discriminated_Private_Aggregate_Edge

This pass closes a concrete remaining generic/aggregate edge case rather than
adding another broad audit layer.  It requires generic body replay of an
aggregate actual for a discriminated private formal type to use substituted
actual evidence and the available full view before aggregate, discriminant,
variant, default-component, predicate, and consumer results can be promoted to
covered.

Implemented package:

  Editor.Ada_RM_Remaining_Gap_Remediation_Pass1368

AUnit coverage:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1368

The tests cover legal, illegal, runtime-check, indeterminate, inventory-gate,
final-gate, corpus-balance, consumer, and stale-fingerprint cases.

The remediated rule family is source-shaped and tied to Pass1366 inventory
ownership, Pass1365 final readiness removal, balanced regression evidence, and
consumer surfacing.  It rejects promotion when substitution evidence is missing,
the generic body replay still uses formal placeholders, the full actual view is
not used, discriminant/variant/default/predicate evidence is lost, or aggregate
consumers disagree with the canonical result.
