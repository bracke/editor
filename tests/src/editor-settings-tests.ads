with AUnit.Test_Cases;

package Editor.Settings.Tests is

   type Settings_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Settings_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Settings_Test_Case);

end Editor.Settings.Tests;
