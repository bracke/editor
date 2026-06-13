with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Diagnostics;
with Editor.Problems;
with Editor.State;
with Editor.Layout;

package body Editor.Problems.Tests is

   use type Editor.Problems.Problem_Row_Severity;
   use type Editor.Problems.Problems_Zone;
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
   end Test_State_Row_Column_Projection;

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
         Source_File      => Null_Unbounded_String);
      Text : constant String := Editor.Problems.Format_Row (Config, Row, 80);
   begin
      Assert (Editor.Problems.Format_Header (Config, 0) = "Problems: 0",
              "header should format zero count deterministically");
      Assert (Editor.Problems.Format_Header (Config, 2) = "Problems: 2",
              "header should format multiple count deterministically");
      Assert (Text = "Error Ln 12, Col 5: missing ;",
              "row formatting should include severity and one-based location");
   end Test_Format_Header_And_Row;

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

   procedure Register_Tests
     (T : in out Problems_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Snapshot'Access,
         "Phase 60 empty Problems snapshot");
      Register_Routine
        (T, Test_Severity_Mapping'Access,
         "Phase 60 maps diagnostic severities to Problems severities");
      Register_Routine
        (T, Test_State_Row_Column_Projection'Access,
         "Phase 60 projects active-buffer diagnostic row and column");
      Register_Routine
        (T, Test_Format_Header_And_Row'Access,
         "Phase 60 formats Problems header and rows deterministically");
      Register_Routine
        (T, Test_Truncate_Text'Access,
         "Phase 60 truncates Problems text deterministically");
      Register_Routine
        (T, Test_Hit_Test_Rows'Access,
         "Phase 61 hit-tests Problems rows and background");
      Register_Routine
        (T, Test_View_Defaults_And_Clear'Access,
         "Phase 77 Problems view state defaults and clear");
      Register_Routine
        (T, Test_Row_Mapping'Access,
         "Phase 77 Problems row-to-diagnostic mapping");
      Register_Routine
        (T, Test_Selection_Movement'Access,
         "Phase 77 Problems keyboard selection movement");
      Register_Routine
        (T, Test_Selected_Row_Visibility'Access,
         "Phase 77 Problems selected row visibility");
   end Register_Tests;

end Editor.Problems.Tests;
