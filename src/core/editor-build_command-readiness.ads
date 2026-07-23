with Editor.Commands;
with Editor.External_Producers;
with Editor.State;

package Editor.Build_Command.Readiness is

   function Build_Run_Readiness
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status;

   function Build_Run_Unavailable_Reason
     (Status : Build_Run_Readiness_Status) return String;

   function Build_Run_Recovery_Hint
     (Status : Build_Run_Readiness_Status) return String;

   function Build_Run_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Command_Availability;

   function Has_Active_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean;

   function Build_Cancel_Availability
     (State : Editor.State.State_Type) return Editor.Commands.Command_Availability;

   function Validate_Build_Run_Invocation
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status;

   function Build_Run_Execution_Gate
     (State : Editor.State.State_Type)
      return Editor.External_Producers.Build_Execution_Gate;

end Editor.Build_Command.Readiness;
