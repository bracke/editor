with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Cursors;
with Editor.Diagnostics;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Panels;
with Editor.Problems;
with Editor.State;
with Editor.Layout;

package body Editor.Problems.Tests is

   use type Editor.Problems.Problem_Row_Severity;
   use type Editor.Problems.Problems_Group_Mode;
   use type Editor.Problems.Problems_Header_Action;
   use type Editor.Problems.Problems_Sort_Mode;
   use type Editor.Problems.Problems_Severity_Filter;
   use type Editor.Problems.Problems_Zone;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Diagnostics.Diagnostic_Index;

   function Name
     (T : Problems_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Problems.Tests");
   end Name;

   procedure Test_Empty_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : constant Editor.Problems.Problems_Snapshot :=
        Editor.Problems.Build_Snapshot (Diagnostics);
   begin
      Assert
        (Editor.Problems.Row_Count (Snapshot) = 0,
         "empty diagnostics should build an empty Problems snapshot");
      Assert
        (Editor.Problems.Message_No_Problems =
           Editor.Feature_Diagnostics.Message_No_Diagnostics,
         "Problems and Diagnostics share the empty-state message");
      Assert
        (Editor.Problems.Message_No_Visible_Problems =
           Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic,
         "Problems and Diagnostics share the filtered-empty message");
      Assert
        (Editor.Problems.Empty_State_Message (0, 0) =
           Editor.Problems.Message_No_Problems,
         "empty Problems message should describe truly empty diagnostics");
      Assert
        (Editor.Problems.Empty_State_Message (0, 3) =
           Editor.Problems.Message_No_Visible_Problems,
         "empty Problems message should describe filtered diagnostics");
      Assert
        (Editor.Problems.Empty_State_Message (2, 3) = "",
         "non-empty Problems snapshots should not expose empty-state text");
   end Test_Empty_Snapshot;

   procedure Test_Severity_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Row : Editor.Problems.Problem_Row;
   begin
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error,
         Message => "missing ;");
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 1, End_Index => 2,
         Severity => Editor.Diagnostics.Warning);

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Assert (Editor.Problems.Row_Count (Snapshot) = 2,
              "two diagnostics should produce two Problems rows");

      Row := Editor.Problems.Row (Snapshot, 1);
      Assert (Row.Severity = Editor.Problems.Problem_Error,
              "diagnostic Error should map to Problem_Error");
      Assert (To_String (Row.Message) = "missing ;",
              "Problems snapshot should preserve diagnostic message text");

      Row := Editor.Problems.Row (Snapshot, 2);
      Assert (Row.Severity = Editor.Problems.Problem_Warning,
              "diagnostic Warning should map to Problem_Warning");
   end Test_Severity_Mapping;

   procedure Test_State_Row_Column_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Row : Editor.Problems.Problem_Row;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.State.Add_Diagnostic
        (S, Start_Index => 5, End_Index => 6,
         Severity => Editor.Diagnostics.Information);

      Snapshot := Editor.Problems.Build_Snapshot (S.Diagnostics);
      Assert (Editor.Problems.Row_Count (Snapshot) = 1,
              "state diagnostics should project into one Problems row");
      Row := Editor.Problems.Row (Snapshot, 1);
      Assert (Row.Row = 1,
              "diagnostic start index should map to zero-based row 1");
      Assert (Row.Column = 1,
              "diagnostic start index should map to zero-based column 1");
      Assert (Editor.Problems.Row_Has_Target (Row),
              "state diagnostic with location should expose a Problems target");
   end Test_State_Row_Column_Projection;

   procedure Test_Filtered_Visible_Snapshot_Uses_Filtered_Empty_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Filtered : Editor.Problems.Problems_Snapshot;
      Visible : Editor.Problems.Problems_Snapshot;
      View : Editor.Problems.Problems_View_State;
   begin
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error,
         Message => "missing ;");

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Visible := Editor.Problems.Visible_Snapshot
        (Snapshot, View, 0);

      Assert (Editor.Problems.Row_Count (Snapshot) = 1,
              "source Problems snapshot should retain the diagnostic");
      Assert (Editor.Problems.Row_Count (Visible) = 0,
              "filtered visible Problems snapshot should be empty");
      Assert
        (Editor.Problems.Empty_State_Message
           (Editor.Problems.Row_Count (Visible),
            Editor.Problems.Row_Count (Snapshot)) =
         Editor.Problems.Message_No_Visible_Problems,
         "filtered Problems render state should use the filtered-empty message");
   end Test_Filtered_Visible_Snapshot_Uses_Filtered_Empty_Message;

   procedure Test_Severity_Filter_Applies_Before_Viewport
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Filtered : Editor.Problems.Problems_Snapshot;
      Visible : Editor.Problems.Problems_Snapshot;
      View : Editor.Problems.Problems_View_State;
   begin
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Warning,
         Message => "unused");
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 2, End_Index => 3,
         Severity => Editor.Diagnostics.Error,
         Message => "missing ;");
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 4, End_Index => 5,
         Severity => Editor.Diagnostics.Hint,
         Message => "consider renaming");

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Editor.Problems.Set_Top_Row (View, 1);
      Editor.Problems.Set_Severity_Filter
        (View, Editor.Problems.Problems_Show_Errors);
      Filtered := Editor.Problems.Filtered_Snapshot (Snapshot, View);
      Visible := Editor.Problems.Visible_Snapshot (Snapshot, View, 1);

      Assert (Editor.Problems.Row_Count (Snapshot) = 3,
              "source Problems snapshot should retain every diagnostic");
      Assert (Editor.Problems.Row_Count (Filtered) = 1,
              "filtered Problems snapshot should contain one matching row");
      Assert
        (Editor.Problems.Row (Filtered, 1).Severity =
         Editor.Problems.Problem_Error,
         "filtered Problems snapshot should retain the matching severity");
      Assert (Editor.Problems.Row_Count (Visible) = 1,
              "severity filter should reduce visible Problems rows");
      Assert
        (Editor.Problems.Row (Visible, 1).Severity =
         Editor.Problems.Problem_Error,
         "severity filter should be applied before viewport slicing");
      Assert
        (Editor.Problems.Format_Header
           ((others => <>), Editor.Problems.Row_Count (Snapshot),
            Editor.Problems.Severity_Filter (View)) =
         "Problems: 3 (errors)",
         "Problems header should expose the active severity filter");
   end Test_Severity_Filter_Applies_Before_Viewport;

   procedure Test_Review_Snapshot_Groups_And_Sorts_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Review : Editor.Problems.Problems_Snapshot;
      View : Editor.Problems.Problems_View_State;
      External_Row : constant Editor.Problems.Problem_Row :=
        (Diagnostic_Index => Editor.Diagnostics.No_Diagnostic,
         Severity         => Editor.Problems.Problem_Warning,
         Row              => 0,
         Column           => 0,
         Message          => To_Unbounded_String ("external"),
         Source_File      => To_Unbounded_String ("src/main.adb"),
         Has_Target       => True,
         Quick_Fix_Label  => Null_Unbounded_String,
         Quick_Fix_Detail => Null_Unbounded_String);
   begin
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 0, End_Index => 1,
         Start_Row => 20, Start_Column => 0,
         Severity => Editor.Diagnostics.Warning,
         Message => "warning");
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 2, End_Index => 3,
         Start_Row => 10, Start_Column => 0,
         Severity => Editor.Diagnostics.Error,
         Message => "error");
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 4, End_Index => 5,
         Start_Row => 1, Start_Column => 0,
         Severity => Editor.Diagnostics.Hint,
         Message => "hint");

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Assert
        (Editor.Problems.Severity_Count
           (Snapshot, Editor.Problems.Problem_Error) = 1,
         "Problems review snapshot should count errors");
      Assert
        (Editor.Problems.Severity_Count
           (Snapshot, Editor.Problems.Problem_Warning) = 1,
         "Problems review snapshot should count warnings");
      Assert
        (Editor.Problems.Group_Label
           (Editor.Problems.Row (Snapshot, 1),
            Editor.Problems.Problems_Group_By_Source) = "current buffer",
         "Problems source grouping should name diagnostics without source files");
      Assert
        (Editor.Problems.Group_Label
           (External_Row, Editor.Problems.Problems_Group_By_Source) =
         "src/main.adb",
         "Problems source grouping should use available source labels");
      Assert
        (Editor.Problems.Sort_Mode_Label
           (Editor.Problems.Problems_Sort_By_Severity) = "severity",
         "Problems sort mode label should be product-facing");
      Assert
        (Editor.Problems.Group_Mode_Label
           (Editor.Problems.Problems_Group_By_Source) = "source",
         "Problems group mode label should be product-facing");
      Assert
        (Editor.Problems.Header_Action_Hint (View) =
         "actions: [filter all] [sort location] [group severity]",
         "Problems header should expose filter/sort/group actions");
      Assert
        (Editor.Problems.Header_Action_Label
           (View, Editor.Problems.Problems_Header_Filter_Action) =
         "[filter all]",
         "Problems header filter affordance should be a stable action label");
      Assert
        (Editor.Problems.Header_Action_At_X (90, 0) =
         Editor.Problems.Problems_Header_Filter_Action,
         "Problems header left hit zone should map to filter");
      Assert
        (Editor.Problems.Header_Action_At_X (90, 35) =
         Editor.Problems.Problems_Header_Sort_Action,
         "Problems header middle hit zone should map to sort");
      Assert
        (Editor.Problems.Header_Action_At_X (90, 70) =
         Editor.Problems.Problems_Header_Group_Action,
         "Problems header right hit zone should map to group");

      View.Sort_Mode := Editor.Problems.Problems_Sort_By_Severity;
      Review := Editor.Problems.Review_Snapshot (Snapshot, View);
      Assert
        (Editor.Problems.Row (Review, 1).Severity =
         Editor.Problems.Problem_Error,
         "Problems severity sort should put errors first");
      Assert
        (Editor.Problems.Row (Review, 2).Severity =
         Editor.Problems.Problem_Warning,
         "Problems severity sort should put warnings before hints");

      View.Sort_Mode := Editor.Problems.Problems_Sort_By_Location;
      Review := Editor.Problems.Review_Snapshot (Snapshot, View);
      Assert
        (Editor.Problems.Row (Review, 1).Row = 1,
         "Problems location sort should restore row order");
   end Test_Review_Snapshot_Groups_And_Sorts_Rows;

   procedure Test_Severity_Filter_Commands_Update_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Warning,
         Message => "unused");
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 2, End_Index => 3,
         Severity => Editor.Diagnostics.Error,
         Message => "missing ;");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_Errors);
      Assert
        (Editor.Problems.Severity_Filter (S.Problems_View) =
         Editor.Problems.Problems_Show_Errors,
         "Problems filter command should select error filter");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
         Editor.Panels.Problems_Content,
         "Problems filter command should reveal the Problems panel");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_All);
      Assert
        (Editor.Problems.Severity_Filter (S.Problems_View) =
         Editor.Problems.Problems_Show_All,
         "Problems clear filter command should show all severities");
   end Test_Severity_Filter_Commands_Update_View;

   procedure Test_Problems_Review_Mode_Commands_Update_View
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 0, End_Index => 1,
         Start_Row => 20, Start_Column => 0,
         Severity => Editor.Diagnostics.Warning,
         Message => "unused");
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 2, End_Index => 3,
         Start_Row => 5, Start_Column => 0,
         Severity => Editor.Diagnostics.Error,
         Message => "missing ;");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Sort_By_Severity);
      Assert
        (S.Problems_View.Sort_Mode =
         Editor.Problems.Problems_Sort_By_Severity,
         "Problems sort command should select severity sort");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
         Editor.Panels.Problems_Content,
         "Problems sort command should reveal the Problems panel");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Sort_By_Source);
      Assert
        (S.Problems_View.Sort_Mode =
         Editor.Problems.Problems_Sort_By_Source,
         "Problems sort command should select source sort");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Group_By_Source);
      Assert
        (S.Problems_View.Group_Mode =
         Editor.Problems.Problems_Group_By_Source,
         "Problems group command should select source grouping");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Group_By_Severity);
      Assert
        (S.Problems_View.Group_Mode =
         Editor.Problems.Problems_Group_By_Severity,
         "Problems group command should select severity grouping");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Sort_By_Location);
      Assert
        (S.Problems_View.Sort_Mode =
         Editor.Problems.Problems_Sort_By_Location,
         "Problems sort command should restore location sort");
   end Test_Problems_Review_Mode_Commands_Update_View;

   procedure Test_Filtered_Problem_Movement_Uses_Filtered_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Filtered : Editor.Problems.Problems_Snapshot;
   begin
      Editor.State.Init (S);
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Warning,
         Message => "smoke warning");
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 2, End_Index => 3,
         Severity => Editor.Diagnostics.Error,
         Message => "smoke error");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_Errors);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Move_Down);

      Snapshot := Editor.Problems.Build_Snapshot (S.Diagnostics);
      Filtered := Editor.Problems.Filtered_Snapshot (Snapshot, S.Problems_View);
      Assert
        (Editor.Problems.Row_Count (Filtered) = 1,
         "Problems movement should operate on the filtered snapshot");
      Assert
        (Editor.Problems.Selected_Row_Index (S.Problems_View) = 1,
         "Problems movement should not select an unfiltered row");
      Assert
        (Editor.Problems.Row (Filtered, 1).Severity =
         Editor.Problems.Problem_Error,
         "Problems filtered selection should still target the error row");
   end Test_Filtered_Problem_Movement_Uses_Filtered_Rows;

   procedure Test_Problems_Open_Selected_Uses_Target_Parity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Row : Editor.Problems.Problem_Row;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 0, End_Index => 1,
         Severity => Editor.Diagnostics.Error,
         Message => "message-only error");
      Snapshot := Editor.Problems.Build_Snapshot (S.Diagnostics);
      Row := Editor.Problems.Row (Snapshot, 1);
      Assert (not Editor.Problems.Row_Has_Target (Row),
              "message-only diagnostic should not expose a Problems target");
      Assert
        (Editor.Problems.Row_Target_Unavailable_Label (Row) =
         "Selected diagnostic has no source target.",
         "Problems target parity should explain missing source targets");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_Errors);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Open_Selected);
      Assert
        (not S.Active_Diagnostic.Has_Active,
         "Problems open-selected must not activate a diagnostic without target");

      Editor.Diagnostics.Clear (S.Diagnostics);
      Editor.Diagnostics.Add
        (S.Diagnostics, Start_Index => 5, End_Index => 6,
         Start_Row => 1, Start_Column => 1,
         Severity => Editor.Diagnostics.Error,
         Message => "located error");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Filter_Errors);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Problems_Open_Selected);
      Assert
        (S.Active_Diagnostic.Has_Active and then S.Active_Diagnostic.Index = 1,
         "Problems open-selected should activate the filtered located diagnostic");
   end Test_Problems_Open_Selected_Uses_Target_Parity;

   procedure Test_Format_Header_And_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Editor.Problems.Problems_View_Config := (others => <>);
      Row : constant Editor.Problems.Problem_Row :=
        (Diagnostic_Index => Editor.Diagnostics.No_Diagnostic,
         Severity         => Editor.Problems.Problem_Error,
         Row              => 11,
         Column           => 4,
         Message          => To_Unbounded_String ("missing ;"),
         Source_File      => Null_Unbounded_String,
         Has_Target       => True,
         Quick_Fix_Label  => Null_Unbounded_String,
         Quick_Fix_Detail => Null_Unbounded_String);
      Text : constant String := Editor.Problems.Format_Row (Config, Row, 80);
   begin
      Assert (Editor.Problems.Format_Header (Config, 0) = "Problems: 0",
              "header should format zero count deterministically");
      Assert (Editor.Problems.Format_Header (Config, 2) = "Problems: 2",
              "header should format multiple count deterministically");
      Assert (Text = "Error Ln 12, Col 5: missing ;",
              "row formatting should include severity and one-based location");
   end Test_Format_Header_And_Row;

   procedure Test_Format_Row_Shows_Quick_Fix_Action
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Row : Editor.Problems.Problem_Row;
      Narrow : String (1 .. 1);
   begin
      Editor.Diagnostics.Add
        (Diagnostics, Start_Index => 0, End_Index => 1,
         Start_Row => 0, Start_Column => 0,
         Severity => Editor.Diagnostics.Error,
         Message => "missing with clause",
         Quick_Fix_Label => "Add missing context clause",
         Quick_Fix_Detail => "Insert Ada.Text_IO dependency");

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Assert (Editor.Problems.Row_Count (Snapshot) = 1,
              "quick-fix diagnostic projects into Problems");
      Row := Editor.Problems.Row (Snapshot, 1);
      Assert (To_String (Row.Quick_Fix_Label) = "Add missing context clause"
              and then To_String (Row.Quick_Fix_Detail) =
                "Insert Ada.Text_IO dependency",
              "Problems row retains quick-fix metadata");

      declare
         Rendered : constant String :=
           Editor.Problems.Format_Row
             ((others => <>), Row, 120);
      begin
         Assert
           (Ada.Strings.Fixed.Index
              (Rendered, "action: Add missing context clause") > 0
             and then Ada.Strings.Fixed.Index
              (Rendered, "Insert Ada.Text_IO dependency") > 0,
            "Problems formatted row exposes quick-fix action label and detail");
      end;

      Narrow := Editor.Problems.Format_Row ((others => <>), Row, 1);
      Assert (Narrow'Length = 1,
              "quick-fix Problems row remains bounded at narrow widths");
   end Test_Format_Row_Shows_Quick_Fix_Action;

   procedure Test_Truncate_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Problems.Truncate_Text ("abc", 3) = "abc",
              "text that fits should not be truncated");
      Assert (Editor.Problems.Truncate_Text ("abcdef", 5) = "ab...",
              "long text should truncate deterministically with ellipsis");
      Assert (Editor.Problems.Truncate_Text ("abcdef", 2) = "ab",
              "very narrow truncation should not exceed requested columns");
   end Test_Truncate_Text;


   procedure Test_Hit_Test_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot    : Editor.Problems.Problems_Snapshot;
      Config      : constant Editor.Problems.Problems_View_Config := (others => <>);
      Panel       : constant Editor.Layout.Rect :=
        (X => 10, Y => 20, Width => 200, Height => 60);
      Hit         : Editor.Problems.Problems_Hit_Result;
   begin
      Editor.Diagnostics.Add
        (Diagnostics, 0, 1, 0, 0, Editor.Diagnostics.Error, "first");
      Editor.Diagnostics.Add
        (Diagnostics, 2, 3, 1, 0, Editor.Diagnostics.Warning, "second");
      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);

      Hit := Editor.Problems.Hit_Test (Panel, Config, Snapshot, 10, 0, 0);
      Assert (Hit.Zone = Editor.Problems.Outside_Problems,
              "point outside panel should be outside Problems");

      Hit := Editor.Problems.Hit_Test (Panel, Config, Snapshot, 10, 15, 25);
      Assert (Hit.Zone = Editor.Problems.Problems_Header_Zone,
              "point in first panel row should hit Problems header");

      Hit := Editor.Problems.Hit_Test (Panel, Config, Snapshot, 10, 15, 35);
      Assert (Hit.Zone = Editor.Problems.Problems_Row_Zone
              and then Hit.Row = 1
              and then Hit.Diagnostic_Index = 1,
              "first visible Problems row should map to first diagnostic");

      Hit := Editor.Problems.Hit_Test (Panel, Config, Snapshot, 10, 15, 45);
      Assert (Hit.Zone = Editor.Problems.Problems_Row_Zone
              and then Hit.Row = 2
              and then Hit.Diagnostic_Index = 2,
              "second visible Problems row should map to second diagnostic");

      Hit := Editor.Problems.Hit_Test (Panel, Config, Snapshot, 10, 15, 55);
      Assert (Hit.Zone = Editor.Problems.Problems_Background_Zone,
              "point below rendered rows should hit Problems background");
   end Test_Hit_Test_Rows;


   function Sample_Snapshot return Editor.Problems.Problems_Snapshot
   is
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
   begin
      Editor.Diagnostics.Add
        (Diagnostics, 0, 1, 0, 0, Editor.Diagnostics.Error, "first");
      Editor.Diagnostics.Add
        (Diagnostics, 2, 3, 1, 0, Editor.Diagnostics.Warning, "second");
      Editor.Diagnostics.Add
        (Diagnostics, 4, 5, 2, 0, Editor.Diagnostics.Information, "third");
      return Editor.Problems.Build_Snapshot (Diagnostics);
   end Sample_Snapshot;

   procedure Test_View_Defaults_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      View : Editor.Problems.Problems_View_State;
   begin
      Assert (Editor.Problems.Selected_Row_Index (View) = 0,
              "new Problems view should have no selected row");
      Assert (Editor.Problems.Top_Row (View) = 1,
              "new Problems view should start at top row 1");
      Editor.Problems.Set_Selected_Row_Index (View, 2);
      Editor.Problems.Set_Top_Row (View, 3);
      Editor.Problems.Clear_View (View);
      Assert (Editor.Problems.Selected_Row_Index (View) = 0,
              "Clear_View should clear selected row");
      Assert (Editor.Problems.Top_Row (View) = 1,
              "Clear_View should restore top row 1");
   end Test_View_Defaults_And_Clear;

   procedure Test_Row_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Problems.Problems_Snapshot := Sample_Snapshot;
      Found : Boolean := False;
      Index : Editor.Diagnostics.Diagnostic_Index := Editor.Diagnostics.No_Diagnostic;
      Row : Natural := 0;
   begin
      Index := Editor.Problems.Diagnostic_For_Row (Snapshot, 0, Found);
      Assert ((not Found) and then Index = Editor.Diagnostics.No_Diagnostic,
              "row 0/header should not map to a diagnostic");

      Index := Editor.Problems.Diagnostic_For_Row (Snapshot, 2, Found);
      Assert (Found and then Index = 2,
              "diagnostic row 2 should map to diagnostic index 2");

      Row := Editor.Problems.Row_For_Diagnostic (Snapshot, 3, Found);
      Assert (Found and then Row = 3,
              "diagnostic index 3 should map to rendered diagnostic row 3");

      Row := Editor.Problems.First_Diagnostic_Row (Snapshot, Found);
      Assert (Found and then Row = 1,
              "first diagnostic row should be row 1");

      Row := Editor.Problems.Last_Diagnostic_Row (Snapshot, Found);
      Assert (Found and then Row = 3,
              "last diagnostic row should be row 3");
   end Test_Row_Mapping;

   procedure Test_Selection_Movement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Problems.Problems_Snapshot := Sample_Snapshot;
      Empty : Editor.Problems.Problems_Snapshot;
      View : Editor.Problems.Problems_View_State;
   begin
      Editor.Problems.Ensure_Valid_Selection (View, Empty);
      Assert (Editor.Problems.Selected_Row_Index (View) = 0,
              "empty Problems snapshot should clear selected row");

      Editor.Problems.Ensure_Valid_Selection (View, Snapshot);
      Assert (Editor.Problems.Selected_Row_Index (View) = 1,
              "valid selection should choose first diagnostic row");

      Editor.Problems.Move_Selection
        (View, Snapshot, Editor.Problems.Next_Row);
      Assert (Editor.Problems.Selected_Row_Index (View) = 2,
              "moving down should select next diagnostic row");

      Editor.Problems.Move_Selection
        (View, Snapshot, Editor.Problems.Previous_Row);
      Assert (Editor.Problems.Selected_Row_Index (View) = 1,
              "moving up should select previous diagnostic row");

      Editor.Problems.Move_Selection
        (View, Snapshot, Editor.Problems.Previous_Row);
      Assert (Editor.Problems.Selected_Row_Index (View) = 3,
              "moving before first row should wrap to last diagnostic row");
   end Test_Selection_Movement;

   procedure Test_Selected_Row_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : constant Editor.Problems.Problems_Snapshot := Sample_Snapshot;
      View : Editor.Problems.Problems_View_State;
   begin
      Editor.Problems.Set_Selected_Row_Index (View, 3);
      Editor.Problems.Ensure_Selected_Row_Visible (View, Snapshot, 2);
      Assert (Editor.Problems.Top_Row (View) = 2,
              "selected row below visible window should scroll down");

      Editor.Problems.Set_Selected_Row_Index (View, 1);
      Editor.Problems.Ensure_Selected_Row_Visible (View, Snapshot, 2);
      Assert (Editor.Problems.Top_Row (View) = 1,
              "selected row above visible window should scroll up");
   end Test_Selected_Row_Visibility;

   procedure Test_Large_Diagnostic_Set_Sort_Filter_And_Scroll_Is_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostics : Editor.Diagnostics.Diagnostic_Vectors.Vector;
      Snapshot : Editor.Problems.Problems_Snapshot;
      Visible : Editor.Problems.Problems_Snapshot;
      View : Editor.Problems.Problems_View_State;
   begin
      for I in 1 .. 240 loop
         Editor.Diagnostics.Add
           (Diagnostics,
            Start_Index => Editor.Cursors.Cursor_Index (I * 2),
            End_Index   => Editor.Cursors.Cursor_Index (I * 2 + 1),
            Start_Row   => I,
            Start_Column => I mod 80,
            Severity    =>
              (if I mod 3 = 0 then Editor.Diagnostics.Error
               elsif I mod 3 = 1 then Editor.Diagnostics.Warning
               else Editor.Diagnostics.Information),
            Message     => "bulk diagnostic" & Natural'Image (I));
      end loop;

      Snapshot := Editor.Problems.Build_Snapshot (Diagnostics);
      Assert (Editor.Problems.Row_Count (Snapshot) = 240,
              "large diagnostic set projects every Problems row");

      Editor.Problems.Set_Severity_Filter
        (View, Editor.Problems.Problems_Show_Errors);
      Visible := Editor.Problems.Visible_Snapshot (Snapshot, View, 12);
      Assert (Editor.Problems.Row_Count (Visible) = 12,
              "large filtered Problems set windows visible rows");

      Editor.Problems.Scroll_By (View, Snapshot, 12, 60);
      Assert (Editor.Problems.Top_Row (View) > 1,
              "large Problems set scrolls without falling back to editor state");

      Snapshot := Editor.Problems.Sorted_Snapshot
        (Snapshot, Editor.Problems.Problems_Sort_By_Severity);
      Assert (Editor.Problems.Row_Count (Snapshot) = 240,
              "large Problems sort preserves row count");
   end Test_Large_Diagnostic_Set_Sort_Filter_And_Scroll_Is_Bounded;

   procedure Register_Tests
     (T : in out Problems_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Snapshot'Access,
         "empty Problems snapshot");
      Register_Routine
        (T, Test_Severity_Mapping'Access,
         "maps diagnostic severities to Problems severities");
      Register_Routine
        (T, Test_State_Row_Column_Projection'Access,
         "projects active-buffer diagnostic row and column");
      Register_Routine
        (T, Test_Filtered_Visible_Snapshot_Uses_Filtered_Empty_Message'Access,
         "Problems filtered visible snapshot uses filtered-empty message");
      Register_Routine
        (T, Test_Severity_Filter_Applies_Before_Viewport'Access,
         "Problems severity filter applies before viewport");
      Register_Routine
        (T, Test_Format_Row_Shows_Quick_Fix_Action'Access,
         "Problems rows show quick-fix action labels");
      Register_Routine
        (T, Test_Review_Snapshot_Groups_And_Sorts_Rows'Access,
         "Problems review snapshot groups and sorts rows");
      Register_Routine
        (T, Test_Severity_Filter_Commands_Update_View'Access,
         "Problems severity filter commands update view");
      Register_Routine
        (T, Test_Problems_Review_Mode_Commands_Update_View'Access,
         "Problems review mode commands update view");
      Register_Routine
        (T, Test_Filtered_Problem_Movement_Uses_Filtered_Rows'Access,
         "Problems movement uses filtered rows");
      Register_Routine
        (T, Test_Problems_Open_Selected_Uses_Target_Parity'Access,
         "Problems open selected uses target parity");
      Register_Routine
        (T, Test_Format_Header_And_Row'Access,
         "formats Problems header and rows deterministically");
      Register_Routine
        (T, Test_Truncate_Text'Access,
         "truncates Problems text deterministically");
      Register_Routine
        (T, Test_Hit_Test_Rows'Access,
         "hit-tests Problems rows and background");
      Register_Routine
        (T, Test_View_Defaults_And_Clear'Access,
         "Problems view state defaults and clear");
      Register_Routine
        (T, Test_Row_Mapping'Access,
         "Problems row-to-diagnostic mapping");
      Register_Routine
        (T, Test_Selection_Movement'Access,
         "Problems keyboard selection movement");
      Register_Routine
        (T, Test_Selected_Row_Visibility'Access,
         "Problems selected row visibility");
      Register_Routine
        (T, Test_Large_Diagnostic_Set_Sort_Filter_And_Scroll_Is_Bounded'Access,
         "large Problems diagnostic sets remain bounded");
   end Register_Tests;

end Editor.Problems.Tests;
