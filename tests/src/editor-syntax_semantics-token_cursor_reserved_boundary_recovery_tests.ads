with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Token_Cursor_Reserved_Boundary_Recovery_Tests is

   type TokenCursorReservedBoundaryRecovery_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : TokenCursorReservedBoundaryRecovery_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out TokenCursorReservedBoundaryRecovery_Test_Case);

end Editor.Syntax_Semantics.Token_Cursor_Reserved_Boundary_Recovery_Tests;
