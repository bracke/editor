with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Quick_Open_Key_Handlers is

   function Handle_Quick_Open_Key
     (S               : in out Editor.State.State_Type;
      Chord           : Editor.Keybindings.Key_Chord;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean;

end Editor.Input_Bridge.Quick_Open_Key_Handlers;
