with AUnit.Reporter.Text;
with AUnit.Options;
with AUnit.Run;
with AUnit.Test_Filters;
with Ada.Command_Line;
with Ada_Language_Service_Suite;

procedure Ada_Language_Service_Tests is
   procedure Runner is new AUnit.Run.Test_Runner (Ada_Language_Service_Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
   Filter   : aliased AUnit.Test_Filters.Name_Filter;
begin
   if Ada.Command_Line.Argument_Count > 0 then
      AUnit.Test_Filters.Set_Name (Filter, Ada.Command_Line.Argument (1));
      Options.Filter := Filter'Unchecked_Access;
   end if;

   Runner (Reporter, Options);
end Ada_Language_Service_Tests;
