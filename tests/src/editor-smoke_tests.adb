with AUnit.Assertions; use AUnit.Assertions;

with Editor.State;
with Editor.Executor;
with Editor.Test_Helper;
with Editor.Instance;
with Text_Buffer;

package body Editor.Smoke_Tests is

   overriding function Name
     (T : Smoke_Test_Case)
      return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Smoke");
   end Name;

   -------------------------------------------------------------------------
   --  Insert a short word
   -------------------------------------------------------------------------
   procedure Test_Insert_Word
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      Assert (Text_Buffer.Length (S.Buffer) = 3,
              "Smoke insert must produce length 3");
   end Test_Insert_Word;

   -------------------------------------------------------------------------
   --  Select and replace
   -------------------------------------------------------------------------
   procedure Test_Select_And_Replace
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (2, 'c'));

      --  Select back over "bc"
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Left (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Assert (Text_Buffer.Length (S.Buffer) = 2,
              "Smoke replace must shrink buffer to 2");

      Assert (S.Carets (0).Anchor = S.Carets (0).Pos,
              "Smoke replace must collapse selection");
   end Test_Select_And_Replace;

   -------------------------------------------------------------------------
   --  Undo / Redo round-trip
   -------------------------------------------------------------------------
   procedure Test_Undo_Redo_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));

      Assert (Text_Buffer.Length (S.Buffer) = 2,
              "Precondition for undo/redo failed");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);

      Assert (Text_Buffer.Length (S.Buffer) = 1,
              "Undo must remove the last typing step");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);

      Assert (Text_Buffer.Length (S.Buffer) = 0,
              "Second undo must remove the first typing step");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);

      Assert (Text_Buffer.Length (S.Buffer) = 1,
              "Redo must restore the first typing step");

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);

      Assert (Text_Buffer.Length (S.Buffer) = 2,
              "Second redo must restore the last typing step");
   end Test_Undo_Redo_Roundtrip;

   -------------------------------------------------------------------------
   --  Instance replay determinism
   -------------------------------------------------------------------------
   procedure Test_Instance_Replay
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      I : Editor.Instance.Editor_Instance;
   begin
      Editor.Instance.Init (I);

      Editor.Instance.Execute (I, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Instance.Execute (I, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Instance.Execute (I, Editor.Test_Helper.Insert (2, 'c'));

      Assert (Text_Buffer.Length (I.State.Buffer) = 3,
              "Smoke instance commands must produce the same buffer");
   end Test_Instance_Replay;

   overriding procedure Register_Tests
     (T : in out Smoke_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Insert_Word'Access, "Insert Word");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Select_And_Replace'Access, "Select And Replace");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Redo_Roundtrip'Access, "Undo Redo Roundtrip");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Instance_Replay'Access, "Instance Replay");
   end Register_Tests;

end Editor.Smoke_Tests;