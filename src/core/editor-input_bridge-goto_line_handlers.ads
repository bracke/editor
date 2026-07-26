with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Goto_Line_Handlers is

   function Handle_Goto_Line
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command)) return Boolean;

end Editor.Input_Bridge.Goto_Line_Handlers;
