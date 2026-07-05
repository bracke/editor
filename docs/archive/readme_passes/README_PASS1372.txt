Pass1372 - Remaining Gap Remediation Pass 6

Selected concrete remaining gap:

  Remaining_Limited_With_Generic_Formal_View_Edge

This pass remediates a source-shaped edge where a limited-with view and a
generic formal view meet through selected-name, context-clause, instantiation,
renaming/alias, and consumer evidence.  The gap is concrete: a generic formal or
renamed entity visible only through a limited view must not be promoted to a full
canonical declaration unless the full cross-unit evidence is present and fresh.

The remediation enforces agreement across:

  * limited-with and full-view context evidence,
  * generic formal view identity,
  * selected-name and renamed-target visibility,
  * private/full/limited-view agreement,
  * alias-cycle and alias-depth rejection,
  * callable profile and type/view preservation through aliases,
  * runtime accessibility-check preservation,
  * consumer surfacing for diagnostics, colouring, outline/navigation,
    hover/details, and build bridge paths,
  * Pass1366 remaining-gap removal and final readiness evidence.

The accompanying AUnit suite covers legal, illegal, runtime-check,
indeterminate, inventory-gate, final-gate, corpus-balance, consumer, and
fingerprint cases for this concrete edge.
