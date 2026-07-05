with Editor.Keybindings;

package Editor.Input_Bridge.Keybinding_Handlers is

   function Handle_Keybinding_Chord
     (Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean;

end Editor.Input_Bridge.Keybinding_Handlers;
