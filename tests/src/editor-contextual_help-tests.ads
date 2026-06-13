with AUnit.Test_Cases;

package Editor.Contextual_Help.Tests is

   type Contextual_Help_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Contextual_Help_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Contextual_Help_Test_Case);

end Editor.Contextual_Help.Tests;
