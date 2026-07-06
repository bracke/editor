with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Cursor;
with Editor.Executor.Clipboard;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Focus_Management;
with Editor.Overlay_Focus;
with Editor.View;

package body Editor.Input_Bridge.File_Target_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_File_Target_Key
     (S     : in out Editor.State.State_Type;
      Chord : Editor.Keybindings.Key_Chord) return Boolean
   is
   begin
      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay)
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
            Editor.Focus_Management.Restore_Focus_To_Editor (S);
         when Editor.Keybindings.Key_Escape =>
            Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
            Editor.Focus_Management.Restore_Previous_Focus_Or_Editor (S);
         when Editor.Keybindings.Key_Backspace =>
            Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
         when Editor.Keybindings.Key_Delete =>
            Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
         when Editor.Keybindings.Key_Left =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
         when Editor.Keybindings.Key_Right =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Right (S);
         when Editor.Keybindings.Key_Home =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Start (S);
         when Editor.Keybindings.Key_End =>
            Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_End (S);
         when Editor.Keybindings.Key_V =>
            if Chord.Modifiers.Ctrl then
               Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
                 (S, To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            end if;
         when others =>
            null;
      end case;

      Notify_Input;
      return True;
   end Handle_File_Target_Key;

end Editor.Input_Bridge.File_Target_Key_Handlers;
