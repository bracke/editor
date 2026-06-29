with Interfaces.C;
with Interfaces.C.Strings;
with Editor.Bridge;
with Editor.Render_Packet;

package Editor.C_API is

   procedure Editor_Init;
   pragma Export (C, Editor_Init, "editor_init");

   procedure Editor_Open_Project_Path
     (Path : Interfaces.C.Strings.chars_ptr);
   pragma Export
     (C, Editor_Open_Project_Path, "editor_open_project_path");

   procedure Editor_Handle_Platform_Event
     (Ev : Editor.Bridge.Platform_Event);
   pragma Export
     (C, Editor_Handle_Platform_Event, "editor_handle_platform_event");

   function Editor_Should_Quit return Interfaces.C.int;
   pragma Export (C, Editor_Should_Quit, "editor_should_quit");

   procedure Editor_Set_Viewport_Size
     (W, H : Interfaces.C.int);
   pragma Export
     (C, Editor_Set_Viewport_Size, "editor_set_viewport_size");

   procedure Editor_Set_Time_Seconds
     (T : Interfaces.C.double);
   pragma Export
     (C, Editor_Set_Time_Seconds, "editor_set_time_seconds");

   procedure Editor_Tick;
   pragma Export (C, Editor_Tick, "editor_tick");

   procedure Editor_Get_Render_Packet
     (Packet : out Editor.Render_Packet.Render_Packet);
   pragma Export
     (C, Editor_Get_Render_Packet, "editor_get_render_packet");

end Editor.C_API;
