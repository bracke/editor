with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Command_Result_Commands is

   function Execute_Command_With_Result
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Command_Ids.Command_Id;
      Shift : Boolean := False)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Command_Result_Commands;
