Pass 457: generic actual association legality completeness

This pass extends the bounded Ada legality diagnostics layer added in pass 456 with concrete checks over retained generic actual association metadata.

Implemented:
- Added Legality_Duplicate_Generic_Actual_Formal.
- Added Legality_Positional_Generic_Actual_After_Named.
- Checks every retained generic actual list per instantiation/formal package owner.
- Flags duplicate named associations for the same formal selector.
- Flags positional actuals that appear after a named association.
- Keeps the pass intentionally bounded: it does not yet perform generic contract matching, overload/type conformance, or defaulted formal completion.

Regression coverage:
- Added Test_Language_Model_Legality_Generic_Actual_Association_Pass.
- Covers duplicate named generic actual formals and mixed named-then-positional actual lists.
