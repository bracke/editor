with AUnit.Test_Cases;

package Editor.Outline.Ada_Extraction_Tests is
   type Ada_Extraction_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Ada_Extraction_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Ada_Extraction_Test_Case);
end Editor.Outline.Ada_Extraction_Tests;
