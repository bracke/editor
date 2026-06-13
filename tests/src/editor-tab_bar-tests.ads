with AUnit.Test_Cases;

package Editor.Tab_Bar.Tests is

   type Tab_Bar_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Tab_Bar_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Tab_Bar_Test_Case);

end Editor.Tab_Bar.Tests;
