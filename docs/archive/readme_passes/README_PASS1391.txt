Pass1391 - Remaining modular type size/operator edge remediation

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1391 and the
associated AUnit suite Test_Ada_RM_Remaining_Gap_Remediation_Pass1391.

Selected remaining-gap inventory item:

  Remaining_Modular_Type_Size_Operator_Edge

The pass closes a concrete modular numeric semantics gap where modular type
modulus/size evidence must be consumed consistently by predefined modular
operators, static expression evaluation, representation clauses,
assignment/conversion, range/predicate checks, and semantic consumers.

The remediation model covers:

* static modulus requirements;
* modulus/size and representation conflicts;
* static overflow classification;
* runtime range/overflow check preservation;
* warning-only policy preservation;
* private/full-view and missing-modulus indeterminate blockers;
* stale modular/representation evidence rejection;
* consumer surfacing and final readiness gap removal;
* balanced legal, illegal, runtime-check, warning-only, indeterminate,
  consumer, inventory, final-gate, and fingerprint evidence.

The test suite is registered in Core_Suite.
