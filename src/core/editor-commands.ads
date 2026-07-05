with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Cursors;
with Editor.Unicode;

package Editor.Commands is

   use Editor.Cursors;
   use Ada.Strings.Unbounded;

   type Command_Id is
     (No_Command,
      Command_Move_Left,
      Command_Move_Right,
      Command_Move_Up,
      Command_Move_Down,
      Command_Move_Line_Start,
      Command_Move_Line_End,
      Command_Move_Document_Start,
      Command_Move_Document_End,
      Command_Move_Word_Left,
      Command_Move_Word_Right,
      Command_Page_Up,
      Command_Page_Down,
      Command_Select_Left,
      Command_Select_Right,
      Command_Select_Up,
      Command_Select_Down,
      Command_Select_Word_Left,
      Command_Select_Word_Right,
      Command_Select_Word,
      Command_Select_Line,
      Command_Start_Rectangular_Selection,
      Command_Clear_Rectangular_Selection,
      Command_Extend_Selection_Line_Up,
      Command_Extend_Selection_Line_Down,
      Command_Select_Line_Start,
      Command_Select_Line_End,
      Command_Select_Document_Start,
      Command_Select_Document_End,
      Command_Select_Page_Up,
      Command_Select_Page_Down,
      Command_Insert_Newline,
      Command_Undo,
      Command_Redo,
      Command_Edit_History_Clear,
      Command_Copy,
      Command_Cut,
      Command_Paste,
      Command_Clipboard_Clear,
      Command_Select_All,
      Command_Selection_Clear,
      Command_Selection_Delete,
      Command_Line_Delete,
      Command_Line_Duplicate,
      Command_Line_Move_Up,
      Command_Line_Move_Down,
      Command_Indent_Increase,
      Command_Indent_Decrease,
      Command_Comment_Line,
      Command_Uncomment_Line,
      Command_Toggle_Line_Comment,
      Command_Line_Join_Next,
      Command_Line_Split_At_Caret,
      Command_Trim_Trailing_Whitespace,
      Command_Format_Buffer,
      Command_Char_Delete_Previous,
      Command_Char_Delete_Next,
      Command_Word_Delete_Previous,
      Command_Word_Delete_Next,
      Command_Save_File,
      Command_Save_File_As,
      Command_Reload_Active_Buffer,
      Command_Revert_Active_Buffer,
      Command_File_Conflict_Keep_Buffer,
      Command_File_Conflict_Reload_From_Disk,
      Command_File_Conflict_Overwrite_Disk,
      Command_File_Conflict_Cancel,
      Command_Rename_Buffer_File,
      Command_Delete_Buffer_File,
      Command_Copy_Buffer_File,
      Command_Move_Buffer_File,
      Command_Save_All,
      Command_Open_Quick_Open,
      Command_Close_Quick_Open,
      Command_Toggle_Quick_Open,
      Command_Accept_Quick_Open,
      Command_Quick_Open_Next_Result,
      Command_Quick_Open_Previous_Result,
      Command_Quick_Open_Query_Set,
      Command_Quick_Open_Query_Clear,
      Command_Quick_Open_Kind_Next,
      Command_Quick_Open_Kind_Previous,
      Command_Quick_Open_Kind_Clear,
      Command_Quick_Open_Scope_Set,
      Command_Quick_Open_Scope_Clear,
      Command_Quick_Open_Scope_From_Selected,
      Command_Quick_Open_Scope_Parent,
      Command_Quick_Open_Reveal_Active,
      Command_Quick_Open_Scope_Active_Directory,
      Command_Quick_Open_Create_From_Query,
      Command_Quick_Open_Create_With_Parents_From_Query,
      Command_Quick_Open_Priority_Toggle,
      Command_Quick_Open_Priority_Clear,
      Command_Open_Buffer_Switcher,
      Command_Close_Buffer_Switcher,
      Command_Accept_Buffer_Switcher,
      Command_Buffer_Switcher_Next_Result,
      Command_Buffer_Switcher_Previous_Result,
      Command_Buffer_Switcher_Filter_Clear,
      Command_Buffer_Switcher_Filter_Pinned,
      Command_Buffer_Switcher_Filter_Group,
      Command_Buffer_Switcher_Filter_Label,
      Command_Buffer_Switcher_Filter_Noted,
      Command_Buffer_Switcher_Sort_Default,
      Command_Buffer_Switcher_Sort_Recent,
      Command_Buffer_Switcher_Sort_Name,
      Command_Buffer_Switcher_Sort_Pinned,
      Command_Buffer_Switcher_Sort_Group,
      Command_Buffer_Switcher_Sort_Label,
      Command_Buffer_Switcher_Sort_Next,
      Command_Buffer_Switcher_Sort_Previous,
      Command_Buffer_Switcher_Selected_Close,
      Command_Buffer_Switcher_Selected_Pin,
      Command_Buffer_Switcher_Selected_Unpin,
      Command_Buffer_Switcher_Selected_Toggle_Pin,
      Command_Buffer_Switcher_Selected_Group_Assign,
      Command_Buffer_Switcher_Selected_Group_Clear,
      Command_Buffer_Switcher_Selected_Label_Set,
      Command_Buffer_Switcher_Selected_Label_Clear,
      Command_Buffer_Switcher_Selected_Note_Set,
      Command_Buffer_Switcher_Selected_Note_Clear,
      Command_Buffer_Switcher_Preview_Toggle,
      Command_Buffer_Switcher_Preview_Show,
      Command_Buffer_Switcher_Preview_Hide,
      Command_Buffer_Switcher_Preview_Next_Line,
      Command_Buffer_Switcher_Preview_Previous_Line,
      Command_Buffer_Switcher_Preview_Center_Cursor,
      Command_Buffer_Switcher_Mark_Toggle,
      Command_Buffer_Switcher_Mark_Set,
      Command_Buffer_Switcher_Mark_Clear,
      Command_Buffer_Switcher_Mark_Clear_All,
      Command_Buffer_Switcher_Mark_Invert_Visible,
      Command_Buffer_Switcher_Mark_Visible,
      Command_Buffer_Switcher_Mark_Clear_Visible,
      Command_Buffer_Switcher_Mark_Pinned,
      Command_Buffer_Switcher_Mark_Group,
      Command_Buffer_Switcher_Mark_Label,
      Command_Buffer_Switcher_Mark_Noted,
      Command_Buffer_Switcher_Mark_Close_Marked,
      Command_Buffer_Switcher_Mark_Confirm,
      Command_Buffer_Switcher_Mark_Cancel,
      Command_Buffer_Switcher_Mark_Pin_Marked,
      Command_Buffer_Switcher_Mark_Unpin_Marked,
      Command_Buffer_Switcher_Mark_Clear_Metadata,
      Command_Buffer_Switcher_Mark_Group_Assign,
      Command_Buffer_Switcher_Mark_Group_Clear,
      Command_Buffer_Switcher_Mark_Label_Set,
      Command_Buffer_Switcher_Mark_Label_Clear,
      Command_Buffer_Switcher_Mark_Note_Set,
      Command_Buffer_Switcher_Mark_Note_Clear,
      Command_Buffer_Switcher_Mark_Review_Toggle,
      Command_Buffer_Switcher_Mark_Review_Show,
      Command_Buffer_Switcher_Mark_Review_Hide,
      Command_Buffer_Switcher_Pending_Mark_Review_Toggle,
      Command_Buffer_Switcher_Pending_Mark_Review_Show,
      Command_Buffer_Switcher_Pending_Mark_Review_Hide,
      Command_Buffer_Switcher_Pending_Mark_Next,
      Command_Buffer_Switcher_Pending_Mark_Previous,
      Command_Buffer_Switcher_Pending_Mark_Summary,
      Command_Buffer_Switcher_Pending_Mark_Remove_Selected,
      Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Summary,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Next,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Previous,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show,
      Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide,
      Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Next,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Previous,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale,
      Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary,
      Command_Buffer_Switcher_Mark_Next,
      Command_Buffer_Switcher_Mark_Previous,
      Command_Buffer_Switcher_Mark_Summary,
      Command_Open_Command_Palette,
      Command_Palette_Show_Command_Help,
      Command_Toggle_Theme,
      Command_Set_Theme_Light,
      Command_Set_Theme_Dark,
      Command_Cancel,
      Command_Open_File,
      Command_Open_Project,
      Command_Switch_Project,
      Command_Show_Recent_Projects,
      Command_Open_Selected_Recent_Project,
      Command_Clear_Recent_Projects,
      Command_Remove_Selected_Recent_Project,
      Command_Remove_Missing_Recent_Projects,
      Command_Select_Next_Recent_Project,
      Command_Select_Previous_Recent_Project,
      Command_Close_Project,
      Command_Clear_Project,
      Command_Refresh_File_Tree,
      Command_Refresh_Project_Files,
      Command_Project_Files_Summary,
      Command_Reveal_Active_File_In_Tree,
      Command_New_Buffer,
      Command_Close_Active_Buffer,
      Command_Confirm_Close_Save,
      Command_Confirm_Close_Discard,
      Command_Cancel_Close,
      Command_Reopen_Closed_Buffer,
      Command_Close_Other_Buffers,
      Command_Close_All_Buffers,
      Command_Close_All_Clean_Buffers,
      Command_Pin_Buffer,
      Command_Unpin_Buffer,
      Command_Toggle_Buffer_Pin,
      Command_Set_Buffer_Label,
      Command_Clear_Buffer_Label,
      Command_Edit_Buffer_Label,
      Command_Show_Buffer_Label,
      Command_Set_Buffer_Note,
      Command_Clear_Buffer_Note,
      Command_Edit_Buffer_Note,
      Command_Show_Buffer_Note,
      Command_Assign_Buffer_Group,
      Command_Clear_Buffer_Group,
      Command_Switch_Buffer_Group,
      Command_Next_Buffer_Group,
      Command_Previous_Buffer_Group,
      Command_Show_All_Buffer_Groups,
      Command_Cancel_Pending_Transition,
      Command_Retry_Pending_Transition,
      Command_Discard_Pending_Transition,
      Command_Next_Buffer,
      Command_Previous_Buffer,
      Command_Previous_Recent_Buffer,
      Command_Next_Recent_Buffer,
      Command_Switch_Buffer,
      Command_Toggle_Minimap,
      Command_Toggle_Scrollbars,
      Command_Toggle_Line_Numbers,
      Command_Toggle_Line_Number_Mode,
      Command_Set_Absolute_Line_Numbers,
      Command_Set_Relative_Line_Numbers,
      Command_Set_Hybrid_Line_Numbers,
      Command_Toggle_Current_Line_Highlight,
      Command_Toggle_Cursor_Blink,
      Command_Toggle_Syntax_Colouring,
      Command_Toggle_Diagnostics,
      Command_Toggle_Problems_Panel,
      Command_Next_Diagnostic,
      Command_Previous_Diagnostic,
      Command_Toggle_Bookmark,
      Command_Next_Bookmark,
      Command_Previous_Bookmark,
      Command_Clear_Bookmarks,
      Command_Clear_All_Bookmarks,
      Command_Bookmark_Toggle_Current_Location,
      Command_Bookmark_Clear_All,
      Command_Bookmark_Next,
      Command_Bookmark_Previous,
      Command_Bookmark_Goto_Next,
      Command_Bookmark_Goto_Previous,
      Command_Bookmark_Open_Selected,
      Command_Bookmark_Reveal_Current,
      Command_Bookmark_Remove_Selected,
      Command_Bookmark_Show,
      Command_Bookmark_Hide,
      Command_Bookmark_Toggle,
      Command_Toggle_Cursor_Style,
      Command_Goto_Start,
      Command_Goto_End,
      Command_Goto_Line,
      Command_Goto_Line_Toggle,
      Command_Goto_Line_Prefill_Current,
      Command_Goto_Line_Query_Set,
      Command_Goto_Line_Query_Clear,
      Command_Navigation_Back,
      Command_Navigation_Forward,
      Command_Navigation_History_Clear,
      Command_Close_Goto_Line,
      Command_Accept_Goto_Line,
      Command_Find_Show,
      Command_Find_Hide,
      Command_Find_Toggle,
      Command_Find_Query_Set,
      Command_Find_Query_Clear,
      Command_Find_Case_Toggle,
      Command_Find_Case_Clear,
      Command_Find_Whole_Word_Toggle,
      Command_Find_Whole_Word_Clear,
      Command_Find_From_Selection,
      Command_Find_From_Active_Word,
      Command_Active_Find_Next,
      Command_Active_Find_Previous,
      Command_Find_First,
      Command_Find_Last,
      Command_Find_Reveal_Current,
      Command_Replace_Show,
      Command_Replace_Hide,
      Command_Replace_Toggle,
      Command_Replace_Text_Set,
      Command_Replace_Text_Clear,
      Command_Replace_Current,
      Command_Replace_All,
      Command_Run_Project_Search,
      Command_Rerun_Project_Search,
      Command_Open_Project_Search_Bar,
      Command_Toggle_Project_Search_Bar,
      Command_Close_Project_Search_Bar,
      Command_Run_Project_Search_From_Bar,
      Command_Project_Search_From_Selection,
      Command_Project_Search_From_Active_Word,
      Command_Project_Search_Active_Directory,
      Command_Clear_Project_Search,
      Command_Open_Selected_Project_Search_Result,
      Command_Move_Project_Search_Selection_Up,
      Command_Move_Project_Search_Selection_Down,
      Command_Next_Project_Search_Result,
      Command_Previous_Project_Search_Result,
      Command_First_Project_Search_Result,
      Command_Last_Project_Search_Result,
      Command_Reveal_Active_Project_Search_Result,
      Command_Project_Search_Scope_Selected_Directory,
      Command_Project_Search_Kind_Next,
      Command_Project_Search_Kind_Previous,
      Command_Project_Search_Kind_Clear,
      Command_Project_Search_Scope_Set,
      Command_Project_Search_Scope_Clear,
      Command_Project_Search_Case_Toggle,
      Command_Project_Search_Case_Clear,
      Command_Project_Search_Whole_Word_Toggle,
      Command_Project_Search_Whole_Word_Clear,
      Command_Project_Search_Regex_Toggle,
      Command_Project_Search_Regex_Clear,
      Command_Project_Search_Include_Filter_Set,
      Command_Project_Search_Exclude_Filter_Set,
      Command_Project_Search_Include_Filter_Clear,
      Command_Project_Search_Exclude_Filter_Clear,
      Command_Project_Search_Replace_Preview,
      Command_Project_Search_Replace_Toggle_Selected,
      Command_Project_Search_Replace_Include_Selected,
      Command_Project_Search_Replace_Exclude_Selected,
      Command_Project_Search_Replace_Include_File,
      Command_Project_Search_Replace_Exclude_File,
      Command_Project_Search_Replace_Include_All,
      Command_Project_Search_Replace_Exclude_All,
      Command_Project_Search_Replace_Selected,
      Command_Project_Search_Replace_All_Included,
      Command_Project_Search_Replace_Clear_Preview,
      Command_Show_Search_Results_Panel,
      Command_Focus_Editor_Text,
      Command_Focus_Search_Results,
      Command_Focus_Problems,
      Command_Toggle_Bottom_Panel_Focus,
      Command_Search_Results_Move_Up,
      Command_Search_Results_Move_Down,
      Command_Search_Results_Page_Up,
      Command_Search_Results_Page_Down,
      Command_Search_Results_Open_Selected,
      Command_Problems_Move_Up,
      Command_Problems_Move_Down,
      Command_Problems_Page_Up,
      Command_Problems_Page_Down,
      Command_Problems_Open_Selected,
      Command_Problems_Filter_All,
      Command_Problems_Filter_Errors,
      Command_Problems_Filter_Warnings,
      Command_Problems_Filter_Info,
      Command_Problems_Filter_Hints,
      Command_Problems_Sort_By_Location,
      Command_Problems_Sort_By_Severity,
      Command_Problems_Sort_By_Source,
      Command_Problems_Group_By_Severity,
      Command_Problems_Group_By_Source,
      Command_Problems_Focus_Editor,
      Command_Focus_File_Tree,
      Command_File_Tree_Move_Up,
      Command_File_Tree_Move_Down,
      Command_File_Tree_Page_Up,
      Command_File_Tree_Page_Down,
      Command_File_Tree_Open_Selected,
      Command_File_Tree_Create_File,
      Command_File_Tree_Create_Directory,
      Command_File_Tree_Rename_Selected,
      Command_File_Tree_Delete_Selected,
      Command_File_Tree_Expand_Selected,
      Command_File_Tree_Collapse_Selected,
      Command_File_Tree_Toggle_Selected,
      Command_File_Tree_Collapse_All,
      Command_File_Tree_Expand_To_Active_File,
      Command_Save_Settings,
      Command_Reload_Settings,
      Command_Reset_Settings_To_Defaults,
      Command_Save_Keybindings,
      Command_Reload_Keybindings,
      Command_Validate_Keybindings,
      Command_Keybindings_Show,
      Command_Keybindings_Focus,
      Command_Keybindings_Assign_Selected,
      Command_Keybindings_Remove_Selected,
      Command_Keybindings_Reset_To_Defaults,
      Command_Keybindings_Filter_Conflicts,
      Command_Keybindings_Filter_Unbound,
      Command_Keybindings_Clear_Filter,
      Command_Keybindings_Cancel_Capture,
      Command_Startup_Show_Summary,
      Command_Configuration_Recover_Show,
      Command_Configuration_Audit,
      Command_Configuration_Reset_Settings,
      Command_Configuration_Reset_Keybindings,
      Command_Configuration_Reset_Workspace,
      Command_Configuration_Reset_Recent_Projects,
      Command_Configuration_Reset_All,
      Command_Configuration_Reset_All_Confirm,
      Command_Configuration_Reset_All_Cancel,
      Command_Configuration_Save_Clean_Settings,
      Command_Configuration_Save_Clean_Keybindings,
      Command_Configuration_Save_Clean_Workspace,
      Command_Configuration_Save_Clean_Recent_Projects,
      Command_Save_Workspace_State,
      Command_Restore_Workspace_State,
      Command_Clear_Workspace_State,
      Command_Toggle_Feature_Panel,
      Command_Show_Feature_Panel,
      Command_Hide_Feature_Panel,
      Command_Focus_Feature_Panel,
      Command_Clear_Feature_Panel,
      Command_Feature_Panel_Select_Next,
      Command_Feature_Panel_Select_Previous,
      Command_Feature_Panel_Open_Selected,
      Command_Refresh_Outline,
      Command_Refresh_Outline_Project_Index,
      Command_Goto_Declaration,
      Command_Goto_Body,
      Command_Goto_Spec,
      Command_Find_References,
      Command_Workspace_Symbols,
      Command_Show_Hover,
      Command_Show_Completions,
      Command_Semantic_Completion_Select_Next,
      Command_Semantic_Completion_Select_Previous,
      Command_Semantic_Completion_Accept,
      Command_Semantic_Popup_Dismiss,
      Command_Rename_Symbol_Preview,
      Command_Rename_Symbol_Apply,
      Command_Semantic_Refresh_Buffer,
      Command_Semantic_Refresh_Project_Index,
      Command_Language_Index_Clear,
      Command_Language_Index_Status,
      Command_Clear_Outline,
      Command_Show_Outline,
      Command_Focus_Outline,
      Command_Open_Selected_Outline_Item,
      Command_Select_Current_Outline_Symbol,
      Command_Reveal_Current_Outline_Symbol,
      Command_Next_Outline_Symbol,
      Command_Previous_Outline_Symbol,
      Command_Select_Next_Outline_Item,
      Command_Select_Previous_Outline_Item,
      Command_Focus_Outline_Filter,
      Command_Filter_Outline,
      Command_Clear_Outline_Filter,
      Command_Toggle_Outline_Filter,
      Command_Outline_Filter_History_Previous,
      Command_Outline_Filter_History_Next,
      Command_Clear_Outline_Filter_History,
      Command_Show_Messages,
      Command_Clear_Messages,
      Command_Clear_Selected_Message,
      Command_Copy_Selected_Message_Text,
      Command_Clear_Info_Messages,
      Command_Clear_Warning_Messages,
      Command_Clear_Error_Messages,
      Command_Toggle_Message_Info,
      Command_Toggle_Message_Warnings,
      Command_Toggle_Message_Errors,
      Command_Show_All_Messages,
      Command_Clear_Message_Filter,
      Command_Dismiss_Latest_Message,
      Command_Dismiss_All_Messages,
      Command_Search_Results_Search_Active_Buffer,
      Command_Search_Results_Focus_Query,
      Command_Search_Results_Repeat_Active_Buffer,
      Command_Search_Results_Query_History_Previous,
      Command_Search_Results_Query_History_Next,
      Command_Search_Results_Toggle_Case_Sensitive,
      Command_Show_Search_Results_Feature,
      Command_Clear_Search_Results_Feature,
      Command_Diagnostics_Show,
      Command_Diagnostics_Clear,
      Command_Diagnostics_Toggle_Info,
      Command_Diagnostics_Toggle_Warnings,
      Command_Diagnostics_Toggle_Errors,
      Command_Diagnostics_Show_All,
      Command_Diagnostics_Clear_Filter,
      Command_Diagnostics_Filter_Errors,
      Command_Diagnostics_Filter_Warnings,
      Command_Diagnostics_Filter_Info_Notes,
      Command_Diagnostics_Filter_Source,
      Command_Diagnostics_Filter_Build,
      Command_Diagnostics_Clear_Build,
      Command_Diagnostics_Open_Selected,
      Command_Diagnostic_Open_Source,
      Command_Diagnostic_Suppress_Selected,
      Command_Diagnostic_Show_Suppressed,
      Command_Diagnostic_Restore_Last_Suppressed,
      Command_Diagnostic_Restore_Selected_Suppressed,
      Command_Diagnostic_Clear_Suppressed,
      Command_Diagnostic_Apply_Quick_Fix,
      Command_Diagnostics_Execute_Selected_Action,
      Command_Diagnostics_Select_Next,
      Command_Diagnostics_Select_Previous,
      Command_Diagnostics_Clear_Selected,
      Command_Diagnostics_Copy_Selected_Text,
      Command_Diagnostics_Clear_Info,
      Command_Diagnostics_Clear_Warnings,
      Command_Diagnostics_Clear_Errors,
      Command_Diagnostics_Toggle_Editor_Source,
      Command_Diagnostics_Toggle_File_Source,
      Command_Diagnostics_Toggle_Project_Source,
      Command_Diagnostics_Toggle_External_Source,
      Command_Diagnostics_Toggle_Unknown_Source,
      Command_Run_Project,
      Command_Run_Tests,
      Command_Terminal_Toggle,
      Command_Terminal_Show,
      Command_Terminal_Hide,
      Command_Terminal_Focus,
      Command_Terminal_Clear,
      Command_Terminal_Clear_Output,
      Command_Terminal_Select_Next_Task,
      Command_Terminal_Select_Previous_Task,
      Command_Terminal_Run_Selected_Task,
      Command_Terminal_Rerun_Last_Task,
      Command_Terminal_Cancel_Task,
      Command_Build_UI_Toggle,
      Command_Build_UI_Show,
      Command_Build_UI_Hide,
      Command_Build_UI_Focus,
      Command_Build_Result_Focus,
      Command_Build_Output_Details_Focus,
      Command_Build_Output_Details_Select_Stdout,
      Command_Build_Output_Details_Select_Stderr,
      Command_Build_Output_Details_Select_Merged,
      Command_Build_Refresh_Candidates,
      Command_Build_Select_First_Candidate,
      Command_Build_Select_Next_Candidate,
      Command_Build_Select_Previous_Candidate,
      Command_Build_Clear_Selected_Candidate,
      Command_Build_Set_Mode_Default,
      Command_Build_Set_Mode_Debug,
      Command_Build_Set_Mode_Release,
      Command_Build_Set_Mode_Validation,
      Command_Build_Toggle_Diagnostics_Ingestion,
      Command_Build_Cycle_Output_Limit,
      Command_Build_Toggle_Option_Verbose,
      Command_Build_Toggle_Option_Keep_Going,
      Command_Build_Acknowledge_Consent,
      Command_Build_Clear_Consent,
      Command_Build_Run,
      Command_Build_Cancel,
      Command_Build_Run_User_Opt_In_Test_Seam,
      Command_Format_Selected_Text,
      Command_Toggle_Format_On_Save);

   type Command_Category is
     (File_Category,
      Project_Category,
      Edit_Category,
      Selection_Category,
      Navigation_Category,
      Search_Category,
      Panel_Category,
      View_Category,
      Diagnostics_Category,
      Bookmarks_Category,
      Overlay_Category,
      Message_Category,
      Theme_Category,
      Settings_Category,
      Workspace_Category,
      Internal_Category);

   type Command_Visibility is
     (Hidden_Command,
      Palette_Command);

   type Command_Availability_Status is
     (Command_Available,
      Command_Unavailable);

   type Command_Availability is record
      Status : Command_Availability_Status := Command_Available;
      Reason : Unbounded_String := Null_Unbounded_String;
   end record;

   Reason_Target_Stale : constant String :=
     "Target is stale; refresh required.";
   Reason_Target_Missing : constant String :=
     "Target no longer exists.";
   Reason_Close_Review_Stale : constant String :=
     "Close review is stale";
   Reason_Project_Search_Result_Stale : constant String :=
     "Search result is stale; run Project Search again.";
   Reason_Search_Result_Stale_Rerun : constant String :=
     "Search result is stale; rerun search.";
   Reason_Replacement_Preview_Stale : constant String :=
     "Replacement preview is stale";
   Reason_Replacement_Preview_Stale_Rerun : constant String :=
     "Replacement preview is stale; rerun search.";
   Reason_Selected_Replacement_Stale : constant String :=
     "Selected replacement is stale";
   Reason_Diagnostic_Edit_Stale_Target : constant String :=
     "Diagnostic edit unavailable: stale edit target";
   Reason_File_Tree_Item_Stale : constant String :=
     "File Tree item is stale.";
   Reason_Target_Line_Unavailable : constant String :=
     "Target line is unavailable.";
   Reason_Diagnostic_Target_Line_Unavailable : constant String :=
     "Diagnostic target line is unavailable.";
   Reason_Diagnostic_Target_Line_Outside_Buffer : constant String :=
     "Diagnostic target line is outside the buffer";
   Reason_Diagnostic_Target_Column_Unavailable : constant String :=
     "Diagnostic target column is unavailable.";
   Reason_Diagnostic_Target_Column_Outside_Line : constant String :=
     "Diagnostic target column is outside the line";

   type Command_Family_Id is
     (No_Command_Family,
      File_Lifecycle_Family);

   type Command_Effect_Classification_Id is
     (No_Command_Effect,
      Writes_Buffer_Text_To_Associated_File,
      Writes_Buffer_Text_To_Explicit_Target_And_Associates,
      Closes_Active_Buffer,
      Reopens_Safe_File_Reference,
      Rereads_Associated_File,
      Discards_Unsaved_Changes_And_Rereads,
      Renames_Associated_File,
      Deletes_Associated_File,
      Copies_Associated_File,
      Moves_Associated_File);

   function Available return Command_Availability;

   function Unavailable
     (Reason : String) return Command_Availability;

   --  Normalize common workflow messages so Command Palette availability,
   --  Executor blocking, status feedback, and empty-state guidance use the
   --  same user-facing wording for the same condition.  This is a pure
   --  string projection; it does not inspect or mutate editor state.
   function Normalize_Workflow_Message
     (Text : String) return String;

   function Is_Available
     (Availability : Command_Availability) return Boolean;

   function Unavailable_Reason
     (Availability : Command_Availability) return String;

   type Command_Descriptor is record
      Id          : Command_Id := No_Command;
      Name        : Unbounded_String := Null_Unbounded_String;
      Description : Unbounded_String := Null_Unbounded_String;
      Category    : Command_Category := Internal_Category;
      Visibility  : Command_Visibility := Hidden_Command;
      Bindable    : Boolean := False;
      Destructive : Boolean := False;
      Lifecycle   : Boolean := False;
      Configuration : Boolean := False;
      Summary : Unbounded_String := Null_Unbounded_String;
      Availability_Summary : Unbounded_String := Null_Unbounded_String;
      Mutation_Summary : Unbounded_String := Null_Unbounded_String;
      Filesystem_Effect_Summary : Unbounded_String := Null_Unbounded_String;
      State_Preservation_Summary : Unbounded_String := Null_Unbounded_String;
      Non_Goal_Summary : Unbounded_String := Null_Unbounded_String;
      Requires_Explicit_Target : Boolean := False;
      Target_Prompt_Capable : Boolean := False;
      Target_Prompt_Label : Unbounded_String := Null_Unbounded_String;
      Family : Command_Family_Id := No_Command_Family;
      Effect_Classification : Command_Effect_Classification_Id := No_Command_Effect;
   end record;

   type Command_Palette_Candidate is record
      Id             : Command_Id := No_Command;
      Label          : Unbounded_String := Null_Unbounded_String;
      Description    : Unbounded_String := Null_Unbounded_String;
      Category       : Command_Category := Internal_Category;
      Category_Label : Unbounded_String := Null_Unbounded_String;
      Available      : Boolean := True;
      Reason         : Unbounded_String := Null_Unbounded_String;
      Has_Keybinding : Boolean := False;
      Keybinding_Display : Unbounded_String := Null_Unbounded_String;
      Reference_Summary : Unbounded_String := Null_Unbounded_String;
      Family : Command_Family_Id := No_Command_Family;
      Effect_Classification : Command_Effect_Classification_Id := No_Command_Effect;
      Match_Score    : Natural := 0;
      Registry_Order : Natural := 0;
   end record;

   package Command_Palette_Candidate_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Palette_Candidate);

   package Command_Descriptor_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Descriptor);

   type Command_Audit_Failure_Kind is
     (Missing_Descriptor,
      Missing_Label,
      Missing_Description,
      Missing_Category,
      Missing_Stable_Name,
      Duplicate_Stable_Name,
      Missing_Availability,
      Missing_Executor_Handling,
      Invalid_Bindability,
      Invalid_Default_Keybinding,
      Missing_Classification,
      Ambiguous_Save_Command,
      Route_Bypasses_Executor,
      Unexpected_Domain_Mutation);

   type Command_Audit_Failure is record
      Kind    : Command_Audit_Failure_Kind := Missing_Descriptor;
      Command : Command_Id := No_Command;
   end record;

   package Command_Audit_Failure_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Command_Audit_Failure);

   --  Build a command descriptor from explicit metadata. Stable persisted
   --  command names are intentionally not derived here; they are provided by
   --  Stable_Command_Name and are independent from labels.
   --  @param Id Command identifier described by the record.
   --  @param Stable_Name Expected stable persisted name for audit checking.
   --  @param Label User-facing command label.
   --  @param Description User-facing command description.
   --  @param Category Command grouping/category.
   --  @param Visible True when command appears in the command palette.
   --  @param Bindable True when command may be targeted by keybindings.
   --  @param Destructive True when command may discard/delete/clear state.
   --  @param Lifecycle True when command participates in lifecycle transitions.
   --  @param Configuration True when command mutates/validates configuration.
   --  @return Descriptor carrying the supplied metadata.
   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor;


   --  Return True when Id is one of the canonical file lifecycle commands
   --  covered by the read-only command-reference projection.
   function Is_File_Lifecycle_Command
     (Id : Command_Id) return Boolean;

   function Reference_Summary
     (Id : Command_Id) return String;

   function Reference_Availability_Summary
     (Id : Command_Id) return String;

   function Reference_Mutation_Summary
     (Id : Command_Id) return String;

   function Reference_Filesystem_Effect_Summary
     (Id : Command_Id) return String;

   function Reference_State_Preservation_Summary
     (Id : Command_Id) return String;

   function Reference_Non_Goal_Summary
     (Id : Command_Id) return String;

   function Reference_Command_Family
     (Id : Command_Id) return Command_Family_Id;

   function Reference_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id;

   --  Minimal descriptor-owned explicit-target prompt metadata.  These
   --  accessors are static, read-only, and do not compute availability,
   --  open prompts, seed target input, or execute filesystem work.
   function Command_Requires_Explicit_Target
     (Id : Command_Id) return Boolean;

   function Command_Is_Target_Prompt_Capable
     (Id : Command_Id) return Boolean;

   function Command_Target_Prompt_Label
     (Id : Command_Id) return String;

   function File_Lifecycle_Target_Prompt_Metadata_Minimal return Boolean;

   --  cleanup guard: verifies that the retained explicit-target
   --  prompt metadata remains minimal and canonical, and that descriptor
   --  projection/accessors agree without introducing prompt-reference prose,
   --  command-name caches, settings, or persistence-adjacent metadata.
   function File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal
     return Boolean;

   --  final freeze guard: verifies the exact descriptor-owned
   --  explicit-target prompt mapping, prompted-name absence, and minimal
   --  metadata boundary after cleanup and de-duplication.
   function File_Lifecycle_Target_Prompt_Metadata_Frozen return Boolean;

   function Command_Summary
     (Id : Command_Id) return String;

   function Command_Availability_Summary
     (Id : Command_Id) return String;

   function Command_Mutation_Summary
     (Id : Command_Id) return String;

   function Command_Filesystem_Effect_Summary
     (Id : Command_Id) return String;

   function Command_State_Preservation_Summary
     (Id : Command_Id) return String;

   function Command_Non_Goal_Summary
     (Id : Command_Id) return String;

   function Command_Family
     (Id : Command_Id) return Command_Family_Id;

   function Command_Family_Label
     (Family : Command_Family_Id) return String;

   function Command_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id;

   function Command_Effect_Classification_Label
     (Effect : Command_Effect_Classification_Id) return String;

   function Has_Command_Reference
     (Id : Command_Id) return Boolean;

   function File_Lifecycle_Command_Reference_Coherent return Boolean;

   --  Return the descriptor for Id. Command identifiers are stable command
   --  targets used by keybindings, the command palette, and the executor.
   --  @param Id Command identifier.
   --  @return User-facing command descriptor.
   function Descriptor
     (Id : Command_Id) return Command_Descriptor;

   --  Return the stable user-facing command label.
   --  @param Id Command identifier.
   --  @return Label from the centralized descriptor registry.
   function Label
     (Id : Command_Id) return String;

   --  Return the command category used for palette grouping/filtering.
   --  @param Id Command identifier.
   --  @return Category from the centralized descriptor registry.
   function Category
     (Id : Command_Id) return Command_Category;

   --  Return the stable user-facing label for a command category.
   --  @param Category Command category enum value.
   --  @return Palette/grouping label centralized with command metadata.
   function Category_Label
     (Category : Command_Category) return String;

   --  Return the discoverability category label for a concrete command.
   --  This is descriptor-derived display metadata only: it does not change
   --  stable command identity, Executor routing, or persisted keybinding names.
   --  @param Id Command identifier.
   --  @return User-facing category label, with command-surface refinements such
   --          as Build, File Tree, Outline, Recent Projects, and Keybindings.
   function Discoverability_Category_Label
     (Id : Command_Id) return String;

   --  Return compact classification markers for command help/discovery rows.
   --  The markers are observational descriptor metadata and never affect
   --  availability, confirmation, or command execution.
   --  @param Id Command identifier.
   --  @return Comma-separated markers such as destructive, lifecycle,
   --          configuration, navigation, editing, view, search, non-bindable.
   function Classification_Label
     (Id : Command_Id) return String;

   --  Return the UI surface/panel where a command is especially relevant, if
   --  such relevance can be derived from stable command metadata. This is
   --  display/ranking metadata only and never carries a panel row, file path,
   --  diagnostic id, build candidate id, or any other execution payload.
   function Surface_Relevance_Label
     (Id : Command_Id) return String;

   --  Return compact guard/confirmation markers for command help. These labels
   --  describe retained Executor guards and never grant availability.
   function Guard_Label
     (Id : Command_Id) return String;

   --  Return True when a concrete command has the discovery metadata    --  requires for search/help projection. This is descriptor-only: it never
   --  consults editor state, keybindings, availability, render state, files, or
   --  the executor.
   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean;

   --  Return True when all palette-visible commands are discoverable and all
   --  hidden/internal commands remain outside the normal palette. This helper is
   --  for route/configuration audits and performs no command execution.
   function Command_Discoverability_Coherent return Boolean;


   --  Return the first command id in the stable registry enumeration.
   --  @return First command identifier.
   function First_Command return Command_Id;

   --  Return the last command id in the stable registry enumeration.
   --  @return Last command identifier.
   function Last_Command return Command_Id;

   --  Return the next command id after Id in deterministic registry order.
   --  No_Command participates only when supplied as Id; normal concrete
   --  traversal should start at First_Concrete_Command or use Command_At.
   --  @param Id Current command identifier.
   --  @param Found True when a following command exists.
   --  @return Following command id, or No_Command when no next value exists.
   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id;

   --  Return the first concrete command id, excluding No_Command.
   --  @return First executable/user command id.
   function First_Concrete_Command return Command_Id;

   --  Return the number of concrete command ids, excluding No_Command.
   --  @return Count of command ids requiring metadata/executor coverage.
   function Concrete_Command_Count return Natural;

   --  Visit all concrete command ids in deterministic registry order.
   --  No_Command is intentionally excluded.
   --  @param Process Callback invoked once per concrete command id.
   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id));

   --  Return True when Id is inside the stable command-id enumeration.
   --  This exists for audit readability; Command_Id values are always valid
   --  when statically typed.
   --  @param Id Command identifier.
   --  @return True for every value of Command_Id.
   function Is_Valid_Command
     (Id : Command_Id) return Boolean;

   --  Return True when a command cannot be executed as a bare palette action
   --  and requires payload or existing contextual state. This helper is static
   --  command metadata and never evaluates editor state.
   --  @param Id Command identifier.
   --  @return True for payload/context-dependent command ids.
   function Requires_Context
     (Id : Command_Id) return Boolean;

   --  Return True when a concrete command has a non-empty, non-placeholder,
   --  trimmed user-facing label in the centralized descriptor registry.
   --  @param Id Command identifier.
   --  @return True when the descriptor label is stable enough for UI/audits.
   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean;

   --  Return True when Id is a concrete user/executor command.
   --  No_Command is the only non-concrete command id.
   --  @param Id Command identifier.
   --  @return True for every executable command id except No_Command.
   function Is_Concrete_Command
     (Id : Command_Id) return Boolean;

   --  Return True for a registered command id that is part of the public
   --  build-command UX surface. build.run is a guarded, descriptor-owned
   --  public command that routes through Executor and the structured,
   --  consent-gated build runner.
   --  @param Id Command identifier.
   --  @return True for public build command metadata.
   function Is_Public_Build_Command
     (Id : Command_Id) return Boolean;

   --  Return True for build-related command ids that are internal/test-only
   --  seams and must stay hidden, non-bindable, and Executor-routed.
   --  @param Id Command identifier.
   --  @return True for current internal build test-seam command ids.
   function Is_Internal_Build_Test_Seam_Command
     (Id : Command_Id) return Boolean;

   --  Return True for commands that may be referenced by test fixtures but
   --  must not be exposed as normal product features.
   --  @param Id Command identifier.
   --  @return True for explicit test-only command seams.
   function Is_Test_Only_Command
     (Id : Command_Id) return Boolean;


   --  Return the stable persistence identifier for Id. This identifier is
   --  not a user-facing label and must remain stable across label changes.
   --  @param Id Command identifier.
   --  @return Stable lowercase hyphenated command name.
   function Stable_Command_Name
     (Id : Command_Id) return String;

   --  Resolve a stable persisted command name to a command id.
   --  @param Name Stable lowercase hyphenated command name.
   --  @param Found True when Name resolves to a known command.
   --  @return Resolved command id, or No_Command when not found.
   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id;


   --  Return True when Id has descriptor metadata in the registry.
   --  No_Command has sentinel metadata but is not executable metadata.
   --  @param Id Command identifier.
   --  @return True when Descriptor(Id) is self-consistent.
   function Has_Descriptor
     (Id : Command_Id) return Boolean;

   --  Return True when Id has a stable persisted command name.
   --  The name is for keybinding/configuration persistence and is not the
   --  user-facing label.
   --  @param Id Command identifier.
   --  @return True for bindable concrete commands with non-empty stable names.
   function Has_Stable_Name
     (Id : Command_Id) return Boolean;

   --  Return True when Executor.Command_Availability intentionally covers Id.
   --  This helper is static metadata for audit tests and does not call the
   --  executor or inspect editor state.
   --  @param Id Command identifier.
   --  @return True for every concrete command id.
   function Has_Availability_Handler
     (Id : Command_Id) return Boolean;

   --  Return True when Id may be targeted by user keybindings.
   --  Context-dependent commands may still be bindable when the executor can
   --  handle them from input routing.
   --  @param Id Command identifier.
   --  @return True for concrete command ids; No_Command is never bindable.
   function Is_Bindable_Command
     (Id : Command_Id) return Boolean;

   --  Return True when Id is intentionally hidden/internal to command routing.
   --  Internal commands may still have labels and keybindings, but are not
   --  offered as command-palette discovery actions.
   --  @param Id Command identifier.
   --  @return True when the descriptor category is Internal or visibility is hidden.
   function Is_Internal_Command
     (Id : Command_Id) return Boolean;

   --  Return True when descriptor metadata satisfies the audit policy.
   --  This helper is descriptor-only: it never consults editor state,
   --  availability, keybindings, or executor routing.
   --  @param Id Command identifier.
   --  @return True when required label/category/description/visibility data exists.
   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean;

   --  Return the first static audit failure for a command, if any.
   --  This helper is side-effect-free and never executes commands.
   --  @param Id Command identifier to audit.
   --  @param Failure Populated with the first failure when Found is True.
   --  @param Found True when a failure was found.
   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean);

   --  Return static audit failures for all concrete commands.
   --  This helper is side-effect-free and excludes No_Command.
   --  @return Vector of actionable command audit failures.
   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector;

   --  Return a deterministic human-readable summary for command-audit tests.
   --  @param Failures Failure vector returned by Audit_Command_Registry.
   --  @return Summary with failure kinds and command ids.
   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String;


   --  Return True when Id is visible in the command palette.
   --  @param Id Command identifier.
   --  @return True when descriptor visibility is Palette_Command.
   function Is_Visible_In_Palette
     (Id : Command_Id) return Boolean;

   --  Return True when Id can discard, delete, clear, reset, or close user
   --  state/data without saving it first.
   --  @param Id Command identifier.
   --  @return True for explicitly classified destructive commands.
   function Is_Destructive_Command
     (Id : Command_Id) return Boolean;

   --  Return True when Id participates in project, workspace, buffer, recent,
   --  or pending-transition lifecycle changes.
   --  @param Id Command identifier.
   --  @return True for explicitly classified lifecycle commands.
   function Is_Lifecycle_Command
     (Id : Command_Id) return Boolean;

   --  Return True when Id mutates or validates global settings/keybinding
   --  configuration.
   --  @param Id Command identifier.
   --  @return True for explicitly classified configuration commands.
   function Is_Configuration_Command
     (Id : Command_Id) return Boolean;

   --  Return True for commands that write file buffer contents.
   --  @param Id Command identifier.
   --  @return True for Save File, Save File As, and Save All.
   function Is_File_Content_Save_Command
     (Id : Command_Id) return Boolean;

   --  Return True for commands that write structural workspace/session state.
   --  @param Id Command identifier.
   --  @return True for Save Workspace State.
   function Is_Workspace_Structural_Save_Command
     (Id : Command_Id) return Boolean;

   --  Return True for commands that write global editor preferences.
   --  @param Id Command identifier.
   --  @return True for Save Settings.
   function Is_Global_Settings_Save_Command
     (Id : Command_Id) return Boolean;

   --  Return True for commands that write global keybinding overrides.
   --  @param Id Command identifier.
   --  @return True for Save Keybindings.
   function Is_Global_Keybindings_Save_Command
     (Id : Command_Id) return Boolean;

   --  Return True for navigation-oriented commands.
   --  @param Id Command identifier.
   --  @return True for static navigation command metadata.
   function Is_Navigation_Command
     (Id : Command_Id) return Boolean;

   --  Return True for search/find/project-search commands.
   --  @param Id Command identifier.
   --  @return True for static search command metadata.
   function Is_Search_Command
     (Id : Command_Id) return Boolean;

   --  Return True for panel focus or panel-list navigation commands.
   --  @param Id Command identifier.
   --  @return True for static panel-focus command metadata.
   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean;

   --  Return True for direct text-editing commands.
   --  @param Id Command identifier.
   --  @return True for static text-editing command metadata.
   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean;

   --  Return True when Id should be offered by the command palette. Hidden
   --  commands may still be executable and key-bindable.
   --  @param Id Command identifier.
   --  @return True if the descriptor is palette-visible.
   function Visible_In_Command_Palette
     (Id : Command_Id) return Boolean;

   --  Return the number of palette-visible command ids in registry order.
   --  @return Count of descriptors whose visibility is Palette_Command.
   function Palette_Command_Count return Natural;

   --  Return the palette-visible command id at a one-based palette index.
   --  @param Index One-based palette-visible command index.
   --  @return Palette-visible command identifier at Index.
   function Palette_Command_At
     (Index : Positive) return Command_Id;

   --  Return the number of stable command ids in registry order.
   --  @return Count of Command_Id values including No_Command.
   function Command_Count return Natural;

   --  Return the command id at a one-based registry index.
   --  @param Index One-based command registry index.
   --  @return Command identifier at Index.
   function Command_At
     (Index : Positive) return Command_Id;

   function Palette_Commands return Command_Descriptor_Vectors.Vector;

   type Command_Kind is
     (Insert_Text_Input,
      Delete_Char,
      Forward_Delete_Char,
      Delete_Current_Line,
      Duplicate_Current_Line,
      Move_Current_Line_Up,
      Move_Current_Line_Down,
      Indent_Current_Line,
      Outdent_Current_Line,
      Comment_Current_Line,
      Uncomment_Current_Line,
      Toggle_Current_Line_Comment,
      Join_Current_Line_With_Next,
      Split_Current_Line_At_Caret,
      Trim_Trailing_Whitespace,
      Delete_Previous_Character,
      Delete_Next_Character,
      Delete_Previous_Word,
      Delete_Next_Word,
      Delete_Selection_Range,
      Move_Left,
      Move_Right,
      Move_Up,
      Move_Down,
      Move_Home,
      Move_End,
      Move_Line_Start,
      Move_Line_End,
      Move_Document_Start,
      Move_Document_End,
      Move_Page_Up,
      Move_Page_Down,
      Move_To_Point,
      Pointer_Hover,
      Drag_To_Point,
      Start_Rectangle_Selection,
      Start_Rectangle_At_Caret,
      Drag_Rectangle_To_Point,
      Clear_Rectangle_Selection,
      Add_Caret_At_Point,
      Clear_Extra_Carets,
      Select_Word,
      Select_Line,
      Extend_Selection_Line_Up,
      Extend_Selection_Line_Down,
      Select_Word_At_Point,
      Select_Line_At_Point,
      Move_Word_Left,
      Move_Word_Right,
      Select_Word_Left,
      Select_Word_Right,
      Select_Line_Start,
      Select_Line_End,
      Select_Document_Start,
      Select_Document_End,
      Select_Page_Up,
      Select_Page_Down,
      Undo,
      Redo,
      Break_Group,
      Copy_Selection,
      Cut_Selection,
      Paste_Text,
      Paste_Clipboard,
      Clear_Clipboard,
      Open_File,
      Open_Project,
      Switch_Project,
      Show_Recent_Projects,
      Open_Selected_Recent_Project,
      Clear_Recent_Projects,
      Remove_Selected_Recent_Project,
      Remove_Missing_Recent_Projects,
      Select_Next_Recent_Project,
      Select_Previous_Recent_Project,
      Close_Project,
      Clear_Project,
      Refresh_File_Tree,
      Refresh_Project_Files,
      Project_Files_Summary,
      Reveal_Active_File_In_Tree,
      New_Buffer,
      Close_Buffer,
      Reopen_Closed_Buffer,
      Close_Other_Buffers,
      Close_All_Clean_Buffers,
      Pin_Buffer,
      Unpin_Buffer,
      Toggle_Buffer_Pin,
      Set_Buffer_Label,
      Clear_Buffer_Label,
      Edit_Buffer_Label,
      Show_Buffer_Label,
      Set_Buffer_Note,
      Clear_Buffer_Note,
      Edit_Buffer_Note,
      Show_Buffer_Note,
      Assign_Buffer_Group,
      Clear_Buffer_Group,
      Switch_Buffer_Group,
      Next_Buffer_Group,
      Previous_Buffer_Group,
      Show_All_Buffer_Groups,
      Cancel_Pending_Transition,
      Retry_Pending_Transition,
      Discard_Pending_Transition,
      Next_Buffer,
      Previous_Buffer,
      Switch_Buffer,
      Toggle_Theme,
      Toggle_Minimap,
      Toggle_Scrollbars,
      Toggle_Line_Number_Mode,
      Toggle_Cursor_Blink,
      Set_Theme_Light,
      Set_Theme_Dark,
      Toggle_Problems_Panel,
      Next_Diagnostic,
      Previous_Diagnostic,
      Toggle_Bookmark,
      Next_Bookmark,
      Previous_Bookmark,
      Clear_Bookmarks,
      Clear_All_Bookmarks,
      Bookmark_Toggle_Current_Location,
      Bookmark_Clear_All,
      Bookmark_Next,
      Bookmark_Previous,
      Bookmark_Goto_Next,
      Bookmark_Goto_Previous,
      Bookmark_Open_Selected,
      Bookmark_Reveal_Current,
      Bookmark_Remove_Selected,
      Bookmark_Show,
      Bookmark_Hide,
      Bookmark_Toggle,
      Save_File,
      Save_File_As,
      Reload_Active_Buffer,
      Revert_Active_Buffer,
      File_Conflict_Keep_Buffer,
      File_Conflict_Reload_From_Disk,
      File_Conflict_Overwrite_Disk,
      File_Conflict_Cancel,
      Rename_Buffer_File,
      Delete_Buffer_File,
      Copy_Buffer_File,
      Move_Buffer_File,
      Save_All,
      Open_Command_Palette,
      Palette_Show_Command_Help,
      Palette_Accept,
      Palette_Cancel,
      Open_Goto_Line,
      Toggle_Goto_Line,
      Prefill_Goto_Line_Current,
      Close_Goto_Line,
      Accept_Goto_Line,
      Goto_Line_Query_Set,
      Goto_Line_Query_Clear,
      Active_Find_Show,
      Active_Find_Hide,
      Active_Find_Toggle,
      Active_Find_Query_Set,
      Active_Find_Query_Clear,
      Active_Find_Case_Toggle,
      Active_Find_Case_Clear,
      Active_Find_Whole_Word_Toggle,
      Active_Find_Whole_Word_Clear,
      Active_Find_From_Selection,
      Active_Find_From_Active_Word,
      Active_Find_Next,
      Active_Find_Previous,
      Active_Find_First,
      Active_Find_Last,
      Active_Find_Reveal_Current,
      Active_Replace_Show,
      Active_Replace_Hide,
      Active_Replace_Toggle,
      Active_Replace_Text_Set,
      Active_Replace_Text_Clear,
      Active_Replace_Current,
      Active_Replace_All,
      Navigation_Back,
      Navigation_Forward,
      Navigation_History_Clear,
      Previous_Recent_Buffer,
      Next_Recent_Buffer,
      Goto_Line_Insert_Text,
      Goto_Line_Backspace,
      Goto_Line_Delete_Forward,
      Goto_Line_Move_Cursor_Left,
      Goto_Line_Move_Cursor_Right,
      Active_Find_Input_Insert_Text,
      Active_Find_Input_Backspace,
      Active_Find_Input_Delete_Forward,
      Active_Find_Input_Move_Cursor_Left,
      Active_Find_Input_Move_Cursor_Right,
      Open_Quick_Open,
      Close_Quick_Open,
      Toggle_Quick_Open,
      Accept_Quick_Open,
      Quick_Open_Next_Result,
      Quick_Open_Previous_Result,
      Quick_Open_Query_Set,
      Quick_Open_Query_Clear,
      Quick_Open_Kind_Next,
      Quick_Open_Kind_Previous,
      Quick_Open_Kind_Clear,
      Quick_Open_Scope_Set,
      Quick_Open_Scope_Clear,
      Quick_Open_Scope_From_Selected,
      Quick_Open_Scope_Parent,
      Quick_Open_Reveal_Active,
      Quick_Open_Scope_Active_Directory,
      Quick_Open_Create_From_Query,
      Quick_Open_Create_With_Parents_From_Query,
      Quick_Open_Priority_Toggle,
      Quick_Open_Priority_Clear,
      Quick_Open_Insert_Text,
      Quick_Open_Backspace,
      Quick_Open_Delete_Forward,
      Quick_Open_Move_Cursor_Left,
      Quick_Open_Move_Cursor_Right,
      Open_Buffer_Switcher,
      Close_Buffer_Switcher,
      Accept_Buffer_Switcher,
      Buffer_Switcher_Next_Result,
      Buffer_Switcher_Previous_Result,
      Buffer_Switcher_Insert_Text,
      Buffer_Switcher_Backspace,
      Buffer_Switcher_Delete_Forward,
      Buffer_Switcher_Move_Cursor_Left,
      Buffer_Switcher_Move_Cursor_Right,
      Buffer_Switcher_Filter_Clear,
      Buffer_Switcher_Filter_Pinned,
      Buffer_Switcher_Filter_Group,
      Buffer_Switcher_Filter_Label,
      Buffer_Switcher_Filter_Noted,
      Buffer_Switcher_Sort_Default,
      Buffer_Switcher_Sort_Recent,
      Buffer_Switcher_Sort_Name,
      Buffer_Switcher_Sort_Pinned,
      Buffer_Switcher_Sort_Group,
      Buffer_Switcher_Sort_Label,
      Buffer_Switcher_Sort_Next,
      Buffer_Switcher_Sort_Previous,
      Buffer_Switcher_Selected_Close,
      Buffer_Switcher_Selected_Pin,
      Buffer_Switcher_Selected_Unpin,
      Buffer_Switcher_Selected_Toggle_Pin,
      Buffer_Switcher_Selected_Group_Assign,
      Buffer_Switcher_Selected_Group_Clear,
      Buffer_Switcher_Selected_Label_Set,
      Buffer_Switcher_Selected_Label_Clear,
      Buffer_Switcher_Selected_Note_Set,
      Buffer_Switcher_Selected_Note_Clear,
      Buffer_Switcher_Preview_Toggle,
      Buffer_Switcher_Preview_Show,
      Buffer_Switcher_Preview_Hide,
      Buffer_Switcher_Preview_Next_Line,
      Buffer_Switcher_Preview_Previous_Line,
      Buffer_Switcher_Preview_Center_Cursor,
      Buffer_Switcher_Mark_Toggle,
      Buffer_Switcher_Mark_Set,
      Buffer_Switcher_Mark_Clear,
      Buffer_Switcher_Mark_Clear_All,
      Buffer_Switcher_Mark_Invert_Visible,
      Buffer_Switcher_Mark_Visible,
      Buffer_Switcher_Mark_Clear_Visible,
      Buffer_Switcher_Mark_Pinned,
      Buffer_Switcher_Mark_Group,
      Buffer_Switcher_Mark_Label,
      Buffer_Switcher_Mark_Noted,
      Buffer_Switcher_Mark_Close_Marked,
      Buffer_Switcher_Mark_Confirm,
      Buffer_Switcher_Mark_Cancel,
      Buffer_Switcher_Mark_Pin_Marked,
      Buffer_Switcher_Mark_Unpin_Marked,
      Buffer_Switcher_Mark_Clear_Metadata,
      Buffer_Switcher_Mark_Group_Assign,
      Buffer_Switcher_Mark_Group_Clear,
      Buffer_Switcher_Mark_Label_Set,
      Buffer_Switcher_Mark_Label_Clear,
      Buffer_Switcher_Mark_Note_Set,
      Buffer_Switcher_Mark_Note_Clear,
      Buffer_Switcher_Mark_Review_Toggle,
      Buffer_Switcher_Mark_Review_Show,
      Buffer_Switcher_Mark_Review_Hide,
      Buffer_Switcher_Pending_Mark_Review_Toggle,
      Buffer_Switcher_Pending_Mark_Review_Show,
      Buffer_Switcher_Pending_Mark_Review_Hide,
      Buffer_Switcher_Pending_Mark_Next,
      Buffer_Switcher_Pending_Mark_Previous,
      Buffer_Switcher_Pending_Mark_Summary,
      Buffer_Switcher_Pending_Mark_Remove_Selected,
      Buffer_Switcher_Pending_Mark_Restore_Last_Pruned,
      Buffer_Switcher_Pending_Mark_Pruned_Summary,
      Buffer_Switcher_Pending_Mark_Pruned_Next,
      Buffer_Switcher_Pending_Mark_Pruned_Previous,
      Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle,
      Buffer_Switcher_Pending_Mark_Pruned_Review_Show,
      Buffer_Switcher_Pending_Mark_Pruned_Review_Hide,
      Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned,
      Buffer_Switcher_Pending_Mark_Dirty_Summary,
      Buffer_Switcher_Pending_Mark_Dirty_Next,
      Buffer_Switcher_Pending_Mark_Dirty_Previous,
      Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Next,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale,
      Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary,
      Buffer_Switcher_Mark_Next,
      Buffer_Switcher_Mark_Previous,
      Buffer_Switcher_Mark_Summary,
      Apply_Replace_Batch,
      Run_Project_Search,
      Rerun_Project_Search,
      Open_Project_Search_Bar,
      Toggle_Project_Search_Bar,
      Close_Project_Search_Bar,
      Run_Project_Search_From_Bar,
      Project_Search_Bar_Insert_Text,
      Project_Search_Bar_Backspace,
      Project_Search_Bar_Delete_Forward,
      Project_Search_Bar_Move_Cursor_Left,
      Project_Search_Bar_Move_Cursor_Right,
      Project_Search_From_Selection,
      Project_Search_From_Active_Word,
      Project_Search_Active_Directory,
      Clear_Project_Search,
      Open_Selected_Project_Search_Result,
      Move_Project_Search_Selection_Up,
      Move_Project_Search_Selection_Down,
      Next_Project_Search_Result,
      Previous_Project_Search_Result,
      First_Project_Search_Result,
      Last_Project_Search_Result,
      Reveal_Active_Project_Search_Result,
      Project_Search_Scope_Selected_Directory,
      Project_Search_Kind_Next,
      Project_Search_Kind_Previous,
      Project_Search_Kind_Clear,
      Project_Search_Scope_Set,
      Project_Search_Scope_Clear,
      Project_Search_Case_Toggle,
      Project_Search_Case_Clear,
      Project_Search_Whole_Word_Toggle,
      Project_Search_Whole_Word_Clear,
      Project_Search_Regex_Toggle,
      Project_Search_Regex_Clear,
      Project_Search_Include_Filter_Set,
      Project_Search_Exclude_Filter_Set,
      Project_Search_Include_Filter_Clear,
      Project_Search_Exclude_Filter_Clear,
      Project_Search_Replace_Preview,
      Project_Search_Replace_Toggle_Selected,
      Project_Search_Replace_Include_Selected,
      Project_Search_Replace_Exclude_Selected,
      Project_Search_Replace_Include_File,
      Project_Search_Replace_Exclude_File,
      Project_Search_Replace_Include_All,
      Project_Search_Replace_Exclude_All,
      Project_Search_Replace_Selected,
      Project_Search_Replace_All_Included,
      Project_Search_Replace_Clear_Preview,
      Show_Search_Results_Panel,
      Focus_Editor_Text,
      Focus_Search_Results,
      Focus_Problems,
      Toggle_Bottom_Panel_Focus,
      Search_Results_Move_Up,
      Search_Results_Move_Down,
      Search_Results_Page_Up,
      Search_Results_Page_Down,
      Search_Results_Open_Selected,
      Search_Results_Close_Or_Hide,
      Problems_Move_Up,
      Problems_Move_Down,
      Problems_Page_Up,
      Problems_Page_Down,
      Problems_Open_Selected,
      Problems_Filter_All,
      Problems_Filter_Errors,
      Problems_Filter_Warnings,
      Problems_Filter_Info,
      Problems_Filter_Hints,
      Problems_Sort_By_Location,
      Problems_Sort_By_Severity,
      Problems_Sort_By_Source,
      Problems_Group_By_Severity,
      Problems_Group_By_Source,
      Problems_Focus_Editor,
      Focus_File_Tree,
      File_Tree_Move_Up,
      File_Tree_Move_Down,
      File_Tree_Page_Up,
      File_Tree_Page_Down,
      File_Tree_Open_Selected,
      File_Tree_Create_File,
      File_Tree_Create_Directory,
      File_Tree_Rename_Selected,
      File_Tree_Delete_Selected,
      File_Tree_Expand_Selected,
      File_Tree_Collapse_Selected,
      File_Tree_Toggle_Selected,
      File_Tree_Collapse_All,
      File_Tree_Expand_To_Active_File,
      Save_Settings,
      Reload_Settings,
      Reset_Settings_To_Defaults,
      Save_Keybindings,
      Reload_Keybindings,
      Validate_Keybindings,
      Keybindings_Show,
      Keybindings_Focus,
      Keybindings_Assign_Selected,
      Keybindings_Remove_Selected,
      Keybindings_Reset_To_Defaults,
      Keybindings_Filter_Conflicts,
      Keybindings_Filter_Unbound,
      Keybindings_Clear_Filter,
      Keybindings_Cancel_Capture,
      Startup_Show_Summary,
      Configuration_Recover_Show,
      Configuration_Audit,
      Configuration_Reset_Settings,
      Configuration_Reset_Keybindings,
      Configuration_Reset_Workspace,
      Configuration_Reset_Recent_Projects,
      Configuration_Reset_All,
      Configuration_Reset_All_Confirm,
      Configuration_Reset_All_Cancel,
      Configuration_Save_Clean_Settings,
      Configuration_Save_Clean_Keybindings,
      Configuration_Save_Clean_Workspace,
      Configuration_Save_Clean_Recent_Projects,
      Save_Workspace_State,
      Restore_Workspace_State,
      Clear_Workspace_State,
      Toggle_Feature_Panel,
      Show_Feature_Panel,
      Hide_Feature_Panel,
      Focus_Feature_Panel,
      Clear_Feature_Panel,
      Feature_Panel_Select_Next,
      Feature_Panel_Select_Previous,
      Feature_Panel_Open_Selected,
      Run_Project,
      Run_Tests,
      Terminal_Toggle,
      Terminal_Show,
      Terminal_Hide,
      Terminal_Focus,
      Terminal_Clear,
      Terminal_Clear_Output,
      Terminal_Select_Next_Task,
      Terminal_Select_Previous_Task,
      Terminal_Run_Selected_Task,
      Terminal_Rerun_Last_Task,
      Terminal_Cancel_Task,
      Build_UI_Toggle,
      Build_UI_Show,
      Build_UI_Hide,
      Build_UI_Focus,
      Build_Result_Focus,
      Build_Output_Details_Focus,
      Build_Output_Details_Select_Stdout,
      Build_Output_Details_Select_Stderr,
      Build_Output_Details_Select_Merged,
      Build_Refresh_Candidates,
      Build_Select_First_Candidate,
      Build_Select_Next_Candidate,
      Build_Select_Previous_Candidate,
      Build_Clear_Selected_Candidate,
      Build_Set_Mode_Default,
      Build_Set_Mode_Debug,
      Build_Set_Mode_Release,
      Build_Set_Mode_Validation,
      Build_Toggle_Diagnostics_Ingestion,
      Build_Cycle_Output_Limit,
      Build_Toggle_Option_Verbose,
      Build_Toggle_Option_Keep_Going,
      Build_Acknowledge_Consent,
      Build_Clear_Consent,
      Build_Cancel,
      Refresh_Outline,
      Refresh_Outline_Project_Index,
      Goto_Declaration,
      Goto_Body,
      Goto_Spec,
      Find_References,
      Workspace_Symbols,
      Show_Hover,
      Show_Completions,
      Semantic_Completion_Select_Next,
      Semantic_Completion_Select_Previous,
      Semantic_Completion_Accept,
      Semantic_Popup_Dismiss,
      Rename_Symbol_Preview,
      Rename_Symbol_Apply,
      Semantic_Refresh_Buffer,
      Semantic_Refresh_Project_Index,
      Language_Index_Clear,
      Language_Index_Status,
      Clear_Outline,
      Show_Outline,
      Focus_Outline,
      Open_Selected_Outline_Item,
      Select_Current_Outline_Symbol,
      Reveal_Current_Outline_Symbol,
      Next_Outline_Symbol,
      Previous_Outline_Symbol,
      Select_Next_Outline_Item,
      Select_Previous_Outline_Item,
      Focus_Outline_Filter,
      Filter_Outline,
      Clear_Outline_Filter,
      Toggle_Outline_Filter,
      Outline_Filter_History_Previous,
      Outline_Filter_History_Next,
      Clear_Outline_Filter_History,
      Show_Messages,
      Clear_Messages,
      Clear_Selected_Message,
      Copy_Selected_Message_Text,
      Clear_Info_Messages,
      Clear_Warning_Messages,
      Clear_Error_Messages,
      Toggle_Message_Info,
      Toggle_Message_Warnings,
      Toggle_Message_Errors,
      Show_All_Messages,
      Clear_Message_Filter,
      Search_Results_Search_Active_Buffer,
      Search_Results_Focus_Query,
      Search_Results_Repeat_Active_Buffer,
      Search_Results_Query_History_Previous,
      Search_Results_Query_History_Next,
      Search_Results_Toggle_Case_Sensitive,
      Show_Search_Results_Feature,
      Clear_Search_Results_Feature,
      Diagnostics_Show,
      Diagnostics_Clear,
      Diagnostics_Toggle_Info,
      Diagnostics_Toggle_Warnings,
      Diagnostics_Toggle_Errors,
      Diagnostics_Show_All,
      Diagnostics_Clear_Filter,
      Diagnostics_Filter_Errors,
      Diagnostics_Filter_Warnings,
      Diagnostics_Filter_Info_Notes,
      Diagnostics_Filter_Source,
      Diagnostics_Filter_Build,
      Diagnostics_Clear_Build,
      Diagnostics_Open_Selected,
      Diagnostic_Open_Source,
      Diagnostic_Suppress_Selected,
      Diagnostic_Show_Suppressed,
      Diagnostic_Restore_Last_Suppressed,
      Diagnostic_Restore_Selected_Suppressed,
      Diagnostic_Clear_Suppressed,
      Diagnostic_Apply_Quick_Fix,
      Diagnostics_Execute_Selected_Action,
      Diagnostics_Select_Next,
      Diagnostics_Select_Previous,
      Diagnostics_Clear_Selected,
      Diagnostics_Copy_Selected_Text,
      Diagnostics_Clear_Info,
      Diagnostics_Clear_Warnings,
      Diagnostics_Clear_Errors,
      Diagnostics_Toggle_Editor_Source,
      Diagnostics_Toggle_File_Source,
      Diagnostics_Toggle_Project_Source,
      Diagnostics_Toggle_External_Source,
      Diagnostics_Toggle_Unknown_Source,
      Toggle_Format_On_Save);

   package Position_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Cursor_Index);

   package Delete_Count_Vectors is new
     Ada.Containers.Vectors (Index_Type => Natural, Element_Type => Natural);

   package Text_Vectors is new
     Ada.Containers.Vectors
       (Index_Type   => Natural,
        Element_Type => Unbounded_String,
        "="          => "=");

   type Command is record
      Kind : Command_Kind := Insert_Text_Input;

      Pos          : Cursor_Index := 0;
      Has_Position : Boolean := False;
      Ch           : Character := ASCII.NUL;
      Code    : Editor.Unicode.Code_Point := Wide_Wide_Character'Val (0);
      Shift   : Boolean := False;
      Ctrl    : Boolean := False;
      Alt     : Boolean := False;
      Click_X : Natural := 0;
      Click_Y : Natural := 0;

      Text          : Unbounded_String := Null_Unbounded_String;
      Path          : Unbounded_String := Null_Unbounded_String;
      Query         : Unbounded_String := Null_Unbounded_String;
      Buffer_Id     : Natural := 0;
      Positions     : Position_Vectors.Vector;
      Delete_Counts : Delete_Count_Vectors.Vector;
      Insert_Texts  : Text_Vectors.Vector;
   end record;


   function Command_For_Id
     (Id    : Command_Id;
      Shift : Boolean := False) return Command;

   function "=" (L, R : Command) return Boolean;

end Editor.Commands;
