with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor.Clipboard;
with Editor.Executor.Command_Surface_Commands;
with Editor.Go_To_Line;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Goto_Line_Handlers is

   use type Editor.Commands.Command_Kind;

   function Handle_Goto_Line
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean
   is
      Cmd2 : Editor.Commands.Command;
   begin
      if Cmd.Kind = Editor.Commands.Open_Goto_Line then
         Execute (Editor.Commands.Command_Goto_Line);
         return True;
      elsif Cmd.Kind = Editor.Commands.Prefill_Goto_Line_Current then
         Execute (Editor.Commands.Command_Goto_Line_Prefill_Current);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Go_To_Line_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Go_To_Line.Select_All (S.Go_To_Line);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Commands.Command_Accept_Goto_Line);
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Execute_Command (Cmd2);
            elsif Cmd.Ch /= ASCII.NUL and then Cmd.Ch /= ASCII.HT then
               Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Execute_Command (Cmd2);
            end if;
            return True;

         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Backspace;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Delete_Forward;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Text =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Paste_Clipboard =>
            Cmd2.Kind := Editor.Commands.Goto_Line_Insert_Text;
            Cmd2.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
            Execute_Command (Cmd2);
            return True;

         when Editor.Commands.Move_Left =>
            Editor.Go_To_Line.Move_Cursor_Left (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Right =>
            Editor.Go_To_Line.Move_Cursor_Right (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Line_Start =>
            Editor.Go_To_Line.Move_Cursor_Start (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Move_Line_End =>
            Editor.Go_To_Line.Move_Cursor_End (S.Go_To_Line);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Commands.Prefill_Goto_Line_Current =>
            Execute (Editor.Commands.Command_Goto_Line_Prefill_Current);
            return True;

         when Editor.Commands.Close_Goto_Line =>
            Execute (Editor.Commands.Command_Close_Goto_Line);
            return True;

         when Editor.Commands.Accept_Goto_Line =>
            Execute (Editor.Commands.Command_Accept_Goto_Line);
            return True;

         when Editor.Commands.Goto_Line_Query_Set =>
            Editor.Executor.Command_Surface_Commands.Execute_Goto_Line_Set_Query
              (S, To_String (Cmd.Text));
            return True;

         when Editor.Commands.Goto_Line_Query_Clear =>
            Editor.Executor.Command_Surface_Commands.Execute_Goto_Line_Clear_Query (S);
            return True;

         when others =>
            return False;
      end case;
   end Handle_Goto_Line;

end Editor.Input_Bridge.Goto_Line_Handlers;
