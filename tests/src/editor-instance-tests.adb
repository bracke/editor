with AUnit.Assertions; use AUnit.Assertions;

with Editor.Commands; use Editor.Commands;
with Text_Buffer;
with Editor.Test_Helper;

package body Editor.Instance.Tests is

   overriding function Name (T : Instance_Test_Case) return AUnit.Message_String is
   begin
      return AUnit.Format ("Editor.Instance");
   end Name;

   procedure Test_Insert
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      E   : Editor.Instance.Editor_Instance;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Instance.Init (E);

      Cmd := Editor.Test_Helper.Insert (0, 'X');
      Editor.Instance.Execute (E, Cmd);

      Assert (Text_Buffer.Length (E.State.Buffer) = 1, "Insert failed");
      Assert (Text_Buffer.Element (E.State.Buffer, 1) = 'X', "Wrong state");
   end Test_Insert;

   procedure Test_Undo_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      E   : Editor.Instance.Editor_Instance;
      Cmd : Editor.Commands.Command;
   begin
      Editor.Instance.Init (E);

      Cmd := Editor.Test_Helper.Insert (0, 'A');
      Editor.Instance.Execute (E, Cmd);
      Editor.Instance.Undo (E);
      Editor.Instance.Redo (E);

      Assert (Text_Buffer.Length (E.State.Buffer) = 1, "Undo/Redo failed");
   end Test_Undo_Redo;

   procedure Test_Replay_Determinism
      (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      E1, E2 : Editor.Instance.Editor_Instance;
      Cmd    : Editor.Commands.Command;
   begin
      Editor.Instance.Init (E1);
      Editor.Instance.Init (E2);

      Cmd := Editor.Test_Helper.Insert (0, 'A');

      Editor.Instance.Execute (E1, Cmd);
      Editor.Instance.Execute (E2, Cmd);

      Assert
      (Text_Buffer.Length (E1.State.Buffer) =
         Text_Buffer.Length (E2.State.Buffer),
         "Replay mismatch");

      Assert
      (Text_Buffer.Element (E1.State.Buffer, 1) =
         Text_Buffer.Element (E2.State.Buffer, 1),
         "Replay content mismatch");
   end Test_Replay_Determinism;

   overriding procedure Register_Tests (T : in out Instance_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Insert'Access, "Insert via Instance");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Undo_Redo'Access, "Undo/Redo");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replay_Determinism'Access, "Replay Determinism");
   end Register_Tests;

end Editor.Instance.Tests;