package body Editor.Cursors is

   function Add
     (Value : Cursor_Index;
      Delta2 : Integer;
      Max   : Cursor_Index)
      return Cursor_Index
   is
      Raw : constant Integer := Integer (Value) + Delta2;
   begin
      if Raw < 0 then
         return 0;
      elsif Raw > Integer (Max) then
         return Max;
      else
         return Cursor_Index (Raw);
      end if;
   end Add;

   function Sub
     (Value : Cursor_Index;
      Delta2 : Integer)
      return Cursor_Index
   is
      Raw : constant Integer := Integer (Value) - Delta2;
   begin
      if Raw < 0 then
         return 0;
      else
         return Cursor_Index (Raw);
      end if;
   end Sub;

end Editor.Cursors;