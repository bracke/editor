with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with Editor.Buffers;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Build_Candidate_Refresh;
with Editor.Build_UI;
with Editor.Build_UI_Actions;
with Editor.Command_Execution;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.External_Producers;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Files;
with Editor.Focus_Management;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Layout;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Outline;
with Editor.Panels;
with Editor.Project;
with Editor.Problems;
with Editor.Project_Search;
with Editor.Pending_Transitions;
with Editor.Quick_Open;
with Editor.Render_Packet;
with Editor.State;
with Editor.Test_Helper;
with Editor.View;
with Editor.Workspace_Persistence;

procedure Editor_Product_Smoke is

   use type Editor.External_Producers.Build_Run_Status;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Focus_Management.Focus_Owner;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Feature_Panel.Feature_Id;
   use type Editor.Problems.Problems_Group_Mode;
   use type Editor.Problems.Problems_Header_Action;
   use type Editor.Problems.Problems_Severity_Filter;
   use type Editor.Problems.Problems_Sort_Mode;

   package Stream_IO renames Ada.Streams.Stream_IO;

   Root : constant String := "/tmp/e2e_product_smoke_project";
   Src  : constant String := Root & "/src";
   Other_Root : constant String := "/tmp/e2e_product_smoke_project_next";
   Other_Src  : constant String := Other_Root & "/src";
   Main_Path : constant String := Src & "/main.adb";
   Unit_Path : constant String := Src & "/smoke_unit.adb";
   Demo_Path : constant String := Src & "/smoke_demo.ads";
   Workspace_Path : constant String := Root & "/e2e.workspace";
   Session_Path : constant String :=
     Editor.Workspace_Persistence.Session_File_Path (Root);
   Report_Path : constant String := "/tmp/editor_product_smoke_report.txt";
   Scenario : constant String :=
     (if Ada.Command_Line.Argument_Count = 0
      then "all"
      else Ada.Command_Line.Argument (1));

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error,
                            "editor_product_smoke: " & Message);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Program_Error with Message;
   end Fail;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Fail (Message);
      end if;
   end Check;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Write_File (Path : String; Text : String) is
      F   : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
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
      Result : constant Editor.Files.File_Open_Result :=
        Editor.Files.Open_File (Path);
   begin
      if Editor.Files.Is_Success (Result) then
         return To_String (Result.Contents);
      end if;
      return "";
   end Read_File;

   procedure Build_Fixture is
   begin
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Ada.Directories.Create_Path (Src);
      Ada.Directories.Create_Path (Other_Src);
      Write_File
        (Root & "/smoke_project.gpr",
         "project Smoke_Project is" & ASCII.LF &
         "   for Source_Dirs use (""src"");" & ASCII.LF &
         "   for Main use (""main.adb"");" & ASCII.LF &
         "end Smoke_Project;" & ASCII.LF);
      Write_File
        (Src & "/smoke_unit.ads",
         "package Smoke_Unit is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   function Token return String;" & ASCII.LF &
         "end Smoke_Unit;" & ASCII.LF);
      Write_File
        (Demo_Path,
         "package Smoke_Demo is" & ASCII.LF &
         "   type Counter is range 0 .. 100;" & ASCII.LF &
         ASCII.LF &
         "   procedure Increment (Value : in out Counter);" & ASCII.LF &
         "end Smoke_Demo;" & ASCII.LF);
      Write_File
        (Unit_Path,
         "package body Smoke_Unit is" & ASCII.LF &
         "   procedure Run is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      null;" & ASCII.LF &
         "   end Run;" & ASCII.LF & ASCII.LF &
         "   function Token return String is" & ASCII.LF &
         "   begin" & ASCII.LF &
         "      return ""E2E_Token"";" & ASCII.LF &
         "   end Token;" & ASCII.LF &
         "end Smoke_Unit;" & ASCII.LF);
      Write_File
        (Main_Path,
         "with Smoke_Unit;" & ASCII.LF & ASCII.LF &
         "procedure Main is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   Smoke_Unit.Run;" & ASCII.LF &
         "end Main;" & ASCII.LF);
      Write_File
        (Other_Root & "/next_project.gpr",
         "project Next_Project is" & ASCII.LF &
         "   for Source_Dirs use (""src"");" & ASCII.LF &
         "end Next_Project;" & ASCII.LF);
      Write_File
        (Other_Src & "/next_unit.ads",
         "package Next_Unit is" & ASCII.LF &
         "end Next_Unit;" & ASCII.LF);
   end Build_Fixture;

   procedure Write_Report (Text : String) is
   begin
      Write_File (Report_Path, Text);
   end Write_Report;

   procedure Finish (Marker, Message : String) is
   begin
      Write_Report (Marker & "=confirmed" & ASCII.LF);
      Ada.Text_IO.Put_Line ("editor_product_smoke: behavior " & Message & " confirmed");
      Ada.Text_IO.Put_Line ("editor_product_smoke: PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Finish;

   function Focused (Name : String) return Boolean is
   begin
      return Scenario = Name;
   end Focused;

   function Smoke_Request return Editor.External_Producers.Build_Run_Request is
      Args : Editor.External_Producers.Process_Argument_Vector :=
        Editor.External_Producers.Empty_Process_Arguments;
   begin
      Editor.External_Producers.Append_Process_Argument (Args, "-P");
      Editor.External_Producers.Append_Process_Argument
        (Args, Root & "/smoke_project.gpr");
      return
        (Tool => Editor.External_Producers.GPRbuild_Tool,
         Provenance => Editor.External_Producers.Build_Request_From_User_Opt_In,
         Working_Label => Null_Unbounded_String,
         Command_Label => To_Unbounded_String ("gprbuild -P smoke_project.gpr"),
         Arguments => Null_Unbounded_String,
         Structured_Arguments => Args);
   end Smoke_Request;

   S : Editor.State.State_Type;
   Refresh : Editor.Project.Project_File_Refresh_Result;
   Found : Boolean := False;
   Node : Editor.File_Tree.File_Tree_Node_Id;
   Row : Natural := 0;
   Unit_Token : Natural := 0;
   Target_Row_Selected : Boolean := False;
   Search_Result : Editor.Project_Search.Project_Search_Result;
   Build_Context : Editor.External_Producers.User_Opt_In_Build_Command_Context;
   Supplied_Process : Editor.External_Producers.Process_Run_Result;
   Build_Result : Editor.External_Producers.Build_Command_Result;
   Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
   Loaded : Editor.Workspace_Persistence.Workspace_Snapshot;
   Persist_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   Packet : Editor.Render_Packet.Render_Packet;

   procedure Run_Build_UI_Interaction_Scenario is
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot;
      Direct_Quick_Fix : Editor.Command_Execution.Command_Execution_Result;
      Direct_Diagnostic_Index : Natural := 0;
      Keyboard_Diagnostic_Index : Natural := 0;
      Keyboard_Quick_Fix_Row : Natural := 0;
      Disabled_Diagnostic_Index : Natural := 0;
      Disabled_Quick_Fix_Row : Natural := 0;

      procedure Select_Diagnostic_Item (Item_Index : Positive) is
         Mapped : Natural := 0;
      begin
         Editor.Feature_Diagnostics.Project_Rows
           (S.Feature_Diagnostics, S.Feature_Panel);
         for Row in 1 .. Editor.Feature_Panel.Row_Count (S.Feature_Panel) loop
            Mapped := Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
              (S.Feature_Diagnostics,
               S.Feature_Panel,
               Row,
               Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
            if Mapped = Natural (Item_Index) then
               Editor.Feature_Panel.Select_Row (S.Feature_Panel, Row);
               return;
            end if;
         end loop;
         Fail ("Build UI smoke could not select diagnostic item"
               & Natural'Image (Natural (Item_Index)));
      end Select_Diagnostic_Item;

      function Latest_Message return String is
         Found : Boolean := False;
         Message : constant Editor.Messages.Editor_Message :=
           Editor.Messages.Active_Message (S.Messages, Found);
      begin
         if Found then
            return Editor.Messages.Text (Message);
         end if;
         return "";
      end Latest_Message;

   begin
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_UI_Show);
      Check (S.Build_UI.Build_UI_Visible,
             "Build UI show command did not make Build Output visible");

      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Check (not Snapshot.Run_Available
             and then To_String (Snapshot.Run_Recovery_Hint) =
               "Refresh build candidates and select one",
             "Build UI did not expose missing-candidate recovery guidance");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Build_Refresh_Candidates);
      Check
        (S.Build_UI.Candidate_Refresh_Status =
           Editor.Build_UI.Build_Candidate_Refresh_Succeeded
         and then S.Build_UI.Last_Refresh_Candidate_Count > 0,
         "Build UI refresh did not discover the smoke project candidate");
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Check (not Snapshot.Run_Available
             and then Snapshot.Candidate_Count > 0,
             "Build UI refresh should expose candidates without auto-selecting");
      Check (To_String (Snapshot.Candidate_Refresh_Action_Label) =
               "Select a build candidate",
             "Build UI refresh did not expose the select-candidate next action");
      Check (To_String (Snapshot.Candidate_Refresh_Action_Command_Name) =
               "build.select-next-candidate",
             "Build UI refresh did not expose the select-candidate command name");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Build_Select_First_Candidate);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Check (Editor.Build_UI.Validate_Build_UI_State (S.Build_UI) =
               Editor.Build_UI.Build_UI_Rejected_Missing_Consent,
             "Build candidate selection did not require explicit consent");
      Check (To_String (Snapshot.Run_Recovery_Hint) =
               "Review the request and acknowledge consent",
             "Build UI did not expose consent recovery guidance");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Build_Acknowledge_Consent);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Check (Editor.Build_UI.Validate_Build_UI_State (S.Build_UI) =
               Editor.Build_UI.Build_UI_Valid,
             "Build UI did not become runnable after consent: "
             & Editor.Build_UI.Validation_Message
                 (Editor.Build_UI.Validate_Build_UI_State (S.Build_UI)));
      Check (To_String (Snapshot.Run_Recovery_Hint) = "Run build",
             "Build UI did not expose runnable recovery guidance after consent");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Build_Cancel);
      Check (S.Build_UI.Build_UI_Visible,
             "Build cancel command should not hide Build Output");

      Editor.State.Load_Text
        (S,
         "procedure Smoke_Direct is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Smoke_Direct;" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing semicolon",
         Source_Label  => "build ui direct quick fix",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 8,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";",
         Quick_Fix_Label   => "Insert semicolon",
         Quick_Fix_Detail  => "Append statement delimiter");
      Direct_Diagnostic_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Select_Diagnostic_Item (Positive (Direct_Diagnostic_Index));
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Check
        (Snapshot.Diagnostics_View.Quick_Fix_Available,
         "Build UI direct quick-fix smoke did not expose an available quick fix");
      Direct_Quick_Fix :=
        Editor.Build_UI_Actions.Build_UI_Apply_Diagnostic_Quick_Fix
          (S, Action_Index => 1, Diagnostic_Index => Direct_Diagnostic_Index);
      Check
        (Direct_Quick_Fix.Status =
           Editor.Command_Execution.Command_Executed
         and then Ada.Strings.Fixed.Index
           (Editor.State.Current_Text (S), "null;") > 0,
         "Build UI direct quick-fix smoke did not apply the selected edit");

      Editor.State.Load_Text
        (S,
         "procedure Smoke_Keyboard is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Smoke_Keyboard;" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "missing semicolon via keyboard",
         Source_Label  => "build ui keyboard quick fix",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 8,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";",
         Quick_Fix_Label   => "Insert semicolon with keyboard",
         Quick_Fix_Detail  => "Append statement delimiter");
      Keyboard_Diagnostic_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Select_Diagnostic_Item (Positive (Keyboard_Diagnostic_Index));
      Editor.Build_UI_Actions.Focus_Build_UI (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Keyboard_Quick_Fix_Row :=
        Editor.Build_UI.Find_Action_Row
          (Snapshot,
           "ada.diagnostic.apply-quick-fix",
           Diagnostic_Index => Keyboard_Diagnostic_Index,
           Quick_Fix_Action_Index => 1);
      Check (Keyboard_Quick_Fix_Row > 0,
             "Build UI keyboard quick-fix smoke did not expose the action row");
      Editor.Build_UI.Set_Selected_Action_Row
        (S.Build_UI,
         Keyboard_Quick_Fix_Row,
         Natural (Snapshot.Actions.Length));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        ((Key       => Editor.Keybindings.Key_Enter,
          Modifiers => (others => False)));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Check
        (Ada.Strings.Fixed.Index (Editor.State.Current_Text (S), "null;") > 0,
         "Build UI keyboard quick-fix smoke did not apply the selected edit");

      Editor.State.Load_Text
        (S,
         "procedure Smoke_Disabled is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Smoke_Disabled;" & ASCII.LF);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "disabled quick fix via keyboard",
         Source_Label  => "build ui disabled keyboard quick fix",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 8,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";",
         Quick_Fix_Label   => "Insert semicolon with keyboard",
         Quick_Fix_Detail  => "Append statement delimiter");
      Disabled_Diagnostic_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Unavailable
        (S.Feature_Diagnostics,
         Positive (Disabled_Diagnostic_Index),
         Label  => "Unavailable quick fix",
         Detail => "No edit or command");
      Select_Diagnostic_Item (Positive (Disabled_Diagnostic_Index));
      Editor.Build_UI_Actions.Focus_Build_UI (S);
      Snapshot := Editor.Build_UI_Actions.Build_UI_Operability_Snapshot (S);
      Disabled_Quick_Fix_Row :=
        Editor.Build_UI.Find_Action_Row
          (Snapshot,
           "ada.diagnostic.apply-quick-fix",
           Diagnostic_Index => Disabled_Diagnostic_Index,
           Quick_Fix_Action_Index => 2);
      Check (Disabled_Quick_Fix_Row > 0,
             "Build UI disabled quick-fix smoke did not expose the inert row");
      Check (not Snapshot.Actions.Element (Disabled_Quick_Fix_Row - 1).Enabled,
             "Build UI disabled quick-fix smoke row should be disabled");
      Editor.Build_UI.Set_Selected_Action_Row
        (S.Build_UI,
         Disabled_Quick_Fix_Row,
         Natural (Snapshot.Actions.Length));
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Handle_Key_Chord
        ((Key       => Editor.Keybindings.Key_Enter,
          Modifiers => (others => False)));
      S := Editor.Input_Bridge.Get_State_For_Test;
      Check
        (Ada.Strings.Fixed.Index (Editor.State.Current_Text (S), "null;") = 0,
         "Build UI disabled quick-fix Enter must not mutate text");
      Check
        (Latest_Message = "Quick fix action has no valid edit or command",
         "Build UI disabled quick-fix Enter reports disabled reason");

      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Finish ("build_ui_interaction", "build UI interaction");
   end Run_Build_UI_Interaction_Scenario;

   procedure Run_Command_Palette_Ranking_Scenario is
      procedure Execute_First_Query
        (Query    : String;
         Expected : Editor.Commands.Command_Id)
      is
         Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Open;
         Editor.Command_Palette.Insert_Text (Query);
         Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
         Check (Natural (Candidates.Length) > 0,
                "command palette execution query produced no candidates: " & Query);
         Check (Candidates.Element (0).Id = Expected,
                "command palette execution query selected wrong command: " & Query);
         Editor.Executor.Execute_Command (S, Candidates.Element (0).Id);
      end Execute_First_Query;

      procedure Check_Query
        (Query    : String;
         Expected : Editor.Commands.Command_Id)
      is
         Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      begin
         Editor.Command_Palette.Reset;
         Editor.Command_Palette.Open;
         Editor.Command_Palette.Insert_Text (Query);
         Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
         Check (Natural (Candidates.Length) > 0,
                "command palette query produced no candidates: " & Query);
         Check (Candidates.Element (0).Id = Expected,
                "command palette query ranked wrong command first: " & Query);
         Editor.Command_Palette.Reset;
      end Check_Query;
   begin
      Check_Query ("open", Editor.Commands.Command_Open_Project);
      Check_Query ("save", Editor.Commands.Command_Save_File);
      Check_Query ("file", Editor.Commands.Command_Open_Quick_Open);
      Check_Query ("build", Editor.Commands.Command_Build_Run);
      Check_Query ("search", Editor.Commands.Command_Open_Project_Search_Bar);
      Check_Query ("outline", Editor.Commands.Command_Refresh_Outline);
      Check_Query ("diagnostics", Editor.Commands.Command_Diagnostics_Show);
      Check_Query ("navigation", Editor.Commands.Command_Navigation_Back);
      Check_Query ("workspace", Editor.Commands.Command_Save_Workspace_State);
      Check_Query ("settings", Editor.Commands.Command_Reset_Settings_To_Defaults);
      Check_Query ("run tests", Editor.Commands.Command_Run_Tests);
      Check_Query ("compile", Editor.Commands.Command_Build_Run);
      Check_Query ("make", Editor.Commands.Command_Build_Run);
      Check_Query ("open file", Editor.Commands.Command_Open_Quick_Open);
      Check_Query ("show diagnostics", Editor.Commands.Command_Diagnostics_Show);
      Check_Query ("issues", Editor.Commands.Command_Diagnostics_Show);
      Check_Query ("filter errors", Editor.Commands.Command_Problems_Filter_Errors);
      Check_Query ("sort problems", Editor.Commands.Command_Problems_Sort_By_Severity);
      Check_Query ("group problems", Editor.Commands.Command_Problems_Group_By_Source);
      Check_Query ("refresh project", Editor.Commands.Command_Refresh_File_Tree);
      Check_Query ("restore workspace", Editor.Commands.Command_Restore_Workspace_State);
      Check_Query ("open session", Editor.Commands.Command_Restore_Workspace_State);

      Execute_First_Query ("diagnostics", Editor.Commands.Command_Diagnostics_Show);
      Check
        (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
         Editor.Feature_Panel.Diagnostics_Feature,
         "command palette diagnostics candidate did not execute");
      Editor.Command_Palette.Reset;

      Execute_First_Query
        ("command", Editor.Commands.Command_Palette_Show_Command_Help);
      Check
        (Editor.Command_Palette.Current_Config.Show_Help_Row,
         "command palette help candidate did not execute");
      Editor.Command_Palette.Reset;

      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Write_Report
        ("command_palette_ranking=confirmed" & ASCII.LF
         & "command_palette_execution=confirmed" & ASCII.LF);
      Ada.Text_IO.Put_Line
        ("editor_product_smoke: behavior command palette ranking confirmed");
      Ada.Text_IO.Put_Line
        ("editor_product_smoke: behavior command palette execution confirmed");
      Ada.Text_IO.Put_Line ("editor_product_smoke: PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Run_Command_Palette_Ranking_Scenario;

   procedure Confirm_Clear_Workspace_State is
   begin
      Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
      Check (Ada.Directories.Exists (Session_Path),
             "clear workspace state must require confirmation before deleting");
      Check
        (Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions) =
           Editor.Pending_Transitions.Pending_Clear_Workspace_State,
         "clear workspace state did not stage a destructive confirmation");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Retry_Pending_Transition);
      Check (not Ada.Directories.Exists (Session_Path),
             "confirmed clear workspace state did not delete the session file");
   end Confirm_Clear_Workspace_State;

   procedure Assert_Render_Packet_Nonempty is
   begin
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Check (Natural (Packet.Rect_Count) <= Editor.Render_Packet.Max_Rectangles,
             "render packet rectangle count exceeded the ABI maximum");
      Check (Natural (Packet.Glyph_Count) <= Editor.Render_Packet.Max_Glyphs,
             "render packet glyph count exceeded the ABI maximum");
      Check (Natural (Packet.Rect_Count) + Natural (Packet.Glyph_Count) > 0,
             "render packet was empty after product workflow");
   end Assert_Render_Packet_Nonempty;

   procedure Save_Restore_Clear_Workspace_State is
   begin
      Editor.Executor.Workspace_Commands.Execute_Save_Workspace_State (S);
      Check (Ada.Directories.Exists (Session_Path),
             "save workspace state did not create the session file");
      Editor.Executor.Workspace_Commands.Execute_Restore_Workspace_State (S);
      Check (S.Post_Restore_Feedback_Current
             and then S.Last_Restore_Summary_Available,
             "restore workspace state did not expose current restore details");
      Confirm_Clear_Workspace_State;
   end Save_Restore_Clear_Workspace_State;

   procedure Assert_Workspace_Persistence_Roundtrip
     (Cursor_Row    : Natural;
      Cursor_Column : Natural;
      View_First_Row : Natural)
   is
   begin
      Editor.Workspace_Persistence.Clear (Workspace);
      Editor.Workspace_Persistence.Set_Project_Root (Workspace, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Workspace,
         (Path => To_Unbounded_String ("src/smoke_unit.adb"),
          Is_Project_Relative => True,
          Cursor_Row => Cursor_Row,
          Cursor_Column => Cursor_Column,
          View_First_Row => View_First_Row));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Workspace, "src/smoke_unit.adb", True);
      Editor.Workspace_Persistence.Save_To_File
        (Workspace, Workspace_Path, Persist_Status);
      Check (Persist_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
             "workspace save failed");
      Editor.Workspace_Persistence.Load_From_File
        (Workspace_Path, Loaded, Persist_Status);
      Check (Persist_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
             "workspace reload failed");
      Check (Editor.Workspace_Persistence.Has_Project_Root (Loaded)
             and then Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1
             and then Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
             "workspace reload did not restore project/open/active file state");
      Check (Ada.Strings.Fixed.Index (Read_File (Workspace_Path), "E2E_Token") = 0,
             "workspace persistence leaked source text");
   end Assert_Workspace_Persistence_Roundtrip;

   procedure Run_Workspace_Session_Scenario is
   begin
      Save_Restore_Clear_Workspace_State;
      Assert_Workspace_Persistence_Roundtrip
        (Cursor_Row => 0, Cursor_Column => 0, View_First_Row => 0);
      Remove_Tree_If_Exists (Root);
      Write_Report
        ("workspace_save_restore_clear=confirmed" & ASCII.LF &
         "workspace_persistence_roundtrip=confirmed" & ASCII.LF);
      Ada.Text_IO.Put_Line
        ("editor_product_smoke: behavior workspace save/restore/clear confirmed");
      Ada.Text_IO.Put_Line
        ("editor_product_smoke: behavior workspace persistence roundtrip confirmed");
      Ada.Text_IO.Put_Line ("editor_product_smoke: PASS");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end Run_Workspace_Session_Scenario;

   procedure Run_Render_Packet_Scenario is
   begin
      Assert_Render_Packet_Nonempty;
      Remove_Tree_If_Exists (Root);
      Finish ("render_packet_nonempty", "render packet nonempty");
   end Run_Render_Packet_Scenario;

   procedure Run_Quick_Open_File_Tree_Scenario is
   begin
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "main.adb");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.File_Tree, (others => <>));
      Check (Editor.Quick_Open.Result_Count (S.Quick_Open) >= 1,
             "Quick Open did not find main.adb");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Accept_Quick_Open);
      Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Main_Path,
             "Quick Open activation did not open main.adb");
      Check (Editor.Focus_Management.Effective_Focus_Owner (S) =
               Editor.Focus_Management.Focus_Editor,
             "Quick Open activation did not return focus to editor");

      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Node := Editor.File_Tree.Find_By_Path
        (S.File_Tree, "src/smoke_unit.adb", Found);
      Check (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
             "file tree did not discover smoke_unit.adb");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Found);
      Check (Found and then Row > 0,
             "file tree node did not map to a selectable row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_File_Tree);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Tree_Open_Selected);
      Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
             "file tree activation did not open the expected buffer");
      Unit_Token := S.Active_Buffer_Token;
      Check (Editor.Focus_Management.Effective_Focus_Owner (S) =
               Editor.Focus_Management.Focus_Editor,
             "file tree activation did not return focus to editor");
   end Run_Quick_Open_File_Tree_Scenario;

   procedure Run_Edit_Save_Scenario is
   begin
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Check (S.File_Info.Dirty, "editing did not mark the file dirty");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Check (not S.File_Info.Dirty, "save did not clear dirty state");
      Check (Ada.Strings.Fixed.Index (Read_File (Unit_Path), "E2E_Token") > 0,
             "saved file no longer contains the expected token");
   end Run_Edit_Save_Scenario;

   procedure Run_Daily_Editing_Scenario is
   begin
      Run_Quick_Open_File_Tree_Scenario;
      Run_Edit_Save_Scenario;

      Editor.Project_Search.Set_Query (S.Project_Search, "E2E_Token");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.File_Tree, S.Project, (others => <>));
      Check (Editor.Project_Search.Status (S.Project_Search) =
               Editor.Project_Search.Project_Search_Ok
             and then Editor.Project_Search.Result_Count (S.Project_Search) >= 1,
             "daily editing search did not find the fixture token");
      Search_Result := Editor.Project_Search.Selected_Result
        (S.Project_Search, Found);
      Check (Found, "daily editing search did not select a result");

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Warning,
         Message       => "daily editing diagnostic",
         Source_Label  => "src/smoke_unit.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Unit_Token,
         Target_Line   => 4,
         Target_Column => 7);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Show);
      Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
      Check (Editor.Feature_Panel.Row_Count (S.Feature_Panel) >= 1,
             "daily editing diagnostic did not project into Diagnostics");
      Target_Row_Selected := False;
      for I in 1 .. Editor.Feature_Panel.Row_Count (S.Feature_Panel) loop
         if Editor.Feature_Panel.Row_Has_Target (S.Feature_Panel, Positive (I)) then
            Editor.Feature_Panel.Select_Row (S.Feature_Panel, I);
            Target_Row_Selected := True;
            Editor.Executor.Execute_Command
              (S, Editor.Commands.Command_Diagnostics_Open_Selected);
            exit when S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Unit_Path;
         end if;
      end loop;
      Check (Target_Row_Selected,
             "daily editing diagnostic projection did not expose a target row");
      Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
             "daily editing diagnostic did not navigate to smoke_unit.adb; active="
             & (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "<none>")
             & "; reason="
             & Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
                 (S.Feature_Diagnostics, S.Feature_Panel));

      Assert_Workspace_Persistence_Roundtrip
        (Cursor_Row => Search_Result.Row,
         Cursor_Column => Search_Result.Match_Column,
         View_First_Row => 1);
      Assert_Render_Packet_Nonempty;

      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Finish ("daily_editing_workflow", "daily editing workflow");
   end Run_Daily_Editing_Scenario;

   procedure Check_Pending
     (Expected    : Editor.Pending_Transitions.Pending_Transition_Kind;
      Needs_Path  : Boolean;
      Needs_Buffer : Boolean)
   is
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Audit : constant Editor.Pending_Transitions.Pending_Transition_Boundary_Audit :=
        Editor.Pending_Transitions.Audit_Pending_Transition_Boundary
          (S.Pending_Transitions);
   begin
      Check (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
             "dirty lifecycle command did not stage a pending transition");
      Check (Target.Kind = Expected,
             "dirty lifecycle command staged the wrong transition kind: expected "
             & Editor.Pending_Transitions.Pending_Transition_Kind'Image (Expected)
             & ", got "
             & Editor.Pending_Transitions.Pending_Transition_Kind'Image
                 (Target.Kind));
      Check (Audit.Boundary_Safe,
             "dirty lifecycle pending transition boundary audit failed");
      Check (Audit.Pending_Target_Revalidation_Required,
             "dirty lifecycle pending transition does not require revalidation");
      Check (Audit.Pending_Target_Has_Revalidation_Key,
             "dirty lifecycle pending transition has no revalidation key");
      Check (Target.Has_Path = Needs_Path,
             "dirty lifecycle pending path metadata mismatch");
      Check (Target.Has_Buffer = Needs_Buffer,
             "dirty lifecycle pending buffer metadata mismatch");
   end Check_Pending;

   procedure Run_Dirty_Lifecycle_Persistence_Scenario is
   begin
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Unit_Path);
      Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
             "dirty lifecycle smoke did not open smoke_unit.adb");
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Check (S.File_Info.Dirty,
             "dirty lifecycle smoke edit did not mark the file dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Check_Pending
        (Editor.Pending_Transitions.Pending_Reload_Active_Buffer,
         Needs_Path   => True,
         Needs_Buffer => True);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Check_Pending
        (Editor.Pending_Transitions.Pending_Revert_Active_Buffer,
         Needs_Path   => True,
         Needs_Buffer => True);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Other_Root);
      Check_Pending
        (Editor.Pending_Transitions.Pending_Open_Project,
         Needs_Path   => True,
         Needs_Buffer => False);

      Editor.Executor.Workspace_Commands.Execute_Save_Workspace_State (S);
      Check (Ada.Directories.Exists (Session_Path),
             "dirty lifecycle smoke did not create a session file");
      Check (Ada.Strings.Fixed.Index (Read_File (Session_Path), "Pending_") = 0,
             "workspace persistence stored transient pending transition state");
      Check (Ada.Strings.Fixed.Index (Read_File (Session_Path), "E2E_Token") = 0,
             "workspace persistence leaked source text while dirty transition pending");

      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Finish
        ("dirty_lifecycle_persistence",
         "dirty lifecycle persistence");
   end Run_Dirty_Lifecycle_Persistence_Scenario;

begin
   Check
     (Scenario = "all"
      or else Scenario = "quick_open_file_tree"
      or else Scenario = "edit_save"
      or else Scenario = "daily_editing"
      or else Scenario = "workspace_session"
      or else Scenario = "dirty_lifecycle_persistence"
      or else Scenario = "build_ui_interaction"
      or else Scenario = "command_palette_ranking"
      or else Scenario = "diagnostic_quick_fix"
      or else Scenario = "diagnostics_problems"
      or else Scenario = "build_diagnostics"
      or else Scenario = "render_packet",
      "unknown product smoke scenario: " & Scenario);

   Build_Fixture;
   Editor.Buffers.Reset_Global_For_Test;
   Editor.State.Init (S);

   Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
   Check (Editor.Project.Has_Project (S.Project),
          "project open did not retain a project root");

   Editor.Project.Refresh_Known_Files (S.Project, Refresh);
   Check (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
          "project file refresh failed");
   Check (Editor.Project.Has_Known_File (S.Project, "src/smoke_unit.adb"),
          "project file index does not include smoke_unit.adb");

   if Focused ("workspace_session") then
      Run_Workspace_Session_Scenario;
      return;
   end if;

   if Focused ("dirty_lifecycle_persistence") then
      Run_Dirty_Lifecycle_Persistence_Scenario;
      return;
   end if;

   if Focused ("render_packet") then
      Run_Render_Packet_Scenario;
      return;
   end if;

   if Focused ("daily_editing") then
      Run_Daily_Editing_Scenario;
      return;
   end if;

   if Focused ("build_ui_interaction") then
      Run_Build_UI_Interaction_Scenario;
      return;
   end if;

   if Focused ("command_palette_ranking") then
      Run_Command_Palette_Ranking_Scenario;
      return;
   end if;

   Run_Quick_Open_File_Tree_Scenario;

   if Focused ("quick_open_file_tree") then
      Remove_Tree_If_Exists (Root);
      Finish ("quick_open_file_tree_navigation", "quick-open file-tree navigation");
      return;
   end if;

   Run_Edit_Save_Scenario;

   if Focused ("edit_save") then
      Remove_Tree_If_Exists (Root);
      Finish ("editing_save_conflict_free", "editing save");
      return;
   end if;

   Save_Restore_Clear_Workspace_State;

   Editor.Executor.File_Open_Commands.Execute_Open_File (S, Demo_Path);
   Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Demo_Path,
          "direct open did not activate the outline smoke fixture");
   Check (not S.File_Info.Dirty,
          "opening outline smoke fixture should start clean");
   declare
      Text_Before_Outline : constant String := Editor.State.Current_Text (S);
      Token_A             : constant Natural := S.Active_Buffer_Token;
      Revision_A          : constant Natural := Editor.State.Current_Buffer_Revision (S);
      Row                 : Natural := 0;
      Col                 : Natural := 0;
   begin
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Check (Editor.Outline.Item_Count (S.Outline) >= 3,
             "outline.refresh returned no real Ada declaration rows");
      Check (Editor.Outline.Is_Current_For_Buffer (S.Outline, Token_A, Revision_A),
             "outline is not current for the refreshed source buffer");
      Check (Editor.State.Current_Text (S) = Text_Before_Outline,
             "outline.refresh mutated buffer text");
      Check (not S.File_Info.Dirty,
             "outline.refresh changed clean dirty state");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 0 and then Col = 0,
             "opening package outline row did not move caret to package declaration");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 1,
             "opening type outline row did not move caret to type declaration");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Selected_Outline_Item);
      Editor.State.Row_Col_For_Index
        (S, S.Carets (S.Carets.First_Index).Pos, Row, Col);
      Check (Row = 3,
             "opening procedure outline row did not move caret to procedure declaration");
      Check (Editor.State.Current_Text (S) = Text_Before_Outline,
             "outline navigation mutated buffer text");
      Check (not S.File_Info.Dirty,
             "outline navigation changed clean dirty state");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Editor.State.Current_Text (S)'Length, ' '));
      Check (S.File_Info.Dirty,
             "outline smoke edit did not mark demo buffer dirty");
      Check (not Editor.Outline.Is_Current_For_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)),
             "edited buffer still reports outline current");
      Check (Editor.Outline.Freshness_For_Active_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)) =
             Editor.Outline.Outline_Stale,
             "edited buffer did not mark outline stale");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Check (Editor.Outline.Is_Current_For_Buffer
               (S.Outline, Token_A, Editor.State.Current_Buffer_Revision (S)),
             "outline.refresh did not make edited buffer current again");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Check (not S.File_Info.Dirty,
             "saving outline smoke fixture did not clear dirty state");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Unit_Path);
      Check (not Editor.Outline.Is_Current_For_Buffer
               (S.Outline, S.Active_Buffer_Token, Editor.State.Current_Buffer_Revision (S)),
             "outline falsely reports current after switching buffers");
   end;

   Editor.Project_Search.Set_Query (S.Project_Search, "E2E_Token");
   Editor.Project_Search.Search_Known_Project_Files
     (S.Project_Search, S.File_Tree, S.Project, (others => <>));
   Check (Editor.Project_Search.Status (S.Project_Search) =
            Editor.Project_Search.Project_Search_Ok
          and then Editor.Project_Search.Result_Count (S.Project_Search) >= 1,
          "project search did not find the fixture token");
   Search_Result := Editor.Project_Search.Selected_Result
     (S.Project_Search, Found);
   Check (Found, "project search did not select the first fixture result");

   Build_Context.Has_Request := True;
   Build_Context.Request := Smoke_Request;
   Build_Context.Gate := Editor.External_Producers.Build_Real_Execution_Gate
     (Allow_Diagnostics_Ingestion => True,
      Show_Diagnostics            => True,
      Consent                     => Editor.External_Producers.Build_Consent_User_Confirmed);
   Supplied_Process := Editor.External_Producers.Build_Process_Run_Result
     (Status        => Editor.External_Producers.Process_Run_Failed,
      Exit_Code     => 1,
      Has_Exit_Code => True,
      Stdout_Text   => "smoke build stdout",
      Stderr_Text   => "smoke_unit.adb:4:7: error: smoke diagnostic" & ASCII.LF);
   Build_Result := Editor.Executor.Execute_User_Opt_In_Build_Command
     (S, Build_Context, Supplied_Process);
   Check (Build_Result.Build_Result.Status =
            Editor.External_Producers.Build_Run_Failed,
          "build command did not publish the supplied failure result");
   Check (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) >= 1,
          "build diagnostic output was not ingested into Diagnostics");
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Severity      => Editor.Feature_Diagnostics.Diagnostic_Error,
         Message       => "smoke diagnostic target",
         Source_Label  => "src/smoke_unit.adb",
         Source_Kind   => Editor.Feature_Diagnostics.External_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Unit_Token,
         Target_Line   => 4,
         Target_Column => 7,
         Has_Edit          => True,
         Edit_Start_Line   => 4,
         Edit_Start_Column => 12,
         Edit_End_Line     => 4,
         Edit_End_Column   => 12,
         Replacement_Text  => " -- quickfix",
         Quick_Fix_Label   => "Annotate null statement",
         Quick_Fix_Detail  => "Insert quick-fix smoke marker");
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Command
        (S.Feature_Diagnostics,
         Positive (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics)),
         Label  => "Explain quick-fix smoke diagnostic",
         Detail => "Open diagnostic explanation",
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);
   Editor.Executor.Execute_Command (S, Editor.Commands.Command_Diagnostics_Show);
   Check (Editor.Focus_Management.Effective_Focus_Owner (S) =
            Editor.Focus_Management.Focus_Diagnostics,
          "Diagnostics show did not focus the Diagnostics panel");
   Editor.Feature_Diagnostics.Project_Rows (S.Feature_Diagnostics, S.Feature_Panel);
   for I in 1 .. Editor.Feature_Panel.Row_Count (S.Feature_Panel) loop
      if Editor.Feature_Panel.Row_Has_Target (S.Feature_Panel, Positive (I)) then
         Editor.Feature_Panel.Select_Row (S.Feature_Panel, I);
         Target_Row_Selected := True;
      end if;
   end loop;
   Check (Target_Row_Selected
          and then Editor.Feature_Diagnostics.Has_Selected_Diagnostic
            (S.Feature_Diagnostics, S.Feature_Panel),
          "Diagnostics projection did not include a selectable target row");
   Check
     (Editor.Feature_Diagnostics.Item_Quick_Fix_Label
        (S.Feature_Diagnostics,
         Positive
           (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics))) =
      "Annotate null statement",
      "Diagnostics quick-fix label did not survive projection");
   Editor.Feature_Panel.Select_Row
     (S.Feature_Panel, Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics));
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
   if Ada.Strings.Fixed.Index
        (Editor.State.Current_Text
           (Editor.Buffers.Global_Buffer
              (Editor.Buffers.Buffer_Id (Unit_Token))),
         "null; -- quickfix") = 0
   then
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
   end if;
   Check
     (Ada.Strings.Fixed.Index
        (Editor.State.Current_Text
           (Editor.Buffers.Global_Buffer
              (Editor.Buffers.Buffer_Id (Unit_Token))),
         "null; -- quickfix") > 0,
      "Diagnostics quick-fix action did not update the target buffer");
   if Focused ("diagnostic_quick_fix") then
      Remove_Tree_If_Exists (Root);
      Finish ("diagnostic_quick_fix", "diagnostic quick-fix workflow");
      return;
   end if;
   Editor.Diagnostics.Add
     (S.Diagnostics, Start_Index => 0, End_Index => 1,
      Start_Row => 0, Start_Column => 0,
      Severity => Editor.Diagnostics.Warning,
      Message => "smoke warning");
   Editor.Diagnostics.Add
     (S.Diagnostics, Start_Index => 2, End_Index => 3,
      Start_Row => 1, Start_Column => 0,
      Severity => Editor.Diagnostics.Error,
      Message => "smoke error");
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_Problems_Filter_Errors);
   Check
     (Editor.Problems.Severity_Filter (S.Problems_View) =
      Editor.Problems.Problems_Show_Errors,
      "Problems filter command did not select errors");
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_Problems_Open_Selected);
   Check
     (S.Active_Diagnostic.Has_Active and then S.Active_Diagnostic.Index = 2,
      "Problems open-selected did not open the filtered error row");
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_Problems_Filter_All);
   Check
     (Editor.Problems.Severity_Filter (S.Problems_View) =
      Editor.Problems.Problems_Show_All,
      "Problems filter command did not clear the severity filter");
   declare
      Panel : Editor.Layout.Rect;
      Click : Editor.Commands.Command :=
        (Kind    => Editor.Commands.Move_To_Point,
         Click_X => 0,
         Click_Y => 0,
         others  => <>);
   begin
      Editor.Panels.Set_Bottom_Content
        (S.Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Visible
        (S.Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Set_Current_Size
        (S.Panels, Editor.Panels.Bottom_Panel, 6);
      Editor.Panels.Set_Current (S.Panels);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Focus_Problems);
      Editor.Command_Palette.Reset;
      Editor.Input_Bridge.Reset;
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.View.Set_Viewport (Width => 800, Height => 480);

      Panel := Editor.Layout.Panel_Rect
        (Editor.Layout.Current,
         Editor.Panels.Bottom_Panel,
         Editor.View.Viewport_Width,
         Editor.View.Viewport_Height);
      Click.Click_Y := Natural (Panel.Y) + Editor.Layout.Cell_H - 1;

      Click.Click_X := Natural (Panel.X) + Editor.Layout.Cell_W;
      Check
        (Editor.Problems.Header_Action_At_X
           (Panel.Width, Click.Click_X - Natural (Panel.X)) =
         Editor.Problems.Problems_Header_Filter_Action,
         "Problems header left zone did not map to filter");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_Errors);
      Check
        (Editor.Problems.Severity_Filter (S.Problems_View) =
         Editor.Problems.Problems_Show_Errors,
         "Problems header filter zone did not toggle errors");

      Click.Click_X := Natural (Panel.X) + Panel.Width / 2;
      Check
        (Editor.Problems.Header_Action_At_X
           (Panel.Width, Click.Click_X - Natural (Panel.X)) =
         Editor.Problems.Problems_Header_Sort_Action,
         "Problems header middle zone did not map to sort");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Sort_By_Severity);
      Check
        (S.Problems_View.Sort_Mode =
         Editor.Problems.Problems_Sort_By_Severity,
         "Problems header sort zone did not cycle sort mode");

      Click.Click_X := Natural (Panel.X) + Panel.Width - Editor.Layout.Cell_W;
      Check
        (Editor.Problems.Header_Action_At_X
           (Panel.Width, Click.Click_X - Natural (Panel.X)) =
         Editor.Problems.Problems_Header_Group_Action,
         "Problems header right zone did not map to group");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Group_By_Source);
      Check
        (S.Problems_View.Group_Mode =
         Editor.Problems.Problems_Group_By_Source,
         "Problems header group zone did not cycle grouping");
   end;
   if Focused ("diagnostics_problems") then
      Remove_Tree_If_Exists (Root);
      Finish ("diagnostics_problems_filters", "diagnostics Problems filters");
      return;
   end if;
   Editor.Navigation_History.Clear (S.Navigation_History);
   Editor.Navigation_History.Record_Explicit_Navigation
     (S.Navigation_History,
      (Buffer_Id     => S.Active_Buffer_Token,
       Has_File_Path => S.File_Info.Has_Path,
       File_Path     => S.File_Info.Path,
       Display_Path  => To_Unbounded_String ("src/main.adb"),
       Line          => 1,
       Column        => 0,
       Viewport_Row  => 0,
       Reason        => Editor.Navigation_History.Navigation_Reason_Feature_Panel));
   Editor.Executor.Execute_Command
     (S, Editor.Commands.Command_Diagnostics_Open_Selected);
   Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
          "Diagnostics open-selected did not open the diagnostic source target; active="
          & (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "<none>")
          & "; reason="
          & Editor.Feature_Diagnostics.Selected_Diagnostic_Open_Unavailable_Reason
              (S.Feature_Diagnostics, S.Feature_Panel));
   Check (Editor.Navigation_History.Back_Count (S.Navigation_History) > 0,
          "Diagnostics navigation did not record a back target");
   Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Back);
   Check (S.File_Info.Has_Path,
          "navigation back after Diagnostics did not retain a file-backed target");
   Check (Editor.Navigation_History.Forward_Count (S.Navigation_History) > 0,
          "navigation back after Diagnostics did not record a forward target");
   Editor.Executor.Execute_Command (S, Editor.Commands.Command_Navigation_Forward);
   Check (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Unit_Path,
          "navigation forward after Diagnostics did not return to the diagnostic target");

   Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Command_Palette);
   Check (Editor.Command_Palette.Is_Open,
          "command palette command did not open the palette");
   Editor.Command_Palette.Close;

   if Focused ("build_diagnostics") then
      Remove_Tree_If_Exists (Root);
      Finish ("build_diagnostics_navigation", "build diagnostics navigation");
      return;
   end if;

   Assert_Workspace_Persistence_Roundtrip
     (Cursor_Row => Search_Result.Row,
      Cursor_Column => Search_Result.Match_Column,
      View_First_Row => 1);

   Assert_Render_Packet_Nonempty;

   Remove_Tree_If_Exists (Root);
   Remove_Tree_If_Exists (Other_Root);
   Write_File
     (Report_Path,
      "workspace_save_restore_clear=confirmed" & ASCII.LF &
      "quick_open_file_tree_navigation=confirmed" & ASCII.LF &
      "editing_save_conflict_free=confirmed" & ASCII.LF &
      "diagnostics_problems_filters=confirmed" & ASCII.LF &
      "build_diagnostics_navigation=confirmed" & ASCII.LF &
      "navigation_forward_roundtrip=confirmed" & ASCII.LF &
      "command_palette_open=confirmed" & ASCII.LF &
      "workspace_persistence_roundtrip=confirmed" & ASCII.LF &
      "render_packet_nonempty=confirmed" & ASCII.LF);
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior workspace save/restore/clear confirmed");
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior quick-open file-tree navigation confirmed");
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior editing save confirmed");
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior build diagnostics navigation confirmed");
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior workspace persistence roundtrip confirmed");
   Ada.Text_IO.Put_Line
     ("editor_product_smoke: behavior render packet nonempty confirmed");
   Ada.Text_IO.Put_Line ("editor_product_smoke: PASS");
   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
exception
   when E : others =>
      Remove_Tree_If_Exists (Root);
      Remove_Tree_If_Exists (Other_Root);
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "editor_product_smoke: FAIL: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Editor_Product_Smoke;
