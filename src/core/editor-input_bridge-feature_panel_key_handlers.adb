with Editor.Cursor;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Outline;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Feature_Panel_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   procedure Project_Search_Rows
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
   end Project_Search_Rows;

   procedure Project_Outline_Rows
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Outline.Set_Rows_From_Outline
        (S.Outline, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
   end Project_Outline_Rows;

   function Handle_Search_Input_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      case Chord.Key is
         when Editor.Keybindings.Key_Up =>
            Execute
              (Editor.Commands.Command_Search_Results_Query_History_Previous);
         when Editor.Keybindings.Key_Down =>
            Execute
              (Editor.Commands.Command_Search_Results_Query_History_Next);
         when Editor.Keybindings.Key_Enter =>
            Execute
              (Editor.Commands.Command_Search_Results_Search_Active_Buffer);
         when Editor.Keybindings.Key_Escape =>
            Editor.Feature_Search_Results.Deactivate_Search_Query_Input
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
         when Editor.Keybindings.Key_Backspace =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
         when Editor.Keybindings.Key_Delete =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Forward
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
         when others =>
            null;
      end case;

      return True;
   end Handle_Search_Input_Key;

   function Handle_Outline_Filter_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      case Chord.Key is
         when Editor.Keybindings.Key_Up =>
            if Chord.Modifiers.Ctrl or else Chord.Modifiers.Alt then
               Execute
                 (Editor.Commands.Command_Outline_Filter_History_Previous);
            else
               Execute
                 (Editor.Commands.Command_Select_Previous_Outline_Item);
            end if;
         when Editor.Keybindings.Key_Down =>
            if Chord.Modifiers.Ctrl or else Chord.Modifiers.Alt then
               Execute
                 (Editor.Commands.Command_Outline_Filter_History_Next);
            else
               Execute
                 (Editor.Commands.Command_Select_Next_Outline_Item);
            end if;
         when Editor.Keybindings.Key_Enter =>
            Editor.Outline.Commit_Filter_To_History (S.Outline);
            Execute (Editor.Commands.Command_Open_Selected_Outline_Item);
         when Editor.Keybindings.Key_Escape =>
            if Editor.Outline.Filter_Text (S.Outline) /= "" then
               Editor.Outline.Clear_Filter_Text (S.Outline);
            else
               Editor.Outline.Deactivate_Filter_Input (S.Outline);
            end if;
            Project_Outline_Rows (S);
         when Editor.Keybindings.Key_Backspace =>
            Editor.Outline.Delete_Filter_Character_Backward (S.Outline);
            Project_Outline_Rows (S);
         when Editor.Keybindings.Key_Delete =>
            Editor.Outline.Delete_Filter_Character_Forward (S.Outline);
            Project_Outline_Rows (S);
         when Editor.Keybindings.Key_Left =>
            Editor.Outline.Move_Filter_Caret_Left (S.Outline);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Right =>
            Editor.Outline.Move_Filter_Caret_Right (S.Outline);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_Home =>
            Editor.Outline.Move_Filter_Caret_Start (S.Outline);
            Editor.Render_Cache.Invalidate_All;
         when Editor.Keybindings.Key_End =>
            Editor.Outline.Move_Filter_Caret_End (S.Outline);
            Editor.Render_Cache.Invalidate_All;
         when others =>
            null;
      end case;

      return True;
   end Handle_Outline_Filter_Key;

   procedure Handle_Feature_Row_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id))
   is
   begin
      case Chord.Key is
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_Feature_Panel_Select_Previous);
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_Feature_Panel_Select_Next);
         when Editor.Keybindings.Key_Enter =>
            if Editor.Feature_Panel.Selected_Row (S.Feature_Panel) /= 0
              and then Editor.Outline.Feature_Row_Maps_To_Item
                (S.Outline,
                 S.Feature_Panel,
                 Editor.Feature_Panel.Selected_Row (S.Feature_Panel))
            then
               Execute (Editor.Commands.Command_Open_Selected_Outline_Item);
            else
               Execute (Editor.Commands.Command_Feature_Panel_Open_Selected);
            end if;
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Focus_Editor_Text);
         when others =>
            null;
      end case;
   end Handle_Feature_Row_Key;

   function Handle_Feature_Panel_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if not Editor.Feature_Panel.Is_Focused (S.Feature_Panel) then
         return False;
      end if;

      if not Editor.Feature_Panel.Is_Visible (S.Feature_Panel) then
         Execute (Editor.Commands.Command_Focus_Editor_Text);
      elsif Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         return Handle_Search_Input_Key (S, Chord, Execute);
      elsif Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         return Handle_Outline_Filter_Key (S, Chord, Execute);
      else
         Handle_Feature_Row_Key (S, Chord, Execute);
      end if;

      Notify_Input;
      return True;
   end Handle_Feature_Panel_Key;

end Editor.Input_Bridge.Feature_Panel_Key_Handlers;
