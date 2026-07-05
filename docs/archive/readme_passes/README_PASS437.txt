Pass 437 — record representation mod-clause grammar

This pass extends the Ada token-cursor parser with structural recognition for
record representation mod clauses.

Changes:
- Added Production_Mod_Clause to Editor.Ada_Token_Cursor.
- Extended Parse_Record_Representation_Clause so `at mod <expression>;` is
  retained as record-representation grammar instead of being skipped as opaque
  tokens.
- Preserved following representation component clauses after a mod clause.
- Added AUnit coverage in
  Test_Language_Model_Token_Cursor_Record_Representation_Mod_Clause_Grammar_Completeness.
- Updated validation/release guards and parser documentation notes.

Scope note:
This is grammar retention only. It does not perform compiler-grade alignment
legality, storage unit validation, component layout legality, representation
conflict detection, or target-specific layout checks.
