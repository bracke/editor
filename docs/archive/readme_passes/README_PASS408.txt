Editor pass408

Parser-completeness pass: Ada statement identifiers before compound statements.

Changes:
- Added token-cursor disambiguation for identifier-colon forms so legal Ada statement identifiers are parsed as labelled statements when the token after ':' is a statement starter.
- The token-cursor grammar now preserves the underlying statement production for labelled compound statements such as:
  * Named_Loop : for I in 1 .. 3 loop
  * Named_Block : declare
  * Named_If : if X > 0 then
- Preserved object-declaration classification for ordinary identifier-subtype declarations such as X : Integer := 0; instead of treating every identifier-colon form as a label.
- Added AUnit coverage for labelled for-loops, declare blocks, if statements, and object-declaration non-regression.
- Extended phase validation and release guards for the new statement-identifier grammar path.

Scope note:
This extends Ada grammar recognition. It still does not perform compiler-grade legality checking for label matching at end statements, duplicate statement identifiers, goto target legality, or statement placement legality.
