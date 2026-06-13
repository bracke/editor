with AUnit.Test_Cases;

package Editor.Overlay_Focus.Tests is

   type Overlay_Focus_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Overlay_Focus_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Overlay_Focus_Test_Case);

end Editor.Overlay_Focus.Tests;
