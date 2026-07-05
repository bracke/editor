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
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Files;
with Editor.Guided_Prompts;
with Editor.Input_Bridge;
with Editor.Navigation_History;
with Editor.Outline;
with Editor.Panels;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Render_Model;
with Editor.State;
with Editor.Syntax_Semantics;
with Editor.Test_Helper;

package body Editor.Executor.Semantic_Language_Service_Tests is

   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Ada_Language_Service.Semantic_Request_Kind;
   use type Editor.Ada_Language_Service.Semantic_Request_Status_Kind;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Feature_Diagnostics.Diagnostic_Source_Kind;
   use type Editor.Files.File_Open_Status;
   use type Editor.Guided_Prompts.Prompt_Kind;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.State.Semantic_Popup_Kind;

   overriding function Name
     (T : Semantic_Language_Service_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Semantic_Language_Service_Tests");
   end Name;

   procedure Test_Semantic_Find_References_Projects_Search_Result_Rows
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
      if S.Active_Buffer_Token = 0 then
         S.Active_Buffer_Token := 1;
      end if;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic reference fixture refreshes Outline");

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
      Ignored := LM.Add_Symbol
        (Analysis, "Run_Renamed", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 14));
      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 6));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Find_References);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic find references is available when the index can answer");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_No_Request,
              "semantic command availability does not mutate tracked requests");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Find_References);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic find references command executes from selected Outline row");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Find_References
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "semantic find references execution records a completed request");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "semantic references are projected into Search Results rows");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "references: Run",
              "semantic references label the Search Results query");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "open-buffer semantic reference row is navigable");
      Assert (Editor.Feature_Search_Results.Item_Target_Buffer
                (S.Feature_Search_Results, 1) = S.Active_Buffer_Token,
              "semantic reference row targets the live buffer token");
      Assert (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "semantic find references shows the Search Results panel");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "semantic references select the first projected row");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Find_References_Projects_Search_Result_Rows;

   procedure Test_Semantic_Workspace_Symbols_Project_Search_Result_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Other    : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);
      if S.Active_Buffer_Token = 0 then
         S.Active_Buffer_Token := 1;
      end if;

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic workspace symbol fixture refreshes Outline");

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
      Ignored := LM.Add_Symbol
        (Analysis, "Run_Helper", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 13));
      Ignored := LM.Add_Symbol
        (Other, "Runner", LM.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 9));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/other.ads",
         Buffer_Token         => 22,
         Buffer_Revision      => 1,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Other);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Workspace_Symbols);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic workspace symbols are available when the index can answer");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_No_Request,
              "workspace symbol availability does not mutate tracked requests");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Workspace_Symbols);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic workspace symbols command executes from selected Outline row");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Workspace_Symbols
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "workspace symbols execution records a completed request");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 3,
              "workspace symbols are projected into Search Results rows");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "symbols: Run",
              "workspace symbols label the Search Results query");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "workspace symbol row is navigable");
      Assert (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "semantic workspace symbols show the Search Results panel");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Workspace_Symbols_Project_Search_Result_Rows;

   procedure Test_Semantic_Completions_Project_Search_Result_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
      Snapshot : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure R" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion fixture refreshes Outline");

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
        (Analysis, "R", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 20));
      Ignored := LM.Add_Symbol
        (Analysis, "Render", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 9));
      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 6));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.adb",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Completions);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic completions are available when the index can answer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Completions);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion command executes from selected Outline row");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Completion
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "semantic completion execution records a completed request");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 3,
              "semantic completions are projected into Search Results rows");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "completions: R",
              "semantic completions label the Search Results query");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "open-buffer semantic completion row is navigable");
      Assert (Editor.Feature_Search_Results.Item_Target_Buffer
                (S.Feature_Search_Results, 1) = S.Active_Buffer_Token,
              "semantic completion row targets the live buffer token");
      Assert (S.Semantic_Popup.Active
              and then S.Semantic_Popup.Kind = Editor.State.Semantic_Completion_Popup,
              "semantic completions show a native completion popup");
      Assert (S.Semantic_Popup.Item_Count = 3
              and then To_String (S.Semantic_Popup.Items (1).Label) = "R",
              "semantic completion popup carries bounded completion rows");
      Assert (not Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
              "semantic completions do not force-open the Search Results panel");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "semantic completions select the first projected row");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Semantic_Popup.Active
              and then Snapshot.Semantic_Popup.Kind =
                Editor.State.Semantic_Completion_Popup,
              "render snapshot exposes semantic completion popup");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Completion_Select_Next);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion popup selects next row");
      Assert (S.Semantic_Popup.Selected_Item = 2
              and then To_String (S.Semantic_Popup.Items (2).Label) = "Render",
              "semantic completion next selects the next candidate");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Completion_Select_Previous);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion popup selects previous row");
      Assert (S.Semantic_Popup.Selected_Item = 1,
              "semantic completion previous wraps back to first candidate");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Popup_Dismiss);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic popup dismiss executes");
      Assert (not S.Semantic_Popup.Active,
              "semantic popup dismiss clears the popup");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Completions);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion command can reopen popup after dismiss");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Completion_Select_Next);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion popup can select candidate before accept");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Semantic_Completion_Accept);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic completion accept executes");
      Assert (Editor.State.Current_Text (S) =
              "@outline procedure Render" & ASCII.LF &
              "body line" & ASCII.LF,
              "semantic completion accept replaces the identifier at the caret");
      Assert (not S.Semantic_Popup.Active,
              "semantic completion accept closes the popup");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Completions_Project_Search_Result_Rows;

   procedure Test_Semantic_Hover_Projects_Search_Result_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S        : Editor.State.State_Type;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Avail    : Editor.Commands.Command_Availability;
      Result   : Editor.Executor.Command_Execution_Result;
      Snapshot : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "@outline procedure Run" & ASCII.LF &
         "body line" & ASCII.LF);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic hover fixture refreshes Outline");

      Editor.Outline.Select_Item (S.Outline, 1);
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Ignored := LM.Add_Symbol
        (Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 20, End_Line => 1, End_Column => 22),
         Profile_Summary => "(Count : Natural)");
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/run.ads",
         Buffer_Token         => S.Active_Buffer_Token,
         Buffer_Revision      => S.Buffer_Revision,
         Lifecycle_Generation => S.Lifecycle_Generation,
         Analysis             => Analysis);

      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Show_Hover);
      Assert (Editor.Commands.Is_Available (Avail),
              "semantic hover is available when the index can answer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Show_Hover);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "semantic hover command executes from selected Outline row");
      Assert (Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Kind =
              Editor.Ada_Language_Service.Semantic_Request_Hover
              and then Editor.Ada_Language_Service.Active_Semantic_Request
                (S.Language_Service).Status =
              Editor.Ada_Language_Service.Semantic_Request_Completed,
              "semantic hover execution records a completed request");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "semantic hover is projected into a Search Results row");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "hover: Run",
              "semantic hover labels the Search Results query");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "open-buffer semantic hover row is navigable");
      Assert (Editor.Feature_Search_Results.Item_Target_Buffer
                (S.Feature_Search_Results, 1) = S.Active_Buffer_Token,
              "semantic hover row targets the live buffer token");
      Assert (S.Semantic_Popup.Active
              and then S.Semantic_Popup.Kind = Editor.State.Semantic_Hover_Popup,
              "semantic hover shows a native hover popup");
      Assert (To_String (S.Semantic_Popup.Title) = "Run"
              and then To_String (S.Semantic_Popup.Detail) =
                "procedure (Count : Natural)",
              "semantic hover popup carries label and detail");
      Assert (not Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
              "semantic hover does not force-open the Search Results panel");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "semantic hover selects the projected row");
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Semantic_Popup.Active
              and then Snapshot.Semantic_Popup.Kind =
                Editor.State.Semantic_Hover_Popup,
              "render snapshot exposes semantic hover popup");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Semantic_Hover_Projects_Search_Result_Row;


   overriding procedure Register_Tests
     (T : in out Semantic_Language_Service_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Find_References_Projects_Search_Result_Rows'Access,
         "semantic find references projects search result rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Workspace_Symbols_Project_Search_Result_Rows'Access,
         "semantic workspace symbols project search result rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Completions_Project_Search_Result_Rows'Access,
         "semantic completions project search result rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Semantic_Hover_Projects_Search_Result_Row'Access,
         "semantic hover projects search result row");
   end Register_Tests;

end Editor.Executor.Semantic_Language_Service_Tests;
