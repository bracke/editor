package Editor.Missing_Stale_Recovery.Core_Audit is

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

end Editor.Missing_Stale_Recovery.Core_Audit;
