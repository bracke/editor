Editor pass 243

This pass continues parser gap nr 1 by adding bounded statement-awareness support for Ada named block and loop statements.

Implemented:
- Added Statement_Named_Block and Statement_Named_Loop to Editor.Ada_Language_Model.Statement_Kind.
- Added parser normalization for leading named statement prefixes:
  - Name : declare
  - Name : begin
  - Name : loop
  - Name : for ... loop
  - Name : while ... loop
- Named statements retain both named-statement metadata and their underlying statement kind.
- Object declarations with colons are not stripped or classified as named statements.
- Added AUnit coverage for named for/plain loops and named declare blocks.
- Extended  language validation guards.
- Updated README and language documentation.

This remains metadata-level statement recognition, not a full Ada statement AST or expression parser.
