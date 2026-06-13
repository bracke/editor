Phase 579 pass 245 - structured statement terminator awareness

Implemented in this pass:
- Added Statement_End_If, Statement_End_Case, Statement_End_Loop, and Statement_End_Select to Editor.Ada_Language_Model.Statement_Kind.
- Updated Editor.Ada_Declaration_Parser so unambiguous executable statement terminators are retained as bounded statement metadata instead of being discarded with all end-lines.
- Kept declaration/body/type terminators non-statement metadata, preserving Outline semantics.
- Kept record variant end case excluded from executable statement metadata.
- Extended AUnit statement-awareness coverage for end if/end case/end loop/end select and variant-record non-pollution.
- Extended phase579_language_validation_check guards.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1.  It remains metadata-level statement recognition, not a full statement AST or expression parser.
