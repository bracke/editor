with AUnit.Test_Cases;

package Editor.Settings_Management.Tests is

   type Settings_Management_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Settings_Management_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Settings_Management_Test_Case);

end Editor.Settings_Management.Tests;
