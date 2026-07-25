with Ada.Containers; use Ada.Containers;
with Editor.Folding;
with Editor.Layout;
with Editor.Render_Model;
with Editor.View;
with Editor.Wrap;

package body Editor.Render_Packet.Geometry is

   use type Editor.Wrap.Wrap_Mode;

   function Line_Count (Value : Context) return Natural is
   begin
      return Natural'Max (1, Value.Snap.Total_Line_Count);
   end Line_Count;

   function Screen_X (Value : Context; C : Natural) return Float is
   begin
      return Editor.View.Visual_Screen_X
        (Value.Layout, Line_Count (Value), C);
   end Screen_X;

   function Screen_Y (Value : Context; Visible_Row : Natural) return Float is
   begin
      return Editor.View.Visual_Screen_Y (Value.Layout, Visible_Row);
   end Screen_Y;

   function Text_Viewport_Right (Value : Context) return Float is
   begin
      if Value.Effective_Minimap_Enabled then
         return Editor.Layout.Text_Viewport_Right
           (Value.Layout,
            Value.Effective_Viewport_W,
            Value.Minimap.Enabled,
            Value.Minimap.Width,
            Value.Minimap.Padding_Left,
            Value.Minimap.Padding_Right);
      else
         return Editor.Layout.Text_Right_X
           (Value.Layout, Value.Effective_Viewport_W);
      end if;
   end Text_Viewport_Right;

   function Text_Viewport_Width (Value : Context) return Natural is
   begin
      if Value.Effective_Minimap_Enabled then
         return Editor.Layout.Text_Viewport_Width
           (Value.Layout,
            Line_Count (Value),
            Value.Effective_Viewport_W,
            Value.Minimap.Enabled,
            Value.Minimap.Width,
            Value.Minimap.Padding_Left,
            Value.Minimap.Padding_Right);
      else
         return Editor.Layout.Text_Viewport_Width
           (Value.Layout, Line_Count (Value), Value.Effective_Viewport_W);
      end if;
   end Text_Viewport_Width;

   function Scrollbar_Viewport_Height (Value : Context) return Natural is
   begin
      return Editor.Layout.Text_Viewport_Height
        (Value.Layout, Editor.View.Viewport_Height);
   end Scrollbar_Viewport_Height;

   function Text_Viewport_Height (Value : Context) return Natural is
   begin
      return Editor.Layout.Text_Viewport_Height
        (Value.Layout, Value.Effective_Viewport_H);
   end Text_Viewport_Height;

   function In_Viewport
     (Value : Context;
      X, Y, W, H : Float) return Boolean
   is
      Left : constant Float :=
        Float (Editor.Layout.Text_Origin_X (Value.Layout, Line_Count (Value)));
      Right : constant Float := Text_Viewport_Right (Value);
      Top : constant Float := Float (Editor.Layout.Text_Viewport_Y (Value.Layout));
      Bottom : constant Float :=
        Editor.Layout.View_Bottom_Y (Value.Layout, Value.Effective_Viewport_H);
   begin
      if Editor.View.Viewport_Width = 0
        or else Editor.View.Viewport_Height = 0
      then
         return True;
      elsif Right <= Left or else Bottom <= Top then
         return False;
      end if;

      return X + W > Left
        and then X < Right
        and then Y + H > Top
        and then Y < Bottom;
   end In_Viewport;

   function In_Gutter_Viewport
     (Value : Context;
      X, Y, W, H : Float) return Boolean
   is
      Left : constant Float := Editor.Layout.Gutter_Left (Value.Layout);
      Right : constant Float :=
        Editor.Layout.Gutter_Right (Value.Layout, Line_Count (Value));
      Top : constant Float := Float (Editor.Layout.Text_Viewport_Y (Value.Layout));
      Bottom : constant Float :=
        Editor.Layout.View_Bottom_Y (Value.Layout, Value.Effective_Viewport_H);
   begin
      if Editor.View.Viewport_Width = 0
        or else Editor.View.Viewport_Height = 0
      then
         return True;
      elsif Right <= Left or else Bottom <= Top then
         return False;
      end if;

      return X + W > Left
        and then X < Right
        and then Y + H > Top
        and then Y < Bottom;
   end In_Gutter_Viewport;

   function Text_End_Index (Value : Context) return Natural is
   begin
      return Value.Snap.Text_Base_Index + Value.Snap.Length;
   end Text_End_Index;

   function Has_Row_Start
     (Value : Context;
      Target_Row : Natural) return Boolean
   is
   begin
      return Value.Snap.Line_Starts.Length > 0
        and then Target_Row >= Value.Snap.Line_Start_Row_Base
        and then Target_Row - Value.Snap.Line_Start_Row_Base <=
          Value.Snap.Line_Starts.Last_Index;
   end Has_Row_Start;

   function Local_Row_Index
     (Value : Context;
      Target_Row : Natural) return Natural
   is
   begin
      return Target_Row - Value.Snap.Line_Start_Row_Base;
   end Local_Row_Index;

   function Index_For_Row_Start
     (Value : Context;
      Target_Row : Natural) return Natural
   is
   begin
      if Has_Row_Start (Value, Target_Row) then
         return Value.Snap.Line_Starts.Element
           (Local_Row_Index (Value, Target_Row));
      else
         return Text_End_Index (Value);
      end if;
   end Index_For_Row_Start;

   function Row_End_Index
     (Value : Context;
      Target_Row : Natural) return Natural
   is
      Row_Start : constant Natural := Index_For_Row_Start (Value, Target_Row);
      Row_End   : Natural := Text_End_Index (Value);
   begin
      if Has_Row_Start (Value, Target_Row + 1) then
         declare
            Next_Start : constant Natural :=
              Index_For_Row_Start (Value, Target_Row + 1);
         begin
            if Next_Start > Row_Start then
               Row_End := Next_Start - 1;
            else
               Row_End := Row_Start;
            end if;
         end;
      end if;
      return Natural'Min (Row_End, Text_End_Index (Value));
   end Row_End_Index;

   function Row_For_Index
     (Value : Context;
      Index : Natural) return Natural
   is
      Lo  : Natural := 0;
      Hi  : Natural := 0;
      Mid : Natural := 0;
   begin
      if Value.Snap.Line_Starts.Length = 0 then
         return 0;
      end if;
      if Index < Value.Snap.Line_Starts.Element (0) then
         return 0;
      end if;
      Hi := Value.Snap.Line_Starts.Last_Index;
      while Lo <= Hi loop
         Mid := (Lo + Hi) / 2;
         if Value.Snap.Line_Starts.Element (Mid) <= Index then
            if Mid = Value.Snap.Line_Starts.Last_Index
              or else Value.Snap.Line_Starts.Element (Mid + 1) > Index
            then
               return Value.Snap.Line_Start_Row_Base + Mid;
            end if;
            Lo := Mid + 1;
         else
            exit when Mid = 0;
            Hi := Mid - 1;
         end if;
      end loop;
      return 0;
   end Row_For_Index;

   procedure Row_Col_For_Index
     (Value : Context;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural)
   is
      Start : Natural := 0;
   begin
      Row := Row_For_Index (Value, Index);
      if Editor.Folding.Is_Row_Hidden (Value.Snap.Folding, Row) then
         declare
            Found : Boolean := False;
         begin
            Row := Editor.Folding.Fold_Start_For_Hidden_Row
              (Value.Snap.Folding, Row, Found);
            Col := 0;
            return;
         end;
      end if;
      if Value.Snap.Line_Starts.Length = 0 then
         Col := Index;
         return;
      end if;
      Start := Index_For_Row_Start (Value, Row);
      if Index >= Start then
         Col := Index - Start;
      else
         Col := 0;
      end if;
   end Row_Col_For_Index;

   function Segment_Contains_Caret
     (Value : Context;
      Seg   : Editor.Wrap.Visual_Row_Info;
      Col   : Natural) return Boolean
   is
   begin
      if Value.Snap.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         return Col >= Seg.Start_Col
           and then Col <= Seg.End_Col
           and then
             (Col < Seg.End_Col
              or else Seg.End_Col =
                Row_End_Index (Value, Seg.Logical_Row)
                - Index_For_Row_Start (Value, Seg.Logical_Row));
      else
         return True;
      end if;
   end Segment_Contains_Caret;

   function Segment_For_Caret
     (Value : Context;
      Row : Natural;
      Col : Natural) return Natural
   is
   begin
      for I in 1 .. Value.Snap.Visible_Visual_Count loop
         declare
            Seg : constant Editor.Wrap.Visual_Row_Info :=
              Value.Snap.Visible_Visual_Rows (I);
         begin
            if Seg.Logical_Row = Row then
               if Value.Snap.Wrap_Mode = Editor.Wrap.Wrap_None then
                  return I;
               elsif Segment_Contains_Caret (Value, Seg, Col) then
                  return I;
               end if;
            end if;
         end;
      end loop;
      return 0;
   end Segment_For_Caret;

   function Screen_Col_For
     (Value       : Context;
      Seg         : Editor.Wrap.Visual_Row_Info;
      Logical_Col : Natural) return Natural
   is
   begin
      if Value.Snap.Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         if Logical_Col >= Seg.Start_Col then
            return Logical_Col - Seg.Start_Col;
         else
            return 0;
         end if;
      else
         return Logical_Col;
      end if;
   end Screen_Col_For;

   function Selection_Affects_Text_Color (Value : Context) return Boolean is
   begin
      return Value.Snap.Selection_Count > 0
        or else Value.Snap.Rectangular_Selection_Count > 0;
   end Selection_Affects_Text_Color;

   function Text_Cell_Is_Selected
     (Value        : Context;
      Buffer_Index : Natural;
      Row          : Natural;
      Col          : Natural) return Boolean
   is
   begin
      for RIdx in 1 .. Value.Snap.Rectangular_Selection_Count loop
         declare
            Span : constant Editor.Render_Model.Rectangular_Selection_Row_Span :=
              Value.Snap.Rectangular_Selections (RIdx);
         begin
            if Span.Row = Row
              and then Col >= Span.Start_Column
              and then Col < Span.End_Column
            then
               return True;
            end if;
         end;
      end loop;

      if Value.Snap.Rectangular_Selection_Count > 0 then
         return False;
      end if;

      for SIdx in 1 .. Value.Snap.Selection_Count loop
         declare
            Sel_Min : constant Natural := Natural (Value.Snap.Sel_Start (SIdx));
            Sel_Max : constant Natural := Natural (Value.Snap.Sel_End (SIdx));
         begin
            if Buffer_Index >= Sel_Min and then Buffer_Index < Sel_Max then
               return True;
            end if;
         end;
      end loop;

      return False;
   end Text_Cell_Is_Selected;

   function Baseline_Y
     (Value : Context;
      Row   : Natural) return Float
   is
      Text_Height : constant Float := Editor.Fonts.Ascent - Editor.Fonts.Descent;
      Extra : constant Float := Float (Value.Cell_H) - Text_Height;
   begin
      return Screen_Y (Value, Row) + Float'Max (0.0, Extra / 2.0) +
        Editor.Fonts.Ascent;
   end Baseline_Y;

   function Glyph_Y
     (Value : Context;
      Row   : Natural;
      M     : Editor.Fonts.Glyph_Metric) return Float
   is
   begin
      return Baseline_Y (Value, Row) - M.Bearing_Y;
   end Glyph_Y;

   function Glyph_X
     (Value : Context;
      Col   : Natural;
      M     : Editor.Fonts.Glyph_Metric) return Float
   is
      Cell_X : constant Float := Screen_X (Value, Col);
      X      : Float := Float'Floor (Cell_X + M.Bearing_X + 0.5);
   begin
      if X < Cell_X then
         return Cell_X;
      elsif X > Cell_X + Float (Value.Cell_W) - M.W then
         return Cell_X + Float (Value.Cell_W) - M.W;
      else
         return X;
      end if;
   end Glyph_X;

end Editor.Render_Packet.Geometry;
