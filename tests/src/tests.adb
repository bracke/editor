with AUnit;
with AUnit.Reporter.Text;
with AUnit.Options;
with AUnit.Run;
with AUnit.Test_Filters;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with GNAT.OS_Lib;
with Hostkit.Host;
with All_Suites;
with Editor.Build_Command;
with Editor.External_Producers.Execution_Policy;
with Editor.Fonts.Init;
with Editor.Recent_Projects;

--  Test_Runner exits zero whatever happens, so this suite could not fail: a failing
--  test reported success, "alr test" was green over it, and nothing would ever have
--  said otherwise. A check that cannot fail is not a check.
procedure Tests is
   use type AUnit.Status;

   function Runner is new AUnit.Run.Test_Runner_With_Status (All_Suites.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Options  : AUnit.Options.AUnit_Options := AUnit.Options.Default_Options;
   Filter   : aliased AUnit.Test_Filters.Name_Filter;
begin
   --  TEMP (Windows-hang diagnosis): print the host facts the real-process
   --  cancel guard depends on, then exit before running any suite so it cannot
   --  hang. Flush so the line survives regardless.
   if Ada.Environment_Variables.Exists ("EDITOR_DIAG_HOST") then
      Ada.Text_IO.Put_Line
        ("DIAG"
         & " Host.Current=" & Hostkit.Host.Current'Image
         & " Is_POSIX="
         & Boolean'Image
             (Editor.External_Producers.Execution_Policy.Native_Process_Control_Is_POSIX)
         & " backend=["
         & Editor.External_Producers.Execution_Policy.Native_Process_Control_Backend_Label
         & "]"
         & " sleep_exists="
         & Boolean'Image (Ada.Directories.Exists ("/bin/sleep"))
         & " sep=[" & GNAT.OS_Lib.Directory_Separator & "]");
      Ada.Text_IO.Flush;
      return;
   end if;

   Editor.Fonts.Init.Initialize;

   if Ada.Command_Line.Argument_Count > 0 then
      AUnit.Test_Filters.Set_Name (Filter, Ada.Command_Line.Argument (1));
      Options.Filter := Filter'Unchecked_Access;
   end if;

   if Runner (Reporter, Options) /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

   Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
exception
   when others =>
      Editor.Build_Command.Stop_Public_Build_Workers_For_Application_Exit;
      raise;
end Tests;
