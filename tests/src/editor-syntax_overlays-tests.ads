with AUnit.Test_Cases;

package Editor.Syntax_Overlays.Tests is

   type Syntax_Overlays_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Syntax_Overlays_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Syntax_Overlays_Test_Case);

end Editor.Syntax_Overlays.Tests;
