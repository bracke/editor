with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Folding;
with Editor.Diagnostics;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.State;

package body Editor.Executor.Diagnostics_Tests is

   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Diagnostics.Diagnostic_Index;
   use type Editor.Feature_Diagnostics.Diagnostic_Quick_Fix_Action_Model;
   use type Editor.Feature_Search_Results.External_Result_Set_Kind;
   use type Editor.Feature_Search_Results.External_Result_Payload;
   use type Editor.Feature_Search_Results.External_Result_Payload_Kind;
   use type Editor.Ada_Language_Service.Index_Status;
   use type Editor.Ada_Language_Service.Service_Status;
   use type Editor.Panels.Bottom_Panel_Content;

   procedure Test_Diagnostics_Execute_Selected_Action_Navigates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "line 1" & ASCII.LF &
         "line 2" & ASCII.LF &
         "line 3" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "semantic action target",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 1);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for selected action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic action executes through command surface");
      Assert (Active_Caret_Line (S) = 3,
              "selected diagnostic action applies navigation effect");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Action_Navigates;

   procedure Test_Diagnostics_Execute_Selected_Explain_Action_Reports
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
      Expected_Message : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "line 1" & ASCII.LF &
         "line 2" & ASCII.LF &
         "line 3" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "semantic explain action",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 1,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for selected explain action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Expected_Message := To_Unbounded_String
        ("Diagnostic action: " &
         Editor.Feature_Diagnostics.Item_Display_Label (S.Feature_Diagnostics, 1));

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic explain action executes through action model");
      Assert (Active_Caret_Line (S) = 1,
              "selected diagnostic explain action must not navigate");
      Assert (Latest_Message_Text (S) = To_String (Expected_Message),
              "selected diagnostic explain action reports projected action label");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "selected diagnostic explain action projects a review row");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "diagnostic action: explain",
              "selected diagnostic explain action labels Search Results");
      Assert (Editor.Feature_Search_Results.Item_Has_Target
                (S.Feature_Search_Results, 1),
              "selected diagnostic explain action row is source-navigable");
      Assert (Editor.Feature_Search_Results.Item_Target_Buffer
                (S.Feature_Search_Results, 1) = S.Active_Buffer_Token,
              "selected diagnostic explain action row targets the live buffer");
      Assert (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "selected diagnostic explain action shows Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Explain_Action_Reports;

   procedure Test_Diagnostics_Execute_Selected_Edit_Action_Applies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Undo_Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "missing semicolon",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 8,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";");
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for selected edit action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic edit action executes");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "selected diagnostic edit action applies the replacement payload");
      Assert (Active_Caret_Line (S) = 1,
              "selected diagnostic edit action does not navigate");

      Undo_Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Undo);
      Assert (Undo_Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic edit action records undo history");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "selected diagnostic edit action is undoable, got: " &
         Editor.State.Current_Text (S));

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Edit_Action_Applies;

   overriding function Name
     (T : Diagnostics_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Diagnostics_Tests");
   end Name;

   procedure Test_Diagnostic_Apply_Quick_Fix_Opens_Action_Picker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "missing semicolon",
         Source_Label  => "semantic",
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
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Command
        (S.Feature_Diagnostics, 1,
         Label  => "Explain missing semicolon",
         Detail => "Open diagnostic explanation",
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);
      Assert
        (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
           (S.Feature_Diagnostics, 1) = 2,
         "fixture diagnostic should expose two quick-fix actions");

      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for quick-fix picker test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "multi-action quick fix opens a picker");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "multi-action quick-fix picker must not apply the first edit immediately");
      Assert (Latest_Message_Text (S) = "Choose a diagnostic quick fix",
              "multi-action quick-fix picker reports selection flow");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
              "quick-fix picker projects one row per action");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              Editor.Feature_Diagnostics.Diagnostic_Quick_Fix_Picker_Query_Text,
              "quick-fix picker labels Search Results");
      Assert
        (Editor.Feature_Search_Results.External_Kind (S.Feature_Search_Results) =
         Editor.Feature_Search_Results.Diagnostic_Quick_Fix_Action_List,
         "quick-fix picker exposes typed Search Results action-list kind");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Feature_Panel_Open_Selected);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "opening selected quick-fix picker row executes the chosen action, got status" &
              Editor.Executor.Command_Execution_Status'Image (Result.Status) &
              " message " & Latest_Message_Text (S));
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "selected quick-fix picker action applies its edit");
      Assert
        (not Editor.State.Has_Pending_Quick_Fix_Workflow (S)
         and then Editor.State.Pending_Quick_Fix_Action_Index (S) = 0,
         "quick-fix picker state is cleared after execution");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostic_Apply_Quick_Fix_Opens_Action_Picker;

   procedure Test_Diagnostic_Quick_Fix_Picker_Executes_Non_Edit_Action
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "missing semicolon",
         Source_Label  => "semantic",
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
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Unavailable
        (S.Feature_Diagnostics, 1,
         Label  => "Unavailable quick fix",
         Detail => "No edit or command");
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Command
        (S.Feature_Diagnostics, 1,
         Label  => "Explain missing semicolon",
         Detail => "Open diagnostic explanation",
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic);

      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for non-edit quick-fix picker test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "multi-action quick fix opens picker for non-edit action test");
      Assert
        (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 2,
         "quick-fix picker skips inert actions");
      Assert
        (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Model
           (S.Feature_Diagnostics, 1, 2) =
         Editor.Feature_Diagnostics.Quick_Fix_Action_Unavailable,
         "inert quick-fix action is explicitly modelled unavailable");
      Assert
        (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Model
           (S.Feature_Diagnostics, 1, 3) =
         Editor.Feature_Diagnostics.Quick_Fix_Action_Command,
         "non-edit quick-fix action is explicitly modelled as a command");
      Assert
        (Editor.Feature_Search_Results.Item_External_Payload
           (S.Feature_Search_Results, 2) =
         Editor.Feature_Search_Results.Quick_Fix_Action_Result_Payload (3),
         "quick-fix picker preserves the original action index after filtering");
      Assert
        (Editor.Feature_Search_Results.Item_External_Payload
           (S.Feature_Search_Results, 2).Kind =
         Editor.Feature_Search_Results.Quick_Fix_Action_Payload,
         "quick-fix picker uses typed external payload metadata");

      Editor.Executor.Panel_Focus_Commands.Execute_Focus_Search_Results (S);
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 2);
      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Open_Selected (S);

      Assert
        (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
         "diagnostic action: explain",
         "opening focused Search Results quick-fix row executes the typed payload action");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "non-edit quick-fix picker action does not mutate buffer text");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Search Results quick-fix activation returns focus to editor text");
      Assert
        (not Editor.State.Has_Pending_Quick_Fix_Workflow (S)
         and then Editor.State.Pending_Quick_Fix_Action_Index (S) = 0,
         "non-edit quick-fix picker clears workflow state");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostic_Quick_Fix_Picker_Executes_Non_Edit_Action;

   procedure Test_Diagnostic_Quick_Fix_Execution_Rejects_Invalid_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Rejected
        (Action_Index    : Natural;
         Expected_Reason : String)
      is
         S      : Editor.State.State_Type;
         Result : Editor.Executor.Command_Execution_Result;
      begin
         Init_Executor_Test_State (S);
         Editor.State.Load_Text
           (S,
            "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "   null" & ASCII.LF &
            "end Demo;" & ASCII.LF);

         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Editor.Feature_Diagnostics.Diagnostic_Error,
            "missing semicolon",
            Source_Label  => "semantic",
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
         Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Unavailable
           (S.Feature_Diagnostics, 1,
            Label  => "Unavailable quick fix",
            Detail => "No edit or command");

         Editor.State.Start_Quick_Fix_Workflow (S, 1, Action_Index);
         Result := Editor.Executor.Execute_Command_With_Result
           (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);

         Assert
           (Result.Status = Editor.Executor.Command_Unavailable,
            "invalid quick-fix action is rejected before descriptor execution");
         Assert
           (Latest_Message_Text (S) = Expected_Reason,
            "invalid quick-fix action reports specific reason: "
            & Latest_Message_Text (S));
         Assert
           (Editor.State.Current_Text (S) =
            "procedure Demo is" & ASCII.LF &
            "begin" & ASCII.LF &
            "   null" & ASCII.LF &
            "end Demo;" & ASCII.LF,
            "invalid quick-fix action does not mutate the buffer");
         Assert
           (not Editor.State.Has_Pending_Quick_Fix_Workflow (S)
            and then Editor.State.Pending_Quick_Fix_Action_Index (S) = 0,
            "invalid quick-fix execution clears pending workflow");

         Editor.Buffers.Reset_Global_For_Test;
      end Assert_Rejected;
   begin
      Assert_Rejected (2, "Quick fix action has no valid edit or command");
      Assert_Rejected (99, "Quick fix action unavailable");
   end Test_Diagnostic_Quick_Fix_Execution_Rejects_Invalid_Actions;

   procedure Test_Diagnostic_Quick_Fix_Availability_Reasons_Are_Specific
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Shown  : Boolean;
      Stale_Index : Natural := 0;
      Missing_Buffer_Index : Natural := 0;
      Invalid_Line_Index : Natural := 0;
      Invalid_Column_Index : Natural := 0;
      Inert_Index : Natural := 0;

      procedure Add_Edit_Quick_Fix
        (Message       : String;
         Target_Buffer : Natural;
         Target_Line   : Natural;
         Target_Column : Natural)
      is
      begin
         Editor.Feature_Diagnostics.Add_Diagnostic
           (S.Feature_Diagnostics,
            Editor.Feature_Diagnostics.Diagnostic_Error,
            Message,
            Source_Label  => "semantic",
            Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
            Has_Target    => True,
            Target_Buffer => Target_Buffer,
            Target_Line   => Target_Line,
            Target_Column => Target_Column,
            Has_Edit          => True,
            Edit_Start_Line   => 1,
            Edit_Start_Column => 1,
            Edit_End_Line     => 1,
            Edit_End_Column   => 1,
            Replacement_Text  => "x",
            Quick_Fix_Label   => "Apply edit",
            Quick_Fix_Detail  => "Edit target");
      end Add_Edit_Quick_Fix;

      procedure Assert_Unavailable
        (Diagnostic_Index : Positive;
         Action_Index     : Natural;
         Expected_Reason  : String)
      is
         Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
             (S, Natural (Diagnostic_Index), Action_Index);
      begin
         Assert (not Editor.Commands.Is_Available (Availability),
                 "quick-fix action should be unavailable: " & Expected_Reason);
         Assert (Editor.Commands.Unavailable_Reason (Availability) = Expected_Reason,
                 "quick-fix unavailable reason should be specific: expected "
                 & Expected_Reason & " got "
                 & Editor.Commands.Unavailable_Reason (Availability));
      end Assert_Unavailable;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "line 1" & ASCII.LF &
         "line 2" & ASCII.LF);

      Add_Edit_Quick_Fix ("stale quick fix", S.Active_Buffer_Token, 1, 1);
      Stale_Index := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
        (S.Feature_Diagnostics, S.Active_Buffer_Token);

      Add_Edit_Quick_Fix ("missing buffer quick fix", 9999, 1, 1);
      Missing_Buffer_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Add_Edit_Quick_Fix ("invalid line quick fix", S.Active_Buffer_Token, 99, 1);
      Invalid_Line_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Add_Edit_Quick_Fix ("invalid column quick fix", S.Active_Buffer_Token, 1, 99);
      Invalid_Column_Index :=
        Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Add_Edit_Quick_Fix ("inert quick fix", S.Active_Buffer_Token, 1, 1);
      Inert_Index := Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics);
      Editor.Feature_Diagnostics.Append_Diagnostic_Quick_Fix_Unavailable
        (S.Feature_Diagnostics, Positive (Inert_Index),
         Label  => "Unavailable quick fix",
         Detail => "No edit or command");

      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for quick-fix reason test");
      Select_Diagnostic_By_Message (S, "invalid column quick fix");

      Assert_Unavailable
        (Positive (Stale_Index), 1, Editor.Commands.Reason_Target_Stale);
      Assert_Unavailable
        (Positive (Missing_Buffer_Index), 1, Editor.Commands.Reason_Target_Missing);
      Assert_Unavailable
        (Positive (Invalid_Line_Index), 1, Editor.Commands.Reason_Diagnostic_Target_Line_Outside_Buffer);
      Assert_Unavailable
        (Positive (Invalid_Column_Index), 1, Editor.Commands.Reason_Diagnostic_Target_Column_Outside_Line);
      Assert_Unavailable
        (Positive (Inert_Index), 2, "Quick fix action has no valid edit or command");
      Assert_Unavailable
        (Positive (Inert_Index), 99, "Quick fix action unavailable");
      Assert
        (Editor.Commands.Is_Available
           (Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
              (S, Inert_Index, 1)),
         "valid quick-fix action remains available");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostic_Quick_Fix_Availability_Reasons_Are_Specific;

   procedure Test_Diagnostics_Execute_Selected_Action_Rejects_No_Action
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Result      : Editor.Executor.Command_Execution_Result;
      Shown       : Boolean;
      Open_Avail  : Editor.Commands.Command_Availability;
      Action_Avail : Editor.Commands.Command_Availability;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "line 1" & ASCII.LF &
         "line 2" & ASCII.LF);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "semantic diagnostic with no action",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 2,
         Target_Column => 1,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_None);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for no-action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Open_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Open_Selected);
      Action_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Editor.Commands.Is_Available (Open_Avail),
              "diagnostic with no primary action can still be opened");
      Assert (not Editor.Commands.Is_Available (Action_Avail),
              "diagnostic with no primary action must not advertise action execution");
      Assert (Editor.Commands.Unavailable_Reason (Action_Avail) =
              "Diagnostic action unavailable",
              "no-action diagnostic availability reports action-specific reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "no-action diagnostic execution is classified unavailable");
      Assert (Latest_Message_Text (S) = "Diagnostic action unavailable",
              "no-action diagnostic execution reports availability reason");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 0,
              "no-action diagnostic must not project stale Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Action_Rejects_No_Action;

   procedure Test_Diagnostics_Execute_Selected_Action_Rejects_Missing_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "line 1" & ASCII.LF);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "semantic action without target",
         Source_Label => "semantic",
         Source_Kind  => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target   => False);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for missing-target action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "selected diagnostic action with no target is unavailable");
      Assert (Latest_Message_Text (S) = Editor.Commands.Reason_Target_Missing,
              "missing-target selected diagnostic action reports diagnostic target reason");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Action_Rejects_Missing_Target;

   procedure Test_Diagnostics_Execute_Selected_Action_Rejects_Stale_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "line 1" & ASCII.LF &
         "line 2" & ASCII.LF &
         "line 3" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "stale semantic action target",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 1);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
        (S.Feature_Diagnostics, S.Active_Buffer_Token);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for stale selected action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "stale selected diagnostic action is unavailable");
      Assert (Active_Caret_Line (S) = 1,
              "stale selected diagnostic action must not navigate");
      Assert
        (Latest_Message_Text (S) = Editor.Commands.Reason_Target_Stale,
         "stale selected diagnostic action reports canonical stale rejection");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Action_Rejects_Stale_Target;

   procedure Test_Diagnostics_Execute_Selected_Multiline_Edit_Action_Applies
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Undo_Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "expand null statement",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 4,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 4,
         Edit_End_Line     => 3,
         Edit_End_Column   => 9,
         Replacement_Text  =>
           "declare" & ASCII.LF &
           "   pragma Assert (True);" & ASCII.LF &
           "begin" & ASCII.LF &
           "   null;" & ASCII.LF &
           "end;");
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for selected multi-line edit action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic multi-line edit action executes");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   declare" & ASCII.LF &
         "   pragma Assert (True);" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "selected diagnostic multi-line edit action applies replacement text");
      Assert (Active_Caret_Line (S) = 1,
              "selected diagnostic multi-line edit action does not navigate");

      Undo_Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Undo);
      Assert (Undo_Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic multi-line edit action records undo history");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "selected diagnostic multi-line edit action is undoable");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Multiline_Edit_Action_Applies;

   procedure Test_Diagnostics_Execute_Selected_Edit_Action_Updates_Open_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package LM renames Editor.Ada_Language_Model;

      S          : Editor.State.State_Type;
      Active_Id  : Editor.Buffers.Buffer_Id;
      Target_Id  : Editor.Buffers.Buffer_Id;
      Analysis   : LM.Analysis_Result;
      Ignored    : LM.Symbol_Id;
      Result     : Editor.Executor.Command_Execution_Result;
      Available  : Editor.Commands.Command_Availability;
      Shown      : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer
        ("/project/main.adb", "main.adb",
         "procedure Main is null;" & ASCII.LF,
         Active_Id);
      Editor.Buffers.Global_Add_File_Buffer
        ("/project/worker.adb", "worker.adb",
         "procedure Worker is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null" & ASCII.LF &
         "end Worker;" & ASCII.LF,
         Target_Id);
      Editor.Buffers.Global_Set_Active_Buffer (Active_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);

      Ignored := LM.Add_Symbol
        (Analysis, "Worker", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 11, End_Line => 1, End_Column => 16));
      Editor.Ada_Project_Index.Put_Analysis
        (S.Language_Index, "/project/worker.adb",
         Buffer_Token         => Natural (Target_Id),
         Buffer_Revision      =>
           Editor.Buffers.Global_Buffer (Target_Id).Buffer_Revision,
         Lifecycle_Generation =>
           Editor.Buffers.Global_Buffer (Target_Id).Lifecycle_Generation,
         Analysis             => Analysis);
      Editor.Ada_Language_Service.Put_Index
        (S.Language_Service, S.Language_Index);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "missing semicolon",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => Natural (Target_Id),
         Target_Line   => 3,
         Target_Column => 8,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 8,
         Edit_End_Line     => 3,
         Edit_End_Column   => 8,
         Replacement_Text  => ";");
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for inactive-buffer edit action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Available := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);
      Assert (Editor.Commands.Is_Available (Available),
              "selected diagnostic edit action is available for inactive open buffer");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic edit action executes for inactive open buffer");
      Assert
        (Ada.Strings.Fixed.Index (Latest_Message_Text (S), " in semantic:3:8") > 0,
         "inactive-buffer diagnostic edit reports the changed source, got: " &
         Latest_Message_Text (S));
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Main is null;" & ASCII.LF,
         "inactive-buffer diagnostic edit leaves active buffer unchanged");
      Assert
        (Editor.State.Current_Text (Editor.Buffers.Global_Buffer (Target_Id)) =
         "procedure Worker is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Worker;" & ASCII.LF,
         "selected diagnostic edit action updates the inactive open buffer");
      Assert (not Editor.Ada_Project_Index.Contains_Path
                    (S.Language_Index, "/project/worker.adb"),
              "inactive-buffer diagnostic edit invalidates changed semantic index entry");
      Assert (Editor.Ada_Language_Service.Status (S.Language_Service) =
              Editor.Ada_Language_Service.Status (S.Language_Index),
              "inactive-buffer diagnostic edit keeps service invalidation aligned");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Edit_Action_Updates_Open_Buffer;

   procedure Test_Diagnostics_Execute_Selected_Edit_Rejects_Invalid_End
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Availability : Editor.Commands.Command_Availability;
      Shown  : Boolean;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "replace statement",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 3,
         Target_Column => 4,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Explain_Diagnostic,
         Has_Edit          => True,
         Edit_Start_Line   => 3,
         Edit_Start_Column => 4,
         Edit_End_Line     => 3,
         Edit_End_Column   => 200,
         Replacement_Text  => "raise Program_Error;");
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for invalid edit-end test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);
      Assert (not Editor.Commands.Is_Available (Availability),
              "selected diagnostic edit action preflight rejects invalid edit end");
      Assert
        (Editor.Commands.Unavailable_Reason (Availability) =
         "Diagnostic edit unavailable: stale edit target",
         "invalid diagnostic edit end should report the executor rejection reason");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "selected diagnostic edit action rejects out-of-range edit end");
      Assert
        (Editor.State.Current_Text (S) =
         "procedure Demo is" & ASCII.LF &
         "begin" & ASCII.LF &
         "   null;" & ASCII.LF &
         "end Demo;" & ASCII.LF,
         "invalid diagnostic edit end must leave buffer unchanged");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Edit_Rejects_Invalid_End;

   procedure Test_Diagnostics_Execute_Selected_Review_Action_Projects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Shown  : Boolean;
      Expected_Message : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S,
         "with Lib;" & ASCII.LF &
         "procedure Main is null;" & ASCII.LF);
      Move_Caret_To_Line (S, 1);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "semantic cross-unit review",
         Source_Label  => "semantic",
         Source_Kind   => Editor.Feature_Diagnostics.Editor_Diagnostic_Source,
         Has_Target    => True,
         Target_Buffer => S.Active_Buffer_Token,
         Target_Line   => 2,
         Target_Column => 11,
         Primary_Action_Kind =>
           Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Review_Cross_Unit);
      Shown := Editor.Feature_Panel_Controller.Show_Feature
        (S, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Shown, "diagnostics feature is shown for selected review action test");
      Editor.Feature_Panel.Select_Row (S.Feature_Panel, 1);
      Expected_Message := To_Unbounded_String
        ("Diagnostic action: " &
         Editor.Feature_Diagnostics.Item_Display_Label (S.Feature_Diagnostics, 1));

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Execute_Selected_Action);

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "selected diagnostic review action executes through action model");
      Assert (Active_Caret_Line (S) = 1,
              "selected diagnostic review action must not navigate");
      Assert (Latest_Message_Text (S) = To_String (Expected_Message),
              "selected diagnostic review action reports projected action label");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) = 1,
              "selected diagnostic review action projects a review row");
      Assert (Editor.Feature_Search_Results.Query_Text (S.Feature_Search_Results) =
              "diagnostic action: review cross-unit",
              "selected diagnostic review action labels Search Results");
      Assert (Editor.Feature_Search_Results.Item_Target_Line
                (S.Feature_Search_Results, 1) = 2,
              "selected diagnostic review action row preserves target line");
      Assert (Editor.Feature_Search_Results.Item_Target_Column
                (S.Feature_Search_Results, 1) = 11,
              "selected diagnostic review action row preserves target column");
      Assert (Editor.Feature_Search_Results.Item_Match_Length
                (S.Feature_Search_Results, 1) = 1,
              "selected diagnostic review action row carries action span");
      Assert (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
              and then Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "selected diagnostic review action shows Search Results");

      Editor.Buffers.Reset_Global_For_Test;
   end Test_Diagnostics_Execute_Selected_Review_Action_Projects;

   procedure Test_Diagnostic_Jump_Invalid_And_Empty_Cases
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Before : Editor.Cursors.Cursor_Index;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc");
      Before := Editor.Executor.Safe_Caret (S);

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Next_Diagnostic (S);
      Assert
        (Editor.Executor.Safe_Caret (S) = Before,
         "next diagnostic with no diagnostics must preserve the caret");

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic (S, 99);
      Assert
        (Editor.Executor.Safe_Caret (S) = Before,
         "invalid diagnostic jump must preserve the caret");
   end Test_Diagnostic_Jump_Invalid_And_Empty_Cases;

   procedure Test_Diagnostic_Jump_Expands_Hidden_Fold
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text
        (S, "0" & ASCII.LF & "1" & ASCII.LF & "2" & ASCII.LF & "3");
      Editor.Folding.Add_Fold (S.Folding, 1, 3);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 1);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic (S, 1);

      Assert
        (not Editor.Folding.Is_Fold_Collapsed (S.Folding, 1),
         "diagnostic jump should expand the fold hiding its target row");
      Assert
        (Editor.Executor.Safe_Caret (S) = 4,
         "diagnostic jump inside a folded range should land on the target row");
   end Test_Diagnostic_Jump_Expands_Hidden_Fold;

   procedure Test_Jump_To_Diagnostic_Moves_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error,
         Message => "bad");

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic (S, 1);

      Assert
        (Editor.Executor.Safe_Caret (S) = 5,
         "jump-to-diagnostic should move the primary caret to the diagnostic start");
      Assert
        (S.Active_Diagnostic.Has_Active and then S.Active_Diagnostic.Index = 1,
         "jump-to-diagnostic should record the active diagnostic");
      Assert
        (not S.File_Info.Dirty,
         "jump-to-diagnostic should not dirty the buffer");
   end Test_Jump_To_Diagnostic_Moves_Caret;

   procedure Test_Next_Previous_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def" & ASCII.LF & "ghi");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 1, End_Index => 2,
         Severity => Editor.Diagnostics.Warning);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Next_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 1,
              "next diagnostic from document start should jump to first diagnostic");
      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Next_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 5,
              "next diagnostic should advance from active diagnostic");
      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Previous_Diagnostic (S);
      Assert (Editor.Executor.Safe_Caret (S) = 1,
              "previous diagnostic should move back from active diagnostic");
   end Test_Next_Previous_Diagnostic;

   procedure Test_Jump_To_Diagnostic_On_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Warning);
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Error);

      Editor.Executor.Diagnostics_Navigation_Commands.Execute_Jump_To_Diagnostic_On_Row (S, 1);
      Assert (Editor.Executor.Safe_Caret (S) = 5,
              "row diagnostic jump should choose dominant severity on the row");
   end Test_Jump_To_Diagnostic_On_Row;


   overriding procedure Register_Tests (T : in out Diagnostics_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Action_Navigates'Access,
         "Diagnostics execute selected action navigates");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Jump_Invalid_And_Empty_Cases'Access,
         "diagnostic empty and invalid jumps are non-mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Jump_Expands_Hidden_Fold'Access,
         "diagnostic jump expands hidden fold");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Explain_Action_Reports'Access,
         "Diagnostics execute selected explain action reports without navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Edit_Action_Applies'Access,
         "Diagnostics execute selected edit action applies replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Apply_Quick_Fix_Opens_Action_Picker'Access,
         "diagnostic quick-fix with multiple actions opens picker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Quick_Fix_Picker_Executes_Non_Edit_Action'Access,
         "diagnostic quick-fix picker executes selected non-edit action");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Quick_Fix_Availability_Reasons_Are_Specific'Access,
         "Diagnostic quick fix availability reasons are specific");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostic_Quick_Fix_Execution_Rejects_Invalid_Actions'Access,
         "Diagnostic quick fix execution rejects invalid actions");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Action_Rejects_No_Action'Access,
         "Diagnostics execute selected action rejects no-action rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Action_Rejects_Missing_Target'Access,
         "Diagnostics execute selected action rejects missing target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Action_Rejects_Stale_Target'Access,
         "Diagnostics execute selected action rejects stale target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Multiline_Edit_Action_Applies'Access,
         "Diagnostics execute selected edit action applies multi-line replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Edit_Action_Updates_Open_Buffer'Access,
         "Diagnostics execute selected edit action updates open buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Edit_Rejects_Invalid_End'Access,
         "Diagnostics execute selected edit action rejects invalid edit end");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Diagnostics_Execute_Selected_Review_Action_Projects'Access,
         "Diagnostics execute selected review action projects Search Results");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Jump_To_Diagnostic_Moves_Caret'Access,
         "diagnostic jump moves caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Next_Previous_Diagnostic'Access,
         "next and previous diagnostic navigation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Jump_To_Diagnostic_On_Row'Access,
         "row diagnostic jump chooses dominant diagnostic");
   end Register_Tests;

end Editor.Executor.Diagnostics_Tests;
