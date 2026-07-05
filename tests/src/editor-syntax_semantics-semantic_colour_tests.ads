with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Semantic_Colour_Tests is

   type Semantic_Colour_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Semantic_Colour_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Semantic_Colour_Test_Case);

end Editor.Syntax_Semantics.Semantic_Colour_Tests;
