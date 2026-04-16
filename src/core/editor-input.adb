package body Editor.Input is

   function To_Command
     (E   : Input_Event;
      Pos : Natural) return Editor.Commands.Command is

      C : Editor.Commands.Command;
   begin

      case E.Key is

         when Key_Insert =>
            C.Kind := Insert_Char;
            C.Pos  := Pos;
            C.Ch   := E.Ch;

         when Key_Delete =>
            C.Kind := Delete_Char;
            C.Pos  := Pos;

         when Key_Left =>
            C.Kind := Move_Left;
            C.Pos  := Pos;

         when Key_Right =>
            C.Kind := Move_Right;
            C.Pos  := Pos;

         when Key_Char =>
            C.Kind := Insert_Char;
            C.Pos  := Pos;
            C.Ch   := E.Ch;

      end case;

      return C;
   end To_Command;

end Editor.Input;