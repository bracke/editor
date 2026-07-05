Pass 598 - Spaced qualified String bound prefixes
==================================================

Scope
-----
This pass keeps the Ada static-evaluation work focused on bounded static
String expressions used by representation expressions.  It closes a parser-level
gap left after the earlier whitespace-tolerant qualification work: direct static
integer parsing could still misclassify a spaced qualification apostrophe as the
bound-attribute apostrophe.

Changes
-------
- Updated the static String bound primary scanner so a qualified String prefix
  may spell separator whitespace between the qualification apostrophe and the
  operand parenthesis.
- `String' ("Gr" & "een")'Length` now follows the same representation-expression
  static path as `String'("Gr" & "een")'Length`.
- The scanner now skips Ada static separator characters before deciding whether
  an apostrophe belongs to qualification or to `First` / `Last` / `Length`.
- Existing character literal skipping, nested parenthesis handling, and final
  bound-attribute detection remain unchanged.
- Updated the direct qualified String Length regression to use the spaced
  qualification spelling.

Representative covered form
---------------------------

```ada
for V'Size use String' ("Gr" & "een")'Length * 8;
```

Expected retained static value: `40`.
