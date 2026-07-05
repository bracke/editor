Editor — Language Model Pass802

Scope: case statement end terminator recovery depth.

Pass802 deepens Ada case statement ending metadata. Well-formed `end case;` forms
now retain case-specific end-keyword and semicolon terminator productions, while
malformed or in-progress `end case` forms without a visible semicolon retain a
case-specific missing-end-terminator recovery boundary.

Added parser productions:
- Production_Case_Statement_End_Keyword
- Production_Case_End_Terminator
- Production_Case_Missing_End_Terminator_Recovery_Boundary

Added AUnit coverage:
- Test_Language_Model_Token_Cursor_Case_End_Terminator_Recovery_Pass802

This improves structural grammar coverage and bounded recovery for Ada case
statement endings. It is not compiler-grade case statement legality checking,
choice coverage checking, duplicate-choice analysis, end-name matching, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.
