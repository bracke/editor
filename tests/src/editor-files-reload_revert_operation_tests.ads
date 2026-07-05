with AUnit.Test_Cases;

package Editor.Files.Reload_Revert_Operation_Tests is

   type Reload_Revert_Operation_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Reload_Revert_Operation_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Reload_Revert_Operation_Test_Case);

end Editor.Files.Reload_Revert_Operation_Tests;
