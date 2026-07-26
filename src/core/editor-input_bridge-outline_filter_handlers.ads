with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Outline_Filter_Handlers is

   function Handle_Outline_Filter_Input
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Payloads.Command;
      Execute : not null access procedure
        (Id : Editor.Command_Ids.Command_Id)) return Boolean;

end Editor.Input_Bridge.Outline_Filter_Handlers;
