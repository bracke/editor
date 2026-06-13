with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
package body Editor.Test_Helper is

   function Insert (Pos : Natural; Ch  : Character) return Command is
      C : Command;
   begin
      C.Kind := Insert_Text_Input;
      C.Pos  := Pos;
      C.Has_Position := True;
      C.Ch   := Ch;
      C.Text := To_Unbounded_String (String'(1 => Ch));
      return C;
   end Insert;

   function Delete (Pos : Natural) return Command is
      C : Command;
   begin
      C.Kind := Delete_Char;
      C.Pos  := Pos;
      C.Has_Position := True;
      return C;
   end Delete;

   function Undo return Command is
      C : Command;
   begin
      C.Kind := Undo;
      C.Pos  := 0;
      C.Ch   := ASCII.NUL;
      return C;
   end Undo;

   function Redo return Command is
      C : Command;
   begin
      C.Kind := Redo;
      C.Pos  := 0;
      C.Ch   := ASCII.NUL;
      return C;
   end Redo;

   function Move_Left (Shift : Boolean := False) return Command is
      C : Command;
   begin
      C.Kind  := Move_Left;
      C.Shift := Shift;
      return C;
   end;

   function Move_Right (Shift : Boolean := False) return Command is
      C : Command;
   begin
      C.Kind  := Move_Right;
      C.Shift := Shift;
      return C;
   end;

end Editor.Test_Helper;
