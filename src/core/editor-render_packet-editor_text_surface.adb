with Ada.Containers; use Ada.Containers;
with Editor.Diagnostics;
with Editor.Folding;
with Editor.Fonts;
with Editor.Gutter.Surface_Rendering;
with Editor.Input_Bridge;
with Editor.Layout;
with Editor.Cursor;
with Editor.Line_Numbers;
with Editor.Minimap;
with Editor.Render_Cache;
with Editor.Render_Layers; use Editor.Render_Layers;
with Editor.Render_Model;
with Editor.Render_Packet.Geometry;
with Editor.Render_Packet.Render_Context;
with Editor.Scrollbars;
with Editor.Search;
with Editor.Settings;
with Editor.Syntax;
with Editor.Theme;
with Editor.Unicode;
with Editor.View;
with Editor.Wrap;

package body Editor.Render_Packet.Editor_Text_Surface is

   use Editor.Render_Packet.Geometry;

   use type Editor.Line_Numbers.Line_Number_Mode;
   use type Editor.Search.Search_Match_Index;
   use type Editor.Wrap.Wrap_Mode;
   procedure Render
     (Packet : in out Render_Packet;
      Context : Editor.Render_Packet.Render_Context.Context)
   is
      Snap   : Editor.Render_Model.Render_Snapshot renames Context.Snap;
      Layout : Editor.Layout.Layout_Config renames Context.Layout;
      Cell_W : Positive renames Context.Cell_W;
      Cell_H : Positive renames Context.Cell_H;
      Scroll_X : Natural renames Context.Scroll_X;
      Cursor_Config : Editor.Cursor.Cursor_Config renames Context.Cursor_Config;
      Minimap : Editor.Minimap.Minimap_Config renames Context.Minimap;
      Settings : Editor.Settings.Settings_State renames Context.Settings;
      Line_Number_Config : Editor.Line_Numbers.Line_Number_Config renames Context.Line_Number_Config;
      Scrollbars : Editor.Scrollbars.Scrollbar_Config renames Context.Scrollbars;
      Effective_Viewport_W : Natural renames Context.Effective_Viewport_W;
      Effective_Viewport_H : Natural renames Context.Effective_Viewport_H;
      Effective_Minimap_Enabled : Boolean renames Context.Effective_Minimap_Enabled;
      Out_Packet : Render_Packet renames Packet;
      Gutter_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Background;
      Gutter_Separator_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Gutter_Separator;
      Current_Text_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Current_Text_Row;
      Current_Gutter_Row_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Current_Gutter_Row;
      Active_Find_Inactive_Match_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Inactive_Match;
      Active_Find_Match_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Active_Find_Match;
      Selection_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Selection_Background;
      Selection_Text_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Syntax_Color (Editor.Syntax.Selection_Overlay);
      Cursor_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Cursor_Color;
      Minimap_Background_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Background;
      Minimap_Text_Density_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Content;
      Minimap_Viewport_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Minimap_Viewport;
      Scrollbar_Track_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Scrollbar_Track;
      Scrollbar_Thumb_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Scrollbar_Thumb;
      Fold_Marker_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Fold_Marker_Color;
      Folded_Line_Ellipsis_Color : constant Editor.Theme.Color_RGB :=
        Editor.Theme.Folded_Line_Ellipsis_Color;
   begin
      if Editor.View.Viewport_Width > 0
        and then Editor.View.Viewport_Height > 0
        and then Editor.Layout.Gutter_Width_For_Line_Count (Layout, Line_Count (Context)) > 0
      then
         declare
            X : constant Float := Editor.Layout.Gutter_Left (Layout);
            Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
            W : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count (Context)) - X;
            H : constant Float := Float (Text_Viewport_Height (Context));
         begin
            if In_Gutter_Viewport (Context, X, Y, W, H) then
               Push_Rect
                 (Out_Packet, Gutter_Background_Layer,
                  X, Y, W, H,
                  Gutter_Background_Color.R,
                  Gutter_Background_Color.G,
                  Gutter_Background_Color.B);
            end if;
         end;
      end if;

      declare
         X : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count (Context)) - 1.0;
         Y : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
         W : constant Float := 1.0;
         H : constant Float := Float (Text_Viewport_Height (Context));
      begin
         Push_Rect
           (Out_Packet, Gutter_Separator_Layer,
            X, Y, W, H,
            Gutter_Separator_Color.R,
            Gutter_Separator_Color.G,
            Gutter_Separator_Color.B);
      end;

      -- Current visual row highlight.
      if Snap.Caret_Count > 0 then
         declare
            Caret_Row : Natural := 0;
            Caret_Col : Natural := 0;
            Segment_Index : Natural := 0;
         begin
            Row_Col_For_Index (Context, Natural (Snap.Caret_Pos (1)), Caret_Row, Caret_Col);
            if Snap.Caret_Virtual_Column (1) > 0 then
               Caret_Col := Snap.Caret_Virtual_Column (1);
            end if;
            Segment_Index := Segment_For_Caret (Context, Caret_Row, Caret_Col);
            if Segment_Index > 0 then
               declare
                  Screen_Row : constant Natural := Segment_Index - 1;
                  X : constant Float := Float (Editor.Layout.Text_Origin_X (Layout, Line_Count (Context)));
                  Y : constant Float := Screen_Y (Context, Screen_Row);
                  W : constant Float := Float (Text_Viewport_Width (Context));
                  H : constant Float := Float (Cell_H);
                  GX : constant Float := Editor.Layout.Gutter_Left (Layout);
                  GY : constant Float := Screen_Y (Context, Screen_Row);
                  GW : constant Float := Editor.Layout.Gutter_Right (Layout, Line_Count (Context)) - GX;
                  GH : constant Float := Float (Cell_H);
               begin
                  if Settings.Highlight_Current_Gutter
                    and then In_Gutter_Viewport (Context, GX, GY, GW, GH)
                  then
                     Push_Rect
                       (Out_Packet, Current_Line_Layer,
                        GX, GY, GW, GH,
                        Current_Gutter_Row_Color.R,
                        Current_Gutter_Row_Color.G,
                        Current_Gutter_Row_Color.B);
                  end if;
                  if Settings.Highlight_Current_Line
                    and then In_Viewport (Context, X, Y, W, H)
                  then
                     Push_Rect
                       (Out_Packet, Current_Line_Layer,
                        X, Y, W, H,
                        Current_Text_Row_Color.R,
                        Current_Text_Row_Color.G,
                        Current_Text_Row_Color.B);
                  end if;
               end;
            end if;
         end;
      end if;

      -- Search match rectangles over visible visual segments only.
      --
      -- Unlike text glyphs, highlight rectangles are solid quads; do not rely
      -- on backend clipping to hide the portion left of the text viewport when
      -- horizontal scrolling is active.  Clip the emitted segment to the
      -- visible grid columns before converting it to screen coordinates.
      if Snap.Active_Find_Match_Count > 0 and then Snap.Line_Starts.Length > 0 then
         declare
            Viewport_Cols : constant Natural :=
              (Text_Viewport_Width (Context) + Cell_W - 1) / Cell_W;
         begin
            for MIdx in 1 .. Snap.Active_Find_Match_Count loop
               declare
                  Match     : constant Editor.Search.Search_Match := Snap.Active_Find_Matches (MIdx);
                  Is_Active : constant Boolean :=
                    Match.End_Index > Snap.Active_Find_Match.Start_Index
                    and then Match.Start_Index < Snap.Active_Find_Match.End_Index;
                  Color     : constant Editor.Theme.Color_RGB :=
                    (if Is_Active then Active_Find_Match_Background_Color
                     else Active_Find_Inactive_Match_Background_Color);
               begin
                  if Match.End_Index > Match.Start_Index and then Viewport_Cols > 0 then
                     for I in 1 .. Snap.Visible_Visual_Count loop
                        declare
                           Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                           Row_Start : constant Natural := Index_For_Row_Start (Context, Seg.Logical_Row);
                           Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                           Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                           Hit_Start : constant Natural := Natural'Max (Natural (Match.Start_Index), Seg_Start);
                           Hit_End   : constant Natural := Natural'Min (Natural (Match.End_Index), Seg_End);
                        begin
                           if Hit_Start < Hit_End then
                              declare
                                 Start_Col : constant Natural := Hit_Start - Row_Start;
                                 End_Col   : constant Natural := Hit_End - Row_Start;
                                 Clip_Start_Col : constant Natural :=
                                   (if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                    then Natural'Max (Start_Col, Scroll_X)
                                    else Start_Col);
                                 Clip_End_Col : constant Natural :=
                                   (if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                    then Natural'Min (End_Col, Scroll_X + Viewport_Cols)
                                    else End_Col);
                              begin
                                 if Clip_Start_Col < Clip_End_Col then
                                    declare
                                       X : constant Float :=
                                         Screen_X (Context, Screen_Col_For (Context, Seg, Clip_Start_Col));
                                       Y : constant Float := Screen_Y (Context, I - 1);
                                       W : constant Float :=
                                         Float
                                           (Editor.Layout.Text_Cell_Width
                                              (Clip_End_Col - Clip_Start_Col));
                                       H : constant Float := Float (Cell_H);
                                    begin
                                       if In_Viewport (Context, X, Y, W, H) then
                                          Push_Rect
                                            (Out_Packet, Active_Find_Match_Layer,
                                             X, Y, W, H,
                                             Color.R, Color.G, Color.B);
                                       end if;
                                    end;
                                 end if;
                              end;
                           end if;
                        end;
                     end loop;
                  end if;
               end;
            end loop;
         end;
      end if;

      -- Rectangular selection rectangles. These are grid-cell spans and
      -- intentionally render even when the selected cells are virtual beyond
      -- the physical end of a short line.
      if Snap.Rectangular_Selection_Count > 0 then
         for RIdx in 1 .. Snap.Rectangular_Selection_Count loop
            declare
               Span : constant Editor.Render_Model.Rectangular_Selection_Row_Span :=
                 Snap.Rectangular_Selections (RIdx);
            begin
               if Span.Start_Column < Span.End_Column then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg : constant Editor.Wrap.Visual_Row_Info :=
                          Snap.Visible_Visual_Rows (I);
                     begin
                        if Seg.Logical_Row = Span.Row then
                           declare
                              X : constant Float :=
                                Screen_X (Context, Screen_Col_For (Context, Seg, Span.Start_Column));
                              Y : constant Float := Screen_Y (Context, I - 1);
                              W : constant Float :=
                                Float
                                  (Editor.Layout.Text_Cell_Width
                                     (Span.End_Column - Span.Start_Column));
                              H : constant Float := Float (Cell_H);
                           begin
                              if In_Viewport (Context, X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Selection_Layer,
                                    X, Y, W, H,
                                    Selection_Background_Color.R,
                                    Selection_Background_Color.G,
                                    Selection_Background_Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Selection rectangles over visible visual segments only.
      if Snap.Rectangular_Selection_Count = 0
        and then Snap.Selection_Count > 0
        and then Snap.Line_Starts.Length > 0 then
         for SIdx in 1 .. Snap.Selection_Count loop
            declare
               Sel_Min : constant Natural := Natural (Snap.Sel_Start (SIdx));
               Sel_Max : constant Natural := Natural (Snap.Sel_End (SIdx));
            begin
               if Sel_Min /= Sel_Max then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                        Row_Start : constant Natural := Index_For_Row_Start (Context, Seg.Logical_Row);
                        Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                        Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                        Hit_Start : constant Natural := Natural'Max (Sel_Min, Seg_Start);
                        Hit_End   : constant Natural := Natural'Min (Sel_Max, Seg_End);
                     begin
                        if Hit_Start < Hit_End then
                           declare
                              Start_Col : constant Natural := Hit_Start - Row_Start;
                              End_Col   : constant Natural := Hit_End - Row_Start;
                              X : constant Float := Screen_X (Context, Screen_Col_For (Context, Seg, Start_Col));
                              Y : constant Float := Screen_Y (Context, I - 1);
                              W : constant Float := Float (Editor.Layout.Text_Cell_Width (End_Col - Start_Col));
                              H : constant Float := Float (Cell_H);
                           begin
                              if In_Viewport (Context, X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Selection_Layer,
                                    X, Y, W, H,
                                    Selection_Background_Color.R,
                                    Selection_Background_Color.G,
                                    Selection_Background_Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Diagnostic underline rectangles over visible visual segments only.
      if Settings.Show_Diagnostics
        and then Snap.Diagnostic_Count > 0
        and then Snap.Line_Starts.Length > 0 then
         for DIdx in 1 .. Snap.Diagnostic_Count loop
            declare
               D     : constant Editor.Diagnostics.Diagnostic_Range :=
                 Snap.Diagnostics (DIdx);
               Color : constant Editor.Theme.Color_RGB :=
                 Editor.Theme.Diagnostic_Color (D.Severity);
            begin
               if D.Start_Index < D.End_Index then
                  for I in 1 .. Snap.Visible_Visual_Count loop
                     declare
                        Seg       : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                        Row_Start : constant Natural := Index_For_Row_Start (Context, Seg.Logical_Row);
                        Seg_Start : constant Natural := Row_Start + Seg.Start_Col;
                        Seg_End   : constant Natural := Row_Start + Seg.End_Col;
                        Hit_Start : constant Natural :=
                          Natural'Max (Natural (D.Start_Index), Seg_Start);
                        Hit_End   : constant Natural :=
                          Natural'Min (Natural (D.End_Index), Seg_End);
                     begin
                        if Hit_Start < Hit_End then
                           declare
                              Start_Col : constant Natural := Hit_Start - Row_Start;
                              End_Col   : constant Natural := Hit_End - Row_Start;
                              X : constant Float := Screen_X (Context, Screen_Col_For (Context, Seg, Start_Col));
                              H : constant Float :=
                                Editor.Theme.Diagnostic_Underline_Height;
                              Y : constant Float :=
                                Screen_Y (Context, I - 1) + Float (Cell_H)
                                - Editor.Theme.Diagnostic_Underline_Bottom_Padding;
                              W : constant Float :=
                                Float (Editor.Layout.Text_Cell_Width (End_Col - Start_Col));
                           begin
                              if In_Viewport (Context, X, Y, W, H) then
                                 Push_Rect
                                   (Out_Packet, Diagnostic_Layer,
                                    X, Y, W, H,
                                    Color.R, Color.G, Color.B);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end if;
            end;
         end loop;
      end if;

      -- Carets.
      if Editor.View.Caret_Visible then
         for CIdx in 1 .. Snap.Caret_Count loop
            declare
               Caret_Row : Natural := 0;
               Caret_Col : Natural := 0;
               Segment_Index : Natural := 0;
            begin
               Row_Col_For_Index (Context, Natural (Snap.Caret_Pos (CIdx)), Caret_Row, Caret_Col);
               if Snap.Caret_Virtual_Column (CIdx) > 0 then
                  Caret_Col := Snap.Caret_Virtual_Column (CIdx);
               end if;
               Segment_Index := Segment_For_Caret (Context, Caret_Row, Caret_Col);
               if Segment_Index > 0 then
                  declare
                     Seg : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (Segment_Index);
                     Visual_Col : constant Natural := Screen_Col_For (Context, Seg, Caret_Col);
                     Cell_X : constant Float := Screen_X (Context, Visual_Col);
                     Cell_Y : constant Float := Screen_Y (Context, Segment_Index - 1);
                     Cursor_X : Float := Cell_X;
                     Cursor_Y : Float := Cell_Y;
                     Cursor_W : Float := 1.0;
                     Cursor_H : Float := Float (Cell_H);
                  begin
                     case Cursor_Config.Style is
                        when Editor.Cursor.Bar_Cursor =>
                           Cursor_W := Float (Cursor_Config.Bar_Width);
                           Cursor_H := Float (Cell_H);
                        when Editor.Cursor.Block_Cursor =>
                           Cursor_W := Float (Cell_W);
                           Cursor_H := Float (Cell_H);
                        when Editor.Cursor.Underline_Cursor =>
                           Cursor_W := Float (Cell_W);
                           Cursor_H := Float (Cursor_Config.Underline_H);
                           Cursor_Y :=
                             Cell_Y + Float (Cell_H)
                             - Float (Cursor_Config.Underline_H);
                     end case;

                     if In_Viewport (Context, Cursor_X, Cursor_Y, Cursor_W, Cursor_H) then
                        Push_Rect
                          (Out_Packet, Caret_Layer,
                           Cursor_X, Cursor_Y, Cursor_W, Cursor_H,
                           Cursor_Color.R, Cursor_Color.G, Cursor_Color.B);
                     end if;
                  end;
               end if;
            end;
         end loop;
      end if;

      -- Glyphs.
      if Snap.Line_Starts.Length > 0 and then Snap.Visible_Visual_Count > 0 then
         declare
            Current_Row : Natural := 0;
            Current_Col : Natural := 0;
         begin
            if Snap.Caret_Count > 0 then
               Row_Col_For_Index (Context, Natural (Snap.Caret_Pos (1)), Current_Row, Current_Col);
            end if;

            declare
               Cache_Current_Row : constant Natural :=
                 (if Line_Number_Config.Mode = Editor.Line_Numbers.Absolute_Line_Numbers
                  then 0
                  else Current_Row);
            begin
               for I in 1 .. Snap.Visible_Visual_Count loop
                  declare
                     Seg        : constant Editor.Wrap.Visual_Row_Info := Snap.Visible_Visual_Rows (I);
                     Screen_Row : constant Natural := I - 1;
                     Row_Start  : constant Natural := Index_For_Row_Start (Context, Seg.Logical_Row);
                     Row_End    : constant Natural := Row_End_Index (Context, Seg.Logical_Row);
                     Emit_Start : constant Natural := Row_Start + Seg.Start_Col;
                     Emit_Stop  : constant Natural := Natural'Min (Row_Start + Seg.End_Col, Row_End);
                     First_Row_Glyph : Natural := 0;
                  begin
                  if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                    or else Seg.Start_Col = 0
                  then
                     Editor.Gutter.Surface_Rendering.Push_Gutter_Marker
                       (Out_Packet, Snap, Layout,
                        Editor.View.Viewport_Width,
                        Effective_Viewport_H,
                        Cell_W, Cell_H, Line_Count (Context),
                        Seg.Logical_Row, Screen_Row);
                     Editor.Gutter.Surface_Rendering.Push_Fold_Marker
                       (Out_Packet, Snap, Layout,
                        Editor.View.Viewport_Width,
                        Effective_Viewport_H,
                        Cell_W, Cell_H, Line_Count (Context),
                        Seg.Logical_Row, Screen_Row);
                  end if;

                  if not Selection_Affects_Text_Color (Context)
                    and then Editor.Render_Cache.Row_Is_Valid
                    (Row        => Seg.Logical_Row,
                     Screen_Row => Screen_Row,
                     Row_Start  => Emit_Start,
                     Row_End    => Emit_Stop,
                     Line_Count => Line_Count (Context),
                     Scroll_X   => Scroll_X,
                     Viewport_W => Effective_Viewport_W,
                     Viewport_H => Effective_Viewport_H,
                     Wrap_Mode  => Snap.Wrap_Mode,
                     Wrap_Col   => Snap.Wrap_Col,
                     Is_Current => Seg.Logical_Row = Current_Row,
                     Line_Number_Mode => Line_Number_Config.Mode,
                     Line_Number_Current_Row => Cache_Current_Row)
                  then
                     Editor.Render_Cache.Emit_Row
                       (Row        => Seg.Logical_Row,
                        Screen_Row => Screen_Row,
                        Row_Start  => Emit_Start,
                        Row_End    => Emit_Stop,
                        Wrap_Mode  => Snap.Wrap_Mode,
                        Wrap_Col   => Snap.Wrap_Col,
                        Packet     => Out_Packet);
                  else
                     First_Row_Glyph := Natural (Out_Packet.Glyph_Count);

                     if Settings.Show_Line_Numbers
                       and then (Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                                 or else Seg.Start_Col = 0)
                     then
                        Editor.Gutter.Surface_Rendering.Push_Gutter_Line_Number
                          (Out_Packet,
                           Layout,
                           Editor.View.Viewport_Width,
                           Effective_Viewport_H,
                           Cell_W,
                           Cell_H,
                           Line_Count (Context),
                           Seg.Logical_Row,
                           Screen_Row,
                           Current_Row,
                           Settings.Highlight_Current_Gutter
                           and then Seg.Logical_Row = Current_Row,
                           Line_Number_Config);
                     end if;

                     if Emit_Start < Emit_Stop then
                        declare
                           Line_Text : String (1 .. Row_End - Row_Start);
                           type Code_Array is array (Natural range <>) of Editor.Unicode.Code_Point;
                           Segment_Codes : Code_Array (0 .. Emit_Stop - Emit_Start - 1) :=
                             (others => Wide_Wide_Character'Val (0));
                           Line_Fill_Pos : Natural := Line_Text'First;

                           procedure Fill_Line
                             (Index : Natural;
                              Code  : Editor.Unicode.Code_Point)
                           is
                              pragma Unreferenced (Index);
                              V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
                           begin
                              if V <= 255 then
                                 Line_Text (Line_Fill_Pos) := Character'Val (V);
                              else
                                 Line_Text (Line_Fill_Pos) := '?';
                              end if;
                              Line_Fill_Pos := Line_Fill_Pos + 1;
                           end Fill_Line;

                           procedure Fill_Segment_Code
                             (Index : Natural;
                              Code  : Editor.Unicode.Code_Point)
                           is
                           begin
                              Segment_Codes (Index - Emit_Start) := Code;
                           end Fill_Segment_Code;
                        begin
                           --  Classify the full logical row, not only the visible
                           --  slice.  This preserves line-local token context when
                           --  horizontal scrolling or wrapping starts inside a
                           --  comment/string/identifier token.
                           Editor.Input_Bridge.For_Each_Text_Code_Point_Range
                             (Row_Start, Row_End, Fill_Line'Access);
                           Editor.Input_Bridge.For_Each_Text_Code_Point_Range
                             (Emit_Start, Emit_Stop, Fill_Segment_Code'Access);

                           declare
                              procedure Emit_Token
                                (Token_Start : Natural;
                                 Token_Stop  : Natural;
                                 Kind        : Editor.Syntax.Syntax_Kind)
                              is
                                 Token_Color : constant Editor.Theme.Color_RGB :=
                                   (if Settings.Use_Syntax_Colouring
                                      or else Kind in Editor.Syntax.Diagnostic_Error
                                                    | Editor.Syntax.Diagnostic_Warning
                                                    | Editor.Syntax.Search_Match
                                                    | Editor.Syntax.Selection_Overlay
                                    then Editor.Theme.Syntax_Color (Kind)
                                    else Editor.Theme.Text_Default);
                              begin
                                 for Abs_Index in Token_Start .. Token_Stop - 1 loop
                                    declare
                                       Ch : constant Character :=
                                         Line_Text
                                           (Line_Text'First + Abs_Index - Row_Start);
                                       Code : constant Editor.Unicode.Code_Point :=
                                         Segment_Codes (Abs_Index - Emit_Start);
                                       Logical_Col : constant Natural :=
                                         Abs_Index - Row_Start;
                                       Glyph_Col : constant Natural := Screen_Col_For (Context, Seg, Abs_Index - Row_Start);
                                       Color : constant Editor.Theme.Color_RGB :=
                                         (if Text_Cell_Is_Selected
                                               (Context, Abs_Index, Seg.Logical_Row, Logical_Col)
                                          then Selection_Text_Color
                                          else Token_Color);
                                       M : Editor.Fonts.Glyph_Metric;
                                    begin
                                       if Ch /= ASCII.CR
                                         and then Ch /= ASCII.LF
                                         and then Ch /= ASCII.NUL
                                       then
                                          if Editor.Fonts.Get_Glyph (Code, M) then
                                             Editor.Fonts.Check_Glyph_Fits_Cell
                                               (M, Cell_W, Cell_H);
                                             if M.W > 0.0 and then M.H > 0.0 then
                                                declare
                                                   GX : constant Float := Glyph_X (Context, Glyph_Col, M);
                                                   GY : constant Float := Float'Floor (Glyph_Y (Context, Screen_Row, M) + 0.5);
                                                   GW : constant Float := M.W;
                                                   GH : constant Float := M.H;
                                                begin
                                                   if In_Viewport (Context, GX, GY, GW, GH) then
                                                      Push_Glyph
                                                        (Out_Packet, Text_Layer,
                                                         GX, GY, GW, GH,
                                                         Float (M.U0),
                                                         Float (M.V0),
                                                         Float (M.U1),
                                                         Float (M.V1),
                                                         Color.R, Color.G, Color.B);
                                                   end if;
                                                end;
                                             end if;
                                          end if;
                                       end if;
                                    end;
                                 end loop;
                              end Emit_Token;

                              Cursor : Natural := Emit_Start;
                           begin
                              for I in 1 .. Snap.Syntax_Span_Count loop
                                 declare
                                    Span : constant Editor.Render_Model.Render_Syntax_Span :=
                                      Snap.Syntax_Spans (I);
                                    Token_Start : constant Natural :=
                                      Natural'Max (Span.Start_Index, Emit_Start);
                                    Token_Stop : constant Natural :=
                                      Natural'Min (Span.End_Index, Emit_Stop);
                                 begin
                                    if Span.Row = Seg.Logical_Row and then Token_Stop > Token_Start then
                                       if Cursor < Token_Start then
                                          Emit_Token (Cursor, Token_Start, Editor.Syntax.Plain_Text);
                                       end if;
                                       Emit_Token (Token_Start, Token_Stop, Span.Kind);
                                       Cursor := Token_Stop;
                                    end if;
                                 end;
                              end loop;

                              if Cursor < Emit_Stop then
                                 Emit_Token (Cursor, Emit_Stop, Editor.Syntax.Plain_Text);
                              end if;
                           end;
                        end;
                     end if;

                     if Snap.Wrap_Mode = Editor.Wrap.Wrap_None
                       or else Seg.Start_Col = 0
                     then
                        Editor.Gutter.Surface_Rendering.Push_Folded_Ellipsis
                          (Out_Packet,
                           Snap,
                           Layout,
                           Editor.View.Viewport_Width,
                           Effective_Viewport_H,
                           Text_Viewport_Right (Context),
                           Cell_W,
                           Cell_H,
                           Line_Count (Context),
                           Seg.Logical_Row,
                           Screen_Row,
                           Seg.End_Col + 1);
                     end if;

                     if not Selection_Affects_Text_Color (Context) then
                        Editor.Render_Cache.Store_Row
                          (Row         => Seg.Logical_Row,
                           Screen_Row  => Screen_Row,
                           Row_Start   => Emit_Start,
                           Row_End     => Emit_Stop,
                           Line_Count  => Line_Count (Context),
                           Scroll_X    => Scroll_X,
                           Viewport_W  => Effective_Viewport_W,
                           Viewport_H  => Effective_Viewport_H,
                           Wrap_Mode   => Snap.Wrap_Mode,
                           Wrap_Col    => Snap.Wrap_Col,
                           Is_Current  => Seg.Logical_Row = Current_Row,
                           Line_Number_Mode => Line_Number_Config.Mode,
                           Line_Number_Current_Row => Cache_Current_Row,
                           Packet      => Out_Packet,
                           First_Glyph => First_Row_Glyph,
                           Glyph_Count => Natural (Out_Packet.Glyph_Count) - First_Row_Glyph);
                     end if;
                  end if;
                  end;
               end loop;
            end;
         end;
      end if;

      -- Minimap overview.  This pass uses only precomputed O(viewport-height)
      -- samples from the render snapshot; it does not scan the document here
      -- and it does not interact with the normal row glyph cache.
      if Effective_Minimap_Enabled
        and then Editor.View.Viewport_Width > 0
        and then Text_Viewport_Height (Context) > 0
      then
         declare
            Left   : constant Float :=
              Editor.Minimap.Left_X
                (Layout, Effective_Viewport_W, Minimap);
            Right  : constant Float :=
              Editor.Minimap.Right_X
                (Layout, Effective_Viewport_W, Minimap);
            Top    : constant Float := Float (Editor.Layout.Text_Viewport_Y (Layout));
            Height : constant Float := Float (Text_Viewport_Height (Context));
            Inner_Pad : constant Float :=
              Editor.Theme.Minimap_Content_Padding;
            Content_Left : constant Float := Left + Inner_Pad;
            Content_W    : constant Float :=
              Float'Max (1.0, Right - Left - 2.0 * Inner_Pad);
            Max_Line_For_Scale : constant Natural :=
              Editor.Theme.Minimap_Max_Line_Length_For_Scale;
            Visible_Rows : constant Natural :=
              (if Snap.Visible_Last_Row >= Snap.Visible_First_Row
               then Snap.Visible_Last_Row - Snap.Visible_First_Row + 1
               else 1);
         begin
            if Right > Left then
               Push_Rect
                 (Out_Packet, Minimap_Background_Layer,
               Left, Top, Right - Left, Height,
               Minimap_Background_Color.R,
               Minimap_Background_Color.G,
               Minimap_Background_Color.B);

            if Snap.Minimap_Sample_Count > 0 then
               for I in 0 .. Snap.Minimap_Sample_Count - 1 loop
                  declare
                  Info : constant Editor.Minimap.Minimap_Line_Info :=
                    Snap.Minimap_Samples (I);
                  Scale_Len : constant Natural :=
                    Natural'Min (Info.Text_Length, Max_Line_For_Scale);
                  Line_W : constant Float :=
                    Float'Max
                      (Editor.Theme.Minimap_Min_Line_Width,
                       Float (Scale_Len) * Content_W
                         / Float (Max_Line_For_Scale));
                  Y : constant Float := Top + Info.Start_Y;
               begin
                  if Info.Has_Text then
                     Push_Rect
                       (Out_Packet, Minimap_Content_Layer,
                        Content_Left, Y,
                        Float'Min (Content_W, Line_W),
                        Editor.Theme.Minimap_Content_Line_Height,
                        Minimap_Text_Density_Color.R,
                        Minimap_Text_Density_Color.G,
                        Minimap_Text_Density_Color.B);
                  end if;

                     end;
               end loop;
            end if;

            declare
               Marker_Y : constant Float :=
                 Top + Editor.Minimap.Viewport_Marker_Y
                   (Snap.Visible_First_Row,
                    Line_Count (Context),
                    Text_Viewport_Height (Context));
               Raw_Marker_H : constant Float :=
                 Editor.Minimap.Viewport_Marker_Height
                   (Visible_Rows,
                    Line_Count (Context),
                    Text_Viewport_Height (Context));
               Marker_H : constant Float :=
                 (if Marker_Y >= Top + Height then 0.0
                  else Float'Min (Raw_Marker_H, Top + Height - Marker_Y));
            begin
               if Marker_H > 0.0 then
                  Push_Rect
                    (Out_Packet, Minimap_Viewport_Layer,
                     Left, Marker_Y, Right - Left, Marker_H,
                     Minimap_Viewport_Color.R,
                     Minimap_Viewport_Color.G,
                     Minimap_Viewport_Color.B);
               end if;
            end;
            end if;
         end;
      end if;


      -- Scrollbars are drawn above editor/minimap content but below palette.
      if Scrollbars.Enabled
        and then Editor.View.Viewport_Width > 0
        and then Editor.View.Viewport_Height > 0
      then
         declare
            Visible_Rows : constant Natural :=
              Editor.Layout.Visible_Row_Count (Layout, Effective_Viewport_H);
            Vertical : constant Editor.Scrollbars.Scrollbar_Geometry :=
              Editor.Scrollbars.Vertical_Geometry
                (Layout          => Layout,
                 Viewport_Width  => Editor.View.Viewport_Width,
                 Viewport_Height => Scrollbar_Viewport_Height (Context),
                 Total_Rows      => Snap.Visible_Line_Count,
                 Visible_Rows    => Visible_Rows,
                 Scroll_Y        => Editor.View.Scroll_Y,
                 Config          => Scrollbars);
         begin
            if Vertical.Visible then
               Push_Rect
                 (Out_Packet, Scrollbar_Track_Layer,
                  Vertical.Track.X, Vertical.Track.Y,
                  Vertical.Track.W, Vertical.Track.H,
                  Scrollbar_Track_Color.R,
                  Scrollbar_Track_Color.G,
                  Scrollbar_Track_Color.B);
               Push_Rect
                 (Out_Packet, Scrollbar_Thumb_Layer,
                  Vertical.Thumb.X, Vertical.Thumb.Y,
                  Vertical.Thumb.W, Vertical.Thumb.H,
                  Scrollbar_Thumb_Color.R,
                  Scrollbar_Thumb_Color.G,
                  Scrollbar_Thumb_Color.B);
            end if;
         end;

         declare
            Text_Left : constant Natural :=
              Editor.Layout.Text_Origin_X (Layout, Line_Count (Context));
            Text_W : constant Natural := Text_Viewport_Width (Context);
            Visible_Cols : constant Natural :=
              Text_W / Editor.Layout.Cell_W;
            Total_Cols : Natural := 0;
            Horizontal : Editor.Scrollbars.Scrollbar_Geometry;
         begin
            for I in 1 .. Snap.Visible_Visual_Count loop
               declare
                  Seg : constant Editor.Wrap.Visual_Row_Info :=
                    Snap.Visible_Visual_Rows (I);
               begin
                  if not Editor.Folding.Is_Row_Hidden
                           (Snap.Folding, Seg.Logical_Row)
                    and then Seg.End_Col >= Seg.Start_Col
                  then
                     Total_Cols := Natural'Max (Total_Cols, Seg.End_Col);
                  end if;
               end;
            end loop;

            Horizontal :=
              Editor.Scrollbars.Horizontal_Geometry
                (Layout          => Layout,
                 Text_Left       => Text_Left,
                 Text_Width      => Text_W,
                 Viewport_Height => Scrollbar_Viewport_Height (Context),
                 Total_Cols      => Total_Cols,
                 Visible_Cols    => Visible_Cols,
                 Scroll_X        => Editor.View.Scroll_X,
                 Config          => Scrollbars);

            if Horizontal.Visible then
               Push_Rect
                 (Out_Packet, Scrollbar_Track_Layer,
                  Horizontal.Track.X, Horizontal.Track.Y,
                  Horizontal.Track.W, Horizontal.Track.H,
                  Scrollbar_Track_Color.R,
                  Scrollbar_Track_Color.G,
                  Scrollbar_Track_Color.B);
               Push_Rect
                 (Out_Packet, Scrollbar_Thumb_Layer,
                  Horizontal.Thumb.X, Horizontal.Thumb.Y,
                  Horizontal.Thumb.W, Horizontal.Thumb.H,
                  Scrollbar_Thumb_Color.R,
                  Scrollbar_Thumb_Color.G,
                  Scrollbar_Thumb_Color.B);
            end if;
         end;
      end if;

   end Render;

end Editor.Render_Packet.Editor_Text_Surface;
