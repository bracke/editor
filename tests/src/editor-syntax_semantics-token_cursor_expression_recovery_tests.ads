with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Token_Cursor_Expression_Recovery_Tests is

   type TokenCursorExpressionRecovery_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : TokenCursorExpressionRecovery_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out TokenCursorExpressionRecovery_Test_Case);

end Editor.Syntax_Semantics.Token_Cursor_Expression_Recovery_Tests;
