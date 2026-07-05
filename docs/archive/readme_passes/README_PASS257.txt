Pass 257 — compact same-line statement awareness

This pass extends parser-owned Ada statement-awareness metadata for compact/generated source where a control statement, inline action, and terminator appear on one physical line.

Implemented:
- Added Statement_Compact_Sequence to Editor.Ada_Language_Model.Statement_Kind.
- Added compact statement sequence detection in Editor.Ada_Declaration_Parser.
- Parser now stamps compact sequence metadata for forms such as:
  - if Ready then null; end if;
  - while Ready loop null; end loop;
  - select accept Stop; else null; end select;
- Inline null actions are retained as Statement_Null metadata.
- Inline end-if/end-loop/end-select terminators are retained using the existing terminator metadata.
- Compact metadata remains parser metadata only and does not create Outline rows, semantic symbols, scopes, or navigation targets.
- Added AUnit coverage and validation guards.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This continues closing parser gap nr 1 while still staying below a full Ada statement AST or expression parser.
