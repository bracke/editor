with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Build_Candidate_Refresh;
with Editor.Build_Candidates;
with Editor.Build_Command;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_Runner_Policy;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Ada_Language_Service;
with Editor.Buffers;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Configuration_Audit;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.Guided_Prompts;
with Editor.Input_Bridge;
with Editor.Lifecycle_Guidance;
with Editor.Messages;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Files;
with Editor.Navigation_History;
with Editor.Outline;
with Editor.Outline_Extractor;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Projects;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.State;
with Editor.Status_Bar;
with Editor.Test_Helper;
with Editor.Workspace_Persistence;

package body Editor.Dogfood_Workflow.Tests is

   use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Ada_Language_Service.Compiler_Diagnostic_Severity;
   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Focus_Management.Focus_Owner;
   use type Editor.Guided_Prompts.Prompt_Kind;
   use type Editor.State.File_Conflict_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffers.Buffer_Dirty_Category;
   use type Editor.Buffers.Buffer_Close_Eligibility;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline_Extractor.Extraction_Status;
   use type Editor.Project.Project_Open_Status;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Root return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/dogfood_project";
   end Temp_Root;

   function Temp_Config_Root return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return "/tmp/editor-tests/dogfood_config";
   end Temp_Config_Root;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Remove_File_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_File_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F   : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
      Parent : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      if Parent'Length > 0 and then not Ada.Directories.Exists (Parent) then
         Ada.Directories.Create_Path (Parent);
      end if;
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Text'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;
      if Text'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_File;

   function Read_File (Path : String) return String is
      Result : constant Editor.Files.File_Open_Result := Editor.Files.Open_File (Path);
   begin
      if Editor.Files.Is_Success (Result) then
         return To_String (Result.Contents);
      end if;
      return "";
   end Read_File;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Active_Message_Text;

   procedure Build_Dogfood_Fixture (Root : String) is
      Src : constant String := Root & "/src";
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_File
        (Root & "/dogfood_project.gpr",
         "project Dogfood_Project is" & ASCII.LF &
         "   for Source_Dirs use (""src"");" & ASCII.LF &
         "   for Main use (""main.adb"");" & ASCII.LF &
         "end Dogfood_Project;" & ASCII.LF);
      Write_File
        (Src & "/dogfood_demo.ads",
         "package Dogfood_Demo is" & ASCII.LF &
         "   type Dogfood_State is record" & ASCII.LF &
         "      Value : Integer := 0;" & ASCII.LF &
         "   end record;" & ASCII.LF & ASCII.LF &
         "   procedure Run (State : in out Dogfood_State);" & ASCII.LF &
         "   function Known_Token return String;" & ASCII.LF &
         "end Dogfood_Demo;" & ASCII.LF);
      Write_File
        (Src & "/dogfood_demo.adb",
         "package body Dogfood_Demo is" & ASCII.LF &
         "   procedure Run (State : in out Dogfood_State) is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      State.Value := State.Value + 1;" & ASCII.LF &
         "   end Run;" & ASCII.LF & ASCII.LF &
         "   function Known_Token return String is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      return ""Dogfood_Known_Token"";" & ASCII.LF &
         "   end Known_Token;" & ASCII.LF &
         "end Dogfood_Demo;" & ASCII.LF);
      Write_File
        (Src & "/main.adb",
         "with Dogfood_Demo;" & ASCII.LF & ASCII.LF &
         "procedure Main is" & ASCII.LF &
         "   State : Dogfood_Demo.Dogfood_State;" & ASCII.LF &
         "begin" & ASCII.LF &
         "   Dogfood_Demo.Run (State);" & ASCII.LF &
         "end Main;" & ASCII.LF);
   end Build_Dogfood_Fixture;

   function Has_Outline_Label
     (Outline : Editor.Outline.Outline_State;
      Needle  : String) return Boolean
   is
   begin
      for I in 1 .. Editor.Outline.Item_Count (Outline) loop
         if Ada.Strings.Fixed.Index (Editor.Outline.Item_Label (Outline, I), Needle) > 0 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Outline_Label;

   function First_Target_Row (Outline : Editor.Outline.Outline_State) return Natural is
   begin
      for I in 1 .. Editor.Outline.Item_Count (Outline) loop
         if Editor.Outline.Item_Target_Kind (Outline, I) =
              Editor.Outline.Buffer_Position_Target
         then
            return I;
         end if;
      end loop;
      return 0;
   end First_Target_Row;

   function Workspace_Text (Path : String) return String is
   begin
      return Read_File (Path);
   end Workspace_Text;

   procedure Run_File_Tree_Text_Prompt_Command
     (S              : in out Editor.State.State_Type;
      Id             : Editor.Commands.Command_Id;
      Text           : String;
      Expected_Kind  : Editor.Guided_Prompts.Prompt_Kind;
      Expected_Title : String)
   is
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      --  drive File Tree mutations through the same user-facing
      --  command -> guided prompt -> Executor route used by keybindings and
      --  Command Palette, rather than constructing payload-bearing commands
      --  directly in the test.  The only transient text lives in the prompt.
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Id);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);
      Assert (Snapshot.Active, Expected_Title & " prompt starts");
      Assert (S.Guided_Prompt.Kind = Expected_Kind,
              Expected_Title & " prompt has the expected kind");

      Editor.Guided_Prompts.Update_Input (S.Guided_Prompt, Text);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Insert_Newline);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              Expected_Title & " prompt completes and clears transient input");
   end Run_File_Tree_Text_Prompt_Command;

   procedure Run_File_Tree_Delete_Confirmation
     (S : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Guided_Prompts.Prompt_Snapshot;
   begin
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_File_Tree_Delete_Selected);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Guided_Prompts.Snapshot (S.Guided_Prompt);
      Assert (Snapshot.Active, "delete confirmation prompt starts");
      Assert (Snapshot.Requires_Confirmation and then Snapshot.Destructive,
              "delete prompt is a destructive confirmation");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Insert_Newline);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "delete confirmation completes and clears transient state");
   end Run_File_Tree_Delete_Confirmation;

   procedure Test_Dogfood_Project_Workflow_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Root;
      Source_Path   : constant String := Root & "/src/dogfood_demo.adb";
      Created_Path  : constant String := Root & "/src/new_widget.adb";
      Renamed_Path  : constant String := Root & "/src/renamed_widget.adb";
      Dirty_Block_Path : constant String := Root & "/src/dirty_block.adb";
      S             : Editor.State.State_Type;
      S2            : Editor.State.State_Type;
      Project_Files : Editor.Project.Project_File_Refresh_Result;
      Found         : Boolean := False;
      Node          : Editor.File_Tree.File_Tree_Node_Id;
      Row           : Natural := 0;
      Diagnostic_Row : Natural := 0;
      QO_Result     : Editor.Quick_Open.Quick_Open_Result;
      Search_Result : Editor.Project_Search.Project_Search_Result;
      QO_Snapshot   : Editor.Quick_Open.Quick_Open_Snapshot;
      Extracted     : Editor.Outline_Extractor.Extraction_Result;
      Outline_Row   : Natural := 0;
      Build_Refresh : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Context       : Editor.Build_Working_Context.Build_Working_Context_Record;
      Build_View    : Editor.Build_UI.Build_UI_Render_Snapshot;
      Build_Run     : Editor.Command_Execution.Command_Execution_Result;
      Supplied_Process : Editor.External_Producers.Process_Run_Result;
      Build_Command_Result : Editor.External_Producers.Build_Command_Result;
      Compiler_Status : Editor.Ada_Language_Service.Compiler_Backend_Status;
      Compiler_Diagnostic : Editor.Ada_Language_Service.Compiler_Diagnostic;
      Diagnostic_Open : Editor.Command_Execution.Command_Execution_Result;
      Workspace_Save : Editor.Command_Execution.Command_Execution_Result;
      Workspace_Restore : Editor.Command_Execution.Command_Execution_Result;
      Saved_Latest_Build_Result :
        Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      Saved_Latest_Build_Output_Details :
        Editor.Build_Output_Details.Latest_Build_Output_Details;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded        : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status        : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Workspace_Path : constant String := Root & "/.workspace";
      Persisted     : Unbounded_String;
   begin
      Build_Dogfood_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      --  Project open and project-scoped discovery.
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Assert (Editor.Project.Has_Project (S.Project),
              "dogfood project opens through the Executor project route");
      Assert (Editor.Project.Root_Path (S.Project) = Root,
              "canonical project root is retained");

      Editor.Project.Refresh_Known_Files (S.Project, Project_Files);
      Assert (Project_Files.Status = Editor.Project.Project_File_Refresh_Ok,
              "known project files refresh from the opened project root");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/dogfood_demo.adb"),
              "known Ada source file is available to project-scoped surfaces");

      --  File Tree over real fixture files, then open through the file-tree route.
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Assert (Editor.File_Tree.Node_Count (S.File_Tree) >= 4,
              "file tree scans real dogfood fixture nodes");
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/dogfood_demo.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "file tree contains the known Ada implementation file");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "known File Tree file maps to a selectable user row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Tree_Open_Selected);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "file-tree activation opens the expected source file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "File Tree file activation returns focus to editor text");

      --  Quick Open finds the same current-project file without owning payloads.
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "dogfood_demo.adb");
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      QO_Snapshot := Editor.Quick_Open.Build_Snapshot (S.Quick_Open);
      Assert (QO_Snapshot.Visible_Count > 0,
              "Quick Open shows at least one dogfood fixture match");
      QO_Result := Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
      Assert (Found and then To_String (QO_Result.Display_Path) = "src/dogfood_demo.adb",
              "Quick Open selects the expected Ada file");
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (To_String (S.File_Info.Path) = Source_Path,
              "Quick Open activation/focus uses the canonical file-open path");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "Quick Open activation returns focus to editor text through Executor");

      --  Editing and save over a real file-backed buffer.
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Assert (S.File_Info.Dirty, "editing marks the active source buffer dirty");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty, "save clears dirty state");
      Assert (Ada.Strings.Fixed.Index (Read_File (Source_Path), "Dogfood_Known_Token") > 0,
              "saved file still contains the known project-search token");

      --  file-mutation dogfood seam: create, rename, and delete
      --  run through the real command -> guided prompt -> Executor path.
      --  The test no longer mutates the fixture directly and then merely
      --  refreshes; it proves the user workflow refreshes File Tree/project
      --  discovery, invalidates adjacent surfaces, and returns focus coherently.
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Create_File,
         "src/new_widget.adb",
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         "create file");
      Assert (Ada.Directories.Exists (Created_Path),
              "File Tree create command creates the requested project file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "File Tree create keeps focus on File Tree for the next operation");
      Editor.Project.Refresh_Known_Files (S.Project, Project_Files);
      Assert (Editor.Project.Has_Known_File (S.Project, "src/new_widget.adb"),
              "created file appears after explicit project-file refresh");
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/new_widget.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "created file appears in File Tree after command-owned refresh");

      Write_File
        (Created_Path,
         "package New_Widget is" & ASCII.LF &
         "   procedure Created;" & ASCII.LF &
         "end New_Widget;" & ASCII.LF);
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "created File Tree row remains selectable for rename");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      --  Seed adjacent project-derived surfaces before the rename so the real
      --  File Tree mutation route must mark them stale through owning state,
      --  not just through policy helpers.
      Editor.Project_Search.Clear_Stale (S.Project_Search);
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "rename invalidates diagnostic target",
         Source_Label  => "src/new_widget.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 1,
         Target_Column => 1);

      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "renamed_widget.adb",
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         "rename file");
      Assert ((not Ada.Directories.Exists (Created_Path))
                and then Ada.Directories.Exists (Renamed_Path),
              "File Tree rename command moves the selected file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "File Tree rename keeps focus on File Tree for adjacent actions");
      Assert (Editor.Project_Search.Is_Stale (S.Project_Search),
              "real File Tree rename marks Project Search results stale");
      Assert (Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "real File Tree rename marks Quick Open candidates stale");
      Diagnostic_Row := 0;
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, I) =
           "src/new_widget.adb"
         then
            Diagnostic_Row := I;
         end if;
      end loop;
      Assert (Diagnostic_Row > 0,
              "real File Tree rename preserves the seeded Diagnostics source row");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale
                (S.Feature_Diagnostics, Diagnostic_Row),
              "real File Tree rename marks matching Diagnostics source rows stale");
      Editor.Feature_Diagnostics.Project_Rows
        (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Diagnostic_Row);
      Assert (not Editor.Commands.Is_Available
                (Editor.Executor.Command_Availability
                   (S, Editor.Commands.Command_Diagnostics_Open_Selected)),
              "stale diagnostic row cannot be opened after adjacent File Tree rename");
      Assert (Editor.Commands.Unavailable_Reason
                (Editor.Executor.Command_Availability
                   (S, Editor.Commands.Command_Diagnostics_Open_Selected)) =
              Editor.Commands.Reason_Target_Stale,
              "Diagnostic stale-target wording matches Search stale-target wording after rename");
      Editor.Project.Refresh_Known_Files (S.Project, Project_Files);
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/new_widget.adb"),
              "old file label disappears after explicit project-file refresh");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/renamed_widget.adb"),
              "renamed file appears after explicit project-file refresh");
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/renamed_widget.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "renamed file appears in File Tree after command-owned refresh");

      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "renamed_widget");
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      QO_Result := Editor.Quick_Open.Selected_Result (S.Quick_Open, Found);
      Assert (Found and then To_String (QO_Result.Display_Path) =
                "src/renamed_widget.adb",
              "Quick Open finds the renamed file after explicit project refresh");

      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "renamed File Tree row remains selectable for delete");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Run_File_Tree_Delete_Confirmation (S);
      Assert (not Ada.Directories.Exists (Renamed_Path),
              "File Tree delete command removes the selected clean file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "File Tree delete keeps focus on File Tree after completion");
      Editor.Project.Refresh_Known_Files (S.Project, Project_Files);
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/renamed_widget.adb", Found);
      Assert (not Found and then Node = Editor.File_Tree.No_File_Tree_Node,
              "deleted clean file is gone from File Tree after command-owned refresh");

      --  Stale selected-node handling: the prompt may start from an existing
      --  selection snapshot, but the Executor must revalidate before mutation
      --  and leave focus on the File Tree so the user can refresh/correct it.
      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Create_File,
         "src/stale_widget.adb",
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         "create stale-test file");
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/stale_widget.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "stale selected-node setup creates a selectable file");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "stale selected-node setup maps to a visible row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Remove_File_If_Exists (Root & "/src/stale_widget.adb");
      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "should_not_exist.adb",
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         "stale rename");
      Assert (not Ada.Directories.Exists (Root & "/src/should_not_exist.adb"),
              "stale File Tree rename does not create or move a replacement target");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "failed stale File Tree rename keeps focus on File Tree for correction");
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);

      --  Dirty open-buffer protection for File Tree mutation routes.  Rename
      --  and delete can collect prompt/confirmation input, but the Executor
      --  must still block filesystem mutation while dirty text is open.
      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Create_File,
         "src/dirty_block.adb",
         Editor.Guided_Prompts.File_Tree_Create_File_Prompt,
         "create dirty-block file");
      Write_File
        (Dirty_Block_Path,
         "package Dirty_Block is" & ASCII.LF &
         "end Dirty_Block;" & ASCII.LF);
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/dirty_block.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "dirty open-buffer setup creates a selectable file");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Dirty_Block_Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Assert (S.File_Info.Dirty,
              "dirty open-buffer setup leaves unsaved text in the target file");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "dirty open-buffer target maps to a visible File Tree row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "dirty_block_renamed.adb",
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         "dirty rename block");
      Assert (Ada.Directories.Exists (Dirty_Block_Path)
                and then not Ada.Directories.Exists
                  (Root & "/src/dirty_block_renamed.adb"),
              "dirty File Tree rename is blocked without moving the file");
      Run_File_Tree_Delete_Confirmation (S);
      Assert (Ada.Directories.Exists (Dirty_Block_Path),
              "dirty File Tree delete is blocked without deleting the file");
      Assert (S.File_Info.Dirty,
              "blocked File Tree mutations preserve dirty target buffer text");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);

      --  Ada Outline refresh from an explicit active-buffer snapshot.
      Extracted := Editor.Outline_Extractor.Extract
        (Editor.Outline_Extractor.Make_Snapshot
           (Editor.State.Current_Text (S),
            "dogfood_demo.adb",
            S.Active_Buffer_Token,
            S.Buffer_Revision,
            S.Lifecycle_Generation,
            535));
      Assert (Editor.Outline_Extractor.Status (Extracted) =
                Editor.Outline_Extractor.Extraction_Ok,
              "Ada Outline extraction succeeds on the real dogfood buffer");
      Editor.Outline.Begin_Extraction
        (S.Outline, Editor.Outline_Extractor.Identity (Extracted));
      Editor.Outline_Extractor.Apply_To_Outline (Extracted, S.Outline);
      Assert (Editor.Outline.Item_Count (S.Outline) >= 3,
              "Outline exposes real extracted Ada rows");
      Assert (Has_Outline_Label (S.Outline, "Dogfood_Demo"),
              "Outline includes the package/package-body row");
      Assert (Has_Outline_Label (S.Outline, "Run"),
              "Outline includes the procedure row");
      Assert (Has_Outline_Label (S.Outline, "Known_Token"),
              "Outline includes the function row");
      Outline_Row := First_Target_Row (S.Outline);
      Assert (Outline_Row > 0, "at least one Outline row has a source target");
      Editor.Outline.Select_Item (S.Outline, Outline_Row);
      Assert (Editor.Outline.Item_Line (S.Outline, Outline_Row) > 0,
              "Outline target has a one-based source line");
      Assert (Editor.Outline.Item_Column (S.Outline, Outline_Row) > 0,
              "Outline target has a one-based source column");

      --  Project Search finds and validates a real source target.
      Editor.Project_Search.Set_Query (S.Project_Search, "Dogfood_Known_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project,
         (Case_Sensitive => True,
          Max_File_Count => 100,
          Max_Result_Count => 20,
          Max_Matches_Per_File => 5,
          Max_Line_Length => Editor.Project_Search.Max_Search_Result_Preview_Length,
          Max_File_Size_Bytes => 64 * 1024,
          Regex_Max_Steps => 100_000));
      Assert (Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_Ok,
              "Project Search succeeds against current project files");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "Project Search finds the known token once");
      Search_Result := Editor.Project_Search.Result_At (S.Project_Search, 1);
      Assert (To_String (Search_Result.Relative_Path) = "src/dogfood_demo.adb",
              "Project Search result points at the expected source file");
      Assert (Search_Result.Row > 0 and then Search_Result.Match_Column > 0,
              "Project Search result carries a navigable source location");
      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, 1);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Open_Selected);
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "Search result activation returns focus to editor text through Executor");
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);
      Editor.Project_Search.Mark_Stale (S.Project_Search);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Open_Selected);
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Project_Search_Results,
              "failed stale Search activation keeps focus on Search results for correction");
      Editor.Project_Search.Clear_Stale (S.Project_Search);
      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);

      --  Build UI candidate refresh, explicit command-route selection, consent,
      --  deterministic bounded run, Diagnostics ingestion, and diagnostic target open.
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Show);
      Assert (S.Build_UI.Build_UI_Visible,
              "Build UI is shown through the public command route");
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Build_Refresh := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S.Build_UI, Context);
      Assert (Build_Refresh.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "Build UI refresh discovers dogfood project build candidates");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) >= 1,
              "Build UI stores discovered candidates only as transient UI state");
      Assert (To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length = 0,
              "candidate refresh does not auto-select");
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Select_Next_Candidate);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "Build candidate selection executes through Executor");
      Assert (To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0,
              "candidate selection is explicit");
      Assert (To_String (S.Build_UI.Candidate_Request_Preview)'Length > 0,
              "selected candidate exposes a structured request preview");
      Assert (not S.Build_UI.Consent_Acknowledged,
              "candidate selection does not auto-consent");
      if not S.Build_UI.Show_Diagnostics_On_Result then
         Build_Run := Editor.Executor.Execute_Command_With_Result
           (S, Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion);
         Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
                 "build diagnostics ingestion is enabled through Executor");
      end if;
      Assert (S.Build_UI.Show_Diagnostics_On_Result,
              "Build UI request explicitly enables diagnostics ingestion");
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Acknowledge_Consent);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "build consent is acknowledged through Executor");
      Assert (S.Build_UI.Consent_Acknowledged,
              "build consent is explicitly acknowledged");
      Assert (Editor.Build_Command.Build_Run_Availability (S).Status =
                Editor.Commands.Command_Available,
              "build.run is available once project, candidate, policy, and consent agree");

      Supplied_Process := Editor.External_Producers.Build_Process_Run_Result
        (Editor.External_Producers.Process_Run_Failed,
         Exit_Code => 1,
         Has_Exit_Code => True,
         Stdout_Text => "compiling dogfood_demo.adb",
         Stderr_Text => "src/dogfood_demo.adb:2:4: warning: dogfood diagnostic");
      Build_Command_Result :=
        Editor.Build_Command.Execute_Public_Build_Run_With_Supplied_Result
          (S, Supplied_Process);
      Assert (Build_Command_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Failed,
              "public build.run frontdoor consumes the deterministic bounded process result");
      Assert (Build_Command_Result.Diagnostic_Result.Ingestion.Ingestion_Result.Accepted_Count >= 1,
              "public build.run ingests diagnostics through the Diagnostics-owned seam");
      Compiler_Status :=
        Editor.Ada_Language_Service.Compiler_Status (S.Language_Service);
      Assert (Compiler_Status.Has_Run
              and then Compiler_Status.Accepted_Count >= 1
              and then Compiler_Status.Warning_Count >= 1,
              "public build.run feeds compiler diagnostics into the language service");
      Compiler_Diagnostic :=
        Editor.Ada_Language_Service.Compiler_Diagnostic_At
          (S.Language_Service, 1);
      Assert (Compiler_Diagnostic.Severity =
                Editor.External_Producers.Compiler_Warning,
              "public build.run preserves compiler diagnostic severity");
      Assert (Compiler_Diagnostic.Has_Location
              and then Compiler_Diagnostic.Line = 2
              and then Compiler_Diagnostic.Column = 4,
              "public build.run preserves compiler diagnostic source location");
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "semantic project refresh executes after public build.run");
      Compiler_Status :=
        Editor.Ada_Language_Service.Compiler_Status (S.Language_Service);
      Assert (Compiler_Status.Has_Run
              and then Compiler_Status.Warning_Count >= 1
              and then Editor.Ada_Language_Service.Compiler_Diagnostic_Count
                (S.Language_Service) >= 1,
              "semantic project refresh preserves compiler-backed language diagnostics");
      Assert (S.Latest_Build_Result.Has_Result,
              "Build latest result summary is updated by the public build frontdoor");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details,
              "Build output details are captured by the public build frontdoor");
      Saved_Latest_Build_Result := S.Latest_Build_Result;
      Saved_Latest_Build_Output_Details := S.Latest_Build_Output_Details;
      Editor.Build_Output_Details.Show_Output_Details (S.Latest_Build_Output_Details);
      Build_View := Editor.Build_UI.Build_Render_Snapshot
        (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details);
      Assert (Build_View.Latest_Result.Latest_Build_Result_Visible,
              "Build UI snapshot exposes latest result summary");
      Assert (Build_View.Output_Details.Output_Details_Available,
              "Build UI snapshot exposes bounded output details");
      Assert (Build_View.Diagnostics_View.Reveal_Available,
              "Build UI exposes Diagnostics reveal when diagnostics are represented");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
              "Diagnostics surface owns the resulting diagnostic rows");
      Diagnostic_Row := 0;
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Ada.Strings.Fixed.Index
           (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, I),
            "dogfood diagnostic") > 0
         then
            Diagnostic_Row := I;
            exit;
         end if;
      end loop;
      Assert (Diagnostic_Row > 0,
              "Diagnostics surface includes the build diagnostic target");
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Diagnostic_Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      Diagnostic_Open := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (Diagnostic_Open.Status = Editor.Command_Execution.Command_Executed,
              "diagnostic target opens through Diagnostics command routing");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "Diagnostics target navigation returns focus to editor text");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Source_Path,
              "workspace fixture saves the intended active source file");

      --  Workspace persistence retains structural state only.
      Editor.Workspace_Persistence.Clear (Workspace);
      Editor.Workspace_Persistence.Set_Project_Root (Workspace, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Workspace,
         (Path => To_Unbounded_String ("src/dogfood_demo.adb"),
          Is_Project_Relative => True,
          Cursor_Row => Search_Result.Row,
          Cursor_Column => Search_Result.Match_Column,
          View_First_Row => 1));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Workspace, "src/dogfood_demo.adb", True);
      Editor.Workspace_Persistence.Save_To_File (Workspace, Workspace_Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace snapshot saves successfully");
      Editor.Workspace_Persistence.Load_From_File (Workspace_Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace snapshot reloads successfully");
      Assert (Editor.Workspace_Persistence.Has_Project_Root (Loaded),
              "workspace reload restores retained project root");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "workspace reload restores retained open-file reference");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "workspace reload restores retained active-file reference");

      Persisted := To_Unbounded_String (Workspace_Text (Workspace_Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Dogfood_Known_Token") = 0,
              "workspace persistence excludes unsaved/source text");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Build_Candidates") = 0,
              "workspace persistence excludes Build candidates");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Consent") = 0,
              "workspace persistence excludes Build consent");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Latest_Build") = 0,
              "workspace persistence excludes latest build result/output state");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Outline") = 0,
              "workspace persistence excludes Outline rows");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Quick_Open") = 0,
              "workspace persistence excludes Quick Open matches");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Project_Search") = 0,
              "workspace persistence excludes Project Search results");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "diagnostic") = 0,
              "workspace persistence excludes Diagnostics rows");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Transient_State_Not_Persisted
                (To_String (Persisted)),
              "dogfood persistence audit helper rejects transient workflow leakage");

      --  restart/reload seam: save through the real workspace
      --  command, then create a fresh editor state, contaminate transient
      --  surfaces, and restore through the real workspace command.  Restore
      --  must install only structural project/open-file/caret/panel state and
      --  must clear pre-restore Search, Outline, Diagnostics, Build, Quick
      --  Open, prompt, and runtime-only details.
      Workspace_Save := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_Workspace_State);
      Assert (Workspace_Save.Status = Editor.Command_Execution.Command_Executed,
              "workspace structural save executes through Executor");
      Assert (Ada.Directories.Exists
                (Editor.Workspace_Persistence.Session_File_Path (Root)),
              "workspace save writes the project session file");

      Editor.State.Init (S2);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S2, Root);
      Assert (Editor.Project.Has_Project (S2.Project),
              "restart opens the same project before workspace restore");
      Editor.Project.Refresh_Known_Files (S2.Project, Project_Files);
      Assert (Project_Files.Status = Editor.Project.Project_File_Refresh_Ok,
              "restart project known files refresh before transient contamination");

      Editor.Quick_Open.Open (S2.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S2.Quick_Open, "dogfood");
      Editor.Quick_Open.Recompute_Results
        (S2.Quick_Open, S2.Project, (Max_Visible_Results => 12,
                                     Max_Result_Count => 100,
                                     Query_Field_Min_Columns => 24,
                                     Overlay_Width_In_Columns => 72,
                                     Row_Height_In_Rows => 1,
                                     Header_Height_In_Rows => 1,
                                     Field_Height_In_Rows => 1,
                                     Result_Padding_Columns => 1));
      Editor.Project_Search.Set_Query (S2.Project_Search, "Dogfood_Known_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S2.Project_Search, S2.Project,
         (Case_Sensitive => True,
          Max_File_Count => 100,
          Max_Result_Count => 20,
          Max_Matches_Per_File => 5,
          Max_Line_Length => Editor.Project_Search.Max_Search_Result_Preview_Length,
          Max_File_Size_Bytes => 64 * 1024,
          Regex_Max_Steps => 100_000));
      Editor.Outline.Begin_Extraction
        (S2.Outline, Editor.Outline_Extractor.Identity (Extracted));
      Editor.Outline_Extractor.Apply_To_Outline (Extracted, S2.Outline);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S2.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "pre-restore diagnostic",
         Source_Label => "pre-restore",
         Build_Produced => True);
      Editor.Executor.Execute_Command (S2, Editor.Commands.Command_Build_UI_Show);
      S2.Latest_Build_Result := Saved_Latest_Build_Result;
      S2.Latest_Build_Output_Details := Saved_Latest_Build_Output_Details;
      Editor.Guided_Prompts.Start
        (S2.Guided_Prompt,
         Editor.Guided_Prompts.Search_Query_Prompt,
         Editor.Commands.Command_Run_Project_Search,
         "Project Search",
         "Enter search text.",
         "Project Search");

      Assert (Editor.Quick_Open.Is_Open (S2.Quick_Open),
              "restart precondition has transient Quick Open state");
      Assert (Editor.Project_Search.Result_Count (S2.Project_Search) > 0,
              "restart precondition has transient Project Search results");
      Assert (Editor.Outline.Item_Count (S2.Outline) > 0,
              "restart precondition has transient Outline rows");
      Assert (Editor.Feature_Diagnostics.Row_Count (S2.Feature_Diagnostics) > 0,
              "restart precondition has transient Diagnostics rows");
      Assert (S2.Build_UI.Build_UI_Visible,
              "restart precondition has transient Build UI state");
      Assert (S2.Latest_Build_Result.Has_Result,
              "restart precondition has transient latest Build result");
      Assert (S2.Latest_Build_Output_Details.Has_Output_Details,
              "restart precondition has transient Build output details");
      Assert (Editor.Guided_Prompts.Is_Active (S2.Guided_Prompt),
              "restart precondition has transient prompt state");

      Workspace_Restore := Editor.Executor.Execute_Command_With_Result
        (S2, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Workspace_Restore.Status = Editor.Command_Execution.Command_Executed,
              "workspace restore executes through Executor");
      Assert (Editor.Project.Has_Project (S2.Project)
                and then Editor.Project.Root_Path (S2.Project) = Root,
              "workspace restore preserves the active project identity");
      Assert (S2.File_Info.Has_Path
                and then To_String (S2.File_Info.Path) = Source_Path,
              "workspace restore reinstalls the active source buffer");
      Assert (not S2.File_Info.Dirty,
              "workspace restore does not fabricate dirty buffer text");
      Assert (Ada.Strings.Fixed.Index
                (Editor.State.Current_Text (S2), "Dogfood_Known_Token") > 0,
              "workspace restore reloads source text from disk");
      Assert (Editor.Quick_Open.Result_Count (S2.Quick_Open) = 0
                and then not Editor.Quick_Open.Is_Open (S2.Quick_Open),
              "workspace restore clears Quick Open transient matches");
      Assert (Editor.Project_Search.Result_Count (S2.Project_Search) = 0,
              "workspace restore clears Project Search transient results");
      Assert (Editor.Outline.Item_Count (S2.Outline) = 0,
              "workspace restore clears Outline transient rows");
      Assert (Editor.Feature_Diagnostics.Row_Count (S2.Feature_Diagnostics) = 0,
              "workspace restore clears Diagnostics transient rows");
      Assert (not S2.Build_UI.Build_UI_Visible
                and then Editor.Build_UI.Candidate_Count (S2.Build_UI) = 0,
              "workspace restore clears Build candidate/UI transient state");
      Assert (not S2.Latest_Build_Result.Has_Result,
              "workspace restore clears latest Build result state");
      Assert (not S2.Latest_Build_Output_Details.Has_Output_Details,
              "workspace restore clears Build output details state");
      Assert (not Editor.Guided_Prompts.Is_Active (S2.Guided_Prompt),
              "workspace restore clears prompt state");
      Assert (not Editor.Pending_Transitions.Has_Pending (S2.Pending_Transitions),
              "workspace restore clears pending lifecycle decisions");

      Persisted := To_Unbounded_String
        (Workspace_Text (Editor.Workspace_Persistence.Session_File_Path (Root)));
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Active_Buffer_Token") = 0,
              "workspace session file excludes runtime active-buffer tokens");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Buffer_Id") = 0,
              "workspace session file excludes runtime buffer ids");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Dirty") = 0,
              "workspace session file excludes dirty state");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "Conflict") = 0,
              "workspace session file excludes file-conflict tokens");
      Assert (Ada.Strings.Fixed.Index (To_String (Persisted), "pre-restore diagnostic") = 0,
              "workspace session file excludes Diagnostics content");

      Remove_Tree_If_Exists (Root);
   end Test_Dogfood_Project_Workflow_Coherent;


   procedure Test_Dogfood_Usability_Fixes_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Persisted : constant String :=
        "project_root=" & ASCII.LF &
        "open_file=src/dogfood_demo.adb" & ASCII.LF;
   begin
      Assert (Editor.Dogfood_Workflow.Dogfood_Status_Label
                (Editor.Dogfood_Workflow.Dogfood_Surface_Quick_Open,
                 Editor.Dogfood_Workflow.Dogfood_State_Empty) =
              "No Quick Open matches.",
              "Quick Open empty state uses dogfood wording");
      Assert (Editor.Dogfood_Workflow.Dogfood_Unavailable_Reason_Label
                (Editor.Dogfood_Workflow.Dogfood_Surface_Project_Search,
                 Editor.Dogfood_Workflow.Dogfood_State_Stale) =
              "Search result is stale; run Project Search again.",
              "Project Search stale reason is actionable");
      Assert (Editor.Dogfood_Workflow.Dogfood_Unavailable_Reason_Label
                (Editor.Dogfood_Workflow.Dogfood_Surface_Diagnostics,
                 Editor.Dogfood_Workflow.Dogfood_State_Target_Unavailable) =
              Editor.Commands.Reason_Target_Missing,
              "Diagnostics target failure uses shared missing-target wording");
      Assert (Editor.Dogfood_Workflow.Dogfood_Unavailable_Reason_Label
                (Editor.Dogfood_Workflow.Dogfood_Surface_Build,
                 Editor.Dogfood_Workflow.Dogfood_State_Consent_Missing) =
              "Build run unavailable: review the request and acknowledge consent first.",
              "Build missing-consent reason identifies the next action");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Messages_User_Readable,
              "dogfood messages avoid internal enum wording");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Focus_Transitions_Coherent,
              "activation messages encode predictable buffer focus policy");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Usability_Fixes_Coherent
                (Persisted),
              "usability helper preserves transient-state exclusion");
   end Test_Dogfood_Usability_Fixes_Coherent;


   procedure Test_Milestone_Readiness_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Workspace_Text : constant String :=
        "project_root=tests/fixtures/dogfood_project" & ASCII.LF &
        "open_file=src/dogfood_demo.adb" & ASCII.LF &
        "active_file=src/dogfood_demo.adb" & ASCII.LF;
      Recent_Text : constant String :=
        "recent_project=tests/fixtures/dogfood_project" & ASCII.LF;
      Keybindings_Text : constant String :=
        "project.open=Ctrl+Alt+O" & ASCII.LF &
        "quick-open=Ctrl+P" & ASCII.LF &
        "save-file=Ctrl+S" & ASCII.LF &
        "command-palette=Ctrl+Shift+P" & ASCII.LF;
      Product_Text : constant String :=
        "startup=no-project" & ASCII.LF &
        "empty-state=real" & ASCII.LF &
        "commands=product" & ASCII.LF;
      S : Editor.State.State_Type;
   begin
      Assert (Editor.Dogfood_Workflow.Startup_State_Label
                (Editor.Dogfood_Workflow.Startup_Project) =
              "No project open.",
              "fresh startup uses an explicit no-project label");
      Assert (Editor.Dogfood_Workflow.Startup_State_Label
                (Editor.Dogfood_Workflow.Startup_Command_Palette) =
              "Command Palette available.",
              "fresh startup keeps command discovery available");
      Assert (Editor.Dogfood_Workflow.First_Run_Command_Disabled_Reason
                (Editor.Dogfood_Workflow.Dogfood_Surface_Build,
                 Editor.Dogfood_Workflow.Dogfood_State_Empty) =
              "No build request ready.",
              "first-run build disabled reason identifies missing request");
      Assert (Editor.Dogfood_Workflow.First_Run_Command_Disabled_Reason
                (Editor.Dogfood_Workflow.Dogfood_Surface_File_Tree,
                 Editor.Dogfood_Workflow.Dogfood_State_No_Selection) =
              "No file selected.",
              "first-run file tree disabled reason identifies missing selection");
      Assert (Editor.Dogfood_Workflow.Workspace_Reload_User_Message
                (Editor.Dogfood_Workflow.Workspace_No_Project_To_Restore) =
              "Workspace contains no project to restore.",
              "workspace reload has a predictable empty-project message");
      Assert (Editor.Dogfood_Workflow.Assert_Fresh_Startup_Coherent,
              "fresh startup labels are coherent and user-readable");
      Assert (Editor.Dogfood_Workflow.Assert_First_Run_Command_Surface_Coherent,
              "first-run command surface reasons are specific");
      Assert (Editor.Dogfood_Workflow.Assert_Workspace_Reload_Minimal
                (Workspace_Text),
              "workspace reload policy excludes transient dogfood state");
      Assert (Editor.Dogfood_Workflow.Assert_Recent_Project_Does_Not_Restore_Transient_State
                (Recent_Text),
              "recent project references do not encode workspace/transient state");
      Assert (Editor.Dogfood_Workflow.Assert_Default_Keybindings_Safe
                (Keybindings_Text),
              "default keybinding text contains no payload or unsafe shortcut policy");
      Assert (not Editor.Dogfood_Workflow.Assert_Default_Keybindings_Safe
                ("open-project=Ctrl+O" & ASCII.LF),
              "default keybinding policy rejects legacy project-open Ctrl+O");
      Assert (not Editor.Dogfood_Workflow.Assert_Default_Keybindings_Safe
                ("build-run=Ctrl+B" & ASCII.LF),
              "default keybinding policy rejects bound build-run shortcuts");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Artifacts_No_Demo_State
                (Product_Text),
              "product milestone artifacts expose no demo or placeholder rows");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Repeatable
                (Workspace_Text, Workspace_Text),
              "dogfood workspace text is repeatable across runs");
      Assert (Editor.Dogfood_Workflow.Assert_Milestone_Startup_And_Dogfood_Readiness_Coherent
                (Workspace_Text, Recent_Text, Keybindings_Text, Product_Text),
              "milestone readiness helper covers startup, reload, recent projects, defaults, and dogfood repeatability");
   end Test_Milestone_Readiness_Coherent;



   procedure Test_Repeated_Local_Use_Hardening_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Workspace_Text : constant String :=
        "editor-workspace-version=1" & ASCII.LF &
        "project-root=/tmp/dogfood" & ASCII.LF &
        "[open-files]" & ASCII.LF &
        "src/main.adb|relative=true|row=1|column=1|view=1" & ASCII.LF &
        "[active-file]" & ASCII.LF &
        "src/main.adb|relative=true" & ASCII.LF &
        "[panels]" & ASCII.LF &
        "file-tree-visible=true" & ASCII.LF &
        "bottom-visible=true" & ASCII.LF &
        "bottom-content=problems" & ASCII.LF;
      Recent_Text : constant String :=
        "project=/tmp/dogfood" & ASCII.LF &
        "project=/tmp/other" & ASCII.LF;
      Keybindings_Text : constant String :=
        "project.open=Ctrl+Alt+O" & ASCII.LF &
        "quick-open=Ctrl+P" & ASCII.LF &
        "project-search=Ctrl+Shift+F" & ASCII.LF &
        "build-run=none" & ASCII.LF;
      Product_Text : constant String :=
        "startup=no-project" & ASCII.LF &
        "empty-state=real" & ASCII.LF &
        "commands=product" & ASCII.LF;
      S : Editor.State.State_Type;
   begin
      Assert (Editor.Dogfood_Workflow.Recent_Project_Open_Result_Label
                (Editor.Dogfood_Workflow.Recent_Project_Opened) =
              "Recent project opened.",
              "recent-project open success message is specific");
      Assert (Editor.Dogfood_Workflow.Recent_Project_Open_Result_Label
                (Editor.Dogfood_Workflow.Recent_Project_Path_Missing) =
              Editor.Commands.Reason_Target_Missing,
              "missing recent-project path message uses the shared missing-target label");
      Assert (Editor.Dogfood_Workflow.Workspace_Reload_Recovery_Label
                (Editor.Dogfood_Workflow.Workspace_Some_Files_Not_Reopened) =
              "Some files could not be reopened.",
              "workspace reload reports missing restored files clearly");
      Assert (Editor.Dogfood_Workflow.Project_Switch_Dirty_Guard_Label
                (Editor.Dogfood_Workflow.Project_Dirty_Guard_Blocked_Close) =
              "Project close blocked: save or discard unsaved project files first.",
              "project close dirty guard names the blocked transition");
      Assert (Editor.Dogfood_Workflow.Stale_Target_Activation_Label
                (Editor.Dogfood_Workflow.Stale_Target_Project_Search) =
              "Search result is stale.",
              "stale search activation fails with a deterministic message");
      Assert (Editor.Dogfood_Workflow.Stale_Target_Activation_Label
                (Editor.Dogfood_Workflow.Stale_Target_Diagnostics) =
              Editor.Commands.Reason_Target_Missing,
              "stale diagnostics activation uses shared missing-target wording");
      Assert (Editor.Dogfood_Workflow.Assert_Repeated_Startup_Coherent,
              "repeated startup keeps empty transient surfaces and command discovery coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Recent_Project_Uses_Project_Lifecycle
                (Recent_Text),
              "recent projects remain project references and lifecycle-open only");
      Assert (Editor.Dogfood_Workflow.Assert_Workspace_Reload_Does_Not_Restore_Transient_State
                (Workspace_Text),
              "workspace reload restores only structural session data");
      Assert (Editor.Dogfood_Workflow.Assert_Project_Close_Clears_Project_Scoped_State,
              "project close/switch labels cover dirty guards and stale target failures");
      Assert (Editor.Dogfood_Workflow.Assert_Dogfood_Repeated_Use_Coherent
                (Workspace_Text, Workspace_Text),
              "dogfood workflow remains repeatable across reload cycles");
      Assert (Editor.Dogfood_Workflow.Assert_Repeated_Local_Use_Coherent
                (Workspace_Text, Recent_Text, Keybindings_Text, Product_Text),
              "repeated-local-use hardening helper covers startup, recent reopen, workspace reload, project close, stale activation, dogfood repeatability, and persistence boundaries");
   end Test_Repeated_Local_Use_Hardening_Coherent;



   procedure Test_Dirty_Conflict_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Root & "_conflict";
      Source_Path : constant String := Root & "/src/dogfood_demo.adb";
      S           : Editor.State.State_Type;
      Node        : Editor.File_Tree.File_Tree_Node_Id;
      Found       : Boolean := False;
      Target      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Metadata    : Editor.Buffers.Buffer_Metadata_Snapshot;
      Summary     : Editor.Buffers.Buffer_Summary;
      Status      : Editor.Status_Bar.Status_Bar_Snapshot;
   begin
      --  dirty/conflict dogfood path: exercise the real file
      --  lifecycle, prompt, File Tree refresh, and dirty-close routes together
      --  instead of checking conflict labels in isolated file-lifecycle tests.
      Build_Dogfood_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Target := Editor.Buffers.Global_Active_Buffer;
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "conflict dogfood setup opens the project source file");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Assert (S.File_Info.Dirty,
              "conflict dogfood setup marks the file-backed buffer dirty");
      Write_File (Source_Path, "external replacement before save" & ASCII.LF);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
              "saving after an external replacement opens a file-conflict prompt");
      Assert (S.File_Conflict_Prompt_Kind in
                Editor.State.External_Modified_While_Dirty
                  | Editor.State.Backing_File_Replaced,
              "external replacement is classified as a changed backing file");
      Assert (S.File_Info.Dirty,
              "conflict prompt preserves dirty buffer text");
      Assert (Read_File (Source_Path) = "external replacement before save" & ASCII.LF,
              "conflict prompt does not overwrite the external disk version");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
              "cancel clears the file-conflict prompt");
      Assert (S.File_Info.Dirty,
              "cancel preserves dirty text and marker");
      Assert (Read_File (Source_Path) = "external replacement before save" & ASCII.LF,
              "cancel leaves the external disk file unchanged");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
              "saving again revalidates the still-conflicted backing file");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Keep_Buffer);
      Assert (not S.File_Conflict_Prompt_Active,
              "keep-buffer dismisses the conflict prompt");
      Assert (S.File_Info.Dirty and then S.File_Info.External_Change_Surfaced,
              "keep-buffer preserves dirty state and exposes changed-on-disk state");
      Metadata := Editor.Buffers.Global_Metadata_For (S.Project, Target);
      Summary := Editor.Buffers.Global_Summary_For (Target);
      Assert (Metadata.External_Conflict and then Metadata.Stale_Backing_State,
              "Buffer List metadata exposes the same changed-on-disk conflict state");
      Assert (Metadata.Dirty_Category = Editor.Buffers.Buffer_Dirty_Conflicted_File,
              "Buffer List dirty category agrees that the dirty file is conflicted");
      Assert (Metadata.Close_Eligibility =
                Editor.Buffers.Buffer_Requires_Conflict_Resolution_Or_Discard,
              "Buffer List close eligibility requires conflict resolution or discard");
      Assert (To_String (Metadata.Lifecycle_Status_Label) = "Conflict pending",
              "Buffer List lifecycle label uses the same conflict wording as status");
      Assert (Ada.Strings.Fixed.Index (To_String (Metadata.Display_Label),
                                      "conflict pending") > 0,
              "Buffer List display label exposes conflict pending instead of generic external-change text");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "conflict pending") > 0,
              "status lifecycle hint agrees with Buffer List conflict wording");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "conflict pending") > 0,
              "dirty close/open-buffer guidance uses the same conflict wording");
      Status.Has_Active_Buffer := True;
      Status.File_Label := To_Unbounded_String ("src/dogfood_demo.adb");
      Status.Buffer_Kind_Label := Metadata.Ownership_Label;
      Status.File_State_Label := Metadata.Lifecycle_Status_Label;
      Status.Is_Dirty := S.File_Info.Dirty;
      Status.Dirty_State_Label := To_Unbounded_String ("Modified");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Status_Bar.Format_Left (Status), "Conflict pending") > 0,
              "status-left projection agrees with Buffer List lifecycle conflict label");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Status_Bar.Status_Dirty_File_State_Segment (Status),
                 "Conflict pending") > 0,
              "compact status state segment agrees with Buffer List lifecycle conflict label");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
              "overwrite path starts from a fresh validated conflict prompt");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Conflict_Prompt_Active,
              "overwrite clears the conflict prompt");
      Assert (not S.File_Info.Dirty,
              "overwrite saves the dirty buffer and clears the dirty marker");
      Assert (not S.File_Info.External_Change_Surfaced,
              "overwrite clears the changed-on-disk marker");
      Assert (Ada.Strings.Fixed.Index (Read_File (Source_Path),
                                      "Dogfood_Known_Token") > 0,
              "overwrite writes the editor buffer, not the external replacement");

      --  Missing backing file path: cancellation must be atomic, and explicit
      --  File Tree refresh must surface the deleted file without render-side
      --  repair.
      Editor.Buffers.Reset_Global_For_Test;
      Build_Dogfood_Fixture (Root);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Remove_File_If_Exists (Source_Path);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
              "saving a dirty buffer after external deletion opens a conflict prompt");
      Assert (S.File_Conflict_Prompt_Kind =
                Editor.State.Backing_File_Deleted_While_Dirty,
              "external deletion is classified as missing backing file while dirty");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
              "missing-file conflict cancel clears the prompt");
      Assert (S.File_Info.Dirty,
              "missing-file conflict cancel preserves dirty text");
      Metadata := Editor.Buffers.Global_Metadata_For
        (S.Project, Editor.Buffers.Global_Active_Buffer);
      Assert (Metadata.Missing_Backing_File and then Metadata.Stale_Backing_State,
              "Buffer List metadata exposes the same missing backing file state");
      Assert (Metadata.Dirty_Category = Editor.Buffers.Buffer_Dirty_Missing_File,
              "Buffer List dirty category agrees that the dirty file is missing");
      Assert (Metadata.Close_Eligibility =
                Editor.Buffers.Buffer_Requires_Conflict_Resolution_Or_Discard,
              "dirty missing file requires conflict resolution or discard before close");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S), "backing file missing") > 0,
              "status lifecycle hint agrees with Buffer List missing-file wording");
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/dogfood_demo.adb", Found);
      Assert (not Found and then Node = Editor.File_Tree.No_File_Tree_Node,
              "File Tree refresh reflects the externally deleted backing file");

      --  Dirty close + save-and-close over an externally changed file must not
      --  silently discard or overwrite.  The close route should hand off to
      --  the same file-conflict prompt, and overwrite confirmation should then
      --  resume the close.
      Editor.Buffers.Reset_Global_For_Test;
      Build_Dogfood_Fixture (Root);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Target := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Write_File (Source_Path, "external replacement before close" & ASCII.LF);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "closing a dirty file-backed buffer opens dirty-close review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (not S.Dirty_Close_Prompt_Active,
              "save-and-close conflict exits dirty-close review");
      Assert (S.File_Conflict_Prompt_Active,
              "save-and-close conflict opens the file-conflict prompt");
      Assert (Editor.Buffers.Global_Contains (Target),
              "conflicted save-and-close keeps the buffer open");
      Assert (S.File_Info.Dirty,
              "conflicted save-and-close keeps dirty text selected");
      Assert (Editor.Buffers.Global_Active_Buffer = Target,
              "failed save-and-close keeps the conflicted buffer selected for correction");
      Metadata := Editor.Buffers.Global_Metadata_For (S.Project, Target);
      Assert (Metadata.Dirty_Category = Editor.Buffers.Buffer_Dirty_Conflicted_File,
              "dirty close review handoff preserves Buffer List conflict classification");
      Assert (Metadata.Close_Eligibility =
                Editor.Buffers.Buffer_Blocked_By_Pending_Confirmation,
              "failed save-and-close keeps close eligibility blocked by the conflict confirmation");
      Assert (S.File_Conflict_Close_After_Overwrite,
              "save-and-close conflict records an explicit close-after-overwrite handoff only after user confirmation");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Conflict_Prompt_Active,
              "overwrite confirmation after save-and-close clears conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Target),
              "overwrite confirmation resumes and completes the pending buffer close");
      Assert (Ada.Strings.Fixed.Index (Read_File (Source_Path),
                                      "Dogfood_Known_Token") > 0,
              "save-and-close overwrite writes editor text before closing");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Conflict_Dogfood_Scenario;


   procedure Test_Project_Switch_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A             : constant String := Ada.Directories.Current_Directory &
        "/switch_project_a";
      Root_B             : constant String := Ada.Directories.Current_Directory &
        "/switch_project_b";
      Source_A           : constant String := Root_A & "/src/dogfood_demo.adb";
      Session_A          : constant String :=
        Editor.Workspace_Persistence.Session_File_Path (Root_A);
      S                  : Editor.State.State_Type;
      Cmd                : Editor.Commands.Command;
      Search_Result      : Editor.Project_Search.Project_Search_Result;
      Extracted          : Editor.Outline_Extractor.Extraction_Result;
      Build_Refresh      : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Found              : Boolean := False;
      Buffer             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Project_A_Root     : Unbounded_String := Null_Unbounded_String;
      Project_A_Row_Count : Natural := 0;
      Project_A_Diagnostic_Remains : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root_A);
      Remove_Tree_If_Exists (Root_B);
      Remove_File_If_Exists (Session_A);
      Build_Dogfood_Fixture (Root_A);
      Build_Dogfood_Fixture (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
      Assert (Editor.Project.Has_Project (S.Project),
              "switch setup opens Project A");
      Project_A_Root := To_Unbounded_String (Editor.Project.Root_Path (S.Project));
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "Project A is promoted to Recent Projects after successful open");
      Assert (not Ada.Directories.Exists (Session_A),
              "project open setup does not fabricate a workspace session file");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Assert (S.File_Info.Dirty,
              "Project A source buffer is dirty before switch");
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Buffer := Editor.Buffers.Global_Active_Buffer;
      Assert (Buffer /= Editor.Buffers.No_Buffer,
              "dirty Project A buffer is present in the registry");

      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "dogfood_demo");
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      Assert (Editor.Quick_Open.Build_Snapshot (S.Quick_Open).Visible_Count > 0,
              "Project A Quick Open state is populated before switch");

      Editor.Project_Search.Set_Query (S.Project_Search, "Dogfood_Known_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project,
         (Case_Sensitive => True,
          Max_File_Count => 100,
          Max_Result_Count => 20,
          Max_Matches_Per_File => 5,
          Max_Line_Length => Editor.Project_Search.Max_Search_Result_Preview_Length,
          Max_File_Size_Bytes => 64 * 1024,
          Regex_Max_Steps => 100_000));
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "Project A Search state is populated before switch");
      Search_Result := Editor.Project_Search.Result_At (S.Project_Search, 1);
      Assert (To_String (Search_Result.Relative_Path) = "src/dogfood_demo.adb",
              "Project A Search result points into Project A");

      Extracted := Editor.Outline_Extractor.Extract
        (Editor.Outline_Extractor.Make_Snapshot
           (Editor.State.Current_Text (S),
            "dogfood_demo.adb",
            S.Active_Buffer_Token,
            S.Buffer_Revision,
            S.Lifecycle_Generation,
            578));
      Editor.Outline.Begin_Extraction
        (S.Outline, Editor.Outline_Extractor.Identity (Extracted));
      Editor.Outline_Extractor.Apply_To_Outline (Extracted, S.Outline);
      Assert (Editor.Outline.Has_Items (S.Outline),
              "Project A Outline state is populated before switch");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "Project A diagnostic",
         "src/dogfood_demo.adb",
         Editor.Feature_Diagnostics.Project_Diagnostic_Source,
         Has_Target => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line => 1,
         Target_Column => 1,
         Build_Produced => True);
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "Project A Diagnostics state is populated before switch");

      Editor.Build_UI.Show (S.Build_UI);
      Context := Editor.Build_Working_Context.Current_Project_Root (Root_A);
      Build_Refresh := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S.Build_UI, Context);
      Assert (Build_Refresh.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "Project A Build candidates are populated before switch");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) > 0,
              "Project A Build UI has candidate rows before switch");
      Project_A_Row_Count := Editor.File_Tree.Visible_Row_Count (S.File_Tree);
      Assert (Project_A_Row_Count > 0,
              "Project A File Tree is populated before switch");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Project.Root_Path (S.Project) = To_String (Project_A_Root),
              "dirty switch attempt preserves Project A");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty switch attempt captures pending transition");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "dirty blocked switch does not promote Project B to Recent Projects");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Project_A_Row_Count,
              "dirty blocked switch preserves Project A File Tree");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "dirty blocked switch preserves Project A Search state");
      Assert (Editor.Outline.Has_Items (S.Outline),
              "dirty blocked switch preserves Project A Outline state");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "dirty blocked switch preserves Project A Diagnostics state");
      Assert (Editor.Build_UI.Candidate_Count (S.Build_UI) > 0,
              "dirty blocked switch preserves Project A Build state");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Editor.Project.Root_Path (S.Project) = To_String (Project_A_Root),
              "cancelled switch leaves Project A active");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancelled switch clears only pending transition state");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "cancelled switch still does not promote Project B");
      Buffer := Editor.Buffers.Global_Find_By_Path (Source_A, Found);
      Assert (Found and then Editor.Buffers.Global_Summary_For (Buffer).Is_Dirty,
              "cancelled switch preserves dirty Project A buffer");
      Assert (not Ada.Directories.Exists (Session_A),
              "cancelled switch does not auto-save Project A workspace");

      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "second dirty switch attempt captures pending transition");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Discard_Pending_Transition);

      Assert (Editor.Project.Has_Project (S.Project),
              "confirmed switch leaves an active project");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_B),
              "confirmed switch activates Project B");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "confirmed switch clears pending transition state");
      Buffer := Editor.Buffers.Global_Find_By_Path (Source_A, Found);
      Assert (not Found,
              "confirmed switch closes discarded Project A dirty buffer");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0,
              "confirmed switch clears Project A Search results");
      Assert (not Editor.Outline.Has_Items (S.Outline),
              "confirmed switch clears Project A Outline state");
      Project_A_Diagnostic_Remains := False;
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, I) =
           "Project A diagnostic"
         then
            Project_A_Diagnostic_Remains := True;
         end if;
      end loop;
      Assert (not Project_A_Diagnostic_Remains,
              "confirmed switch clears Project A Diagnostics rows");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) > 0,
              "confirmed switch installs Project B File Tree");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/dogfood_demo.adb"),
              "confirmed switch installs Project B known-file index");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 2,
              "confirmed switch promotes Project B to Recent Projects after success");
      Assert (not Ada.Directories.Exists (Session_A),
              "confirmed switch does not auto-save Project A workspace");

      Remove_Tree_If_Exists (Root_A);
      Remove_Tree_If_Exists (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root_A);
         Remove_Tree_If_Exists (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Switch_Dogfood_Scenario;


   procedure Test_Integrated_Workflow_Polish_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Workspace_Text : constant String :=
        "editor-workspace-version=1" & ASCII.LF &
        "project-root=/tmp/dogfood" & ASCII.LF &
        "[open-files]" & ASCII.LF &
        "src/main.adb|relative=true|row=4|column=7|view=1" & ASCII.LF &
        "[active-file]" & ASCII.LF &
        "src/main.adb|relative=true" & ASCII.LF;
      Recent_Text : constant String :=
        "project=/tmp/dogfood" & ASCII.LF;
      Keybindings_Text : constant String :=
        "project.open=Ctrl+Alt+O" & ASCII.LF &
        "quick-open=Ctrl+P" & ASCII.LF &
        "project-search=Ctrl+Shift+F" & ASCII.LF &
        "build-run=none" & ASCII.LF;
      Product_Text : constant String :=
        "startup=no-project" & ASCII.LF &
        "empty-state=real" & ASCII.LF &
        "commands=product" & ASCII.LF;
      S : Editor.State.State_Type;
   begin
      Assert (Editor.Commands.Normalize_Workflow_Message ("No project open.") =
              "No project open.",
              "real command/message normalizer canonicalizes no-project text");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File Tree unavailable: no project open.") =
              "No project open.",
              "File Tree startup no-project wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Quick Open unavailable: no project open.") =
              "No project open.",
              "Quick Open startup no-project wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Project Search unavailable: no project open.") =
              "No project open.",
              "Project Search startup no-project wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build unavailable: no project open or no build request ready.") =
              "No project open.",
              "Build startup no-project wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Search result is stale; run Project Search again.") =
              Editor.Commands.Reason_Target_Stale,
              "real command/message normalizer canonicalizes stale target text");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No project open for build candidates") =
              "No project open.",
              "build candidate no-project wording uses the shared workflow label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Outline unavailable: no active buffer.") =
              "No active buffer.",
              "Outline no-active-buffer wording uses the shared active-buffer label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Search Results: no active buffer") =
              "No active buffer.",
              "Search Results no-active-buffer wording uses the shared active-buffer label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: selected build candidate is stale") =
              Editor.Commands.Reason_Target_Stale,
              "Build stale-candidate wording uses the shared stale-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No open buffers") =
              "No buffers open.",
              "Buffer List empty wording uses the shared open-buffer label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No matching open buffers") =
              "No matching open buffers.",
              "Buffer List filtered empty wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Only one buffer open") =
              "No other buffer.",
              "single-buffer navigation wording uses the shared other-buffer label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No previous buffer") =
              "No previous buffer.",
              "previous-buffer unavailable wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No next buffer") =
              "No next buffer.",
              "next-buffer unavailable wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Selected row is not a buffer") =
              "Selected row is not a buffer.",
              "non-buffer row activation wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No matching buffers") =
              "No matching open buffers.",
              "Buffer List filtered matcher wording uses the shared open-buffer label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No marked buffers") =
              "No marked buffers.",
              "Buffer List marked-buffer empty wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No pending marked targets") =
              "No pending close targets.",
              "Buffer List pending marked-close wording uses the shared close-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No dirty-prune preview targets") =
              "No dirty-prune preview targets.",
              "Buffer List dirty-prune preview empty wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No removed dirty-prune apply targets") =
              "No removed dirty-prune apply targets.",
              "Buffer List removed dirty-prune apply wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No selection") =
              "No selected text",
              "selection/clipboard no-selection wording uses the shared selected-text label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No clipboard to clear") =
              "Clipboard is empty",
              "clipboard clear empty-state wording uses the shared clipboard-empty label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Invalid selection.") =
              "Invalid selection",
              "clipboard invalid-selection wording avoids punctuation drift");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No file tree node selected.") =
              "No file selected.",
              "File Tree missing-selection wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No result selected.") =
              "No file selected.",
              "Search/replace generic missing-selection wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Search Results: no selected result") =
              "No file selected.",
              "Search Results panel missing-selection wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No Quick Open result selected.") =
              "No file selected.",
              "Quick Open missing-result wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No item selected.") =
              "No file selected.",
              "generic panel item selection wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No replacement selected") =
              "No file selected.",
              "replacement preview missing-selection wording uses the shared file-selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Search Results: no query") =
              "No search query.",
              "Search Results no-query wording uses the shared search-query label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No matches found.") =
              "No search results.",
              "Project Search no-match wording uses the shared search-results label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Project Search shown") =
              "Project Search shown.",
              "Project Search show wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Project Search hidden") =
              "Project Search hidden.",
              "Project Search hide wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Invalid Project Search include filter") =
              "Invalid Project Search filter.",
              "Project Search invalid filter wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No Project Search scope to clear") =
              "No Project Search filter to clear.",
              "Project Search empty filter-clear wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No replacement preview") =
              "No replacement preview.",
              "Replace preview empty-state wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement target changed; rerun search") =
              Editor.Commands.Reason_Target_Stale,
              "Replace preview changed-target wording uses the shared stale-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement target is unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Replace preview unavailable-target wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement target is read-only") =
              "File is not writable.",
              "Replace preview read-only wording uses the shared writable-file label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement target is not a regular file") =
              "Target is not a file.",
              "Replace preview non-file target wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement target path is invalid") =
              "Invalid file path.",
              "Replace preview invalid-path wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Replacement text must be single-line") =
              "Replacement text must be single-line.",
              "Replace preview replacement-text validation is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Could not open file for replacement") =
              "Could not open file.",
              "Replace preview open failure uses one file-open failure label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build request is not ready for consent") =
              "No build request ready.",
              "Build request readiness wording matches policy");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: no build candidate selected") =
              "No build candidate selected.",
              "Build missing-candidate wording uses the shared Build selection label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: review the request and acknowledge consent first") =
              "Build consent required.",
              "Build consent wording uses the shared consent-required label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build unavailable: consent required.") =
              "Build consent required.",
              "Build result/output consent-required wording uses the shared consent label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Consent missing: review and acknowledge the build request") =
              "Build consent required.",
              "Build UI consent-missing detail uses the shared consent-required label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build candidate applied to transient request; Consent missing: review and acknowledge the build request") =
              "Build consent required.",
              "Build candidate application consent detail uses the shared consent-required label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No build candidates found.") =
              "No build candidates.",
              "Build candidate discovery empty-state wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: choose a build tool first") =
              "No build tool selected.",
              "Build tool selection wording uses the shared actionable label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: custom shell commands are not supported") =
              "No build request ready.",
              "Build unsupported command-shape wording uses the shared request label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: arguments must be structured tokens, not shell text") =
              "No build request ready.",
              "Build structured-argument wording uses the shared request label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("candidate request could not be formed") =
              "No build request ready.",
              "Build candidate request-shape wording uses the shared request label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("candidate request is not structured argv") =
              "No build request ready.",
              "Build candidate argv wording uses the shared request label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: no project working context selected") =
              "No project open.",
              "Build missing working-context wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build working directory is required.") =
              "No project open.",
              "Build missing working-directory wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No canonical project/workspace context") =
              "No project open.",
              "Build missing canonical working-context wording uses the shared project label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Project root unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Project-root unavailable wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("candidate path missing or unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Build candidate missing-path wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("candidate path outside project root") =
              "Target is outside the current project.",
              "Build candidate boundary wording uses the shared project-boundary label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("candidate must be refreshed") =
              Editor.Commands.Reason_Target_Stale,
              "Build candidate refresh wording uses the shared stale-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build working directory is unavailable.") =
              Editor.Commands.Reason_Target_Missing,
              "Build unavailable working-directory wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: selected project working context is unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Build unavailable working-context wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: working context must come from the current project/workspace") =
              "Target is outside the current project.",
              "Build outside working-context wording uses the shared boundary label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build working context canonical path required") =
              "Target is outside the current project.",
              "Build invalid canonical working-context wording uses the shared boundary label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build run unavailable: execution backend is disabled") =
              "Build execution is unavailable.",
              "Build disabled-backend wording uses the shared execution-unavailable label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build unavailable: execution backend disabled.") =
              "Build execution is unavailable.",
              "Build output-details disabled-backend wording uses the shared execution-unavailable label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build output unavailable") =
              "No build output captured.",
              "Build output unavailable wording uses the shared no-output label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No standard output captured") =
              "No stdout captured.",
              "Build stdout empty-state wording uses the shared stdout label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No standard error captured") =
              "No stderr captured.",
              "Build stderr empty-state wording uses the shared stderr label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Consent stale: review the changed build request") =
              "Build consent is stale.",
              "Build stale-consent wording uses the shared stale-consent label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build candidate file no longer exists") =
              Editor.Commands.Reason_Target_Missing,
              "Build missing-candidate-file wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Parent directory unavailable") =
              "Parent directory is unavailable.",
              "File lifecycle parent-directory wording uses the shared recovery label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Parent directory does not exist: src/panels/") =
              "Parent directory is unavailable.",
              "Path-specific parent-directory failures are redacted to the shared recovery label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File is not writable") =
              "File is not writable.",
              "File lifecycle unwritable wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File is not readable") =
              "File is not readable.",
              "File lifecycle unreadable wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Could not reload buffer") =
              "Could not reload file.",
              "Reload failure wording uses file lifecycle terminology consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Could not reload file; buffer unchanged") =
              "Could not reload file.",
              "Reload failure detail is normalized to one primary outcome");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Could not write file; buffer remains dirty") =
              "Could not save file.",
              "Write failure detail is normalized to the shared save failure label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Dirty buffer cannot be closed") =
              "Unsaved changes require confirmation.",
              "Dirty close guard wording uses the shared confirmation label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Cannot switch project with unsaved changes") =
              "Unsaved changes require confirmation.",
              "Project switch dirty guard wording uses the shared confirmation label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Cannot restore workspace with unsaved changes") =
              "Unsaved changes require confirmation.",
              "Workspace restore dirty guard wording uses the shared confirmation label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Save or resolve changes first") =
              "Unsaved changes require confirmation.",
              "Close-all dirty guard wording uses the shared confirmation label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Dirty buffer file cannot be renamed") =
              "Dirty buffer preserved.",
              "File Tree rename dirty-buffer guard reports preserved dirty text");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Delete blocked by unsaved changes") =
              "Dirty buffer preserved.",
              "File Tree delete dirty-buffer guard reports preserved dirty text");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Close canceled") =
              "Close cancelled.",
              "Dirty close cancel spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Save failed; buffer remains open and dirty") =
              "Save failed; buffer remains open.",
              "Save-and-close failure wording uses one shared primary outcome");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Save As required before saving this buffer") =
              "Buffer has no file path.",
              "Unbacked buffer save wording uses the shared backing-file label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File changed on disk; choose how to proceed.") =
              "File conflict requires resolution.",
              "external-change save prompt uses the shared file-conflict label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File conflict detected; choose how to proceed.") =
              "File conflict requires resolution.",
              "generic file-conflict prompt wording uses the shared conflict label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Reload will discard unsaved changes. Disk version has changed since file was opened.") =
              "Reload will discard unsaved changes.",
              "reload conflict detail is normalized to one primary discard warning");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Kept buffer changes; file remains conflicted") =
              "Kept buffer changes; file remains conflicted.",
              "keep-buffer conflict action is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("File conflict canceled") =
              "File conflict cancelled.",
              "file-conflict cancel spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Diagnostic target file is unavailable.") =
              Editor.Commands.Reason_Target_Missing,
              "Diagnostics missing-file wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Target file missing or unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Diagnostics source-labelled missing target wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Selected diagnostic has no source target") =
              "Selected diagnostic has no source target.",
              "source-less diagnostics navigation wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Outline target unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Outline target-unavailable wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Diagnostic target line is unavailable") =
              Editor.Commands.Reason_Target_Line_Unavailable,
              "Diagnostics missing-line wording uses the shared target-line label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Target path is outside the project") =
              "Target is outside the current project.",
              "outside-project target wording uses the shared boundary label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Workspace session malformed; no session restored.") =
              "No workspace restored.",
              "Workspace malformed-session wording uses the shared no-restore label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Workspace loaded with stale or unsupported structural entries ignored.") =
              "Workspace restored with missing entries skipped.",
              "Workspace partial-restore wording uses the shared skipped-entries label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Recent Projects list empty.") =
              "No recent projects.",
              "Recent Projects empty-list wording uses the shared empty label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Recent project is unavailable.") =
              Editor.Commands.Reason_Target_Missing,
              "Recent Projects unavailable-entry wording uses the shared missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Recent Projects loaded with invalid lightweight entries ignored.") =
              "Recent Projects loaded with invalid entries ignored.",
              "Recent Projects partial-load wording uses one shared warning label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Editor ready with configuration warnings.") =
              "Ready with configuration warnings.",
              "Startup warning wording does not leak product-shell phrasing into surfaces");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Settings file has an invalid format.") =
              "Settings file is invalid.",
              "Settings loader invalid-format wording uses one recovery label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Settings loaded with ignored invalid entries.") =
              "Settings loaded with invalid values reset to defaults.",
              "Settings partial-load wording uses one recovery label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Keybindings file malformed; default keybindings active.") =
              "Default keybindings active.",
              "Keybinding malformed-file wording uses the safe-default label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Keybindings loaded with ignored invalid entries.") =
              "Keybindings loaded with rejected bindings.",
              "Keybinding partial-load wording uses the rejected-bindings label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Keybinding entry is malformed.") =
              "Shortcut is invalid.",
              "Malformed keybinding entry wording uses the shortcut validation label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed.") =
              "Reset all configuration requires confirmation.",
              "Configuration reset-all prompt wording is concise and actionable");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("All configuration domains reset after explicit confirmation.") =
              "All configuration domains reset.",
              "Configuration reset-all completion wording uses one outcome label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Command Palette is closed.") =
              "Command Palette closed.",
              "Command Palette closed-state wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No commands match ""zzzz-no-command""") =
              "No matching commands.",
              "Command Palette no-match wording hides query-specific noise");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No available commands") =
              "No available commands.",
              "Command Palette available-only empty state is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No available commands match ""build""") =
              "No matching available commands.",
              "Command Palette available-only no-match wording keeps filter context");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No command selected") =
              "No command selected.",
              "Command Palette missing-selection wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Selected setting is not editable") =
              "Selected setting is not editable.",
              "Settings non-editable wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Setting value is invalid") =
              "Invalid setting value.",
              "Settings validation wording uses one invalid-value label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Command is not bindable") =
              "Selected command is not bindable.",
              "Keybinding command bindability wording is canonical");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Keybinding conflict: shortcut already assigned") =
              "Shortcut is already assigned.",
              "Keybinding conflict wording uses one shortcut-conflict label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Keybinding assignment canceled") =
              "Keybinding assignment cancelled.",
              "Keybinding assignment cancel spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No bookmarks") =
              "No bookmarks.",
              "Bookmarks empty-state wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No bookmarkable location") =
              "No bookmarkable location.",
              "Bookmarks no-location wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No bookmark in active file") =
              "No bookmark in active file.",
              "Bookmarks in-file empty-state wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Bookmark target unavailable") =
              Editor.Commands.Reason_Target_Missing,
              "Bookmarks stale target wording shares the missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No previous navigation location") =
              "No previous navigation location.",
              "Navigation back empty-history wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No navigation history to clear") =
              "No navigation history.",
              "Navigation history clear empty-state wording uses one label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Navigation target unavailable.") =
              Editor.Commands.Reason_Target_Missing,
              "Navigation stale-target wording shares the missing-target label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Another prompt is active") =
              "Another prompt is active.",
              "Prompt concurrency wording is punctuated consistently");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Prompt canceled") =
              "Prompt cancelled.",
              "Prompt cancellation spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Conflict prompt is stale") =
              "Prompt is stale.",
              "Stale prompt wording uses one prompt-stale label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No close confirmation pending") =
              "No pending confirmation.",
              "Missing confirmation wording uses one no-pending label");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Reload/revert requires its own explicit confirmation") =
              "Reload or revert requires confirmation.",
              "Reload/revert confirmation wording avoids slash-heavy UI text");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Pending transition canceled") =
              "Pending transition cancelled.",
              "Project transition cancellation spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Switch project canceled") =
              "Switch project cancelled.",
              "Project switch cancellation spelling is normalized");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Reload canceled") =
              "Reload cancelled.",
              "File reload cancellation spelling is normalized");
      Assert (Editor.Commands.Unavailable_Reason
                (Editor.Executor.Command_Availability
                   (S, Editor.Commands.Command_Open_Quick_Open)) =
              "No project open.",
              "Executor availability exposes canonical no-project wording");
      Assert (Editor.Dogfood_Workflow.Integrated_Workflow_Message
                (Editor.Dogfood_Workflow.Workflow_No_Project_Open) =
              "No project open.",
              "canonical no-project wording is exact");
      Assert (Editor.Dogfood_Workflow.Integrated_Workflow_Message
                (Editor.Dogfood_Workflow.Workflow_Target_Stale) =
              Editor.Commands.Reason_Target_Stale,
              "stale target wording is shared across surfaces");
      Assert (Editor.Dogfood_Workflow.Integrated_Workflow_Message
                (Editor.Dogfood_Workflow.Workflow_Confirmation_Pending) =
              "Command unavailable while confirmation is pending.",
              "pending-confirmation wording is shared");
      Assert (Editor.Dogfood_Workflow.Integrated_Focus_After_Action
                (Editor.Dogfood_Workflow.Workflow_Quick_Open_File_Activated) =
              Editor.Dogfood_Workflow.Focus_Result_Editor,
              "Quick Open activation returns focus to the editor");
      Assert (Editor.Dogfood_Workflow.Integrated_Focus_After_Action
                (Editor.Dogfood_Workflow.Workflow_Diagnostic_Target_Activated) =
              Editor.Dogfood_Workflow.Focus_Result_Editor,
              "Diagnostic navigation returns focus to the editor");
      Assert (Editor.Dogfood_Workflow.Integrated_Surface_Disposition_After
                (Editor.Dogfood_Workflow.Workflow_Event_File_Renamed,
                 Editor.Dogfood_Workflow.Dogfood_Surface_Quick_Open) =
              Editor.Dogfood_Workflow.Workflow_Surface_Refresh_Required,
              "file rename makes Quick Open refresh explicit");
      Assert (Editor.Dogfood_Workflow.Integrated_Surface_Disposition_After
                (Editor.Dogfood_Workflow.Workflow_Event_Project_Switched,
                 Editor.Dogfood_Workflow.Dogfood_Surface_Diagnostics) =
              Editor.Dogfood_Workflow.Workflow_Surface_Cleared,
              "project switch clears old Diagnostics projection");
      Assert (Editor.Dogfood_Workflow.Assert_Message_Consistency,
              "message consistency policy is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Focus_Policy_Coherent,
              "focus-return policy is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Surface_Dispositions_Coherent,
              "cross-surface disposition policy is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Workflow_Polish_Coherent
                (Workspace_Text, Recent_Text, Keybindings_Text, Product_Text),
              "integrated workflow polish preserves persistence and routing boundaries");
   end Test_Integrated_Workflow_Polish_Coherent;


   procedure Test_Product_Workflow_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Product_Text : constant String :=
        "project.open" & ASCII.LF &
        "project.close" & ASCII.LF &
        "project.switch" & ASCII.LF &
        "project.reopen-recent" & ASCII.LF &
        "file.open" & ASCII.LF &
        "file.save" & ASCII.LF &
        "file.save-as" & ASCII.LF &
        "file.reload-buffer" & ASCII.LF &
        "file.revert-buffer" & ASCII.LF &
        "file-tree.refresh" & ASCII.LF &
        "file-tree.create-file" & ASCII.LF &
        "file-tree.create-directory" & ASCII.LF &
        "file-tree.rename-selected" & ASCII.LF &
        "file-tree.delete-selected" & ASCII.LF &
        "quick-open.show" & ASCII.LF &
        "quick-open.open-selected" & ASCII.LF &
        "project.search.run" & ASCII.LF &
        "project.search.open-selected" & ASCII.LF &
        "outline.show" & ASCII.LF &
        "build.run" & ASCII.LF &
        "build.ui.show" & ASCII.LF &
        "build.ui.toggle" & ASCII.LF &
        "build.ui.hide" & ASCII.LF &
        "build.ui.focus" & ASCII.LF &
        "diagnostics.show" & ASCII.LF &
        "buffer.switch-next" & ASCII.LF &
        "buffer.switch-previous" & ASCII.LF &
        "file.close-buffer" & ASCII.LF &
        "file.close-clean-buffers" & ASCII.LF &
        "workspace.restore" & ASCII.LF;
   begin
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Command
                (Editor.Dogfood_Workflow.Product_Open_Project) =
              "project.open",
              "product workflow uses canonical project.open command id");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Label
                (Editor.Dogfood_Workflow.Product_Run_Build) =
              "Run Build",
              "product workflow exposes product-facing build label");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Message
                (Editor.Dogfood_Workflow.Product_Save_Buffer) =
              "File saved.",
              "product workflow uses canonical save success message");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Failure_Message
                (Editor.Dogfood_Workflow.Product_Close_Project) =
              "Cannot close project while dirty buffers need review.",
              "product workflow keeps dirty close wording user-facing");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Failure_Message
                (Editor.Dogfood_Workflow.Product_Switch_Project) =
              "Project switch cancelled.",
              "product workflow uses explicit switch cancellation wording");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_Open_File_From_Quick_Open) =
              Editor.Dogfood_Workflow.Focus_Result_Editor,
              "Quick Open activation focuses editor");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_Inspect_Diagnostics) =
              Editor.Dogfood_Workflow.Focus_Result_Diagnostics,
              "Diagnostics command focuses Diagnostics panel");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Message
                (Editor.Dogfood_Workflow.Product_Inspect_Diagnostics) =
              "Diagnostics shown.",
              "Diagnostics inspection uses panel-visible success wording");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_Search_Project) =
              Editor.Dogfood_Workflow.Focus_Result_Search_Results,
              "project search focuses the search results surface");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_View_Outline) =
              Editor.Dogfood_Workflow.Focus_Result_Outline,
              "outline command focuses the Outline surface");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_Inspect_Build_Output) =
              Editor.Dogfood_Workflow.Focus_Result_Build_Output,
              "build output inspection focuses Build Output");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Focus_Result
                (Editor.Dogfood_Workflow.Product_Close_Project) =
              Editor.Dogfood_Workflow.Focus_Result_Empty_State,
              "project close lands in an empty project state");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Dirty_Buffer_Behavior
                (Editor.Dogfood_Workflow.Product_Quit_Safely) =
              "blocks until dirty buffers are saved, discarded, or cancellation preserves them",
              "quit policy preserves dirty buffers on cancellation");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Workflow_Reference_Coherent,
              "product workflow reference is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Messages_User_Readable,
              "product workflow messages avoid internal terms");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Focus_Policy_Coherent,
              "product workflow focus policy is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Prompt_Policy_Coherent,
              "product prompt policy is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_File_Buffer_Coherent,
              "File Tree and buffer workflow is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Navigation_Coherent,
              "navigation workflow is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Build_Diagnostics_Coherent,
              "build and diagnostics workflow is coherent");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Workspace_Restore_Coherent,
              "workspace restore workflow is coherent");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Prompt_Title
                (Editor.Dogfood_Workflow.Product_Delete_File_Or_Directory) =
              "Delete File or Directory",
              "delete workflow has a product prompt title");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Prompt_Title
                (Editor.Dogfood_Workflow.Product_Rename_File_Or_Directory) =
              "Rename File or Directory",
              "rename workflow uses the same prompt title as the real prompt surface");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Message
                (Editor.Dogfood_Workflow.Product_Rename_File_Or_Directory) =
              "File or directory renamed.",
              "rename workflow does not use generic item wording");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Message
                (Editor.Dogfood_Workflow.Product_Delete_File_Or_Directory) =
              "File or directory deleted.",
              "delete workflow does not use generic item wording");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Failure_Message
                (Editor.Dogfood_Workflow.Product_Rename_File_Or_Directory) =
              "File or directory could not be renamed.",
              "rename failure workflow does not use generic item wording");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Message
                (Editor.Dogfood_Workflow.Product_Inspect_Build_Output) =
              "Build Output shown.",
              "build-output inspection uses the product surface status");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Failure_Message
                (Editor.Dogfood_Workflow.Product_Inspect_Build_Output) =
              "No build output captured.",
              "build-output empty state uses the canonical useful empty message");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Cancel_Status
                (Editor.Dogfood_Workflow.Product_Reload_Buffer) =
              "Dirty buffer preserved.",
              "reload cancellation preserves dirty text");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Cancel_Status
                (Editor.Dogfood_Workflow.Product_Create_File) =
              "Create file cancelled.",
              "create-file cancellation is specific to the workflow");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Cancel_Status
                (Editor.Dogfood_Workflow.Product_Create_Directory) =
              "Create directory cancelled.",
              "create-directory cancellation is specific to the workflow");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Cancel_Status
                (Editor.Dogfood_Workflow.Product_Rename_File_Or_Directory) =
              "Rename cancelled.",
              "rename cancellation is specific to the workflow");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_File_Buffer_Effect
                (Editor.Dogfood_Workflow.Product_Rename_File_Or_Directory) =
              "updates backing path for an open renamed file",
              "rename workflow updates open buffer backing path");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Panel_Effect
                (Editor.Dogfood_Workflow.Product_Run_Build) =
              "updates build output and diagnostics from the same build result",
              "build workflow keeps output and diagnostics coherent");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Persistence_Effect
                (Editor.Dogfood_Workflow.Product_Restore_Workspace) =
              "restores only valid project, buffers, selection, and focus",
              "workspace restore only restores valid session state");
      Assert (Editor.Dogfood_Workflow.Assert_Product_Surface_Coherent
                (Product_Text),
              "product workflow surface has expected core commands");
      Assert (Editor.Commands.Normalize_Workflow_Message ("File renamed") =
              "File renamed.",
              "normalizes file rename status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Directory renamed") =
              "Directory renamed.",
              "normalizes directory rename status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("File deleted") =
              "File deleted.",
              "normalizes file delete status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Directory deleted") =
              "Directory deleted.",
              "normalizes directory delete status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Create file cancelled") =
              "Create file cancelled.",
              "normalizes create-file cancellation status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Create directory cancelled") =
              "Create directory cancelled.",
              "normalizes create-directory cancellation status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Rename cancelled") =
              "Rename cancelled.",
              "normalizes rename cancellation status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Delete cancelled") =
              "Delete cancelled.",
              "normalizes delete cancellation status punctuation");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Build UI shown") =
              "Build Output shown.",
              "normalizes removed Build UI show status wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Item could not be renamed") =
              "File or directory could not be renamed.",
              "normalizes generic rename failure wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("No build output") =
              "No build output captured.",
              "normalizes build-output empty status to useful product wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Diagnostics shown") =
              "Diagnostics shown.",
              "normalizes diagnostics panel show status punctuation");
      Assert (Editor.Feature_Diagnostics.Message_Diagnostics_Shown =
              "Diagnostics shown.",
              "diagnostics panel show message is product-facing");
      Assert (Editor.Feature_Diagnostics.Message_Diagnostics_Cleared =
              "Diagnostics cleared.",
              "diagnostics clear message is product-facing");
      Assert (Editor.Commands.Normalize_Workflow_Message ("No diagnostics produced") =
              "No diagnostics.",
              "normalizes build-produced empty diagnostics wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Backing file no longer exists") =
              "Backing file missing.",
              "normalizes backing-file loss to the product vocabulary");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Rename blocked by unsaved changes") =
              "Dirty buffer preserved.",
              "normalizes dirty File Tree rename blockers to preserved data wording");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Delete blocked by unsaved changes") =
              "Dirty buffer preserved.",
              "normalizes dirty File Tree delete blockers to preserved data wording");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Build panel is closed; open Build before running build.run") =
              "Build Output is closed; open Build Output before running build.run.",
              "normalizes removed build-surface availability wording");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Workspace state restored") =
              "Workspace restored.",
              "normalizes workspace restore success to product wording");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("Workspace state partially restored") =
              "Workspace restored with missing entries skipped.",
              "normalizes partial workspace restore to product wording");
   end Test_Product_Workflow_Surface_Coherent;

   procedure Test_Product_Focus_And_Cancel_Behavior
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Root;
      Source_Path : constant String := Root & "/src/dogfood_demo.adb";
      Cancel_Path : constant String := Root & "/src/cancelled_from_prompt.adb";
      S           : Editor.State.State_Type;
      Before_Text : Unbounded_String;
      Workspace_Command_Result : Editor.Command_Execution.Command_Execution_Result;
   begin
      Assert (Editor.Focus_Management.Command_Returns_Focus_To_Editor
                (Editor.Commands.Command_Open_File),
              "explicit file-open command returns focus to the editor buffer");
      Assert (Editor.Focus_Management.Command_Returns_Focus_To_Editor
                (Editor.Commands.Command_File_Tree_Open_Selected),
              "File Tree activation returns focus to the editor buffer");
      Assert (Editor.Focus_Management.Command_Returns_Focus_To_Editor
                (Editor.Commands.Command_Search_Results_Open_Selected),
              "search-result activation returns focus to the editor buffer");
      Assert (Editor.Focus_Management.Command_Returns_Focus_To_Editor
                (Editor.Commands.Command_Open_Selected_Outline_Item),
              "outline activation returns focus to the editor buffer");
      Assert (Editor.Focus_Management.Focus_Target_For_Surface_Command
                (Editor.Commands.Command_Show_Outline) =
              Editor.Focus_Management.Focus_Outline,
              "Show Outline has a deterministic focus target");
      Assert (Editor.Focus_Management.Focus_Target_For_Surface_Command
                (Editor.Commands.Command_Diagnostics_Show) =
              Editor.Focus_Management.Focus_Diagnostics,
              "Show Diagnostics has a deterministic focus target");
      Assert (Editor.Focus_Management.Focus_Target_For_Surface_Command
                (Editor.Commands.Command_Build_UI_Show) =
              Editor.Focus_Management.Focus_Build_UI,
              "Build Output entry uses the build surface focus target");
      Assert (Editor.Focus_Management.Focus_Owner_Label
                (Editor.Focus_Management.Focus_Build_UI) = "Build Output",
              "build focus label is product-facing Build Output");
      Assert (Editor.Focus_Management.Active_Panel_Label
                (Editor.Focus_Management.Focus_Build_UI) = "Build Output",
              "active panel label is product-facing Build Output");

      Editor.State.Init (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Show);
      Assert (Active_Message_Text (S) = "Build Output shown.",
              "build output show status is product-facing");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Focus);
      Assert (Active_Message_Text (S) = "Build Output focused.",
              "build output focus status is product-facing");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Hide);
      Assert (Active_Message_Text (S) = "Build Output hidden.",
              "build output hide status is product-facing");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Show);
      Assert (Active_Message_Text (S) = "No diagnostics.",
              "diagnostics show reports the useful empty diagnostics state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Show_Outline);
      Assert (Active_Message_Text (S) = "Outline shown.",
              "Outline show status is punctuated and product-facing");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_Outline);
      Assert (Active_Message_Text (S) = "Outline focused.",
              "Outline focus status is punctuated and product-facing");
      Assert (Editor.Commands.Normalize_Workflow_Message
                ("No outline items item selected.") =
              "No file selected.",
              "normalizes old duplicated Outline selection wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Outline shown") =
              "Outline shown.",
              "normalizes old unpunctuated Outline show wording");
      Assert (Editor.Commands.Normalize_Workflow_Message ("Outline focused") =
              "Outline focused.",
              "normalizes old unpunctuated Outline focus wording");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Refresh_Outline).Name =
              "Refresh Outline",
              "Outline refresh label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Open_Selected_Outline_Item).Description =
              "Open the selected Outline item.",
              "Outline activation description avoids implementation metadata wording");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Select_Current_Outline_Symbol).Name =
              "Select Current Outline Symbol",
              "current-symbol Outline command label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Reveal_Current_Outline_Symbol).Name =
              "Reveal Current Outline Symbol",
              "reveal-current Outline command label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Next_Outline_Symbol).Name =
              "Next Outline Symbol",
              "next-symbol Outline command label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Previous_Outline_Symbol).Name =
              "Previous Outline Symbol",
              "previous-symbol Outline command label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Focus_Outline_Filter).Name =
              "Focus Outline Filter",
              "Outline filter focus label is product-facing");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Clear_Outline_Filter).Name =
              "Clear Outline Filter",
              "Outline filter clear label is product-facing");

      Build_Dogfood_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));

      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_File_Tree_Create_File);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "create-file prompt starts through the product command path");
      Editor.Guided_Prompts.Update_Input
        (S.Guided_Prompt, "src/cancelled_from_prompt.adb");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id (Editor.Commands.Command_Cancel);
      S := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "prompt cancellation clears transient prompt state");
      Assert (Active_Message_Text (S) = "Create file cancelled.",
              "create-file cancellation reports product wording");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "File Tree prompt cancellation restores File Tree focus");
      Assert (not Ada.Directories.Exists (Cancel_Path),
              "prompt cancellation does not create a filesystem target");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "prompt cancellation preserves active buffer text");
      Assert (not S.File_Info.Dirty,
              "prompt cancellation does not dirty the active buffer");

      Write_File
        (Editor.Workspace_Persistence.Session_File_Path (Root),
         "not a workspace snapshot" & ASCII.LF);
      Workspace_Command_Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Workspace_Command_Result.Status =
                Editor.Command_Execution.Command_Failed,
              "invalid workspace restore fails through the product command path");
      Assert (Active_Message_Text (S) = "Workspace could not be restored.",
              "invalid workspace restore reports product wording");
      Assert (Editor.Project.Has_Project (S.Project)
                and then Editor.Project.Root_Path (S.Project) = Root,
              "invalid workspace restore preserves the active project");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Source_Path,
              "invalid workspace restore preserves the active file");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "invalid workspace restore preserves active buffer text");
      Remove_Tree_If_Exists (Root);
   end Test_Product_Focus_And_Cancel_Behavior;



   procedure Test_File_Tree_Clean_Open_Buffer_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Root;
      Source_Path  : constant String := Root & "/src/clean_open.adb";
      Renamed_Path : constant String := Root & "/src/clean_open_renamed.adb";
      S            : Editor.State.State_Type;
      Found        : Boolean := False;
      Node         : Editor.File_Tree.File_Tree_Node_Id;
      Row          : Natural := 0;
   begin
      Build_Dogfood_Fixture (Root);
      Write_File
        (Source_Path,
         "package Clean_Open is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Clean_Open;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);

      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Source_Path,
              "clean-open setup opens the selected File Tree target");
      Assert (not S.File_Info.Dirty,
              "clean-open setup starts from a clean buffer");
      Assert (Editor.Buffers.Global_Count = 1,
              "clean-open setup has one open buffer");

      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/clean_open.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "clean-open source is present in the File Tree");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "clean-open source maps to a selectable File Tree row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);

      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "clean_open_renamed.adb",
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         "rename clean open file");

      Assert (not Ada.Directories.Exists (Source_Path)
                and then Ada.Directories.Exists (Renamed_Path),
              "clean open File Tree rename moves the backing file");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Renamed_Path,
              "clean open File Tree rename updates the active buffer path");
      Assert (not S.File_Info.Dirty,
              "clean open File Tree rename preserves clean state");
      Assert (Ada.Strings.Fixed.Index
                (Editor.State.Current_Text (S), "Clean_Open") > 0,
              "clean open File Tree rename preserves buffer text");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "clean open File Tree rename focuses the renamed buffer");

      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/clean_open_renamed.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "renamed clean-open file is present in the File Tree");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "renamed clean-open file maps to a selectable row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Run_File_Tree_Delete_Confirmation (S);

      Assert (not Ada.Directories.Exists (Renamed_Path),
              "clean open File Tree delete removes the backing file");
      Assert (Editor.Buffers.Global_Count = 0,
              "clean open File Tree delete closes the clean buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
              "clean open File Tree delete leaves no stale active buffer id");
      Assert (not S.File_Info.Has_Path,
              "clean open File Tree delete clears the active file path");
      Assert (Editor.State.Current_Text (S)'Length = 0,
              "clean open File Tree delete leaves an empty editor buffer");
      Assert (not S.File_Info.Dirty,
              "clean open File Tree delete leaves no dirty phantom buffer");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "clean open File Tree delete keeps File Tree focus");
      Assert (Active_Message_Text (S) = "File deleted.",
              "clean open File Tree delete reports product success");

      Remove_Tree_If_Exists (Root);
   end Test_File_Tree_Clean_Open_Buffer_Lifecycle;


   procedure Test_File_Tree_Delete_Active_Buffer_Selects_Next_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Root;
      First_Path   : constant String := Root & "/src/delete_keep_first.adb";
      Second_Path  : constant String := Root & "/src/delete_active_second.adb";
      S            : Editor.State.State_Type;
      Found        : Boolean := False;
      Node         : Editor.File_Tree.File_Tree_Node_Id;
      Row          : Natural := 0;
   begin
      Build_Dogfood_Fixture (Root);
      Write_File
        (First_Path,
         "package Delete_Keep_First is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Delete_Keep_First;" & ASCII.LF);
      Write_File
        (Second_Path,
         "package Delete_Active_Second is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Delete_Active_Second;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, First_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Second_Path);

      Assert (Editor.Buffers.Global_Count = 2,
              "multi-buffer delete setup has two clean file buffers");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Second_Path,
              "multi-buffer delete setup makes the second file active");
      Assert (not S.File_Info.Dirty,
              "multi-buffer delete setup active file is clean");

      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/delete_active_second.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "active clean delete target is present in the File Tree");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "active clean delete target maps to a File Tree row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);

      Run_File_Tree_Delete_Confirmation (S);

      Assert (not Ada.Directories.Exists (Second_Path),
              "active clean File Tree delete removes the active backing file");
      Assert (Ada.Directories.Exists (First_Path),
              "active clean File Tree delete preserves the remaining backing file");
      Assert (Editor.Buffers.Global_Count = 1,
              "active clean File Tree delete closes only the deleted buffer");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = First_Path,
              "active clean File Tree delete switches to the remaining buffer");
      Assert (Ada.Strings.Fixed.Index
                (Editor.State.Current_Text (S), "Delete_Keep_First") > 0,
              "active clean File Tree delete loads the remaining buffer text");
      Assert (not S.File_Info.Dirty,
              "active clean File Tree delete keeps the replacement buffer clean");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "active clean File Tree delete focuses the replacement editor buffer");
      Assert (Active_Message_Text (S) = "File deleted.",
              "active clean File Tree delete reports product success");

      Remove_Tree_If_Exists (Root);
   end Test_File_Tree_Delete_Active_Buffer_Selects_Next_Buffer;


   procedure Test_File_Tree_Rename_Directory_Rebases_Active_Child_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root            : constant String := Temp_Root;
      Old_Dir         : constant String := Root & "/src/rename_dir_active";
      New_Dir         : constant String := Root & "/src/rename_dir_done";
      Old_Child_Path  : constant String := Old_Dir & "/open_child.adb";
      New_Child_Path  : constant String := New_Dir & "/open_child.adb";
      Other_Path      : constant String := Root & "/src/rename_dir_other.adb";
      S               : Editor.State.State_Type;
      Found           : Boolean := False;
      Node            : Editor.File_Tree.File_Tree_Node_Id;
      Row             : Natural := 0;
      Child_Id_Before : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Child_Id_After  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Old_Found       : Boolean := False;
      New_Found       : Boolean := False;
   begin
      Build_Dogfood_Fixture (Root);
      Ada.Directories.Create_Directory (Old_Dir);
      Write_File
        (Old_Child_Path,
         "package Open_Child is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Open_Child;" & ASCII.LF);
      Write_File
        (Other_Path,
         "package Rename_Dir_Other is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Rename_Dir_Other;" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Other_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Old_Child_Path);

      Child_Id_Before := Editor.Buffers.Global_Find_By_Path
        (Old_Child_Path, Found);
      Assert (Found and then Child_Id_Before /= Editor.Buffers.No_Buffer,
              "directory rename setup has a child buffer at the old path");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = Old_Child_Path,
              "directory rename setup makes the child buffer active");
      Assert (Editor.Buffers.Global_Count = 2,
              "directory rename setup preserves the other clean buffer");
      Assert (not S.File_Info.Dirty,
              "directory rename setup active child is clean");

      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/rename_dir_active", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "directory rename source is present in the File Tree");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "directory rename source maps to a selectable row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);

      Run_File_Tree_Text_Prompt_Command
        (S,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         "rename_dir_done",
         Editor.Guided_Prompts.File_Tree_Rename_Prompt,
         "rename directory containing active open buffer");

      Child_Id_After := Editor.Buffers.Global_Find_By_Path
        (New_Child_Path, New_Found);
      declare
         Old_Child : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Find_By_Path (Old_Child_Path, Old_Found);
      begin
         pragma Unreferenced (Old_Child);
      end;

      Assert (not Ada.Directories.Exists (Old_Dir)
                and then Ada.Directories.Exists (New_Dir)
                and then Ada.Directories.Exists (New_Child_Path),
              "File Tree directory rename moves the child file subtree");
      Assert (not Old_Found,
              "File Tree directory rename removes the old child buffer path");
      Assert (New_Found and then Child_Id_After = Child_Id_Before,
              "File Tree directory rename rebases the existing child buffer id");
      Assert (Editor.Buffers.Global_Count = 2,
              "File Tree directory rename does not create duplicate buffers");
      Assert (S.File_Info.Has_Path
                and then To_String (S.File_Info.Path) = New_Child_Path,
              "File Tree directory rename updates the active child path");
      Assert (Ada.Strings.Fixed.Index
                (Editor.State.Current_Text (S), "Open_Child") > 0,
              "File Tree directory rename preserves active child text");
      Assert (not S.File_Info.Dirty,
              "File Tree directory rename preserves clean child state");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "File Tree directory rename returns focus to the active child buffer");
      Assert (Active_Message_Text (S) = "Directory renamed.",
              "File Tree directory rename reports product success");

      Remove_Tree_If_Exists (Root);

   end Test_File_Tree_Rename_Directory_Rebases_Active_Child_Buffer;


   procedure Test_Main_Workflow_Smoke
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Root & "_main_workflow_smoke";
      Source_Path : constant String := Root & "/src/dogfood_demo.adb";
      Main_Path   : constant String := Root & "/src/main.adb";
      S           : Editor.State.State_Type;
      Search_Result : Editor.Project_Search.Project_Search_Result;
      Build_Run      : Editor.Command_Execution.Command_Execution_Result;
      Build_Refresh  : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Context        : Editor.Build_Working_Context.Build_Working_Context_Record;
      Supplied_Process : Editor.External_Producers.Process_Run_Result;
      Build_Command_Result : Editor.External_Producers.Build_Command_Result;
      Diagnostic_Open : Editor.Command_Execution.Command_Execution_Result;
      Back_Result     : Editor.Command_Execution.Command_Execution_Result;

      procedure Expect_Active_Message_Contains
        (Needle : String;
         Why    : String)
      is
      begin
         Assert (Ada.Strings.Fixed.Index (Active_Message_Text (S), Needle) > 0,
                 Why & " (active message was '" & Active_Message_Text (S) & "')");
      end Expect_Active_Message_Contains;
   begin
      --  Main workflow canary: open project -> Quick Open -> Project Search
      --  -> edit -> build -> inspect Diagnostics -> navigate back.
      Build_Dogfood_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Assert (Editor.Project.Has_Project (S.Project),
              "main workflow smoke opens a project");
      Expect_Active_Message_Contains
        ("Opened project",
         "main workflow smoke reports project-open feedback");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "main workflow smoke starts in the source file");
      Expect_Active_Message_Contains
        ("Opened dogfood_demo.adb",
         "main workflow smoke reports file-open feedback");

      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "main.adb");
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) > 0,
              "main workflow smoke Quick Open finds the main source");
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Main_Path,
              "main workflow smoke Quick Open opens main.adb");
      Expect_Active_Message_Contains
        ("Opened main.adb",
         "main workflow smoke reports Quick Open activation feedback");

      Editor.Project_Search.Set_Query (S.Project_Search, "Dogfood_Known_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project,
         (Case_Sensitive => True,
          Max_File_Count => 100,
          Max_Result_Count => 20,
          Max_Matches_Per_File => 5,
          Max_Line_Length => Editor.Project_Search.Max_Search_Result_Preview_Length,
          Max_File_Size_Bytes => 64 * 1024,
          Regex_Max_Steps => 100_000));
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "main workflow smoke Project Search finds the known token");
      Search_Result := Editor.Project_Search.Result_At (S.Project_Search, 1);
      Assert (To_String (Search_Result.Absolute_Path) = Source_Path,
              "main workflow smoke Project Search targets the source file");
      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, 1);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Open_Selected);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "main workflow smoke Project Search opens the result target");
      Expect_Active_Message_Contains
        ("Activated src/dogfood_demo.adb",
         "main workflow smoke reports Project Search activation feedback");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Assert (S.File_Info.Dirty,
              "main workflow smoke edit marks the active source dirty");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
              "main workflow smoke saves the edit before build navigation");
      Expect_Active_Message_Contains
        ("Saved file",
         "main workflow smoke reports save feedback");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Show);
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Build_Refresh := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S.Build_UI, Context);
      Assert (Build_Refresh.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "main workflow smoke discovers build candidates");
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Select_Next_Candidate);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "main workflow smoke selects a build candidate");
      if not S.Build_UI.Show_Diagnostics_On_Result then
         Build_Run := Editor.Executor.Execute_Command_With_Result
           (S, Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion);
         Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
                 "main workflow smoke enables build Diagnostics ingestion");
      end if;
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Acknowledge_Consent);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "main workflow smoke acknowledges build consent");
      Supplied_Process := Editor.External_Producers.Build_Process_Run_Result
        (Editor.External_Producers.Process_Run_Failed,
         Exit_Code => 1,
         Has_Exit_Code => True,
         Stdout_Text => "compiling dogfood_demo.adb",
         Stderr_Text => "src/dogfood_demo.adb:2:4: warning: smoke diagnostic");
      Build_Command_Result :=
        Editor.Build_Command.Execute_Public_Build_Run_With_Supplied_Result
          (S, Supplied_Process);
      Assert (Build_Command_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Failed,
              "main workflow smoke records the build result");
      Assert (Length (Build_Command_Result.Command_Message) > 0,
              "main workflow smoke build result carries user-facing command feedback");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
              "main workflow smoke ingests build Diagnostics");

      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Show);
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Diagnostics,
              "main workflow smoke inspects Diagnostics");
      Expect_Active_Message_Contains
        ("Diagnostics shown",
         "main workflow smoke reports Diagnostics inspection feedback");
      Diagnostic_Open := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (Diagnostic_Open.Status = Editor.Command_Execution.Command_Executed,
              "main workflow smoke opens a Diagnostic target");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) > 0,
              "main workflow smoke records navigation history before back");

      Back_Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Navigation_Back);
      Assert (Back_Result.Status = Editor.Command_Execution.Command_Executed,
              "main workflow smoke navigates back");
      Assert (S.File_Info.Has_Path,
              "main workflow smoke keeps a file-backed editor target after back");
      Expect_Active_Message_Contains
        ("Navigated back",
         "main workflow smoke reports navigation-back feedback");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Main_Workflow_Smoke;


   procedure Test_Full_Daily_Editor_Loop_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Root & "_full_daily_loop";
      Source_Path   : constant String := Root & "/src/dogfood_demo.adb";
      Main_Path     : constant String := Root & "/src/main.adb";
      S             : Editor.State.State_Type;
      S2            : Editor.State.State_Type;
      Found         : Boolean := False;
      Node          : Editor.File_Tree.File_Tree_Node_Id;
      Row           : Natural := 0;
      Search_Result : Editor.Project_Search.Project_Search_Result;
      Outline_Row   : Natural := 0;
      Extracted     : Editor.Outline_Extractor.Extraction_Result;
      Build_Run     : Editor.Command_Execution.Command_Execution_Result;
      Build_Refresh : Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;
      Context       : Editor.Build_Working_Context.Build_Working_Context_Record;
      Supplied_Process : Editor.External_Producers.Process_Run_Result;
      Build_Command_Result : Editor.External_Producers.Build_Command_Result;
      Diagnostic_Open : Editor.Command_Execution.Command_Execution_Result;
      Workspace_Save : Editor.Command_Execution.Command_Execution_Result;
      Workspace_Restore : Editor.Command_Execution.Command_Execution_Result;
      Closed_Buffer : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      --  fix nr 1: a single integrated daily-use loop.  This is not
      --  a command-surface check; it walks the product path from project open
      --  through file navigation, editing, save, Quick Open, Project Search,
      --  Outline, Build/Diagnostics, buffer switching/closing, project close,
      --  workspace restore, and clean quit readiness policy.
      Build_Dogfood_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Assert (Editor.Project.Has_Project (S.Project),
              "daily loop opens a project");
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/dogfood_demo.adb", Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "daily loop locates a source file in File Tree");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Assert (Found and then Row > 0,
              "daily loop maps File Tree source to a selectable row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Tree_Open_Selected);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "daily loop opens File Tree selection into the editor");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop File Tree activation focuses editor");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length,
                                       ASCII.LF));
      Assert (S.File_Info.Dirty,
              "daily loop edit marks buffer dirty");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
              "daily loop save clears dirty state");
      Assert (Ada.Strings.Fixed.Index (Read_File (Source_Path), "Dogfood_Known_Token") > 0,
              "daily loop save preserves source contents on disk");

      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "main.adb");
      Editor.Quick_Open.Recompute_Results
        (S.Quick_Open, S.Project, (Max_Visible_Results => 12,
                                   Max_Result_Count => 100,
                                   Query_Field_Min_Columns => 24,
                                   Overlay_Width_In_Columns => 72,
                                   Row_Height_In_Rows => 1,
                                   Header_Height_In_Rows => 1,
                                   Field_Height_In_Rows => 1,
                                   Result_Padding_Columns => 1));
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Main_Path,
              "daily loop Quick Open opens the requested second buffer");
      Assert (Editor.Buffers.Global_Count >= 2,
              "daily loop has multiple buffers after Quick Open");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Next_Buffer);
      Assert (S.File_Info.Has_Path,
              "daily loop next-buffer keeps an active file-backed buffer");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop buffer switch focuses editor");

      Editor.Project_Search.Set_Query (S.Project_Search, "Dogfood_Known_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project,
         (Case_Sensitive => True,
          Max_File_Count => 100,
          Max_Result_Count => 20,
          Max_Matches_Per_File => 5,
          Max_Line_Length => Editor.Project_Search.Max_Search_Result_Preview_Length,
          Max_File_Size_Bytes => 64 * 1024,
          Regex_Max_Steps => 100_000));
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "daily loop Project Search finds the known token");
      Search_Result := Editor.Project_Search.Result_At (S.Project_Search, 1);
      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, 1);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Project_Search_Results);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Search_Results_Open_Selected);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "daily loop Project Search result opens the source buffer");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop Project Search activation focuses editor");

      Extracted := Editor.Outline_Extractor.Extract
        (Editor.Outline_Extractor.Make_Snapshot
           (Editor.State.Current_Text (S),
            "dogfood_demo.adb",
            S.Active_Buffer_Token,
            S.Buffer_Revision,
            S.Lifecycle_Generation,
            579));
      Assert (Editor.Outline_Extractor.Status (Extracted) =
                Editor.Outline_Extractor.Extraction_Ok,
              "daily loop Outline extraction succeeds on active source buffer");
      Editor.Outline.Begin_Extraction
        (S.Outline, Editor.Outline_Extractor.Identity (Extracted));
      Editor.Outline_Extractor.Apply_To_Outline (Extracted, S.Outline);
      Outline_Row := First_Target_Row (S.Outline);
      Assert (Outline_Row > 0,
              "daily loop Outline has an activatable symbol row");
      Editor.Outline.Select_Item (S.Outline, Outline_Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Outline);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop Outline activation focuses editor");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Show);
      Context := Editor.Build_Working_Context.Current_Project_Root (Root);
      Build_Refresh := Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S.Build_UI, Context);
      Assert (Build_Refresh.Status =
                Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Succeeded,
              "daily loop discovers build candidates");
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Select_Next_Candidate);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "daily loop explicitly selects a build candidate");
      if not S.Build_UI.Show_Diagnostics_On_Result then
         Build_Run := Editor.Executor.Execute_Command_With_Result
           (S, Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion);
         Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
                 "daily loop enables build diagnostics ingestion");
      end if;
      Assert (S.Build_UI.Show_Diagnostics_On_Result,
              "daily loop Build UI request explicitly enables diagnostics ingestion");
      S.Public_Build_Execution_Policy :=
        Editor.Build_Runner_Policy.Build_Execution_Bounded_Process;
      Build_Run := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Acknowledge_Consent);
      Assert (Build_Run.Status = Editor.Command_Execution.Command_Executed,
              "daily loop acknowledges build consent");
      Supplied_Process := Editor.External_Producers.Build_Process_Run_Result
        (Editor.External_Producers.Process_Run_Failed,
         Exit_Code => 1,
         Has_Exit_Code => True,
         Stdout_Text => "compiling dogfood_demo.adb",
         Stderr_Text => "src/dogfood_demo.adb:2:4: warning: daily-loop diagnostic");
      Build_Command_Result :=
        Editor.Build_Command.Execute_Public_Build_Run_With_Supplied_Result
          (S, Supplied_Process);
      Assert (Build_Command_Result.Build_Result.Status =
                Editor.External_Producers.Build_Run_Failed,
              "daily loop records a deterministic build result");
      Assert (S.Latest_Build_Output_Details.Has_Output_Details,
              "daily loop captures Build Output details");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
              "daily loop surfaces build diagnostics");
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Diagnostics);
      Diagnostic_Open := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (Diagnostic_Open.Status = Editor.Command_Execution.Command_Executed,
              "daily loop opens a diagnostic target");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop diagnostic activation focuses editor");

      Workspace_Save := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_Workspace_State);
      Assert (Workspace_Save.Status = Editor.Command_Execution.Command_Executed,
              "daily loop saves workspace before closing");

      Closed_Buffer := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (not Editor.Buffers.Global_Contains (Closed_Buffer),
              "daily loop closes the active clean buffer");
      Assert (Editor.Buffers.Global_Count >= 1,
              "daily loop selects or retains another buffer after close");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop close-buffer keeps editor focus when another buffer remains");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);
      Assert (not Editor.Project.Has_Project (S.Project),
              "daily loop closes the project after clean buffers are safe");
      Assert (Editor.Buffers.Global_Count = 0,
              "daily loop project close removes clean project-owned buffers");

      Editor.State.Init (S2);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S2, Root);
      Workspace_Restore := Editor.Executor.Execute_Command_With_Result
        (S2, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Workspace_Restore.Status = Editor.Command_Execution.Command_Executed,
              "daily loop restores workspace after project reopen");
      Assert (Editor.Project.Has_Project (S2.Project)
                and then Editor.Project.Root_Path (S2.Project) = Root,
              "daily loop restore returns to the project");
      Assert (S2.File_Info.Has_Path,
              "daily loop restore returns to a valid active file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S2) =
                Editor.Focus_Management.Focus_Editor,
              "daily loop restore focuses the editor for continued work");
      Assert (not S2.File_Info.Dirty,
              "daily loop restore does not recreate dirty state");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Status
                (Editor.Dogfood_Workflow.Product_Quit_Safely) =
              "Ready to quit.",
              "daily loop ends in the documented clean quit-readiness state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Full_Daily_Editor_Loop_Dogfood_Scenario;


   procedure Test_Save_Reload_Revert_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Root;
      Source_Path  : constant String := Root & "/src/dogfood_demo.adb";
      Save_As_Path : constant String := Root & "/src/dogfood_saved_as.adb";
      Dir_Target   : constant String := Root & "/src";
      S            : Editor.State.State_Type;
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Found        : Boolean := False;
      Buffer       : Editor.Buffers.Buffer_Id;

      procedure Append_Text (Text : String) is
      begin
         for Ch of Text loop
            Editor.Executor.Execute_No_Log
              (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, Ch));
         end loop;
      end Append_Text;
   begin
      Build_Dogfood_Fixture (Root);
      Remove_File_If_Exists (Save_As_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_Path);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source_Path,
              "save/reload/revert scenario starts on a real project file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "opening the scenario file focuses the editor");

      Append_Text (ASCII.LF & "-- saved edit");
      Assert (S.File_Info.Dirty,
              "editing the scenario file marks it dirty before save");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
              "save clears the dirty flag in the daily workflow");
      Assert (Read_File (Source_Path) = Editor.State.Current_Text (S),
              "save writes the exact active buffer text to disk");
      Assert (To_String (S.File_Info.Path) = Source_Path,
              "save preserves the active backing path");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "save keeps editor focus");

      Append_Text (ASCII.LF & "-- save-as edit");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Assert (not S.File_Info.Dirty,
              "save-as clears the dirty flag after writing the new target");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Save_As_Path,
              "save-as rebases the active buffer path to the new file");
      Assert (Read_File (Save_As_Path) = Editor.State.Current_Text (S),
              "save-as writes the exact active buffer text to the new file");
      Buffer := Editor.Buffers.Global_Find_By_Path (Save_As_Path, Found);
      Assert (Found and then Buffer = Editor.Buffers.Global_Active_Buffer,
              "save-as updates the global buffer registry association");
      Assert (Ada.Directories.Exists (Source_Path),
              "save-as does not delete the previous backing file");

      Append_Text (ASCII.LF & "-- failed save-as must survive");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Before_Path := S.File_Info.Path;
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Dir_Target);
      Assert (S.File_Info.Dirty,
              "failed save-as preserves dirty state");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "failed save-as preserves buffer text");
      Assert (S.File_Info.Has_Path and then S.File_Info.Path = Before_Path,
              "failed save-as preserves the previous backing path");
      Assert (Read_File (Save_As_Path) /= Editor.State.Current_Text (S),
              "failed save-as does not write dirty text to the old target");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
              "save after failed save-as writes the preserved dirty buffer");
      Assert (Read_File (Save_As_Path) = Editor.State.Current_Text (S),
              "save after failed save-as targets the retained backing path");

      Write_File (Save_As_Path, "clean reload from disk");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.State.Current_Text (S) = "clean reload from disk",
              "reload of a clean buffer replaces text from disk");
      Assert (not S.File_Info.Dirty,
              "reload of a clean buffer remains clean");
      Assert (To_String (S.File_Info.Path) = Save_As_Path,
              "reload preserves the active backing path");

      Append_Text (" + local dirty reload edit");
      Write_File (Save_As_Path, "confirmed reload from disk");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty reload captures a confirmation instead of mutating text");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text
                and then S.File_Info.Dirty,
              "dirty reload prompt preserves dirty text before a decision");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancelled dirty reload clears only the pending decision");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text
                and then S.File_Info.Dirty,
              "cancelled dirty reload preserves dirty text and state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty reload can be requested again after cancellation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "confirmed dirty reload clears the pending decision");
      Assert (Editor.State.Current_Text (S) = "confirmed reload from disk"
                and then not S.File_Info.Dirty,
              "confirmed dirty reload replaces text from disk and clears dirty state");

      Append_Text (" + local dirty revert edit");
      Write_File (Save_As_Path, "confirmed revert from disk");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty revert captures a confirmation instead of mutating text");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text
                and then S.File_Info.Dirty,
              "dirty revert prompt preserves dirty text before a decision");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancelled dirty revert clears only the pending decision");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text
                and then S.File_Info.Dirty,
              "cancelled dirty revert preserves dirty text and state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty revert can be requested again after cancellation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "confirmed dirty revert clears the pending decision");
      Assert (Editor.State.Current_Text (S) = "confirmed revert from disk"
                and then not S.File_Info.Dirty,
              "confirmed dirty revert replaces text from disk and clears dirty state");

      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Remove_File_If_Exists (Save_As_Path);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text,
              "reload with a missing backing file preserves current text");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Save_As_Path,
              "reload with a missing backing file preserves the file association");
      Assert (S.File_Info.Missing_Target_Surfaced,
              "reload with a missing backing file surfaces missing-target state");

      Append_Text (" + dirty missing revert edit");
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty revert with a missing file still requires explicit confirmation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "failed missing-file revert clears the stale decision after reporting failure");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Before_Text
                and then S.File_Info.Dirty,
              "failed missing-file revert preserves dirty text and state");
      Assert (S.File_Info.Missing_Target_Surfaced,
              "failed missing-file revert surfaces missing-target state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_Reload_Revert_Dogfood_Scenario;


   procedure Test_Product_Command_Names_Resolve
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;

      procedure Assert_Resolves
        (Name     : String;
         Expected : Editor.Commands.Command_Id;
         Message  : String)
      is
         Actual : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      begin
         Assert (Found, Message & " is accepted as a product command name");
         Assert (Actual = Expected, Message & " resolves to the existing command implementation");
      end Assert_Resolves;

      procedure Assert_Removed_Name_Rejected
        (Name    : String;
         Message : String)
      is
         Actual : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
      begin
         Assert (not Found, Message & " must not resolve");
         Assert (Actual = Editor.Commands.No_Command,
                 Message & " must return No_Command");
      end Assert_Removed_Name_Rejected;
   begin
      Assert_Resolves ("command-palette.show-command-help",
                       Editor.Commands.Command_Palette_Show_Command_Help,
                       "command-palette.show-command-help");
      Assert_Resolves ("project.open",
                       Editor.Commands.Command_Open_Project,
                       "project.open");
      Assert_Resolves ("project.close",
                       Editor.Commands.Command_Close_Project,
                       "project.close");
      Assert_Resolves ("project.switch",
                       Editor.Commands.Command_Switch_Project,
                       "project.switch");
      Assert_Resolves ("project.reopen-recent",
                       Editor.Commands.Command_Open_Selected_Recent_Project,
                       "project.reopen-recent");
      Assert_Resolves ("file.open",
                       Editor.Commands.Command_Open_File,
                       "file.open");
      Assert_Resolves ("file.save",
                       Editor.Commands.Command_Save_File,
                       "file.save");
      Assert_Resolves ("file.save-as",
                       Editor.Commands.Command_Save_File_As,
                       "file.save-as");
      Assert_Resolves ("file.reload-buffer",
                       Editor.Commands.Command_Reload_Active_Buffer,
                       "file.reload-buffer");
      Assert_Resolves ("file.revert-buffer",
                       Editor.Commands.Command_Revert_Active_Buffer,
                       "file.revert-buffer");
      Assert_Resolves ("file-tree.refresh",
                       Editor.Commands.Command_Refresh_File_Tree,
                       "file-tree.refresh");
      Assert_Resolves ("file-tree.open-selected",
                       Editor.Commands.Command_File_Tree_Open_Selected,
                       "file-tree.open-selected");
      Assert_Resolves ("file-tree.create-file",
                       Editor.Commands.Command_File_Tree_Create_File,
                       "file-tree.create-file");
      Assert_Resolves ("file-tree.create-directory",
                       Editor.Commands.Command_File_Tree_Create_Directory,
                       "file-tree.create-directory");
      Assert_Resolves ("file-tree.rename-selected",
                       Editor.Commands.Command_File_Tree_Rename_Selected,
                       "file-tree.rename-selected");
      Assert_Resolves ("file-tree.rename",
                       Editor.Commands.Command_File_Tree_Rename_Selected,
                       "file-tree.rename compatibility alias");
      Assert_Resolves ("file-tree.delete-selected",
                       Editor.Commands.Command_File_Tree_Delete_Selected,
                       "file-tree.delete-selected");
      Assert_Resolves ("file-tree.delete",
                       Editor.Commands.Command_File_Tree_Delete_Selected,
                       "file-tree.delete compatibility alias");
      Assert_Resolves ("quick-open.show",
                       Editor.Commands.Command_Open_Quick_Open,
                       "quick-open.show");
      Assert_Resolves ("quick-open.open-selected",
                       Editor.Commands.Command_Accept_Quick_Open,
                       "quick-open.open-selected");
      Assert_Resolves ("project.search.run",
                       Editor.Commands.Command_Run_Project_Search,
                       "project.search.run");
      Assert_Resolves ("search.project",
                       Editor.Commands.Command_Run_Project_Search,
                       "search.project compatibility alias");
      Assert_Resolves ("project.search.open-selected",
                       Editor.Commands.Command_Open_Selected_Project_Search_Result,
                       "project.search.open-selected");
      Assert_Resolves ("search.open-selected",
                       Editor.Commands.Command_Open_Selected_Project_Search_Result,
                       "search.open-selected compatibility alias");
      Assert_Resolves ("outline.show",
                       Editor.Commands.Command_Show_Outline,
                       "outline.show");
      Assert_Resolves ("build.run",
                       Editor.Commands.Command_Build_Run,
                       "build.run");
      Assert_Resolves ("build.ui.show",
                       Editor.Commands.Command_Build_UI_Show,
                       "build.ui.show");
      Assert_Resolves ("build.output.show",
                       Editor.Commands.Command_Build_UI_Show,
                       "build.output.show compatibility alias");
      Assert_Resolves ("build.ui.toggle",
                       Editor.Commands.Command_Build_UI_Toggle,
                       "build.ui.toggle");
      Assert_Resolves ("build.output.toggle",
                       Editor.Commands.Command_Build_UI_Toggle,
                       "build.output.toggle compatibility alias");
      Assert_Resolves ("build.ui.hide",
                       Editor.Commands.Command_Build_UI_Hide,
                       "build.ui.hide");
      Assert_Resolves ("build.output.hide",
                       Editor.Commands.Command_Build_UI_Hide,
                       "build.output.hide compatibility alias");
      Assert_Resolves ("build.ui.focus",
                       Editor.Commands.Command_Build_UI_Focus,
                       "build.ui.focus");
      Assert_Resolves ("build.output.focus",
                       Editor.Commands.Command_Build_UI_Focus,
                       "build.output.focus compatibility alias");
      Assert_Resolves ("diagnostics.show",
                       Editor.Commands.Command_Diagnostics_Show,
                       "diagnostics.show");
      Assert_Resolves ("buffer.switch-next",
                       Editor.Commands.Command_Next_Buffer,
                       "buffer.switch-next");
      Assert_Resolves ("buffer.switch-previous",
                       Editor.Commands.Command_Previous_Buffer,
                       "buffer.switch-previous");
      Assert_Resolves ("file.close-buffer",
                       Editor.Commands.Command_Close_Active_Buffer,
                       "file.close-buffer");
      Assert_Resolves ("file.close-clean-buffers",
                       Editor.Commands.Command_Close_All_Clean_Buffers,
                       "file.close-clean-buffers");
      Assert_Resolves ("buffer.close-all-clean",
                       Editor.Commands.Command_Close_All_Clean_Buffers,
                       "buffer.close-all-clean compatibility alias");
      Assert_Resolves ("workspace.restore",
                       Editor.Commands.Command_Restore_Workspace_State,
                       "workspace.restore");

      Assert_Removed_Name_Rejected ("command_palette.show_command_help",
                                    "removed command-palette spelling");
      Assert_Removed_Name_Rejected ("project.reopen_recent",
                                    "removed project reopen spelling");
      Assert_Removed_Name_Rejected ("file.save_as",
                                    "removed save-as spelling");
      Assert_Removed_Name_Rejected ("file_tree.refresh",
                                    "removed file tree spelling");
      Assert_Removed_Name_Rejected ("file_tree.open_selected",
                                    "removed file tree open-selected spelling");
      Assert_Removed_Name_Rejected ("file-tree.create_file",
                                    "removed create-file spelling");
      Assert_Removed_Name_Rejected ("file_tree.create_file",
                                    "removed file tree create-file spelling");
      Assert_Removed_Name_Rejected ("file-tree.create_directory",
                                    "removed create-directory spelling");
      Assert_Removed_Name_Rejected ("file_tree.create_directory",
                                    "removed file tree create-directory spelling");
      Assert_Removed_Name_Rejected ("quick_open.show",
                                    "removed quick-open spelling");
      Assert_Removed_Name_Rejected ("quick_open.open_selected",
                                    "removed quick-open open-selected spelling");
      Assert_Removed_Name_Rejected ("search.open_selected",
                                    "removed search open-selected spelling");
      Assert_Removed_Name_Rejected ("outline.open_selected",
                                    "removed outline open-selected spelling");
      Assert_Removed_Name_Rejected ("outline.goto-selected",
                                    "removed outline goto-selected name");
      Assert_Removed_Name_Rejected ("outline.goto_selected",
                                    "removed outline goto-selected spelling");
      Assert_Removed_Name_Rejected ("outline.select_next",
                                    "removed outline select-next spelling");
      Assert_Removed_Name_Rejected ("outline.select_previous",
                                    "removed outline select-previous spelling");
      Assert_Removed_Name_Rejected ("buffer.switch_next",
                                    "removed buffer switch-next spelling");
      Assert_Removed_Name_Rejected ("buffer.switch_previous",
                                    "removed buffer switch-previous spelling");
      Assert_Removed_Name_Rejected ("buffer.close_all_clean",
                                    "removed buffer close-all-clean spelling");

      for Step in Editor.Dogfood_Workflow.Product_Workflow_Step loop
         if Step /= Editor.Dogfood_Workflow.Product_Edit_Buffer
           and then Step /= Editor.Dogfood_Workflow.Product_Quit_Safely
         then
            declare
               Name : constant String :=
                 Editor.Dogfood_Workflow.Product_Workflow_Command (Step);
               Id : constant Editor.Commands.Command_Id :=
                 Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
               D  : Editor.Commands.Command_Descriptor;
            begin
               Assert (Found,
                       "documented product command resolves: " & Name);
               Assert (Id /= Editor.Commands.No_Command,
                       "documented product command has an implementation: " & Name);
               D := Editor.Commands.Descriptor (Id);
               Assert
                 (To_String (D.Name) =
                    Editor.Dogfood_Workflow.Product_Workflow_Label (Step),
                  "documented workflow label matches command descriptor: " &
                  Name);
            end;
         end if;
      end loop;
   end Test_Product_Command_Names_Resolve;


   procedure Test_Product_Command_Surface_Is_User_Facing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Check
        (Name            : String;
         Expected_Label  : String;
         Expected_Visible : Boolean)
      is
         Found : Boolean := False;
         Id    : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         D     : Editor.Commands.Command_Descriptor;
      begin
         Assert (Found, Name & " resolves as a product command name");
         Assert (Id /= Editor.Commands.No_Command,
                 Name & " resolves to a real command");
         D := Editor.Commands.Descriptor (Id);
         Assert (To_String (D.Name)'Length > 0,
                 Name & " has a non-empty command palette label");
         Assert (To_String (D.Name) = Expected_Label,
                 Name & " exposes the expected product-facing label");
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (To_String (D.Name)) = False,
                 Name & " label does not expose internal terminology");
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (To_String (D.Description)) = False,
                 Name & " description does not expose internal terminology");
         if Expected_Visible then
            Assert (D.Visibility = Editor.Commands.Palette_Command,
                    Name & " is discoverable in the normal command palette");
         else
            Assert (D.Visibility = Editor.Commands.Hidden_Command,
                    Name & " remains intentionally hidden from normal command discovery");
         end if;
      end Check;
   begin
      Check ("command-palette.show-command-help", "Show Command Help", True);
      Check ("project.open", "Open Project", True);
      Check ("project.close", "Close Project", True);
      Check ("project.switch", "Switch Project", True);
      Check ("project.reopen-recent", "Open Selected Recent Project", False);
      Check ("file.open", "Open File", True);
      Check ("file.save", "Save File", True);
      Check ("file.save-as", "Save File As", True);
      Check ("file.reload-buffer", "Reload File", True);
      Check ("file.revert-buffer", "Revert File", True);
      Check ("file-tree.refresh", "Refresh File Tree", True);
      Check ("file-tree.open-selected", "Open Selected File", True);
      Check ("file-tree.create-file", "Create File", True);
      Check ("file-tree.create-directory", "Create Directory", True);
      Check ("file-tree.rename-selected", "Rename File or Directory", True);
      Check ("file-tree.delete-selected", "Delete File or Directory", True);
      Check ("quick-open.show", "Quick Open", True);
      Check ("quick-open.open-selected", "Open Selected Quick Open Result", False);
      Check ("project.search.run", "Search Project", True);
      Check ("project.search.open-selected", "Open Selected Project Search Result", True);
      Check ("outline.show", "Show Outline", True);
      Check ("build.run", "Run Build", True);
      Check ("build.ui.show", "Show Build Output", True);
      Check ("build.ui.toggle", "Toggle Build Output", True);
      Check ("build.ui.hide", "Hide Build Output", True);
      Check ("build.ui.focus", "Focus Build Output", True);
      Check ("diagnostics.show", "Show Diagnostics", True);
      Check ("buffer.switch-next", "Next Buffer", True);
      Check ("buffer.switch-previous", "Previous Buffer", True);
      Check ("file.close-buffer", "Close Buffer", True);
      Check ("file.close-clean-buffers", "Close All Clean Buffers", True);
      Check ("workspace.restore", "Restore Workspace", True);

      for Id in Editor.Commands.Command_Id loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (Id);
         begin
            if D.Visibility = Editor.Commands.Palette_Command then
               Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                         (To_String (D.Name)) = False,
                       "palette-visible command label avoids internal terms: " &
                       To_String (D.Name));
               Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                         (To_String (D.Description)) = False,
                       "palette-visible command description avoids internal terms: " &
                       To_String (D.Name));
            end if;
         end;
      end loop;
   end Test_Product_Command_Surface_Is_User_Facing;


   procedure Test_Quick_Open_Product_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Label
        (Id       : Editor.Commands.Command_Id;
         Expected : String;
         Message  : String)
      is
         D : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
      begin
         Assert (To_String (D.Name) = Expected, Message);
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (To_String (D.Name)) = False,
                 Message & " label avoids internal terminology");
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (To_String (D.Description)) = False,
                 Message & " description avoids internal terminology");
      end Expect_Label;
   begin
      Expect_Label (Editor.Commands.Command_Close_Quick_Open,
                    "Hide Quick Open",
                    "Quick Open hide label is product-facing");
      Expect_Label (Editor.Commands.Command_Toggle_Quick_Open,
                    "Toggle Quick Open",
                    "Quick Open toggle label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Next_Result,
                    "Next Quick Open Result",
                    "Quick Open next-result label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Previous_Result,
                    "Previous Quick Open Result",
                    "Quick Open previous-result label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Query_Set,
                    "Set Quick Open Query",
                    "Quick Open query-set label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Query_Clear,
                    "Clear Quick Open Query",
                    "Quick Open query-clear label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Kind_Next,
                    "Next Quick Open File Kind",
                    "Quick Open next-kind label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Kind_Previous,
                    "Previous Quick Open File Kind",
                    "Quick Open previous-kind label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Kind_Clear,
                    "Clear Quick Open File Kind",
                    "Quick Open kind-clear label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Scope_Set,
                    "Set Quick Open Scope",
                    "Quick Open scope-set label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Scope_Clear,
                    "Clear Quick Open Scope",
                    "Quick Open scope-clear label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Scope_From_Selected,
                    "Scope Quick Open to Selected Directory",
                    "Quick Open selected-scope label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Scope_Parent,
                    "Quick Open Parent Scope",
                    "Quick Open parent-scope label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Reveal_Active,
                    "Reveal Active File in Quick Open",
                    "Quick Open reveal-active label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Scope_Active_Directory,
                    "Scope Quick Open to Active Directory",
                    "Quick Open active-directory scope label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Create_From_Query,
                    "Create File from Quick Open Query",
                    "Quick Open create-from-query label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query,
                    "Create File with Parent Directories from Quick Open Query",
                    "Quick Open create-with-parents label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Priority_Toggle,
                    "Toggle Quick Open Recent Priority",
                    "Quick Open priority-toggle label is product-facing");
      Expect_Label (Editor.Commands.Command_Quick_Open_Priority_Clear,
                    "Clear Quick Open Priority",
                    "Quick Open priority-clear label is product-facing");
   end Test_Quick_Open_Product_Surface_Coherent;

   procedure Test_Diagnostics_Product_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Clean
        (Id       : Editor.Commands.Command_Id;
         Expected : String;
         Message  : String)
      is
         D    : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Name : constant String := To_String (D.Name);
         Desc : constant String := To_String (D.Description);
      begin
         Assert (Name = Expected, Message);
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (Name) = False,
                 Message & " label avoids internal terminology");
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (Desc) = False,
                 Message & " description avoids internal terminology");
         Assert (Ada.Strings.Fixed.Index (Desc, "projection") = 0,
                 Message & " description avoids projection wording");
         Assert (Ada.Strings.Fixed.Index (Desc, "Diagnostic_Id") = 0,
                 Message & " description avoids runtime diagnostic identifiers");
         Assert (Ada.Strings.Fixed.Index (Desc, "payload") = 0,
                 Message & " description avoids command-payload wording");
         Assert (Ada.Strings.Fixed.Index (Desc, "explicitly classified") = 0,
                 Message & " description avoids classifier wording");
      end Expect_Clean;
   begin
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Info,
                    "Toggle Info Diagnostics",
                    "Diagnostics info toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Warnings,
                    "Toggle Warning Diagnostics",
                    "Diagnostics warning toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Errors,
                    "Toggle Error Diagnostics",
                    "Diagnostics error toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Filter_Errors,
                    "Show Error Diagnostics",
                    "Diagnostics error filter is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Filter_Warnings,
                    "Show Warning Diagnostics",
                    "Diagnostics warning filter is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Filter_Info_Notes,
                    "Show Info and Note Diagnostics",
                    "Diagnostics info filter is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Filter_Source,
                    "Show Diagnostics from Selected Source",
                    "Diagnostics source filter is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Filter_Build,
                    "Show Build Diagnostics",
                    "Diagnostics build filter is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Open_Selected,
                    "Open Selected Diagnostic",
                    "Diagnostics open-selected command is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Clear_Selected,
                    "Clear Selected Diagnostic",
                    "Diagnostics clear-selected command is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Editor_Source,
                    "Toggle Editor Diagnostics",
                    "Diagnostics editor-source toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_File_Source,
                    "Toggle File Diagnostics",
                    "Diagnostics file-source toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Project_Source,
                    "Toggle Project Diagnostics",
                    "Diagnostics project-source toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_External_Source,
                    "Toggle External Diagnostics",
                    "Diagnostics external-source toggle is product-facing");
      Expect_Clean (Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source,
                    "Toggle Unknown Diagnostics",
                    "Diagnostics unknown-source toggle is product-facing");
   end Test_Diagnostics_Product_Surface_Coherent;


   procedure Test_Open_Buffer_List_Product_Surface_Coherent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Clean
        (Id       : Editor.Commands.Command_Id;
         Expected : String;
         Message  : String)
      is
         D    : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Name : constant String := To_String (D.Name);
         Desc : constant String := To_String (D.Description);
      begin
         Assert (Name = Expected, Message);
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (Name) = False,
                 Message & " label avoids implementation wording");
         Assert (Editor.Dogfood_Workflow.Product_Label_Contains_Internal_Term
                   (Desc) = False,
                 Message & " description avoids implementation wording");
      end Expect_Clean;
   begin
      Expect_Clean (Editor.Commands.Command_Open_Buffer_Switcher,
                    "Show Open Buffer List",
                    "Open Buffer List show label is product-facing");
      Expect_Clean (Editor.Commands.Command_Close_Buffer_Switcher,
                    "Hide Open Buffer List",
                    "Open Buffer List hide label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Filter_Clear,
                    "Clear Open Buffer List Filter",
                    "Open Buffer List filter-clear label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Filter_Pinned,
                    "Filter Open Buffer List to Pinned Buffers",
                    "Open Buffer List pinned-filter label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Sort_Default,
                    "Sort Open Buffer List Default",
                    "Open Buffer List default-sort label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Sort_Recent,
                    "Sort Open Buffer List by Recent",
                    "Open Buffer List recent-sort label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Selected_Close,
                    "Close Selected Buffer List Row",
                    "Open Buffer List selected-close label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Preview_Show,
                    "Show Open Buffer List Preview",
                    "Open Buffer List preview label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Mark_Toggle,
                    "Toggle Selected Buffer Mark",
                    "Open Buffer List mark label is product-facing");
      Expect_Clean (Editor.Commands.Command_Buffer_Switcher_Mark_Summary,
                    "Summarize Buffer Marks",
                    "Open Buffer List mark-summary label is product-facing");
   end Test_Open_Buffer_List_Product_Surface_Coherent;


   procedure Test_Dirty_Close_Project_Switch_Quit_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A      : constant String := Temp_Root & "_dirty_a";
      Root_B      : constant String := Temp_Root & "_dirty_b";
      Dirty_Path  : constant String := Root_A & "/src/dogfood_demo.adb";
      Clean_Path  : constant String := Root_A & "/src/main.adb";
      S           : Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Dirty_Text  : Unbounded_String;
      Dirty_Id    : Editor.Buffers.Buffer_Id;
      Clean_Id    : Editor.Buffers.Buffer_Id;

      procedure Append_Text (Text : String) is
      begin
         for Ch of Text loop
            Editor.Executor.Execute_No_Log
              (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, Ch));
         end loop;
      end Append_Text;

      procedure Reset_Project_A is
      begin
         Editor.Buffers.Reset_Global_For_Test;
         Remove_Tree_If_Exists (Root_A);
         Remove_Tree_If_Exists (Root_B);
         Build_Dogfood_Fixture (Root_A);
         Build_Dogfood_Fixture (Root_B);
         Editor.State.Init (S);
         Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root_A);
         Editor.Executor.File_Open_Commands.Execute_Open_File (S, Dirty_Path);
      end Reset_Project_A;
   begin
      --  Close active dirty buffer: cancel must be a non-mutating decision.
      Reset_Project_A;
      Append_Text (ASCII.LF & "-- dirty close cancel");
      Dirty_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Dirty_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "dirty close opens explicit dirty-buffer review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Close);
      Assert (not S.Dirty_Close_Prompt_Active,
              "dirty close cancel clears only the close review");
      Assert (Editor.Buffers.Global_Contains (Dirty_Id),
              "dirty close cancel keeps the dirty buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = Dirty_Id,
              "dirty close cancel keeps the same active buffer");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Dirty_Text,
              "dirty close cancel preserves dirty buffer text");
      Assert (S.File_Info.Dirty,
              "dirty close cancel preserves dirty state");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "dirty close cancel restores editor focus");

      --  Close active dirty buffer: discard must close only the selected dirty
      --  buffer and select the next valid buffer without dirtying it.
      Reset_Project_A;
      Append_Text (ASCII.LF & "-- dirty close discard");
      Dirty_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Clean_Path);
      Clean_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Clean_Id /= Dirty_Id,
              "discard scenario has a second clean buffer");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Dirty_Path);
      Assert (Editor.Buffers.Global_Active_Buffer = Dirty_Id,
              "discard scenario returns to dirty buffer before close");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (S.Dirty_Close_Prompt_Active,
              "dirty close discard path opens review");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Confirm_Close_Discard);
      Assert (not S.Dirty_Close_Prompt_Active,
              "dirty close discard resolves review");
      Assert (not Editor.Buffers.Global_Contains (Dirty_Id),
              "dirty close discard closes the selected dirty buffer");
      Assert (Editor.Buffers.Global_Contains (Clean_Id),
              "dirty close discard keeps the clean buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = Clean_Id,
              "dirty close discard selects the remaining buffer");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Clean_Path,
              "dirty close discard loads the remaining buffer path into editor state");
      Assert (not S.File_Info.Dirty,
              "dirty close discard does not dirty the remaining buffer");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "dirty close discard focuses the replacement editor buffer");

      --  Close project with dirty buffers: cancel must preserve project,
      --  buffers, text, dirty state, and editor focus.
      Reset_Project_A;
      Append_Text (ASCII.LF & "-- project close cancel");
      Dirty_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Dirty_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Close_Project);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty project close captures pending decision");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty project close cancel clears only the pending decision");
      Assert (Editor.Project.Has_Project (S.Project)
                and then Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "dirty project close cancel preserves the active project");
      Assert (Editor.Buffers.Global_Contains (Dirty_Id),
              "dirty project close cancel keeps the dirty buffer open");
      Assert (Editor.Buffers.Global_Active_Buffer = Dirty_Id,
              "dirty project close cancel keeps the dirty buffer active");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Dirty_Text
                and then S.File_Info.Dirty,
              "dirty project close cancel preserves dirty text and state");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "dirty project close cancel restores editor focus");

      --  Switch project with dirty buffers: cancel must preserve the old
      --  project and never promote/activate the target.
      Reset_Project_A;
      Append_Text (ASCII.LF & "-- project switch cancel");
      Dirty_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Dirty_Id := Editor.Buffers.Global_Active_Buffer;
      Cmd.Kind := Editor.Commands.Switch_Project;
      Cmd.Path := To_Unbounded_String (Root_B);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty project switch captures pending decision");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "dirty project switch does not activate the target before confirmation");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty project switch cancel clears the pending decision");
      Assert (Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root_A),
              "dirty project switch cancel preserves the current project");
      Assert (Editor.Buffers.Global_Contains (Dirty_Id)
                and then Editor.Buffers.Global_Active_Buffer = Dirty_Id,
              "dirty project switch cancel preserves the active dirty buffer");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Dirty_Text
                and then S.File_Info.Dirty,
              "dirty project switch cancel preserves dirty text and state");

      --  Quit readiness is represented by the product policy until
      --  the host quit lifecycle invokes it.  The product rule must distinguish
      --  clean readiness from dirty blockers without mutating state.
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Success_Status
                (Editor.Dogfood_Workflow.Product_Quit_Safely) =
              "Ready to quit.",
              "clean quit readiness status is explicit");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Failure_Status
                (Editor.Dogfood_Workflow.Product_Quit_Safely) =
              "Dirty buffers need review before quitting.",
              "dirty quit readiness reports blockers");
      Assert (Editor.Dogfood_Workflow.Product_Workflow_Dirty_Buffer_Behavior
                (Editor.Dogfood_Workflow.Product_Quit_Safely) =
              "blocks until dirty buffers are saved, discarded, or cancellation preserves them",
              "quit readiness uses the same dirty-buffer decision policy");

      Remove_Tree_If_Exists (Root_A);
      Remove_Tree_If_Exists (Root_B);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root_A);
         Remove_Tree_If_Exists (Root_B);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Close_Project_Switch_Quit_Dogfood_Scenario;



   procedure Test_Workspace_Restore_Edge_Cases_Dogfood_Scenario
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Root & "_restore_edges";
      Valid_Path    : constant String := Root & "/src/main.adb";
      Missing_Path  : constant String := Root & "/src/missing.adb";
      Mismatch_Root : constant String := Root & "_missing_root";
      S             : Editor.State.State_Type;
      Snapshot      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status        : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary       : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found         : Boolean := False;
      Id            : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Existing_Text : Unbounded_String;

      function Entry_For
        (Path : String) return Editor.Workspace_Persistence.Workspace_File_Entry
      is
      begin
         return
           (Path                => To_Unbounded_String (Path),
            Is_Project_Relative => True,
            Cursor_Row          => 0,
            Cursor_Column       => 0,
            View_First_Row      => 0);
      end Entry_For;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Mismatch_Root);
      Build_Dogfood_Fixture (Root);

      --  Missing active file with a valid restored fallback: restore should
      --  skip the stale entry, select a valid restored buffer, and return the
      --  user to the editor instead of leaving focus on a stale overlay/panel.
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot, Entry_For ("src/missing.adb"));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot, Entry_For ("src/main.adb"));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/missing.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path
        (Snapshot, "src/missing_dir");

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "workspace restore with stale active path is a partial restore");
      Assert (Summary.Files_Requested = 2,
              "workspace restore counts requested file entries");
      Assert (Summary.Files_Restored = 1,
              "workspace restore restores the valid file entry");
      Assert (Summary.Files_Skipped >= 1,
              "workspace restore skips the missing file entry");
      Assert (Summary.Expansions_Skipped = 1,
              "workspace restore skips missing File Tree expansion");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Valid_Path,
              "workspace restore falls back to the valid restored file");
      Assert (Editor.State.Current_Text (S) = Read_File (Valid_Path),
              "workspace restore loads the valid restored file text");
      Id := Editor.Buffers.Global_Find_By_Path (Valid_Path, Found);
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "workspace restore registers the valid restored buffer");
      Id := Editor.Buffers.Global_Find_By_Path (Missing_Path, Found);
      Assert (not Found,
              "workspace restore does not create a buffer for a missing file");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "workspace restore focuses editor for a valid restored active buffer");

      --  If all file entries are stale, restore must not leave focus on a
      --  pre-restore overlay.  The File Tree remains the deterministic recovery
      --  surface and no missing buffer path is registered.
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Quick_Open);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot, Entry_For ("src/missing.adb"));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/missing.adb", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "workspace restore with only missing files is partial");
      Assert (not S.File_Info.Has_Path,
              "workspace restore with only missing files does not fabricate active file state");
      Id := Editor.Buffers.Global_Find_By_Path (Missing_Path, Found);
      Assert (not Found,
              "workspace restore with only missing files does not register missing buffer paths");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_File_Tree,
              "workspace restore with only missing files returns to File Tree recovery focus");

      --  A structurally invalid restore must remain non-mutating: project,
      --  active file, text, buffer identity, and editor focus are preserved.
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Valid_Path);
      Existing_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Editor);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Mismatch_Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot, Entry_For ("src/main.adb"));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "workspace restore rejects a mismatched project root");
      Assert (Editor.Project.Has_Project (S.Project)
                and then Editor.Project.Root_Path (S.Project) = Ada.Directories.Full_Name (Root),
              "invalid workspace restore preserves the active project");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Valid_Path,
              "invalid workspace restore preserves the active file path");
      Assert (To_Unbounded_String (Editor.State.Current_Text (S)) = Existing_Text,
              "invalid workspace restore preserves active buffer text");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
              "invalid workspace restore preserves active buffer identity");
      Assert (Editor.Focus_Management.Effective_Focus_Owner (S) =
                Editor.Focus_Management.Focus_Editor,
              "invalid workspace restore preserves editor focus");

      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Mismatch_Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Remove_Tree_If_Exists (Mismatch_Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Restore_Edge_Cases_Dogfood_Scenario;

   overriding function Name
     (T : Dogfood_Workflow_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Dogfood_Workflow");
   end Name;

   overriding procedure Set_Up (T : in out Dogfood_Workflow_Test_Case) is
      pragma Unreferenced (T);
   begin
      Remove_Tree_If_Exists (Temp_Config_Root);
      Ada.Directories.Create_Path (Temp_Config_Root);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Temp_Config_Root);
   end Set_Up;

   overriding procedure Tear_Down (T : in out Dogfood_Workflow_Test_Case) is
      pragma Unreferenced (T);
   begin
      Editor.Recent_Projects.Clear_Config_Directory_Override;
      Remove_Tree_If_Exists (Temp_Config_Root);
   end Tear_Down;

   overriding procedure Register_Tests
     (T : in out Dogfood_Workflow_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Dogfood_Project_Workflow_Coherent'Access,
         "dogfood project workflow coherent");
      Register_Routine
        (T, Test_Dogfood_Usability_Fixes_Coherent'Access,
         "dogfood usability fixes coherent");
      Register_Routine
        (T, Test_Milestone_Readiness_Coherent'Access,
         "milestone startup and dogfood readiness coherent");
      Register_Routine
        (T, Test_Repeated_Local_Use_Hardening_Coherent'Access,
         "repeated local use hardening coherent");
      Register_Routine
        (T, Test_Integrated_Workflow_Polish_Coherent'Access,
         "integrated workflow polish coherent");
      Register_Routine
        (T, Test_Project_Switch_Dogfood_Scenario'Access,
         "project switch dogfood scenario");
      Register_Routine
        (T, Test_Dirty_Conflict_Dogfood_Scenario'Access,
         "dirty conflict dogfood scenario");
      Register_Routine
        (T, Test_Product_Workflow_Surface_Coherent'Access,
         "product workflow surface coherent");
      Register_Routine
        (T, Test_Product_Focus_And_Cancel_Behavior'Access,
         "product focus and cancel behavior");
      Register_Routine
        (T, Test_File_Tree_Clean_Open_Buffer_Lifecycle'Access,
         "File Tree clean open-buffer lifecycle");
      Register_Routine
        (T, Test_File_Tree_Delete_Active_Buffer_Selects_Next_Buffer'Access,
         "File Tree delete active buffer selects next buffer");
      Register_Routine
        (T, Test_File_Tree_Rename_Directory_Rebases_Active_Child_Buffer'Access,
         "File Tree rename directory rebases active child buffer");
      Register_Routine
        (T, Test_Main_Workflow_Smoke'Access,
         "main workflow smoke");
      Register_Routine
        (T, Test_Full_Daily_Editor_Loop_Dogfood_Scenario'Access,
         "full daily editor loop dogfood scenario");
      Register_Routine
        (T, Test_Save_Reload_Revert_Dogfood_Scenario'Access,
         "save reload revert dogfood scenario");
      Register_Routine
        (T, Test_Dirty_Close_Project_Switch_Quit_Dogfood_Scenario'Access,
         "dirty close project switch quit dogfood scenario");
      Register_Routine
        (T, Test_Workspace_Restore_Edge_Cases_Dogfood_Scenario'Access,
         "workspace restore edge cases dogfood scenario");
      Register_Routine
        (T, Test_Product_Command_Names_Resolve'Access,
         "product command names resolve");
      Register_Routine
        (T, Test_Product_Command_Surface_Is_User_Facing'Access,
         "product command surface is user-facing");
      Register_Routine
        (T, Test_Quick_Open_Product_Surface_Coherent'Access,
         "Quick Open product surface coherent");
      Register_Routine
        (T, Test_Diagnostics_Product_Surface_Coherent'Access,
         "Diagnostics product surface coherent");
      Register_Routine
        (T, Test_Open_Buffer_List_Product_Surface_Coherent'Access,
         "Open Buffer List product surface coherent");
   end Register_Tests;

end Editor.Dogfood_Workflow.Tests;
