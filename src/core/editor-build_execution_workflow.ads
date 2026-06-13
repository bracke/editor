with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.External_Producers;
with Editor.State;

package Editor.Build_Execution_Workflow is

   --  Phase 555 end-to-end Build execution workflow assertions.  This package
   --  is deliberately audit/coherence focused: it owns no runner, no terminal,
   --  no job queue, no history, no rerun payload, no Diagnostics rows, and no
   --  persistence state.  It verifies that the retained Build command path can
   --  execute only structured, consented requests through the existing gated
   --  process/producer boundary and that latest summary/output/diagnostic
   --  projections remain transient and display-only.

   function Assert_Build_Run_Requires_Valid_Consented_Request
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Run_Uses_Structured_Tokens
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean;

   function Assert_Build_Run_Does_Not_Use_Shell_Text
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean;

   function Assert_Build_Output_Is_Bounded
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean;

   function Assert_Build_Result_Summary_Reflects_Runner_Status
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean;

   function Assert_Build_Diagnostics_Owned_By_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Render_Does_Not_Run_Or_Parse
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Result_Output_Not_Persisted
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Keybindings_Have_No_Run_Payloads return Boolean;

   function Assert_Build_Command_Surface_Has_No_Execution_Payloads
      return Boolean;

   function Assert_Build_Execution_No_Transient_Persistence_Fields
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Disabled_Does_Not_Ingest
     (Result : Editor.External_Producers.Build_Command_Result) return Boolean;

   function Assert_Build_Cancel_Advertised_With_Active_Job_Model
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Run_Unavailable_Reasons_Complete return Boolean;

   function Assert_Build_Latest_Result_Replaces_Attempt
     (Before : Editor.Build_Result_Summary.Latest_Build_Result_Summary;
      After  : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean;

   function Assert_Build_Preflight_Result_Has_No_Diagnostics
     (Result : Editor.External_Producers.Build_Command_Result) return Boolean;

   function Assert_Build_Preflight_Preserves_Request_Surface
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type) return Boolean;

   function Assert_Build_Run_Gate_Consent_Matches_Preflight
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Preflight_Failure_Is_Non_Destructive
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.External_Producers.Build_Command_Result) return Boolean;

   function Assert_Build_Execution_Workflow_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Build_Execution_Workflow;
