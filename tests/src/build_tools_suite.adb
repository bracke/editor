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
   begin
      Ret.Add_Test (new Editor.Problems.Tests.Problems_Test_Case);
      Ret.Add_Test (new Editor.Diagnostics.Tests.Diagnostics_Test_Case);
      Ret.Add_Test (new Editor.Diagnostics_Review_UX.Tests.Diagnostics_Review_UX_Test_Case);
      Ret.Add_Test (new Editor.Command_Extension_Readiness.Tests.Command_Extension_Readiness_Test_Case);
      Ret.Add_Test (new Editor.Producer_Contracts.Tests.Producer_Contracts_Test_Case);
      Ret.Add_Test (new Editor.External_Producers.Tests.External_Producers_Test_Case);
      Ret.Add_Test (new Editor.Build_UI.Tests.Build_UI_Test_Case);
      Ret.Add_Test (new Editor.Terminal_Tasks.Tests.Terminal_Tasks_Test_Case);
      Ret.Add_Test (new Editor.Build_Candidates.Tests.Build_Candidates_Test_Case);
      Ret.Add_Test (new Editor.Build_Diagnostics.Tests.Build_Diagnostics_Test_Case);
      Ret.Add_Test (new Editor.Build_Diagnostics_Review.Tests.Build_Diagnostics_Review_Test_Case);
      Ret.Add_Test (new Editor.Build_Milestone_Freeze.Tests.Build_Milestone_Freeze_Test_Case);
      Ret.Add_Test (new Editor.Build_Result_Summary.Tests.Build_Result_Summary_Test_Case);
      Ret.Add_Test (new Editor.Build_Output_Details.Tests.Build_Output_Details_Test_Case);
      Ret.Add_Test (new Editor.Build_Execution_Workflow.Tests.Build_Execution_Workflow_Test_Case);
      Ret.Add_Test (new Test_Slice_Rules.Tests.Test_Slice_Rules_Test_Case);
      return Ret;
   end Suite;

end Build_Tools_Suite;
