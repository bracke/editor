Editor Phase 579 — Pass867

Case choice-list missing-choice recovery depth.

Changes:
- Added `Production_Case_Choice_Missing_Choice_Recovery_Boundary`.
- Updated case statement choice-list scanning so malformed/in-progress alternatives such as `when 1 | =>` retain case-specific missing-choice recovery metadata.
- Preserved case choice separator, choice arrow, alternative statement-sequence, end-case, and following-statement visibility.
- Added AUnit coverage in `Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery_Pass867`.

This improves structural grammar coverage for Ada case statement choice lists. It is not compiler-grade case-choice coverage checking, discrete-choice legality checking, static range evaluation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
