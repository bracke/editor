with Editor.Layout;
with Editor.Line_Numbers;
with Editor.Settings;
with Editor.Wrap;
use type Editor.Line_Numbers.Line_Number_Mode;
use type Editor.Wrap.Wrap_Mode;

package body Editor.Render_Cache is

   use type Editor.Render_Packet.C_Int;

   Max_Cached_Rows       : constant := 128;
   Max_Cached_Row_Glyphs : constant := 2048;

   subtype Cache_Index is Natural range 0 .. Max_Cached_Rows - 1;
   subtype Row_Glyph_Index is Natural range 0 .. Max_Cached_Row_Glyphs - 1;

   type Row_Glyph_Array is
     array (Row_Glyph_Index) of Editor.Render_Packet.Glyph_Command;

   type Row_Entry is record
      Valid       : Boolean := False;
      Row         : Natural := 0;
      Screen_Row  : Natural := 0;
      Row_Start   : Natural := 0;
      Row_End     : Natural := 0;
      Line_Count  : Natural := 0;
      Scroll_X    : Natural := 0;
      Viewport_W  : Natural := 0;
      Viewport_H  : Natural := 0;
      Wrap_Mode   : Editor.Wrap.Wrap_Mode := Editor.Wrap.Wrap_None;
      Wrap_Col    : Positive := 1;
      Cell_W      : Natural := 0;
      Cell_H      : Natural := 0;
      Is_Current  : Boolean := False;
      Line_Number_Mode : Editor.Line_Numbers.Line_Number_Mode :=
        Editor.Line_Numbers.Absolute_Line_Numbers;
      Line_Number_Current_Row : Natural := 0;
      Settings_Version : Natural := 0;
      Glyph_Count : Natural := 0;
      Glyphs      : Row_Glyph_Array;
   end record;

   Entries : array (Cache_Index) of Row_Entry;

   Hit_Count         : Natural := 0;
   Miss_Count        : Natural := 0;
   Invalidated_Count : Natural := 0;

   function Slot_For
     (Row        : Natural;
      Row_Start  : Natural := 0;
      Screen_Row : Natural := 0) return Cache_Index is
   begin
      return Cache_Index
        (((Row mod Max_Cached_Rows) * 17
          + (Row_Start mod Max_Cached_Rows) * 3
          + (Screen_Row mod Max_Cached_Rows)) mod Max_Cached_Rows);
   end Slot_For;

   procedure Reset is
   begin
      for I in Entries'Range loop
         Entries (I).Valid := False;
         Entries (I).Glyph_Count := 0;
      end loop;

      Hit_Count := 0;
      Miss_Count := 0;
      Invalidated_Count := 0;
   end Reset;

   procedure Invalidate_All is
   begin
      for I in Entries'Range loop
         if Entries (I).Valid then
            Entries (I).Valid := False;
            Invalidated_Count := Invalidated_Count + 1;
         end if;
      end loop;
   end Invalidate_All;

   procedure Invalidate_Row
     (Row : Natural)
   is
   begin
      for I in Entries'Range loop
         if Entries (I).Valid and then Entries (I).Row = Row then
            Entries (I).Valid := False;
            Entries (I).Glyph_Count := 0;
            Invalidated_Count := Invalidated_Count + 1;
         end if;
      end loop;
   end Invalidate_Row;

   procedure Invalidate_Range
     (First_Row : Natural;
      Last_Row  : Natural)
   is
   begin
      if Last_Row < First_Row then
         return;
      end if;

      if Last_Row - First_Row + 1 >= Max_Cached_Rows then
         Invalidate_All;
         return;
      end if;

      for Row in First_Row .. Last_Row loop
         Invalidate_Row (Row);
      end loop;
   end Invalidate_Range;

   function Row_Is_Valid
     (Row          : Natural;
      Screen_Row   : Natural;
      Row_Start    : Natural;
      Row_End      : Natural;
      Line_Count   : Natural;
      Scroll_X     : Natural;
      Viewport_W   : Natural;
      Viewport_H   : Natural;
      Wrap_Mode    : Editor.Wrap.Wrap_Mode;
      Wrap_Col     : Positive;
      Is_Current   : Boolean;
      Line_Number_Mode : Editor.Line_Numbers.Line_Number_Mode;
      Line_Number_Current_Row : Natural) return Boolean
   is
      Slot : constant Cache_Index := Slot_For (Row, Row_Start, Screen_Row);
      E    : Row_Entry renames Entries (Slot);
      OK   : constant Boolean :=
        E.Valid
        and then E.Row = Row
        and then E.Screen_Row = Screen_Row
        and then E.Row_Start = Row_Start
        and then E.Row_End = Row_End
        and then E.Line_Count = Line_Count
        and then E.Scroll_X = Scroll_X
        and then E.Viewport_W = Viewport_W
        and then E.Viewport_H = Viewport_H
        and then E.Wrap_Mode = Wrap_Mode
        and then E.Wrap_Col = Wrap_Col
        and then E.Cell_W = Editor.Layout.Cell_W
        and then E.Cell_H = Editor.Layout.Cell_H
        and then E.Is_Current = Is_Current
        and then E.Line_Number_Mode = Line_Number_Mode
        and then E.Line_Number_Current_Row = Line_Number_Current_Row
        and then E.Settings_Version = Editor.Settings.Version;
   begin
      if OK then
         Hit_Count := Hit_Count + 1;
      else
         Miss_Count := Miss_Count + 1;
      end if;

      return OK;
   end Row_Is_Valid;

   procedure Store_Row
     (Row          : Natural;
      Screen_Row   : Natural;
      Row_Start    : Natural;
      Row_End      : Natural;
      Line_Count   : Natural;
      Scroll_X     : Natural;
      Viewport_W   : Natural;
      Viewport_H   : Natural;
      Wrap_Mode    : Editor.Wrap.Wrap_Mode;
      Wrap_Col     : Positive;
      Is_Current   : Boolean;
      Line_Number_Mode : Editor.Line_Numbers.Line_Number_Mode;
      Line_Number_Current_Row : Natural;
      Packet       : Editor.Render_Packet.Render_Packet;
      First_Glyph  : Natural;
      Glyph_Count  : Natural)
   is
      Slot : constant Cache_Index := Slot_For (Row, Row_Start, Screen_Row);
      E    : Row_Entry renames Entries (Slot);
   begin
      if Glyph_Count > Max_Cached_Row_Glyphs then
         E.Valid := False;
         E.Glyph_Count := 0;
         return;
      end if;

      E.Row := Row;
      E.Screen_Row := Screen_Row;
      E.Row_Start := Row_Start;
      E.Row_End := Row_End;
      E.Line_Count := Line_Count;
      E.Scroll_X := Scroll_X;
      E.Viewport_W := Viewport_W;
      E.Viewport_H := Viewport_H;
      E.Wrap_Mode := Wrap_Mode;
      E.Wrap_Col := Wrap_Col;
      E.Cell_W := Editor.Layout.Cell_W;
      E.Cell_H := Editor.Layout.Cell_H;
      E.Is_Current := Is_Current;
      E.Line_Number_Mode := Line_Number_Mode;
      E.Line_Number_Current_Row := Line_Number_Current_Row;
      E.Settings_Version := Editor.Settings.Version;
      E.Glyph_Count := Glyph_Count;

      if Glyph_Count > 0 then
         for I in 0 .. Glyph_Count - 1 loop
            E.Glyphs (I) := Packet.Glyphs (Integer (First_Glyph + I));
         end loop;
      end if;

      E.Valid := True;
   end Store_Row;

   procedure Emit_Row
     (Row          : Natural;
      Screen_Row   : Natural;
      Row_Start    : Natural;
      Row_End      : Natural;
      Wrap_Mode    : Editor.Wrap.Wrap_Mode;
      Wrap_Col     : Positive;
      Packet       : in out Editor.Render_Packet.Render_Packet)
   is
      Slot  : constant Cache_Index := Slot_For (Row, Row_Start, Screen_Row);
      E     : Row_Entry renames Entries (Slot);
      Index : Natural := 0;
   begin
      if not E.Valid
        or else E.Row /= Row
        or else E.Screen_Row /= Screen_Row
        or else E.Row_Start /= Row_Start
        or else E.Row_End /= Row_End
        or else E.Wrap_Mode /= Wrap_Mode
        or else E.Wrap_Col /= Wrap_Col
      then
         return;
      end if;

      if E.Glyph_Count > 0 then
         for I in 0 .. E.Glyph_Count - 1 loop
            Index := Natural (Packet.Glyph_Count);
            exit when Index >= Editor.Render_Packet.Max_Glyphs;

            Packet.Glyphs (Integer (Index)) := E.Glyphs (I);
            Packet.Glyph_Count := Packet.Glyph_Count + 1;
         end loop;
      end if;
   end Emit_Row;

   function Cache_Hits return Natural is
   begin
      return Hit_Count;
   end Cache_Hits;

   function Cache_Misses return Natural is
   begin
      return Miss_Count;
   end Cache_Misses;

   function Rows_Invalidated return Natural is
   begin
      return Invalidated_Count;
   end Rows_Invalidated;

end Editor.Render_Cache;
