Pass 573 - Character operands in static string concatenation

Implemented bounded static string-expression support for character literal operands in Ada string concatenation.

Changes:
- Treat a valid character literal as a one-character static string inside the retained static string evaluator.
- Allow string/character concatenation to feed scalar Value attributes.
- Preserve existing bounded behavior: malformed character fragments and unknown operands remain nonstatic.
- Extended regression coverage for named and direct `"Gr" & 'e' & "en"` style Value expressions.
