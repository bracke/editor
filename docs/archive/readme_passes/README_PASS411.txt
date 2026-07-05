Pass411 — Ada declare-expression grammar coverage

This pass extends the token-cursor Ada grammar substrate with Ada 2022 declare-expression recognition.

Implemented:
- Added Production_Declare_Expression to Editor.Ada_Token_Cursor.
- Parenthesized expression parsing now treats `(declare ... begin ...)` as an expression primary instead of a generic aggregate/block fallback.
- The declare-expression declarative part is parsed through the existing declaration/statement parser, so nested object declarations remain visible to the grammar result.
- Added AUnit coverage for declare expressions in declarations and assignments.
- Updated validation/release guard comments and user-facing grammar documentation.

Conservative boundary:
- This is syntax retention, not compiler-grade legality checking. The parser does not validate staticness, freezing, accessibility, type resolution, or declaration legality inside declare expressions.
