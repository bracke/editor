Pass 621 - Nested scalar Value operand scanning

- Added a shared bounded scanner for scalar Value operands inside representation-expression static integer evaluation.
- The scanner now skips Ada string literals, character literals, and nested parentheses while locating the outer Value-call close.
- Direct forms such as `Color'Pos (Color'Value (Color'Image (Green))) * 8` now pass the whole `Color'Image (Green)` operand to the retained static string/discrete evaluator instead of truncating at the inner right parenthesis.
- The same literal-aware operand scan is used for `T'Base'Value (...)` forms such as `Color'Base'Value (Color'Base'Image (Blue))`.
- Added regression coverage in the discrete Value pass for direct Image-fed and Base-Image-fed Value operands feeding representation static values.
