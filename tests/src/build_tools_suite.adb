with Ada.Environment_Variables;

with Editor.Build_Candidates.Tests;
with Editor.Build_Diagnostics.Tests;
with Editor.Build_Diagnostics_Review.Tests;
with Editor.Build_Execution_Workflow.Tests;
with Editor.Build_Milestone_Freeze.Tests;
with Editor.Build_Output_Details.Tests;
with Editor.Build_Result_Summary.Tests;
with Editor.Build_UI.Tests;
with Editor.Command_Extension_Readiness.Tests;
with Editor.Diagnostics.Tests;
with Editor.Diagnostics_Review_UX.Tests;
with Editor.External_Producers.Tests;
with Editor.Problems.Tests;
with Editor.Producer_Contracts.Tests;
with Editor.Terminal_Tasks.Tests;
with Test_Slice_Rules.Tests;

package body Build_Tools_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
      --  TEMP (Windows-hang diagnosis): EDITOR_BUILD_CASE selects a single test
      --  case so CI can bisect which one hangs; unset adds them all as before.
      --  If every case still hangs, the hang is at process init/exit (e.g. a
      --  build worker task that will not terminate on Windows), not a test.
      Sel : constant String :=
        (if Ada.Environment_Variables.Exists ("EDITOR_BUILD_CASE")
         then Ada.Environment_Variables.Value ("EDITOR_BUILD_CASE")
         else "");
      function Want (Name : String) return Boolean is
        (Sel = "" or else Sel = Name);
   begin
      if Want ("problems") then
         Ret.Add_Test (new Editor.Problems.Tests.Problems_Test_Case);
      end if;
      if Want ("diagnostics") then
         Ret.Add_Test (new Editor.Diagnostics.Tests.Diagnostics_Test_Case);
      end if;
      if Want ("diagux") then
         Ret.Add_Test (new Editor.Diagnostics_Review_UX.Tests.Diagnostics_Review_UX_Test_Case);
      end if;
      if Want ("cmdext") then
         Ret.Add_Test (new Editor.Command_Extension_Readiness.Tests.Command_Extension_Readiness_Test_Case);
      end if;
      if Want ("prodcontract") then
         Ret.Add_Test (new Editor.Producer_Contracts.Tests.Producer_Contracts_Test_Case);
      end if;
      if Want ("extprod") then
         Ret.Add_Test (new Editor.External_Producers.Tests.External_Producers_Test_Case);
      end if;
      if Want ("buildui") then
         Ret.Add_Test (new Editor.Build_UI.Tests.Build_UI_Test_Case);
      end if;
      if Want ("terminal") then
         Ret.Add_Test (new Editor.Terminal_Tasks.Tests.Terminal_Tasks_Test_Case);
      end if;
      if Want ("candidates") then
         Ret.Add_Test (new Editor.Build_Candidates.Tests.Build_Candidates_Test_Case);
      end if;
      if Want ("builddiag") then
         Ret.Add_Test (new Editor.Build_Diagnostics.Tests.Build_Diagnostics_Test_Case);
      end if;
      if Want ("builddiagrev") then
         Ret.Add_Test (new Editor.Build_Diagnostics_Review.Tests.Build_Diagnostics_Review_Test_Case);
      end if;
      if Want ("milestone") then
         Ret.Add_Test (new Editor.Build_Milestone_Freeze.Tests.Build_Milestone_Freeze_Test_Case);
      end if;
      if Want ("resultsum") then
         Ret.Add_Test (new Editor.Build_Result_Summary.Tests.Build_Result_Summary_Test_Case);
      end if;
      if Want ("outputdetails") then
         Ret.Add_Test (new Editor.Build_Output_Details.Tests.Build_Output_Details_Test_Case);
      end if;
      if Want ("execwf") then
         Ret.Add_Test (new Editor.Build_Execution_Workflow.Tests.Build_Execution_Workflow_Test_Case);
      end if;
      if Want ("slice") then
         Ret.Add_Test (new Test_Slice_Rules.Tests.Test_Slice_Rules_Test_Case);
      end if;
      return Ret;
   end Suite;

end Build_Tools_Suite;
