Pass1385 — Remaining Diagnostic / Runtime / Warning Source-Span Remediation

This pass remediates a concrete remaining-gap inventory edge:

  Remaining_Diagnostic_Runtime_Warning_Source_Span_Edge

The new package Editor.Ada_RM_Remaining_Gap_Remediation_Pass1385 makes diagnostic surfacing part of the remaining-gap burn-down instead of treating it as a cosmetic projection. It enforces that internal Ada semantic evidence preserves one canonical blocker family, precision class, smallest meaningful source span, secondary evidence ordering, runtime-check state, warning-only state, and consumer-visible status.

The checker distinguishes:

  * legal rows with no diagnostic;
  * hard-illegal rows with precise source spans;
  * legal-with-runtime-check rows;
  * warning-only policy rows;
  * indeterminate recovered-syntax/source-span rows;
  * stale diagnostic rows;
  * duplicate diagnostics;
  * generic fallback blockers used where a precise RM blocker exists;
  * whole-declaration spans used where an association, selector, actual, attribute, or operator span is available;
  * consumer disagreement across diagnostics, hover/details, colouring, outline/navigation, and build bridge paths.

The pass also keeps the Pass1366 inventory gates: concrete subrule name, owner package/pass, source-shaped evidence, coverage promotion, final readiness removal, balanced legal/illegal/runtime-check/warning/indeterminate tests, consumer surfacing, blocker stability, and fingerprint freshness.

AUnit coverage is provided by Test_Ada_RM_Remaining_Gap_Remediation_Pass1385 and registered in Core_Suite.
