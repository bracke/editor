Pass 481 - Record representation mod-clause legality

Focus:
- Continue record representation clause completeness after pass 480.
- Close the gap where token-cursor grammar recognized `at mod ...` inside record representation clauses, but the syntax tree and retained language model did not keep it for legality diagnostics.

Implemented:
- Added `Node_Representation_Mod_Clause` to the Ada syntax tree.
- Retained `at mod ...;` lines inside `for T use record ... end record;` as structured syntax-tree nodes instead of leaving them as generic inner statements.
- Added `Representation_Record_Mod_Clause` to the retained representation-clause model.
- Wired record mod clauses to their enclosing record representation target.
- Added bounded legality diagnostics for record representation mod clauses:
  - target must be a retained record type;
  - modulus expression must be static natural;
  - static modulus value must be positive.
- Kept duplicate handling through the existing representation-clause identity pass, so repeated mod clauses for the same target are reported as duplicate representation clauses.

Regression coverage:
- Added `Test_Language_Model_Legality_Record_Representation_Mod_Clause_Pass`.
- Covers syntax-tree retention of mod clauses, zero modulus rejection, and non-static modulus rejection.

Scope:
- This remains a bounded IDE legality layer. Full ABI/layout consequences of record alignment still belong to deeper target-machine layout interpretation.
