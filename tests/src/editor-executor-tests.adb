with AUnit.Assertions; use AUnit.Assertions;

with Editor.State;
with Editor.Commands;
with Text_Buffer;
with Editor.Test_Helper;

package body Editor.Executor.Tests is

   overriding function Name (T : Executor_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Editor.Executor");
   end Name;

   procedure Test_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Text_Buffer.Clear (S.Buffer);

      Cmd := Editor.Test_Helper.Insert (0, 'X');

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Text_Buffer.Length (S.Buffer) = 1, "Insert failed");
      Assert (Text_Buffer.Element (S.Buffer, 1) = 'X', "Wrong char");
   end Test_Insert;

   procedure Test_Delete
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Text_Buffer.Clear (S.Buffer);

      Text_Buffer.Insert (S.Buffer, 1, 'A');
      Text_Buffer.Insert (S.Buffer, 2, 'B');

      Cmd := Editor.Test_Helper.Delete (0);

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Text_Buffer.Length (S.Buffer) = 1, "Delete failed");
   end Test_Delete;

   overriding procedure Register_Tests (T : in out Executor_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Insert'Access, "Insert");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete'Access, "Delete");
   end Register_Tests;

end Editor.Executor.Tests;