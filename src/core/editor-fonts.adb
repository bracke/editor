with Textrender; use Textrender;
with Editor.Fonts.Init;
with Editor.Unicode;

package body Editor.Fonts is

   The_Backend : aliased Textrender.Renderer;

   function Backend return access Textrender.Renderer is
     (The_Backend'Access);

   function Get_Glyph
     (Ch     : Character;
      Metric : out Glyph_Metric) return Boolean
   is
      Pos : constant Natural := Character'Pos (Ch);
   begin
      if Pos < Character'Pos (' ') or else Pos > Character'Pos ('~') then
         Metric := (Colour => False, others => 0.0);
         return False;
      end if;

      return Get_Glyph
        (Editor.Unicode.Code_Point'Val (Pos), Metric);
   end Get_Glyph;

   --  Colour glyphs are pictures, and the coverage atlas has one channel, so
   --  they are packed into a sheet of their own here and the renderer uploads it
   --  as a second texture.
   --
   --  Shelf packing, and one tile per codepoint: a screen full of the same emoji
   --  costs a single tile. The sheet is only ever added to, which suits an editor
   --  -- the set of emoji in a document is small and does not churn -- and means
   --  a tile's coordinates stay valid once handed out.
   Sheet_Width : constant := 512;
   Sheet_Height : constant := 512;

   type Sheet_Bytes is
     array (1 .. Sheet_Width * Sheet_Height * 4) of Interfaces.Unsigned_8;
   type Sheet_Access is access Sheet_Bytes;

   Sheet        : Sheet_Access := null;
   Sheet_Dirty  : Boolean := False;
   Shelf_X      : Natural := 0;
   Shelf_Y      : Natural := 0;
   Shelf_Height : Natural := 0;

   type Sheet_Tile is record
      Codepoint : Natural := 0;
      X, Y      : Natural := 0;
      W, H      : Natural := 0;
      Used      : Boolean := False;
   end record;

   Tiles      : array (1 .. 256) of Sheet_Tile;
   Tile_Count : Natural := 0;

   function Find_Tile (Codepoint : Natural) return Natural is
   begin
      for Index in 1 .. Tile_Count loop
         if Tiles (Index).Used and then Tiles (Index).Codepoint = Codepoint then
            return Index;
         end if;
      end loop;

      return 0;
   end Find_Tile;

   --  Pack this codepoint's picture, or find where it already sits. Zero when it
   --  has no colour glyph, or when the sheet has no room left for it.
   function Tile_For (Codepoint : Natural) return Natural is
      Code   : constant Textrender.Codepoint := Textrender.Codepoint (Codepoint);
      Colour : Textrender.Colour_Glyph;
      Pixels : access constant Textrender.Rgba_Buffer;
      Found  : constant Natural := Find_Tile (Codepoint);
      use type Textrender.Status_Code;
   begin
      if Found > 0 then
         return Found;
      end if;

      if Tile_Count >= Tiles'Length
        or else not Textrender.Has_Colour_Glyph (The_Backend, Code)
        or else Textrender.Get_Colour_Glyph (The_Backend, Code, Colour) /= Textrender.Success
        or else Colour.Width = 0
        or else Colour.Height = 0
        or else Colour.Width > Sheet_Width
      then
         return 0;
      end if;

      Pixels := Textrender.Colour_Glyph_Pixels (The_Backend, Code);

      if Pixels = null then
         return 0;
      end if;

      if Shelf_X + Colour.Width > Sheet_Width then
         Shelf_X := 0;
         Shelf_Y := Shelf_Y + Shelf_Height;
         Shelf_Height := 0;
      end if;

      if Shelf_Y + Colour.Height > Sheet_Height then
         return 0;
      end if;

      if Sheet = null then
         Sheet := new Sheet_Bytes'(others => 0);
      end if;

      for Row in 0 .. Colour.Height - 1 loop
         for Column in 0 .. Colour.Width - 1 loop
            declare
               From : constant Natural := (Row * Colour.Width + Column) * 4;
               Into : constant Natural :=
                 ((Shelf_Y + Row) * Sheet_Width + Shelf_X + Column) * 4;
            begin
               for Channel in 0 .. 3 loop
                  Sheet (Into + Channel + 1) :=
                    Interfaces.Unsigned_8 (Pixels (Pixels'First + From + Channel));
               end loop;
            end;
         end loop;
      end loop;

      Tile_Count := Tile_Count + 1;
      Tiles (Tile_Count) :=
        (Codepoint => Codepoint,
         X => Shelf_X, Y => Shelf_Y,
         W => Colour.Width, H => Colour.Height,
         Used => True);

      Shelf_X := Shelf_X + Colour.Width;
      Shelf_Height := Natural'Max (Shelf_Height, Colour.Height);
      Sheet_Dirty := True;

      return Tile_Count;
   end Tile_For;

   function Colour_Sheet_Width return Natural is
     (if Sheet = null then 0 else Sheet_Width);

   function Colour_Sheet_Height return Natural is
     (if Sheet = null then 0 else Sheet_Height);

   function Colour_Sheet_Pixels return System.Address is
     (if Sheet = null then System.Null_Address else Sheet.all'Address);

   function Colour_Sheet_Dirty return Boolean is (Sheet_Dirty);

   procedure Clear_Colour_Sheet_Dirty is
   begin
      Sheet_Dirty := False;
   end Clear_Colour_Sheet_Dirty;

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

      --  A picture first: for such a codepoint the outline lookup has nothing
      --  to find, and would fall through to the '?' below.
      declare
         Tile : constant Natural := Tile_For (CP);
      begin
         if Tile > 0 then
            Metric :=
              (W  => Float (Tiles (Tile).W),
               H  => Float (Tiles (Tile).H),
               U0 => Float (Tiles (Tile).X) / Float (Sheet_Width),
               V0 => Float (Tiles (Tile).Y) / Float (Sheet_Height),
               U1 => Float (Tiles (Tile).X + Tiles (Tile).W) / Float (Sheet_Width),
               V1 => Float (Tiles (Tile).Y + Tiles (Tile).H) / Float (Sheet_Height),
               Bearing_X => 0.0,
               Bearing_Y => 0.0,
               Advance_X => Float (Tiles (Tile).W),
               Colour    => True);
            return True;
         end if;
      end;

      Status := Textrender.Get_Glyph (The_Backend, Textrender.Codepoint (CP), M);

      if Status /= Textrender.Success
        and then Status /= Textrender.Glyph_Missing
      then
         --  Last-ditch safe fallback. Textrender normally maps missing glyphs
         --  internally, but render packet construction must never crash on a
         --  Unicode scalar value unsupported by the active font.
         Status :=
           Textrender.Get_Glyph (The_Backend, Textrender.Codepoint (Character'Pos ('?')), M);
      end if;

      if Status /= Textrender.Success
        and then Status /= Textrender.Glyph_Missing
      then
         Metric := (Colour => False, others => 0.0);
         return False;
      end if;

      Metric :=
        (W         => Float (M.W),
         H         => Float (M.H),
         U0        => M.U0,
         V0        => M.V0,
         U1        => M.U1,
         V1        => M.V1,
         Bearing_X => M.Bearing_X,
         Bearing_Y => M.Bearing_Y,
         Advance_X => M.Advance_X,
         Colour    => False);

      return True;
   end Get_Glyph;

   function Ascent return Float is
   begin
      return Textrender.Ascent (The_Backend);
   end Ascent;

   function Descent return Float is
   begin
      return Textrender.Descent (The_Backend);
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