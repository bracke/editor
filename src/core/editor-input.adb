with Editor.Commands; use Editor.Commands;
with Editor.Unicode;
with Editor.UTF8;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Input is

   function To_Command
     (E   : Input_Event;
      Pos : Natural) return Editor.Commands.Command is

      C : Editor.Commands.Command;
   begin
      C.Pos    := Pos;
      C.Has_Position := True;
      C.Ch     := ASCII.NUL;
      C.Code   := Wide_Wide_Character'Val (0);
      C.Shift  := E.Shift;
      C.Ctrl   := E.Ctrl;
      C.Alt    := E.Alt;

      case E.Key is
         when Key_Insert_Text_Input =>
            C.Kind := Insert_Text_Input;
            C.Ch   := E.Ch;

            if E.Code /= Wide_Wide_Character'Val (0) then
               if Editor.Unicode.Is_Valid_Scalar (E.Code) then
                  C.Code := E.Code;
               else
                  C.Code := Editor.Unicode.Replacement_Character;
                  C.Ch   := ASCII.NUL;
               end if;

               C.Text := To_Unbounded_String (Editor.UTF8.Encode_UTF8 (C.Code));
            elsif E.Ch /= ASCII.NUL then
               C.Code := Wide_Wide_Character'Val (Character'Pos (E.Ch));
               C.Text := To_Unbounded_String (String'(1 => E.Ch));
            else
               C.Code := Wide_Wide_Character'Val (0);
               C.Text := Null_Unbounded_String;
            end if;

         when Key_Delete_Char =>
            if E.Ctrl then
               C.Kind := Delete_Previous_Word;
            else
               C.Kind := Delete_Char;
            end if;

         when Key_Forward_Delete_Char =>
            if E.Ctrl then
               C.Kind := Delete_Next_Word;
            else
               C.Kind := Forward_Delete_Char;
            end if;

         when Key_Move_Left =>
            if E.Ctrl then
               C.Kind := Move_Word_Left;
            else
               C.Kind := Move_Left;
            end if;

         when Key_Move_Right =>
            if E.Ctrl then
               C.Kind := Move_Word_Right;
            else
               C.Kind := Move_Right;
            end if;

         when Key_Move_Up =>
            C.Kind := Move_Up;

         when Key_Move_Down =>
            C.Kind := Move_Down;

         when Key_Home =>
            if E.Ctrl then
               C.Kind := Move_Document_Start;
            else
               C.Kind := Move_Line_Start;
            end if;

         when Key_End =>
            if E.Ctrl then
               C.Kind := Move_Document_End;
            else
               C.Kind := Move_Line_End;
            end if;

         when Key_Page_Up =>
            C.Kind := Move_Page_Up;

         when Key_Page_Down =>
            C.Kind := Move_Page_Down;

         when Key_Mouse_Left =>
            C.Kind := Move_To_Point;
            C.Click_X := E.X;
            C.Click_Y := E.Y;

         when Key_Undo =>
            C.Kind := Undo;
            C.Shift := False;

         when Key_Redo =>
            C.Kind := Redo;
            C.Shift := False;

         when Key_Save =>
            C.Kind := Save_File;
            C.Ctrl := True;

         when Key_Command_Palette =>
            C.Kind := Open_Command_Palette;
            C.Ctrl := True;
      end case;

      return C;
   end To_Command;

end Editor.Input;
