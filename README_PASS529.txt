Pass 529 - pragma character-literal argument scanning

Implemented another focused completeness pass in the unified representation /
operational pragma lowering path.

Changes:
- Added shared character-literal awareness to pragma argument scanners.
- Matching pragma close detection now ignores parentheses inside Ada character
  literals such as `')'`.
- Top-level pragma argument splitting now ignores commas and parentheses inside
  character literals.
- Top-level association-arrow detection now ignores character-literal contents.
- Named target extraction and positional fallback scanning now reuse the same
  character-literal-safe logic.
- Added regression coverage proving a value-only pragma retains
  `Char_Delay (')')` as the complete Relative_Deadline value instead of
  truncating at the right parenthesis character literal.
