with AUnit.Test_Cases;

package Editor.Command_Palette.Tests is

   type Command_Palette_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Command_Palette_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Command_Palette_Test_Case);

end Editor.Command_Palette.Tests;
