with AUnit.Reporter.Text;
with AUnit.Options;
with AUnit.Run;
with AUnit.Test_Filters;
with Ada.Command_Line;
with Editor.Build_Command;
with Editor.Fonts.Init;
with Editor_Core_Suite;

procedure Editor_Core_Tests is
   procedure Runner is new AUnit.Run.Test_Runner (Editor_Core_Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
   Filter   : aliased AUnit.Test_Filters.Name_Filter;
begin
   Editor.Fonts.Init.Initialize;

   if Ada.Command_Line.Argument_Count > 0 then
      AUnit.Test_Filters.Set_Name (Filter, Ada.Command_Line.Argument (1));
      Options.Filter := Filter'Unchecked_Access;
   end if;

   Runner (Reporter, Options);
   Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
exception
   when others =>
      Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
      raise;
end Editor_Core_Tests;
