Pass 531 - syntax-tree pragma argument literal-safe splitting

Implemented another concrete convergence pass for pragma/aspect/property handling.

Changes:
- Hardened syntax-tree top-level association-arrow detection so arrows inside
  string literals and Ada character literals are ignored.
- Hardened syntax-tree comma splitting for pragma/aspect/generic association
  lists so commas inside string literals and character literals do not split
  retained argument nodes.
- Reused the same literal-aware behavior for key/value child retention, so a
  pragma argument such as "arrow => kept" remains a positional value rather
  than becoming a bogus association.
- Added regression coverage for pragma arguments containing string-literal
  commas and string-literal arrows alongside the existing character-literal
  parenthesis coverage.

This keeps syntax-tree retention aligned with the previously hardened semantic
pragma lowering scanners.
