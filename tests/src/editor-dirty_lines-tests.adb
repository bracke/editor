with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;

package body Editor.Dirty_Lines.Tests is

   overriding function Name
     (T : Dirty_Lines_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Dirty_Lines");
   end Name;

   procedure Test_Clear_And_Empty_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Assert (not Has_Baseline (State),
              "new dirty-line state should not have an explicit baseline");
      Assert (Dirty_Line_Count (State) = 0,
              "new dirty-line state should have no dirty rows");

      Set_Baseline_Text (State, "");
      Assert (Has_Baseline (State),
              "Set_Baseline_Text should establish a baseline");
      Assert (Baseline_Line_Count (State) = 1,
              "empty text should have one deterministic logical line");

      Clear (State);
      Assert (not Has_Baseline (State),
              "Clear should remove the baseline");
      Assert (Baseline_Line_Count (State) = 0,
              "Clear should remove baseline lines");
      Assert (Dirty_Line_Count (State) = 0,
              "Clear should remove dirty rows");
   end Test_Clear_And_Empty_Baseline;

   procedure Test_Identical_Text_Is_Clean
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "alpha" & ASCII.LF & "beta");
      Recompute (State, "alpha" & ASCII.LF & "beta");

      Assert (Dirty_Line_Count (State) = 0,
              "identical text should produce zero dirty rows");
      Assert (Kind_For_Row (State, 0) = Clean_Line,
              "row 0 should be clean");
      Assert (Kind_For_Row (State, 1) = Clean_Line,
              "row 1 should be clean");
   end Test_Identical_Text_Is_Clean;

   procedure Test_Modified_Existing_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "A" & ASCII.LF & "B" & ASCII.LF & "C");
      Recompute (State, "A" & ASCII.LF & "X" & ASCII.LF & "C");

      Assert (Dirty_Line_Count (State) = 1,
              "one changed existing row should count as one dirty row");
      Assert (Kind_For_Row (State, 1) = Modified_Line,
              "changed existing row should be Modified_Line");
      Assert (Is_Dirty_Row (State, 1),
              "modified row should be dirty");
   end Test_Modified_Existing_Row;

   procedure Test_Added_Row_After_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "A" & ASCII.LF & "B");
      Recompute (State, "A" & ASCII.LF & "B" & ASCII.LF & "C");

      Assert (Dirty_Line_Count (State) = 1,
              "one appended row should count as one dirty row");
      Assert (Kind_For_Row (State, 2) = Added_Line,
              "row beyond baseline should be Added_Line");
   end Test_Added_Row_After_Baseline;

   procedure Test_Multiple_Changed_Rows_And_Out_Of_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "A" & ASCII.LF & "B" & ASCII.LF & "C");
      Recompute (State, "X" & ASCII.LF & "B" & ASCII.LF & "Y" & ASCII.LF & "Z");

      Assert (Dirty_Line_Count (State) = 3,
              "two modified rows and one added row should count as three dirty rows");
      Assert (Kind_For_Row (State, 0) = Modified_Line,
              "row 0 should be modified");
      Assert (Kind_For_Row (State, 1) = Clean_Line,
              "row 1 should remain clean");
      Assert (Kind_For_Row (State, 2) = Modified_Line,
              "row 2 should be modified");
      Assert (Kind_For_Row (State, 3) = Added_Line,
              "row 3 should be added");
      Assert (Kind_For_Row (State, 99) = Clean_Line,
              "out-of-range rows should be clean");
   end Test_Multiple_Changed_Rows_And_Out_Of_Range;

   procedure Test_Clear_Dirty_State_To_Current
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "old");
      Recompute (State, "new" & ASCII.LF & "line");
      Assert (Dirty_Line_Count (State) > 0,
              "setup should create dirty rows");

      Clear_Dirty_State_To_Current (State, "new" & ASCII.LF & "line");
      Assert (Has_Baseline (State),
              "reset-to-current should keep a baseline");
      Assert (Dirty_Line_Count (State) = 0,
              "reset-to-current should clear dirty rows");
      Assert (Baseline_Line_Count (State) = 2,
              "reset baseline should store current line count");
   end Test_Clear_Dirty_State_To_Current;

   procedure Test_Trailing_Newline_Line_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "a" & ASCII.LF);
      Assert (Baseline_Line_Count (State) = 2,
              "trailing LF should create a final empty logical line");
      Recompute (State, "a" & ASCII.LF & "b");
      Assert (Kind_For_Row (State, 1) = Modified_Line,
              "final empty baseline row should compare deterministically");
   end Test_Trailing_Newline_Line_Count;

   procedure Test_Deleted_Baseline_Row_Has_No_Visible_Dirty_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Set_Baseline_Text (State, "A" & ASCII.LF & "B");
      Recompute (State, "A");

      Assert (Dirty_Line_Count (State) = 0,
              "deleted baseline-only rows should not create visible dirty rows");
      Assert (Kind_For_Row (State, 1) = Clean_Line,
              "row removed from current text should report as clean/out-of-range");
   end Test_Deleted_Baseline_Row_Has_No_Visible_Dirty_Row;

   procedure Test_Recompute_Without_Baseline_Uses_Empty_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Dirty_Line_State;
   begin
      Recompute (State, "created");

      Assert (Has_Baseline (State),
              "recompute without a prior baseline should establish an empty baseline");
      Assert (Dirty_Line_Count (State) = 1,
              "text compared with implicit empty baseline should mark row 0 dirty");
      Assert (Kind_For_Row (State, 0) = Modified_Line,
              "first row replaces the implicit empty baseline row");
   end Test_Recompute_Without_Baseline_Uses_Empty_Baseline;

   overriding procedure Register_Tests
     (T : in out Dirty_Lines_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_And_Empty_Baseline'Access,
         "clear and empty baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Identical_Text_Is_Clean'Access,
         "identical text is clean");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Modified_Existing_Row'Access,
         "modified existing row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Added_Row_After_Baseline'Access,
         "added row after baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Multiple_Changed_Rows_And_Out_Of_Range'Access,
         "multiple rows and out of range");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Dirty_State_To_Current'Access,
         "clear dirty state to current");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Trailing_Newline_Line_Count'Access,
         "trailing newline policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Deleted_Baseline_Row_Has_No_Visible_Dirty_Row'Access,
         "deleted baseline rows have no visible marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Recompute_Without_Baseline_Uses_Empty_Baseline'Access,
         "recompute without baseline uses empty baseline");
   end Register_Tests;

end Editor.Dirty_Lines.Tests;
