with AUnit.Assertions;  use AUnit.Assertions;
with Editor.State;
with Editor.Executor;
with Editor.Test_Helper;
with Text_Buffer;

package body Editor.Selection.Tests is

   overriding function Name (T : Selection_Test_Case)
      return AUnit.Message_String is
   begin
      return AUnit.Format ("Editor.Selection (Option A)");
   end Name;

   -------------------------------------------------------------------------
   procedure Test_Start_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Assert (S.Selection.Active, "Selection active");
      Assert (S.Selection.Start_Pos = 0, "Anchor captured");
      Assert (S.Selection.End_Pos = 1, "End follows caret");
   end Test_Start_Selection;

   -------------------------------------------------------------------------
   procedure Test_Extend_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Assert (S.Selection.Active, "Selection active");
      Assert (S.Selection.Start_Pos = 0, "Anchor stable");
      Assert (S.Selection.End_Pos = S.Carets (0), "End equals caret");
   end Test_Extend_Selection;

   -------------------------------------------------------------------------
   procedure Test_Reverse_Selection
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Insert (0, 'a'));

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Move_Right (Shift => False));
      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Move_Right (Shift => False));

      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
      (S, Editor.Test_Helper.Move_Left (Shift => True));

      Assert (S.Selection.Active, "Selection active");
      Assert (S.Selection.Start_Pos = 2, "Anchor unchanged");
      Assert (S.Selection.End_Pos < S.Selection.Start_Pos,
            "Selection may cross anchor");
   end Test_Reverse_Selection;

   -------------------------------------------------------------------------
   procedure Test_Collapse_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => False));

      Assert (not S.Selection.Active, "Selection collapsed");
      Assert (S.Selection.Start_Pos = S.Selection.End_Pos,
              "Collapsed bounds equal");
   end Test_Collapse_Selection;

   -------------------------------------------------------------------------
   procedure Test_Replace_Selection_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Assert (Text_Buffer.Length (S.Buffer) = 2,
              "Replace shrinks buffer");
      Assert (not S.Selection.Active,
              "Selection collapsed after replace");
   end Test_Replace_Selection_Insert;

   -------------------------------------------------------------------------
   procedure Test_Delete_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Delete (0));

      Assert (Text_Buffer.Length (S.Buffer) = 1,
              "Delete removes span");
      Assert (not S.Selection.Active,
              "Selection collapsed");
   end Test_Delete_Selection;

   -------------------------------------------------------------------------
   procedure Test_Undo_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);

      Assert (S.Selection.Active, "Undo restores snapshot");
      Assert (S.Selection.Start_Pos = 0, "Anchor restored");
      Assert (S.Selection.End_Pos = 1, "End restored");
   end Test_Undo_Selection;

   -------------------------------------------------------------------------
   overriding procedure Register_Tests
     (T : in out Selection_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Start_Selection'Access, "Start Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Extend_Selection'Access, "Extend Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reverse_Selection'Access, "Reverse Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Collapse_Selection'Access, "Collapse Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Selection_Insert'Access, "Replace Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Selection'Access, "Delete Selection");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Selection'Access, "Undo Selection");
   end Register_Tests;

end Editor.Selection.Tests;