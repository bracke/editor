Pass 557 - Static Width attributes for discrete scalar evaluation

Implemented another bounded precise-static-evaluation pass in the Ada semantic
language model.

Changes:
- Added retained static evaluation for the scalar Width attribute.
- Supported enumeration Width from retained literal metadata.
- Supported aliased/chained forms such as T'Base'Width.
- Added predefined Boolean Width support.
- Added bounded Character / Character-alias Width support for ordinary character
  literals and representation arithmetic.
- Wired Width through Natural-valued representation expressions, signed static
  expressions, and numeric-only clauses such as Small.
- Added regression coverage for enumeration, aliased enumeration, Boolean,
  Character alias, Base'Width, and Small numeric-recognition uses.
