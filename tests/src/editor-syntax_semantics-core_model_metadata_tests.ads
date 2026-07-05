with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Core_Model_Metadata_Tests is

   type Core_Model_Metadata_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : Core_Model_Metadata_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out Core_Model_Metadata_Test_Case);

end Editor.Syntax_Semantics.Core_Model_Metadata_Tests;
