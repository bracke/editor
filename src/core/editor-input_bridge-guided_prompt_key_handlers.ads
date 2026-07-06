with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Guided_Prompt_Key_Handlers is

   function Handle_Guided_Prompt_Key
     (S            : in out Editor.State.State_Type;
      Chord        : Editor.Keybindings.Key_Chord;
      Accept_Enter : not null access procedure;
      Report_Info  : not null access procedure (Text : String)) return Boolean;

end Editor.Input_Bridge.Guided_Prompt_Key_Handlers;
