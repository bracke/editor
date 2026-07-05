pass 249 - Ada code statement awareness

This pass continues the parser statement-grammar coverage work from pass 248.

Implemented:
- Added Statement_Code to Editor.Ada_Language_Model.Statement_Kind.
- Added conservative parser recognition for Ada code statements represented as qualified expressions, for example Instruction'(Opcode => 16#90#);.
- Code statements are counted as explicit parser metadata instead of being flattened into Statement_Call.
- Code statements do not create Outline rows, semantic declaration symbols, scopes, or navigation targets.
- Added AUnit coverage for code-statement recognition and call-statement non-pollution.
- Extended language_validation_check guards.
- Updated README and language-intelligence documentation.

The parser still does not claim a full Ada statement AST or expression parser.
