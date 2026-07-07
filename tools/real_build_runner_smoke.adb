with Ada.Directories;
with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;

procedure Real_Build_Runner_Smoke is
   Tool : constant String := "real_build_runner_smoke";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Normalize_Alire_Environment is
   begin
      if Ada.Environment_Variables.Exists ("HOME") then
         declare
            Home : constant String := Ada.Environment_Variables.Value ("HOME");
         begin
            if not Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
               Ada.Environment_Variables.Set ("XDG_CONFIG_HOME", Home & "/.config");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_DATA_HOME") then
               Ada.Environment_Variables.Set ("XDG_DATA_HOME", Home & "/.local/share");
            end if;
            if not Ada.Environment_Variables.Exists ("XDG_CACHE_HOME") then
               Ada.Environment_Variables.Set ("XDG_CACHE_HOME", Home & "/.cache");
            end if;
         end;
      end if;
   end Normalize_Alire_Environment;

   Status : Integer;
   Root   : constant String := Ada.Directories.Current_Directory;
begin
   Require_File (Tool, "tests/e2e_real_build_runner_smoke.gpr");
   if not Command_Exists ("alr") then
      if Strict ("EDITOR_REQUIRE_REAL_BUILD_SMOKE") then
         Fail (Tool, "alr not found; real build-runner smoke requires Alire-selected GNAT 15");
      else
         Info (Tool, "alr not found; real build-runner smoke skipped");
         return;
      end if;
   end if;
   Normalize_Alire_Environment;
   Ada.Directories.Set_Directory ("tests");
   Status := Run4
     ("alr", "exec", "--", "gprbuild", "-Pe2e_real_build_runner_smoke.gpr");
   Ada.Directories.Set_Directory (Root);
   if Status /= 0 then
      Fail (Tool, "real build-runner smoke build failed");
   end if;
   Status := Run0 ("tests/bin/editor_real_build_runner_smoke");
   if Status /= 0 then
      Fail (Tool, "real build-runner smoke failed");
   end if;
   Info (Tool, "real build-runner smoke passed");
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
end Real_Build_Runner_Smoke;
