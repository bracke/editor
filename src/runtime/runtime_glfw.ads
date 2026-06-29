with Interfaces.C;
with Interfaces.C.Strings;

package Runtime_GLFW is
   type Runtime_Glfw_Options is record
      Smoke_Mode                       : Interfaces.C.int := 0;
      Smoke_Max_Frames                 : Interfaces.C.int := 0;
      Smoke_Resize                     : Interfaces.C.int := 0;
      Smoke_Resize_Count               : Interfaces.C.int := 0;
      Smoke_Zero_Framebuffer           : Interfaces.C.int := 0;
      Smoke_Atlas_Min_Nonzero_Bytes    : Interfaces.C.unsigned := 0;
      Smoke_Visual_Contract            : Interfaces.C.int := 0;
      Smoke_Visual_Min_Rects           : Interfaces.C.unsigned := 0;
      Smoke_Visual_Min_Glyphs          : Interfaces.C.unsigned := 0;
      Smoke_Max_Seconds                : Interfaces.C.int := 0;
      Project_Path                     : Interfaces.C.Strings.chars_ptr :=
        Interfaces.C.Strings.Null_Ptr;
   end record;
   pragma Convention (C_Pass_By_Copy, Runtime_Glfw_Options);

   type Runtime_Glfw_Options_Access is access all Runtime_Glfw_Options;
   pragma Convention (C, Runtime_Glfw_Options_Access);

   function Runtime_Glfw_Run return Interfaces.C.int;
   pragma Export (C, Runtime_Glfw_Run, "runtime_glfw_run");

   function Runtime_Glfw_Run_With_Options
     (Options : Runtime_Glfw_Options_Access) return Interfaces.C.int;
   pragma Export
     (C, Runtime_Glfw_Run_With_Options, "runtime_glfw_run_with_options");
end Runtime_GLFW;
