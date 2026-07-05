with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Result_Commands is

   function Execute_Command_With_Result
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Command_Result_Commands;
