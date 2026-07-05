with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Settings_Handlers is

   function Handle_Settings_Chord
     (S      : in out Editor.State.State_Type;
      Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean;

end Editor.Input_Bridge.Settings_Handlers;
