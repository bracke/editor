with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Project_Search_Bar_Handlers is

   function Handle_Project_Search_Bar
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Payloads.Command;
      Execute         : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Payloads.Command);
      Sync_Replace_Mode : not null access procedure) return Boolean;

end Editor.Input_Bridge.Project_Search_Bar_Handlers;
