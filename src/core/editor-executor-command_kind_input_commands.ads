with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Kind_Input_Commands is

   function Try_Execute_Input_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Executor.Command_Kind_Input_Commands;
