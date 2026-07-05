Editor  IDE-grade outline/semantic language model - pass427

This pass extends Ada token-cursor parser grammar coverage for select statements.

Implemented:
- Added Production_Select_Guard.
- Added Production_Select_Else_Part.
- Added Production_Terminate_Alternative.
- Added Production_Abortable_Part.
- Added Parse_Select_Guard so guarded select alternatives parse as condition expressions instead of falling through the generic case/discrete-choice alternative path.
- Extended select/or/else/terminate/then abort handling to retain conditional, timed, terminate, and asynchronous select-alternative structure.
- Added AUnit regression coverage in Test_Language_Model_Token_Cursor_Select_Alternative_Grammar_Completeness.
- Updated validation/release guards and documentation.

Non-goals retained:
- No compiler-grade select legality checking.
- No entry conformance validation.
- No guard legality/staticness validation.
- No abortability or runtime rendezvous semantics.
