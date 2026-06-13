Pass 556 - Character alias static literal propagation

Implemented another bounded precise static-evaluation pass for Ada representation legality.

Changes:
- Added retained static Character-type metadata for subtype aliases and derived scalar types.
- Character aliases now preserve character-literal compatibility without materializing all predefined Character literals.
- Static evaluation now accepts character literals through aliased/derived Character types for:
  - T'Pos ('A')
  - T'Succ ('A') / T'Pred ('B')
  - T'Min ('A', 'B') / T'Max ('A', 'B')
  - T'Base'Min / T'Base'Max forms
- The same metadata flows into natural-valued representation expressions, signed static expressions, and numeric-only clauses such as Small.
- Added regression coverage for subtype and derived Character static literal use.

Scope:
- This remains bounded to ordinary single-code-unit character literal source spellings.
- Wider/escaped Character literal forms remain nonstatic until lexer-decoded character tokens are retained.
