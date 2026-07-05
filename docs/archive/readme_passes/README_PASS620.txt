Pass 620 - Nested discrete operands in direct Min/Max arithmetic

- Tightened the bounded discrete natural operand fallback used by direct scalar Min/Max/Succ/Pred static-integer evaluation.
- The fallback scanner now skips Ada string literals, Ada character literals, and nested parentheses before accepting the requested comma or right-parenthesis delimiter.
- Direct representation expressions such as `Color'Max (Color'Min (Red, Green), Blue) * 8` now keep the nested left operand intact instead of splitting at the inner comma if the numeric-expression path falls back to discrete evaluation.
- Direct qualified operands such as `Color'Succ (Color'(Green)) * 8` now keep the qualified argument intact instead of truncating at the inner right parenthesis.
- Added regression coverage in the qualified discrete constant pass for direct nested Min/Max and direct qualified Succ operands feeding Size arithmetic without an intermediate constant or outer Pos call.
