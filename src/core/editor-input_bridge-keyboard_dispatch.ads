with Editor.Commands;
with Editor.Commands.Payloads;
with Editor.Instance;
with Editor.Keybindings;

package Editor.Input_Bridge.Keyboard_Dispatch is

   procedure Handle_Key_Chord
     (Instance                   : in out Editor.Instance.Editor_Instance;
      Initialized                : Boolean;
      Chord                      : Editor.Keybindings.Key_Chord;
      Accept_Guided_Prompt_Enter : not null access procedure;
      Report_Info                : not null access procedure (Text : String);
      Handle_Command_Palette     : not null access function
        (Cmd : Editor.Commands.Payloads.Command) return Boolean;
      Execute_Command_Id         : not null access procedure
        (Id : Editor.Commands.Command_Id; Shift : Boolean));

end Editor.Input_Bridge.Keyboard_Dispatch;
