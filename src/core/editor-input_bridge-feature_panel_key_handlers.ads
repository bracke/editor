with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Feature_Panel_Key_Handlers is

   function Handle_Feature_Panel_Key
     (S       : in out Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Command_Ids.Command_Id)) return Boolean;

end Editor.Input_Bridge.Feature_Panel_Key_Handlers;
