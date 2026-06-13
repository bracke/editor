Editor Phase 579 - Pass838

Case-expression alternative separator and recovery depth.

Pass838 improves structural token-cursor coverage for Ada case expressions.
It adds explicit metadata for comma separators between case-expression
alternatives and bounded missing-alternative recovery after a trailing comma.

Regression coverage:
- Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838

This improves grammar coverage only. It is not compiler-grade case-expression
legality checking, discrete-choice validation, static expression evaluation,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.
