package Editor.Missing_Stale_Recovery.Target_Use_Policies is

   function Target_State_Blocks_Use
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean;

   function Target_Use_May_Proceed
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return Boolean;

   function Target_Use_Blocking_Message
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return String;

   function Target_Use_Failure_Requires_Recovery_Command
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean;

   function Target_Use_Requires_Execution_Validation
     (Use_Kind : Target_Use_Kind) return Boolean;

   function Target_Use_May_Auto_Refresh
     (Use_Kind : Target_Use_Kind) return Boolean;

end Editor.Missing_Stale_Recovery.Target_Use_Policies;
