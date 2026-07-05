with AUnit.Test_Cases;

package Editor.Executor.Semantic_Index_State_Tests is

   type Semantic_Index_State_Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding function Name
     (T : Semantic_Index_State_Test_Case) return AUnit.Message_String;

   overriding procedure Register_Tests
     (T : in out Semantic_Index_State_Test_Case);

end Editor.Executor.Semantic_Index_State_Tests;
