with Editor.Commands;
with Editor.Guided_Prompts;
with Editor.Keybindings;

package Editor.Input_Bridge.Keybinding_Handlers is

   function Handle_Keybinding_Chord
     (Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean;

   function Consume_Keybinding_Text_Input
     (Prompt : Editor.Guided_Prompts.Prompt_State;
      Cmd    : Editor.Commands.Command) return Boolean;

   function Is_Keybinding_Capture_Prompt
     (Prompt : Editor.Guided_Prompts.Prompt_State) return Boolean;

   function Handle_Keybinding_Prompt_Key
     (Prompt  : in out Editor.Guided_Prompts.Prompt_State;
      Chord   : Editor.Keybindings.Key_Chord;
      Report  : not null access procedure (Message : String)) return Boolean;

   procedure Confirm_Keybinding_Capture
     (Prompt      : in out Editor.Guided_Prompts.Prompt_State;
      Report_Info : not null access procedure (Message : String));

end Editor.Input_Bridge.Keybinding_Handlers;
