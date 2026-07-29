with Ada.Environment_Variables;

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
      --  TEMP (Windows-hang diagnosis): EDITOR_TEST_SUITE selects a single
      --  sub-suite so CI can bisect which one hangs; unset runs them all.
      Sel : constant String :=
        (if Ada.Environment_Variables.Exists ("EDITOR_TEST_SUITE")
         then Ada.Environment_Variables.Value ("EDITOR_TEST_SUITE")
         else "");
      function Want (Name : String) return Boolean is
        (Sel = "" or else Sel = Name);
   begin
      if Want ("core") then Result.Add_Test (Editor_Core_Suite.Suite); end if;
      if Want ("ui") then Result.Add_Test (Editor_UI_Suite.Suite); end if;
      if Want ("workspace") then
         Result.Add_Test (Project_Workspace_Suite.Suite);
      end if;
      if Want ("build") then Result.Add_Test (Build_Tools_Suite.Suite); end if;
      if Want ("outline") then
         Result.Add_Test (Ada_Parser_Outline_Suite.Suite);
      end if;
      if Want ("langservice") then
         Result.Add_Test (Ada_Language_Service_Suite.Suite);
      end if;
      if Want ("lang") then Result.Add_Test (Ada_Language_Suite.Suite); end if;
      if Want ("rm") then Result.Add_Test (Ada_RM_Validation_Suite.Suite); end if;
      if Want ("text") then Result.Add_Test (Text_Suite.Suite); end if;
      return Result;
   end Suite;

end All_Suites;
