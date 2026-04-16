with AUnit.Assertions; use AUnit.Assertions;
with Editor.State;
with Editor.Executor;
with Editor.Test_Helper;

package body Editor.History.Tests is

   procedure Test_Undo_Restores_Snapshot
   (T : in out AUnit.Test_Cases.Test_Case'Class) is

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Move_Right (Shift => True));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'X'));

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Undo);

      Assert (S.Selection.Start_Pos = 0,
              "Snapshot restored correctly");
   end Test_Undo_Restores_Snapshot;

   overriding function Name (T : History_Test_Case)
      return AUnit.Message_String is
   begin
      return AUnit.Format ("Editor.Selection (Option A)");
   end Name;
   overriding procedure Register_Tests
     (T : in out History_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Restores_Snapshot'Access,
         "Undo restores snapshot");
   end Register_Tests;

end Editor.History.Tests;