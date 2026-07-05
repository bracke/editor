Pass 443: parenthesized aggregate association reuse

This pass closes the remaining aggregate-association parser split between
qualified/indexed association lists and ordinary parenthesized aggregate
primaries.

Implemented:
- Added a shared Parse_Component_Association_Item helper for aggregate item
  parsing.
- Reused the same top-level =>/choice-list detection inside ordinary
  parenthesized aggregate primaries, not only Parse_Association_List.
- Preserved first-item associations such as `(A | B => 1, others => <>)`
  without routing the first choice through generic expression parsing.
- Preserved delta aggregate update associations such as
  `(Base with delta A | B => 3, others => <>)` with the same component
  association, discrete choice-list, range-choice, iterated-association, and
  box-expression handling.
- Added regression coverage:
  Test_Language_Model_Token_Cursor_Parenthesized_Aggregate_Association_Grammar_Completeness

This remains syntactic retention only. Aggregate expected type, coverage,
choice legality, and delta update legality remain compiler-grade semantic
checks outside the editor token-cursor grammar.
