with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Command_Kinds;
with Editor.Commands;
with Editor.Cursors;
with Editor.Unicode;

package Editor.Commands.Payloads is

   use Editor.Cursors;
   use Ada.Strings.Unbounded;


   package Position_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Cursor_Index);

   package Delete_Count_Vectors is new
     Ada.Containers.Vectors (Index_Type => Natural, Element_Type => Natural);

   package Text_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Unbounded_String,
        "="          => "=");

   type Command is record
      Kind : Command_Kind := Editor.Command_Kinds.Insert_Text_Input;

      Pos          : Cursor_Index := 0;
      Has_Position : Boolean := False;
      Ch           : Character := ASCII.NUL;
      Code    : Editor.Unicode.Code_Point := Wide_Wide_Character'Val (0);
      Shift   : Boolean := False;
      Ctrl    : Boolean := False;
      Alt     : Boolean := False;
      Click_X : Natural := 0;
      Click_Y : Natural := 0;

      Text          : Unbounded_String := Null_Unbounded_String;
      Path          : Unbounded_String := Null_Unbounded_String;
      Query         : Unbounded_String := Null_Unbounded_String;
      Buffer_Id     : Natural := 0;
      Positions     : Position_Vectors.Vector;
      Delete_Counts : Delete_Count_Vectors.Vector;
      Insert_Texts  : Text_Vectors.Vector;
   end record;


   function Command_For_Id
     (Id    : Command_Id;
      Shift : Boolean := False) return Command;

   function "=" (L, R : Command) return Boolean;

end Editor.Commands.Payloads;
