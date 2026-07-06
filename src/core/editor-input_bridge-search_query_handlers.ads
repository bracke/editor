with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Search_Query_Handlers is

   function Handle_Search_Query_Input
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean;

end Editor.Input_Bridge.Search_Query_Handlers;
