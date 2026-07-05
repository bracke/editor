with AUnit.Test_Cases;

package Editor.Syntax_Semantics.Core_Model_Tail_Metadata_Tests is

   type CoreModelTailMetadata_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name (T : CoreModelTailMetadata_Test_Case) return AUnit.Message_String;
   overriding procedure Register_Tests (T : in out CoreModelTailMetadata_Test_Case);

end Editor.Syntax_Semantics.Core_Model_Tail_Metadata_Tests;
