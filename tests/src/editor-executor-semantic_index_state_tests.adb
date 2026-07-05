with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Files;
with Editor.Navigation_History;
with Editor.Outline;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Render_Model;
with Editor.State;
with Editor.Syntax_Semantics;
with Editor.Test_Helper;

package body Editor.Executor.Semantic_Index_State_Tests is

   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Ada_Language_Service.Semantic_Request_Kind;
   use type Editor.Ada_Language_Service.Semantic_Request_Status_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Files.File_Open_Status;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.State.Semantic_Popup_Kind;

   overriding function Name
     (T : Semantic_Index_State_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Semantic_Index_State_Tests");
   end Name;


   procedure Test_Semantic_Outline_Commands_Unavailable_Without_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      S      : Editor.State.State_Type;
      Avail  : Editor.Commands.Command_Availability;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic availability fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (not Editor.Commands.Is_Available (Avail),
              "find references must not be offered without an index answer");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "References unavailable for Run: unavailable.",
              "find references reports the language service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Hover);
      Assert (not Editor.Commands.Is_Available (Avail),
              "hover must not be offered without an index answer");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Hover unavailable for Run: unavailable.",
              "hover reports the language service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Completions);
      Assert (not Editor.Commands.Is_Available (Avail),
              "completions must not be offered without an index answer");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Completions unavailable for Run: unavailable.",
              "completions report the language service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Preview);
      Assert (not Editor.Commands.Is_Available (Avail),
              "rename preview must not be offered without an index answer");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Rename preview unavailable for Run: unavailable.",
              "rename preview reports the language service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "executing unavailable semantic commands remains blocked");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "unavailable semantic commands must not project stale Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Outline_Commands_Unavailable_Without_Index;

   procedure Test_Semantic_Commands_Use_Caret_When_Outline_Hidden
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
              "semantic hidden-panel fixture refreshes Outline");

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

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 20, Anchor => 20,
            Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (Editor.Commands.Is_Available (Avail),
              "hidden Outline does not block caret semantic command availability");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "hidden Outline still allows caret semantic command execution");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "caret semantic command projects semantic results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Commands_Use_Caret_When_Outline_Hidden;

   procedure Test_Semantic_Goto_Declaration_Uses_Caret_Symbol
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
         "Run;" & ASCII.LF);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/run.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("run.adb");
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 24, Anchor => 24,
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

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Declaration);
      Assert (Editor.Commands.Is_Available (Avail),
              "goto declaration is available from the caret symbol");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Declaration);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "goto declaration executes from the caret symbol");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Goto_Declaration
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "goto declaration execution records a completed semantic request");
      Assert (Active_Caret_Line (S) = 1,
              "caret goto declaration moves to the indexed declaration line");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Goto_Declaration_Uses_Caret_Symbol;

   procedure Test_Semantic_Outline_Commands_Block_Overflowed_Index
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
              "semantic overflow fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      for I in 1 .. 201 loop
         Ignored := LM.Add_Symbol
           (Analysis, "Run", LM.Symbol_Procedure,
            (Start_Line => Positive (I), Start_Column => 4,
             End_Line => Positive (I), End_Column => 6));
      end loop;
      Assert (not LM.Overflowed (Analysis),
              "semantic overflow test must exercise service cap");

      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/repeated.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (not Editor.Commands.Is_Available (Avail),
              "overflowed references must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "References unavailable for Run: overflow.",
              "overflowed references report the bounded service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Preview);
      Assert (not Editor.Commands.Is_Available (Avail),
              "overflowed rename preview must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Rename preview unavailable for Run: overflow.",
              "overflowed rename reports the bounded service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "overflowed semantic execution remains blocked");
      Assert (Latest_Message_Text (S) = "References unavailable for Run: overflow.",
              "overflowed semantic execution reports the bounded service reason");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "overflowed semantic commands must not project partial Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Outline_Commands_Block_Overflowed_Index;

   procedure Test_Semantic_Outline_Commands_Report_Stale_Current_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
      Live_Token : constant Natural := 1;
      Stale_Revision : Natural;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic stale-current fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("/project/run.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("run.adb");
      S.Active_Buffer_Token := Live_Token;

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22));
      Stale_Revision :=
        (if S.Buffer_Revision > 0 then S.Buffer_Revision - 1
         else S.Buffer_Revision + 1);
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => Live_Token,
         Buffer_Revision      => Stale_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current references must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "References unavailable for Run: stale.",
              "stale current references report the stale service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Hover);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current hover must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Hover unavailable for Run: stale.",
              "stale current hover reports the stale service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Completions);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current completions must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Completions unavailable for Run: stale.",
              "stale current completions report the stale service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Preview);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current rename preview must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Rename preview unavailable for Run: stale.",
              "stale current rename preview reports the stale service reason");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Symbol_Apply);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current rename apply must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Rename apply unavailable for Run: stale.",
              "stale current rename apply reports the stale service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current semantic execution remains blocked");
      Assert (Latest_Message_Text (S) = "References unavailable for Run: stale.",
              "stale current execution reports the stale service reason");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "stale current references must not project stale Search Results");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Hover);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current hover execution remains blocked");
      Assert (Latest_Message_Text (S) = "Hover unavailable for Run: stale.",
              "stale current hover execution reports the stale service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Completions);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current completion execution remains blocked");
      Assert (Latest_Message_Text (S) = "Completions unavailable for Run: stale.",
              "stale current completion execution reports the stale service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Preview);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current rename preview execution remains blocked");
      Assert (Latest_Message_Text (S) = "Rename preview unavailable for Run: stale.",
              "stale current rename preview execution reports the stale service reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Rename_Symbol_Apply);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current rename apply execution remains blocked");
      Assert (Latest_Message_Text (S) = "Rename apply unavailable for Run: stale.",
              "stale current rename apply execution reports the stale service reason");

      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 20, Anchor => 20,
            Virtual_Column => 0, Anchor_Virtual_Column => 0));

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Declaration);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale current caret goto declaration must not be offered");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Declaration unavailable for Run: stale.",
              "stale current caret goto declaration reports stale reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Declaration);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale current caret goto declaration remains blocked");
      Assert (Latest_Message_Text (S) = "Declaration unavailable for Run: stale.",
              "stale current caret goto declaration execution reports stale reason");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Outline_Commands_Report_Stale_Current_Index;

   procedure Test_Semantic_Outline_Commands_Block_Stale_Edit_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
      Cmd      : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic stale-edit fixture refreshes Outline");

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
        (S, Editor.Commands.Command_Find_References);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic stale-edit setup starts with an answerable index");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String ("x");
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (not Editor.Commands.Is_Available (Avail),
              "semantic commands must not be offered after editing indexed text");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "References unavailable for Run: unavailable.",
              "stale edit invalidation reports the missing fresh index answer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale edit semantic execution remains blocked");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "stale edit semantic commands must not project stale Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Outline_Commands_Block_Stale_Edit_Index;

   procedure Test_Language_Index_Project_Workflow_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_project_workflow");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      Note_Path : constant String := Ada.Directories.Compose (Src, "notes.txt");
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Msg    : Unbounded_String;
      Lines  : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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
      Write_Text_File (Note_Path, "not Ada" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language project index refresh command executes");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language project index refresh indexes project Ada files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "language project index refresh records project symbols");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "language project index refresh syncs language service");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "Language project index refreshed:") > 0,
              "language project index refresh reports user-facing summary");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Status);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index status command executes");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "Language index status:") > 0,
              "language index status reports a status prefix");
      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "files") > 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "symbols") > 0,
              "language index status reports indexed files and symbols");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "backend=internal-index") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "compiler=not-run") > 0,
              "language index status reports semantic backend state");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "d=0") > 0,
              "language index status reports no active-file compiler diagnostics before compiler run");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "rq=none/none") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "cancel=no") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "prev=none") > 0,
              "language index status reports semantic request lifecycle state");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "caps=nav+") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "ref+") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "cmp+") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "hov+") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "ren+") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "req!") > 0,
              "language index status reports ready language-service capabilities");

      Lines.Append
        (To_Unbounded_String
           ("compiler run completed without diagnostics"));
      Editor.Ada_Language_Service.Put_Compiler_Diagnostic_Lines
        (S.Language_Service, Lines, Tool_Name => "gnat", Run_Fingerprint => 76);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Status);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index status command executes after clean compiler run");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "backend=internal-index") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "compiler=0") > 0,
              "clean compiler run does not promote inactive diagnostics backend");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "d=0") > 0,
              "clean compiler run reports zero active-file compiler diagnostics");
      Lines.Clear;

      Lines.Append
        (To_Unbounded_String
           ("src/main.adb:4:4: warning: status diagnostic"));
      Lines.Append
        (To_Unbounded_String
           ("src/lib.ads:2:4: error: unrelated active-file status diagnostic"));
      Editor.Ada_Language_Service.Put_Compiler_Diagnostic_Lines
        (S.Language_Service, Lines, Tool_Name => "gnat", Run_Fingerprint => 77);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Status);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index status command executes with compiler backend");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "backend=gnat-compiler") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "compiler=") > 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "warn=") > 0,
              "language index status reports compiler-backed diagnostics");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "d=1") > 0,
              "language index status reports compiler diagnostics for the active file only");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Clear);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index clear command executes");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) = 0,
              "language index clear removes indexed files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) = 0,
              "language index clear removes indexed symbols");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "language index clear syncs language service");
      Assert (Latest_Message_Text (S) = "Language index cleared.",
              "language index clear reports deterministic feedback");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Status);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index status command executes after clear");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "caps=nav!") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "ref!") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "cmp!") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "hov!") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "ren!") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Msg), "req!") > 0,
              "language index status reports not-ready capabilities after clear");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic project index refresh command executes");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "semantic project refresh rebuilds project language index");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "semantic project refresh syncs language service");
      Assert (Editor.Syntax_Semantics.Symbol_Count (S.Syntax_Symbols) > 0,
              "semantic project refresh updates active-buffer semantic map");
      Assert (S.Syntax_Symbols_Buffer_Token = S.Active_Buffer_Token,
              "semantic project refresh stamps active-buffer semantic token");
      Assert (S.Syntax_Symbols_Revision = S.Buffer_Revision,
              "semantic project refresh stamps active-buffer semantic revision");
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index
                (To_String (Msg), "Semantic project index refreshed:") > 0,
              "semantic project refresh reports user-facing summary");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Project_Workflow_Commands;

   procedure Test_Language_Index_Auto_Refreshes_Project_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_auto_project_lifecycle");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      Extra_Path : constant String := Ada.Directories.Compose (Src, "extra.ads");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "project open should automatically index project Ada files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "project open should automatically retain project symbols");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "automatic project index should sync the language service");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Assert (Editor.Syntax_Semantics.Symbol_Count (S.Syntax_Symbols) > 0,
              "opening an Ada file should prepare active-buffer semantic state");
      Assert (S.Syntax_Symbols_Buffer_Token = S.Active_Buffer_Token,
              "automatic file-open semantics should stamp the active buffer");
      Assert (S.Syntax_Symbols_Revision = S.Buffer_Revision,
              "automatic file-open semantics should stamp the active revision");

      Write_Text_File
        (Extra_Path,
         "package Extra is" & ASCII.LF &
         "   Value : constant Integer := 1;" & ASCII.LF &
         "end Extra;" & ASCII.LF);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_Project_Files (S);

      Assert (Editor.Ada_Project_Index.Contains_Path (S.Language_Index, Extra_Path),
              "project file refresh should automatically refresh language index rows");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "project file refresh should keep language service in sync");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Auto_Refreshes_Project_Lifecycle;

   procedure Test_Semantic_Refresh_Publishes_Live_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("semantic_refresh_live_diagnostics");
      Path : constant String := Ada.Directories.Compose (Root, "live_semantic.ads");
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      First_Count  : Natural;
      Second_Count : Natural;
      Quick_Fix_Row : Natural := 0;
      Action_Avail  : Editor.Commands.Command_Availability;
      Shown         : Boolean;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Root);
      Write_Text_File
        (Path,
         "package Live_Semantic is" & ASCII.LF &
         "   type Word is record" & ASCII.LF &
         "      A : Integer;" & ASCII.LF &
         "      B : Integer;" & ASCII.LF &
         "   end record;" & ASCII.LF &
         "   for Word use record" & ASCII.LF &
         "      A at 0 range 0 .. 7;" & ASCII.LF &
         "      B at 0 range 4 .. 15;" & ASCII.LF &
         "   end record;" & ASCII.LF &
         "end Live_Semantic;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic refresh executes for active Ada file");
      Assert (Editor.Ada_Language_Service.Semantic_Diagnostic_Count_For_Path
                (S.Language_Service, Path) > 0,
              "semantic refresh publishes live diagnostics to language service");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) > 0,
              "semantic refresh projects live diagnostics to Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Source_Label
                (S.Feature_Diagnostics, 1) = Path,
              "live Diagnostics rows retain file source labels");
      Assert (Editor.Feature_Diagnostics.Item_Source_Kind
                (S.Feature_Diagnostics, 1) =
              Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
              "live semantic Diagnostics rows use editor semantic source kind");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target
                (S.Feature_Diagnostics, 1),
              "live semantic Diagnostics rows are navigable");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer
                (S.Feature_Diagnostics, 1) = S.Active_Buffer_Token,
              "live semantic Diagnostics rows target the active buffer snapshot");
      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Quick_Fix_Label
              (S.Feature_Diagnostics, I)'Length > 0
           and then Editor.Feature_Diagnostics.Item_Primary_Action_Kind
              (S.Feature_Diagnostics, I) /=
                Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None
         then
            Quick_Fix_Row := I;
            exit;
         end if;
      end loop;
      Assert (Quick_Fix_Row > 0,
              "live semantic Diagnostics must expose a descriptor-backed quick-fix row");
      Assert (Editor.Feature_Diagnostics.Item_Quick_Fix_Detail
                (S.Feature_Diagnostics, Quick_Fix_Row)'Length > 0,
              "live semantic quick-fix row renders descriptor detail");
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "Diagnostics feature is shown for live semantic quick-fix execution");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Quick_Fix_Row);
      Action_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);
      Assert (Editor.Commands.Is_Available (Action_Avail),
              "live semantic quick-fix action is available from Diagnostics");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "live semantic quick-fix executes through the Diagnostics command");

      First_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "repeated semantic refresh executes");
      Second_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Assert (Second_Count = First_Count,
              "repeated semantic refresh replaces live Diagnostics rows without duplicates");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Status);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index status executes after live semantic diagnostics");
      Assert (Ada.Strings.Fixed.Index
                (Latest_Message_Text (S), "semantic=") > 0
              and then Ada.Strings.Fixed.Index
                (Latest_Message_Text (S), "sd=") > 0,
              "language index status reports semantic diagnostics totals and active-file count");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Clear);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index clear executes after live diagnostics");
      Assert (Editor.Ada_Language_Service.Semantic_Diagnostic_Count
                (S.Language_Service) = 0,
              "language index clear removes live semantic backend diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "language index clear removes projected live semantic Diagnostics rows");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Semantic_Refresh_Publishes_Live_Diagnostics;

   procedure Test_Semantic_Buffer_Refresh_Publishes_Live_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("semantic_buffer_refresh_live_diagnostics");
      Path : constant String := Ada.Directories.Compose (Root, "buffer_live_semantic.ads");
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      First_Count  : Natural;
      Second_Count : Natural;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Root);
      Write_Text_File
        (Path,
         "package Buffer_Live_Semantic is" & ASCII.LF &
         "   type Word is record" & ASCII.LF &
         "      A : Integer;" & ASCII.LF &
         "      B : Integer;" & ASCII.LF &
         "   end record;" & ASCII.LF &
         "   for Word use record" & ASCII.LF &
         "      A at 0 range 0 .. 7;" & ASCII.LF &
         "      B at 0 range 4 .. 15;" & ASCII.LF &
         "   end record;" & ASCII.LF &
         "end Buffer_Live_Semantic;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic buffer refresh executes for active Ada file");
      Assert (Editor.Ada_Project_Index.Contains_Path (S.Language_Index, Path),
              "semantic buffer refresh indexes the active buffer analysis");
      Assert (Editor.Ada_Language_Service.Semantic_Diagnostic_Count_For_Path
                (S.Language_Service, Path) > 0,
              "semantic buffer refresh publishes live diagnostics to language service");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) > 0,
              "semantic buffer refresh projects live diagnostics to Diagnostics");
      Assert (Editor.Feature_Diagnostics.Item_Source_Label
                (S.Feature_Diagnostics, 1) = Path,
              "buffer live Diagnostics rows retain file source labels");
      Assert (Editor.Feature_Diagnostics.Item_Target_Buffer
                (S.Feature_Diagnostics, 1) = S.Active_Buffer_Token,
              "buffer live Diagnostics rows target the active buffer snapshot");

      First_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "repeated semantic buffer refresh executes");
      Second_Count := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Assert (Second_Count = First_Count,
              "repeated semantic buffer refresh replaces live Diagnostics rows without duplicates");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Language_Index_Clear);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index clear executes after buffer live diagnostics");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "language index clear removes buffer-projected live Diagnostics rows");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Semantic_Buffer_Refresh_Publishes_Live_Diagnostics;

   procedure Test_Semantic_Project_Refresh_Projects_Cross_Unit_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("semantic_project_refresh_cross_unit");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Path : constant String := Ada.Directories.Compose (Src, "client.ads");
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Found_Service : Boolean := False;
      Found_Feature : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_Text_File
        (Path,
         "with Missing_Dep;" & ASCII.LF &
         "package Client is" & ASCII.LF &
         "end Client;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic project refresh executes for cross-unit fixture");

      for I in 1 .. Editor.Ada_Language_Service.Semantic_Diagnostic_Count
        (S.Language_Service)
      loop
         declare
            Diagnostic : constant Editor.Ada_Language_Service.Semantic_Diagnostic :=
              Editor.Ada_Language_Service.Semantic_Diagnostic_At
                (S.Language_Service, I);
         begin
            if To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic-cross-unit") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Message), "missing") > 0
            then
               Found_Service := True;
            end if;
         end;
      end loop;

      for I in 1 .. Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) loop
         if Editor.Feature_Diagnostics.Item_Source_Label (S.Feature_Diagnostics, I) = Path
           and then Ada.Strings.Fixed.Index
             (Editor.Feature_Diagnostics.Item_Message (S.Feature_Diagnostics, I),
              "cross-unit") > 0
         then
            Found_Feature := True;
         end if;
      end loop;

      Assert (Found_Service,
              "semantic project refresh publishes cross-unit diagnostics to language service");
      Assert (Found_Feature,
              "semantic project refresh projects cross-unit diagnostics to Diagnostics");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Semantic_Project_Refresh_Projects_Cross_Unit_Diagnostics;

   procedure Test_Indexed_Outline_Body_Spec_Navigation_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("indexed_outline_body_spec");
      Spec_Path : constant String := Ada.Directories.Compose (Root, "demo.ads");
      Body_Path : constant String := Ada.Directories.Compose (Root, "demo.adb");
      Sep_Path  : constant String := Ada.Directories.Compose (Root, "demo-run.adb");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Avail  : Editor.Commands.Command_Availability;
      Unit_Target : Editor.Ada_Project_Index.Unique_Target_Result;
      Symbol_Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
      Spec_Row : Natural := 0;
      Body_Row : Natural := 0;
      Sep_Row  : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Root);
      Write_Text_File
        (Spec_Path,
         "package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Write_Text_File
        (Body_Path,
         "package body Demo is" & ASCII.LF &
         "   procedure Run is separate;" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Write_Text_File
        (Sep_Path,
         "separate (Demo)" & ASCII.LF &
         "procedure Run is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Run;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Spec_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed body/spec fixture refreshes semantic project index");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed body/spec fixture refreshes spec Outline");
      for I in 1 .. Editor.Outline.Item_Count (S.Outline) loop
         if Editor.Outline.Item_Kind (S.Outline, I) =
           Editor.Outline.Outline_Package
         then
            Spec_Row := I;
            exit;
         end if;
      end loop;
      Assert (Spec_Row /= 0, "indexed body/spec fixture exposes spec package row");
      Editor.Outline.Select_Item (S.Outline, Spec_Row);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Spec_Row);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Body);
      Assert (Editor.Commands.Is_Available (Avail),
              "indexed package spec row offers goto body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Body);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed package spec row navigates to body");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Body_Path,
              "goto body opens indexed body file");
      Assert (Active_Caret_Line (S) = 1,
              "goto body places caret on indexed body declaration");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Goto_Body
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "goto body execution records a completed semantic request");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed body/spec fixture refreshes body Outline");
      for I in 1 .. Editor.Outline.Item_Count (S.Outline) loop
         if Editor.Outline.Item_Kind (S.Outline, I) =
           Editor.Outline.Outline_Package_Body
         then
            Body_Row := I;
            exit;
         end if;
      end loop;
      Assert (Body_Row /= 0, "indexed body/spec fixture exposes package body row");
      Editor.Outline.Select_Item (S.Outline, Body_Row);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Body_Row);

      Unit_Target := Editor.Ada_Project_Index.Resolve_Unique_Unit_Target
        (S.Language_Index, "Demo", Editor.Ada_Project_Index.Unit_Package_Spec);
      Symbol_Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Demo");
      Assert (Natural (Symbol_Targets.Matches.Length) >= 2,
              "indexed body/spec fixture retains ordinary Demo symbols; found" &
              Natural'Image (Natural (Symbol_Targets.Matches.Length)));
      Assert (Unit_Target.Available,
              "indexed package spec unit target is available for Demo; units" &
              Natural'Image (Editor.Ada_Project_Index.Unit_Count (S.Language_Index)) &
              ", ambiguous=" & Boolean'Image (Unit_Target.Ambiguous) &
              ", overflow=" & Boolean'Image (Unit_Target.Overflow));
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Spec);
      Assert (Editor.Commands.Is_Available (Avail),
              "indexed package body row offers goto spec from label '" &
              Editor.Outline.Item_Label (S.Outline, Body_Row) & "': " &
              Editor.Commands.Unavailable_Reason (Avail));
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Spec);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed package body row navigates to spec");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Spec_Path,
              "goto spec opens indexed spec file");
      Assert (Active_Caret_Line (S) = 1,
              "goto spec places caret on indexed spec declaration");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Goto_Spec
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "goto spec execution records a completed semantic request");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Sep_Path);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed body/spec fixture refreshes separate subunit Outline");
      for I in 1 .. Editor.Outline.Item_Count (S.Outline) loop
         if Editor.Outline.Item_Kind (S.Outline, I) =
           Editor.Outline.Outline_Procedure
           and then Ada.Strings.Fixed.Index
             (Editor.Outline.Item_Label (S.Outline, I), "Run") > 0
         then
            Sep_Row := I;
            exit;
         end if;
      end loop;
      Assert (Sep_Row /= 0,
              "indexed body/spec fixture exposes separate procedure body row");
      Editor.Outline.Select_Item (S.Outline, Sep_Row);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Sep_Row);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Spec);
      Assert (Editor.Commands.Is_Available (Avail),
              "indexed separate procedure body row offers goto spec from label '" &
              Editor.Outline.Item_Label (S.Outline, Sep_Row) & "': " &
              Editor.Commands.Unavailable_Reason (Avail));
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Spec);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "indexed separate procedure body row navigates to parent spec");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Spec_Path,
              "separate procedure goto spec opens indexed parent spec file");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Goto_Spec
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "separate procedure goto spec records a completed semantic request");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Spec_Path);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "stale body/spec fixture refreshes spec Outline again");
      Spec_Row := 0;
      for I in 1 .. Editor.Outline.Item_Count (S.Outline) loop
         if Editor.Outline.Item_Kind (S.Outline, I) =
           Editor.Outline.Outline_Package
         then
            Spec_Row := I;
            exit;
         end if;
      end loop;
      Assert (Spec_Row /= 0, "stale body/spec fixture exposes spec package row");
      Editor.Outline.Select_Item (S.Outline, Spec_Row);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, Spec_Row);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "command-kind text edits invalidate language service with project index");

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Goto_Body);
      Assert (not Editor.Commands.Is_Available (Avail),
              "stale selected package spec row does not offer goto body");
      Assert (Editor.Commands.Unavailable_Reason (Avail) =
              "Outline indexed target unavailable",
              "stale selected package spec row reports indexed target unavailable");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Goto_Body);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale selected package spec row cannot execute goto body");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Indexed_Outline_Body_Spec_Navigation_Workflow;

   procedure Test_Language_Index_Survives_Buffer_Switcher_Accept
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_buffer_switcher");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index buffer-switcher fixture refreshes project index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language index buffer-switcher fixture indexed both files");

      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Open_Buffer_Switcher (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher),
              "language index buffer-switcher fixture opens Buffer List");
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Buffer_Switcher_Insert_Text (S, "main");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 1,
              "language index buffer-switcher fixture filters to main");
      Editor.Executor.Buffer_Switcher_Surface_Commands.Execute_Accept_Buffer_Switcher (S);

      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Main_Path,
              "buffer-switcher accept focuses main source");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "buffer-switcher accept preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "buffer-switcher accept preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "buffer-switcher accept keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Buffer_Switcher_Accept;

   procedure Test_Language_Index_Survives_Navigation_Back
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_navigation_back");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Main_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Main_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index navigation fixture refreshes project index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language index navigation fixture indexed both files");

      Editor.Navigation_History.Clear (S.Navigation_History);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Main_Id);
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Main_Path,
              "language index navigation fixture switches to main");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 1,
              "language index navigation fixture records previous lib buffer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Navigation_Back);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "navigate back executes for indexed open buffer target");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Lib_Path,
              "navigate back focuses lib source");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "navigate back preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "navigate back preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "navigate back keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Navigation_Back;

   procedure Test_Language_Index_Survives_Close_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_close_active");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index close-active fixture refreshes project index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language index close-active fixture indexed both files");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "close active buffer executes for clean indexed source");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Main_Path,
              "close active buffer focuses remaining source");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "close active buffer preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "close active buffer preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "close active buffer keeps closed-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Close_Active_Buffer;

   procedure Test_Language_Index_Survives_New_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_new_buffer");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index new-buffer fixture refreshes project index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language index new-buffer fixture indexed both files");

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);

      Assert (not S.File_Info.Has_Path,
              "new buffer creates an untitled active buffer");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "new buffer preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "new buffer preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "new buffer keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_New_Buffer;

   procedure Test_Language_Index_Survives_Save_All
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_save_all");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Main_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Main_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Extra;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Main_Id);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "language index save-all fixture refreshes project index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "language index save-all fixture indexed both files");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_All);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "save all executes for inactive dirty file-backed buffer");
      Assert (S.File_Info.Has_Path
              and then To_String (S.File_Info.Path) = Main_Path,
              "save all restores original active source");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "save all preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "save all preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "save all keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Save_All;

   procedure Test_Language_Index_Survives_Save_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_save_file");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Saved;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "save-file fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "save-file fixture indexed both files");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "save file executes for dirty file-backed buffer");
      Assert (not S.File_Info.Dirty,
              "save file clears dirty state");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "save file rebuilds project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "save file rebuilds project language index symbols");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "save file rebuild syncs language service index");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "save file keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Save_File;

   procedure Test_Language_Index_Survives_Reload_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_reload_confirm");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Unsaved;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "reload confirmation fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "reload confirmation fixture indexed both files");

      Write_Text_File
        (Lib_Path,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure From_Disk;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty reload creates a confirmation prompt");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "reload confirmation clears the prompt");
      Assert (not S.File_Info.Dirty,
              "reload confirmation clears dirty state");
      Assert (Ada.Strings.Fixed.Index (Editor.State.Current_Text (S), "From_Disk") > 0,
              "reload confirmation installs disk text");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "reload confirmation rebuilds project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "reload confirmation rebuilds project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "reload confirmation keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Reload_Confirmation;

   procedure Test_Language_Index_Survives_Revert_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_revert_confirm");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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
         "   procedure From_Disk;" & ASCII.LF &
         "end Lib;" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Unsaved;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "revert confirmation fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "revert confirmation fixture indexed both files");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Revert_Active_Buffer);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "dirty revert creates a confirmation prompt");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "revert confirmation clears the prompt");
      Assert (not S.File_Info.Dirty,
              "revert confirmation clears dirty state");
      Assert (Ada.Strings.Fixed.Index (Editor.State.Current_Text (S), "From_Disk") > 0,
              "revert confirmation restores disk text");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "revert confirmation rebuilds project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "revert confirmation rebuilds project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "revert confirmation keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Revert_Confirmation;

   procedure Test_Language_Index_Survives_File_Conflict_Reload
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_conflict_reload");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Unsaved;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "file-conflict reload fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-conflict reload fixture indexed both files");

      Write_Text_File
        (Lib_Path,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure From_Disk;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (S.File_Conflict_Prompt_Active,
              "save conflict opens file conflict prompt");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Reload_From_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "file-conflict reload clears prompt");
      Assert (not S.File_Info.Dirty,
              "file-conflict reload clears dirty state");
      Assert (Ada.Strings.Fixed.Index (Editor.State.Current_Text (S), "From_Disk") > 0,
              "file-conflict reload installs disk text");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-conflict reload rebuilds project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "file-conflict reload rebuilds project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "file-conflict reload keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_File_Conflict_Reload;

   procedure Test_Language_Index_Survives_File_Conflict_Overwrite
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_conflict_overwrite");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Reloaded : Editor.Files.File_Open_Result;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);
      Set_Buffer_Text
        (S,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure Unsaved;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "file-conflict overwrite fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-conflict overwrite fixture indexed both files");

      Write_Text_File
        (Lib_Path,
         "package Lib is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "   procedure External;" & ASCII.LF &
         "end Lib;" & ASCII.LF);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (S.File_Conflict_Prompt_Active,
              "save conflict opens overwrite prompt");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
              "file-conflict overwrite clears prompt");
      Assert (not S.File_Info.Dirty,
              "file-conflict overwrite clears dirty state");
      Reloaded := Editor.Files.Open_File (Lib_Path);
      Assert (Editor.Files.Is_Success (Reloaded)
              and then Ada.Strings.Fixed.Index
                (To_String (Reloaded.Contents), "Unsaved") > 0,
              "file-conflict overwrite writes buffer text to disk");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "file-conflict overwrite rebuilds project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "file-conflict overwrite rebuilds project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "file-conflict overwrite keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_File_Conflict_Overwrite;

   procedure Test_Language_Index_Survives_Diagnostic_Open_Selected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("language_index_diagnostic_open");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Main_Path : constant String := Ada.Directories.Compose (Src, "main.adb");
      Lib_Path  : constant String := Ada.Directories.Compose (Src, "lib.ads");
      S : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Main_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Shown : Boolean := False;
      Targets : Editor.Ada_Project_Index.Index_Resolution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
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

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Main_Path);
      Main_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Lib_Path);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Refresh_Project_Index);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "diagnostic-open fixture refreshes project language index");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "diagnostic-open fixture indexed both files");

      Editor.Feature_Diagnostics.Clear_Diagnostics (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "inactive-buffer semantic diagnostic",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Natural (Main_Id),
         Target_Line   => 4,
         Target_Column => 4);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for inactive target test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "diagnostic open selected executes for inactive target buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Main_Id,
              "diagnostic open selected focuses inactive target buffer");
      Assert (Editor.Ada_Project_Index.File_Count (S.Language_Index) >= 2,
              "diagnostic open selected preserves project language index files");
      Assert (Editor.Ada_Project_Index.Symbol_Count (S.Language_Index) >= 2,
              "diagnostic open selected preserves project language index symbols");
      Targets := Editor.Ada_Project_Index.Resolve (S.Language_Index, "Lib");
      Assert (Natural (Targets.Matches.Length) >= 1,
              "diagnostic open selected keeps cross-file Lib symbol available");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Language_Index_Survives_Diagnostic_Open_Selected;


   overriding procedure Register_Tests
     (T : in out Semantic_Index_State_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Outline_Commands_Unavailable_Without_Index'Access,
         "semantic outline commands unavailable without index");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Commands_Use_Caret_When_Outline_Hidden'Access,
         "semantic commands use caret when outline hidden");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Goto_Declaration_Uses_Caret_Symbol'Access,
         "semantic goto declaration uses caret symbol");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Outline_Commands_Block_Overflowed_Index'Access,
         "semantic outline commands block overflowed index");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Outline_Commands_Report_Stale_Current_Index'Access,
         "semantic outline commands report stale current index");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Outline_Commands_Block_Stale_Edit_Index'Access,
         "semantic outline commands block stale edit index");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Project_Workflow_Commands'Access,
         "language index project workflow commands");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Auto_Refreshes_Project_Lifecycle'Access,
         "language index auto refreshes project lifecycle");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Refresh_Publishes_Live_Diagnostics'Access,
         "semantic refresh publishes live diagnostics");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Buffer_Refresh_Publishes_Live_Diagnostics'Access,
         "semantic buffer refresh publishes live diagnostics");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Project_Refresh_Projects_Cross_Unit_Diagnostics'Access,
         "semantic project refresh projects cross unit diagnostics");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Indexed_Outline_Body_Spec_Navigation_Workflow'Access,
         "indexed outline body spec navigation workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Buffer_Switcher_Accept'Access,
         "language index survives buffer switcher accept");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Navigation_Back'Access,
         "language index survives navigation back");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Close_Active_Buffer'Access,
         "language index survives close active buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_New_Buffer'Access,
         "language index survives new buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Save_All'Access,
         "language index survives save all");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Save_File'Access,
         "language index survives save file");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Reload_Confirmation'Access,
         "language index survives reload confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Revert_Confirmation'Access,
         "language index survives revert confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_File_Conflict_Reload'Access,
         "language index survives file conflict reload");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_File_Conflict_Overwrite'Access,
         "language index survives file conflict overwrite");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Language_Index_Survives_Diagnostic_Open_Selected'Access,
         "language index survives diagnostic open selected");
   end Register_Tests;

end Editor.Executor.Semantic_Index_State_Tests;
