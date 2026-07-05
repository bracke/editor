with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Generic_Formal_Package_Contract_Tests is

   type GenericFormalPackageContract_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : GenericFormalPackageContract_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out GenericFormalPackageContract_Test_Case);

end Editor.Syntax_Semantics.Generic_Formal_Package_Contract_Tests;
