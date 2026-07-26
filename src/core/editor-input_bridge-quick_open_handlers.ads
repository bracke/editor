with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Quick_Open_Handlers is

   function Handle_Quick_Open
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command)) return Boolean;

end Editor.Input_Bridge.Quick_Open_Handlers;
