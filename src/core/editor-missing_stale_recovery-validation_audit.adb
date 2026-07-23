with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Validation_Audit is

   use Ada.Strings.Unbounded;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Assert_Access_Distinctions_Are_Explicit return Boolean is
   begin
      return Validate_Buffer_Access_State
          ("demo.adb", True, True, False, True, Require_Read => True).State = Target_Unreadable
        and then Validate_Buffer_Access_State
          ("demo.adb", True, True, True, False, Require_Write => True).State = Target_Unwritable
        and then Target_Outcome_Message (Make (Buffer_Surface, Target_Unreadable, "demo.adb")) =
          "File is not readable."
        and then Target_Outcome_Message (Make (Buffer_Surface, Target_Unwritable, "demo.adb")) =
          "File is not writable.";
   end Assert_Access_Distinctions_Are_Explicit;

   function Assert_Line_Only_Diagnostics_Navigate_To_Line_Start return Boolean is
   begin
      return Diagnostic_Line_Only_Navigation_Column (12, 0) = 1
        and then Diagnostic_Line_Only_Navigation_Column (12, 5) = 5;
   end Assert_Line_Only_Diagnostics_Navigate_To_Line_Start;

   function Assert_Search_Content_Staleness_Is_Gated return Boolean is
   begin
      return Search_Result_Content_State (True, True, False, False) = Target_Stale
        and then Search_Result_Content_State (True, True, True, True) = Target_Stale
        and then Search_Result_Content_State (True, False, True, False) = Target_Line_Out_Of_Range
        and then Search_Result_Content_State (False, True, True, False) = Target_Missing;
   end Assert_Search_Content_Staleness_Is_Gated;

   function Assert_Replace_Apply_Summary_Is_Bounded return Boolean is
      Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 0, Missing_Targets => 1, Stale_Targets => 1,
         Out_Of_Range_Targets => 0);
   begin
      return Replace_Apply_Summary_Message (Summary) =
        "Replace preview is stale; rerun search.";
   end Assert_Replace_Apply_Summary_Is_Bounded;

   function Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation return Boolean is
   begin
      return not Quick_Open_Session_Recent_Boost_Allowed ("missing.adb")
        and then not Build_Request_Consent_Remains_Valid
          (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr"));
   end Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation;

   function Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired return Boolean is
   begin
      return Surface_Requires_Execution_Validation (Quick_Open_Surface)
        and then Selected_Stale_Target_Selection_Action (File_Tree_Surface) =
          "clear or mark selected File Tree node stale"
        and then Selected_Stale_Target_Selection_Action (Build_Surface) =
          "invalidate selected build request consent"
        and then not Failed_Recovery_Operation_May_Fabricate_State (File_Tree_Surface)
        and then not Persistence_Field_Allowed (Persist_Surface_Stale_Selection);
   end Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired;

   function Assert_Recent_Missing_Markers_Are_Snapshot_Only return Boolean is
   begin
      return Recent_Missing_Marker_Is_Snapshot_Derived
        and then not Recent_Missing_Marker_May_Delete_Files
        and then not Recent_Missing_Marker_May_Clear_Workspace;
   end Assert_Recent_Missing_Markers_Are_Snapshot_Only;

   function Assert_Replace_All_And_Build_Reconsent_Are_Gated return Boolean is
      Clean_Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 0,
         Out_Of_Range_Targets => 0);
      Dirty_Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 1,
         Out_Of_Range_Targets => 0);
   begin
      return Replace_All_May_Apply (Clean_Summary)
        and then not Replace_All_May_Apply (Dirty_Summary)
        and then not Build_Candidate_Refresh_Requires_Reconsent
          ("demo.gpr", ".", "demo.gpr", ".")
        and then Build_Candidate_Refresh_Requires_Reconsent
          ("demo.gpr", ".", "other.gpr", ".");
   end Assert_Replace_All_And_Build_Reconsent_Are_Gated;

   function Assert_File_Tree_Mutations_Preflight_At_Execution return Boolean is
   begin
      return File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Activate_Node)
        and then File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Rename_Node)
        and then File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Delete_Node)
        and then Validate_File_Tree_Mutation_Target
          (File_Tree_Activate_Node, "", "").State = Target_Missing
        and then Validate_File_Tree_Mutation_Target
          (File_Tree_Create_File, "missing/new.adb", "", "missing").State =
            Target_Parent_Directory_Missing;
   end Assert_File_Tree_Mutations_Preflight_At_Execution;

   function Assert_Workspace_Active_File_Fallback_Is_Deterministic return Boolean is
   begin
      return Workspace_Active_File_Fallback_Policy (False, 0) =
          Workspace_Use_Restored_Active_File
        and then Workspace_Active_File_Fallback_Policy (True, 2) =
          Workspace_Use_First_Reopened_File
        and then Workspace_Active_File_Fallback_Policy (True, 0) =
          Workspace_No_Active_File
        and then Workspace_Active_File_Fallback_Label (Workspace_Use_First_Reopened_File) =
          "fallback to first reopened file";
   end Assert_Workspace_Active_File_Fallback_Is_Deterministic;

   function Assert_Replace_Skipped_Report_Requires_Validation return Boolean is
      Clean : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 0,
         Out_Of_Range_Targets => 0);
      Skipped : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 0, Missing_Targets => 1, Stale_Targets => 1,
         Out_Of_Range_Targets => 1);
   begin
      return Replace_Apply_Skipped_Report_Allowed (False, Clean)
        and then not Replace_Apply_Skipped_Report_Allowed (False, Skipped)
        and then Replace_Apply_Skipped_Report_Allowed (True, Skipped);
   end Assert_Replace_Skipped_Report_Requires_Validation;

   function Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit return Boolean is
      Previous_Project : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Quick_Open_Surface, Reference_Previous_Project, Generation_Current);
      Stale_Search : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Project_Search_Surface, Reference_Current_Project, Generation_Stale);
      Stale_Replace : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Replace_Preview_Surface, Reference_Current_Project, Generation_Stale);
      Current_Build : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Build_Surface, Reference_Current_Project, Generation_Current);
   begin
      return Target_Reference_Context_May_Be_Consumed (Reference_Current_Project)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Previous_Project)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Project_Closed)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Unknown_Project)
        and then Target_Generation_State_Allows_Target_Use (Generation_Current)
        and then not Target_Generation_State_Allows_Target_Use (Generation_Stale)
        and then not Target_Generation_State_Allows_Target_Use (Generation_Missing)
        and then Previous_Project.State = Target_Outside_Project
        and then Stale_Search.State = Target_Stale
        and then Stale_Replace.State = Target_Preview_Stale
        and then Current_Build.State = Target_Available
        and then Recovery_Message_Content_Allowed
          (Recovery_Message_Surface_Category)
        and then Recovery_Message_Content_Allowed
          (Recovery_Message_Counts_Only)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Target_Path)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Target_Line)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Internal_Enum)
        and then Target_Result_Message_Is_Payload_Free (Previous_Project)
        and then Target_Result_Message_Is_Payload_Free (Stale_Search);
   end Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit;

   function Assert_Target_Use_Blocking_Matrix_Is_Explicit return Boolean is
      Missing_Search : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/deleted.adb"),
         Line    => 10,
         Column  => 1);
      Available_Replace : constant Target_Validation_Result :=
        (State   => Target_Available,
         Surface => Replace_Preview_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 3,
         Column  => 4);
      Available_Build : constant Target_Validation_Result :=
        (State   => Target_Available,
         Surface => Build_Surface,
         Path    => To_Unbounded_String ("demo.gpr"),
         Line    => 0,
         Column  => 0);
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (Build_Surface);
   begin
      return Target_State_Blocks_Use (Target_Missing, Use_Open_Target)
        and then Target_State_Blocks_Use (Target_Unwritable, Use_Save_Target)
        and then Target_State_Blocks_Use (Target_Parent_Directory_Missing, Use_Save_Target)
        and then Target_State_Blocks_Use (Target_Line_Out_Of_Range, Use_Navigate_Target)
        and then Target_State_Blocks_Use (Target_Candidate_Stale, Use_Run_Build_Target)
        and then Target_State_Blocks_Use (Target_Command_Pending, Use_Run_Build_Target)
        and then not Target_State_Blocks_Use (Target_Available, Use_Open_Target)
        and then not Target_Use_May_Proceed (Missing_Search, Use_Navigate_Target)
        and then Target_Use_May_Proceed (Available_Replace, Use_Apply_Replace_Target)
        and then Target_Use_May_Proceed (Available_Build, Use_Run_Build_Target)
        and then not Target_Use_May_Proceed (Available_Build, Use_Apply_Replace_Target)
        and then Target_Use_Blocking_Message (Pending, Use_Run_Build_Target) =
          "Build: Command unavailable while confirmation is pending."
        and then Target_Use_Failure_Requires_Recovery_Command
          (Target_Preview_Stale, Use_Apply_Replace_Target)
        and then not Target_Use_Failure_Requires_Recovery_Command
          (Target_Source_Less, Use_Navigate_Target);
   end Assert_Target_Use_Blocking_Matrix_Is_Explicit;

   function Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh return Boolean is
   begin
      return Target_Use_Requires_Execution_Validation (Use_Open_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Save_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Navigate_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Apply_Replace_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Run_Build_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Open_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Navigate_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Apply_Replace_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Run_Build_Target);
   end Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh;

   function Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate return Boolean is
   begin
      return Failed_Target_Use_Preserves_User_Text (Use_Save_Target, Target_Missing)
        and then Failed_Target_Use_Preserves_User_Text (Use_Reload_Target, Target_Unreadable)
        and then Failed_Target_Use_Preserves_User_Text (Use_Revert_Target, Target_Reload_Required)
        and then not Target_Use_Failure_May_Discard_User_Text (Use_Save_Target, Target_Missing)
        and then not Missing_Target_May_Create_Implicit_File (Buffer_Surface)
        and then not Missing_Target_May_Create_Implicit_File (File_Tree_Surface)
        and then not Missing_Target_May_Create_Implicit_File (Project_Search_Surface);
   end Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate;

   function Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State return Boolean is
      Search_Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 4,
         Column  => 1);
      Missing_Buffer : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Buffer_Surface,
         Path    => To_Unbounded_String ("src/deleted.adb"),
         Line    => 0,
         Column  => 0);
   begin
      return not Target_Validation_Failure_May_Mutate_State (Search_Result)
        and then not Target_Validation_Failure_May_Mutate_State (Missing_Buffer)
        and then Target_Validation_Failure_Disposition (Search_Result) =
          Failure_Marks_Surface_Stale
        and then Target_Validation_Failure_Disposition (Missing_Buffer) =
          Failure_Preserves_Surface_State
        and then Validation_Failure_Disposition_Label (Failure_Marks_Surface_Stale) =
          "mark target stale and require explicit recovery"
        and then not Recovery_Command_Failed_Attempt_Clears_Stale_State
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_Failed_Attempt_Clears_Stale_State
          (Recovery_Build_Refresh_Candidates);
   end Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State;

   function Assert_Stale_Targets_Expose_Explicit_User_Action_Hints return Boolean is
   begin
      return Stale_Target_User_Action_Hint (File_Tree_Surface) = "refresh File Tree"
        and then Stale_Target_User_Action_Hint (Project_Search_Surface) = "rerun search"
        and then Stale_Target_User_Action_Hint (Replace_Preview_Surface) = "rerun search before replace"
        and then Stale_Target_User_Action_Hint (Outline_Surface) = "refresh Outline"
        and then Stale_Target_User_Action_Hint (Build_Surface) = "refresh build candidates"
        and then Project_Transition_Surface_Disposition (Build_Surface) =
          "clear Build candidates, request, consent, result and output";
   end Assert_Stale_Targets_Expose_Explicit_User_Action_Hints;

   function Assert_Recovery_Hints_Map_To_Explicit_Commands return Boolean is
      Search_Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 1,
         Column  => 1);
      Build_Result : constant Target_Validation_Result :=
        (State   => Target_Candidate_Stale,
         Surface => Build_Surface,
         Path    => To_Unbounded_String ("demo.gpr"),
         Line    => 0,
         Column  => 0);
   begin
      return Recovery_Command_For_Surface (Project_Search_Surface) = Recovery_Project_Search_Run
        and then Recovery_Command_Can_Address_Result
          (Recovery_Project_Search_Run, Search_Result)
        and then Recovery_Command_For_Surface (Build_Surface) = Recovery_Build_Refresh_Candidates
        and then Recovery_Command_Can_Address_Result
          (Recovery_Build_Refresh_Candidates, Build_Result)
        and then Ada.Strings.Fixed.Index
          (Recovery_Command_Hint_Message (Search_Result), "Recovery: rerun search.") > 0
        and then Ada.Strings.Fixed.Index
          (Recovery_Command_Hint_Message (Build_Result), "Recovery: refresh build candidates.") > 0;
   end Assert_Recovery_Hints_Map_To_Explicit_Commands;

   function Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing return Boolean is
      Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Quick_Open_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 0,
         Column  => 0);
   begin
      return Snapshot_Status_Is_Transient (Result)
        and then not Snapshot_Status_May_Be_Persisted (Result)
        and then not Snapshot_Status_May_Probe_Filesystem;
   end Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing;

   function Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text return Boolean is
   begin
      return not Workspace_Load_May_Restore_Unsaved_Text
        and then not Project_Transition_May_Discard_Dirty_Buffer
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_Workspace_Load)
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_File_Reload_From_Disk)
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_File_Revert_Buffer)
        and then not Recovery_Command_Requires_Dirty_Guard (Recovery_File_Tree_Refresh);
   end Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text;

   function Assert_Content_And_Project_Events_Update_Recovery_Surfaces return Boolean is
   begin
      return Event_Effect_On_Surface
          (Event_Buffer_Edited, Project_Search_Surface) = Surface_Marked_Stale
        and then Event_State_After
          (Event_Buffer_Edited, Project_Search_Surface) = Target_Stale
        and then Event_State_After
          (Event_Buffer_Reloaded, Replace_Preview_Surface) = Target_Preview_Stale
        and then Event_State_After
          (Event_Buffer_Edited, Outline_Surface) = Target_Refresh_Required
        and then Event_Effect_On_Surface
          (Event_Project_Switched, Quick_Open_Surface) = Surface_Cleared
        and then Event_Effect_On_Surface
          (Event_Project_Closed, Build_Surface) = Surface_Cleared
        and then Event_Effect_On_Surface
          (Event_Project_Search_Rerun, Project_Search_Surface) = Surface_Replaced
        and then Event_Effect_On_Surface
          (Event_Project_Search_Rerun, Replace_Preview_Surface) = Surface_Cleared
        and then Event_Effect_Label (Surface_Replaced) = "replaced by explicit refresh"
        and then Surface_Event_Effect_Is_Transient (Surface_Marked_Stale)
        and then not Surface_Event_Effect_Is_Transient (Surface_Unchanged);
   end Assert_Content_And_Project_Events_Update_Recovery_Surfaces;

   function Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor return Boolean is
   begin
      return not Event_May_Create_Files (Event_Buffer_Edited)
        and then not Event_May_Create_Files (Event_File_Tree_Refreshed)
        and then not Event_May_Create_Files (Event_Build_Candidates_Refreshed)
        and then not Event_May_Bypass_Executor (Event_Project_Search_Rerun)
        and then not Event_May_Bypass_Executor (Event_Outline_Refreshed)
        and then not Event_May_Bypass_Executor (Event_Build_Candidates_Refreshed);
   end Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor;

   function Assert_Non_Executor_Recovery_Triggers_Are_Observational return Boolean is
   begin
      return Recovery_Trigger_May_Probe_Filesystem (Trigger_User_Executor_Command)
        and then Recovery_Trigger_May_Mutate_State (Trigger_User_Executor_Command)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Render_Snapshot)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Render_Snapshot)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Availability_Check)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Availability_Check)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Background_Watcher)
        and then not Recovery_Trigger_May_Auto_Refresh (Trigger_Background_Watcher)
        and then not Recovery_Trigger_May_Persist_Recovery_State (Trigger_Workspace_Save)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Command_Palette_View)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Keybinding_Resolution);
   end Assert_Non_Executor_Recovery_Triggers_Are_Observational;

end Editor.Missing_Stale_Recovery.Validation_Audit;
