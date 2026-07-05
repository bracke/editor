Editor pass373

Representation-clause interpretation completeness pass.

Changes:
- Corrected bounded static numeric evaluation for Ada based literals with exponents.
- Based literal exponents now scale by the literal base, e.g. 2#10#E3 = 16 and 16#2#E2 = 512.
- Decimal integer exponents still scale by decimal ten, e.g. 2E3 = 2000.
- The corrected evaluator is used by enumeration representation values, attribute representation clauses, and record representation component storage/bit values.
- Added regression coverage: Test_Language_Model_Representation_Based_Exponent_Expressions.

Still conservative:
- No GNAT-equivalent representation legality checking.
- No named constant lookup.
- No attribute evaluation.
- No layout overlap/alignment validation.
- Unsupported expressions are retained as source text without guessed numeric values.
