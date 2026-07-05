Pass 343 — token-cursor generic formal grammar completeness

This pass extends the Ada token-cursor grammar with explicit production families for generic formal declarations.

Implemented:
- Formal object declarations.
- Formal type declarations.
- Formal private, derived, discrete, signed integer, modular, floating point, ordinary fixed point, decimal fixed point, array, access, and interface type definitions.
- Formal procedure/function declarations.
- Formal package declarations with generic actual parts.
- AUnit coverage for every newly represented formal family.
- Validation guards for token-cursor formal grammar productions and tests.

The grammar remains bounded and editor-owned; this pass improves parser structure without introducing external parser generators, scripts, or runtime-side parsing.
