package Editor.Missing_Stale_Recovery.Execution_Policies is

   function Invocation_Source_May_Carry_Target_Payload
     (Source : Command_Invocation_Source) return Boolean;

   function Invocation_Source_May_Execute_Recovery_Command
     (Source : Command_Invocation_Source) return Boolean;

   function Recovery_Trigger_May_Probe_Filesystem
     (Trigger : Recovery_Trigger_Kind) return Boolean;

   function Recovery_Trigger_May_Mutate_State
     (Trigger : Recovery_Trigger_Kind) return Boolean;

   function Recovery_Trigger_May_Persist_Recovery_State
     (Trigger : Recovery_Trigger_Kind) return Boolean;

   function Recovery_Trigger_May_Auto_Refresh
     (Trigger : Recovery_Trigger_Kind) return Boolean;

   function Target_Path_Identity_Matches
     (Expected_Path : String; Actual_Path : String) return Boolean;

   function Missing_Target_May_Be_Auto_Remapped return Boolean;

   function Validation_Phase_May_Probe_Filesystem
     (Phase : Target_Validation_Phase) return Boolean;

   function Validation_Phase_May_Mutate_State
     (Phase : Target_Validation_Phase) return Boolean;

   function Validation_Phase_May_Authorize_Target_Use
     (Phase : Target_Validation_Phase) return Boolean;

   function Validation_Phase_May_Reuse_Cached_Target_Result
     (Phase : Target_Validation_Phase) return Boolean;

   function Execution_Revalidation_Required
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean;

   function Cached_Target_Validation_May_Be_Applied
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean;

   function Execution_Revalidation_Message
     (Surface : Target_Surface) return String;

   function Command_Outcome_Count_For_Validation
     (Result : Target_Validation_Result) return Natural;

   function Command_Outcome_Is_User_Readable
     (Result : Target_Validation_Result) return Boolean;

   function Surface_Recovery_Label
     (Surface : Target_Surface; State : Target_Availability_State) return String;

   function Staleness_Reason_Label
     (Reason : Target_Staleness_Reason) return String;

   function Staleness_Reason_May_Be_Persisted
     (Reason : Target_Staleness_Reason) return Boolean;

   function Staleness_Reason_Requires_Explicit_Recovery
     (Reason : Target_Staleness_Reason) return Boolean;

   function Validate_Staleness_Provenance
     (Surface : Target_Surface;
      Reason  : Target_Staleness_Reason) return Target_Validation_Result;

   function Project_Scope_Identity_Matches
     (Expected_Project_Root : String;
      Actual_Project_Root   : String) return Boolean;

   function Stale_Target_May_Be_Opened_From_Previous_Project return Boolean;

   function Target_Reference_Context_May_Be_Consumed
     (Context : Target_Reference_Context) return Boolean;

   function Target_Generation_State_Allows_Target_Use
     (Generation : Target_Generation_State) return Boolean;

   function Validate_Target_Reference_For_Execution
     (Surface    : Target_Surface;
      Context    : Target_Reference_Context;
      Generation : Target_Generation_State) return Target_Validation_Result;

   function Recovery_Message_Content_Allowed
     (Content : Recovery_Message_Content) return Boolean;

   function Outcome_Message_May_Embed_Target_Path
     (Result : Target_Validation_Result) return Boolean;

   function Outcome_Message_May_Expose_Internal_Enum
     (Result : Target_Validation_Result) return Boolean;

   function Target_Result_Message_Is_Payload_Free
     (Result : Target_Validation_Result) return Boolean;

end Editor.Missing_Stale_Recovery.Execution_Policies;
