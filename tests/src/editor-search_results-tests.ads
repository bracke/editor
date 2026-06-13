with AUnit.Test_Cases;

package Editor.Search_Results.Tests is

   type Search_Results_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Search_Results_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Search_Results_Test_Case);

end Editor.Search_Results.Tests;
