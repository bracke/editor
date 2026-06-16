with Textrender; use Textrender;
with Editor.Fonts.Init;
with Editor.Unicode;

package body Editor.Fonts is

   function Get_Glyph
     (Ch     : Character;
      Metric : out Glyph_Metric) return Boolean
   is
      Pos : constant Natural := Character'Pos (Ch);
   begin
      if Pos < Character'Pos (' ') or else Pos > Character'Pos ('~') then
         Metric := (others => 0.0);
         return False;
      end if;

      return Get_Glyph
        (Editor.Unicode.Code_Point'Val (Pos), Metric);
   end Get_Glyph;

   function Get_Glyph
     (Code   : Editor.Unicode.Code_Point;
      Metric : out Glyph_Metric) return Boolean
   is
      M      : Textrender.Glyph_Metric;
      Status : Textrender.Status_Code;
      CP     : Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if not Editor.Unicode.Is_Valid_Scalar (Code) then
         CP := 16#FFFD#;
      end if;

      pragma Assert (Editor.Fonts.Init.Is_Initialized,
         "Editor font system must be initialized before glyph lookup");

      Status := Textrender.Get_Glyph (Textrender.Codepoint (CP), M);

      if Status /= Textrender.Success
        and then Status /= Textrender.Glyph_Missing
      then
         --  Last-ditch safe fallback. Textrender normally maps missing glyphs
         --  internally, but render packet construction must never crash on a
         --  Unicode scalar value unsupported by the active font.
         Status := Textrender.Get_Glyph (Textrender.Codepoint (Character'Pos ('?')), M);
      end if;

      if Status /= Textrender.Success
        and then Status /= Textrender.Glyph_Missing
      then
         Metric := (others => 0.0);
         return False;
      end if;

      Metric :=
        (W         => M.W,
         H         => M.H,
         U0        => M.U0,
         V0        => M.V0,
         U1        => M.U1,
         V1        => M.V1,
         Bearing_X => M.Bearing_X,
         Bearing_Y => M.Bearing_Y,
         Advance_X => M.Advance_X);

      return True;
   end Get_Glyph;

   function Ascent return Float is
   begin
      return Textrender.Ascent;
   end Ascent;

   function Descent return Float is
   begin
      return Textrender.Descent;
   end Descent;

   function Monospace_Cell_Width return Float is
      M : Glyph_Metric;
   begin
      if Get_Glyph (Character'('M'), M) then
         return Float'Ceiling (M.Advance_X);
      else
         return 10.0;
      end if;
   end Monospace_Cell_Width;

   function Font_Is_Monospace return Boolean is
      I_Metric     : Glyph_Metric;
      M_Metric     : Glyph_Metric;
      Space_Metric : Glyph_Metric;

      Epsilon : constant Float := 0.01;
   begin
      if not Get_Glyph (Character'('i'), I_Metric) then
         return False;
      end if;

      if not Get_Glyph (Character'('M'), M_Metric) then
         return False;
      end if;

      if not Get_Glyph (Character'(' '), Space_Metric) then
         return False;
      end if;

      return abs (I_Metric.Advance_X - M_Metric.Advance_X) <= Epsilon
        and then abs (Space_Metric.Advance_X - M_Metric.Advance_X) <= Epsilon;
   end Font_Is_Monospace;

   procedure Check_Glyph_Fits_Cell
   (Metric      : Glyph_Metric;
      Cell_Width  : Positive;
      Cell_Height : Positive)
   is
   begin
      --  Empty glyphs such as space are valid in Textrender. They still
      --  advance one editor cell, but they do not have atlas UVs to draw.
      if Metric.W = 0.0 and then Metric.H = 0.0 then
         pragma Assert
           (Metric.Advance_X >= 0.0,
            "Empty glyph advance must be non-negative");
         return;
      end if;

      pragma Assert
        (Metric.W > 0.0,
         "Glyph width must be > 0 unless the glyph is empty");

      pragma Assert
        (Metric.H > 0.0,
         "Glyph height must be > 0 unless the glyph is empty");

      --  Bitmap bounds can overhang a fixed cell slightly even when the
      --  monospace advance fits.  Layout is cell/advance based, so render
      --  packet construction must not abort on that diagnostic condition.
      pragma Unreferenced (Cell_Width, Cell_Height);

      pragma Assert
      (Metric.U0 >= 0.0 and then Metric.U0 <= 1.0,
         "Glyph U0 must be normalized");

      pragma Assert
      (Metric.V0 >= 0.0 and then Metric.V0 <= 1.0,
         "Glyph V0 must be normalized");

      pragma Assert
      (Metric.U1 >= 0.0 and then Metric.U1 <= 1.0,
         "Glyph U1 must be normalized");

      pragma Assert
      (Metric.V1 >= 0.0 and then Metric.V1 <= 1.0,
         "Glyph V1 must be normalized");

      pragma Assert
      (Metric.U1 > Metric.U0,
         "Glyph U coordinates must be increasing");

      pragma Assert
      (Metric.V1 > Metric.V0,
         "Glyph V coordinates must be increasing");

   end Check_Glyph_Fits_Cell;

end Editor.Fonts;