with Editor.Cursor;
with Editor.Executor.Clipboard;
with Editor.Go_To_Line;
with Editor.Overlay_Focus;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Goto_Line_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_Goto_Line_Key
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
        (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_Accept_Goto_Line);
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Close_Goto_Line);
         when Editor.Keybindings.Key_Backspace =>
            Cmd.Kind := Editor.Commands.Goto_Line_Backspace;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Delete =>
            Cmd.Kind := Editor.Commands.Goto_Line_Delete_Forward;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Left =>
            Editor.Go_To_Line.Move_Cursor_Left (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Right =>
            Editor.Go_To_Line.Move_Cursor_Right (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Home =>
            Editor.Go_To_Line.Move_Cursor_Start (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_End =>
            Editor.Go_To_Line.Move_Cursor_End (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_V =>
            if Chord.Modifiers.Ctrl then
               Cmd.Kind := Editor.Commands.Goto_Line_Insert_Text;
               Cmd.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
               Execute_Command (Cmd);
            end if;
         when others =>
            null;
      end case;

      Notify_Input;
      return True;
   end Handle_Goto_Line_Key;

end Editor.Input_Bridge.Goto_Line_Key_Handlers;
