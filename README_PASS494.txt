Pass 494 - broader representation/operational property unification

Implemented another bounded Ada language-model completeness pass over aspect vs
attribute-definition clause handling.

Highlights:
- Added explicit retained representation/operational kinds for:
  - No_Controlled_Parts
  - Preelaborable_Initialization
  - Discard_Names
  - Volatile_Function
- Lowered matching aspect specifications and attribute-definition clauses into
  the same representation metadata path.
- Added default True handling for Boolean aspects without explicit values.
- Added shared target compatibility routing:
  - No_Controlled_Parts / Preelaborable_Initialization: type-like targets
  - Discard_Names: type-like targets and exceptions
  - Volatile_Function: subprogram-like targets
- Added shared static Boolean legality checking for these properties.
- Expanded the representation/operational unification regression to prove
  aspect and attribute-definition forms use the same explicit kinds and
  diagnostics.

This pass continues the phase-579 parser/language-model completeness work by
reducing another set of formerly loose representation/operational properties to
one semantic path regardless of source spelling.
