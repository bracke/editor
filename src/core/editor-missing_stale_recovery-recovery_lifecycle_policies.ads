package Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies is

   function Recovery_Attempt_Disposition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_State_Disposition;
   function Recovery_Attempt_Outcome_Label
     (Outcome : Recovery_Attempt_Outcome) return String;
   function Recovery_Attempt_May_Clear_State
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean;
   function Recovery_Attempt_Message_May_Embed_Path
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean;
   function Recovery_Attempt_Produces_One_Primary_Outcome
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean;
   function Recovery_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean;

   function Recovery_Command_Effect_Allowed
     (Command : Recovery_Command_Kind;
      Effect  : Recovery_Command_Effect_Kind;
      Source  : Command_Invocation_Source := Invocation_Executor) return Boolean;
   function Recovery_Command_May_Write_Persistence
     (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_May_Open_Target
     (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_May_Clear_Other_Surface
     (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_Effect_Label
     (Effect : Recovery_Command_Effect_Kind) return String;

   function Recovery_Command_Postcondition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_Postcondition;
   function Recovery_Postcondition_Label
     (Postcondition : Recovery_Postcondition) return String;
   function Recovery_Command_May_Immediately_Consume_Recovered_Target
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean;
   function Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean;

   function Stale_Surface_Lifecycle_Action_Allowed
     (Surface : Target_Surface;
      Action  : Stale_Surface_Lifecycle_Action) return Boolean;
   function Stale_Surface_Lifecycle_Action_Label
     (Action : Stale_Surface_Lifecycle_Action) return String;
   function Stale_Surface_Lifecycle_Action_Is_Transient
     (Action : Stale_Surface_Lifecycle_Action) return Boolean;
   function Stale_Surface_Lifecycle_Action_May_Use_Payload
     (Action : Stale_Surface_Lifecycle_Action) return Boolean;
   function Stale_Surface_Lifecycle_Requires_Executor_Recovery
     (Surface : Target_Surface) return Boolean;

   function Multi_Target_Command_Requires_Full_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean;
   function Multi_Target_Command_May_Mutate_Before_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean;
   function Multi_Target_Validation_Allows_Mutation
     (Summary : Multi_Target_Validation_Summary) return Boolean;
   function Multi_Target_Validation_Message
     (Summary : Multi_Target_Validation_Summary) return String;
   function Multi_Target_Validation_Message_May_Embed_Paths
     (Summary : Multi_Target_Validation_Summary) return Boolean;
   function Multi_Target_Recovery_Preserves_Existing_State_On_Failure
     (Command : Multi_Target_Command_Kind;
      Summary : Multi_Target_Validation_Summary) return Boolean;

   function Recovery_Command_May_Delete_User_File
     (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_May_Fabricate_Project_State
     (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Message_May_Embed_Target_Payload
     (Result : Target_Validation_Result) return Boolean;
   function Recovery_Message_Identifies_Surface_And_Category
     (Result : Target_Validation_Result) return Boolean;
   function Recovery_Action_Is_Safe_For_State
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean;
   function Target_State_Has_Explicit_Recovery_Path
     (Surface : Target_Surface;
      State   : Target_Availability_State) return Boolean;

end Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies;
