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
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Diagnostics;
with Editor.Feature_Diagnostics;
with Editor.Outline;
with Editor.Outline.Fixtures;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.State;

package body Editor.Executor.Project_Workspace_File_Tree_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Outline.Outline_Refresh_Status;

   overriding function Name
     (T : Project_Workspace_File_Tree_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Project_Workspace_File_Tree_Tests");
   end Name;


   procedure Test_File_Tree_Node_Action_Toggles_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("toggle_root");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      A_Dir : Editor.File_Tree.File_Tree_Node_Id;
      Before_Count : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      A_Dir := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");
      Before_Count := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, A_Dir, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (Editor.File_Tree.Node (S.File_Tree, A_Dir).Is_Expanded,
              "file tree node action must expand directory nodes");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) > Before_Count,
              "directory toggle must rebuild visible rows");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, A_Dir, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (not Editor.File_Tree.Node (S.File_Tree, A_Dir).Is_Expanded,
              "second toggle must collapse directory nodes");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Node_Action_Toggles_Directory;

   procedure Test_File_Tree_Node_Action_Opens_And_Switches_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("open_root");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Dir_Id : Editor.File_Tree.File_Tree_Node_Id;
      Count_After_Open : Natural;
      Active_After_Open : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Dir_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);
      Count_After_Open := Editor.Buffers.Global_Count;
      Active_After_Open := Editor.Buffers.Global_Active_Buffer;
      Assert (Count_After_Open >= 1,
              "file tree open action must create or activate a buffer");
      Assert (S.File_Info.Has_Path,
              "file tree open action must update active file identity");
      Assert (To_String (S.File_Info.Display_Name) = "a.txt",
              "file tree open action must make clicked file active");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "opening an already-open file from tree must not duplicate buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_After_Open,
              "opening an already-open active file must keep the existing buffer active");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Dir_Id, Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "open-file action on directory node must be a no-op");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Toggle_Directory_Action);
      Assert (Editor.Buffers.Global_Count = Count_After_Open,
              "toggle-directory action on file node must be a no-op");

      Cleanup_Fixture (Root);
   end Test_File_Tree_Node_Action_Opens_And_Switches_File;

   procedure Test_File_Tree_Node_Action_Invalid_Is_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Count_Before : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Count_Before := Editor.Buffers.Global_Count;
      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S,
         Editor.File_Tree.File_Tree_Node_Id'Last,
         Editor.File_Tree_View.Open_File_Action);
      Assert (Editor.Buffers.Global_Count = Count_Before,
              "invalid file tree node action must not mutate buffers");
      Assert (Editor.File_Tree.Is_Empty (S.File_Tree),
              "invalid file tree node action must not mutate file tree");
   end Test_File_Tree_Node_Action_Invalid_Is_No_Op;



   procedure Test_File_Tree_Missing_Target_Does_Not_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("missing_target_root");
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Count_Before : Natural;
      Rows_Before  : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt before removal");

      Remove_File_If_Exists (File_Path);
      Count_Before := Editor.Buffers.Global_Count;
      Rows_Before := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, File_Id, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.Buffers.Global_Count = Count_Before,
              "missing file tree targets must not open a buffer");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows_Before,
              "missing file tree activation must not mutate file tree rows");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_File_Tree_Missing_Target_Does_Not_Open;

   procedure Test_Refresh_Preserves_Unchanged_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("refresh_selection_root");
      Added : constant String := Ada.Directories.Compose (Root, "b.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row : Natural := 0;
      Row_Found : Boolean := False;
      Selected : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, File_Id, Row_Found);
      Assert (Row_Found, "a.txt must be visible in the file tree");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Write_Text_File (Added, "new");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Refresh_File_Tree);

      Selected := Editor.File_Tree_View.Node_For_Row
        (S.File_Tree,
         Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View),
         Found);
      Assert (Found, "refresh must leave a valid selected row");
      Assert (To_String (Editor.File_Tree.Node (S.File_Tree, Selected).Relative_Path) = "a.txt",
              "refresh must preserve selection when the same target still exists");
      Remove_File_If_Exists (Added);
      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_File_If_Exists (Added);
         Cleanup_Fixture (Root);
         raise;
   end Test_Refresh_Preserves_Unchanged_Selection;


   procedure Test_Refresh_Clears_Disappeared_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("refresh_removed_selection_root");
      Removed : constant String := Ada.Directories.Compose (Root, "a.txt");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      File_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row : Natural := 0;
      Row_Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Fixture (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      File_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must contain a.txt");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, File_Id, Row_Found);
      Assert (Row_Found, "a.txt must be visible in the file tree");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Remove_File_If_Exists (Removed);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Refresh_File_Tree);

      Assert (Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View) = 0,
              "refresh must clear selection when the selected target disappears");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Refresh_Clears_Disappeared_Selection;

   function Pending_Test_Summary
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
   begin
      return (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   end Pending_Test_Summary;

   procedure Test_Pending_Invalid_Open_Project_Clears_Silently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("invalid project"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => False,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      Assert (not Editor.Executor.Pending_Transition_Policy.Pending_Transition_Is_Still_Valid (S),
              "empty-path pending open-project target must be stale");
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "stale pending open-project target must clear deterministically");
   end Test_Pending_Invalid_Open_Project_Clears_Silently;

   procedure Test_Pending_Invalid_Close_Buffer_Clears_Silently
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("closed.adb"),
         Buffer_Id  => Natural (Editor.Buffers.No_Buffer),
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Pending_Test_Summary);

      Assert (not Editor.Executor.Pending_Transition_Policy.Pending_Transition_Is_Still_Valid (S),
              "pending close-buffer target must be stale after target disappears");
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "stale pending close-buffer target must clear deterministically");
   end Test_Pending_Invalid_Close_Buffer_Clears_Silently;



   procedure Test_Open_Selected_Recent_Project_Opens_First_Entry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Root       : constant String := Temp_Path ("recent_project");
      Config_Dir : constant String := Temp_Path ("recent_config");
      Cmd        : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Config_Dir);
      Ada.Directories.Create_Path (Root);
      Ada.Directories.Create_Path (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Root, "recent_project", 213);

      Cmd.Kind := Editor.Commands.Open_Selected_Recent_Project;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Has_Project (S.Project),
              "open selected recent project should open the first recent entry");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "recent project activation should use the approved project-open path");

      Use_Executor_Recent_Config;
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Config_Dir);
   end Test_Open_Selected_Recent_Project_Opens_First_Entry;

   procedure Test_Open_Selected_Recent_Project_Missing_Path_Fails_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Missing : constant String := Temp_Path ("missing_recent_project");
      Cmd     : Editor.Commands.Command;
   begin
      Remove_Tree_If_Exists (Missing);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing, "missing", 213);

      Cmd.Kind := Editor.Commands.Open_Selected_Recent_Project;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Project.Has_Project (S.Project),
              "missing recent project activation must not install a project");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "failed recent project activation must not rewrite recent projects");
   end Test_Open_Selected_Recent_Project_Missing_Path_Fails_Safely;

   procedure Test_Recent_Project_Selection_Commands_Are_Transient
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/a", "a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/b", "b", 2);

      S.Recent_Project_Selected_Index := 0;
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 1,
              "select next must initialize transient selection to the first recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 2,
              "select next must move to the next recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Next_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 1,
              "select next must wrap deterministically to the first recent row");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Select_Previous_Recent_Project);
      Assert (S.Recent_Project_Selected_Index = 2,
              "select previous must wrap deterministically to the last recent row");

      Assert (not Editor.Project.Has_Project (S.Project),
              "selecting recent rows must not open or mutate project context");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 2,
              "selecting recent rows must not remove or persist recent entries");
   end Test_Recent_Project_Selection_Commands_Are_Transient;

   procedure Test_Show_Recent_Projects_Reports_No_Available
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Missing1 : constant String := Temp_Path ("show_missing_a");
      Missing2 : constant String := Temp_Path ("show_missing_b");
      Msg      : Unbounded_String;
   begin
      Remove_Tree_If_Exists (Missing1);
      Remove_Tree_If_Exists (Missing2);
      Init_Executor_Test_State (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing1, "missing-a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Missing2, "missing-b", 2);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Show_Recent_Projects);
      Msg := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "No available recent projects") > 0,
              "Recent Projects projection must expose the all-unavailable empty state");
      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "project path no longer exists") > 0,
              "Recent Projects projection must still show removable unavailable rows");
      Assert (not Editor.Project.Has_Project (S.Project),
              "showing Recent Projects must not open a project");
   end Test_Show_Recent_Projects_Reports_No_Available;

   procedure Test_File_Tree_Already_Open_Missing_File_Focuses_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root  : constant String := Temp_Path ("ft_open_focus_root");
      Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      S     : Editor.State.State_Type;
      Node  : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "fixture must include a File Tree node for a.txt");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.State.Replace_Buffer_Contents (S, "dirty unsaved content");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Remove_File_If_Exists (Path);

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.State.Current_Text (S) = "dirty unsaved content",
              "File Tree activation of an already-open missing file must preserve dirty content");
      Assert (S.File_Info.Dirty,
              "File Tree focus path must preserve the dirty marker");
      Assert (Editor.Buffers.Global_Count = 1,
              "File Tree focus path must not create a duplicate buffer");
      Assert (Latest_Message_Text (S) =
                "Focused existing buffer a.txt; disk was not reloaded",
              "File Tree already-open feedback must match explicit open/focus feedback");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Tree_Already_Open_Missing_File_Focuses_Buffer;



   procedure Select_File_Tree_Test_Path
     (S             : in out Editor.State.State_Type;
      Relative_Path : String)
   is
      Found     : Boolean := False;
      Row_Found : Boolean := False;
      Node      : constant Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.Find_By_Path (S.File_Tree, Relative_Path, Found);
      Row       : Natural := 0;
   begin
      Assert (Found, "test file tree path must exist: " & Relative_Path);
      Editor.File_Tree.Expand_Ancestors (S.File_Tree, Node);
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "test file tree row must be visible: " & Relative_Path);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
   end Select_File_Tree_Test_Path;

   procedure Test_Language_Index_Survives_File_Tree_Rename_Active_Non_Ada
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_file_tree_rename");
      Main_Path : constant String := Ada.Directories.Compose (Root, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Root, "lib.ads");
      Notes_Path : constant String := Ada.Directories.Compose (Root, "notes.txt");
      Renamed_Path : constant String :=
        Ada.Directories.Compose (Root, "notes-renamed.txt");
      S : Editor.State.State_Type;
      Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Root);
      Write_Text_File
        (Main_Path,
         "with Lib;" & ASCII.LF &
         "procedure Main is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   Lib.Run;" & ASCII.LF &
         "end Main;" & ASCII.LF);
      Write_Text_File
        (Lib_Path,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      Write_Text_File (Notes_Path, "notes" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Notes_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "file-tree rename fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-tree rename fixture indexed Ada project files");

      Select_File_Tree_Test_Path (S, "notes.txt");
      Cmd.Text := To_Unbounded_String ("notes-renamed.txt");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Renamed_Path,
              "file-tree rename rebases active non-Ada buffer");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-tree rename preserves unrelated Ada language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "file-tree rename preserves unrelated Ada language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "file-tree rename keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_File_Tree_Rename_Active_Non_Ada;

   procedure Test_Rename_Active_File_Invalidates_Derived_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("rename_invalidates");
      Old_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      New_Path : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Analysis : Editor.Ada_Language_Model.Analysis_Result;
      Ignored  : Editor.Ada_Language_Model.Symbol_Id;
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "rename setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Old_Path);
      Ignored := Editor.Ada_Language_Model.Add_Symbol
        (Analysis, "Renamed_File_Target",
         Editor.Ada_Language_Model.Symbol_Object,
         (Start_Line => 1, Start_Column => 1, End_Line => 1, End_Column => 3));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, Old_Path,
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "rename setup mirrors language service and index");

      declare
         Result : constant Editor.Outline.Outline_Refresh_Result :=
           Editor.Outline.Fixtures.Populate_Synthetic_Outline (S.Outline);
      begin
         Assert
           (Result.Status = Editor.Outline.Outline_Refresh_Ok,
            "synthetic outline fixture refresh succeeds");
      end;
      Editor.Diagnostics.Add
        (S.Diagnostics, 1, 1, Editor.Diagnostics.Error, "before rename");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "before rename",
         Source_Label => "a.txt");

      Select_File_Tree_Test_Path (S, "a.txt");
      Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "rename must create renamed target");
      Assert (not Ada.Directories.Exists (Old_Path),
              "rename must remove old target");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = New_Path,
              "clean active buffer path must be rebased");
      Assert (not Editor.Outline.Has_Items (S.Outline),
              "rename of active file must clear stale outline rows");
      Assert (Editor.Diagnostics.Diagnostic_Count (S.Diagnostics) = 0,
              "rename of active file must clear stale active diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "rename of active file must clear stale diagnostics feature rows");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "rename must refresh project search state");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) = 0,
              "rename drops stale language index rows for the moved file");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "rename invalidates language service with project index");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Active_File_Invalidates_Derived_State;

   procedure Test_Delete_Build_Config_Marks_Selected_Candidate_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("build_config_stale");
      Alire_Path : constant String := Ada.Directories.Compose (Root, "alire.toml");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd        : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Write_Text_File (Alire_Path, "name = ""demo""" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "build-config setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidates.Append (Editor.Build_Candidates.Alire_Candidate (Root));
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI, Editor.Build_Candidates.Candidate_Id_For_Alire (Root));
      Assert (To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0,
              "setup must select build candidate");

      Select_File_Tree_Test_Path (S, "alire.toml");
      Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Ada.Directories.Exists (Alire_Path),
              "delete must remove selected build config file");
      Assert (S.Build_UI.Selected_Candidate_Stale,
              "delete of build config must stale selected build candidate");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "stale build candidate must clear consent");
      Assert (not S.Build_UI.Pending_Public_Build_Request,
              "stale build candidate must clear pending request");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Build_Config_Marks_Selected_Candidate_Stale;


   procedure Test_Rename_Directory_With_Build_Config_Invalidates_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("build_config_dir_rename");
      Config_Dir : constant String := Ada.Directories.Compose (Root, "config");
      Old_Gpr    : constant String := Ada.Directories.Compose (Config_Dir, "demo.gpr");
      New_Dir    : constant String := Ada.Directories.Compose (Root, "renamed_config");
      New_Gpr    : constant String := Ada.Directories.Compose (New_Dir, "demo.gpr");
      S          : Editor.State.State_Type;
      Open_Res   : Editor.Project.Project_Open_Result;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd        : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Ada.Directories.Create_Directory (Config_Dir);
      Write_Text_File (Old_Gpr, "project Demo is end Demo;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "directory build-config setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidates.Append (Editor.Build_Candidates.Gprbuild_Candidate
        (Root, "config/demo.gpr"));
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 1,
              "setup must have a discovered build candidate");

      Select_File_Tree_Test_Path (S, "config");
      Cmd.Text := To_Unbounded_String ("renamed_config");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Gpr),
              "directory rename must move nested build config");
      Assert (not Ada.Directories.Exists (Old_Gpr),
              "directory rename must remove old nested build config path");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 0,
              "directory rename containing build config must clear stale candidates");
      Assert
        (S.Build_UI.Candidate_Refresh_Status =
           Editor.Build_UI.Build_Candidate_Refresh_Not_Requested,
         "stale build candidates must require explicit rediscovery");
      Assert
        (To_String (S.Build_UI.Candidate_Discovery_Message) =
           "Build candidates are stale after File Tree mutation",
         "directory build-config rename must report stale candidates");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Directory_With_Build_Config_Invalidates_Candidates;


   procedure Test_Rename_Marks_Relative_Diagnostics_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("relative_diag_stale");
      Old_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      New_Path : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "relative diagnostics setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "old file diagnostic",
         Source_Label => "a.txt");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Info,
         "unrelated diagnostic",
         Source_Label => "other.txt");

      Select_File_Tree_Test_Path (S, "a.txt");
      Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "relative diagnostics rename must create renamed target");
      Assert (not Ada.Directories.Exists (Old_Path),
              "relative diagnostics rename must remove old target");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "relative diagnostics rename must preserve diagnostic rows");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 1),
              "relative source-label diagnostic must be marked stale");
      Assert (not Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 2),
              "unrelated relative diagnostic must remain live");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Marks_Relative_Diagnostics_Stale;



   procedure Test_Rename_Marks_Relative_Build_Source_Candidate_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("relative_build_source_stale");
      Src_Dir  : constant String := Ada.Directories.Compose (Root, "src");
      Old_Path : constant String := Ada.Directories.Compose (Src_Dir, "main.adb");
      New_Path : constant String := Ada.Directories.Compose (Src_Dir, "renamed.adb");
      S        : Editor.State.State_Type;
      Open_Res : Editor.Project.Project_Open_Result;
      Candidate  : Editor.Build_Candidates.Build_Candidate_Record :=
        Editor.Build_Candidates.Gprbuild_Candidate (Root, "demo.gpr");
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Empty_Candidates;
      Cmd      : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Remove_Tree_If_Exists (Root);
      Build_Fixture (Root);
      Ada.Directories.Create_Directory (Src_Dir);
      Write_Text_File (Old_Path, "procedure Main is begin null; end Main;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Open_Res := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Res),
              "relative build-source setup project must open");
      Editor.Project.Apply_Open_Result (S.Project, Open_Res);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);

      Candidate.Candidate_Id := To_Unbounded_String ("relative-source-candidate");
      Candidate.Source_Path_If_Represented := To_Unbounded_String ("src/main.adb");
      Candidates.Append (Candidate);
      Editor.Build_UI.Set_Build_Candidates (S.Build_UI, Candidates, "test");
      S.Build_UI.Selected_Build_Candidate_Id :=
        To_Unbounded_String ("relative-source-candidate");
      S.Build_UI.Consent_Acknowledged := True;
      S.Build_UI.Pending_Public_Build_Request := True;

      Select_File_Tree_Test_Path (S, "src/main.adb");
      Cmd.Text := To_Unbounded_String ("renamed.adb");
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Ada.Directories.Exists (New_Path),
              "relative build-source rename must create renamed file");
      Assert (not Ada.Directories.Exists (Old_Path),
              "relative build-source rename must remove old file path");
      Assert (S.Build_UI.Selected_Candidate_Stale,
              "relative build-source candidate must be marked stale");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "stale relative build-source candidate must clear consent");
      Assert (not S.Build_UI.Pending_Public_Build_Request,
              "stale relative build-source candidate must clear pending request");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) = 1,
              "non-build-config source rename must preserve candidate list");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Marks_Relative_Build_Source_Candidate_Stale;


   overriding procedure Register_Tests (T : in out Project_Workspace_File_Tree_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Toggles_Directory'Access,
         "File Tree Toggle Directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Opens_And_Switches_File'Access,
         "File Tree Open And Switch File");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Node_Action_Invalid_Is_No_Op'Access,
         "File Tree Invalid No-Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Missing_Target_Does_Not_Open'Access,
         "missing file tree target does not open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Refresh_Preserves_Unchanged_Selection'Access,
         "refresh preserves unchanged file tree selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Refresh_Clears_Disappeared_Selection'Access,
         "refresh clears disappeared file tree selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Invalid_Open_Project_Clears_Silently'Access,
         "pending invalid open project clears silently");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Pending_Invalid_Close_Buffer_Clears_Silently'Access,
         "pending invalid close buffer clears silently");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Selected_Recent_Project_Opens_First_Entry'Access,
         "open selected recent project opens first entry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Selected_Recent_Project_Missing_Path_Fails_Safely'Access,
         "open selected recent project missing path fails safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recent_Project_Selection_Commands_Are_Transient'Access,
         "recent project selection commands are transient");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Show_Recent_Projects_Reports_No_Available'Access,
         "show recent projects reports no available entries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Already_Open_Missing_File_Focuses_Buffer'Access,
         "File Tree already-open missing file focuses buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_File_Tree_Rename_Active_Non_Ada'Access,
         "Language index survives File Tree rename of active non-Ada buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Active_File_Invalidates_Derived_State'Access,
         "rename active file invalidates derived state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Build_Config_Marks_Selected_Candidate_Stale'Access,
         "delete build config marks selected candidate stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Directory_With_Build_Config_Invalidates_Candidates'Access,
         "rename directory containing build config invalidates candidates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Marks_Relative_Diagnostics_Stale'Access,
         "rename marks relative diagnostics stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Marks_Relative_Build_Source_Candidate_Stale'Access,
         "rename marks relative build-source candidate stale");
   end Register_Tests;

end Editor.Executor.Project_Workspace_File_Tree_Tests;
