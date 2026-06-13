package Editor.Wrap is

   --  Soft-wrap mode used by view, render-model, navigation, and cache code.
   type Wrap_Mode is
     (Wrap_None,
      Wrap_At_Viewport);

   --  A visible visual row segment of one logical row.
   --
   --  Logical_Row is the zero-based logical document row.
   --  Start_Col is the inclusive logical column where this visual row begins.
   --  End_Col is the exclusive logical column where this visual row ends.
   type Visual_Row_Info is record
      Logical_Row : Natural := 0;
      Start_Col   : Natural := 0;
      End_Col     : Natural := 0;
   end record;

   --  Return the fixed-grid wrap column count for the text viewport.
   --
   --  @param Viewport_Text_Width width, in pixels, of the text viewport only;
   --         this must exclude the gutter and any left text origin.
   --  @param Cell_W width, in pixels, of one monospaced grid cell.
   --  @return at least one text cell, even for empty or very narrow viewports.
   function Wrap_Column
     (Viewport_Text_Width : Natural;
      Cell_W              : Positive) return Positive;

   --  Return the number of visual rows required for one logical line.
   --
   --  @param Line_Length logical line length in editor text units.
   --  @param Wrap_Col fixed wrap column count in text cells.
   --  @return at least one visual row; exact multiples do not produce an
   --          additional empty visual row.
   function Visual_Row_Count_For_Logical_Line
     (Line_Length : Natural;
      Wrap_Col    : Positive) return Positive;

   --  Return the visual part within a logical row that contains a column.
   --
   --  @param Logical_Row logical row. It is accepted for call-site clarity;
   --         the calculation is per-line and does not need the row value.
   --  @param Logical_Col logical column inside the row.
   --  @param Wrap_Col fixed wrap column count in text cells.
   --  @return zero-based visual part inside the logical row.
   function Visual_Row_For
     (Logical_Row : Natural;
      Logical_Col : Natural;
      Wrap_Col    : Positive) return Natural;

   --  Return the logical column interval for one wrapped visual segment.
   --
   --  @param Logical_Row zero-based logical document row.
   --  @param Visual_Part zero-based wrapped part inside the logical row.
   --  @param Line_Length logical line length in editor text units.
   --  @param Wrap_Col fixed wrap column count in text cells.
   --  @return visual row information with Start_Col and End_Col clamped to
   --          the logical line length.
   function Visual_Segment
     (Logical_Row : Natural;
      Visual_Part : Natural;
      Line_Length : Natural;
      Wrap_Col    : Positive) return Visual_Row_Info;

end Editor.Wrap;
