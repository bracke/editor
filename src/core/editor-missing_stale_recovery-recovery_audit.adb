with Ada.Strings.Unbounded;

package body Editor.Missing_Stale_Recovery.Recovery_Audit is

   use Ada.Strings.Unbounded;

   function Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome return Boolean is
      Clean : constant Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 0,
         Active_File_Missing    => False,
         Ignored_Expanded_Paths => 0,
         Invalid_Caret_Targets  => 0,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
      Stale : constant Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 2,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 1,
         Invalid_Caret_Targets  => 1,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
      Missing_Project : constant Workspace_Recovery_Summary :=
        (Project_Missing        => True,
         Missing_Open_Files     => 4,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 3,
         Invalid_Caret_Targets  => 2,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
   begin
      return Workspace_Recovery_Primary_Outcome_Count (Clean) = 0
        and then Workspace_Recovery_Primary_Outcome_Count (Stale) = 1
        and then Workspace_Recovery_Primary_Outcome_Count (Missing_Project) = 1
        and then not Workspace_Recovery_Summary_May_Be_Persisted (Stale)
        and then Workspace_Recovery_Message (Stale) =
          "Some workspace files could not be reopened; active file could not be restored."
        and then Workspace_Recovery_Message (Missing_Project) =
          "Workspace project path unavailable.";
   end Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome;

   function Assert_Availability_And_Render_Cannot_Clear_Stale_State return Boolean is
   begin
      return not Availability_Check_May_Write_Persistence
        and then not Availability_Check_May_Clear_Stale_State
        and then not Render_Snapshot_May_Clear_Stale_State
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Availability)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Render);
   end Assert_Availability_And_Render_Cannot_Clear_Stale_State;

   function Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor return Boolean is
   begin
      return Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Executor)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, Project_Search_Surface, Invocation_Executor)
        and then Recovery_Command_May_Clear_Surface
          (Recovery_Project_Search_Run, Project_Search_Surface, Invocation_Executor)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_Project_Search_Run, Outline_Surface, Invocation_Executor)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_Workspace_Load)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_File_Reload_From_Disk)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_File_Revert_Buffer);
   end Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor;

   function Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped return Boolean is
      Search_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Project_Search_Surface, Staleness_File_Content_Changed);
      Preview_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Replace_Preview_Surface, Staleness_Snapshot_Generation_Mismatch);
      Build_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Build_Surface, Staleness_Candidate_Identity_Changed);
   begin
      return Search_Stale.State = Target_Stale
        and then Preview_Stale.State = Target_Preview_Stale
        and then Build_Stale.State = Target_Candidate_Stale
        and then Staleness_Reason_Requires_Explicit_Recovery
          (Staleness_Project_Identity_Mismatch)
        and then not Staleness_Reason_May_Be_Persisted
          (Staleness_File_Content_Changed)
        and then Project_Scope_Identity_Matches ("/tmp/project", "/tmp/project")
        and then not Project_Scope_Identity_Matches ("/tmp/project", "/tmp/other")
        and then not Stale_Target_May_Be_Opened_From_Previous_Project;
   end Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped;

   function Assert_Missing_Targets_Are_Not_Remapped return Boolean is
   begin
      return Target_Path_Identity_Matches ("src/main.adb", "src/main.adb")
        and then not Target_Path_Identity_Matches ("src/main.adb", "src/renamed.adb")
        and then not Missing_Target_May_Be_Auto_Remapped;
   end Assert_Missing_Targets_Are_Not_Remapped;

   function Assert_Target_Validation_Is_Command_Execution_Boundary return Boolean is
   begin
      return Validation_Phase_May_Probe_Filesystem (Validation_Command_Execution)
        and then Validation_Phase_May_Mutate_State (Validation_Command_Execution)
        and then Validation_Phase_May_Authorize_Target_Use (Validation_Command_Execution)
        and then not Validation_Phase_May_Probe_Filesystem (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Mutate_State (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Authorize_Target_Use (Validation_Availability_Check)
        and then not Validation_Phase_May_Mutate_State (Validation_Persistence_Save);
   end Assert_Target_Validation_Is_Command_Execution_Boundary;

   function Assert_Cached_Target_Validation_Is_Never_Authoritative return Boolean is
   begin
      return not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Availability_Check)
        and then not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Command_Execution)
        and then not Cached_Target_Validation_May_Be_Applied
          (Quick_Open_Surface, Use_Open_Target)
        and then not Cached_Target_Validation_May_Be_Applied
          (Project_Search_Surface, Use_Navigate_Target)
        and then not Cached_Target_Validation_May_Be_Applied
          (Replace_Preview_Surface, Use_Apply_Replace_Target)
        and then Execution_Revalidation_Required
          (Diagnostics_Surface, Use_Navigate_Target)
        and then Execution_Revalidation_Required
          (Build_Surface, Use_Run_Build_Target)
        and then Execution_Revalidation_Message (Build_Surface) =
          "Build candidate is revalidated before use.";
   end Assert_Cached_Target_Validation_Is_Never_Authoritative;

   function Assert_Confirmation_Pending_Blocks_Recovery_Commands return Boolean is
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (File_Tree_Surface);
   begin
      return Pending.State = Target_Command_Pending
        and then Target_Outcome_Message (Pending) =
          "File Tree: Command unavailable while confirmation is pending."
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_Build_Refresh_Candidates);
   end Assert_Confirmation_Pending_Blocks_Recovery_Commands;

   function Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled return Boolean is
   begin
      return not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Filesystem_Watcher)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Background_Refresh)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Autosave_Recovery)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_External_File_Manager)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Shell_Execution)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Terminal)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_LSP_Recovery)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_New_Persistence_Domain)
        and then not Forbidden_Recovery_Mechanism_Allowed
          (Forbidden_Command_Palette_Target_Payload)
        and then not Forbidden_Recovery_Mechanism_Allowed
          (Forbidden_Keybinding_Target_Payload);
   end Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled;

   function Assert_Transient_Surface_Fields_Are_Not_Persisted return Boolean is
   begin
      return not Transient_Surface_Field_May_Be_Persisted
          (Transient_File_Tree_Stale_Selection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Quick_Open_Results)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Project_Search_Results)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Replace_Preview_Targets)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Outline_Rows)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Outline_Current_Symbol)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Filter)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Selection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Stale_Projection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Candidates)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Request)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Consent)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Result)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Output);
   end Assert_Transient_Surface_Fields_Are_Not_Persisted;

   function Assert_Project_Transition_Clears_Build_Transient_State return Boolean is
   begin
      return Project_Transition_Clears_Build_Transient (Transient_Build_Candidates)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Request)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Consent)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Result)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Output)
        and then not Project_Transition_Clears_Build_Transient
          (Transient_Project_Search_Results)
        and then not Project_Transition_Clears_Build_Transient
          (Transient_Outline_Rows);
   end Assert_Project_Transition_Clears_Build_Transient_State;

   function Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets return Boolean is
   begin
      return Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Failed)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Cancelled)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_File_Tree_Refresh, Project_Search_Surface, Recovery_Succeeded)
        and then Recovery_Attempt_Disposition
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Recovery_Succeeded) = Recovery_State_Replaced
        and then Recovery_Attempt_Disposition
          (Recovery_Project_Search_Clear_Results, Project_Search_Surface, Recovery_Succeeded) = Recovery_State_Cleared
        and then not Recovery_Attempt_Message_May_Embed_Path
          (Recovery_Project_Search_Run, Recovery_Failed)
        and then not Recovery_Attempt_Message_May_Embed_Path
          (Recovery_Workspace_Load, Recovery_Succeeded)
        and then Recovery_Attempt_Produces_One_Primary_Outcome
          (Recovery_Project_Search_Run, Recovery_Failed)
        and then Recovery_Attempt_Produces_One_Primary_Outcome
          (Recovery_Build_Refresh_Candidates, Recovery_Succeeded)
        and then Recovery_Attempt_Preserves_Dirty_Text
          (Recovery_File_Reload_From_Disk, Recovery_Failed)
        and then Recovery_Attempt_Preserves_Dirty_Text
          (Recovery_File_Revert_Buffer, Recovery_Cancelled)
        and then Recovery_Attempt_Outcome_Label (Recovery_Failed) =
          "Recovery failed; existing state preserved.";
   end Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets;

   function Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe return Boolean is
   begin
      return Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Probe_Filesystem, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Mutate_Owning_Surface, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Reload_From_Disk, Effect_Reload_Buffer, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Revert_Buffer, Effect_Revert_Buffer, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_Workspace_Load, Effect_Open_Target, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Probe_Filesystem, Invocation_Render)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Mutate_Owning_Surface, Invocation_Availability)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Build_Refresh_Candidates, Effect_Run_Build, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Recent_Projects_Remove_Missing, Effect_Delete_User_File, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Workspace_Load, Effect_Create_Project_Context, Invocation_Executor)
        and then not Recovery_Command_May_Write_Persistence
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_May_Clear_Other_Surface
          (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Effect_Label (Effect_Delete_User_File) = "delete user file";
   end Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe;

   function Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use return Boolean is
   begin
      return Recovery_Command_Postcondition
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded) =
          Postcondition_Revalidate_Before_Use
        and then Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded)
        and then Recovery_Command_Postcondition
          (Recovery_Outline_Refresh, Outline_Surface, Recovery_Succeeded) =
          Postcondition_Revalidate_Before_Use
        and then Recovery_Command_Postcondition
          (Recovery_Quick_Open_Clear_Query, Quick_Open_Surface, Recovery_Succeeded) =
          Postcondition_Surface_Cleared
        and then Recovery_Command_Postcondition
          (Recovery_Project_Search_Run, Build_Surface, Recovery_Succeeded) =
          Postcondition_No_Target_Use
        and then not Recovery_Command_May_Immediately_Consume_Recovered_Target
          (Recovery_Build_Refresh_Candidates, Build_Surface, Recovery_Succeeded)
        and then not Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Failed)
        and then Recovery_Postcondition_Label
          (Postcondition_Revalidate_Before_Use) =
          "Recovery completed; revalidate target before use.";
   end Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use;

   function Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit return Boolean is
   begin
      return Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Mark_Stale)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Display_Marker)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Block_Target_Use)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Offer_Recovery_Hint)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Clear_By_Explicit_Recovery)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Persist_Marker)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Auto_Refresh)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Replace_Preview_Surface, Lifecycle_Auto_Rerun)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Quick_Open_Surface, Lifecycle_Open_Target)
        and then Stale_Surface_Lifecycle_Action_Is_Transient
          (Lifecycle_Display_Marker)
        and then not Stale_Surface_Lifecycle_Action_Is_Transient
          (Lifecycle_Persist_Marker)
        and then not Stale_Surface_Lifecycle_Action_May_Use_Payload
          (Lifecycle_Offer_Recovery_Hint)
        and then Stale_Surface_Lifecycle_Requires_Executor_Recovery
          (Build_Surface)
        and then Stale_Surface_Lifecycle_Action_Label
          (Lifecycle_Clear_By_Explicit_Recovery) = "clear by explicit recovery";
   end Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;

   function Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free return Boolean is
      Bad_Replace : constant Multi_Target_Validation_Summary :=
        (Valid_Targets        => 3,
         Missing_Targets      => 1,
         Stale_Targets        => 1,
         Outside_Project      => 0,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 1);
      Good_Workspace : constant Multi_Target_Validation_Summary :=
        (Valid_Targets        => 2,
         Missing_Targets      => 0,
         Stale_Targets        => 0,
         Outside_Project      => 0,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 0);
   begin
      return Multi_Target_Command_Requires_Full_Preflight
          (Multi_Project_Search_Replace_All)
        and then Multi_Target_Command_Requires_Full_Preflight
          (Multi_Workspace_Reopen_Files)
        and then not Multi_Target_Command_May_Mutate_Before_Preflight
          (Multi_Project_Search_Replace_All)
        and then not Multi_Target_Validation_Allows_Mutation (Bad_Replace)
        and then Multi_Target_Validation_Allows_Mutation (Good_Workspace)
        and then Multi_Target_Validation_Message (Bad_Replace) =
          "Some targets are stale; refresh or rerun before applying."
        and then not Multi_Target_Validation_Message_May_Embed_Paths (Bad_Replace)
        and then Multi_Target_Recovery_Preserves_Existing_State_On_Failure
          (Multi_Project_Search_Replace_All, Bad_Replace)
        and then not Multi_Target_Recovery_Preserves_Existing_State_On_Failure
          (Multi_Workspace_Reopen_Files, Good_Workspace);
   end Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free;

   function Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless return Boolean is
      Search : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 5,
         Column  => 1);
      Recent : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Recent_Project_Surface,
         Path    => To_Unbounded_String ("/tmp/missing-project"),
         Line    => 0,
         Column  => 0);
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (Project_Search_Surface);
   begin
      return Recovery_Action_Is_Safe_For_State
          (Recovery_Project_Search_Run, Search)
        and then Recovery_Action_Is_Safe_For_State
          (Recovery_Recent_Projects_Remove_Missing, Recent)
        and then not Recovery_Action_Is_Safe_For_State
          (Recovery_Project_Search_Run, Pending)
        and then not Recovery_Command_May_Delete_User_File
          (Recovery_Recent_Projects_Remove_Missing)
        and then not Recovery_Command_May_Delete_User_File
          (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_May_Fabricate_Project_State
          (Recovery_Workspace_Load)
        and then not Recovery_Message_May_Embed_Target_Payload (Search)
        and then Recovery_Message_Identifies_Surface_And_Category (Search)
        and then Target_State_Has_Explicit_Recovery_Path
          (Project_Search_Surface, Target_Stale)
        and then Target_State_Has_Explicit_Recovery_Path
          (Build_Surface, Target_Candidate_Stale)
        and then not Target_State_Has_Explicit_Recovery_Path
          (Quick_Open_Surface, Target_No_Result_Selected)
        and then not Target_State_Has_Explicit_Recovery_Path
          (Diagnostics_Surface, Target_Source_Less);
   end Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless;

   function Assert_Missing_Stale_Target_Recovery_Coherent return Boolean is
   begin
      return Assert_Missing_Targets_Do_Not_Fabricate_State
        and then Assert_Dirty_Buffers_Preserved_When_File_Missing
        and then Assert_Stale_Search_Replace_Does_Not_Apply
        and then Assert_Stale_Outline_Does_Not_Navigate
        and then Assert_Missing_Diagnostic_Target_Fails_Clearly
        and then Assert_Stale_Build_Candidate_Blocks_Run
        and then Assert_Render_Does_Not_Probe_Or_Repair_Targets
        and then Assert_Recovery_State_Not_Persisted
        and then Assert_Keybindings_Have_No_Target_Payloads
        and then Assert_Project_Transition_Clears_Project_Scoped_Stale_State
        and then Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded
        and then Assert_Stale_Targets_Block_Navigation_Apply_And_Run
        and then Assert_Surface_Specific_Messages_Are_Clear
        and then Assert_No_Automatic_Repair_From_Render_Or_Availability
        and then Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating
        and then Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads
        and then Assert_Explicit_Caret_Policy_Required_For_Clamping
        and then Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards
        and then Assert_Recovery_Commands_Route_Only_Through_Executor
        and then Assert_Command_Sources_Have_No_Target_Payloads
        and then Assert_One_Primary_User_Readable_Outcome_Per_Command
        and then Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly
        and then Assert_Access_Distinctions_Are_Explicit
        and then Assert_Line_Only_Diagnostics_Navigate_To_Line_Start
        and then Assert_Search_Content_Staleness_Is_Gated
        and then Assert_Replace_Apply_Summary_Is_Bounded
        and then Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation
        and then Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired
        and then Assert_Recent_Missing_Markers_Are_Snapshot_Only
        and then Assert_Replace_All_And_Build_Reconsent_Are_Gated
        and then Assert_File_Tree_Mutations_Preflight_At_Execution
        and then Assert_Workspace_Active_File_Fallback_Is_Deterministic
        and then Assert_Replace_Skipped_Report_Requires_Validation
        and then Assert_Target_Use_Blocking_Matrix_Is_Explicit
        and then Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh
        and then Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate
        and then Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State
        and then Assert_Stale_Targets_Expose_Explicit_User_Action_Hints
        and then Assert_Recovery_Hints_Map_To_Explicit_Commands
        and then Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing
        and then Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text
        and then Assert_Content_And_Project_Events_Update_Recovery_Surfaces
        and then Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor
        and then Assert_Non_Executor_Recovery_Triggers_Are_Observational
        and then Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome
        and then Assert_Availability_And_Render_Cannot_Clear_Stale_State
        and then Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor
        and then Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped
        and then Assert_Missing_Targets_Are_Not_Remapped
        and then Assert_Target_Validation_Is_Command_Execution_Boundary
        and then Assert_Cached_Target_Validation_Is_Never_Authoritative
        and then Assert_Confirmation_Pending_Blocks_Recovery_Commands
        and then Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled
        and then Assert_Transient_Surface_Fields_Are_Not_Persisted
        and then Assert_Project_Transition_Clears_Build_Transient_State
        and then Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless
        and then Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets
        and then Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free
        and then Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit
        and then Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe
        and then Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use
        and then Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;
   end Assert_Missing_Stale_Target_Recovery_Coherent;

end Editor.Missing_Stale_Recovery.Recovery_Audit;
