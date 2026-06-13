with AUnit.Test_Cases;

package Editor.Quick_Open.Tests is

   type Quick_Open_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Quick_Open_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests (T : in out Quick_Open_Test_Case);

end Editor.Quick_Open.Tests;
