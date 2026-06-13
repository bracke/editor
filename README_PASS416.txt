Editor phase579 IDE-grade outline/semantic language model pass416

This pass extends the Ada token-cursor parser for membership-choice ranges.

Implemented changes:
- Added structural range handling inside membership choice lists after `in` and `not in`.
- Membership choices now retain explicit ranges such as `1 .. 10`.
- Membership choices now retain subtype ranges such as `Natural range 20 .. 30`.
- Membership choices now retain leading `range` forms such as `not in range 100 .. 200`.
- Added regression coverage through `Test_Language_Model_Token_Cursor_Membership_Range_Grammar_Completeness`.
- Updated phase validation guards, release guard comments, README, outline docs, syntax-colouring docs, and release checklist.

The parser still does not perform compiler-grade subtype legality, static range validation, expected-type resolution, or complete Ada semantic legality checking.
