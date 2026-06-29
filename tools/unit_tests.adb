with Ada.Directories;
with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Unit_Tests is
   Tool : constant String := "unit_tests";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
   Root   : constant String := Ada.Directories.Current_Directory;
begin
   Require_File (Tool, "tests/tests.gpr");
   if not Command_Exists ("alr") and then not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_UNIT_TESTS") then
         Fail (Tool, "neither alr nor gprbuild found");
      else
         Info (Tool, "neither alr nor gprbuild found; unit tests skipped");
         return;
      end if;
   end if;

   Ada.Directories.Set_Directory ("tests");
   if Command_Exists ("alr") then
      if Ada.Environment_Variables.Exists ("HOME") then
         declare
            Home : constant String := Ada.Environment_Variables.Value ("HOME");
         begin
            if not Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_CONFIG_HOME", Home & "/.config");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_DATA_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_DATA_HOME", Home & "/.local/share");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_CACHE_HOME") then
               Ada.Environment_Variables.Set
                 ("XDG_CACHE_HOME", Home & "/.cache");
            end if;
         end;
      end if;
      Status := Run1 ("alr", "build");
   else
      Status := Run2 ("gprbuild", "-P", "tests.gpr");
   end if;
   Ada.Directories.Set_Directory (Root);

   if Status /= 0 then
      Fail (Tool, "unit test build failed");
   end if;

   declare
      No_Args : GNAT.OS_Lib.Argument_List (1 .. 0);
      Result  : constant Captured_Command_Output :=
        Run_Capture_Bounded
          ("tests/bin/tests", No_Args, "/tmp/editor_unit_tests_aunit.out",
           Max_Bytes => 2_000_000);
   begin
      if not AUnit_Output_Passed (Result) then
         Fail
           (Tool,
            "unit tests failed; see /tmp/editor_unit_tests_aunit.out");
      end if;
   end;

   Info (Tool, "unit tests passed");
exception
   when Program_Error =>
      if Ada.Directories.Current_Directory /= Root then
         Ada.Directories.Set_Directory (Root);
      end if;
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Unit_Tests;
