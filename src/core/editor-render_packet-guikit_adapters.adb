with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Fonts;
with Editor.Layout;
with Editor.Theme;
with Editor.View;
with Guikit.Draw;
with Guikit.Item_Grid;

package body Editor.Render_Packet.Guikit_Adapters is

   use type Editor.Render_Packet.C_Int;

   function Current_Guikit_Theme return Guikit.Draw.Theme_Kind is
   begin
      if Editor.Theme.Active_Theme_Id = "light" then
         return Guikit.Draw.Theme_Light;
      else
         return Guikit.Draw.Theme_Dark;
      end if;
   end Current_Guikit_Theme;

   function To_Guikit_Color
     (Color : Guikit.Draw.Render_Color) return Editor.Theme.Color_RGB
   is
      Palette : constant Guikit.Draw.Palette_Color :=
        Guikit.Draw.Color_For (Color, Current_Guikit_Theme);
   begin
      return Editor.Theme.RGB (Palette.R, Palette.G, Palette.B);
   end To_Guikit_Color;

   procedure Push_Guikit_Rectangle
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Rect   : Guikit.Draw.Rectangle_Command)
   is
      Color : constant Editor.Theme.Color_RGB := To_Guikit_Color (Rect.Color);
   begin
      if Packet.Rect_Count < Editor.Render_Packet.C_Int (Editor.Render_Packet.Max_Rectangles) then
         Packet.Rects (Integer (Packet.Rect_Count)).Layer := Editor.Render_Layers.To_C (Layer);
         Packet.Rects (Integer (Packet.Rect_Count)).X := Editor.Render_Packet.C_Float (Rect.X);
         Packet.Rects (Integer (Packet.Rect_Count)).Y := Editor.Render_Packet.C_Float (Rect.Y);
         Packet.Rects (Integer (Packet.Rect_Count)).W := Editor.Render_Packet.C_Float (Rect.Width);
         Packet.Rects (Integer (Packet.Rect_Count)).H := Editor.Render_Packet.C_Float (Rect.Height);
         Packet.Rects (Integer (Packet.Rect_Count)).R := Editor.Render_Packet.C_Float (Color.R);
         Packet.Rects (Integer (Packet.Rect_Count)).G := Editor.Render_Packet.C_Float (Color.G);
         Packet.Rects (Integer (Packet.Rect_Count)).B := Editor.Render_Packet.C_Float (Color.B);
         Packet.Rect_Count := Packet.Rect_Count + 1;
      end if;
   end Push_Guikit_Rectangle;

   procedure Push_Guikit_Text
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Cmd    : Guikit.Draw.Text_Command)
   is
      Cursor_X : Float := Float (Cmd.X);
      Text     : constant String := To_String (Cmd.Text);
      Color    : constant Editor.Theme.Color_RGB := To_Guikit_Color (Cmd.Color);
      Cell_W   : constant Natural := Editor.Layout.Cell_W;
      Cell_H   : constant Positive := Editor.Layout.Cell_H;
   begin
      for I in Text'Range loop
         declare
            M : Editor.Fonts.Glyph_Metric;
         begin
            if Text (I) /= ASCII.NUL
              and then Text (I) /= ASCII.CR
              and then Text (I) /= ASCII.LF
              and then Editor.Fonts.Get_Glyph (Text (I), M)
            then
               Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
               if M.W > 0.0 and then M.H > 0.0 then
                  if Packet.Glyph_Count < Editor.Render_Packet.C_Int (Editor.Render_Packet.Max_Glyphs) then
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).Layer := Editor.Render_Layers.To_C (Layer);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).X :=
                       Editor.Render_Packet.C_Float
                         (Float'Floor (Cursor_X + M.Bearing_X + 0.5));
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).Y :=
                       Editor.Render_Packet.C_Float
                         (Float'Floor
                            (Float (Cmd.Y)
                             + Float'Max
                                 (0.0,
                                  (Float (Cell_H)
                                   - (Editor.Fonts.Ascent - Editor.Fonts.Descent))
                                  / 2.0)
                             + Editor.Fonts.Ascent
                             - M.Bearing_Y
                             + 0.5));
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).W := Editor.Render_Packet.C_Float (M.W);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).H := Editor.Render_Packet.C_Float (M.H);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).U0 := Editor.Render_Packet.C_Float (M.U0);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).V0 := Editor.Render_Packet.C_Float (M.V0);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).U1 := Editor.Render_Packet.C_Float (M.U1);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).V1 := Editor.Render_Packet.C_Float (M.V1);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).R  := Editor.Render_Packet.C_Float (Color.R);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).G  := Editor.Render_Packet.C_Float (Color.G);
                     Packet.Glyphs (Integer (Packet.Glyph_Count)).B  := Editor.Render_Packet.C_Float (Color.B);
                     Packet.Glyph_Count := Packet.Glyph_Count + 1;
                  end if;
               end if;
            end if;
            Cursor_X := Cursor_X + Float (Cell_W);
         end;
      end loop;
   end Push_Guikit_Text;

   procedure Push_Item_Grid_Background
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      Clip_Width  : Natural;
      Clip_Height : Natural;
      X, Y, W, H  : Float;
      Kind        : Guikit.Item_Grid.Background_Kind)
   is
      Rects : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Cell  : constant Guikit.Item_Grid.Item_Layout :=
        (X => Natural (Float'Floor (X)),
         Y => Natural (Float'Floor (Y)),
         Width => Natural (Float'Floor (W)),
         Height => Natural (Float'Floor (H)),
         others => <>);
   begin
      Guikit.Item_Grid.Draw_Item_Background
        (Rectangles      => Rects,
         Clip_Width      => Clip_Width,
         Clip_Height     => Clip_Height,
         Cell            => Cell,
         Kind            => Kind,
         Selection_Color => Guikit.Draw.Selection_Color,
         Hover_Color     => Guikit.Draw.Hover_Color,
         Border_Color    => Guikit.Draw.Border_Color,
         Alternate_Color => Guikit.Draw.Detail_Alternate_Color);

      for R of Rects loop
         Push_Guikit_Rectangle (Packet, Layer, R);
      end loop;
   end Push_Item_Grid_Background;

end Editor.Render_Packet.Guikit_Adapters;
