with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Input_Field;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Active_Find_Handlers is

   use type Editor.Commands.Command_Kind;

   function Handle_Active_Find_Input
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean
   is
      Cmd2 : Editor.Commands.Command;
   begin
      if not S.Active_Find_Prompt then
         return False;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Input_Field.Select_All (S.Active_Find_Input);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Commands.Command_Active_Find_Next);
            elsif Cmd.Ch = ASCII.HT then
               null;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Execute_Command (Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Execute_Command (Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Backspace;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Delete_Forward;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
            Cmd2.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Left (S);
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Right (S);
            return True;

         when Editor.Commands.Move_Home | Editor.Commands.Move_Line_Start =>
            Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Start (S);
            return True;

         when Editor.Commands.Move_End | Editor.Commands.Move_Line_End =>
            Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_End (S);
            return True;

         when Editor.Commands.Active_Find_Next =>
            Execute (Editor.Commands.Command_Active_Find_Next);
            return True;

         when Editor.Commands.Active_Find_Previous =>
            Execute (Editor.Commands.Command_Active_Find_Previous);
            return True;

         when Editor.Commands.Active_Find_First =>
            Execute (Editor.Commands.Command_Find_First);
            return True;

         when Editor.Commands.Active_Find_Last =>
            Execute (Editor.Commands.Command_Find_Last);
            return True;

         when Editor.Commands.Active_Find_Reveal_Current =>
            Execute (Editor.Commands.Command_Find_Reveal_Current);
            return True;

         when Editor.Commands.Active_Find_Query_Clear =>
            Execute (Editor.Commands.Command_Find_Query_Clear);
            return True;

         when Editor.Commands.Active_Find_Case_Toggle =>
            Execute (Editor.Commands.Command_Find_Case_Toggle);
            return True;

         when Editor.Commands.Active_Find_Case_Clear =>
            Execute (Editor.Commands.Command_Find_Case_Clear);
            return True;

         when Editor.Commands.Active_Find_Whole_Word_Toggle =>
            Execute (Editor.Commands.Command_Find_Whole_Word_Toggle);
            return True;

         when Editor.Commands.Active_Find_Whole_Word_Clear =>
            Execute (Editor.Commands.Command_Find_Whole_Word_Clear);
            return True;

         when Editor.Commands.Clear_Extra_Carets
            | Editor.Commands.Palette_Cancel =>
            Execute (Editor.Commands.Command_Find_Hide);
            return True;

         when others =>
            return False;
      end case;
   end Handle_Active_Find_Input;

end Editor.Input_Bridge.Active_Find_Handlers;
