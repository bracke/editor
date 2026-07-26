with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Diagnostics_Action_Commands is

   function Execute_Diagnostics_Action_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Diagnostics_Action_Commands;
