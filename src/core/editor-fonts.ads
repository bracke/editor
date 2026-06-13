with Interfaces.C;
with Editor.Unicode;

package Editor.Fonts is

   --  Font contract:
   --
   --  The editor uses a fixed grid with a monospace font.
   --  Font metrics are used only to position glyph bitmaps inside cells
   --  and to validate that the configured cell width fits the font.
   --
   --  Logical layout remains cell-based:
   --     one character = one cell
   --     one caret column = one cell
   --
   --  Glyph Advance_X must not drive cursor movement or column layout.
   --
   --  Current glyph coverage is printable ASCII: 32 .. 126.
   --

   type Glyph_Metric is record
      W : Float := 0.0;
      H : Float := 0.0;

      U0 : Float := 0.0;
      V0 : Float := 0.0;
      U1 : Float := 0.0;
      V1 : Float := 0.0;

      Bearing_X : Float := 0.0;
      Bearing_Y : Float := 0.0;

      --  Diagnostic / cell sizing only.
      --  Layout remains grid-based; glyph advance never drives cursor movement.
      Advance_X : Float := 0.0;
   end record;

   function Ascent return Float;
   function Descent return Float;

   function Get_Glyph
     (Ch     : Character;
      Metric : out Glyph_Metric) return Boolean;

   function Get_Glyph
     (Code   : Editor.Unicode.Code_Point;
      Metric : out Glyph_Metric) return Boolean;

   function Monospace_Cell_Width return Float;

   function Font_Is_Monospace return Boolean;

   procedure Check_Glyph_Fits_Cell
     (Metric      : Glyph_Metric;
      Cell_Width  : Positive;
      Cell_Height : Positive);

end Editor.Fonts;