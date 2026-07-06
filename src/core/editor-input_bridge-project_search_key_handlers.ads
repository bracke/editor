with Editor.Commands;
with Editor.Keybindings;
with Editor.State;

package Editor.Input_Bridge.Project_Search_Key_Handlers is

   function Handle_Project_Search_Bar_Key
     (S               : in out Editor.State.State_Type;
      Chord           : Editor.Keybindings.Key_Chord;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean;

end Editor.Input_Bridge.Project_Search_Key_Handlers;
