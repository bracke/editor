with AUnit;
with AUnit.Reporter.Text;
with AUnit.Options;
with AUnit.Run;
with AUnit.Test_Filters;
with Ada.Command_Line;
with Ada_Language_Service_Suite;

--  AUnit's plain Test_Runner reports success however many assertions
--  failed, so a build server ticks a job green over a failing suite.
--  The outcome is carried in the exit status here instead.
procedure Ada_Language_Service_Tests is
   use type AUnit.Status;

   function Runner is new AUnit.Run.Test_Runner_With_Status (Ada_Language_Service_Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
   Filter   : aliased AUnit.Test_Filters.Name_Filter;
begin
   if Ada.Command_Line.Argument_Count > 0 then
      AUnit.Test_Filters.Set_Name (Filter, Ada.Command_Line.Argument (1));
      Options.Filter := Filter'Unchecked_Access;
   end if;

   Status := Runner (Reporter, Options);

   if Status /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Ada_Language_Service_Tests;
