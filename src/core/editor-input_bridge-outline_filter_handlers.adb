with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Feature_Panel;
with Editor.Outline;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Outline_Filter_Handlers is

   use type Editor.Command_Kinds.Command_Kind;

   procedure Project_Outline_Rows (S : in out Editor.State.State_Type) is
   begin
      Editor.Outline.Set_Rows_From_Outline (S.Outline_Runtime.Outline, S.Panel.Feature_Panel);
      if Editor.Outline.Selected_Index (S.Outline_Runtime.Outline) /= 0 then
         Editor.Feature_Panel.Request_Reveal_Row
           (S.Panel.Feature_Panel,
            Editor.Outline.Visible_Row_For_Outline_Row
              (S.Outline_Runtime.Outline, Editor.Outline.Selected_Index (S.Outline_Runtime.Outline)));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Project_Outline_Rows;

   function Handle_Outline_Filter_Input
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Payloads.Command;
      Execute : not null access procedure
        (Id : Editor.Command_Ids.Command_Id)) return Boolean
   is
   begin
      if not Editor.Outline.Filter_Input_Is_Active (S.Outline_Runtime.Outline) then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Command_Kinds.Insert_Text_Input =>
            if Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Editor.Outline.Commit_Filter_To_History (S.Outline_Runtime.Outline);
               if Editor.Feature_Panel.Has_Selection (S.Panel.Feature_Panel) then
                  Execute (Editor.Command_Ids.Command_Open_Selected_Outline_Item);
               end if;
            elsif Cmd.Ch = ASCII.HT then
               Editor.Outline.Deactivate_Filter_Input (S.Outline_Runtime.Outline);
               Editor.Render_Cache.Invalidate_All;
            elsif Length (Cmd.Text) > 0 then
               Editor.Outline.Insert_Filter_Text (S.Outline_Runtime.Outline, To_String (Cmd.Text));
               Project_Outline_Rows (S);
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Outline.Insert_Filter_Character (S.Outline_Runtime.Outline, Cmd.Ch);
               Project_Outline_Rows (S);
            end if;
            return True;

         when Editor.Command_Kinds.Delete_Char
            | Editor.Command_Kinds.Delete_Previous_Character =>
            Editor.Outline.Delete_Filter_Character_Backward (S.Outline_Runtime.Outline);
            Project_Outline_Rows (S);
            return True;

         when Editor.Command_Kinds.Forward_Delete_Char
            | Editor.Command_Kinds.Delete_Next_Character =>
            Editor.Outline.Delete_Filter_Character_Forward (S.Outline_Runtime.Outline);
            Project_Outline_Rows (S);
            return True;

         when Editor.Command_Kinds.Paste_Text =>
            Editor.Outline.Insert_Filter_Text (S.Outline_Runtime.Outline, To_String (Cmd.Text));
            Project_Outline_Rows (S);
            return True;

         when Editor.Command_Kinds.Paste_Clipboard =>
            Editor.Outline.Insert_Filter_Text
              (S.Outline_Runtime.Outline, To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            Project_Outline_Rows (S);
            return True;

         when Editor.Command_Kinds.Move_Left =>
            Editor.Outline.Move_Filter_Caret_Left (S.Outline_Runtime.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Right =>
            Editor.Outline.Move_Filter_Caret_Right (S.Outline_Runtime.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Home | Editor.Command_Kinds.Move_Line_Start =>
            Editor.Outline.Move_Filter_Caret_Start (S.Outline_Runtime.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_End | Editor.Command_Kinds.Move_Line_End =>
            Editor.Outline.Move_Filter_Caret_End (S.Outline_Runtime.Outline);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Down | Editor.Command_Kinds.Select_Next_Outline_Item =>
            Execute (Editor.Command_Ids.Command_Select_Next_Outline_Item);
            return True;

         when Editor.Command_Kinds.Move_Up | Editor.Command_Kinds.Select_Previous_Outline_Item =>
            Execute (Editor.Command_Ids.Command_Select_Previous_Outline_Item);
            return True;

         when Editor.Command_Kinds.Open_Selected_Outline_Item =>
            Execute (Editor.Command_Ids.Command_Open_Selected_Outline_Item);
            return True;

         when Editor.Command_Kinds.Clear_Extra_Carets | Editor.Command_Kinds.Palette_Cancel =>
            if Editor.Outline.Filter_Text (S.Outline_Runtime.Outline) /= "" then
               Editor.Outline.Clear_Filter_Text (S.Outline_Runtime.Outline);
            else
               Editor.Outline.Deactivate_Filter_Input (S.Outline_Runtime.Outline);
            end if;
            Editor.Outline.Set_Rows_From_Outline (S.Outline_Runtime.Outline, S.Panel.Feature_Panel);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when others =>
            return True;
      end case;
   end Handle_Outline_Filter_Input;

end Editor.Input_Bridge.Outline_Filter_Handlers;
