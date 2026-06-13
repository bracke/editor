Pass 453 - expression literal grammar completeness

Focus:
- Close the remaining token-cursor expression grammar gap where numeric, string,
  and character literals were only visible as generic primaries.

Changes:
- Added Production_Numeric_Literal.
- Added Production_String_Literal.
- Added Production_Character_Literal.
- Parse_Primary now emits literal-specific productions for Ada numeric,
  string, and character literal tokens before falling back to name/attribute
  suffix parsing.
- Literal values in static expressions, ranges, membership choice lists,
  defaults, aggregates, and named-number declarations are now directly visible
  to semantic consumers without re-tokenizing primary labels.

Regression coverage:
- Added Test_Language_Model_Token_Cursor_Expression_Literal_Grammar_Completeness.
- Covers based numeric literals, string literals, character literals, and literal
  membership alternatives.
