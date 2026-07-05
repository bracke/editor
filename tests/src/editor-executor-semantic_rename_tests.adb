with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Files;
with Editor.Guided_Prompts;
with Editor.Input_Bridge;
with Editor.Outline;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.State;

package body Editor.Executor.Semantic_Rename_Tests is

   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Ada_Language_Service.Semantic_Request_Kind;
   use type Editor.Ada_Language_Service.Semantic_Request_Status_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Feature_Search_Results.External_Result_Set_Kind;
   use type Editor.Files.File_Open_Status;
   use type Editor.Guided_Prompts.Prompt_Kind;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;

   overriding function Name
     (T : Semantic_Rename_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Semantic_Rename_Tests");
   end Name;


   procedure Test_Semantic_Rename_Preview_Projects_Search_Result_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 6));
      Ignored := LM.Add_Symbol
        (Analysis, "Run_Renamed", LM.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 14));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Preview);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic rename preview is available when the index can answer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Preview);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename preview executes even when conflicts are projected");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Rename
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "semantic rename preview execution records a completed request");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 3,
              "semantic rename preview projects edit and conflict rows");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "rename: Run -> Run_Renamed",
              "semantic rename preview labels the Search Results query");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "open-buffer semantic rename row is navigable");
      Assert (Editor.Feature_Search_Results.Item_Target_Buffer
                (S.Feature_Search_Results, 1) = S.Active_Buffer_Token,
              "semantic rename row targets the live buffer token");
      Assert (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "semantic rename preview shows the Search Results panel");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "semantic rename preview selects the first projected row");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Preview_Projects_Search_Result_Rows;

   procedure Test_Semantic_Rename_Apply_Updates_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename-apply fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Apply);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic rename apply is available for conflict-free active-buffer edits");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Apply);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename apply executes through command surface");
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Run_Renamed" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic rename apply mutates the active buffer text");
      Assert (Latest_Message_Text (S) =
              "Rename applied for Run: 1 edits.",
              "semantic rename apply reports applied edit count");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Apply_Updates_Active_Buffer;

   procedure Test_Semantic_Rename_Apply_Updates_Open_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Active_Id : Editor.Buffers.Buffer_Id;
      Other_Id  : Editor.Buffers.Buffer_Id;
      Active_Analysis : LM.Analysis_Result;
      Other_Analysis  : LM.Analysis_Result;
      Other_State     : Editor.State.State_Type;
      Ignored  : LM.Symbol_Id;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer
        ("/project/run.adb", "run.adb",
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF,
         Active_Id);
      Editor.Buffers.Global_Add_File_Buffer
        ("/project/use_run.adb", "use_run.adb",
         "procedure Run is null;" & ASCII.LF,
         Other_Id);
      Editor.Buffers.Global_Set_Active_Buffer (Active_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "open-buffer rename fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Other_State := Editor.Buffers.Global_Buffer (Other_Id);
      Ignored := LM.Add_Symbol
        (Active_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Ignored := LM.Add_Symbol
        (Other_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 11, End_Line => 1, End_Column => 13));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => Natural (Active_Id),
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Active_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/use_run.adb",
         Buffer_Token         => Natural (Other_Id),
         Buffer_Revision      => Other_State.Buffer_Revision,
         Lifecycle_Generation => Other_State.Lifecycle_Generation,
         Analysis             => Other_Analysis);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Apply);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename apply handles all affected open buffers");
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Run_Renamed" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic rename apply updates the active buffer");
      Assert (Editor.State.Current_Text
                (Editor.Buffers.Global_Buffer (Other_Id)) =
              "procedure Run_Renamed is null;" & ASCII.LF,
              "semantic rename apply updates another open buffer");
      Assert (Latest_Message_Text (S) =
              "Rename applied for Run: 2 edits.",
              "semantic rename apply reports cross-buffer edit count");
      Assert (not Editor.Ada_Project_Index.Contains_Path
                    (S.Language_Index, "/project/run.adb")
              and then not Editor.Ada_Project_Index.Contains_Path
                    (S.Language_Index, "/project/use_run.adb"),
              "semantic rename apply invalidates changed open-buffer index entries");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "semantic rename apply keeps language service and index invalidation aligned");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Apply_Updates_Open_Buffers;

   procedure Test_Semantic_Rename_Apply_Updates_Unopened_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Active_Analysis : LM.Analysis_Result;
      Disk_Analysis   : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Result   : Editor.Executor.Command_Execution_Result;
      Root      : constant String := Temp_Path ("semantic_rename_disk");
      Disk_Path : constant String := Ada.Directories.Compose (Root, "use_run.adb");
      Reloaded  : Editor.Files.File_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Disk_Path, "procedure Run is null;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "disk rename fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Ignored := LM.Add_Symbol
        (Active_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Ignored := LM.Add_Symbol
        (Disk_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 11, End_Line => 1, End_Column => 13));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Active_Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, Disk_Path,
         Buffer_Token         => 0,
         Buffer_Revision      => 0,
         Lifecycle_Generation => 0,
         Analysis             => Disk_Analysis);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Apply);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "status=" &
              Editor.Executor.Command_Execution_Status'Image (Result.Status)
              & " message=" & Latest_Message_Text (S));
      Reloaded := Editor.Files.Open_File (Disk_Path);
      Assert (Reloaded.Status = Editor.Files.File_Open_Ok
              and then To_String (Reloaded.Contents) =
                "procedure Run_Renamed is null;" & ASCII.LF,
              "semantic rename apply saves the unopened file edit");
      Assert (Latest_Message_Text (S) =
              "Rename applied for Run: 2 edits.",
              "semantic rename apply counts open and unopened file edits");
      Assert (not Editor.Ada_Project_Index.Contains_Path
                    (S.Language_Index, "/project/run.adb")
              and then not Editor.Ada_Project_Index.Contains_Path
                    (S.Language_Index, Disk_Path),
              "semantic rename apply invalidates changed disk-backed index entries");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "semantic rename apply invalidates disk-backed language service entries");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Apply_Updates_Unopened_File;

   procedure Test_Semantic_Rename_Uses_Prompt_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Cmd      : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Refresh_Outline);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 20, Anchor => 20,
            Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Rename_Symbol_Preview);
      Cmd.Text := To_Unbounded_String ("Run_Custom");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "rename: Run -> Run_Custom",
              "semantic rename preview must use the prompted target name");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Rename_Symbol_Apply);
      Cmd.Text := To_Unbounded_String ("Run_Custom");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Run_Custom" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic rename apply must use the prompted target name");
      Assert (Latest_Message_Text (S) =
              "Rename applied for Run: 1 edits.",
              "prompted semantic rename reports applied edit count");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Uses_Prompt_Target;

   procedure Test_Semantic_Rename_Rejects_Reserved_Prompt_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Cmd      : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Refresh_Outline);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 20, Anchor => 20,
            Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Rename_Symbol_Preview);
      Cmd.Text := To_Unbounded_String ("return");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Latest_Message_Text (S) =
              "Rename preview unavailable for Run: unavailable.",
              "semantic rename preview rejects reserved prompted target names");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "reserved prompted rename preview projects no stale rows");

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Rename_Symbol_Apply);
      Cmd.Text := To_Unbounded_String ("return");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Run" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic rename apply leaves text unchanged for reserved target names");
      Assert (Latest_Message_Text (S) =
              "Rename apply unavailable for Run: unavailable.",
              "semantic rename apply reports reserved prompted target rejection");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Rejects_Reserved_Prompt_Target;

   procedure Test_Semantic_Rename_Command_Starts_Guided_Prompt
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);
      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 20, Anchor => 20,
            Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Execute_Command_Id
        (Editor.Commands.Command_Rename_Symbol_Apply);
      S := Editor.Input_Bridge.Get_State_For_Test;

      Assert (Editor.Guided_Prompts.Is_Active (S.Guided_Prompt),
              "semantic rename apply command should open a guided prompt even when the default target conflicts");
      Assert (S.Guided_Prompt.Kind = Editor.Guided_Prompts.Semantic_Rename_Prompt,
              "semantic rename prompt kind is exposed to the GUI");
      Assert (Editor.Guided_Prompts.Input_Text (S.Guided_Prompt) = "Run",
              "semantic rename prompt pre-fills the current symbol name");
      Assert (To_String (S.Guided_Prompt.Confirm_Label) = "Rename",
              "semantic rename apply prompt uses the apply confirmation label");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Command_Starts_Guided_Prompt;

   procedure Test_Semantic_Rename_Apply_Blocks_Conflicts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic rename conflict fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Ignored := LM.Add_Symbol
        (Analysis, "Run_Renamed", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 14));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Apply);
      Assert (not Editor.Commands.Is_Available (Avail),
              "semantic rename apply is unavailable when preview has conflicts");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Rename apply unavailable for Run: ambiguous.",
              "semantic rename apply reports conflict status through availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Apply);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "semantic rename apply does not execute conflicted previews");
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Run" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic rename apply leaves conflicted text unchanged");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Rename_Apply_Blocks_Conflicts;


   overriding procedure Register_Tests
     (T : in out Semantic_Rename_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Preview_Projects_Search_Result_Rows'Access,
         "semantic rename preview projects search result rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Apply_Updates_Active_Buffer'Access,
         "semantic rename apply updates active buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Apply_Updates_Open_Buffers'Access,
         "semantic rename apply updates open buffers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Apply_Updates_Unopened_File'Access,
         "semantic rename apply updates unopened file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Uses_Prompt_Target'Access,
         "semantic rename uses prompt target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Rejects_Reserved_Prompt_Target'Access,
         "semantic rename rejects reserved prompt target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Command_Starts_Guided_Prompt'Access,
         "semantic rename command starts guided prompt");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Rename_Apply_Blocks_Conflicts'Access,
         "semantic rename apply blocks conflicts");
   end Register_Tests;

end Editor.Executor.Semantic_Rename_Tests;
