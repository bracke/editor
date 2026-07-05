with Editor.Configuration_Audit.Tests;
with Editor.Dirty_Guards.Tests;
with Editor.Executor.Project_Workspace_File_Tree_Tests;
with Editor.Executor.Project_Workspace_Session_Tests;
with Editor.Executor.Project_Workspace_Tests;
with Editor.File_Tree.Tests;
with Editor.File_Tree_View.Tests;
with Editor.Lifecycle_Audit.Tests;
with Editor.Pending_Transition_Bar.Tests;
with Editor.Pending_Transitions.Tests;
with Editor.Projection_Surface_File_Lifecycle.Tests;
with Editor.Project.Tests;
with Editor.Project_Lifecycle.Tests;
with Editor.Project_Search.Tests;
with Editor.Project_Search_Bar.Tests;
with Editor.Recent_Projects.Tests;
with Editor.Search_Results.Tests;
with Editor.Workspace_Persistence.Tests;

package body Project_Workspace_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Project.Tests.Project_Test_Case);
      Ret.Add_Test (new Editor.File_Tree.Tests.File_Tree_Test_Case);
      Ret.Add_Test (new Editor.File_Tree_View.Tests.File_Tree_View_Test_Case);
      Ret.Add_Test (new Editor.Project_Search.Tests.Project_Search_Test_Case);
      Ret.Add_Test (new Editor.Project_Search_Bar.Tests.Project_Search_Bar_Test_Case);
      Ret.Add_Test (new Editor.Search_Results.Tests.Search_Results_Test_Case);
      Ret.Add_Test (new Editor.Workspace_Persistence.Tests.Workspace_Persistence_Test_Case);
      Ret.Add_Test (new Editor.Recent_Projects.Tests.Recent_Projects_Test_Case);
      Ret.Add_Test (new Editor.Dirty_Guards.Tests.Dirty_Guards_Test_Case);
      Ret.Add_Test (new Editor.Pending_Transitions.Tests.Pending_Transitions_Test_Case);
      Ret.Add_Test (new Editor.Pending_Transition_Bar.Tests.Pending_Transition_Bar_Test_Case);
      Ret.Add_Test (new Editor.Project_Lifecycle.Tests.Project_Lifecycle_Test_Case);
      Ret.Add_Test (new Editor.Projection_Surface_File_Lifecycle.Tests.Projection_Surface_File_Lifecycle_Test_Case);
      Ret.Add_Test (new Editor.Lifecycle_Audit.Tests.Lifecycle_Audit_Test_Case);
      Ret.Add_Test (new Editor.Configuration_Audit.Tests.Configuration_Audit_Test_Case);
      Ret.Add_Test (new Editor.Executor.Project_Workspace_Tests.Project_Workspace_Test_Case);
      Ret.Add_Test (new Editor.Executor.Project_Workspace_Session_Tests.Project_Workspace_Session_Test_Case);
      Ret.Add_Test (new Editor.Executor.Project_Workspace_File_Tree_Tests.Project_Workspace_File_Tree_Test_Case);
      return Ret;
   end Suite;

end Project_Workspace_Suite;
