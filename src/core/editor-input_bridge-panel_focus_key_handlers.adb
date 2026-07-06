with Editor.Cursor;
with Editor.Panel_Focus;
with Editor.Terminal_Tasks;
with Editor.View;

package body Editor.Input_Bridge.Panel_Focus_Key_Handlers is

   use type Editor.Keybindings.Key_Code;
   use type Editor.Panel_Focus.Bottom_Focus_Content;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_Focused_Surface_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if Editor.Terminal_Tasks.Build_Render_Snapshot
          (S.Terminal_Tasks).Focused
      then
         case Chord.Key is
            when Editor.Keybindings.Key_Up =>
               Execute (Editor.Commands.Command_Terminal_Select_Previous_Task);
            when Editor.Keybindings.Key_Down =>
               Execute (Editor.Commands.Command_Terminal_Select_Next_Task);
            when Editor.Keybindings.Key_Enter =>
               Execute (Editor.Commands.Command_Terminal_Run_Selected_Task);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when Editor.Keybindings.Key_Delete =>
               Execute (Editor.Commands.Command_Terminal_Clear_Output);
            when others =>
               return False;
         end case;
         Notify_Input;
         return True;
      elsif S.Recent_Projects_Focused then
         case Chord.Key is
            when Editor.Keybindings.Key_Up =>
               Execute (Editor.Commands.Command_Select_Previous_Recent_Project);
            when Editor.Keybindings.Key_Down =>
               Execute (Editor.Commands.Command_Select_Next_Recent_Project);
            when Editor.Keybindings.Key_Enter =>
               Execute (Editor.Commands.Command_Open_Selected_Recent_Project);
            when Editor.Keybindings.Key_Escape =>
               Execute (Editor.Commands.Command_Focus_Editor_Text);
            when Editor.Keybindings.Key_Delete =>
               Execute (Editor.Commands.Command_Remove_Selected_Recent_Project);
            when others =>
               return False;
         end case;
         Notify_Input;
         return True;
      elsif Editor.Panel_Focus.Bottom_Panel_Has_Focus (S.Panel_Focus) then
         if Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute (Editor.Commands.Command_Search_Results_Move_Up);
               when Editor.Keybindings.Key_Down =>
                  Execute (Editor.Commands.Command_Search_Results_Move_Down);
               when Editor.Keybindings.Key_Page_Up =>
                  Execute (Editor.Commands.Command_Search_Results_Page_Up);
               when Editor.Keybindings.Key_Page_Down =>
                  Execute (Editor.Commands.Command_Search_Results_Page_Down);
               when Editor.Keybindings.Key_Enter =>
                  Execute (Editor.Commands.Command_Search_Results_Open_Selected);
               when Editor.Keybindings.Key_Escape =>
                  Execute (Editor.Commands.Command_Focus_Editor_Text);
               when others =>
                  return False;
            end case;
            Notify_Input;
            return True;
         elsif Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Problems_Focus
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Up =>
                  Execute (Editor.Commands.Command_Problems_Move_Up);
               when Editor.Keybindings.Key_Down =>
                  Execute (Editor.Commands.Command_Problems_Move_Down);
               when Editor.Keybindings.Key_Page_Up =>
                  Execute (Editor.Commands.Command_Problems_Page_Up);
               when Editor.Keybindings.Key_Page_Down =>
                  Execute (Editor.Commands.Command_Problems_Page_Down);
               when Editor.Keybindings.Key_Enter =>
                  Execute (Editor.Commands.Command_Problems_Open_Selected);
               when Editor.Keybindings.Key_Escape =>
                  Execute (Editor.Commands.Command_Problems_Focus_Editor);
               when others =>
                  return False;
            end case;
            Notify_Input;
            return True;
         end if;
      end if;

      return False;
   end Handle_Focused_Surface_Key;

end Editor.Input_Bridge.Panel_Focus_Key_Handlers;
