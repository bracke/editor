with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Focus_Management;
with Editor.Overlay_Focus;

package body Editor.Input_Bridge.File_Target_Handlers is

   use type Editor.Commands.Command_Kind;

   function Handle_File_Target_Prompt
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      if not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S) then
         return False;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Executor.File_Target_Prompt_Commands.Select_All_File_Target_Prompt_Text
                 (S);
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
               Editor.Focus_Management.Restore_Focus_To_Editor (S);
            elsif Cmd.Ch = ASCII.HT then
               null;
            elsif Length (Cmd.Text) > 0 then
               Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                 (S, To_String (Cmd.Text));
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                 (S, String'(1 => Cmd.Ch));
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
            return True;

         when Editor.Commands.Paste_Text =>
            Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
              (S, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
              (S, To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Right (S);
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Start (S);
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_End (S);
            return True;

         when Editor.Commands.Palette_Cancel =>
            Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
            Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (S);
            return True;

         when others =>
            return True;
      end case;
   end Handle_File_Target_Prompt;

end Editor.Input_Bridge.File_Target_Handlers;
