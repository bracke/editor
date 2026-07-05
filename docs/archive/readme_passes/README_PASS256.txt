Editor  IDE-grade Outline/Semantic Language Model pass 256

This pass extends parser-owned statement-awareness metadata for executable
alternative actions.

Changes:
- Added Statement_Alternative_Code to Editor.Ada_Language_Model.Statement_Kind.
- Added parser-side alternative-action shape detection for:
  * selected-name call actions after executable alternative arrows,
  * argument-list call actions after alternative arrows,
  * named-association call actions after alternative arrows,
  * qualified-expression code actions after alternative arrows.
- Alternative code actions are kept as Statement_Code plus Statement_Alternative_Code,
  and are not flattened into ordinary call metadata.
- Alternative call actions retain the same bounded call-shape metadata used for
  ordinary call statements: arguments, named associations, and selected names.
- Record variant alternatives remain excluded from executable statement metadata.
- No Outline rows, semantic declaration symbols, scopes, or navigation targets are
  created from alternative-action metadata.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check guards.
- Updated README, outline docs, syntax-colouring docs, and release checklist.

This continues closing parser gap nr 1 using bounded parser metadata. It still does
not claim a full Ada statement AST or expression/name parser.
