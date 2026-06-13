with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Runtime_Smoke is
   Tool : constant String := "runtime_smoke";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
   Frames : constant String := Env ("EDITOR_RUNTIME_SMOKE_FRAMES", "8");
   Resize_Count : constant String := Env ("EDITOR_RUNTIME_SMOKE_RESIZE_COUNT", "3");
   Atlas_Min : constant String := Env ("EDITOR_RUNTIME_SMOKE_ATLAS_MIN_NONZERO_BYTES", "32");
   Timeout_Seconds : constant String := Env ("EDITOR_RUNTIME_SMOKE_TIMEOUT_SECONDS", "30");
   Has_Display : constant Boolean := Env ("DISPLAY") /= "" or else Env ("WAYLAND_DISPLAY") /= "";
begin
   if not Has_Display then
      if Strict ("EDITOR_REQUIRE_RUNTIME_SMOKE") then
         Fail (Tool, "DISPLAY or WAYLAND_DISPLAY is required for runtime smoke");
      else
         Info (Tool, "no DISPLAY or WAYLAND_DISPLAY; runtime smoke skipped");
         return;
      end if;
   end if;
   if not Ada.Directories.Exists ("bin/editor_app") then
      if Command_Exists ("alr") or else Command_Exists ("gprbuild") then
         Status := Run0 ("tools/bin/runtime_link_check");
         if Status /= 0 then
            Fail (Tool, "could not build bin/editor_app before smoke");
         end if;
      elsif Strict ("EDITOR_REQUIRE_RUNTIME_SMOKE") then
         Fail (Tool, "bin/editor_app missing and no Ada build tool is available");
      else
         Info (Tool, "neither alr nor gprbuild found and bin/editor_app is not executable; runtime smoke skipped");
         return;
      end if;
   end if;

   declare
      Args : GNAT.OS_Lib.Argument_List (1 .. 10) :=
        (new String'("--runtime-smoke"),
         new String'("--runtime-smoke-frames=" & Frames),
         new String'("--runtime-smoke-resize-count=" & Resize_Count),
         new String'("--runtime-smoke-zero-framebuffer"),
         new String'("--runtime-smoke-atlas-min-nonzero=" & Atlas_Min),
         new String'("--runtime-smoke-visual-contract"),
         new String'("--runtime-smoke-resize"),
         new String'("--runtime-smoke-max-seconds=" & Timeout_Seconds),
         new String'("--runtime-smoke-visual-min-rects=" & Env ("EDITOR_RUNTIME_SMOKE_VISUAL_MIN_RECTS", "1")),
         new String'("--runtime-smoke-visual-min-glyphs=" & Env ("EDITOR_RUNTIME_SMOKE_VISUAL_MIN_GLYPHS", "1")));
   begin
      Status := Run ("bin/editor_app", Args);
   end;
   if Status /= 0 then
      Fail (Tool, "runtime smoke failed or exceeded its internal smoke timeout of " & Timeout_Seconds & " seconds");
   end if;
   Info (Tool, "runtime smoke passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Runtime_Smoke;
