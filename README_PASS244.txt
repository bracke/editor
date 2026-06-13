Editor Phase 579 pass 244

This pass continues parser statement-awareness work from pass 243.

Implemented:
- Added Statement_Or_Alternative to Editor.Ada_Language_Model.Statement_Kind.
- Added Statement_Then_Abort_Alternative to Editor.Ada_Language_Model.Statement_Kind.
- Parser now records select `or` alternatives as bounded statement metadata.
- Parser now records asynchronous select `then abort` alternatives as bounded statement metadata.
- These tasking-control alternatives do not create Outline rows or semantic declaration symbols.
- Expanded AUnit statement-awareness coverage for selective accept and asynchronous select syntax.
- Extended phase579_language_validation_check guards.
- Updated README and language documentation.

This is still statement metadata, not a full Ada statement AST or expression parser.
