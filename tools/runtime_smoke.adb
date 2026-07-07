with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with Interfaces.C;
with Interfaces.C.Strings;

procedure Runtime_Smoke is
   package C renames Interfaces.C;
   package C_Strings renames Interfaces.C.Strings;

   Tool : constant String := "runtime_smoke";
   Tool_Failed : Boolean := False;

   function C_System (Command : C_Strings.chars_ptr) return C.int
     with Import, Convention => C, External_Name => "system";

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
   if not Ada.Directories.Exists ("bin/editor") then
      if Command_Exists ("alr") then
         Status := Run0 ("tools/bin/runtime_link_check");
         if Status /= 0 then
            Fail (Tool, "could not build bin/editor before smoke");
         end if;
      elsif Strict ("EDITOR_REQUIRE_RUNTIME_SMOKE") then
         Fail (Tool, "bin/editor missing and alr is unavailable");
      else
         Info
           (Tool,
            "alr not found and bin/editor is not "
            & "executable; runtime smoke skipped");
         return;
      end if;
   end if;

   declare
      Command : constant String :=
        "./bin/editor --runtime-smoke"
        & " --runtime-smoke-frames=" & Frames
        & " --runtime-smoke-resize-count=" & Resize_Count
        & " --runtime-smoke-zero-framebuffer"
        & " --runtime-smoke-atlas-min-nonzero=" & Atlas_Min
        & " --runtime-smoke-visual-contract"
        & " --runtime-smoke-resize"
        & " --runtime-smoke-max-seconds=" & Timeout_Seconds
        & " --runtime-smoke-visual-min-rects="
        & Env ("EDITOR_RUNTIME_SMOKE_VISUAL_MIN_RECTS", "1")
        & " --runtime-smoke-visual-min-glyphs="
        & Env ("EDITOR_RUNTIME_SMOKE_VISUAL_MIN_GLYPHS", "1");
      C_Command : C_Strings.chars_ptr := C_Strings.New_String (Command);
   begin
      Status := Integer (C_System (C_Command));
      C_Strings.Free (C_Command);
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
