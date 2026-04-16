with Ada.Containers.Vectors;

package Editor.Cursors is

   ------------------------------------------------------------------------
   -- Core cursor type
   ------------------------------------------------------------------------
   subtype Cursor_Index is Natural;

   type Span is record
      Left  : Cursor_Index;
      Right : Cursor_Index;
   end record;

   ------------------------------------------------------------------------
   -- Cursor vector definition
   ------------------------------------------------------------------------
   package Cursors_Vector is
      new Ada.Containers.Vectors
        (Index_Type   => Natural,
         Element_Type => Cursor_Index);

   function Add
  (Value : Cursor_Index;
   Delta2 : Integer;
   Max   : Cursor_Index)
   return Cursor_Index;

   function Sub
   (Value : Cursor_Index;
      Delta2 : Integer)
      return Cursor_Index;

end Editor.Cursors;