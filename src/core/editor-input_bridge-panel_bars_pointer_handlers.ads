with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Panel_Bars_Pointer_Handlers is

   type Execute_Command_Access is not null access procedure
     (Id : Editor.Commands.Command_Id);

   function Handle_Pending_Transition_Bar_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : Execute_Command_Access) return Boolean;

   function Handle_Tab_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Status_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Panel_Splitter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Input_Bridge.Panel_Bars_Pointer_Handlers;
