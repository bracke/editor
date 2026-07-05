Pass 447: representation / operational item grammar completeness

Implemented structural token-cursor coverage for Ada representation and operational items:

- representation targets are retained explicitly before `use` or an attribute designator
- attribute definition clauses retain separate attribute designators (`Size`, `Alignment`, `Address`, `Read`, etc.)
- operational attribute definition clauses emit explicit operational-item productions
- enumeration representation clauses retain each literal association structurally
- record representation component clauses retain component position, first-bit, and last-bit productions
- standalone aspect clauses are parsed as representation/operational items and reuse aspect association grammar

Added regression coverage:

- Test_Language_Model_Token_Cursor_Representation_Operational_Item_Grammar_Completeness

This pass remains syntactic grammar retention. Compiler-grade representation legality, operational attribute conformance, freezing, staticness, target layout conflicts, and aspect legality are still semantic/compiler responsibilities.
