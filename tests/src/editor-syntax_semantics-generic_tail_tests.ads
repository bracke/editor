with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Generic_Tail_Tests is

   type Generic_Tail_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Generic_Tail_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Generic_Tail_Test_Case);

end Editor.Syntax_Semantics.Generic_Tail_Tests;
