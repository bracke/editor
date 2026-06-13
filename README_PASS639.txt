Pass 639 - Raise construct exception/message grammar

This pass improves token-cursor structural grammar coverage for Ada raise constructs.

Changes:
- Added Production_Raise_Exception_Name for the exception-name position in raise statements and raise expressions.
- Added Production_Raise_Message_Expression for the string/message-expression position after `with`.
- Updated raise-expression parsing so `raise E with M` retains the same exception/message shape as raise statements.
- Updated raise-statement parsing so `raise E with M;` distinguishes the exception-name and message-expression positions while preserving bare `raise;` as a re-raise statement.
- Extended AUnit grammar regression coverage for raise statements and raise expressions.

This improves structural grammar coverage for Ada raise statements and raise expressions. It is not compiler-grade legality checking for exception resolution, handler placement, or message expression type conformance.
