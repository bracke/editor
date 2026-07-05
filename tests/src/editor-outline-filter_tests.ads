with AUnit.Test_Cases;

package Editor.Outline.Filter_Tests is
   type Filter_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Filter_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Filter_Test_Case);
end Editor.Outline.Filter_Tests;
