with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Buffer_Switcher_Handlers is

   function Handle_Buffer_Switcher
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean;

end Editor.Input_Bridge.Buffer_Switcher_Handlers;
