Pass 627 - Literal-aware scalar attribute-default call scanner

This pass tightens the bounded discrete static-default scanner used for
scalar attribute-function defaults.  The path that recognizes `T'Val`,
`T'Succ`, `T'Pred`, `T'Min`, and `T'Max` previously selected the first `(`
without first skipping Ada literals.  The scanner now skips string literals
and character literals before committing to the outer attribute-call opening
parenthesis.

New regression coverage keeps `Color'Val (Character'Pos ('(') -
Character'Pos ('(') + 1)` on the retained discrete constant path and verifies
that the retained value feeds later `Color'Pos` representation arithmetic.
