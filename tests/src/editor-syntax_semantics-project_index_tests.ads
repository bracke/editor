with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Project_Index_Tests is

   type Project_Index_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Project_Index_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Project_Index_Test_Case);

end Editor.Syntax_Semantics.Project_Index_Tests;
