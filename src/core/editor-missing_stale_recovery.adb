with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies;
with Editor.Missing_Stale_Recovery.Core_Audit;
with Editor.Missing_Stale_Recovery.Execution_Policies;
with Editor.Missing_Stale_Recovery.Facade_Contract_Policies;
with Editor.Missing_Stale_Recovery.File_Lifecycle_Policies;
with Editor.Missing_Stale_Recovery.Project_Workspace_Policies;
with Editor.Missing_Stale_Recovery.Recovery_Audit;
with Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies;
with Editor.Missing_Stale_Recovery.Recovery_Policies;
with Editor.Missing_Stale_Recovery.Surface_Event_Policies;
with Editor.Missing_Stale_Recovery.Surface_Validation_Policies;
with Editor.Missing_Stale_Recovery.Target_Use_Policies;
with Editor.Missing_Stale_Recovery.Target_Messages;
with Editor.Missing_Stale_Recovery.Validation_Audit;

package body Editor.Missing_Stale_Recovery is

   function Trim (Text : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Trim;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Exists (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Exists;

   function Is_Directory (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Directory;

   function Is_Ordinary_File (Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Ordinary_File;

   function Canonical (Path : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Canonical;

   function Is_Inside_Project
     (Project_Root : String; Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Messages.Is_Inside_Project;

   function Label (State : Target_Availability_State) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Label;

   function Availability_Reason
     (State : Target_Availability_State) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Availability_Reason;

   function Surface_Label (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Surface_Label;

   function Outcome_Label (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Outcome_Label;

   function Target_Outcome_Message
     (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Target_Outcome_Message;

   function Render_Marker_Label
     (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Render_Marker_Label;

   function Workspace_Recovery_Message
     (Summary : Workspace_Recovery_Summary) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Workspace_Recovery_Message;

   function Recent_Project_Recovery_Message
     (Missing_Count : Natural; Removed_Count : Natural) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Recent_Project_Recovery_Message;

   function Workspace_Restore_Action_Fabricates_State
     (Action : Workspace_Restore_Action) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Workspace_Restore_Action_Fabricates_State;

   function Workspace_Restore_Action_Is_Safe
     (Action : Workspace_Restore_Action) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Workspace_Restore_Action_Is_Safe;

   function Caret_Target_Policy
     (State : Target_Availability_State; Explicit_Clamp_Policy : Boolean) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Caret_Target_Policy;

   function Recovery_Command_Name (Command : Recovery_Command_Kind) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Name;

   function Recovery_Command_Is_Payload_Free (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Payload_Free;

   function Recovery_Command_Is_Explicit (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Explicit;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Replaces_Stale_Surface;

   function Surface_Cleared_On_Project_Transition
     (Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Surface_Cleared_On_Project_Transition;

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Stale_State_After_Content_Change;

   function Navigation_Allowed
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Navigation_Allowed;

   function Replace_Apply_Allowed
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Replace_Apply_Allowed;

   function Build_Run_Allowed
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Build_Run_Allowed;

   function Recovery_State_Is_Persistable
     (State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Recovery_State_Is_Persistable;

   function Persistence_Field_Allowed
     (Field : Recovery_Persistence_Field) return Boolean
     renames Editor.Missing_Stale_Recovery.Facade_Contract_Policies.Persistence_Field_Allowed;

   function Render_May_Probe_Targets return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Render_May_Probe_Targets;

   function Render_May_Repair_Targets return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Render_May_Repair_Targets;

   function Availability_May_Repair_Targets return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Availability_May_Repair_Targets;

   function Recovery_Command_May_Run_From_Render
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_May_Run_From_Render;

   function Recovery_Command_May_Run_From_Availability
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_May_Run_From_Availability;

   function Recovery_Command_May_Bypass_Dirty_Guards
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_May_Bypass_Dirty_Guards;

   function Command_Availability_When_No_Selection
     (Surface : Target_Surface) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Command_Availability_When_No_Selection;

   function Recovery_Command_Routes_Through_Executor
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Routes_Through_Executor;

   function Invocation_Source_May_Carry_Target_Payload
     (Source : Command_Invocation_Source) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Invocation_Source_May_Carry_Target_Payload;

   function Invocation_Source_May_Execute_Recovery_Command
     (Source : Command_Invocation_Source) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Invocation_Source_May_Execute_Recovery_Command;

   function Recovery_Trigger_May_Probe_Filesystem
     (Trigger : Recovery_Trigger_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Recovery_Trigger_May_Probe_Filesystem;

   function Recovery_Trigger_May_Mutate_State
     (Trigger : Recovery_Trigger_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Recovery_Trigger_May_Mutate_State;

   function Recovery_Trigger_May_Persist_Recovery_State
     (Trigger : Recovery_Trigger_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Recovery_Trigger_May_Persist_Recovery_State;

   function Recovery_Trigger_May_Auto_Refresh
     (Trigger : Recovery_Trigger_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Recovery_Trigger_May_Auto_Refresh;

   function Target_Path_Identity_Matches
     (Expected_Path : String; Actual_Path : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Target_Path_Identity_Matches;

   function Missing_Target_May_Be_Auto_Remapped return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Missing_Target_May_Be_Auto_Remapped;


   function Validation_Phase_May_Probe_Filesystem
     (Phase : Target_Validation_Phase) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validation_Phase_May_Probe_Filesystem;

   function Validation_Phase_May_Mutate_State
     (Phase : Target_Validation_Phase) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validation_Phase_May_Mutate_State;

   function Validation_Phase_May_Authorize_Target_Use
     (Phase : Target_Validation_Phase) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validation_Phase_May_Authorize_Target_Use;

   function Validation_Phase_May_Reuse_Cached_Target_Result
     (Phase : Target_Validation_Phase) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validation_Phase_May_Reuse_Cached_Target_Result;

   function Execution_Revalidation_Required
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Execution_Revalidation_Required;

   function Cached_Target_Validation_May_Be_Applied
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Cached_Target_Validation_May_Be_Applied;

   function Execution_Revalidation_Message
     (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Execution_Revalidation_Message;

   function Command_Outcome_Count_For_Validation
     (Result : Target_Validation_Result) return Natural
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Command_Outcome_Count_For_Validation;

   function Command_Outcome_Is_User_Readable
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Command_Outcome_Is_User_Readable;

   function Surface_Recovery_Label
     (Surface : Target_Surface; State : Target_Availability_State) return String
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Surface_Recovery_Label;





   function Staleness_Reason_Label
     (Reason : Target_Staleness_Reason) return String
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Staleness_Reason_Label;

   function Staleness_Reason_May_Be_Persisted
     (Reason : Target_Staleness_Reason) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Staleness_Reason_May_Be_Persisted;

   function Staleness_Reason_Requires_Explicit_Recovery
     (Reason : Target_Staleness_Reason) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Staleness_Reason_Requires_Explicit_Recovery;

   function Validate_Staleness_Provenance
     (Surface : Target_Surface;
      Reason  : Target_Staleness_Reason) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validate_Staleness_Provenance;

   function Project_Scope_Identity_Matches
     (Expected_Project_Root : String;
      Actual_Project_Root   : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Project_Scope_Identity_Matches;

   function Stale_Target_May_Be_Opened_From_Previous_Project return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Stale_Target_May_Be_Opened_From_Previous_Project;


   function Target_Reference_Context_May_Be_Consumed
     (Context : Target_Reference_Context) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Target_Reference_Context_May_Be_Consumed;

   function Target_Generation_State_Allows_Target_Use
     (Generation : Target_Generation_State) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Target_Generation_State_Allows_Target_Use;

   function Validate_Target_Reference_For_Execution
     (Surface    : Target_Surface;
      Context    : Target_Reference_Context;
      Generation : Target_Generation_State) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Validate_Target_Reference_For_Execution;

   function Recovery_Message_Content_Allowed
     (Content : Recovery_Message_Content) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Recovery_Message_Content_Allowed;

   function Outcome_Message_May_Embed_Target_Path
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Outcome_Message_May_Embed_Target_Path;

   function Outcome_Message_May_Expose_Internal_Enum
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Outcome_Message_May_Expose_Internal_Enum;

   function Target_Result_Message_Is_Payload_Free
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Execution_Policies.Target_Result_Message_Is_Payload_Free;


   function Target_State_Blocks_Use
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_State_Blocks_Use;

   function Target_Use_May_Proceed
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_Use_May_Proceed;

   function Target_Use_Blocking_Message
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return String
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_Use_Blocking_Message;

   function Target_Use_Failure_Requires_Recovery_Command
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_Use_Failure_Requires_Recovery_Command;

   function Target_Use_Requires_Execution_Validation
     (Use_Kind : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_Use_Requires_Execution_Validation;

   function Target_Use_May_Auto_Refresh
     (Use_Kind : Target_Use_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Target_Use_Policies.Target_Use_May_Auto_Refresh;

   function Missing_Target_May_Create_Implicit_File
     (Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Missing_Target_May_Create_Implicit_File;

   function Failed_Target_Use_Preserves_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Failed_Target_Use_Preserves_User_Text;

   function Target_Use_Failure_May_Discard_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Target_Use_Failure_May_Discard_User_Text;

   function Target_Validation_Failure_May_Mutate_State
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Target_Validation_Failure_May_Mutate_State;

   function Target_Validation_Failure_Disposition
     (Result : Target_Validation_Result) return Validation_Failure_Disposition
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Target_Validation_Failure_Disposition;

   function Validation_Failure_Disposition_Label
     (Disposition : Validation_Failure_Disposition) return String
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Validation_Failure_Disposition_Label;

   function Recovery_Command_Failed_Attempt_Clears_Stale_State
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Recovery_Command_Failed_Attempt_Clears_Stale_State;

   function Stale_Target_User_Action_Hint
     (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Stale_Target_User_Action_Hint;

   function Project_Transition_Surface_Disposition
     (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Project_Transition_Surface_Disposition;

   function Event_Effect_On_Surface
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Surface_Event_Effect
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Event_Effect_On_Surface;

   function Event_Effect_Label
     (Effect : Surface_Event_Effect) return String
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Event_Effect_Label;

   function Event_State_After
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Target_Availability_State
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Event_State_After;

   function Event_May_Create_Files
     (Event : Recovery_Event_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Event_May_Create_Files;

   function Event_May_Bypass_Executor
     (Event : Recovery_Event_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Event_May_Bypass_Executor;

   function Surface_Event_Effect_Is_Transient
     (Effect : Surface_Event_Effect) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Surface_Event_Effect_Is_Transient;


   function Recovery_Command_For_Surface
     (Surface : Target_Surface) return Recovery_Command_Kind
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Recovery_Command_For_Surface;

   function Recovery_Command_Can_Address_Result
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Recovery_Command_Can_Address_Result;

   function Recovery_Command_Hint_Message
     (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Surface_Event_Policies.Recovery_Command_Hint_Message;

   function Workspace_Load_May_Restore_Unsaved_Text return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Workspace_Load_May_Restore_Unsaved_Text;

   function Project_Transition_May_Discard_Dirty_Buffer return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Project_Transition_May_Discard_Dirty_Buffer;

   function Recovery_Command_Requires_Dirty_Guard
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Recovery_Command_Requires_Dirty_Guard;

   function Snapshot_Status_Is_Transient
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Snapshot_Status_Is_Transient;

   function Snapshot_Status_May_Be_Persisted
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Snapshot_Status_May_Be_Persisted;

   function Snapshot_Status_May_Probe_Filesystem return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Snapshot_Status_May_Probe_Filesystem;

   function Surface_Requires_Execution_Validation
     (Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Surface_Requires_Execution_Validation;

   function Selected_Stale_Target_Selection_Action
     (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Selected_Stale_Target_Selection_Action;

   function Failed_Recovery_Operation_May_Fabricate_State
     (Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Failed_Recovery_Operation_May_Fabricate_State;

   function Recent_Missing_Marker_Is_Snapshot_Derived return Boolean
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Recent_Missing_Marker_Is_Snapshot_Derived;

   function Recent_Missing_Marker_May_Delete_Files return Boolean
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Recent_Missing_Marker_May_Delete_Files;

   function Recent_Missing_Marker_May_Clear_Workspace return Boolean
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Recent_Missing_Marker_May_Clear_Workspace;

   function Buffer_Known_Missing_State_Allowed
     (Dirty : Boolean; State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Buffer_Known_Missing_State_Allowed;

   function Replace_All_May_Apply
     (Summary : Replace_Apply_Validation_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Replace_All_May_Apply;

   function Build_Candidate_Material_Identity_Matches
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Build_Candidate_Material_Identity_Matches;

   function Build_Candidate_Refresh_Requires_Reconsent
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Build_Candidate_Refresh_Requires_Reconsent;

   function Validate_Buffer_Access_State
     (Path           : String;
      Target_Exists  : Boolean;
      Ordinary_File  : Boolean;
      Readable       : Boolean;
      Writable       : Boolean;
      Require_Read   : Boolean := False;
      Require_Write  : Boolean := False) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Buffer_Access_State;

   function Diagnostic_Line_Only_Navigation_Column
     (Line : Natural;
      Column : Natural) return Natural
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Diagnostic_Line_Only_Navigation_Column;

   function Search_Result_Content_State
     (Target_Exists             : Boolean;
      Line_Available            : Boolean;
      Match_Still_Present       : Boolean;
      File_Touched_Since_Search : Boolean) return Target_Availability_State
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Search_Result_Content_State;

   function Replace_Apply_Summary_Message
     (Summary : Replace_Apply_Validation_Summary) return String
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Replace_Apply_Summary_Message;

   function Quick_Open_Session_Recent_Boost_Allowed
     (Path : String;
      Project_Root : String := "") return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Quick_Open_Session_Recent_Boost_Allowed;

   function Build_Request_Consent_Remains_Valid
     (Candidate_Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Build_Request_Consent_Remains_Valid;

   function Recovery_Command_No_Op_Message
     (Command : Recovery_Command_Kind) return String
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Recovery_Command_No_Op_Message;

   function File_Tree_Expanded_Path_Restore_State
     (Path : String) return Target_Availability_State
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.File_Tree_Expanded_Path_Restore_State;


   function Validate_File_Tree_Mutation_Target
     (Kind         : File_Tree_Mutation_Kind;
      Path         : String;
      Project_Root : String := "";
      Parent_Path  : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_File_Tree_Mutation_Target;

   function Workspace_Active_File_Fallback_Policy
     (Active_File_Missing      : Boolean;
      Reopened_File_Count      : Natural) return Workspace_Active_File_Fallback
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Workspace_Active_File_Fallback_Policy;

   function Workspace_Active_File_Fallback_Label
     (Fallback : Workspace_Active_File_Fallback) return String
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Workspace_Active_File_Fallback_Label;

   function Replace_Apply_Skipped_Report_Allowed
     (Command_Reached_Validation : Boolean;
      Summary                    : Replace_Apply_Validation_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Replace_Apply_Skipped_Report_Allowed;

   function File_Tree_Mutation_Requires_Execution_Validation
     (Kind : File_Tree_Mutation_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.File_Tree_Mutation_Requires_Execution_Validation;

   function Command_Availability_When_Confirmation_Pending
     (Surface : Target_Surface) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Command_Availability_When_Confirmation_Pending;

   function Recovery_Command_Available_With_Confirmation_Pending
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Recovery_Command_Available_With_Confirmation_Pending;

   function Forbidden_Recovery_Mechanism_Allowed
     (Mechanism : Forbidden_Recovery_Mechanism) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Forbidden_Recovery_Mechanism_Allowed;

   function Transient_Surface_Field_May_Be_Persisted
     (Field : Transient_Surface_Field) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Transient_Surface_Field_May_Be_Persisted;

   function Project_Transition_Clears_Build_Transient
     (Field : Transient_Surface_Field) return Boolean
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Project_Transition_Clears_Build_Transient;

   function Validate_Project_Target
     (Project_Path : String;
      Require_Directory : Boolean := True) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_Project_Target;


   function Validate_Workspace_Project_Target
     (Project_Path : String) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_Workspace_Project_Target;

   function Validate_Workspace_File_Target
     (Path : String) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_Workspace_File_Target;

   function Validate_Recent_Project_Target
     (Project_Path : String) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_Recent_Project_Target;

   function Validate_File_Target
     (Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_File_Target;

   function Validate_Project_File_Target
     (Project_Root  : String;
      Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Project_File_Target;


   function Validate_Buffer_Backing_File_Target
     (Path  : String;
      Dirty : Boolean := False) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Buffer_Backing_File_Target;

   function Validate_Save_Target
     (Path : String) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Save_Target;

   function Validate_Reveal_Target
     (Path         : String;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Reveal_Target;

   function Dirty_Buffer_Text_Preserved_On
     (State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Dirty_Buffer_Text_Preserved_On;

   function Dirty_State_Preserved_On
     (State : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Dirty_State_Preserved_On;

   function Validate_Line_Column_Target
     (Line             : Natural;
      Column           : Natural;
      Last_Line        : Natural;
      Last_Line_Column : Natural) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.File_Lifecycle_Policies.Validate_Line_Column_Target;

   function Validate_File_Tree_Node_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Project_Workspace_Policies.Validate_File_Tree_Node_Target;

   function Validate_Quick_Open_Result_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Quick_Open_Result_Target;

   function Validate_Search_Result_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Search_Result_Target;

   function Validate_Replace_Preview_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Replace_Preview_Target;

   function Validate_Outline_Target
     (Active_Buffer_Matches : Boolean;
      Stale                 : Boolean;
      Line                  : Natural;
      Column                : Natural;
      Last_Line             : Natural;
      Last_Line_Column      : Natural) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Outline_Target;

   function Validate_Diagnostic_Target
     (Path       : String;
      Has_Source : Boolean;
      Line       : Natural;
      Column     : Natural;
      Last_Line  : Natural;
      Last_Line_Column : Natural;
      Project_Root : String := "") return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Diagnostic_Target;

   function Validate_Build_Working_Context_Target
     (Working_Root : String) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Build_Working_Context_Target;

   function Validate_Build_Candidate_Target
     (Candidate_Path : String;
      Working_Root   : String;
      Stale          : Boolean := False) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Surface_Validation_Policies.Validate_Build_Candidate_Target;

   function Assert_Missing_Targets_Do_Not_Fabricate_State return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Missing_Targets_Do_Not_Fabricate_State;

   function Assert_Dirty_Buffers_Preserved_When_File_Missing return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Dirty_Buffers_Preserved_When_File_Missing;

   function Assert_Stale_Search_Replace_Does_Not_Apply return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Stale_Search_Replace_Does_Not_Apply;

   function Assert_Stale_Outline_Does_Not_Navigate return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Stale_Outline_Does_Not_Navigate;

   function Assert_Missing_Diagnostic_Target_Fails_Clearly return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Missing_Diagnostic_Target_Fails_Clearly;

   function Assert_Stale_Build_Candidate_Blocks_Run return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Stale_Build_Candidate_Blocks_Run;

   function Assert_Render_Does_Not_Probe_Or_Repair_Targets return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Render_Does_Not_Probe_Or_Repair_Targets;

   function Assert_Recovery_State_Not_Persisted return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Recovery_State_Not_Persisted;

   function Assert_Keybindings_Have_No_Target_Payloads return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Keybindings_Have_No_Target_Payloads;

   function Assert_Project_Transition_Clears_Project_Scoped_Stale_State return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Project_Transition_Clears_Project_Scoped_Stale_State;

   function Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded;

   function Assert_Stale_Targets_Block_Navigation_Apply_And_Run return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Stale_Targets_Block_Navigation_Apply_And_Run;

   function Assert_Surface_Specific_Messages_Are_Clear return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Surface_Specific_Messages_Are_Clear;

   function Assert_No_Automatic_Repair_From_Render_Or_Availability return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_No_Automatic_Repair_From_Render_Or_Availability;

   function Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating;

   function Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads;

   function Assert_Explicit_Caret_Policy_Required_For_Clamping return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Explicit_Caret_Policy_Required_For_Clamping;

   function Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards;

   function Assert_Recovery_Commands_Route_Only_Through_Executor return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Recovery_Commands_Route_Only_Through_Executor;

   function Assert_Command_Sources_Have_No_Target_Payloads return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Command_Sources_Have_No_Target_Payloads;

   function Assert_One_Primary_User_Readable_Outcome_Per_Command return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_One_Primary_User_Readable_Outcome_Per_Command;

   function Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly return Boolean
     renames Editor.Missing_Stale_Recovery.Core_Audit.Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly;


   function Assert_Access_Distinctions_Are_Explicit return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Access_Distinctions_Are_Explicit;

   function Assert_Line_Only_Diagnostics_Navigate_To_Line_Start return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Line_Only_Diagnostics_Navigate_To_Line_Start;

   function Assert_Search_Content_Staleness_Is_Gated return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Search_Content_Staleness_Is_Gated;

   function Assert_Replace_Apply_Summary_Is_Bounded return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Replace_Apply_Summary_Is_Bounded;

   function Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation;


   function Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired;

   function Assert_Recent_Missing_Markers_Are_Snapshot_Only return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Recent_Missing_Markers_Are_Snapshot_Only;

   function Assert_Replace_All_And_Build_Reconsent_Are_Gated return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Replace_All_And_Build_Reconsent_Are_Gated;


   function Assert_File_Tree_Mutations_Preflight_At_Execution return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_File_Tree_Mutations_Preflight_At_Execution;

   function Assert_Workspace_Active_File_Fallback_Is_Deterministic return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Workspace_Active_File_Fallback_Is_Deterministic;

   function Assert_Replace_Skipped_Report_Requires_Validation return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Replace_Skipped_Report_Requires_Validation;



   function Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit;

   function Assert_Target_Use_Blocking_Matrix_Is_Explicit return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Target_Use_Blocking_Matrix_Is_Explicit;

   function Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh;

   function Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate;

   function Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State;

   function Assert_Stale_Targets_Expose_Explicit_User_Action_Hints return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Stale_Targets_Expose_Explicit_User_Action_Hints;

   function Assert_Recovery_Hints_Map_To_Explicit_Commands return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Recovery_Hints_Map_To_Explicit_Commands;

   function Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing;

   function Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text;

   function Assert_Content_And_Project_Events_Update_Recovery_Surfaces return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Content_And_Project_Events_Update_Recovery_Surfaces;

   function Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor;

   function Assert_Non_Executor_Recovery_Triggers_Are_Observational return Boolean
     renames Editor.Missing_Stale_Recovery.Validation_Audit.Assert_Non_Executor_Recovery_Triggers_Are_Observational;



   function Workspace_Recovery_Primary_Outcome_Count
     (Summary : Workspace_Recovery_Summary) return Natural
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Workspace_Recovery_Primary_Outcome_Count;

   function Workspace_Recovery_Summary_May_Be_Persisted
     (Summary : Workspace_Recovery_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Workspace_Recovery_Summary_May_Be_Persisted;

   function Availability_Check_May_Write_Persistence return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Availability_Check_May_Write_Persistence;

   function Availability_Check_May_Clear_Stale_State return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Availability_Check_May_Clear_Stale_State;

   function Render_Snapshot_May_Clear_Stale_State return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Render_Snapshot_May_Clear_Stale_State;

   function Recovery_Command_May_Clear_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Source  : Command_Invocation_Source) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Recovery_Command_May_Clear_Surface;

   function Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies.Recovery_Command_Failed_Attempt_Preserves_Dirty_Text;

   function Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome;

   function Assert_Availability_And_Render_Cannot_Clear_Stale_State return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Availability_And_Render_Cannot_Clear_Stale_State;

   function Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor;

   function Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped;

   function Assert_Missing_Targets_Are_Not_Remapped return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Missing_Targets_Are_Not_Remapped;

   function Assert_Target_Validation_Is_Command_Execution_Boundary return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Target_Validation_Is_Command_Execution_Boundary;

   function Assert_Cached_Target_Validation_Is_Never_Authoritative return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Cached_Target_Validation_Is_Never_Authoritative;

   function Assert_Confirmation_Pending_Blocks_Recovery_Commands return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Confirmation_Pending_Blocks_Recovery_Commands;

   function Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled;

   function Assert_Transient_Surface_Fields_Are_Not_Persisted return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Transient_Surface_Fields_Are_Not_Persisted;

   function Assert_Project_Transition_Clears_Build_Transient_State return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Project_Transition_Clears_Build_Transient_State;



   function Recovery_Attempt_Disposition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_State_Disposition
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_Disposition;

   function Recovery_Attempt_Outcome_Label
     (Outcome : Recovery_Attempt_Outcome) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_Outcome_Label;

   function Recovery_Attempt_May_Clear_State
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_May_Clear_State;

   function Recovery_Attempt_Message_May_Embed_Path
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_Message_May_Embed_Path;

   function Recovery_Attempt_Produces_One_Primary_Outcome
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_Produces_One_Primary_Outcome;

   function Recovery_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Attempt_Preserves_Dirty_Text;

   function Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets;



   function Recovery_Command_Effect_Allowed
     (Command : Recovery_Command_Kind;
      Effect  : Recovery_Command_Effect_Kind;
      Source  : Command_Invocation_Source := Invocation_Executor) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_Effect_Allowed;

   function Recovery_Command_May_Write_Persistence
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Write_Persistence;

   function Recovery_Command_May_Open_Target
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Open_Target;

   function Recovery_Command_May_Clear_Other_Surface
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Clear_Other_Surface;

   function Recovery_Command_Effect_Label
     (Effect : Recovery_Command_Effect_Kind) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_Effect_Label;


   function Recovery_Command_Postcondition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_Postcondition
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_Postcondition;

   function Recovery_Postcondition_Label
     (Postcondition : Recovery_Postcondition) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Postcondition_Label;

   function Recovery_Command_May_Immediately_Consume_Recovered_Target
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Immediately_Consume_Recovered_Target;

   function Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_Result_Requires_Revalidation_Before_Target_Use;

   function Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe;

   function Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use;



   function Stale_Surface_Lifecycle_Action_Allowed
     (Surface : Target_Surface;
      Action  : Stale_Surface_Lifecycle_Action) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Stale_Surface_Lifecycle_Action_Allowed;

   function Stale_Surface_Lifecycle_Action_Label
     (Action : Stale_Surface_Lifecycle_Action) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Stale_Surface_Lifecycle_Action_Label;

   function Stale_Surface_Lifecycle_Action_Is_Transient
     (Action : Stale_Surface_Lifecycle_Action) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Stale_Surface_Lifecycle_Action_Is_Transient;

   function Stale_Surface_Lifecycle_Action_May_Use_Payload
     (Action : Stale_Surface_Lifecycle_Action) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Stale_Surface_Lifecycle_Action_May_Use_Payload;

   function Stale_Surface_Lifecycle_Requires_Executor_Recovery
     (Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Stale_Surface_Lifecycle_Requires_Executor_Recovery;

   function Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;

   function Multi_Target_Command_Requires_Full_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Command_Requires_Full_Preflight;

   function Multi_Target_Command_May_Mutate_Before_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Command_May_Mutate_Before_Preflight;

   function Multi_Target_Validation_Allows_Mutation
     (Summary : Multi_Target_Validation_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Validation_Allows_Mutation;

   function Multi_Target_Validation_Message
     (Summary : Multi_Target_Validation_Summary) return String
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Validation_Message;

   function Multi_Target_Validation_Message_May_Embed_Paths
     (Summary : Multi_Target_Validation_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Validation_Message_May_Embed_Paths;

   function Multi_Target_Recovery_Preserves_Existing_State_On_Failure
     (Command : Multi_Target_Command_Kind;
      Summary : Multi_Target_Validation_Summary) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Multi_Target_Recovery_Preserves_Existing_State_On_Failure;

   function Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free;

   function Recovery_Command_May_Delete_User_File
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Delete_User_File;

   function Recovery_Command_May_Fabricate_Project_State
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Command_May_Fabricate_Project_State;

   function Recovery_Message_May_Embed_Target_Payload
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Message_May_Embed_Target_Payload;

   function Recovery_Message_Identifies_Surface_And_Category
     (Result : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Message_Identifies_Surface_And_Category;

   function Recovery_Action_Is_Safe_For_State
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Recovery_Action_Is_Safe_For_State;

   function Target_State_Has_Explicit_Recovery_Path
     (Surface : Target_Surface;
      State   : Target_Availability_State) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies.Target_State_Has_Explicit_Recovery_Path;

   function Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless;

   function Assert_Missing_Stale_Target_Recovery_Coherent return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Audit.Assert_Missing_Stale_Target_Recovery_Coherent;

end Editor.Missing_Stale_Recovery;
