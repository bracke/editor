# Editor Phase 579 pass705 — Attribute grammar depth

This pass deepens the token-cursor grammar for Ada attribute references while preserving the Phase 579 language-intelligence invariants.

## Implemented

- Added explicit attribute designator-name markers for attribute references and attribute-definition clauses.
- Added class-wide attribute-reference markers for chains such as `T'Class'Object_Size`.
- Added subtype-mark attribute-reference markers for forms such as `T'Class` in access and subtype contexts.
- Added attribute argument association and expression markers for argument-bearing attributes such as `A'First (1)` and `T'Image (X)`.
- Added bounded recovery markers for malformed attribute argument parts such as a missing expression after `=>`.
- Added AUnit coverage for argument-bearing attributes, class-wide attribute chains, subtype-mark attributes, malformed argument recovery, and continuation into following declarations.
- Updated validation/release guard markers and documentation.

## Non-goals

This is structural grammar coverage only. It is not compiler-grade legality checking for attribute availability, prefix category legality, staticness, dimensionality, subtype-vs-expression resolution, overload resolution, attribute result typing, or implementation-defined attributes.
