with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Feature_Panel;
with Editor.Outline;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Outline_Filter_Handlers is

   use type Editor.Commands.Command_Kind;

   procedure Project_Outline_Rows (S : in out Editor.State.State_Type) is
   begin
      Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      if Editor.Outline.Selected_Index (S.Outline) /= 0 then
         Editor.Feature_Panel.Request_Reveal_Row
           (S.Feature_Panel,
            Editor.Outline.Visible_Row_For_Outline_Row
              (S.Outline, Editor.Outline.Selected_Index (S.Outline)));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Project_Outline_Rows;

   function Handle_Outline_Filter_Input
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if not Editor.Outline.Filter_Input_Is_Active (S.Outline) then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Editor.Outline.Commit_Filter_To_History (S.Outline);
               if Editor.Feature_Panel.Has_Selection (S.Feature_Panel) then
                  Execute (Editor.Commands.Command_Open_Selected_Outline_Item);
               end if;
            elsif Cmd.Ch = ASCII.HT then
               Editor.Outline.Deactivate_Filter_Input (S.Outline);
               Editor.Render_Cache.Invalidate_All;
            elsif Length (Cmd.Text) > 0 then
               Editor.Outline.Insert_Filter_Text (S.Outline, To_String (Cmd.Text));
               Project_Outline_Rows (S);
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Outline.Insert_Filter_Character (S.Outline, Cmd.Ch);
               Project_Outline_Rows (S);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Outline.Delete_Filter_Character_Backward (S.Outline);
            Project_Outline_Rows (S);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Outline.Delete_Filter_Character_Forward (S.Outline);
            Project_Outline_Rows (S);
            return True;

         when Editor.Commands.Paste_Text =>
            Editor.Outline.Insert_Filter_Text (S.Outline, To_String (Cmd.Text));
            Project_Outline_Rows (S);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Editor.Outline.Insert_Filter_Text
              (S.Outline, To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            Project_Outline_Rows (S);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Outline.Move_Filter_Caret_Left (S.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Outline.Move_Filter_Caret_Right (S.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Outline.Move_Filter_Caret_Start (S.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Outline.Move_Filter_Caret_End (S.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Down | Editor.Commands.Select_Next_Outline_Item =>
            Execute (Editor.Commands.Command_Select_Next_Outline_Item);
            return True;

         when Editor.Commands.Move_Up | Editor.Commands.Select_Previous_Outline_Item =>
            Execute (Editor.Commands.Command_Select_Previous_Outline_Item);
            return True;

         when Editor.Commands.Open_Selected_Outline_Item =>
            Execute (Editor.Commands.Command_Open_Selected_Outline_Item);
            return True;

         when Editor.Commands.Clear_Extra_Carets | Editor.Commands.Palette_Cancel =>
            if Editor.Outline.Filter_Text (S.Outline) /= "" then
               Editor.Outline.Clear_Filter_Text (S.Outline);
            else
               Editor.Outline.Deactivate_Filter_Input (S.Outline);
            end if;
            Editor.Outline.Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when others =>
            return True;
      end case;
   end Handle_Outline_Filter_Input;

end Editor.Input_Bridge.Outline_Filter_Handlers;
