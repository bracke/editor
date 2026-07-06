with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Quick_Open_Handlers is

   function Handle_Quick_Open
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command)) return Boolean;

end Editor.Input_Bridge.Quick_Open_Handlers;
