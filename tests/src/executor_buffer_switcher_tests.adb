with Ada.Command_Line;
with AUnit;
with AUnit.Options;
with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit.Test_Suites; use AUnit.Test_Suites;
with Editor.Build_Command;
with Editor.Executor.Buffer_Switcher_Tests;
with Editor.Fonts.Init;

--  AUnit's plain Test_Runner reports success however many assertions
--  failed, so a build server ticks a job green over a failing suite.
--  The outcome is carried in the exit status here instead.
procedure Executor_Buffer_Switcher_Tests is
   use type AUnit.Status;

   function Suite return Access_Test_Suite is
      Ret : constant Access_Test_Suite := new Test_Suite;
   begin
      Ret.Add_Test (new Editor.Executor.Buffer_Switcher_Tests.Buffer_Switcher_Test_Case);
      return Ret;
   end Suite;

   function Runner is new AUnit.Run.Test_Runner_With_Status (Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
begin
   Editor.Fonts.Init.Initialize;
   Status := Runner (Reporter, Options);
   Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
exception
   when others =>
      Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
      raise;

   if Status /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Executor_Buffer_Switcher_Tests;
