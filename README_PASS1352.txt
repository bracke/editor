Pass1352 - RM Gap Burn-Down Pass 10: Pragmas / Configuration / Categorization / Restrictions

This pass adds Editor.Ada_RM_Gap_Burn_Down_Pass1352 and the AUnit suite
Test_Ada_RM_Gap_Burn_Down_Pass1352.

The pass burns down the global/unit-level policy gap left after the earlier
local and cross-unit semantic slices.  It forces one canonical source-shaped
result across configuration pragmas, restriction pragmas, restriction warnings,
unit categorization pragmas, assertion/suppression policies, interfacing and
No_Return interactions, volatile/atomic/independent state policy, tasking and
allocation restrictions, exception/finalization restrictions, remediation
promotion, balanced regression evidence, consumer surfacing, and fingerprint
freshness.

Concrete policy semantics covered:

* Configuration pragma placement and target applicability.
* Duplicate and conflicting configuration pragma rejection.
* Known restriction rule evidence.
* Hard Restrictions violations versus Restriction_Warnings preservation.
* Warning-only restriction evidence kept distinct from hard Ada legality errors.
* Pure, Preelaborate, Remote_Types, Shared_Passive, and Remote_Call_Interface
  categorization conflicts and dependency-category checks.
* Body/spec categorization agreement.
* Suppress/Unsuppress placement and runtime-check evidence preservation.
* Assert/Assertion_Policy Boolean and runtime assertion-check classification.
* Pack, Inline, No_Inline target legality.
* Import/Export/Convention, No_Return, Volatile, Atomic, and Independent
  interactions with existing interfacing, control-flow, and shared-state slices.
* Tasking/protected, access/allocation, and exception/finalization consumers of
  restriction policy.
* Elaboration consumers of unit categorization policy.
* Diagnostics, semantic colouring, outline/navigation-style consumers,
  hover/details, and build-diagnostic bridge agreement.
* Private, limited, incomplete, generic-formal, missing full-view, missing
  cross-unit, missing configuration, missing categorization, missing restriction,
  and missing policy evidence as indeterminate states rather than false hard
  diagnostics.
* Burn-down, source, AST, unit, type, profile, substitution, effect, policy,
  category, restriction, and consumer fingerprint freshness.

The AUnit suite includes balanced legal, hard-illegal, warning-only,
legal-with-runtime-check, and indeterminate scenarios, plus explicit audit-gate
and consumer-disagreement rejection cases.
