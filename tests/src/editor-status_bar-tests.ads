with AUnit.Test_Cases;

package Editor.Status_Bar.Tests is

   type Status_Bar_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Status_Bar_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Status_Bar_Test_Case);

end Editor.Status_Bar.Tests;
