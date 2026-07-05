with AUnit.Test_Cases;

package Editor.Files.Rename_Delete_Operation_Tests is

   type Rename_Delete_Operation_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Rename_Delete_Operation_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Rename_Delete_Operation_Test_Case);

end Editor.Files.Rename_Delete_Operation_Tests;
