with Editor.Cursor;
with Editor.Render_Cache;
with Editor.Settings_Management;
with Editor.View;

package body Editor.Input_Bridge.Settings_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Settings_Input is
   begin
      Editor.Render_Cache.Invalidate_All;
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Settings_Input;

   function Handle_Settings_Chord
     (S      : in out Editor.State.State_Type;
      Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean
   is
      UI     : Editor.Settings_Management.Settings_Editor_State :=
        Editor.Settings_Management.Current_Settings_Editor_State;
      Status : Editor.Settings_Management.Setting_Update_Status;
   begin
      if not Editor.Settings_Management.Current_Settings_Surface_Focused
        or else not Editor.Settings_Management.Current_Settings_Surface_Visible
        or else Chord.Modifiers.Ctrl
        or else Chord.Modifiers.Shift
        or else Chord.Modifiers.Alt
        or else Chord.Modifiers.Meta
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Down =>
            Editor.Settings_Management.Select_Next_Setting (UI);
            Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
            Report ("Settings selection changed.");
         when Editor.Keybindings.Key_Up =>
            Editor.Settings_Management.Select_Previous_Setting (UI);
            Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
            Report ("Settings selection changed.");
         when Editor.Keybindings.Key_Enter =>
            if Editor.Settings_Management.Has_Pending_Reset_All (UI) then
               Editor.Settings_Management.Confirm_Reset_All_Settings
                 (S.Settings, UI, Status);
            else
               Editor.Settings_Management.Execute_Settings_Surface_Command
                 (Editor.Settings_Management.Settings_Action_Toggle_Selected,
                  S.Settings, UI, Status);
            end if;
            Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
            Report (Editor.Settings_Management.Update_Status_Label (Status));
         when Editor.Keybindings.Key_Delete =>
            Editor.Settings_Management.Execute_Settings_Surface_Command
              (Editor.Settings_Management.Settings_Action_Reset_Selected,
               S.Settings, UI, Status);
            Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
            Report (Editor.Settings_Management.Update_Status_Label (Status));
         when Editor.Keybindings.Key_Escape =>
            if Editor.Settings_Management.Has_Pending_Reset_All (UI) then
               Editor.Settings_Management.Cancel_Reset_All_Settings (UI, Status);
               Report (Editor.Settings_Management.Update_Status_Label (Status));
            else
               Editor.Settings_Management.Hide_Settings (UI);
               Report ("Settings hidden.");
            end if;
            Editor.Settings_Management.Set_Current_Settings_Editor_State (UI);
         when others =>
            return False;
      end case;

      Notify_Settings_Input;
      return True;
   end Handle_Settings_Chord;

end Editor.Input_Bridge.Settings_Handlers;
