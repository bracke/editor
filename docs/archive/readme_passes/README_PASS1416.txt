Pass1416 - Remaining_Decimal_Fixed_Point_Attribute_Edge

This pass adds Editor.Ada_RM_Remaining_Gap_Remediation_Pass1416 and the matching AUnit package Test_Ada_RM_Remaining_Gap_Remediation_Pass1416.

The concrete remaining gap remediated by this pass is decimal fixed-point attribute legality when source-shaped contexts depend on Delta, Small, Fore, Aft, First, Last, decimal scale, digits, expected-type resolution, static range validation, and rounding behavior. The pass ties together type evidence, attribute evidence, scale/delta/digits evidence, runtime rounding-check preservation, warning-only preservation, stale scale evidence, consumer surfacing, final readiness, and fingerprint freshness into one stable blocker family:

RM.Decimal.Fixed_Point.Attribute

Covered source-shaped cases include:

* legal decimal fixed-point attribute resolution against a compatible fixed-point type;
* legal static Delta/Small/Fore/Aft attribute value resolution;
* illegal attribute use on a non-decimal-fixed target;
* illegal delta/digits mismatch rejection;
* illegal Small value not matching the decimal scale evidence rejection;
* illegal attribute expected-type mismatch rejection;
* illegal static range overflow rejection;
* runtime rounding-check preservation without promoting it to a static illegality;
* warning-only preservation without converting a warning into an illegality;
* private/full-view indeterminate blockers;
* missing fixed-point type evidence blockers;
* missing attribute evidence blockers;
* stale scale/delta/digits evidence blockers;
* diagnostic consumer agreement for decimal fixed-point attribute state;
* final-readiness gap removal;
* source, AST, type, profile, attribute, scale, effect, and consumer fingerprint freshness gates.

The pass is registered in Core_Suite and advances the Remaining Gap Remediation series beyond pass1415 without adding a broad audit/status/projection layer.
