with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Build_Commands is

   function Build_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_Build_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Build_Commands;
