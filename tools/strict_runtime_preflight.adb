with Editor_Tool_Common; use Editor_Tool_Common;

procedure Strict_Runtime_Preflight is
   Tool : constant String := "strict_runtime_preflight";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Missing : Natural := 0;

   procedure Require_Command (Name : String) is
   begin
      if not Command_Exists (Name) then
         Info (Tool, "missing required command for strict runtime validation: " & Name);
         Missing := Missing + 1;
      else
         Info (Tool, "found command: " & Name);
      end if;
   end Require_Command;

   procedure Require_One_Build_Tool is
   begin
      if Command_Exists ("alr") then
         Info (Tool, "found Ada build tool: alr");
      elsif Command_Exists ("gprbuild") then
         Info (Tool, "found Ada build tool: gprbuild");
      else
         Info (Tool, "missing required Ada build tool: alr or gprbuild");
         Missing := Missing + 1;
      end if;
   end Require_One_Build_Tool;

   procedure Require_Display is
   begin
      if Env ("DISPLAY") /= "" then
         Info (Tool, "found graphical display: DISPLAY=" & Env ("DISPLAY"));
      elsif Env ("WAYLAND_DISPLAY") /= "" then
         Info (Tool, "found graphical display: WAYLAND_DISPLAY=" & Env ("WAYLAND_DISPLAY"));
      else
         Info (Tool, "missing graphical runtime session: DISPLAY or WAYLAND_DISPLAY");
         Missing := Missing + 1;
      end if;
   end Require_Display;

begin
   Require_File (Tool, "editor.gpr");
   Require_File (Tool, "src/runtime/main.c");
   Require_File (Tool, "src/runtime/runtime_glfw.c");
   Require_File (Tool, "src/runtime/render_backend_vulkan.c");
   Require_File (Tool, "src/runtime/shaders/rect.vert.spv");
   Require_File (Tool, "src/runtime/shaders/rect.frag.spv");
   Require_File (Tool, "src/runtime/shaders/text.vert.spv");
   Require_File (Tool, "src/runtime/shaders/text.frag.spv");
   Require_File (Tool, "docs/release/SHADER_TOOLCHAIN_VERSION.txt");

   Require_Command ("gcc");
   Require_One_Build_Tool;
   Require_Command ("glslangValidator");
   Require_Display;

   if not Command_Exists ("vulkaninfo") then
      Info (Tool, "vulkaninfo not found; continuing because runtime_smoke is the authoritative Vulkan runtime gate");
   else
      Info (Tool, "found optional Vulkan diagnostic command: vulkaninfo");
   end if;

   if Missing /= 0 then
      if Strict ("EDITOR_REQUIRE_STRICT_RUNTIME_PREFLIGHT")
        or else Strict ("EDITOR_REQUIRE_RUNTIME_SMOKE")
        or else Strict ("EDITOR_REQUIRE_RUNTIME_LINK")
      then
         Fail (Tool, "strict runtime validation preflight failed with" & Natural'Image (Missing) & " missing requirement(s)");
      else
         Info (Tool, "strict runtime validation preflight found" & Natural'Image (Missing) & " missing requirement(s); skipped in non-strict mode");
         return;
      end if;
   end if;

   Info (Tool, "strict runtime validation preflight passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Strict_Runtime_Preflight;
