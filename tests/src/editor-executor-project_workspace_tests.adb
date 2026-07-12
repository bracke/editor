with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Configuration_Audit;
with Editor.Dirty_Guards;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Files;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Diagnostics;
with Editor.Feature_Diagnostics;
with Editor.History;
with Editor.Messages;
with Editor.Outline;
with Editor.Outline.Fixtures;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Recent_Buffers;
with Editor.State;
with Editor.Test_Helper;
with Editor.View;
with Editor.Workspace_Persistence;

package body Editor.Executor.Project_Workspace_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Files.File_Open_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.State.Dirty_Close_Scope;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

   overriding function Name
     (T : Project_Workspace_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Project_Workspace_Tests");
   end Name;


   procedure Test_Project_Close_Removes_Project_Clean_Buffers_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("project_close_root");
      Project_F  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Other_F    : constant String := Temp_Path ("unrelated.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Other_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_F);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Other_F);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (not Editor.Project.Has_Project (S.Project),
              "project close must clear the project state");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (not Found,
              "project close must remove the clean project-owned buffer");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Other_F, Found);
      Assert (Found,
              "project close must preserve unrelated buffers");
      Assert (Editor.Buffers.Global_Count >= 1,
              "project close must leave unrelated buffers open under the existing buffer policy");
      Assert (Latest_Message_Text (S) = "Project closed",
              "project close feedback must remain deterministic");

      Remove_File_If_Exists (Other_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Other_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Removes_Project_Clean_Buffers_Only;

   procedure Test_Project_Close_Blocks_Project_Dirty_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("project_dirty_root");
      Project_F   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S           : Editor.State.State_Type;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_F);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (Editor.Project.Has_Project (S.Project),
              "blocked project close must preserve project state");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "blocked project close must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "blocked project close must keep the dirty project buffer");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "blocked project close must preserve dirty marker");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "blocked project close must leave an explicit pending transition");
      Assert (Latest_Message_Text (S) = "Cannot close project with unsaved changes",
              "blocked project close feedback must not imply close happened");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Blocks_Project_Dirty_Buffer;

   procedure Test_Project_Close_Ignores_Unrelated_Dirty_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("unrelated_dirty_root");
      Project_F  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Other_F    : constant String := Temp_Path ("unrelated_dirty.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Other_Id   : Editor.Buffers.Buffer_Id;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Other_F, "outside clean");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_F);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Other_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Result : constant Editor.Executor.Command_Execution_Result :=
           Editor.Executor.Execute_Command_With_Result
             (S, Editor.Commands.Command_Close_Project);
         pragma Unreferenced (Result);
      begin
         null;
      end;

      Assert (not Editor.Project.Has_Project (S.Project),
              "unrelated dirty buffers must not block project close");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_F, Found);
      Assert (not Found,
              "clean project-owned buffer should be removed on project close");
      Other_Id := Editor.Buffers.Global_Find_By_Path (Other_F, Found);
      Assert (Found and then Other_Id /= Editor.Buffers.No_Buffer,
              "unrelated dirty buffer must remain open");
      Assert (Editor.Buffers.Global_Summary_For (Other_Id).Is_Dirty,
              "unrelated dirty marker must be preserved");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "successful project close must not leave a pending transition");

      Remove_File_If_Exists (Other_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Other_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Ignores_Unrelated_Dirty_Buffer;

   procedure Test_Project_Switch_Closes_Old_Clean_Project_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("switch_a");
      Root_B     : constant String := Temp_Path ("switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Has_Project (S.Project),
              "switch must leave an active project");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "switch must install the validated target project");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (not Found,
              "switch must close old clean project-owned buffers");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Outside_Id /= Editor.Buffers.No_Buffer,
              "switch must preserve outside-project buffers");
      Assert (Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "switch must preserve outside-project dirty buffers");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "successful switch must leave no pending transition");
      Assert (Latest_Message_Text (S) = "Project switched",
              "successful switch feedback must be deterministic");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Closes_Old_Clean_Project_Buffers;

   procedure Test_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A      : constant String := Temp_Path ("switch_dirty_a");
      Root_B      : constant String := Temp_Path ("switch_dirty_b");
      Project_A   : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S           : Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "blocked switch must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "blocked switch must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "blocked switch must preserve dirty project buffer");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "blocked switch must capture a pending transition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "cancelled switch must still preserve active project");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancelled switch must clear only the transient payload");
      Assert (Latest_Message_Text (S) = "Switch project cancelled.",
              "switch cancellation feedback must be specific");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic;

   procedure Test_Project_Switch_Target_Failure_Preserves_Previous_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A  : constant String := Temp_Path ("switch_valid_a");
      Missing : constant String := Temp_Path ("switch_missing_target");
      S       : Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Rows    : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Remove_Tree_If_Exists (Missing);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Missing);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "failed switch must preserve previous active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "failed switch must preserve previous project surfaces");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "failed switch must not promote the missing target");
      Assert (Latest_Message_Text (S) = "Target project unavailable",
              "failed switch must report target unavailability");

      Cleanup_Fixture (Root_A);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Target_Failure_Preserves_Previous_Project;


   procedure Test_Project_Switch_Requires_Active_Source_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("switch_requires_source");
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Project.Has_Project (S.Project),
              "switch without source project must not open target as project.open");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = 0,
              "switch without source project must not initialize File Tree");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 0,
              "switch without source project must not promote Recent Projects");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "switch without source project must not create pending state");
      Assert (Latest_Message_Text (S) = "No project open.",
              "switch without source project must report missing source project");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Requires_Active_Source_Project;


   procedure Test_Project_Switch_To_Current_Project_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("switch_same_project");
      Project_A : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Rows      : Natural := 0;
      Found     : Boolean := False;
      Id        : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "same-project switch setup must have an open project buffer");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "same-project switch setup must have one recent project");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "same-project switch must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "same-project switch must not clear File Tree rows");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "same-project switch must not close clean project buffers");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "same-project switch must not promote a duplicate recent entry");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "same-project switch must not create a pending transition");
      Assert (Latest_Message_Text (S) = "Project already open",
              "same-project switch feedback must be deterministic");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_To_Current_Project_Is_No_Op;


   procedure Test_Project_Switch_To_Current_Project_Skips_Target_Preflight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("switch_same_missing");
      Project_A : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Rows      : Natural := 0;
      Found     : Boolean := False;
      Id        : Editor.Buffers.Buffer_Id;
      Root_Full : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Root_Full := To_Unbounded_String (Ada.Directories.Full_Name (Root));
      Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "same-project missing-root setup must have an open buffer");

      Remove_Tree_If_Exists (Root);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = To_String (Root_Full),
              "same-project switch must preserve project even when root vanished");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows,
              "same-project missing-root switch must not clear File Tree rows");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "same-project missing-root switch must not close buffers");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "same-project missing-root switch must not repromote Recent Projects");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "same-project missing-root switch must not create pending state");
      Assert (Latest_Message_Text (S) = "Project already open",
              "same-project missing-root switch must report no-op, not target failure");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_To_Current_Project_Skips_Target_Preflight;


   procedure Test_Pending_Switch_Blocks_Different_Project_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("pending_switch_a");
      Root_B    : constant String := Temp_Path ("pending_switch_b");
      Root_C    : constant String := Temp_Path ("pending_switch_c");
      Project_A : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Target    : Editor.Pending_Transitions.Pending_Transition_Target;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Build_Fixture (Root_C);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "pending-switch setup must capture B as target");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project,
              "pending-switch setup must use switch transition kind");

      Cmd.Path := To_Unbounded_String (Root_C);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "different switch target while pending must preserve source project");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "different switch target while pending must preserve pending payload");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project,
              "different switch target must not replace transition kind");
      Assert (Editor.Recent_Projects.Normalized_Root_Path (To_String (Target.Path)) =
                Editor.Recent_Projects.Normalized_Root_Path (Root_B),
              "different switch target must not replace the captured target");
      Assert (Latest_Message_Text (S) = "Command unavailable while confirmation is pending.",
              "different switch target while pending must report command unavailability");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Cleanup_Fixture (Root_C);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Cleanup_Fixture (Root_C);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Pending_Switch_Blocks_Different_Project_Target;


   procedure Test_Pending_Close_Blocks_Project_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("pending_close_a");
      Root_B    : constant String := Temp_Path ("pending_close_b");
      Project_A : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Target    : Editor.Pending_Transitions.Pending_Transition_Target;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty project content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "pending-close setup must capture close confirmation");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Close_Project,
              "pending-close setup must use close transition kind");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "switch while close pending must preserve source project");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "switch while close pending must preserve pending close payload");
      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Assert (Target.Kind = Editor.Pending_Transitions.Pending_Close_Project,
              "switch while close pending must not replace pending close");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "switch while close pending must not promote target recent project");
      Assert (Latest_Message_Text (S) = "Command unavailable while confirmation is pending.",
              "switch while close pending must report command unavailability");

      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Pending_Close_Blocks_Project_Switch;


   procedure Test_Project_Close_Dirty_Cancel_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("close_dirty");
      Project_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S           : Editor.State.State_Type;
      Before_Rows : Natural := 0;
      Found       : Boolean := False;
      Id          : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before_Rows := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "dirty close content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "blocked close must preserve active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Before_Rows,
              "blocked close must preserve File Tree state");
      Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "blocked close must preserve dirty project buffer");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "blocked close must capture a pending confirmation");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "cancelled close must still preserve active project");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancelled close must clear only the transient payload");
      Assert (Latest_Message_Text (S) = "Close project cancelled.",
              "close cancellation feedback must be specific");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Dirty_Cancel_Is_Atomic;


   procedure Test_Project_Switch_Retry_Ignores_Retained_Outside_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("retry_switch_a");
      Root_B     : constant String := Temp_Path ("retry_switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("retry_switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "retry setup must create pending switch");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (Editor.Project.Has_Project (S.Project),
              "switch retry must leave an active project");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "switch retry must proceed after project dirty is resolved");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "switch retry must retain outside-project dirty buffer");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "successful switch retry must clear pending switch");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Retry_Ignores_Retained_Outside_Dirty;


   procedure Test_Project_Close_Retry_Ignores_Retained_Outside_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("retry_close");
      Project_A  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F  : constant String := Temp_Path ("retry_close_outside.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "retry setup must create pending close");

      S.File_Info.Dirty := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (not Editor.Project.Has_Project (S.Project),
              "close retry must proceed after project dirty is resolved");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "close retry must retain outside-project dirty buffer");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "successful close retry must clear pending close");
      Assert (Latest_Message_Text (S) = "Project closed",
              "close retry feedback must be deterministic");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Retry_Ignores_Retained_Outside_Dirty;


   procedure Test_Project_Close_Clears_Project_State_Not_Recent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("close_clean");
      S    : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "setup must promote opened project to Recent Projects");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) > 0,
              "setup must have project File Tree rows");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "clean close must clear active project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = 0,
              "clean close must clear File Tree rows");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "clean close must retain Recent Projects entries");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "clean close must leave no pending transition");
      Assert (Latest_Message_Text (S) = "Project closed",
              "clean close feedback must be deterministic");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Clears_Project_State_Not_Recent;


   procedure Test_Project_Switch_Preserves_Outside_Buffer_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A    : constant String := Temp_Path ("undo_switch_a");
      Root_B    : constant String := Temp_Path ("undo_switch_b");
      Outside_F : constant String := Temp_Path ("undo_switch_outside.txt");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      Undo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Assert (Undo_Before > 0,
              "undo preservation setup must create outside-buffer undo history");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "undo switch setup must switch projects");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "switch must preserve retained outside-buffer undo history");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "outside",
              "outside-buffer undo must remain usable after project switch");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Preserves_Outside_Buffer_Undo;


   procedure Test_Project_Close_Preserves_Outside_Buffer_Undo
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("undo_close");
      Outside_F : constant String := Temp_Path ("undo_close_outside.txt");
      S         : Editor.State.State_Type;
      Undo_Before : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Undo_Before := Natural (Editor.History.Undo_Stack.Length);
      Assert (Undo_Before > 0,
              "undo preservation setup must create outside-buffer undo history");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "undo close setup must close the project");
      Assert (Natural (Editor.History.Undo_Stack.Length) = Undo_Before,
              "close must preserve retained outside-buffer undo history");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "outside",
              "outside-buffer undo must remain usable after project close");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Preserves_Outside_Buffer_Undo;


   procedure Test_Project_Switch_Preserves_Outside_Recent_Buffer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("recent_switch_a");
      Root_B     : constant String := Temp_Path ("recent_switch_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("recent_switch_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found, "recent switch setup must open outside buffer");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Assert (Editor.Recent_Buffers.Contains
                (S.Recent_Buffers, Natural (Outside_Id)),
              "recent switch setup must track outside buffer");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "recent switch setup must switch projects");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "switch must retain outside buffer");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = 1,
              "switch must prune project-owned recent buffers only");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Natural (Outside_Id),
              "switch must preserve retained outside-buffer recency");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Preserves_Outside_Recent_Buffer_Order;


   procedure Test_Project_Close_Preserves_Outside_Recent_Buffer_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("recent_close");
      Project_A  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F  : constant String := Temp_Path ("recent_close_outside.txt");
      S          : Editor.State.State_Type;
      Found      : Boolean := False;
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found, "recent close setup must open outside buffer");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Assert (Editor.Recent_Buffers.Contains
                (S.Recent_Buffers, Natural (Outside_Id)),
              "recent close setup must track outside buffer");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);

      Assert (not Editor.Project.Has_Project (S.Project),
              "recent close setup must close project");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "close must retain outside buffer");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = 1,
              "close must prune project-owned recent buffers only");
      Assert (Editor.Recent_Buffers.Id_At (S.Recent_Buffers, 1) = Natural (Outside_Id),
              "close must preserve retained outside-buffer recency");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Close_Preserves_Outside_Recent_Buffer_Order;






   procedure Test_Project_Switch_Discard_Uses_Lifecycle_Affected_Set
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A     : constant String := Temp_Path ("switch_sets_a");
      Root_B     : constant String := Temp_Path ("switch_sets_b");
      Project_A  : constant String := Ada.Directories.Compose (Root_A, "a.txt");
      Outside_F  : constant String := Temp_Path ("switch_sets_outside.txt");
      S          : Editor.State.State_Type;
      Cmd        : Editor.Commands.Command;
      Found      : Boolean := False;
      Ignored_Id : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Ignored_Id);
      Outside_Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root_A);
      Build_Fixture (Root_B);
      Write_Text_File (Outside_F, "outside");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Editor.State.Replace_Buffer_Contents (S, "outside dirty retained");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_A);
      Editor.State.Replace_Buffer_Contents (S, "project dirty affected");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Sets : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
           Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      begin
         Assert (Natural (Sets.Project_Close_Affected.Length) = 1,
                 "switch setup should expose exactly one affected project buffer");
         Assert (Natural (Sets.Project_Close_Unaffected.Length) = 1,
                 "switch setup should expose exactly one retained outside buffer");
      end;

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "switch with dirty project buffer should create a pending transition");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Discard_Pending_Transition);

      Assert (Editor.Project.Has_Project (S.Project),
              "switch discard should complete the project switch");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "switch discard should install the target project");
      Ignored_Id := Editor.Buffers.Global_Find_By_Path (Project_A, Found);
      Assert (not Found,
              "switch discard should close only affected project buffers");
      Outside_Id := Editor.Buffers.Global_Find_By_Path (Outside_F, Found);
      Assert (Found and then Outside_Id /= Editor.Buffers.No_Buffer,
              "switch discard should retain outside-project buffers from the unaffected set");
      Assert (Editor.Buffers.Global_Summary_For (Outside_Id).Is_Dirty,
              "switch discard should preserve retained outside dirty text/state");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "completed switch discard should clear pending transition");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root_A);
      Cleanup_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root_A);
         Cleanup_Fixture (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Discard_Uses_Lifecycle_Affected_Set;


   procedure Test_Behavior_Preservation_Smoke_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("preserve_project");
      Project_F   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Outside_F   : constant String := Temp_Path ("preserve_outside.txt");
      S           : Editor.State.State_Type;
      Project_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Id  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Dirty : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      After_Dirty  : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      Before_Sets  : Editor.Buffers.Buffer_Project_Lifecycle_Sets;
      After_Sets   : Editor.Buffers.Buffer_Project_Lifecycle_Sets;
      Boundary     : Editor.Configuration_Audit.Buffer_Boundary_Audit_Summary;
      Cmd          : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (Outside_F, "outside clean");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Outside_F);
      Outside_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "outside dirty retained by project lifecycle");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Project_F);
      Project_Id := Editor.Buffers.Global_Active_Buffer;
      Set_Buffer_Text (S, "project dirty reviewed by selected close");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Before_Dirty := Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (S.Project);
      Before_Sets  := Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      Boundary := Editor.Configuration_Audit.Buffer_Boundary_Audit_For
        (S,
         "workspace-format-version=1" & ASCII.LF
         & "open-file path=" & Project_F & ASCII.LF
         & "open-file path=" & Outside_F & ASCII.LF);

      Assert (Boundary.Buffer_Metadata_Coherent,
              "preservation smoke: metadata audit remains coherent");
      Assert (Boundary.Workspace_Persistence_Safe,
              "preservation smoke: workspace persistence boundary remains safe");
      Assert (Boundary.Command_Keybinding_Payloads_Clear,
              "preservation smoke: command/keybinding routes remain payload-free");
      Assert (Boundary.Render_Boundary_Safe,
              "preservation smoke: render remains observational");
      Assert (Before_Dirty.Dirty_Count = 2
                and then Before_Dirty.File_Backed_Count = 2,
              "preservation smoke: dirty guard summary still sees both dirty file buffers");
      Assert (Natural (Before_Sets.Project_Close_Affected.Length) = 1
                and then Natural (Before_Sets.Project_Close_Unaffected.Length) = 1,
              "preservation smoke: project lifecycle affected/retained split is stable");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.Dirty_Close_Prompt_Active,
              "preservation smoke: selected dirty close still enters dirty review");
      Assert (S.Dirty_Close_Prompt_Scope = Editor.State.Selected_Buffer_Close_Scope,
              "preservation smoke: selected close scope is preserved");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel);
      Assert (not S.Dirty_Close_Prompt_Active,
              "preservation smoke: cancel still exits dirty close review");
      Assert (Editor.Buffers.Global_Contains (Project_Id),
              "preservation smoke: cancel keeps selected project buffer open");
      Assert (Editor.Buffers.Global_Contains (Outside_Id),
              "preservation smoke: cancel keeps outside-project buffer open");

      After_Dirty := Editor.Buffers.Global_Categorized_Dirty_Buffer_Summary (S.Project);
      After_Sets  := Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
      Assert (After_Dirty.Dirty_Count = Before_Dirty.Dirty_Count
                and then After_Dirty.File_Backed_Count = Before_Dirty.File_Backed_Count,
              "preservation smoke: audit/routing changes do not disturb dirty guard state");
      Assert (Natural (After_Sets.Project_Close_Affected.Length) =
                Natural (Before_Sets.Project_Close_Affected.Length)
                and then Natural (After_Sets.Project_Close_Unaffected.Length) =
                  Natural (Before_Sets.Project_Close_Unaffected.Length),
              "preservation smoke: cancel preserves project lifecycle sets");

      Editor.Buffers.Global_Set_Active_Buffer (Project_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "project dirty reviewed by selected close",
              "preservation smoke: selected project dirty text survives cancel");
      Assert (S.File_Info.Dirty,
              "preservation smoke: selected project dirty marker survives cancel");

      Editor.Buffers.Global_Set_Active_Buffer (Outside_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (Buffer_Text (S) = "outside dirty retained by project lifecycle",
              "preservation smoke: outside-project dirty text remains retained");
      Assert (S.File_Info.Dirty,
              "preservation smoke: outside-project dirty marker remains retained");

      Remove_File_If_Exists (Outside_F);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Outside_F);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Behavior_Preservation_Smoke_Matrix;


   overriding procedure Register_Tests (T : in out Project_Workspace_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Removes_Project_Clean_Buffers_Only'Access,
         "project close removes project clean buffers only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Blocks_Project_Dirty_Buffer'Access,
         "project close blocks project dirty buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Ignores_Unrelated_Dirty_Buffer'Access,
         "project close ignores unrelated dirty buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Closes_Old_Clean_Project_Buffers'Access,
         "project switch closes old clean project buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Blocks_Project_Dirty_And_Cancel_Is_Atomic'Access,
         "project switch blocks project dirty and cancel is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Target_Failure_Preserves_Previous_Project'Access,
         "project switch target failure preserves previous project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Requires_Active_Source_Project'Access,
         "project switch requires active source project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_To_Current_Project_Is_No_Op'Access,
         "project switch to current project is no op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_To_Current_Project_Skips_Target_Preflight'Access,
         "project switch to current project skips target preflight");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Switch_Blocks_Different_Project_Target'Access,
         "pending switch blocks different project target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Close_Blocks_Project_Switch'Access,
         "pending close blocks project switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Dirty_Cancel_Is_Atomic'Access,
         "project close dirty cancel is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Retry_Ignores_Retained_Outside_Dirty'Access,
         "project switch retry ignores retained outside dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Retry_Ignores_Retained_Outside_Dirty'Access,
         "project close retry ignores retained outside dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Clears_Project_State_Not_Recent'Access,
         "project close clears project state not recent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Preserves_Outside_Buffer_Undo'Access,
         "project switch preserves outside buffer undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Preserves_Outside_Buffer_Undo'Access,
         "project close preserves outside buffer undo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Preserves_Outside_Recent_Buffer_Order'Access,
         "project switch preserves outside recent buffer order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Close_Preserves_Outside_Recent_Buffer_Order'Access,
         "project close preserves outside recent buffer order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Switch_Discard_Uses_Lifecycle_Affected_Set'Access,
         "project switch discard uses lifecycle affected set");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Behavior_Preservation_Smoke_Matrix'Access,
         "behavior preservation smoke matrix");
   end Register_Tests;

end Editor.Executor.Project_Workspace_Tests;
