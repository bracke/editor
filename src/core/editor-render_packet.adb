with Interfaces.C; use Interfaces.C;
with Editor.Render_Packet.Surface_Registry;
with Editor.Render_Layers; use Editor.Render_Layers;

package body Editor.Render_Packet is

   procedure Push_Rect
     (Packet : in out Render_Packet;
      Layer : Render_Layer;
      X, Y, W, H, R, G, B : Float)
   is
      Index : constant Integer := Integer (Packet.Rect_Count);
   begin
      if Index < Max_Rectangles then
         Packet.Rects (Index).Layer := To_C (Layer);
         Packet.Rects (Index).X := C_Float (X);
         Packet.Rects (Index).Y := C_Float (Y);
         Packet.Rects (Index).W := C_Float (W);
         Packet.Rects (Index).H := C_Float (H);
         Packet.Rects (Index).R := C_Float (R);
         Packet.Rects (Index).G := C_Float (G);
         Packet.Rects (Index).B := C_Float (B);
         Packet.Rect_Count := Packet.Rect_Count + 1;
      end if;
   end Push_Rect;

   procedure Push_Glyph
     (Packet         : in out Render_Packet;
      Layer          : Render_Layer;
      X, Y, W, H     : Float;
      U0, V0, U1, V1 : Float;
      R, G, B        : Float;
      Colour         : Boolean := False)
   is
      Index : constant Integer := Integer (Packet.Glyph_Count);
   begin
      if Index < Max_Glyphs then
         Packet.Glyphs (Index).Layer := To_C (Layer);
         Packet.Glyphs (Index).X  := C_Float (X);
         Packet.Glyphs (Index).Y  := C_Float (Y);
         Packet.Glyphs (Index).W  := C_Float (W);
         Packet.Glyphs (Index).H  := C_Float (H);
         Packet.Glyphs (Index).U0 := C_Float (U0);
         Packet.Glyphs (Index).V0 := C_Float (V0);
         Packet.Glyphs (Index).U1 := C_Float (U1);
         Packet.Glyphs (Index).V1 := C_Float (V1);
         Packet.Glyphs (Index).R  := C_Float (R);
         Packet.Glyphs (Index).G  := C_Float (G);
         Packet.Glyphs (Index).B  := C_Float (B);
         Packet.Glyphs (Index).Colour := (if Colour then 1 else 0);
         Packet.Glyph_Count := Packet.Glyph_Count + 1;
      end if;
   end Push_Glyph;

   procedure Build_Render_Packet
     (Out_Packet : out Render_Packet)
     renames Editor.Render_Packet.Surface_Registry.Build_Render_Packet;

end Editor.Render_Packet;
