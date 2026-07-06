with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.File_Target_Key_Handlers is

   function Handle_File_Target_Key
     (S     : in out Editor.State.State_Type;
      Chord : Editor.Keybindings.Key_Chord) return Boolean;

end Editor.Input_Bridge.File_Target_Key_Handlers;
