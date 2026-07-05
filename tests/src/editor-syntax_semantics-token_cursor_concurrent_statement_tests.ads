with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Token_Cursor_Concurrent_Statement_Tests is

   type TokenCursorConcurrentStatement_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : TokenCursorConcurrentStatement_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out TokenCursorConcurrentStatement_Test_Case);

end Editor.Syntax_Semantics.Token_Cursor_Concurrent_Statement_Tests;
