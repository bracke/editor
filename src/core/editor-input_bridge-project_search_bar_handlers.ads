with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Project_Search_Bar_Handlers is

   function Handle_Project_Search_Bar
     (S               : in out Editor.State.State_Type;
      Cmd             : Editor.Commands.Command;
      Execute         : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Execute_Command : not null access procedure
        (Command : Editor.Commands.Command);
      Sync_Replace_Mode : not null access procedure) return Boolean;

end Editor.Input_Bridge.Project_Search_Bar_Handlers;
