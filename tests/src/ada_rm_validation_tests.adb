with Ada.Command_Line;
with AUnit;
with AUnit.Run;
with AUnit.Reporter.Text;
with Ada_RM_Validation_Suite;

--  AUnit's plain Test_Runner reports success however many assertions
--  failed, so a build server ticks a job green over a failing suite.
--  The outcome is carried in the exit status here instead.
procedure Ada_RM_Validation_Tests is
   use type AUnit.Status;

   function Runner is new AUnit.Run.Test_Runner_With_Status (Ada_RM_Validation_Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
begin
   Status := Runner (Reporter);

   if Status /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Ada_RM_Validation_Tests;
