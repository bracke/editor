with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Folding;
with Editor.Fonts;
with Editor.Gutter_Markers;
with Editor.Layout;
with Editor.Theme;
with Editor.View;
with Editor.Render_Layers;
with Guikit.Draw;

package body Editor.Gutter.Surface_Rendering is

   use type Editor.Render_Packet.C_Int;
   use type Editor.Gutter_Markers.Gutter_Marker_Kind;

   procedure Push_Rect
     (Packet : in out Editor.Render_Packet.Render_Packet;
      Layer  : Editor.Render_Layers.Render_Layer;
      X, Y, W, H, R, G, B : Float)
   is
      Index : constant Integer := Integer (Packet.Rect_Count);
   begin
      if Index < Editor.Render_Packet.Max_Rectangles then
         Packet.Rects (Index).Layer := Editor.Render_Layers.To_C (Layer);
         Packet.Rects (Index).X := Editor.Render_Packet.C_Float (X);
         Packet.Rects (Index).Y := Editor.Render_Packet.C_Float (Y);
         Packet.Rects (Index).W := Editor.Render_Packet.C_Float (W);
         Packet.Rects (Index).H := Editor.Render_Packet.C_Float (H);
         Packet.Rects (Index).R := Editor.Render_Packet.C_Float (R);
         Packet.Rects (Index).G := Editor.Render_Packet.C_Float (G);
         Packet.Rects (Index).B := Editor.Render_Packet.C_Float (B);
         Packet.Rect_Count := Packet.Rect_Count + 1;
      end if;
   end Push_Rect;

   procedure Push_Glyph
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      Layer          : Editor.Render_Layers.Render_Layer;
      X, Y, W, H     : Float;
      U0, V0, U1, V1 : Float;
      R, G, B        : Float)
   is
      Index : constant Integer := Integer (Packet.Glyph_Count);
   begin
      if Index < Editor.Render_Packet.Max_Glyphs then
         Packet.Glyphs (Index).Layer := Editor.Render_Layers.To_C (Layer);
         Packet.Glyphs (Index).X  := Editor.Render_Packet.C_Float (X);
         Packet.Glyphs (Index).Y  := Editor.Render_Packet.C_Float (Y);
         Packet.Glyphs (Index).W  := Editor.Render_Packet.C_Float (W);
         Packet.Glyphs (Index).H  := Editor.Render_Packet.C_Float (H);
         Packet.Glyphs (Index).U0 := Editor.Render_Packet.C_Float (U0);
         Packet.Glyphs (Index).V0 := Editor.Render_Packet.C_Float (V0);
         Packet.Glyphs (Index).U1 := Editor.Render_Packet.C_Float (U1);
         Packet.Glyphs (Index).V1 := Editor.Render_Packet.C_Float (V1);
         Packet.Glyphs (Index).R  := Editor.Render_Packet.C_Float (R);
         Packet.Glyphs (Index).G  := Editor.Render_Packet.C_Float (G);
         Packet.Glyphs (Index).B  := Editor.Render_Packet.C_Float (B);
         Packet.Glyph_Count := Packet.Glyph_Count + 1;
      end if;
   end Push_Glyph;

   function Screen_Y
     (Layout_Config : Editor.Layout.Layout_Config;
      Visible_Row   : Natural) return Float
   is
   begin
      return Editor.View.Visual_Screen_Y (Layout_Config, Visible_Row);
   end Screen_Y;

   function Baseline_Y
     (Layout_Config : Editor.Layout.Layout_Config;
      Cell_H        : Positive;
      Visible_Row   : Natural) return Float
   is
      Text_Height : constant Float := Editor.Fonts.Ascent - Editor.Fonts.Descent;
      Extra       : constant Float := Float (Cell_H) - Text_Height;
   begin
      return Screen_Y (Layout_Config, Visible_Row)
        + Float'Max (0.0, Extra / 2.0)
        + Editor.Fonts.Ascent;
   end Baseline_Y;

   function Glyph_Y
     (Layout_Config : Editor.Layout.Layout_Config;
      Cell_H        : Positive;
      Visible_Row   : Natural;
      M             : Editor.Fonts.Glyph_Metric) return Float
   is
   begin
      return Baseline_Y (Layout_Config, Cell_H, Visible_Row) - M.Bearing_Y;
   end Glyph_Y;

   function Glyph_X
     (Layout_Config : Editor.Layout.Layout_Config;
      Line_Count    : Natural;
      Cell_W        : Natural;
      Column        : Natural;
      M             : Editor.Fonts.Glyph_Metric) return Float
   is
      Cell_X : constant Float := Editor.View.Visual_Screen_X
        (Layout_Config,
         Line_Count,
         Column);
      X      : Float := Float'Floor (Cell_X + M.Bearing_X + 0.5);
   begin
      if X < Cell_X then
         return Cell_X;
      elsif X > Cell_X + Float (Cell_W) - M.W then
         return Cell_X + Float (Cell_W) - M.W;
      else
         return X;
      end if;
   end Glyph_X;

   function In_Gutter_Viewport
     (Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Line_Count     : Natural;
      X, Y, W, H     : Float) return Boolean
   is
      Left   : constant Float := Editor.Layout.Gutter_Left (Layout_Config);
      Right  : constant Float := Editor.Layout.Gutter_Right (Layout_Config, Line_Count);
      Top    : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout_Config));
      Bottom : constant Float :=
        Editor.Layout.View_Bottom_Y (Layout_Config, Viewport_Height);
   begin
      if Viewport_Width = 0 or else Viewport_Height = 0 then
         return True;
      elsif Right <= Left or else Bottom <= Top then
         return False;
      end if;

      return X + W > Left
        and then X < Right
        and then Y + H > Top
        and then Y < Bottom;
   end In_Gutter_Viewport;

   procedure Push_Gutter_Line_Number
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural;
      Current_Row   : Natural;
      Is_Current    : Boolean;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config)
   is
      Number : constant String := Editor.Line_Numbers.Display_Text
        (Config       => Line_Number_Config,
         Document_Row => Row,
         Current_Row  => Current_Row);
      Line_Number_Color : constant Editor.Theme.Color_RGB :=
        (if Is_Current
         then Editor.Theme.Current_Line_Number
         else Editor.Theme.Inactive_Line_Number);
   begin
      for I in Number'Range loop
         if Number (I) /= ' ' then
            declare
               M : Editor.Fonts.Glyph_Metric;
            begin
               if Editor.Fonts.Get_Glyph (Number (I), M) then
                  Editor.Fonts.Check_Glyph_Fits_Cell
                    (M, Cell_W, Cell_H);
                  declare
                     Digit_From_Right : constant Natural := Number'Last - I;
                     Cell_X : constant Float :=
                       Editor.Layout.Line_Number_Cell_X
                         (Layout_Config, Line_Count, Digit_From_Right);
                     GX : constant Float := Float'Floor (Cell_X + M.Bearing_X + 0.5);
                     GY : constant Float := Float'Floor (Glyph_Y (Layout_Config, Cell_H, Screen_Row, M) + 0.5);
                  begin
                     if In_Gutter_Viewport
                       (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
                        GX, GY, M.W, M.H)
                     then
                        Push_Glyph
                          (Packet, Editor.Render_Layers.Gutter_Text_Layer,
                           GX, GY, M.W, M.H,
                           M.U0, M.V0, M.U1, M.V1,
                           Line_Number_Color.R,
                           Line_Number_Color.G,
                           Line_Number_Color.B);
                     end if;
                  end;
               end if;
            end;
         end if;
      end loop;
   end Push_Gutter_Line_Number;

   procedure Push_Fold_Marker
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural)
   is
      Size : constant Float := Float'Max (4.0, Float (Cell_W) * 0.45);
      X    : constant Float :=
        Float (Editor.Layout.Gutter_Fold_X (Layout_Config));
      Y    : constant Float :=
        Screen_Y (Layout_Config, Screen_Row) + (Float (Cell_H) - Size) / 2.0;
      Collapsed : constant Boolean :=
        Editor.Folding.Is_Fold_Collapsed (Snapshot.Folding, Row);
   begin
      if not Editor.Folding.Has_Fold_Start (Snapshot.Folding, Row) then
         return;
      end if;

      if In_Gutter_Viewport
        (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
         X, Y, Size, Size)
      then
         if Collapsed then
            Push_Rect
              (Packet, Editor.Render_Layers.Fold_Marker_Layer,
               X + Size * 0.25, Y,
               Size * 0.5, Size,
               Editor.Theme.Fold_Marker_Color.R,
               Editor.Theme.Fold_Marker_Color.G,
               Editor.Theme.Fold_Marker_Color.B);
         else
            Push_Rect
              (Packet, Editor.Render_Layers.Fold_Marker_Layer,
               X, Y + Size * 0.25,
               Size, Size * 0.5,
               Editor.Theme.Fold_Marker_Color.R,
               Editor.Theme.Fold_Marker_Color.G,
               Editor.Theme.Fold_Marker_Color.B);
         end if;
      end if;
   end Push_Fold_Marker;

   procedure Push_Gutter_Marker
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural)
   is
      Found : Boolean := False;
      Kind  : Editor.Gutter_Markers.Gutter_Marker_Kind;
      Color : Editor.Theme.Color_RGB;
      Hover_Background : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Marker_Hover_Background;
      Hover_Outline : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Marker_Hover_Outline;
      Zone_W : constant Natural := Editor.Layout.Gutter_Marker_Width;
      Size : constant Float := Float'Max (3.0, Float (Cell_W) * 0.45);
      X : constant Float :=
        Float (Editor.Layout.Gutter_Marker_X (Layout_Config))
        + (Float (Zone_W) - Size) / 2.0;
      Y : constant Float :=
        Screen_Y (Layout_Config, Screen_Row) + (Float (Cell_H) - Size) / 2.0;
      Hover_Active : constant Boolean :=
        Snapshot.Gutter_Marker_Hover.Active
        and then Snapshot.Gutter_Marker_Hover.Row = Row;
      Hover_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout_Config));
      Hover_Y : constant Float := Screen_Y (Layout_Config, Screen_Row);
      Hover_W : constant Float := Float (Zone_W);
      Hover_H : constant Float := Float (Cell_H);
   begin
      if not Editor.Layout.Marker_Zone_Visible (Layout_Config, Line_Count) then
         return;
      end if;

      Kind := Editor.Gutter_Markers.Dominant_Marker_For_Row
        (State => Snapshot.Gutter_Markers,
         Row   => Row,
         Found => Found);

      if not Found then
         return;
      end if;

      case Kind is
         when Editor.Gutter_Markers.Diagnostic_Error_Marker =>
            Color := Editor.Theme.Gutter_Diagnostic_Error;
         when Editor.Gutter_Markers.Diagnostic_Warning_Marker =>
            Color := Editor.Theme.Gutter_Diagnostic_Warning;
         when Editor.Gutter_Markers.Bookmark_Marker =>
            Color := Editor.Theme.Gutter_Bookmark;
         when Editor.Gutter_Markers.Added_Line_Marker =>
            Color := Editor.Theme.Gutter_Added_Line;
         when Editor.Gutter_Markers.Modified_Line_Marker =>
            Color := Editor.Theme.Gutter_Modified_Line;
         when Editor.Gutter_Markers.Dirty_Line_Marker =>
            Color := Editor.Theme.Gutter_Dirty_Line;
      end case;

      if Hover_Active and then In_Gutter_Viewport
        (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
         Hover_X, Hover_Y, Hover_W, Hover_H)
      then
         Push_Rect
           (Packet, Editor.Render_Layers.Gutter_Marker_Hover_Layer,
            Hover_X, Hover_Y, Hover_W, Hover_H,
            Hover_Background.R, Hover_Background.G, Hover_Background.B);
         Push_Rect
           (Packet, Editor.Render_Layers.Gutter_Marker_Hover_Layer,
            Hover_X, Hover_Y, Hover_W, 1.0,
            Hover_Outline.R, Hover_Outline.G, Hover_Outline.B);
         Push_Rect
           (Packet, Editor.Render_Layers.Gutter_Marker_Hover_Layer,
            Hover_X, Hover_Y + Hover_H - 1.0, Hover_W, 1.0,
            Hover_Outline.R, Hover_Outline.G, Hover_Outline.B);
      end if;

      case Kind is
         when Editor.Gutter_Markers.Added_Line_Marker =>
         declare
            Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 3.0);
            Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout_Config));
            Bar_Y : constant Float := Screen_Y (Layout_Config, Screen_Row);
            Bar_H : constant Float := Float (Cell_H);
         begin
            if In_Gutter_Viewport
              (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
               Bar_X, Bar_Y, Bar_W, Bar_H)
            then
               Push_Rect
                 (Packet, Editor.Render_Layers.Gutter_Marker_Layer,
                  Bar_X, Bar_Y, Bar_W, Bar_H,
                  Color.R, Color.G, Color.B);
            end if;
         end;
         when Editor.Gutter_Markers.Modified_Line_Marker =>
         declare
            Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 3.0);
            Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout_Config));
            Bar_H : constant Float := Float'Max (1.0, Float (Cell_H) * 0.75);
            Bar_Y : constant Float :=
              Screen_Y (Layout_Config, Screen_Row) + (Float (Cell_H) - Bar_H) / 2.0;
         begin
            if In_Gutter_Viewport
              (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
               Bar_X, Bar_Y, Bar_W, Bar_H)
            then
               Push_Rect
                 (Packet, Editor.Render_Layers.Gutter_Marker_Layer,
                  Bar_X, Bar_Y, Bar_W, Bar_H,
                  Color.R, Color.G, Color.B);
            end if;
         end;
         when Editor.Gutter_Markers.Dirty_Line_Marker =>
         declare
            Bar_W : constant Float := Float'Max (1.0, Float (Zone_W) / 4.0);
            Bar_X : constant Float := Float (Editor.Layout.Gutter_Marker_X (Layout_Config));
         begin
            if In_Gutter_Viewport
              (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
               Bar_X, Screen_Y (Layout_Config, Screen_Row), Bar_W, Float (Cell_H))
            then
               Push_Rect
                 (Packet, Editor.Render_Layers.Gutter_Marker_Layer,
                  Bar_X, Screen_Y (Layout_Config, Screen_Row), Bar_W, Float (Cell_H),
                  Color.R, Color.G, Color.B);
            end if;
         end;
         when others =>
            if In_Gutter_Viewport
              (Layout_Config, Viewport_Width, Viewport_Height, Line_Count,
               X, Y, Size, Size)
            then
               Push_Rect
                 (Packet, Editor.Render_Layers.Gutter_Marker_Layer,
                  X, Y, Size, Size,
                  Color.R, Color.G, Color.B);
            end if;
      end case;
   end Push_Gutter_Marker;

   procedure Push_Folded_Ellipsis
     (Packet        : in out Editor.Render_Packet.Render_Packet;
      Snapshot      : Editor.Render_Model.Render_Snapshot;
      Layout_Config : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Text_Viewport_Right : Float;
      Cell_W        : Natural;
      Cell_H        : Positive;
      Line_Count    : Natural;
      Row           : Natural;
      Screen_Row    : Natural;
      Start_Col     : Natural)
   is
      Text    : constant String := "...";
      Pen_Col : Natural := Start_Col;
      Left    : constant Float := Float (Editor.Layout.Text_Origin_X (Layout_Config, Line_Count));
      Top     : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout_Config));
      Bottom  : constant Float := Float (Editor.Layout.View_Bottom_Y (Layout_Config, Viewport_Height));
   begin
      if not Editor.Folding.Is_Fold_Collapsed (Snapshot.Folding, Row) then
         return;
      end if;

      for Ch of Text loop
         declare
            M : Editor.Fonts.Glyph_Metric;
         begin
            if Editor.Fonts.Get_Glyph (Ch, M) then
               Editor.Fonts.Check_Glyph_Fits_Cell (M, Cell_W, Cell_H);
               declare
                  GX : constant Float := Float'Floor (Glyph_X (Layout_Config, Line_Count, Cell_W, Pen_Col, M) + 0.5);
                  GY : constant Float := Float'Floor (Glyph_Y (Layout_Config, Cell_H, Screen_Row, M) + 0.5);
               begin
                  if Viewport_Width = 0
                    or else Viewport_Height = 0
                    or else (GX + M.W > Left
                            and then GX < Text_Viewport_Right
                            and then GY + M.H > Top
                            and then GY < Bottom)
                  then
                     Push_Glyph
                       (Packet, Editor.Render_Layers.Text_Layer,
                        GX, GY, M.W, M.H,
                        M.U0, M.V0, M.U1, M.V1,
                        Editor.Theme.Folded_Line_Ellipsis_Color.R,
                        Editor.Theme.Folded_Line_Ellipsis_Color.G,
                        Editor.Theme.Folded_Line_Ellipsis_Color.B);
                  end if;
               end;
            end if;
         end;
         Pen_Col := Pen_Col + 1;
      end loop;
   end Push_Folded_Ellipsis;

end Editor.Gutter.Surface_Rendering;
