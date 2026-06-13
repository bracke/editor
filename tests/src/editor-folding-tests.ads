with AUnit.Test_Cases;

package Editor.Folding.Tests is

   type Folding_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Folding_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Folding_Test_Case);

end Editor.Folding.Tests;
