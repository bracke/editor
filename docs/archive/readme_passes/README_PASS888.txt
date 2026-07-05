Editor — IDE-grade Outline / Semantic Colouring / Ada Parser — Pass888

This pass improves structural expression grammar recovery for malformed Ada case
expressions whose alternatives have an arrow but no dependent expression.

Implemented changes:

* Added token-cursor production metadata:
  * Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary
* Refined case-expression parsing so alternatives such as:

     (case Mode is when 1 =>, when others => 0)
     (case Mode is when 1 => 10, when others =>)

  record case-expression-specific dependent-expression recovery rather than
  treating the following comma, close delimiter, semicolon, or reserved boundary
  as an ordinary expression primary.
* Preserved existing case-expression, arrow, dependent-expression, generic
  recovery, and following-declaration metadata.
* Added AUnit coverage:
  * Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery_Pass888
* Updated validation/release guard documentation.

This improves structural grammar coverage for malformed Ada case-expression
dependent expressions. It is not expression type checking, discrete-choice
legality checking, case coverage checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
