with Editor.Fonts;
with Editor.Render_Packet.Render_Context;
with Editor.Wrap;

package Editor.Render_Packet.Geometry is

   subtype Context is Editor.Render_Packet.Render_Context.Context;

   function Line_Count (Value : Context) return Natural;
   function Screen_X (Value : Context; C : Natural) return Float;
   function Screen_Y (Value : Context; Visible_Row : Natural) return Float;
   function Text_Viewport_Right (Value : Context) return Float;
   function Text_Viewport_Width (Value : Context) return Natural;
   function Scrollbar_Viewport_Height (Value : Context) return Natural;
   function Text_Viewport_Height (Value : Context) return Natural;

   function In_Viewport
     (Value : Context;
      X, Y, W, H : Float) return Boolean;
   function In_Gutter_Viewport
     (Value : Context;
      X, Y, W, H : Float) return Boolean;

   function Text_End_Index (Value : Context) return Natural;
   function Has_Row_Start
     (Value : Context;
      Target_Row : Natural) return Boolean;
   function Local_Row_Index
     (Value : Context;
      Target_Row : Natural) return Natural;
   function Index_For_Row_Start
     (Value : Context;
      Target_Row : Natural) return Natural;
   function Row_End_Index
     (Value : Context;
      Target_Row : Natural) return Natural;
   function Row_For_Index
     (Value : Context;
      Index : Natural) return Natural;

   procedure Row_Col_For_Index
     (Value : Context;
      Index : Natural;
      Row   : out Natural;
      Col   : out Natural);

   function Segment_For_Caret
     (Value : Context;
      Row : Natural;
      Col : Natural) return Natural;
   function Screen_Col_For
     (Value       : Context;
      Seg         : Editor.Wrap.Visual_Row_Info;
      Logical_Col : Natural) return Natural;

   function Selection_Affects_Text_Color (Value : Context) return Boolean;
   function Text_Cell_Is_Selected
     (Value        : Context;
      Buffer_Index : Natural;
      Row          : Natural;
      Col          : Natural) return Boolean;

   function Baseline_Y
     (Value : Context;
      Row   : Natural) return Float;
   function Glyph_Y
     (Value : Context;
      Row   : Natural;
      M     : Editor.Fonts.Glyph_Metric) return Float;
   function Glyph_X
     (Value : Context;
      Col   : Natural;
      M     : Editor.Fonts.Glyph_Metric) return Float;

end Editor.Render_Packet.Geometry;
