with AUnit.Test_Cases;

package Editor.Keybindings.Tests is

   type Keybindings_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Keybindings_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Keybindings_Test_Case);

end Editor.Keybindings.Tests;
