package Editor.Missing_Stale_Recovery.Surface_Event_Policies is

   function Missing_Target_May_Create_Implicit_File
     (Surface : Target_Surface) return Boolean;
   function Failed_Target_Use_Preserves_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean;
   function Target_Use_Failure_May_Discard_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean;
   function Target_Validation_Failure_May_Mutate_State
     (Result : Target_Validation_Result) return Boolean;
   function Target_Validation_Failure_Disposition
     (Result : Target_Validation_Result) return Validation_Failure_Disposition;
   function Validation_Failure_Disposition_Label
     (Disposition : Validation_Failure_Disposition) return String;
   function Recovery_Command_Failed_Attempt_Clears_Stale_State
     (Command : Recovery_Command_Kind) return Boolean;

   function Stale_Target_User_Action_Hint
     (Surface : Target_Surface) return String;
   function Project_Transition_Surface_Disposition
     (Surface : Target_Surface) return String;

   function Event_Effect_On_Surface
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Surface_Event_Effect;
   function Event_Effect_Label
     (Effect : Surface_Event_Effect) return String;
   function Event_State_After
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Target_Availability_State;
   function Event_May_Create_Files
     (Event : Recovery_Event_Kind) return Boolean;
   function Event_May_Bypass_Executor
     (Event : Recovery_Event_Kind) return Boolean;
   function Surface_Event_Effect_Is_Transient
     (Effect : Surface_Event_Effect) return Boolean;

   function Recovery_Command_For_Surface
     (Surface : Target_Surface) return Recovery_Command_Kind;
   function Recovery_Command_Can_Address_Result
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean;
   function Recovery_Command_Hint_Message
     (Result : Target_Validation_Result) return String;

end Editor.Missing_Stale_Recovery.Surface_Event_Policies;
