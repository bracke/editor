with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Kind_Diagnostics_Commands is

   function Try_Execute_Diagnostics_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Executor.Command_Kind_Diagnostics_Commands;
