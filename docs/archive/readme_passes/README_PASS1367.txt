Pass1367 - Remaining Gap Remediation Pass 1

This pass starts the post-inventory remediation phase after Pass1366.  It deliberately remediates one concrete remaining gap instead of adding another broad audit package.

Implemented package:

  Editor.Ada_RM_Remaining_Gap_Remediation_Pass1367

Selected remaining gap:

  Remaining_Call_Defaulted_Null_Exclusion_Access_Edge

The gap covers call actual association where a defaulted access formal has a null exclusion and the semantic model must preserve null-exclusion legality, accessibility classification, callable-profile agreement, overload agreement, generic substitution profile evidence, renaming profile evidence, access-to-subprogram convention evidence, and consumer surfacing.

The pass enforces:

  * the selected row must come from the Pass1366 remaining-gap inventory;
  * the missing subrule must be concrete and owned by a candidate package/pass;
  * a new legality rule must be present;
  * RM coverage and remediation state must be promoted to Covered only with evidence;
  * source-shaped legal, illegal, runtime-check, indeterminate, and consumer-surfaced regression evidence must exist;
  * diagnostics/colouring/outline/navigation/hover/build-bridge consumers must not reinterpret the result independently;
  * source, AST, call, type, profile, overload, substitution, accessibility, and consumer fingerprints must be fresh.

The concrete legality cases covered are:

  * legal defaulted non-null access actual for a null-excluded formal;
  * illegal defaulted null actual for a null-excluded formal;
  * illegal explicit null actual for a null-excluded formal;
  * illegal static accessibility escapes;
  * legal-with-runtime-check accessibility cases;
  * missing profile/type/substitution/cross-unit evidence as indeterminate, not hard illegal;
  * malformed call association rows: missing required actual, extra actual, duplicate actual, invalid named/positional ordering;
  * callable-profile, overload-profile, generic-substitution, renaming, and access-to-subprogram convention disagreement.

Added AUnit suite:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1367

Registered in:

  Core_Suite
