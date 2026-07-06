with Editor.Cursor;
with Editor.Executor.Clipboard;
with Editor.Overlay_Focus;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Project_Search_Key_Handlers is

   use type Editor.Keybindings.Key_Code;
   use type Editor.Project_Search_Bar.Project_Search_Bar_Field;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   procedure Sync_Project_Search_Replace_Mode_From_Bar
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Project_Search_Bar.Active_Field (S.Project_Search_Bar) =
        Editor.Project_Search_Bar.Project_Search_Replace_Field
      then
         Editor.Project_Search.Set_Replace_Mode_Active (S.Project_Search, True);
      end if;
   end Sync_Project_Search_Replace_Mode_From_Bar;

   function Handle_Project_Search_Bar_Key
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
        (S.Overlay_Focus, Editor.Overlay_Focus.Project_Search_Bar_Overlay)
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            if Chord.Modifiers.Ctrl then
               Execute (Editor.Commands.Command_Open_Selected_Project_Search_Result);
            else
               Execute (Editor.Commands.Command_Run_Project_Search_From_Bar);
            end if;
         when Editor.Keybindings.Key_Tab =>
            Editor.Project_Search_Bar.Toggle_Active_Field (S.Project_Search_Bar);
            Sync_Project_Search_Replace_Mode_From_Bar (S);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Close_Project_Search_Bar);
         when Editor.Keybindings.Key_Backspace =>
            Cmd.Kind := Editor.Commands.Project_Search_Bar_Backspace;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Delete =>
            Cmd.Kind := Editor.Commands.Project_Search_Bar_Delete_Forward;
            Execute_Command (Cmd);
         when Editor.Keybindings.Key_Left =>
            Editor.Project_Search_Bar.Move_Cursor_Left (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Right =>
            Editor.Project_Search_Bar.Move_Cursor_Right (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Home =>
            Editor.Project_Search_Bar.Move_Cursor_Start (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_End =>
            Editor.Project_Search_Bar.Move_Cursor_End (S.Project_Search_Bar);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_V =>
            if Chord.Modifiers.Ctrl then
               Cmd.Kind := Editor.Commands.Project_Search_Bar_Insert_Text;
               Cmd.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
               Execute_Command (Cmd);
            end if;
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_Move_Project_Search_Selection_Down);
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_Move_Project_Search_Selection_Up);
         when others =>
            null;
      end case;

      Notify_Input;
      return True;
   end Handle_Project_Search_Bar_Key;

end Editor.Input_Bridge.Project_Search_Key_Handlers;
