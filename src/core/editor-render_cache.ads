with Editor.Line_Numbers;
with Editor.Render_Packet;
with Editor.Wrap;

package Editor.Render_Cache is

   procedure Reset;
   procedure Invalidate_All;
   procedure Invalidate_Row
     (Row : Natural);
   procedure Invalidate_Range
     (First_Row : Natural;
      Last_Row  : Natural);

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
      Line_Number_Current_Row : Natural) return Boolean;

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
      Glyph_Count  : Natural);

   procedure Emit_Row
     (Row          : Natural;
      Screen_Row   : Natural;
      Row_Start    : Natural;
      Row_End      : Natural;
      Wrap_Mode    : Editor.Wrap.Wrap_Mode;
      Wrap_Col     : Positive;
      Packet       : in out Editor.Render_Packet.Render_Packet);

   function Cache_Hits return Natural;
   function Cache_Misses return Natural;
   function Rows_Invalidated return Natural;

end Editor.Render_Cache;
