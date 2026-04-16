with Ada.Containers.Vectors;
with Ada.Containers; use Ada.Containers;
with Editor.Cursors;

package Editor.Commands is

   use Editor.Cursors;

   ---------------------------------------------------------------------------
   --  Command_Kind
   --
   --  Enumerates all supported command types.
   ---------------------------------------------------------------------------
   type Command_Kind is
     (Insert_Char, Delete_Char, Move_Left, Move_Right, Undo, Redo);

   type Command is record
      Kind  : Command_Kind;
      Pos   : Editor.Cursors.Cursor_Index;
      Ch    : Character;
      Shift : Boolean := False;
   end record;

   function "=" (L, R : Command) return Boolean;

end Editor.Commands;