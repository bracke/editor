Editor phase579 IDE-grade Ada language model pass338

This pass continues the token-cursor Ada grammar work from pass337.

Implemented:
- Added token-cursor grammar productions for pragma argument associations.
- Added token-cursor grammar productions for aspect associations.
- Added token-cursor grammar productions for generic actual parts and generic actual associations.
- Added token-cursor grammar productions for record representation clauses and representation component clauses.
- Parsed package and subprogram generic instantiation actual parts instead of skipping them as opaque declaration tails.
- Parsed aspect specifications after type declarations into association productions instead of retaining only a coarse aspect-spec marker.
- Parsed record representation clauses such as `for T use record ... end record;` with component-clause productions.
- Added AUnit coverage for metadata and representation token-cursor grammar completeness.
- Extended phase579 language validation guards.

Validation notes:
- The project archive contains no Python, pyc, or shell scripts.
- Node_Kind and Production_Kind enumerator lists were checked for duplicate entries.
