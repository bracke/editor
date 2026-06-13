Editor Phase 579 pass 352

Completeness pass for interpreted record representation layout metadata.

Changes:
- Kept representation component layout metadata bounded with Max_Representation_Components.
- Add_Record_Representation_Component now marks the existing overflow/fingerprint state when the layout metadata budget is exceeded.
- Extended simple static literal parsing for record representation component clauses beyond plain decimals.
- Storage-unit and bit-range values now parse Ada integer literals with underscores and based notation such as 16#10# and 2#1_111#.
- Added AUnit regression coverage for based/underscore representation literals.
- Updated README, Outline docs, semantic-colouring docs, and release-check guard tokens.

Conservative boundary:
- This is still not GNAT-equivalent representation legality checking.
- It does not evaluate named constants, attributes, arithmetic expressions, or arbitrary static expressions.
- Unsupported layout expressions remain preserved as source text and do not receive parsed static numeric values.
