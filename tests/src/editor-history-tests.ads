with AUnit.Test_Cases;

package Editor.History.Tests is

   type History_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : History_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out History_Test_Case);

end Editor.History.Tests;