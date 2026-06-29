with Interfaces.C;
with Interfaces.C.Strings;


package body Editor.Runtime_C_API is
   use type Interfaces.C.Strings.chars_ptr;

   Viewport_W : C_Int := 800;
   Viewport_H : C_Int := 600;
   Atlas_Is_Dirty : Boolean := True;

   type Atlas_Bytes is array (0 .. 3) of aliased Interfaces.C.unsigned_char;
   pragma Convention (C, Atlas_Bytes);

   Atlas : aliased constant Atlas_Bytes :=
     (0 => 255, 1 => 255, 2 => 255, 3 => 255);

   procedure Editor_Init is
   begin
      Viewport_W := 800;
      Viewport_H := 600;
      Atlas_Is_Dirty := True;
   end Editor_Init;

   procedure Editor_Open_Project_Path
     (Path : Interfaces.C.Strings.chars_ptr)
   is
      pragma Unreferenced (Path);
   begin
      null;
   end Editor_Open_Project_Path;

   procedure Editor_Handle_Platform_Event (Ev : Platform_Event) is
      pragma Unreferenced (Ev);
   begin
      null;
   end Editor_Handle_Platform_Event;

   function Editor_Should_Quit return C_Int is
   begin
      return 0;
   end Editor_Should_Quit;

   procedure Editor_Set_Viewport_Size (W, H : C_Int) is
   begin
      if Integer (W) > 0 then
         Viewport_W := W;
      end if;
      if Integer (H) > 0 then
         Viewport_H := H;
      end if;
   end Editor_Set_Viewport_Size;

   procedure Editor_Set_Time_Seconds (T : Interfaces.C.double) is
      pragma Unreferenced (T);
   begin
      null;
   end Editor_Set_Time_Seconds;

   procedure Editor_Tick is
   begin
      null;
   end Editor_Tick;

   procedure Editor_Get_Render_Packet (Packet : out Render_Packet) is
      Width  : constant C_Float := C_Float (Viewport_W);
      Height : constant C_Float := C_Float (Viewport_H);
   begin
      Packet := (others => <>);
      Packet.Rect_Count := 1;
      Packet.Rects (0) :=
        (Layer => 0,
         X     => 0.0,
         Y     => 0.0,
         W     => Width,
         H     => Height,
         R     => 0.08,
         G     => 0.09,
         B     => 0.10);
      Packet.Glyph_Count := 1;
      Packet.Glyphs (0) :=
        (Layer => 22,
         X     => 24.0,
         Y     => 24.0,
         W     => 12.0,
         H     => 16.0,
         U0    => 0.0,
         V0    => 0.0,
         U1    => 1.0,
         V1    => 1.0,
         R     => 0.85,
         G     => 0.88,
         B     => 0.92);
   end Editor_Get_Render_Packet;

   function Font_Atlas_Width return C_Int is
   begin
      return 1;
   end Font_Atlas_Width;

   function Font_Atlas_Height return C_Int is
   begin
      return 1;
   end Font_Atlas_Height;

   function Font_Atlas_Pixels return System.Address is
   begin
      return Atlas'Address;
   end Font_Atlas_Pixels;

   function Font_Atlas_Dirty return C_Int is
   begin
      return (if Atlas_Is_Dirty then 1 else 0);
   end Font_Atlas_Dirty;

   procedure Font_Clear_Atlas_Dirty is
   begin
      Atlas_Is_Dirty := False;
   end Font_Clear_Atlas_Dirty;
end Editor.Runtime_C_API;
