with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Diagnostics_Action_Commands is

   function Execute_Diagnostics_Action_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Diagnostics_Action_Commands;
