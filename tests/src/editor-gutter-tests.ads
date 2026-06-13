with AUnit.Test_Cases;

package Editor.Gutter.Tests is

   type Gutter_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Gutter_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Gutter_Test_Case);

end Editor.Gutter.Tests;
