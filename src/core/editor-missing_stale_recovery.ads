with Ada.Strings.Unbounded;

package Editor.Missing_Stale_Recovery is

   type Target_Availability_State is
     (Target_Available,
      Target_Missing,
      Target_Parent_Directory_Missing,
      Target_Unreadable,
      Target_Unwritable,
      Target_Outside_Project,
      Target_Stale,
      Target_Line_Out_Of_Range,
      Target_Column_Out_Of_Range,
      Target_Source_Less,
      Target_Refresh_Required,
      Target_Reload_Required,
      Target_Working_Directory_Missing,
      Target_Candidate_Stale,
      Target_Preview_Stale,
      Target_No_Result_Selected,
      Target_No_Diagnostic_Selected,
      Target_No_Build_Candidate_Selected,
      Target_Command_Pending);

   type Target_Surface is
     (Workspace_Surface,
      Recent_Project_Surface,
      Buffer_Surface,
      File_Tree_Surface,
      Quick_Open_Surface,
      Project_Search_Surface,
      Replace_Preview_Surface,
      Outline_Surface,
      Diagnostics_Surface,
      Build_Surface);

   type Target_Validation_Result is record
      State   : Target_Availability_State := Target_Available;
      Surface : Target_Surface := Buffer_Surface;
      Path    : Ada.Strings.Unbounded.Unbounded_String;
      Line    : Natural := 0;
      Column  : Natural := 0;
   end record;

   type Recovery_Command_Kind is
     (Recovery_Workspace_Load,
      Recovery_Recent_Projects_Remove_Missing,
      Recovery_File_Reload_From_Disk,
      Recovery_File_Revert_Buffer,
      Recovery_File_Reveal_Active_In_Tree,
      Recovery_File_Tree_Refresh,
      Recovery_Quick_Open_Clear_Query,
      Recovery_Project_Search_Run,
      Recovery_Project_Search_Clear_Results,
      Recovery_Project_Search_Replace_Clear_Preview,
      Recovery_Outline_Refresh,
      Recovery_Diagnostics_Clear,
      Recovery_Build_Refresh_Candidates);


   type Workspace_Restore_Action is
     (Workspace_Reopen_File,
      Workspace_Skip_Missing_File,
      Workspace_Restore_Active_File,
      Workspace_Fallback_To_First_Available_File,
      Workspace_Ignore_Missing_Expanded_Path,
      Workspace_Clamp_Caret_Target,
      Workspace_Ignore_Caret_Target,
      Workspace_Reject_Fabricated_Project,
      Workspace_Reject_Fabricated_Buffer);

   type Command_Invocation_Source is
     (Invocation_Executor,
      Invocation_Command_Palette,
      Invocation_Keybinding,
      Invocation_Render,
      Invocation_Availability);

   type Recovery_Trigger_Kind is
     (Trigger_User_Executor_Command,
      Trigger_Render_Snapshot,
      Trigger_Availability_Check,
      Trigger_Background_Watcher,
      Trigger_Workspace_Save,
      Trigger_Command_Palette_View,
      Trigger_Keybinding_Resolution);

   type Target_Validation_Phase is
     (Validation_Snapshot_Projection,
      Validation_Availability_Check,
      Validation_Command_Execution,
      Validation_Persistence_Save);


   type File_Tree_Mutation_Kind is
     (File_Tree_Activate_Node,
      File_Tree_Create_File,
      File_Tree_Rename_Node,
      File_Tree_Delete_Node);

   type Workspace_Active_File_Fallback is
     (Workspace_Use_Restored_Active_File,
      Workspace_Use_First_Reopened_File,
      Workspace_No_Active_File);


   type Target_Staleness_Reason is
     (Staleness_None,
      Staleness_Snapshot_Generation_Mismatch,
      Staleness_Project_Identity_Mismatch,
      Staleness_File_Content_Changed,
      Staleness_Target_Path_Missing,
      Staleness_Target_Line_Changed,
      Staleness_Candidate_Identity_Changed,
      Staleness_User_Cleared_Surface);

   type Target_Use_Kind is
     (Use_Open_Target,
      Use_Save_Target,
      Use_Reload_Target,
      Use_Revert_Target,
      Use_Reveal_Target,
      Use_Navigate_Target,
      Use_Apply_Replace_Target,
      Use_Run_Build_Target);



   type Target_Reference_Context is
     (Reference_Current_Project,
      Reference_Previous_Project,
      Reference_Project_Closed,
      Reference_Unknown_Project);

   type Target_Generation_State is
     (Generation_Current,
      Generation_Stale,
      Generation_Missing,
      Generation_Unknown);

   type Recovery_Message_Content is
     (Recovery_Message_Surface_Category,
      Recovery_Message_Counts_Only,
      Recovery_Message_Target_Path,
      Recovery_Message_Target_Line,
      Recovery_Message_Internal_Enum);

   type Recovery_Event_Kind is
     (Event_Buffer_Edited,
      Event_Buffer_Reloaded,
      Event_Project_Switched,
      Event_Project_Closed,
      Event_File_Tree_Refreshed,
      Event_Quick_Open_Requeried,
      Event_Project_Search_Rerun,
      Event_Replace_Preview_Cleared,
      Event_Outline_Refreshed,
      Event_Diagnostics_Cleared,
      Event_Build_Candidates_Refreshed);

   type Surface_Event_Effect is
     (Surface_Unchanged,
      Surface_Marked_Stale,
      Surface_Cleared,
      Surface_Replaced,
      Surface_Ignored);

   type Validation_Failure_Disposition is
     (Failure_Preserves_Surface_State,
      Failure_Marks_Surface_Stale,
      Failure_Clears_Nothing);

   type Recovery_Attempt_Outcome is
     (Recovery_Not_Attempted,
      Recovery_Succeeded,
      Recovery_Failed,
      Recovery_Cancelled);

   type Recovery_State_Disposition is
     (Recovery_State_Unchanged,
      Recovery_State_Cleared,
      Recovery_State_Replaced,
      Recovery_State_Marked_Stale);


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
   function Workspace_Load_May_Restore_Unsaved_Text return Boolean;
   function Project_Transition_May_Discard_Dirty_Buffer return Boolean;
   function Recovery_Command_Requires_Dirty_Guard
     (Command : Recovery_Command_Kind) return Boolean;
   function Snapshot_Status_Is_Transient
     (Result : Target_Validation_Result) return Boolean;
   function Snapshot_Status_May_Be_Persisted
     (Result : Target_Validation_Result) return Boolean;
   function Snapshot_Status_May_Probe_Filesystem return Boolean;

   type Recovery_Persistence_Field is
     (Persist_Workspace_Structural_Reference,
      Persist_Recent_Project_Reference,
      Persist_Settings_Global_Preference,
      Persist_Keybinding_Command_Name,
      Persist_Stale_Target_Payload,
      Persist_Recovery_Command_Payload,
      Persist_Missing_Target_Cache,
      Persist_Validated_Target_Cache,
      Persist_Command_Outcome_Message,
      Persist_Surface_Stale_Selection);

   type Forbidden_Recovery_Mechanism is
     (Forbidden_Filesystem_Watcher,
      Forbidden_Background_Refresh,
      Forbidden_Autosave_Recovery,
      Forbidden_External_File_Manager,
      Forbidden_Shell_Execution,
      Forbidden_Terminal,
      Forbidden_LSP_Recovery,
      Forbidden_New_Persistence_Domain,
      Forbidden_Command_Palette_Target_Payload,
      Forbidden_Keybinding_Target_Payload);

   type Transient_Surface_Field is
     (Transient_File_Tree_Stale_Selection,
      Transient_Quick_Open_Results,
      Transient_Project_Search_Results,
      Transient_Replace_Preview_Targets,
      Transient_Outline_Rows,
      Transient_Outline_Current_Symbol,
      Transient_Diagnostics_Filter,
      Transient_Diagnostics_Selection,
      Transient_Diagnostics_Stale_Projection,
      Transient_Build_Candidates,
      Transient_Build_Request,
      Transient_Build_Consent,
      Transient_Build_Result,
      Transient_Build_Output);


   type Replace_Apply_Validation_Summary is record
      Applied_Targets      : Natural := 0;
      Missing_Targets      : Natural := 0;
      Stale_Targets        : Natural := 0;
      Out_Of_Range_Targets : Natural := 0;
   end record;

   type Workspace_Recovery_Summary is record
      Project_Missing       : Boolean := False;
      Missing_Open_Files    : Natural := 0;
      Active_File_Missing   : Boolean := False;
      Ignored_Expanded_Paths : Natural := 0;
      Invalid_Caret_Targets : Natural := 0;
      Fabricated_Project    : Boolean := False;
      Fabricated_Buffer     : Boolean := False;
   end record;

   function Label (State : Target_Availability_State) return String;
   function Outcome_Label (Result : Target_Validation_Result) return String;
   function Target_Outcome_Message (Result : Target_Validation_Result) return String;
   function Render_Marker_Label (Result : Target_Validation_Result) return String;
   function Availability_Reason (State : Target_Availability_State) return String;
   function Surface_Label (Surface : Target_Surface) return String;
   function Workspace_Recovery_Message (Summary : Workspace_Recovery_Summary) return String;
   function Recent_Project_Recovery_Message
     (Missing_Count : Natural; Removed_Count : Natural) return String;
   function Workspace_Restore_Action_Is_Safe
     (Action : Workspace_Restore_Action) return Boolean;
   function Workspace_Restore_Action_Fabricates_State
     (Action : Workspace_Restore_Action) return Boolean;
   function Caret_Target_Policy
     (State : Target_Availability_State; Explicit_Clamp_Policy : Boolean) return String;
   function Recovery_Command_Name (Command : Recovery_Command_Kind) return String;
   function Recovery_Command_Is_Payload_Free (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_Is_Explicit (Command : Recovery_Command_Kind) return Boolean;
   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean;
   function Surface_Cleared_On_Project_Transition
     (Surface : Target_Surface) return Boolean;
   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State;
   function Navigation_Allowed (Result : Target_Validation_Result) return Boolean;
   function Replace_Apply_Allowed (Result : Target_Validation_Result) return Boolean;
   function Build_Run_Allowed (Result : Target_Validation_Result) return Boolean;
   function Recovery_State_Is_Persistable (State : Target_Availability_State) return Boolean;
   function Persistence_Field_Allowed
     (Field : Recovery_Persistence_Field) return Boolean;
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



   function Surface_Requires_Execution_Validation
     (Surface : Target_Surface) return Boolean;
   function Selected_Stale_Target_Selection_Action
     (Surface : Target_Surface) return String;
   function Failed_Recovery_Operation_May_Fabricate_State
     (Surface : Target_Surface) return Boolean;
   function Recent_Missing_Marker_Is_Snapshot_Derived return Boolean;
   function Recent_Missing_Marker_May_Delete_Files return Boolean;
   function Recent_Missing_Marker_May_Clear_Workspace return Boolean;
   function Buffer_Known_Missing_State_Allowed
     (Dirty : Boolean; State : Target_Availability_State) return Boolean;
   function Replace_All_May_Apply
     (Summary : Replace_Apply_Validation_Summary) return Boolean;
   function Build_Candidate_Material_Identity_Matches
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean;
   function Build_Candidate_Refresh_Requires_Reconsent
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean;

   function Validate_Buffer_Access_State
     (Path           : String;
      Target_Exists  : Boolean;
      Ordinary_File  : Boolean;
      Readable       : Boolean;
      Writable       : Boolean;
      Require_Read   : Boolean := False;
      Require_Write  : Boolean := False) return Target_Validation_Result;

   function Diagnostic_Line_Only_Navigation_Column
     (Line : Natural;
      Column : Natural) return Natural;

   function Search_Result_Content_State
     (Target_Exists             : Boolean;
      Line_Available            : Boolean;
      Match_Still_Present       : Boolean;
      File_Touched_Since_Search : Boolean) return Target_Availability_State;

   function Replace_Apply_Summary_Message
     (Summary : Replace_Apply_Validation_Summary) return String;

   function Quick_Open_Session_Recent_Boost_Allowed
     (Path : String;
      Project_Root : String := "") return Boolean;

   function Build_Request_Consent_Remains_Valid
     (Candidate_Result : Target_Validation_Result) return Boolean;

   function Recovery_Command_No_Op_Message
     (Command : Recovery_Command_Kind) return String;

   function File_Tree_Expanded_Path_Restore_State
     (Path : String) return Target_Availability_State;


   function Validate_File_Tree_Mutation_Target
     (Kind         : File_Tree_Mutation_Kind;
      Path         : String;
      Project_Root : String := "";
      Parent_Path  : String := "") return Target_Validation_Result;

   function Workspace_Active_File_Fallback_Policy
     (Active_File_Missing      : Boolean;
      Reopened_File_Count      : Natural) return Workspace_Active_File_Fallback;

   function Workspace_Active_File_Fallback_Label
     (Fallback : Workspace_Active_File_Fallback) return String;

   function Replace_Apply_Skipped_Report_Allowed
     (Command_Reached_Validation : Boolean;
      Summary                    : Replace_Apply_Validation_Summary) return Boolean;

   function File_Tree_Mutation_Requires_Execution_Validation
     (Kind : File_Tree_Mutation_Kind) return Boolean;

   function Command_Availability_When_Confirmation_Pending
     (Surface : Target_Surface) return Target_Validation_Result;
   function Recovery_Command_Available_With_Confirmation_Pending
     (Command : Recovery_Command_Kind) return Boolean;
   function Forbidden_Recovery_Mechanism_Allowed
     (Mechanism : Forbidden_Recovery_Mechanism) return Boolean;
   function Transient_Surface_Field_May_Be_Persisted
     (Field : Transient_Surface_Field) return Boolean;
   function Project_Transition_Clears_Build_Transient
     (Field : Transient_Surface_Field) return Boolean;

   function Validate_Project_Target
     (Project_Path : String;
      Require_Directory : Boolean := True) return Target_Validation_Result;

   function Validate_Workspace_Project_Target
     (Project_Path : String) return Target_Validation_Result;

   function Validate_Workspace_File_Target
     (Path : String) return Target_Validation_Result;

   function Validate_Recent_Project_Target
     (Project_Path : String) return Target_Validation_Result;

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

   function Validate_File_Tree_Node_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Quick_Open_Result_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Search_Result_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Replace_Preview_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Outline_Target
     (Active_Buffer_Matches : Boolean;
      Stale                 : Boolean;
      Line                  : Natural;
      Column                : Natural;
      Last_Line             : Natural;
      Last_Line_Column      : Natural) return Target_Validation_Result;

   function Validate_Diagnostic_Target
     (Path       : String;
      Has_Source : Boolean;
      Line       : Natural;
      Column     : Natural;
      Last_Line  : Natural;
      Last_Line_Column : Natural;
      Project_Root : String := "") return Target_Validation_Result;

   function Validate_Build_Candidate_Target
     (Candidate_Path : String;
      Working_Root   : String;
      Stale          : Boolean := False) return Target_Validation_Result;

   function Validate_Build_Working_Context_Target
     (Working_Root : String) return Target_Validation_Result;


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



   type Recovery_Command_Effect_Kind is
     (Effect_Probe_Filesystem,
      Effect_Mutate_Owning_Surface,
      Effect_Write_Persistence,
      Effect_Open_Target,
      Effect_Reload_Buffer,
      Effect_Revert_Buffer,
      Effect_Run_Build,
      Effect_Delete_User_File,
      Effect_Create_Project_Context,
      Effect_Clear_Other_Surface);

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

   type Recovery_Postcondition is
     (Postcondition_Revalidate_Before_Use,
      Postcondition_Surface_Replaced,
      Postcondition_Surface_Cleared,
      Postcondition_No_Target_Use);

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


   type Stale_Surface_Lifecycle_Action is
     (Lifecycle_Mark_Stale,
      Lifecycle_Display_Marker,
      Lifecycle_Block_Target_Use,
      Lifecycle_Offer_Recovery_Hint,
      Lifecycle_Clear_By_Explicit_Recovery,
      Lifecycle_Persist_Marker,
      Lifecycle_Auto_Refresh,
      Lifecycle_Auto_Rerun,
      Lifecycle_Open_Target);

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

   type Multi_Target_Command_Kind is
     (Multi_Workspace_Reopen_Files,
      Multi_Project_Search_Replace_All,
      Multi_Diagnostics_Navigate_Next_Previous,
      Multi_Build_Candidate_Refresh);

   type Multi_Target_Validation_Summary is record
      Valid_Targets        : Natural := 0;
      Missing_Targets      : Natural := 0;
      Stale_Targets        : Natural := 0;
      Outside_Project      : Natural := 0;
      Unreadable_Targets   : Natural := 0;
      Out_Of_Range_Targets : Natural := 0;
   end record;

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

   function Assert_Missing_Targets_Do_Not_Fabricate_State return Boolean;
   function Assert_Dirty_Buffers_Preserved_When_File_Missing return Boolean;
   function Assert_Stale_Search_Replace_Does_Not_Apply return Boolean;
   function Assert_Stale_Outline_Does_Not_Navigate return Boolean;
   function Assert_Missing_Diagnostic_Target_Fails_Clearly return Boolean;
   function Assert_Stale_Build_Candidate_Blocks_Run return Boolean;
   function Assert_Render_Does_Not_Probe_Or_Repair_Targets return Boolean;
   function Assert_Recovery_State_Not_Persisted return Boolean;
   function Assert_Keybindings_Have_No_Target_Payloads return Boolean;
   function Assert_Project_Transition_Clears_Project_Scoped_Stale_State return Boolean;
   function Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded return Boolean;
   function Assert_Stale_Targets_Block_Navigation_Apply_And_Run return Boolean;
   function Assert_Surface_Specific_Messages_Are_Clear return Boolean;
   function Assert_No_Automatic_Repair_From_Render_Or_Availability return Boolean;
   function Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating return Boolean;
   function Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads return Boolean;
   function Assert_Explicit_Caret_Policy_Required_For_Clamping return Boolean;
   function Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards return Boolean;
   function Assert_Recovery_Commands_Route_Only_Through_Executor return Boolean;
   function Assert_Command_Sources_Have_No_Target_Payloads return Boolean;
   function Assert_One_Primary_User_Readable_Outcome_Per_Command return Boolean;
   function Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly return Boolean;

   function Assert_Access_Distinctions_Are_Explicit return Boolean;
   function Assert_Line_Only_Diagnostics_Navigate_To_Line_Start return Boolean;
   function Assert_Search_Content_Staleness_Is_Gated return Boolean;
   function Assert_Replace_Apply_Summary_Is_Bounded return Boolean;
   function Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation return Boolean;

   function Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired return Boolean;
   function Assert_Recent_Missing_Markers_Are_Snapshot_Only return Boolean;
   function Assert_Replace_All_And_Build_Reconsent_Are_Gated return Boolean;

   function Assert_File_Tree_Mutations_Preflight_At_Execution return Boolean;
   function Assert_Workspace_Active_File_Fallback_Is_Deterministic return Boolean;
   function Assert_Replace_Skipped_Report_Requires_Validation return Boolean;

   function Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit return Boolean;
   function Assert_Target_Use_Blocking_Matrix_Is_Explicit return Boolean;
   function Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh return Boolean;
   function Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate return Boolean;
   function Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State return Boolean;
   function Assert_Stale_Targets_Expose_Explicit_User_Action_Hints return Boolean;
   function Assert_Recovery_Hints_Map_To_Explicit_Commands return Boolean;
   function Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing return Boolean;
   function Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text return Boolean;
   function Assert_Content_And_Project_Events_Update_Recovery_Surfaces return Boolean;
   function Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor return Boolean;
   function Assert_Non_Executor_Recovery_Triggers_Are_Observational return Boolean;


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

   function Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome return Boolean;
   function Assert_Availability_And_Render_Cannot_Clear_Stale_State return Boolean;
   function Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor return Boolean;

   function Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped return Boolean;
   function Assert_Missing_Targets_Are_Not_Remapped return Boolean;
   function Assert_Target_Validation_Is_Command_Execution_Boundary return Boolean;
   function Assert_Cached_Target_Validation_Is_Never_Authoritative return Boolean;
   function Assert_Confirmation_Pending_Blocks_Recovery_Commands return Boolean;
   function Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled return Boolean;
   function Assert_Transient_Surface_Fields_Are_Not_Persisted return Boolean;
   function Assert_Project_Transition_Clears_Build_Transient_State return Boolean;
   function Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless return Boolean;
   function Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets return Boolean;
   function Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free return Boolean;
   function Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe return Boolean;
   function Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use return Boolean;
   function Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit return Boolean;
   function Assert_Missing_Stale_Target_Recovery_Coherent return Boolean;

end Editor.Missing_Stale_Recovery;
