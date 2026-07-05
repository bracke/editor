with AUnit.Test_Cases;

package Editor.Outline.Structure_Range_Tests is
   type Structure_Range_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Structure_Range_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Structure_Range_Test_Case);
end Editor.Outline.Structure_Range_Tests;
