Pass 512 - class-wide property-name canonicalization for aspect/attribute unification

Implemented another representation/operational unification pass.

Changes:
- Added canonical property-name normalization for the shared representation /
  operational property resolver.
- Normalizes whitespace around class-wide attribute ticks, so forms such as
  Pre'Class, Pre 'Class, and Pre' Class map to the same retained property kind.
- Applied the same canonical name path to aspect recognition and Boolean aspect
  defaulting, not only attribute-definition clause lowering.
- Added regression coverage proving spaced class-wide aspect marks and spaced
  class-wide attribute-definition clauses share the same explicit kinds for
  Type_Invariant'Class, Pre'Class, Post'Class, and Nonblocking'Class.
