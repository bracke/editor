with Editor.Buffer_Switcher;
with Editor.Cursor;
with Editor.Executor.Clipboard;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Buffer_Switcher_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_Buffer_Switcher_Key
     (S               : in out Editor.State.State_Type;
      Chord           : Editor.Keybindings.Key_Chord;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean
   is
      Cmd : Editor.Commands.Command;
   begin
      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_Accept_Buffer_Switcher);
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Close_Buffer_Switcher);
         when Editor.Keybindings.Key_Tab =>
            if Chord.Modifiers.Shift then
               Execute (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
            else
               Execute (Editor.Commands.Command_Buffer_Switcher_Next_Result);
            end if;
         when Editor.Keybindings.Key_Backspace =>
            Cmd.Kind := Editor.Commands.Buffer_Switcher_Backspace;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Delete =>
            Cmd.Kind := Editor.Commands.Buffer_Switcher_Delete_Forward;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Left =>
            Editor.Buffer_Switcher.Move_Cursor_Left (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Right =>
            Editor.Buffer_Switcher.Move_Cursor_Right (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Home =>
            Editor.Buffer_Switcher.Move_Cursor_Start (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_End =>
            Editor.Buffer_Switcher.Move_Cursor_End (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_V =>
            if Chord.Modifiers.Ctrl then
               Cmd.Kind := Editor.Commands.Buffer_Switcher_Insert_Text;
               Cmd.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
               Execute_Command (Cmd);
            end if;
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_Buffer_Switcher_Next_Result);
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
         when others =>
            null;
      end case;

      Notify_Input;
      return True;
   end Handle_Buffer_Switcher_Key;

end Editor.Input_Bridge.Buffer_Switcher_Key_Handlers;
