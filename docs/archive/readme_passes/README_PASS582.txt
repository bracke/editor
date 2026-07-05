Pass582: Character-valued static expressions now participate directly in bounded static string concatenation.

Changes:
- Extended static string expression evaluation beyond named Character constants to any bounded Character-valued static expression accepted by the discrete evaluator.
- Direct operands such as Character'Val (71), Character'Succ ('F'), and Character'(Character'Val (71)) can now act as one-character String operands in concatenation.
- Added AUnit regression coverage proving these expression-built strings feed Color'Value and retained String'Length representation expressions.
- Cleaned the adjacent regression-source literal spelling for newly added string constants so quoted Ada source text is represented with doubled quotes inside the test harness.
