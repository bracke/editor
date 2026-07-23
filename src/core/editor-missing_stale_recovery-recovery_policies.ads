package Editor.Missing_Stale_Recovery.Recovery_Policies is

   function Workspace_Restore_Action_Fabricates_State
     (Action : Workspace_Restore_Action) return Boolean;

   function Workspace_Restore_Action_Is_Safe
     (Action : Workspace_Restore_Action) return Boolean;

   function Caret_Target_Policy
     (State : Target_Availability_State; Explicit_Clamp_Policy : Boolean)
      return String;

   function Recovery_Command_Name
     (Command : Recovery_Command_Kind) return String;

   function Recovery_Command_Is_Payload_Free
     (Command : Recovery_Command_Kind) return Boolean;

   function Recovery_Command_Is_Explicit
     (Command : Recovery_Command_Kind) return Boolean;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean;

   function Surface_Cleared_On_Project_Transition
     (Surface : Target_Surface) return Boolean;

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State;

   function Navigation_Allowed
     (Result : Target_Validation_Result) return Boolean;

   function Replace_Apply_Allowed
     (Result : Target_Validation_Result) return Boolean;

   function Build_Run_Allowed
     (Result : Target_Validation_Result) return Boolean;

   function Recovery_State_Is_Persistable
     (State : Target_Availability_State) return Boolean;

   function Persistence_Field_Allowed
     (Surface : Target_Surface;
      State   : Target_Availability_State) return Boolean;

   function Render_May_Probe_Targets return Boolean;

   function Render_May_Repair_Targets return Boolean;

   function Availability_May_Repair_Targets return Boolean;

   function Recovery_Command_May_Run_From_Render
     (Command : Recovery_Command_Kind) return Boolean;

   function Recovery_Command_May_Run_From_Availability
     (Command : Recovery_Command_Kind) return Boolean;

   function Recovery_Command_May_Bypass_Dirty_Guards
     (Command : Recovery_Command_Kind) return Boolean;

   function Command_Availability_When_No_Selection
     (Surface : Target_Surface) return Target_Validation_Result;

   function Recovery_Command_Routes_Through_Executor
     (Command : Recovery_Command_Kind) return Boolean;

end Editor.Missing_Stale_Recovery.Recovery_Policies;
