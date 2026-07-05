Pass 442 — aggregate component association grammar completeness

Implemented one focused Ada token-cursor grammar pass for aggregate component associations.

Changes:
- Added Production_Component_Association to the token-cursor production set.
- Added top-level aggregate association arrow detection so association choices are parsed before the value expression.
- Reused the discrete-choice-list grammar for aggregate choices such as A | B, 1 .. 10, and others before =>.
- Preserved others => <> values through the existing Production_Box_Expression path.
- Kept positional aggregate items on the existing expression path.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Aggregate_Component_Association_Grammar_Completeness.
- Updated validation guards, release guard notes, README, syntax-colouring notes, and release checklist.

Scope:
This improves structural Ada grammar retention for aggregate component associations. It is not compiler-grade aggregate legality checking, type resolution, or coverage validation.
