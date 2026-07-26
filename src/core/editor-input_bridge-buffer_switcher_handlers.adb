with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Kinds;
with Editor.Commands.Payloads;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffer_Switcher;
with Editor.Executor.Clipboard;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Input_Bridge.Buffer_Switcher_Handlers is

   use type Editor.Command_Kinds.Command_Kind;

   function Handle_Buffer_Switcher
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command)) return Boolean
   is
      Cmd2 : Editor.Commands.Payloads.Command;
   begin
      if Cmd.Kind = Editor.Command_Kinds.Open_Buffer_Switcher then
         Execute (Editor.Command_Ids.Command_Open_Buffer_Switcher);
         return True;
      end if;

      if not Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
      then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Command_Kinds.Insert_Text_Input =>
            if Cmd.Ctrl and then (Cmd.Ch = 'a' or else Cmd.Ch = 'A') then
               Editor.Buffer_Switcher.Select_All (S.Buffer_Switcher);
               Editor.Render_Cache.Invalidate_All;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Execute (Editor.Command_Ids.Command_Accept_Buffer_Switcher);
            elsif Cmd.Ch = ASCII.HT then
               if Cmd.Shift then
                  Execute (Editor.Command_Ids.Command_Buffer_Switcher_Previous_Result);
               else
                  Execute (Editor.Command_Ids.Command_Buffer_Switcher_Next_Result);
               end if;
            elsif Length (Cmd.Text) > 0 then
               Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Insert_Text;
               Cmd2.Text := Cmd.Text;
               Execute_Command (Cmd2);
            elsif Cmd.Ch /= ASCII.NUL then
               Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Insert_Text;
               Cmd2.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               Execute_Command (Cmd2);
            end if;
            return True;

         when Editor.Command_Kinds.Delete_Char
            | Editor.Command_Kinds.Delete_Previous_Character =>
            Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Backspace;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Forward_Delete_Char
            | Editor.Command_Kinds.Delete_Next_Character =>
            Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Delete_Forward;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Paste_Text =>
            Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Insert_Text;
            Cmd2.Text := Cmd.Text;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Paste_Clipboard =>
            Cmd2.Kind := Editor.Command_Kinds.Buffer_Switcher_Insert_Text;
            Cmd2.Text := Editor.Executor.Clipboard.Text_For_Local_Input;
            Execute_Command (Cmd2);
            return True;

         when Editor.Command_Kinds.Move_Up =>
            Execute (Editor.Command_Ids.Command_Buffer_Switcher_Previous_Result);
            return True;

         when Editor.Command_Kinds.Move_Down =>
            Execute (Editor.Command_Ids.Command_Buffer_Switcher_Next_Result);
            return True;

         when Editor.Command_Kinds.Move_Left =>
            Editor.Buffer_Switcher.Move_Cursor_Left (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Right =>
            Editor.Buffer_Switcher.Move_Cursor_Right (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_Home | Editor.Command_Kinds.Move_Line_Start =>
            Editor.Buffer_Switcher.Move_Cursor_Start (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Move_End | Editor.Command_Kinds.Move_Line_End =>
            Editor.Buffer_Switcher.Move_Cursor_End (S.Buffer_Switcher);
            Editor.Render_Cache.Invalidate_All;
            return True;

         when Editor.Command_Kinds.Palette_Accept | Editor.Command_Kinds.Accept_Buffer_Switcher =>
            Execute (Editor.Command_Ids.Command_Accept_Buffer_Switcher);
            return True;

         when Editor.Command_Kinds.Palette_Cancel | Editor.Command_Kinds.Close_Buffer_Switcher =>
            Execute (Editor.Command_Ids.Command_Close_Buffer_Switcher);
            return True;

         when others =>
            null;
      end case;

      return True;
   end Handle_Buffer_Switcher;

end Editor.Input_Bridge.Buffer_Switcher_Handlers;
