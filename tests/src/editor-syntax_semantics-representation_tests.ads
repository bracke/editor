with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Representation_Tests is

   type Representation_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Representation_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Representation_Test_Case);

end Editor.Syntax_Semantics.Representation_Tests;
