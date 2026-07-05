with Test_Ada_Language_Service_Integration;
with Editor.Executor.Semantic_Index_State_Tests;
with Editor.Executor.Semantic_Language_Service_Tests;
with Editor.Executor.Semantic_Rename_Tests;

package body Ada_Language_Service_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Test_Ada_Language_Service_Integration.Test_Case);
      Ret.Add_Test
        (new Editor.Executor.Semantic_Language_Service_Tests
           .Semantic_Language_Service_Test_Case);
      Ret.Add_Test
        (new Editor.Executor.Semantic_Rename_Tests
           .Semantic_Rename_Test_Case);
      Ret.Add_Test
        (new Editor.Executor.Semantic_Index_State_Tests
           .Semantic_Index_State_Test_Case);
      return Ret;
   end Suite;

end Ada_Language_Service_Suite;
