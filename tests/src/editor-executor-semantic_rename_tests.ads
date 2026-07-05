with AUnit.Test_Cases;

package Editor.Executor.Semantic_Rename_Tests is

   type Semantic_Rename_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Semantic_Rename_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Semantic_Rename_Test_Case);

end Editor.Executor.Semantic_Rename_Tests;
