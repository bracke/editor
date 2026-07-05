with AUnit.Test_Cases;

package Editor.Outline.Lexical_Tests is
   type Lexical_Test_Case is new AUnit.Test_Cases.Test_Case with null record;
   overriding function Name (T : Lexical_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Lexical_Test_Case);
end Editor.Outline.Lexical_Tests;
