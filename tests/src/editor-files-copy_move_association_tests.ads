with AUnit.Test_Cases;

package Editor.Files.Copy_Move_Association_Tests is

   type Copy_Move_Association_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Copy_Move_Association_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Copy_Move_Association_Test_Case);

end Editor.Files.Copy_Move_Association_Tests;
