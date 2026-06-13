Pass1376 - Remaining enumeration attribute / representation gap remediation

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1376 and its AUnit suite.

Selected concrete remaining gap:

  Remaining_Enumeration_Attribute_Representation_Edge

The pass remediates a focused enumeration semantic edge where enumeration representation clauses, literal identity, language-defined enumeration attributes, static expression evaluation, choices, assignments/conversions, and semantic consumers must agree on one canonical result.

The pass covers:

* enumeration representation completeness and duplicate representation codes
* non-static enumeration representation values
* Pos/Val/Succ/Pred bounds legality
* Value-style runtime checks
* ambiguous enumeration/character literal rejection
* private/full-view indeterminate blockers
* stale representation/static evidence rejection
* consumer-surfaced final readiness gap removal

The AUnit tests cover legal, illegal, runtime-check, indeterminate, inventory-gate, final-gate, corpus-balance, consumer, and fingerprint cases.
