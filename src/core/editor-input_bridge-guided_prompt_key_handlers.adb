with Editor.Cursor;
with Editor.Input_Bridge.Keybinding_Handlers;
with Editor.Guided_Prompts;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Guided_Prompt_Key_Handlers is

   use type Editor.Keybindings.Key_Code;
   use type Editor.Guided_Prompts.Prompt_Kind;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_Guided_Prompt_Key
     (S            : in out Editor.State.State_Type;
      Chord        : Editor.Keybindings.Key_Chord;
      Accept_Enter : not null access procedure;
      Report_Info  : not null access procedure (Text : String)) return Boolean
   is
   begin
      if not Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Escape =>
            Editor.Guided_Prompts.Cancel (S.Guided_Prompt);
            Report_Info ("Prompt cancelled.");
         when Editor.Keybindings.Key_Enter =>
            Accept_Enter.all;
         when Editor.Keybindings.Key_Up =>
            Editor.Guided_Prompts.Move_File_Picker_Selection
              (S.Guided_Prompt, -1);
         when Editor.Keybindings.Key_Down =>
            Editor.Guided_Prompts.Move_File_Picker_Selection
              (S.Guided_Prompt, 1);
         when Editor.Keybindings.Key_Right =>
            if Editor.Guided_Prompts.Apply_File_Picker_Selection
              (S.Guided_Prompt)
            then
               Report_Info ("Directory selected.");
            end if;
         when Editor.Keybindings.Key_Backspace =>
            Editor.Guided_Prompts.Backspace (S.Guided_Prompt);
         when Editor.Keybindings.Key_Delete =>
            Editor.Guided_Prompts.Delete_Forward (S.Guided_Prompt);
         when others =>
            if Editor.Input_Bridge.Keybinding_Handlers
              .Handle_Keybinding_Prompt_Key
                (S.Guided_Prompt, Chord, Report_Info)
            then
               return True;
            end if;
      end case;

      Editor.Render_Cache.Invalidate_All;
      Notify_Input;
      return True;
   end Handle_Guided_Prompt_Key;

end Editor.Input_Bridge.Guided_Prompt_Key_Handlers;
