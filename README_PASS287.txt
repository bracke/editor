Editor Phase 579 IDE-grade Outline/Semantic Language Model - Pass 287

Implemented anonymous block terminator statement-awareness metadata.

Changes:
- Added Statement_End_Block to Editor.Ada_Language_Model.Statement_Kind.
- Parser now records bare end; as anonymous block/declare-block terminator metadata.
- Compact/generated declare-block forms now retain Statement_End_Block for their anonymous end; terminators.
- Named end Name; remains conservative declaration/body structure because it overlaps package, subprogram, task, protected, and named block terminators in this declaration-oriented parser.
- No Outline rows, semantic symbols, scopes, declarations, or navigation targets are created from block terminator syntax.
- Extended AUnit statement-awareness coverage.
- Extended phase579_language_validation_check guards.
- Updated README and docs.
