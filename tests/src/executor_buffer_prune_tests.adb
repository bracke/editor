with AUnit.Options;
with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit.Test_Suites; use AUnit.Test_Suites;
with Editor.Build_Command;
with Editor.Executor.Buffer_Prune_Tests;
with Editor.Fonts.Init;

procedure Executor_Buffer_Prune_Tests is
   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Executor.Buffer_Prune_Tests.Buffer_Prune_Test_Case);
      return Ret;
   end Suite;

   procedure Runner is new AUnit.Run.Test_Runner (Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
begin
   Editor.Fonts.Init.Initialize;
   Runner (Reporter, Options);
   Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
exception
   when others =>
      Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
      raise;
end Executor_Buffer_Prune_Tests;
