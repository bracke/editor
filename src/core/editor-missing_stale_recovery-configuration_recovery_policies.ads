package Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies is

   function Snapshot_Status_Is_Transient
     (Result : Target_Validation_Result) return Boolean;
   function Snapshot_Status_May_Be_Persisted
     (Result : Target_Validation_Result) return Boolean;
   function Snapshot_Status_May_Probe_Filesystem return Boolean;

   function Recovery_Command_No_Op_Message
     (Command : Recovery_Command_Kind) return String;

   function Command_Availability_When_Confirmation_Pending
     (Surface : Target_Surface) return Target_Validation_Result;
   function Recovery_Command_Available_With_Confirmation_Pending
     (Command : Recovery_Command_Kind) return Boolean;
   function Forbidden_Recovery_Mechanism_Allowed
     (Mechanism : Forbidden_Recovery_Mechanism) return Boolean;
   function Transient_Surface_Field_May_Be_Persisted
     (Field : Transient_Surface_Field) return Boolean;

   function Workspace_Recovery_Primary_Outcome_Count
     (Summary : Workspace_Recovery_Summary) return Natural;
   function Workspace_Recovery_Summary_May_Be_Persisted
     (Summary : Workspace_Recovery_Summary) return Boolean;
   function Availability_Check_May_Write_Persistence return Boolean;
   function Availability_Check_May_Clear_Stale_State return Boolean;
   function Render_Snapshot_May_Clear_Stale_State return Boolean;
   function Recovery_Command_May_Clear_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Source  : Command_Invocation_Source) return Boolean;
   function Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind) return Boolean;

end Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies;
