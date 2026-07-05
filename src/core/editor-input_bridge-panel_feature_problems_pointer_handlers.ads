with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers is

   type Execute_Command_Access is not null access procedure
     (Id : Editor.Commands.Command_Id);

   function Handle_Feature_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Problems_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access) return Boolean;

end Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers;
