Phase 579 pass409 — generalized iterator loop grammar

Implemented a token-cursor grammar pass for Ada generalized iterator loops.

Changes:
- Added Production_Iterator_Specification to Editor.Ada_Token_Cursor.
- Distinguished `for Item of Container loop` and `for Element of reverse Sequence loop` from representation clauses.
- Preserved ordinary discrete-loop handling for `for I in reverse 1 .. 10 loop`.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Iterator_Loop_Grammar_Completeness.
- Updated validation/release guards and docs.

This is syntactic parser coverage only. It does not perform compiler-grade iterator legality checking, iterator interface conformance, subtype legality, or container aspect validation.
