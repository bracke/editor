with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Command_Kinds;
package body Editor.Test_Helper is

   function Insert (Pos : Natural; Ch  : Character) return Command is
      C : Command;
   begin
      C.Kind := Editor.Command_Kinds.Insert_Text_Input;
      C.Pos  := Pos;
      C.Has_Position := True;
      C.Ch   := Ch;
      C.Text := To_Unbounded_String (String'(1 => Ch));
      return C;
   end Insert;

   function Delete (Pos : Natural) return Command is
      C : Command;
   begin
      C.Kind := Editor.Command_Kinds.Delete_Char;
      C.Pos  := Pos;
      C.Has_Position := True;
      return C;
   end Delete;

   function Undo return Command is
      C : Command;
   begin
      C.Kind := Editor.Command_Kinds.Undo;
      C.Pos  := 0;
      C.Ch   := ASCII.NUL;
      return C;
   end Undo;

   function Redo return Command is
      C : Command;
   begin
      C.Kind := Editor.Command_Kinds.Redo;
      C.Pos  := 0;
      C.Ch   := ASCII.NUL;
      return C;
   end Redo;

   function Move_Left (Shift : Boolean := False) return Command is
      C : Command;
   begin
      C.Kind  := Editor.Command_Kinds.Move_Left;
      C.Shift := Shift;
      return C;
   end;

   function Move_Right (Shift : Boolean := False) return Command is
      C : Command;
   begin
      C.Kind  := Editor.Command_Kinds.Move_Right;
      C.Shift := Shift;
      return C;
   end;

end Editor.Test_Helper;
