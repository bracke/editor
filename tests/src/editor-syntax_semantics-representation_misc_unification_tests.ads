with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Representation_Misc_Unification_Tests is

   type RepresentationMiscUnification_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : RepresentationMiscUnification_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out RepresentationMiscUnification_Test_Case);

end Editor.Syntax_Semantics.Representation_Misc_Unification_Tests;
