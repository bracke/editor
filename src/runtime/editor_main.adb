with Ada.Command_Line;

with Interfaces.C.Strings;

with System;

--  These two export the C entry points main.c calls -- runtime_glfw_run_with_options and
--  render_backend_validate_required_shader_assets. Naming them here is what puts them in
--  the binder's closure. That is the point of an Ada main: the closure is computed, so
--  what is used gets linked and what is not, does not.
with Render_Backend_Vulkan;
with Runtime_Glfw;
pragma Unreferenced (Render_Backend_Vulkan);
pragma Unreferenced (Runtime_Glfw);

--  The editor's entry point.
--
--  The C main it replaces did the same work, but a C main leaves the binder with no Ada
--  main to compute a closure from -- so gprbuild binds every Ada unit of every withed
--  project. That dragged in df_vulkan's SPARK safety layer, whose generated wrappers call
--  Vulkan extension entry points that libvulkan does not export, and the link failed. The
--  editor worked around it by not depending on df_vulkan or guikit at all: it reached
--  into df_vulkan's prefix for vk.ads, and compiled guikit's sources as if they were its
--  own. Both were the same fix for the same missing closure.
--
--  An Ada main gives the binder its closure. The safety layer, which nothing withs, stays
--  out of the link, and the editor can depend on its dependencies.
--
--  The argument parsing stays in C, where it already was: this hands argv straight back.
procedure Editor_Main is
   use type Interfaces.C.int;

   function Run
     (Argc : Interfaces.C.int;
      Argv : System.Address)
      return Interfaces.C.int
     with Import => True, Convention => C, External_Name => "editor_main";

   Count : constant Natural := Ada.Command_Line.Argument_Count;

   --  argv, the way C expects it: the program name, the arguments, and a null.
   type Argument_Vector is
     array (0 .. Count + 1) of aliased Interfaces.C.Strings.chars_ptr
     with Convention => C;

   Arguments : Argument_Vector;
   Status    : Interfaces.C.int;
begin
   Arguments (0) := Interfaces.C.Strings.New_String (Ada.Command_Line.Command_Name);

   for Index in 1 .. Count loop
      Arguments (Index) :=
        Interfaces.C.Strings.New_String (Ada.Command_Line.Argument (Index));
   end loop;

   Arguments (Count + 1) := Interfaces.C.Strings.Null_Ptr;

   Status := Run (Interfaces.C.int (Count + 1), Arguments (0)'Address);

   for Index in 0 .. Count loop
      Interfaces.C.Strings.Free (Arguments (Index));
   end loop;

   Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Exit_Status (Status));
end Editor_Main;
