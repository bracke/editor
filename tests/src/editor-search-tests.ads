with AUnit.Test_Cases;

package Editor.Search.Tests is

   type Search_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Search_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Search_Test_Case);

end Editor.Search.Tests;
