with AUnit.Test_Cases;

package Editor.Outline.Tests is
   type Outline_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Outline_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Outline_Test_Case);
end Editor.Outline.Tests;
