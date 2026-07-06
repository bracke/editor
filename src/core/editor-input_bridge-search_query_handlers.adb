with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Feature_Search_Results;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Search_Query_Handlers is

   use type Editor.Commands.Command_Kind;

   procedure Project_Search_Rows (S : in out Editor.State.State_Type) is
   begin
      Editor.Feature_Search_Results.Project_Rows
        (S.Feature_Search_Results, S.Feature_Panel);
      Editor.Render_Cache.Invalidate_All;
   end Project_Search_Rows;

   procedure Insert_Search_Text
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
   begin
      for Ch of Text loop
         if Ch /= ASCII.LF and then Ch /= ASCII.CR then
            Editor.Feature_Search_Results.Insert_Search_Input_Character
              (S.Feature_Search_Results, Ch);
         end if;
      end loop;
   end Insert_Search_Text;

   function Handle_Search_Query_Input
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if not Editor.Feature_Search_Results.Search_Input_Is_Active
        (S.Feature_Search_Results)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Commands.Command_Search_Results_Search_Active_Buffer);
            elsif Length (Cmd.Text) > 0 then
               Insert_Search_Text (S, To_String (Cmd.Text));
               Project_Search_Rows (S);
            elsif Cmd.Ch /= ASCII.NUL and then Cmd.Ch /= ASCII.HT then
               Editor.Feature_Search_Results.Insert_Search_Input_Character
                 (S.Feature_Search_Results, Cmd.Ch);
               Project_Search_Rows (S);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Backward
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Feature_Search_Results.Delete_Search_Input_Character_Forward
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
            return True;

         when Editor.Commands.Paste_Text =>
            Insert_Search_Text (S, To_String (Cmd.Text));
            Project_Search_Rows (S);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Insert_Search_Text
              (S, To_String (Editor.Executor.Clipboard.Text_For_Local_Input));
            Project_Search_Rows (S);
            return True;

         when Editor.Commands.Move_Up =>
            Execute (Editor.Commands.Command_Search_Results_Query_History_Previous);
            return True;

         when Editor.Commands.Move_Down =>
            Execute (Editor.Commands.Command_Search_Results_Query_History_Next);
            return True;

         when Editor.Commands.Clear_Extra_Carets | Editor.Commands.Palette_Cancel =>
            Editor.Feature_Search_Results.Deactivate_Search_Query_Input
              (S.Feature_Search_Results);
            Project_Search_Rows (S);
            return True;

         when others =>
            return True;
      end case;
   end Handle_Search_Query_Input;

end Editor.Input_Bridge.Search_Query_Handlers;
