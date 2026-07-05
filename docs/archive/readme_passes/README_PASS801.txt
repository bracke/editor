# Editor — Pass801

Pass801 deepens Ada compound-statement end terminator/recovery metadata.

Changed:

* Added token-cursor productions:
  * `Production_If_End_Terminator`
  * `Production_If_Missing_End_Terminator_Recovery_Boundary`
  * `Production_Loop_End_Terminator`
  * `Production_Loop_Missing_End_Terminator_Recovery_Boundary`
  * `Production_Block_End_Terminator`
  * `Production_Block_Missing_End_Terminator_Recovery_Boundary`
* Well-formed `end if;`, `end loop;`, and block `end;` forms now retain family-specific terminator metadata.
* Malformed or in-progress compound ends without a visible semicolon now emit family-specific bounded recovery metadata.
* Preserved existing if/loop/block end-name, end-keyword, statement-sequence, and shared recovery metadata.
* Added AUnit regression:
  * `Test_Language_Model_Token_Cursor_Compound_End_Terminator_Recovery_Pass801`
* Updated validation/release guards.

This improves structural grammar coverage and bounded recovery for Ada compound statement endings. It is not compiler-grade compound-statement legality checking, end-name matching, control-flow analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
