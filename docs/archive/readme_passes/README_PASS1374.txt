Pass1374 - Remaining Gap Remediation Pass 8

Added Editor.Ada_RM_Remaining_Gap_Remediation_Pass1374.

Selected concrete Pass1366 inventory gap:

  Remaining_Static_String_Slice_Bounds_Edge

This pass remediates a source-shaped edge where string and character literal
bounds, slices, indexes, assignments, aggregates, membership/case choices, and
semantic consumers must share one canonical literal/root-type/range result.
It closes the gap between static-expression/choice evidence, subtype/range
classification, literal resolution, aggregate/assignment consumers, and final
readiness reporting.

The remediation enforces:

* static string slice lower/upper ordering,
* static index bounds rejection,
* string length compatibility with expected array targets,
* character/element type compatibility,
* null literal rejection outside access contexts,
* runtime index and range-check preservation,
* indeterminate state for missing expected array or index subtype evidence,
* stale static-evidence rejection,
* semantic consumer surfacing and final readiness gap removal,
* source/AST/type/static/choice/consumer fingerprint freshness.

Added AUnit coverage:

  Test_Ada_RM_Remaining_Gap_Remediation_Pass1374

Registered the suite in Core_Suite.
