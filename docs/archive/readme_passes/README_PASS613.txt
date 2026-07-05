Pass 613 - Literal-aware copied String Range attribute delimiter selection

- Replaced the copied String Range constraint delimiter lookup with a literal-aware attribute scanner.
- The scanner now skips Ada string literals, character literals, and qualification apostrophes such as String'(...) before accepting the real top-level Range attribute designator.
- This prevents optional Range dimension expressions containing Character'Pos or character literals from masking the source Range attribute.
- Added regression coverage for an inline qualified String Range copy with a Character'Pos-based dimension expression feeding representation-expression static values.
