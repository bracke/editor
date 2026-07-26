with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Commands;
with Editor.Commands.Payloads;
with Editor.Guided_Prompts;
with Editor.Input_Bridge.Keybinding_Handlers;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Input_Bridge.Text_Entry_Dispatch is

   function Handle_Guided_Prompt_Input
     (S                          : in out Editor.State.State_Type;
      Cmd                        : Editor.Commands.Payloads.Command;
      Accept_Guided_Prompt_Enter : not null access procedure;
      Report_Info                : not null access procedure (Text : String))
      return Boolean
   is
   begin
      if not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
         return False;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            if Editor.Input_Bridge.Keybinding_Handlers
              .Consume_Keybinding_Text_Input (S.Guided_Prompt, Cmd)
            then
               null;
            elsif Cmd.Ch = ASCII.LF or else Cmd.Ch = ASCII.CR then
               Accept_Guided_Prompt_Enter.all;
            elsif Cmd.Ch = ASCII.ESC then
               Editor.Guided_Prompts.Cancel (S.Guided_Prompt);
               Report_Info.all ("Prompt cancelled.");
            elsif Length (Cmd.Text) > 0 then
               Editor.Guided_Prompts.Insert_Text
                 (S.Guided_Prompt, To_String (Cmd.Text));
            elsif Cmd.Ch /= ASCII.NUL then
               Editor.Guided_Prompts.Insert_Text
                 (S.Guided_Prompt, String'(1 => Cmd.Ch));
            end if;
         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            Editor.Guided_Prompts.Backspace (S.Guided_Prompt);
         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            Editor.Guided_Prompts.Delete_Forward (S.Guided_Prompt);
         when Editor.Commands.Split_Current_Line_At_Caret =>
            Accept_Guided_Prompt_Enter.all;
         when others =>
            null;
      end case;

      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Guided_Prompt_Input;

end Editor.Input_Bridge.Text_Entry_Dispatch;
