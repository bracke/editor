with Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Core_Audit is

   use Ada.Strings.Unbounded;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Assert_Missing_Targets_Do_Not_Fabricate_State return Boolean is
   begin
      return Validate_File_Target ("").State = Target_Missing
        and then Validate_Project_Target ("").State = Target_Missing;
   end Assert_Missing_Targets_Do_Not_Fabricate_State;

   function Assert_Dirty_Buffers_Preserved_When_File_Missing return Boolean is
   begin
      return Availability_Reason (Target_Missing) = "Target no longer exists."
        and then Label (Target_Reload_Required) = "reload required"
        and then Dirty_Buffer_Text_Preserved_On (Target_Missing)
        and then Dirty_Buffer_Text_Preserved_On (Target_Unwritable);
   end Assert_Dirty_Buffers_Preserved_When_File_Missing;

   function Assert_Stale_Search_Replace_Does_Not_Apply return Boolean is
   begin
      return Validate_Search_Result_Target ("missing", 1, 1, Stale => True).State = Target_Stale
        and then Validate_Replace_Preview_Target ("missing", 1, 1, Stale => True).State = Target_Preview_Stale;
   end Assert_Stale_Search_Replace_Does_Not_Apply;

   function Assert_Stale_Outline_Does_Not_Navigate return Boolean is
   begin
      return Validate_Outline_Target (True, True, 1, 1, 1, 1).State = Target_Refresh_Required
        and then Validate_Outline_Target (False, False, 1, 1, 1, 1).State = Target_Stale;
   end Assert_Stale_Outline_Does_Not_Navigate;

   function Assert_Missing_Diagnostic_Target_Fails_Clearly return Boolean is
   begin
      return Validate_Diagnostic_Target ("", False, 0, 0, 0, 0).State = Target_Source_Less
        and then Availability_Reason (Target_Source_Less) = "Selected diagnostic has no source target.";
   end Assert_Missing_Diagnostic_Target_Fails_Clearly;

   function Assert_Stale_Build_Candidate_Blocks_Run return Boolean is
   begin
      return Validate_Build_Candidate_Target ("missing.gpr", ".", True).State = Target_Candidate_Stale;
   end Assert_Stale_Build_Candidate_Blocks_Run;

   function Assert_Render_Does_Not_Probe_Or_Repair_Targets return Boolean is
   begin
      return Surface_Label (File_Tree_Surface) = "File Tree"
        and then Label (Target_Stale) = "target stale"
        and then not Render_May_Probe_Targets;
   end Assert_Render_Does_Not_Probe_Or_Repair_Targets;

   function Assert_Recovery_State_Not_Persisted return Boolean is
   begin
      return Label (Target_Preview_Stale) = "preview stale"
        and then not Recovery_State_Is_Persistable (Target_Stale)
        and then not Recovery_State_Is_Persistable (Target_Candidate_Stale);
   end Assert_Recovery_State_Not_Persisted;

   function Assert_Keybindings_Have_No_Target_Payloads return Boolean is
   begin
      return Availability_Reason (Target_Refresh_Required) = "Refresh required."
        and then Recovery_Command_Is_Payload_Free (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Is_Payload_Free (Recovery_Project_Search_Run)
        and then Recovery_Command_Is_Payload_Free (Recovery_Build_Refresh_Candidates);
   end Assert_Keybindings_Have_No_Target_Payloads;

   function Assert_Project_Transition_Clears_Project_Scoped_Stale_State return Boolean is
   begin
      return Surface_Cleared_On_Project_Transition (Quick_Open_Surface)
        and then Surface_Cleared_On_Project_Transition (Project_Search_Surface)
        and then Surface_Cleared_On_Project_Transition (Replace_Preview_Surface)
        and then Surface_Cleared_On_Project_Transition (Diagnostics_Surface)
        and then Surface_Cleared_On_Project_Transition (Build_Surface)
        and then not Surface_Cleared_On_Project_Transition (Recent_Project_Surface);
   end Assert_Project_Transition_Clears_Project_Scoped_Stale_State;

   function Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded return Boolean is
   begin
      return Recovery_Command_Is_Explicit (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Is_Explicit (Recovery_Outline_Refresh)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_Project_Search_Replace_Clear_Preview, Replace_Preview_Surface)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_Build_Refresh_Candidates, Build_Surface)
        and then not Recovery_Command_Replaces_Stale_Surface
          (Recovery_Build_Refresh_Candidates, Project_Search_Surface);
   end Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded;

   function Assert_Stale_Targets_Block_Navigation_Apply_And_Run return Boolean is
   begin
      return not Navigation_Allowed
          (Make (Outline_Surface, Target_Refresh_Required, Line => 1, Column => 1))
        and then not Replace_Apply_Allowed
          (Make (Replace_Preview_Surface, Target_Preview_Stale, Line => 1))
        and then not Build_Run_Allowed
          (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr"));
   end Assert_Stale_Targets_Block_Navigation_Apply_And_Run;

   function Assert_Surface_Specific_Messages_Are_Clear return Boolean is
   begin
      return Target_Outcome_Message (Make (Quick_Open_Surface, Target_Stale, "missing.adb")) =
          "Quick Open result is stale."
        and then Target_Outcome_Message (Make (Project_Search_Surface, Target_Missing, "missing.adb", 1)) =
          "Search target no longer exists."
        and then Target_Outcome_Message (Make (Outline_Surface, Target_Refresh_Required, Line => 1, Column => 1)) =
          "Outline is stale; refresh required."
        and then Target_Outcome_Message (Make (Diagnostics_Surface, Target_Source_Less)) =
          "Selected diagnostic has no source target."
        and then Target_Outcome_Message (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr")) =
          "Selected build candidate is stale."
        and then Target_Outcome_Message (Make (Build_Surface, Target_Working_Directory_Missing, "missing-root")) =
          "Build working directory is unavailable.";
   end Assert_Surface_Specific_Messages_Are_Clear;

   function Assert_No_Automatic_Repair_From_Render_Or_Availability return Boolean is
   begin
      return not Render_May_Probe_Targets
        and then not Render_May_Repair_Targets
        and then not Availability_May_Repair_Targets
        and then not Recovery_Command_May_Run_From_Render (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_May_Run_From_Availability (Recovery_File_Tree_Refresh);
   end Assert_No_Automatic_Repair_From_Render_Or_Availability;

   function Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating return Boolean is
   begin
      return Workspace_Restore_Action_Is_Safe (Workspace_Skip_Missing_File)
        and then Workspace_Restore_Action_Is_Safe (Workspace_Fallback_To_First_Available_File)
        and then Workspace_Restore_Action_Is_Safe (Workspace_Ignore_Missing_Expanded_Path)
        and then not Workspace_Restore_Action_Is_Safe (Workspace_Reject_Fabricated_Project)
        and then Workspace_Restore_Action_Fabricates_State (Workspace_Reject_Fabricated_Project)
        and then Workspace_Restore_Action_Fabricates_State (Workspace_Reject_Fabricated_Buffer)
        and then not Workspace_Restore_Action_Fabricates_State (Workspace_Skip_Missing_File);
   end Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating;

   function Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads return Boolean is
   begin
      return Command_Availability_When_No_Selection (Quick_Open_Surface).State = Target_No_Result_Selected
        and then Command_Availability_When_No_Selection (Diagnostics_Surface).State = Target_No_Diagnostic_Selected
        and then Command_Availability_When_No_Selection (Build_Surface).State = Target_No_Build_Candidate_Selected
        and then Recovery_Command_Is_Payload_Free (Recovery_Quick_Open_Clear_Query)
        and then Recovery_Command_Is_Payload_Free (Recovery_Diagnostics_Clear)
        and then Recovery_Command_Is_Payload_Free (Recovery_Build_Refresh_Candidates);
   end Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads;

   function Assert_Explicit_Caret_Policy_Required_For_Clamping return Boolean is
   begin
      return Caret_Target_Policy (Target_Line_Out_Of_Range, False) = "ignore caret target"
        and then Caret_Target_Policy (Target_Line_Out_Of_Range, True) = "clamp caret target"
        and then Caret_Target_Policy (Target_Available, False) = "restore caret";
   end Assert_Explicit_Caret_Policy_Required_For_Clamping;

   function Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards return Boolean is
   begin
      return not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_File_Reload_From_Disk)
        and then not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_File_Revert_Buffer)
        and then not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_Workspace_Load);
   end Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards;

   function Assert_Recovery_Commands_Route_Only_Through_Executor return Boolean is
   begin
      return Recovery_Command_Routes_Through_Executor (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Routes_Through_Executor (Recovery_Project_Search_Run)
        and then Recovery_Command_Routes_Through_Executor (Recovery_Build_Refresh_Candidates)
        and then Invocation_Source_May_Execute_Recovery_Command (Invocation_Executor)
        and then not Invocation_Source_May_Execute_Recovery_Command (Invocation_Render)
        and then not Invocation_Source_May_Execute_Recovery_Command (Invocation_Availability);
   end Assert_Recovery_Commands_Route_Only_Through_Executor;

   function Assert_Command_Sources_Have_No_Target_Payloads return Boolean is
   begin
      return not Invocation_Source_May_Carry_Target_Payload (Invocation_Command_Palette)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Keybinding)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Render)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Availability)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Executor);
   end Assert_Command_Sources_Have_No_Target_Payloads;

   function Assert_One_Primary_User_Readable_Outcome_Per_Command return Boolean is
      Missing_Quick_Open : constant Target_Validation_Result :=
        Make (Quick_Open_Surface, Target_Stale, "gone.adb");
      Missing_Build : constant Target_Validation_Result :=
        Make (Build_Surface, Target_Missing, "gone.gpr");
      Missing_Diagnostic : constant Target_Validation_Result :=
        Make (Diagnostics_Surface, Target_Source_Less);
   begin
      return Command_Outcome_Count_For_Validation (Missing_Quick_Open) = 1
        and then Command_Outcome_Count_For_Validation (Missing_Build) = 1
        and then Command_Outcome_Count_For_Validation (Missing_Diagnostic) = 1
        and then Command_Outcome_Is_User_Readable (Missing_Quick_Open)
        and then Command_Outcome_Is_User_Readable (Missing_Build)
        and then Command_Outcome_Is_User_Readable (Missing_Diagnostic);
   end Assert_One_Primary_User_Readable_Outcome_Per_Command;

   function Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly return Boolean is
   begin
      return Surface_Recovery_Label (Quick_Open_Surface, Target_Stale) =
          "Quick Open target stale"
        and then Surface_Recovery_Label (Build_Surface, Target_Candidate_Stale) =
          "Build candidate stale"
        and then Surface_Recovery_Label (Diagnostics_Surface, Target_Source_Less) =
          "Diagnostics target source-less"
        and then Surface_Recovery_Label (Outline_Surface, Target_Available) = "";
   end Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly;

end Editor.Missing_Stale_Recovery.Core_Audit;
