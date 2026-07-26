with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers is

   type Execute_Command_Access is not null access procedure
     (Id : Editor.Command_Ids.Command_Id);

   function Handle_Feature_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command) return Boolean;

   function Handle_Problems_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Payloads.Command;
      Execute : Execute_Command_Access) return Boolean;

end Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers;
