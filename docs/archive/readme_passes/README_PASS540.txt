Pass 540 - Static numeric compatibility refinement

This pass deepens the precise static-evaluation work from pass 539.

Implemented:
- Added a clause-level static numeric expression recognizer for numeric-only
  representation properties such as Small.
- Small now accepts universal-real static arithmetic over retained named
  numbers and static constants, for example `Small_One / Small_Two`.
- Static constants whose defaults are numeric static expressions are now
  registered as later numeric static names even when their default does not
  begin with a literal token.
- Integer-valued representation clauses still require retained Natural
  evaluation; the numeric recognizer is only used for numeric-compatible
  properties such as Small.
- Added regression coverage ensuring derived universal-real constants are
  accepted for Small while expressions containing unknown nonstatic names are
  rejected.

Bounded scope:
- The retained model still does not compute exact rational/real values.  It
  recognizes static numeric compatibility for real-valued representation
  properties and preserves exact integer values only for clauses that require
  Natural storage-unit values.
