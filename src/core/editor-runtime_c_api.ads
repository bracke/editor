with Interfaces.C;
with System;

package Editor.Runtime_C_API is
   pragma Elaborate_Body;

   subtype C_Float is Interfaces.C.C_float;
   subtype C_Int is Interfaces.C.int;

   Max_Rectangles : constant := 8192;
   Max_Glyphs     : constant := 8192;

   type Platform_Event is record
      Kind    : C_Int := 0;
      Ch      : Interfaces.C.unsigned := 0;
      Shift   : C_Int := 0;
      Ctrl    : C_Int := 0;
      Alt     : C_Int := 0;
      X       : C_Int := 0;
      Y       : C_Int := 0;
      Wheel_X : C_Int := 0;
      Wheel_Y : C_Int := 0;
   end record;
   pragma Convention (C_Pass_By_Copy, Platform_Event);

   type Rect_Command is record
      Layer : C_Int := 0;
      X     : C_Float := 0.0;
      Y     : C_Float := 0.0;
      W     : C_Float := 0.0;
      H     : C_Float := 0.0;
      R     : C_Float := 0.0;
      G     : C_Float := 0.0;
      B     : C_Float := 0.0;
   end record;
   pragma Convention (C_Pass_By_Copy, Rect_Command);

   type Glyph_Command is record
      Layer : C_Int := 0;
      X     : C_Float := 0.0;
      Y     : C_Float := 0.0;
      W     : C_Float := 0.0;
      H     : C_Float := 0.0;
      U0    : C_Float := 0.0;
      V0    : C_Float := 0.0;
      U1    : C_Float := 0.0;
      V1    : C_Float := 0.0;
      R     : C_Float := 0.0;
      G     : C_Float := 0.0;
      B     : C_Float := 0.0;
   end record;
   pragma Convention (C_Pass_By_Copy, Glyph_Command);

   type Rect_Array is array (0 .. Max_Rectangles - 1) of Rect_Command;
   pragma Convention (C, Rect_Array);

   type Glyph_Array is array (0 .. Max_Glyphs - 1) of Glyph_Command;
   pragma Convention (C, Glyph_Array);

   type Render_Packet is record
      Rect_Count  : C_Int := 0;
      Glyph_Count : C_Int := 0;
      Rects       : Rect_Array;
      Glyphs      : Glyph_Array;
   end record;
   pragma Convention (C_Pass_By_Copy, Render_Packet);

   procedure Editor_Init;
   pragma Export (C, Editor_Init, "editor_init");

   procedure Editor_Handle_Platform_Event (Ev : Platform_Event);
   pragma Export (C, Editor_Handle_Platform_Event, "editor_handle_platform_event");

   function Editor_Should_Quit return C_Int;
   pragma Export (C, Editor_Should_Quit, "editor_should_quit");

   procedure Editor_Set_Viewport_Size (W, H : C_Int);
   pragma Export (C, Editor_Set_Viewport_Size, "editor_set_viewport_size");

   procedure Editor_Set_Time_Seconds (T : Interfaces.C.double);
   pragma Export (C, Editor_Set_Time_Seconds, "editor_set_time_seconds");

   procedure Editor_Tick;
   pragma Export (C, Editor_Tick, "editor_tick");

   procedure Editor_Get_Render_Packet (Packet : out Render_Packet);
   pragma Export (C, Editor_Get_Render_Packet, "editor_get_render_packet");

   function Font_Atlas_Width return C_Int;
   pragma Export (C, Font_Atlas_Width, "editor_font_atlas_width");

   function Font_Atlas_Height return C_Int;
   pragma Export (C, Font_Atlas_Height, "editor_font_atlas_height");

   function Font_Atlas_Pixels return System.Address;
   pragma Export (C, Font_Atlas_Pixels, "editor_font_atlas_pixels");

   function Font_Atlas_Dirty return C_Int;
   pragma Export (C, Font_Atlas_Dirty, "editor_font_atlas_dirty");

   procedure Font_Clear_Atlas_Dirty;
   pragma Export (C, Font_Clear_Atlas_Dirty, "editor_font_clear_atlas_dirty");
end Editor.Runtime_C_API;
