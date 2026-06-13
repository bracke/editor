Pass824 - Exception handler choice-list recovery depth

Pass824 deepens Ada exception handler choice-list recovery. Exception handlers now retain a handler-specific recovery production when a choice separator `|` is followed by a recovery boundary instead of another choice, for example `when Constraint_Error | =>`. The parser keeps the existing separator metadata, records the missing-choice recovery boundary, and leaves the following arrow or boundary token available for the surrounding handler parser.

Implementation notes:
- Added `Production_Exception_Choice_Missing_Choice_Recovery_Boundary`.
- Updated exception handler choice-list parsing in both local-name and ordinary handler forms.
- Preserved existing metadata for exception handler, choice list, named/selected/others choices, separators, arrows, statement sequence, null statements, and missing-arrow recovery.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Exception_Handler_Missing_Choice_Pass824`.

Scope note: this improves structural grammar coverage for exception handler choice-list recovery. It is not compiler-grade exception-choice legality checking, duplicate-choice validation, exception visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
