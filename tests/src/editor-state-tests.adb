with AUnit.Assertions; use AUnit.Assertions;
with Editor.Executor;
with Editor.Test_Helper;
with Text_Buffer;

package body Editor.State.Tests is

   procedure Test_Caret_Validity
   (T : in out AUnit.Test_Cases.Test_Case'Class) is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'a'));

      Assert (S.Carets (0) <= Text_Buffer.Length (S.Buffer) + 1,
              "Caret must remain valid after execution");
   end Test_Caret_Validity;

   overriding function Name (T : State_Test_Case)
      return AUnit.Message_String is
   begin
      return AUnit.Format ("Editor.Selection (Option A)");
   end Name;

   overriding procedure Register_Tests
     (T : in out State_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Validity'Access, "Caret Validity");
   end Register_Tests;

end Editor.State.Tests;