with Ada.Directories;
with Ada.Environment_Variables;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Runtime_Missing_Asset_Check is
   Tool        : constant String := "runtime_missing_asset_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status      : Integer;
   Tmp         : constant String := "build/runtime-missing-shader-empty";
   Output_Path : constant String := "build/runtime-missing-shader-output.txt";
begin
   if not Ada.Directories.Exists ("bin/editor") then
      if Command_Exists ("alr") then
         Status := Run0 ("tools/bin/runtime_link_check");
         if Status /= 0 then
            Fail (Tool, "could not build bin/editor before missing-asset check");
         end if;
      elsif Strict ("EDITOR_REQUIRE_RUNTIME_MISSING_ASSET") then
         Fail (Tool, "bin/editor missing and alr is unavailable");
      else
         Info
           (Tool,
            "alr not found and bin/editor is not "
            & "executable; missing-asset runtime check skipped");
         return;
      end if;
   end if;

   if not Ada.Directories.Exists ("build") then
      Ada.Directories.Create_Directory ("build");
   end if;
   if not Ada.Directories.Exists (Tmp) then
      Ada.Directories.Create_Directory (Tmp);
   end if;

   Ada.Environment_Variables.Set ("EDITOR_SHADER_DIR", Tmp);
   Ada.Environment_Variables.Set ("EDITOR_SHADER_DIR_ONLY", "1");

   declare
      Args   : GNAT.OS_Lib.Argument_List (1 .. 1) := (1 => new String'("--runtime-check-shaders"));
      Result : constant Captured_Command_Output :=
        Run_Capture_Bounded
          (Program     => "./bin/editor",
           Args        => Args,
           Output_Path => Output_Path);
   begin
      if Result.Exit_Code = 0 then
         Fail (Tool, "missing-shader negative check unexpectedly succeeded");
      end if;

      if not Output_Contains (Result, "runtime asset error") then
         Fail (Tool, "missing-shader negative check failed without expected runtime asset error output");
      end if;

      if not Output_Contains (Result, "EDITOR_SHADER_DIR_ONLY") then
         Fail (Tool, "missing-shader negative check did not prove fallback-disabled shader lookup mode");
      end if;

      if Result.Truncated then
         Info (Tool, "captured missing-asset output was truncated after the bounded release-tool limit");
      end if;
   end;

   Info (Tool, "missing-shader negative check observed expected runtime asset error");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Runtime_Missing_Asset_Check;
