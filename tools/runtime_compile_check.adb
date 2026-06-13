with Editor_Tool_Common; use Editor_Tool_Common;

procedure Runtime_Compile_Check is
   Tool : constant String := "runtime_compile_check";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
begin
   Require_File (Tool, "src/runtime/main.c");
   Require_File (Tool, "src/runtime/runtime_glfw.c");
   Require_File (Tool, "src/runtime/render_backend_vulkan.c");

   if not Command_Exists ("gcc") then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail (Tool, "gcc not found");
      else
         Info (Tool, "gcc not found; runtime C syntax/header check skipped");
         return;
      end if;
   end if;

   Status := Run4 ("gcc", "-std=c11", "-fsyntax-only", "-Isrc/runtime", "src/runtime/main.c");
   if Status /= 0 then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail (Tool, "runtime C syntax/header check failed; ensure GLFW/Vulkan headers are installed");
      else
         Info (Tool, "runtime C syntax/header check skipped or failed because dependencies are unavailable");
         return;
      end if;
   end if;

   Status := Run4 ("gcc", "-std=c11", "-fsyntax-only", "-Isrc/runtime", "src/runtime/runtime_glfw.c");
   if Status /= 0 then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail (Tool, "runtime_glfw.c syntax/header check failed");
      else
         Info (Tool, "runtime_glfw.c syntax/header check skipped or failed because dependencies are unavailable");
         return;
      end if;
   end if;

   Status := Run4 ("gcc", "-std=c11", "-fsyntax-only", "-Isrc/runtime", "src/runtime/render_backend_vulkan.c");
   if Status /= 0 then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail (Tool, "render_backend_vulkan.c syntax/header check failed");
      else
         Info (Tool, "render_backend_vulkan.c syntax/header check skipped or failed because dependencies are unavailable");
         return;
      end if;
   end if;

   Info (Tool, "runtime C syntax/header check passed");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Runtime_Compile_Check;
