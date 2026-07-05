Pass 454 - deep quantified-expression domain grammar

Implemented a completeness pass for Ada quantified expressions in the token-cursor grammar.

Changes:
- Added Production_Quantified_Parameter.
- Added Production_Quantified_Domain.
- Added Production_Quantified_Iterator_Filter.
- Added Production_Quantified_Predicate.
- Replaced skip-to-arrow recovery in quantified expressions with structural parsing of:
  * quantified parameter names,
  * discrete range domains,
  * subtype-style range domains,
  * generalized iterator domains,
  * optional when filters,
  * predicate expressions after =>.
- Preserved existing Loop_Parameter_Specification and Iterator_Specification productions.
- Added regression coverage with Test_Language_Model_Token_Cursor_Quantified_Domain_Deep_Grammar_Completeness.

This is grammar retention only. Legality checks such as domain subtype compatibility, iterator profile validation, staticness, predicate typing, and overload resolution remain semantic/compiler work.
