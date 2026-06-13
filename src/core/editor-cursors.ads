with Ada.Containers.Vectors;

package Editor.Cursors is

   subtype Cursor_Index is Natural;

   type Span is record
      Left  : Cursor_Index;
      Right : Cursor_Index;
   end record;

   type Caret_State is record
      Pos                   : Cursor_Index := 0;
      Anchor                : Cursor_Index := 0;
      Virtual_Column        : Natural := 0;
      Anchor_Virtual_Column : Natural := 0;
   end record;

   package Cursors_Vector is
      new Ada.Containers.Vectors
        (Index_Type   => Natural,
         Element_Type => Caret_State);

   function Add
     (Value  : Cursor_Index;
      Delta2 : Integer;
      Max    : Cursor_Index)
      return Cursor_Index;

   function Sub
     (Value  : Cursor_Index;
      Delta2 : Integer)
      return Cursor_Index;

end Editor.Cursors;