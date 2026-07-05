with Editor.Commands;
with Editor.External_Producers;
with Editor.Build_Output_Details;
with Editor.Build_Process_Control;
with Editor.State;

package Editor.Build_Command is

   --  public build command bounded runner foundation.  Readiness is
   --  side-effect-free; execution remains Executor-owned and can reach only the
   --  bounded non-shell process-runner seam after structured request, current
   --  consent, explicit transient working context, and runtime policy checks.

   type Build_Run_Readiness_Status is
     (Build_Run_Readiness_Ready,
      Build_Run_Readiness_No_Project_Open,
      Build_Run_Readiness_No_Candidate_Selected,
      Build_Run_Readiness_Selected_Candidate_Stale,
      Build_Run_Readiness_Candidate_File_Missing,
      Build_Run_Readiness_Request_Incomplete,
      Build_Run_Readiness_Tool_Required,
      Build_Run_Readiness_Arguments_Invalid,
      Build_Run_Readiness_Working_Context_Required,
      Build_Run_Readiness_Working_Context_Unavailable,
      Build_Run_Readiness_Working_Context_Invalid,
      Build_Run_Readiness_Consent_Required,
      Build_Run_Readiness_Consent_Stale,
      Build_Run_Readiness_Execution_Backend_Disabled,
      Build_Run_Readiness_Job_Already_Active);

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

   procedure Begin_Public_Build_Job
     (State : in out Editor.State.State_Type;
      Label : String);

   procedure Register_Public_Build_Process
     (State  : in out Editor.State.State_Type;
      Handle : Editor.Build_Process_Control.Build_Process_Handle);

   procedure Register_Public_Build_Test_Process
     (State : in out Editor.State.State_Type);

   procedure Complete_Public_Build_Job
     (State : in out Editor.State.State_Type);

   function Request_Public_Build_Cancel
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result;

   function Request_Public_Build_Lifecycle_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Command_Result;

   function Drain_Public_Build_Worker_For_Shutdown
     (State  : in out Editor.State.State_Type;
      Reason : String)
      return Editor.External_Producers.Build_Command_Result;

   procedure Stop_Public_Build_Workers_For_Application_Exit;

   procedure Append_Public_Build_Output_Chunk
     (State : in out Editor.State.State_Type;
      Output_Stream : Editor.Build_Output_Details.Build_Output_Stream_Selection;
      Text : String);

   procedure Complete_Public_Build_Output_Stream
     (State : in out Editor.State.State_Type;
      Runner_Status : Editor.Build_Output_Details.Build_Output_Runner_Status;
      Exit_Code : Integer := 0;
      Has_Exit_Code : Boolean := False);

   function Validate_Build_Run_Invocation
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status;

   function Build_Run_Execution_Gate
     (State : Editor.State.State_Type)
      return Editor.External_Producers.Build_Execution_Gate;

   function Execute_Public_Build_Run
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result;

   function Start_Public_Build_Run_Asynchronously
     (State : in out Editor.State.State_Type)
      return Editor.External_Producers.Build_Command_Result;

   function Poll_Public_Build_Run_Completion
     (State : in out Editor.State.State_Type;
      Result : out Editor.External_Producers.Build_Command_Result) return Boolean;

   function Has_Queued_Public_Build_Job
     (State : Editor.State.State_Type) return Boolean;

   --  deterministic dogfood seam: execute the same public build.run
   --  frontdoor and state-update path as Execute_Public_Build_Run, but with a
   --  caller-supplied bounded process result.  This is for workflow fixtures
   --  that must prove Build -> Output Details -> Diagnostics integration
   --  without depending on host gprbuild/alr availability.
   function Execute_Public_Build_Run_With_Supplied_Result
     (State           : in out Editor.State.State_Type;
      Supplied_Result : Editor.External_Producers.Process_Run_Result)
      return Editor.External_Producers.Build_Command_Result;

   function Assert_Build_Run_Descriptor_Stable return Boolean;
   function Assert_Build_Run_Routes_Through_Executor
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Build_Run_Availability_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Build_Cancel_Command_Descriptor_Stable return Boolean;
   function Assert_Build_Cancel_Requires_Active_Job
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Build_Run_Command_Palette_Boundary
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Build_Run_Keybinding_Boundary return Boolean;
   function Assert_Build_Run_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Public_Build_Command_Registration_Coherent
     (State : Editor.State.State_Type) return Boolean;
   function Assert_Async_Build_Cancel_Handoff_Behavior return Boolean;
   function Assert_Async_Build_Output_Snapshot_Handoff_Behavior return Boolean;
   function Assert_Async_Build_Partial_Stdout_Stderr_Before_Completion
     return Boolean;
   function Assert_Async_Build_Real_Process_Cancel_Integration
     return Boolean;
   function Assert_Async_Build_Lifecycle_Shutdown_Handoff_Behavior
     return Boolean;
   function Assert_Async_Build_Worker_Shutdown_Drain_Behavior
     return Boolean;
   function Assert_Async_Build_State_Slots_Are_Isolated
     return Boolean;
   function Assert_Async_Build_Slot_Id_Is_Stable_Per_State
     return Boolean;
   function Assert_Async_Build_Slot_Pool_Exhaustion_Is_Rejected
     return Boolean;
   function Assert_Async_Build_Worker_Stop_Terminates_Pool_Behavior
     return Boolean;

end Editor.Build_Command;
