with Editor.State.Tests;
with Editor.Executor.Tests;
with Editor.Instance.Tests;
with Editor.History.Tests;
with Editor.Selection.Tests;
with Editor.Smoke_Tests;

package body Misc_Suite is

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Instance.Tests.Instance_Test_Case);
      Ret.Add_Test (new Editor.State.Tests.State_Test_Case);
      Ret.Add_Test (new Editor.Executor.Tests.Executor_Test_Case);
      Ret.Add_Test (new Editor.History.Tests.History_Test_Case);
      Ret.Add_Test (new Editor.Selection.Tests.Selection_Test_Case);
      Ret.Add_Test (new Editor.Smoke_Tests.Smoke_Test_Case);
      return Ret;
   end Suite;

end Misc_Suite;
