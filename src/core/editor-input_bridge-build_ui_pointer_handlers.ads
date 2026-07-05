with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Build_UI_Pointer_Handlers is

   type Execute_Command_Access is not null access procedure
     (Id : Editor.Commands.Command_Id);

   type Report_Info_Access is not null access procedure
     (Message : String);

   function Handle_Build_UI_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access;
      Report  : Report_Info_Access) return Boolean;

end Editor.Input_Bridge.Build_UI_Pointer_Handlers;
