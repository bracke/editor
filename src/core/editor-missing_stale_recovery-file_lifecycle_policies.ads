package Editor.Missing_Stale_Recovery.File_Lifecycle_Policies is

   function Workspace_Load_May_Restore_Unsaved_Text return Boolean;
   function Project_Transition_May_Discard_Dirty_Buffer return Boolean;
   function Recovery_Command_Requires_Dirty_Guard
     (Command : Recovery_Command_Kind) return Boolean;

   function Buffer_Known_Missing_State_Allowed
     (Dirty : Boolean; State : Target_Availability_State) return Boolean;

   function Validate_Buffer_Access_State
     (Path           : String;
      Target_Exists  : Boolean;
      Ordinary_File  : Boolean;
      Readable       : Boolean;
      Writable       : Boolean;
      Require_Read   : Boolean := False;
      Require_Write  : Boolean := False) return Target_Validation_Result;

   function Validate_File_Target
     (Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result;

   function Validate_Project_File_Target
     (Project_Root  : String;
      Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result;

   function Validate_Buffer_Backing_File_Target
     (Path  : String;
      Dirty : Boolean := False) return Target_Validation_Result;

   function Validate_Save_Target
     (Path : String) return Target_Validation_Result;

   function Validate_Reveal_Target
     (Path         : String;
      Project_Root : String := "") return Target_Validation_Result;

   function Dirty_Buffer_Text_Preserved_On
     (State : Target_Availability_State) return Boolean;
   function Dirty_State_Preserved_On
     (State : Target_Availability_State) return Boolean;

   function Validate_Line_Column_Target
     (Line             : Natural;
      Column           : Natural;
      Last_Line        : Natural;
      Last_Line_Column : Natural) return Target_Validation_Result;

end Editor.Missing_Stale_Recovery.File_Lifecycle_Policies;
