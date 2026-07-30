with Ada_Language_Suite;
with Ada_Language_Service_Suite;
with Ada_Parser_Outline_Suite;
with Ada_RM_Validation_Suite;
with Build_Tools_Suite;
with Editor_Core_Suite;
with Editor_UI_Suite;
with Project_Workspace_Suite;
with Text_Suite;

package body All_Suites is

   function Suite return Access_Test_Suite is
      Result : constant Access_Test_Suite := New_Suite;
   begin
      Result.Add_Test (Editor_Core_Suite.Suite);
      Result.Add_Test (Editor_UI_Suite.Suite);
      Result.Add_Test (Project_Workspace_Suite.Suite);
      Result.Add_Test (Build_Tools_Suite.Suite);
      Result.Add_Test (Ada_Parser_Outline_Suite.Suite);
      Result.Add_Test (Ada_Language_Service_Suite.Suite);
      Result.Add_Test (Ada_Language_Suite.Suite);
      Result.Add_Test (Ada_RM_Validation_Suite.Suite);
      Result.Add_Test (Text_Suite.Suite);
      return Result;
   end Suite;

end All_Suites;
