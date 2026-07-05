with Editor.Command_Execution;
with Editor.Commands;
with Editor.External_Producers;
with Editor.State;

package Editor.Executor.Terminal_Commands is

   function Terminal_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Ensure_Terminal_Project_Tasks
     (S : in out Editor.State.State_Type);

   function Terminal_Process_Status_Message
     (Status : Editor.External_Producers.Process_Run_Status) return String;

   function Execute_Project_Task_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   function Execute_Terminal_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Terminal_Commands;
