with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Diagnostics_Suppressed_Commands is

   function Diagnostics_Suppressed_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Execute_Diagnostics_Suppressed_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Diagnostics_Suppressed_Commands;
