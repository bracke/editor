pass 253: Ada parser null-alternative statement awareness

This pass continues closing the parser statement-grammar gap while preserving the bounded language-model architecture.

Implemented:
- Added Statement_Null_Alternative to Editor.Ada_Language_Model.Statement_Kind.
- Parser now records executable null alternatives in case/exception alternatives such as `when A => null;`.
- Else lines containing null statements can also stamp the null-alternative metadata.
- Record variant alternatives remain excluded, so `when others => null;` inside a record variant part does not become executable statement metadata.
- Null alternatives remain metadata only: no Outline rows, no semantic declaration symbols, no scopes, and no navigation targets.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README and language feature documentation.

Still intentionally not claimed:
- No full Ada statement AST.
- No expression/association AST.
- No compiler-grade legality or overload resolution.
