with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Feature_Panel_Key_Handlers is

   function Handle_Feature_Panel_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean;

end Editor.Input_Bridge.Feature_Panel_Key_Handlers;
