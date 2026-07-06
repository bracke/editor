with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers is

   function Handle_Suppressed_Diagnostics_Key
     (S           : in out Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Report_Info : not null access procedure (Text : String)) return Boolean;

end Editor.Input_Bridge.Diagnostics_Focus_Key_Handlers;
