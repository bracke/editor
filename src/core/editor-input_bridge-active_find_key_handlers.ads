with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Active_Find_Key_Handlers is

   function Handle_Active_Find_Key
     (S                : Editor.State.State_Type;
      Chord            : Editor.Keybindings.Key_Chord;
      Execute_Previous : not null access procedure;
      Hide             : not null access procedure) return Boolean;

end Editor.Input_Bridge.Active_Find_Key_Handlers;
