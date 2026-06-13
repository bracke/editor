Phase 579 pass 413 - aggregate iterated component association grammar

This pass extends the Ada token-cursor parser so aggregate iterated component
associations are no longer routed through the quantified-expression parser.

Implemented:
- Added Production_Iterated_Component_Association.
- Added Parse_Iterated_Component_Association for aggregate-local
  `for ... in/of ... =>` syntax.
- Preserved loop-parameter metadata for aggregate `for I in ... => ...`.
- Preserved iterator metadata for aggregate `for Element of ... => ...`.
- Improved parenthesized aggregate association parsing for mixed named and
  iterated associations.
- Added AUnit coverage for aggregate iterated associations and a non-regression
  assertion that they do not produce Production_Quantified_Expression.
- Updated validation/release guards and documentation.

This is syntactic grammar coverage only. It does not implement compiler-grade
aggregate legality, expected-type resolution, discrete range legality, iterator
interface conformance, aggregate completeness checks, or static matching.
