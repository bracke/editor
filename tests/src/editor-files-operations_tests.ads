with AUnit.Test_Cases;

package Editor.Files.Operations_Tests is

   type Operations_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Operations_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Operations_Test_Case);

end Editor.Files.Operations_Tests;
