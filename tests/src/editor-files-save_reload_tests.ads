with AUnit.Test_Cases;

package Editor.Files.Save_Reload_Tests is

   type Save_Reload_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Save_Reload_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Save_Reload_Test_Case);

end Editor.Files.Save_Reload_Tests;
