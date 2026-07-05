Pass 372 — bounded static expression interpretation for representation clauses

This pass expands representation-clause interpretation beyond literal-only values.

Changes:
- Extended the parser-owned representation metadata static-value parser to evaluate
  bounded numeric static expressions made from numeric literals, parentheses,
  +, -, *, /, mod, rem, and **.
- The evaluator is used consistently for:
  - enumeration representation literal values,
  - attribute representation clauses such as Size and Alignment,
  - record representation component storage-unit and bit-range values.
- Non-natural, unresolved, named, attribute-based, non-integral division, or otherwise
  unsupported expressions remain preserved as source text without a parsed numeric value.
- Added regression coverage:
  Test_Language_Model_Representation_Static_Expressions_Are_Evaluated

Still conservative:
- No GNAT-equivalent legality checking.
- No named constant lookup or attribute evaluation.
- No layout overlap/alignment validation.
- No arbitrary Ada static-expression evaluator.
