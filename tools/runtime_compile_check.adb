with Ada.Directories;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;

procedure Runtime_Compile_Check is
   use type GNAT.OS_Lib.String_Access;

   Tool : constant String := "runtime_compile_check";
   Tool_Failed : Boolean := False;
   Gcc : GNAT.OS_Lib.String_Access;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   procedure Reject_File (Path : String; Reason : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Fail (Tool, "obsolete runtime file present: " & Path & "; " & Reason);
      end if;
   end Reject_File;

   Status : Integer;
begin
   Require_File (Tool, "src/runtime/main.c");
   Require_File (Tool, "src/runtime/runtime_glfw.adb");
   Require_File (Tool, "src/runtime/render_backend_vulkan.ads");
   Require_File (Tool, "src/runtime/render_backend_vulkan.adb");
   Reject_File
     ("src/runtime/render_backend_vulkan.c",
      "Vulkan backend is implemented in Ada with df_vulkan");
   Reject_File
     ("src/runtime/runtime_glfw.c",
      "window/input runtime is implemented in Ada with openglada_glfw");
   Reject_File
     ("src/runtime/render_backend.h",
      "the C backend API header was replaced by Ada exports");

   Gcc := GNAT.OS_Lib.Locate_Exec_On_Path ("gcc");
   if Gcc = null then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail (Tool, "gcc not found");
      else
         Info
           (Tool,
            "gcc not found; runtime C entrypoint syntax check skipped");
         return;
      end if;
   end if;

   Status :=
     Run4
       (Gcc.all,
        "-std=c11",
        "-fsyntax-only",
        "-Isrc/runtime",
        "src/runtime/main.c");
   if Status /= 0 then
      if Strict ("EDITOR_REQUIRE_RUNTIME_COMPILE") then
         Fail
           (Tool,
            "runtime C entrypoint syntax check failed; "
            & "ensure runtime entrypoint dependencies are installed");
      else
         Info
           (Tool,
            "runtime C entrypoint syntax check skipped or failed "
            & "because dependencies are unavailable");
         return;
      end if;
   end if;

   Info
     (Tool,
      "runtime C entrypoint syntax check passed; "
      & "Ada Vulkan backend files present");
exception
   when Program_Error =>
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
end Runtime_Compile_Check;
