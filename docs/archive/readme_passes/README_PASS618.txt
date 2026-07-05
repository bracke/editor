Pass 618 - Nested discrete Min/Max argument splitting

- Tightened bounded discrete static attribute-function parsing for `T'Min` and `T'Max`.
- The Min/Max operand splitter now selects the separating comma only at top level, skipping nested parentheses, Ada string literals, and Ada character literals.
- Newly covered retained form: `Color'Max (Color'Min (Red, Green), Blue)`.
- Nested Min/Max discrete constants now feed later `T'Pos` representation-expression static values through the retained discrete static environment.
- Added regression coverage in the qualified discrete constant pass.
