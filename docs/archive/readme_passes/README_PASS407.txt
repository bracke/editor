Editor pass407

Parser-completeness pass: Ada discrete choice lists and range choices.

Changes:
- Added token-cursor grammar productions for discrete choice lists and individual discrete choices.
- Added the missing Range_Expression production to the public token-cursor production enum so range choices/slices are represented consistently.
- Refactored case statement alternatives, case expression alternatives, and record variant alternatives to parse Ada choice lists up to => instead of treating only a single expression as the alternative selector.
- Handles alternatives such as:
  * when A | B | C =>
  * when 1 .. 10 | others =>
  * case expressions with multiple choices per alternative
- Added AUnit coverage for case-statement and case-expression choice lists, range choices, and retained case alternative productions.

Scope note:
This extends Ada grammar recognition. It still does not perform compiler-grade legality checking for staticness, coverage of all values, duplicate choices, subtype membership legality, or exhaustiveness.
