with Editor.Commands;   use Editor.Commands;
with Editor.Guided_Prompts;
with Editor.Project;
with Editor.State;

with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Buffer_Metadata_Commands;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Executor.Buffer_Switcher_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Preview_Commands;
with Editor.Executor.Buffer_Switcher_Selected_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Build_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Configuration_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Editing_Commands;
with Editor.Executor.Editor_Preferences_Commands;
with Editor.Executor.Feature_Panel_Commands;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Selection_Commands;
with Editor.Executor.Semantic_Commands;
with Editor.Executor.Terminal_Commands;
with Editor.Executor.Workspace_Commands;

package body Editor.Executor.Availability is

   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;

      function Has_Project return Boolean is
      begin
         return Editor.Project.Has_Project (S.Project);
      end Has_Project;

      Lifecycle_Handled : Boolean := False;
      Lifecycle_Result  : Editor.Commands.Command_Availability :=
        Editor.Commands.Available;
   begin
      --  while a destructive dirty lifecycle operation is waiting
      --  for explicit retry/cancel, other guarded lifecycle commands are
      --  unavailable instead of replacing the pending payload through
      --  availability-visible command paths.  Save All, Close Clean, Retry,
      --  and Cancel remain available so the user can resolve the state.

      --  completeness: an active guided prompt owns the current
      --  multi-step workflow.  Availability remains observational, but command
      --  surfaces must not advertise a second lifecycle/destructive/configuration
      --  prompt while the first prompt or confirmation is pending.  Cancel stays
      --  available so the user can leave the modal prompt atomically.
      if Editor.Guided_Prompts.Is_Active (S.Guided_Prompt) then
         --  completeness pass 5: prompt focus is modal at the
         --  command-surface level, not only inside Input_Bridge dispatch.
         --  Confirmation/entry is handled by prompt-local input paths; normal
         --  command availability must not advertise unrelated mutations while
         --  transient prompt input or confirmation payload is active.
         case Id is
            when Command_Cancel =>
               return Editor.Commands.Available;
            when Command_Restore_Workspace_State =>
               return Editor.Commands.Available;
            when No_Command =>
               return Editor.Commands.Unavailable ("No command");
            when others =>
               if Editor.Guided_Prompts.Is_Confirmation (S.Guided_Prompt) then
                  return Editor.Commands.Unavailable
                    ("Command unavailable while confirmation is pending");
               else
                  return Editor.Commands.Unavailable ("Another prompt is active");
               end if;
         end case;
      end if;

      Editor.Executor.File_Lifecycle_Commands.Lifecycle_Command_Availability
        (S, Id, Lifecycle_Handled, Lifecycle_Result);
      if Lifecycle_Handled then
         return Lifecycle_Result;
      end if;

      case Id is
         when No_Command =>
            return Editor.Commands.Unavailable ("No command selected");

         when Command_Save_File .. Command_Move_Buffer_File
            | Command_Confirm_Close_Save .. Command_Cancel_Close
            | Command_Cancel_Pending_Transition
              .. Command_Discard_Pending_Transition =>
            raise Program_Error with
              "lifecycle availability should be handled before parent switch";

         when Command_Reveal_Active_File_In_Tree =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_Toggle_Bookmark
            =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Command_Move_Left
            | Command_Move_Right
            | Command_Move_Up
            | Command_Move_Down
            | Command_Move_Line_Start
            | Command_Move_Line_End
            | Command_Move_Document_Start
            | Command_Move_Document_End
            | Command_Move_Word_Left
            | Command_Move_Word_Right
            | Command_Page_Up
            | Command_Page_Down =>
            return Editor.Executor.Navigation_Commands
              .Navigation_Command_Availability (S, Id);

         when Command_Select_Left
            | Command_Select_Right
            | Command_Select_Up
            | Command_Select_Down
            | Command_Select_Word_Left
            | Command_Select_Word_Right
            | Command_Select_Word
            | Command_Select_Line
            | Command_Start_Rectangular_Selection
            | Command_Clear_Rectangular_Selection
            | Command_Extend_Selection_Line_Up
            | Command_Extend_Selection_Line_Down
            | Command_Select_Line_Start
            | Command_Select_Line_End
            | Command_Select_Document_Start
            | Command_Select_Document_End
            | Command_Select_Page_Up
            | Command_Select_Page_Down =>
            return Editor.Executor.Selection_Commands
              .Selection_Command_Availability (S, Id);

         when Command_Insert_Newline
            | Command_Goto_Start
            | Command_Goto_End =>
            return Editor.Executor.Navigation_Commands
              .Navigation_Command_Availability (S, Id);

         when Command_Copy =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Cut =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Paste =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Clipboard_Clear =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Select_All =>
            return Editor.Executor.Selection_Commands
              .Selection_Command_Availability (S, Id);

         when Command_Selection_Clear =>
            return Editor.Executor.Selection_Commands
              .Selection_Command_Availability (S, Id);

         when Command_Selection_Delete =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Trim_Trailing_Whitespace
            | Command_Format_Buffer =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Format_Selected_Text =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Line_Delete
            | Command_Line_Duplicate
            | Command_Line_Move_Up
            | Command_Line_Move_Down
            | Command_Indent_Increase
            | Command_Indent_Decrease
            | Command_Comment_Line
            | Command_Uncomment_Line
            | Command_Toggle_Line_Comment
            | Command_Line_Join_Next
            | Command_Line_Split_At_Caret
            | Command_Char_Delete_Previous
            | Command_Char_Delete_Next
            | Command_Word_Delete_Previous
            | Command_Word_Delete_Next =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Goto_Line
            | Command_Goto_Line_Toggle =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Goto_Line_Prefill_Current =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Navigation_Back =>
            return Editor.Executor.Navigation_Commands
              .Navigation_Command_Availability (S, Id);

         when Command_Navigation_Forward =>
            return Editor.Executor.Navigation_Commands
              .Navigation_Command_Availability (S, Id);

         when Command_Navigation_History_Clear =>
            return Editor.Executor.Navigation_Commands
              .Navigation_Command_Availability (S, Id);

         when Command_Reopen_Closed_Buffer =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);

         when Command_Close_Active_Buffer =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);

         when Command_Close_Other_Buffers =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);

         when Command_Project_Search_From_Selection
            =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_From_Active_Word
            | Command_Project_Search_Active_Directory =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Find_From_Selection =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_From_Active_Word =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Save_All =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);

         when Command_Close_All_Buffers =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);

         when Command_Close_All_Clean_Buffers =>
            return Editor.Executor.File_Lifecycle_Commands
              .Lifecycle_Command_Availability (S, Id);


         when Command_Pin_Buffer =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Unpin_Buffer =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Toggle_Buffer_Pin =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Set_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Clear_Buffer_Label =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Clear_Buffer_Note =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Assign_Buffer_Group =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Clear_Buffer_Group =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Switch_Buffer_Group
            | Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group =>
            if Id = Command_Switch_Buffer_Group then
               return Editor.Executor.Buffer_Metadata_Commands
                 .Buffer_Metadata_Command_Availability (S, Id);
            else
               return Editor.Executor.Buffer_Navigation_Commands
                 .Buffer_Navigation_Command_Availability (S, Id);
            end if;

         when Command_Show_All_Buffer_Groups =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Buffer_Metadata_Command_Availability (S, Id);

         when Command_Next_Buffer | Command_Previous_Buffer =>
            return Editor.Executor.Buffer_Navigation_Commands
              .Buffer_Navigation_Command_Availability (S, Id);

         when Command_Previous_Recent_Buffer =>
            return Editor.Executor.Buffer_Navigation_Commands
              .Buffer_Navigation_Command_Availability (S, Id);

         when Command_Next_Recent_Buffer =>
            return Editor.Executor.Buffer_Navigation_Commands
              .Buffer_Navigation_Command_Availability (S, Id);

         when Command_Open_Buffer_Switcher =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Filter_Clear =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Filter_Pinned =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Filter_Group =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Filter_Label =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Filter_Noted =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Sort_Default
            | Command_Buffer_Switcher_Sort_Recent
            | Command_Buffer_Switcher_Sort_Name
            | Command_Buffer_Switcher_Sort_Pinned
            | Command_Buffer_Switcher_Sort_Group
            | Command_Buffer_Switcher_Sort_Label
            | Command_Buffer_Switcher_Sort_Next
            | Command_Buffer_Switcher_Sort_Previous =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Open_Quick_Open =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Toggle_Quick_Open =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Refresh_File_Tree
            | Command_Refresh_Project_Files
            | Command_Focus_File_Tree =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_Quick_Open_Reveal_Active
            | Command_Quick_Open_Scope_Active_Directory =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Priority_Toggle
            | Command_Quick_Open_Priority_Clear =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Undo =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Redo =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Edit_History_Clear =>
            return Editor.Executor.Editing_Commands
              .Editing_Command_Availability (S, Id);

         when Command_Project_Files_Summary =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_Palette_Show_Command_Help =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Open_Project_Search_Bar
            | Command_Toggle_Project_Search_Bar =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_New_Buffer =>
            return Editor.Executor.File_Open_Commands
              .File_Open_Command_Availability (S, Id);

         when Command_Open_Command_Palette
            | Command_Cancel =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Toggle_Problems_Panel
            | Command_Focus_Editor_Text =>
            return Editor.Executor.Panel_Focus_Commands
              .Panel_Focus_Command_Availability (S, Id);

         when Command_Toggle_Theme
            | Command_Set_Theme_Light
            | Command_Set_Theme_Dark
            | Command_Toggle_Minimap
            | Command_Toggle_Scrollbars
            | Command_Toggle_Line_Numbers
            | Command_Toggle_Format_On_Save
            | Command_Toggle_Line_Number_Mode
            | Command_Set_Absolute_Line_Numbers
            | Command_Set_Relative_Line_Numbers
            | Command_Set_Hybrid_Line_Numbers
            | Command_Toggle_Current_Line_Highlight
            | Command_Toggle_Cursor_Blink
            | Command_Toggle_Syntax_Colouring
            | Command_Toggle_Diagnostics
            | Command_Toggle_Cursor_Style =>
            return Editor.Executor.Editor_Preferences_Commands
              .Editor_Preferences_Command_Availability (S, Id);

         when Command_Run_Project_Search_From_Bar =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Rerun_Project_Search | Command_Run_Project_Search =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Clear_Project_Search =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Open_Selected_Project_Search_Result =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Next_Project_Search_Result
            | Command_Previous_Project_Search_Result =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_First_Project_Search_Result
            | Command_Last_Project_Search_Result =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Reveal_Active_Project_Search_Result =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Scope_Selected_Directory =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Kind_Next
            | Command_Project_Search_Kind_Previous
            | Command_Project_Search_Kind_Clear
            | Command_Project_Search_Scope_Clear
            | Command_Project_Search_Case_Toggle
            | Command_Project_Search_Case_Clear
            | Command_Project_Search_Whole_Word_Toggle
            | Command_Project_Search_Whole_Word_Clear
            | Command_Project_Search_Regex_Toggle
            | Command_Project_Search_Regex_Clear
            | Command_Project_Search_Include_Filter_Clear
            | Command_Project_Search_Exclude_Filter_Clear =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Scope_Set =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Include_Filter_Set
            | Command_Project_Search_Exclude_Filter_Set =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Replace_Preview =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Replace_Clear_Preview =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Replace_Toggle_Selected
            | Command_Project_Search_Replace_Include_Selected
            | Command_Project_Search_Replace_Exclude_Selected
            | Command_Project_Search_Replace_Include_File
            | Command_Project_Search_Replace_Exclude_File
            | Command_Project_Search_Replace_Include_All
            | Command_Project_Search_Replace_Exclude_All =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Replace_Selected =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Project_Search_Replace_All_Included =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Search_Results_Open_Selected =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Focus_Search_Results
            | Command_Show_Search_Results_Panel =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Clear_Bookmarks =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Next_Bookmark
            | Command_Previous_Bookmark
            | Command_Clear_All_Bookmarks =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Toggle_Current_Location =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Clear_All =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Next
            | Command_Bookmark_Previous
            | Command_Bookmark_Goto_Next
            | Command_Bookmark_Goto_Previous =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Open_Selected
            | Command_Bookmark_Remove_Selected =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Reveal_Current =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Show | Command_Bookmark_Toggle =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Bookmark_Hide =>
            return Editor.Executor.Bookmark_Commands
              .Bookmark_Command_Availability (S, Id);

         when Command_Next_Diagnostic
            | Command_Previous_Diagnostic =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Focus_Problems =>
            return Editor.Executor.Panel_Focus_Commands
              .Panel_Focus_Command_Availability (S, Id);

         when Command_Problems_Move_Up
            | Command_Problems_Move_Down
            | Command_Problems_Page_Up
            | Command_Problems_Page_Down =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Problems_Open_Selected =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Problems_Filter_All
            | Command_Problems_Filter_Errors
            | Command_Problems_Filter_Warnings
            | Command_Problems_Filter_Info
            | Command_Problems_Filter_Hints
            | Command_Problems_Sort_By_Location
            | Command_Problems_Sort_By_Severity
            | Command_Problems_Sort_By_Source
            | Command_Problems_Group_By_Severity
            | Command_Problems_Group_By_Source =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Close_Quick_Open =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Accept_Quick_Open =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Next_Result
            | Command_Quick_Open_Previous_Result =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Query_Set =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Query_Clear =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Kind_Next
            | Command_Quick_Open_Kind_Previous =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Kind_Clear =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Scope_Set =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Scope_Clear =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Scope_From_Selected =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Quick_Open_Scope_Parent =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Close_Buffer_Switcher =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Accept_Buffer_Switcher =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result =>
            return Editor.Executor.Buffer_Switcher_Surface_Commands
              .Buffer_Switcher_Surface_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Close
            | Command_Buffer_Switcher_Selected_Toggle_Pin
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Note_Set =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Pin =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Unpin =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Group_Clear =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Label_Clear =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Selected_Note_Clear =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Buffer_Switcher_Selected_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Preview_Toggle
            | Command_Buffer_Switcher_Preview_Show =>
            return Editor.Executor.Buffer_Switcher_Preview_Commands
              .Buffer_Switcher_Preview_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Toggle
            | Command_Buffer_Switcher_Mark_Set
            | Command_Buffer_Switcher_Mark_Clear
            | Command_Buffer_Switcher_Mark_Clear_All
            | Command_Buffer_Switcher_Mark_Close_Marked
            | Command_Buffer_Switcher_Mark_Pin_Marked
            | Command_Buffer_Switcher_Mark_Unpin_Marked
            | Command_Buffer_Switcher_Mark_Clear_Metadata
            | Command_Buffer_Switcher_Mark_Group_Assign
            | Command_Buffer_Switcher_Mark_Group_Clear
            | Command_Buffer_Switcher_Mark_Label_Set
            | Command_Buffer_Switcher_Mark_Label_Clear
            | Command_Buffer_Switcher_Mark_Note_Set
            | Command_Buffer_Switcher_Mark_Note_Clear =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Confirm =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Cancel =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Review_Toggle
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Mark_Summary =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Summary
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            return Editor.Executor.Buffer_Switcher_Pending_Mark_Commands
              .Buffer_Switcher_Pending_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous =>
            return Editor.Executor.Buffer_Switcher_Pending_Mark_Commands
              .Buffer_Switcher_Pending_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Invert_Visible
            | Command_Buffer_Switcher_Mark_Visible =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Pinned =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Group =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Label =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Mark_Noted =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Buffer_Switcher_Mark_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Preview_Hide =>
            return Editor.Executor.Buffer_Switcher_Preview_Commands
              .Buffer_Switcher_Preview_Command_Availability (S, Id);

         when Command_Buffer_Switcher_Preview_Next_Line
            | Command_Buffer_Switcher_Preview_Previous_Line
            | Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Editor.Executor.Buffer_Switcher_Preview_Commands
              .Buffer_Switcher_Preview_Command_Availability (S, Id);

         when Command_Goto_Line_Query_Set =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Goto_Line_Query_Clear =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Close_Goto_Line =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Accept_Goto_Line =>
            return Editor.Executor.Command_Surface_Commands
              .Command_Surface_Command_Availability (S, Id);

         when Command_Find_Show
            | Command_Find_Toggle
            | Command_Replace_Show
            | Command_Replace_Toggle =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Hide =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Replace_Hide =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Replace_Text_Set =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Replace_Text_Clear =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Query_Set =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Case_Toggle =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Case_Clear =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Whole_Word_Toggle =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Whole_Word_Clear =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Find_Query_Clear =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Find_Reveal_Current
            | Command_Replace_Current
            | Command_Replace_All =>
            return Editor.Executor.Find_Replace_Commands
              .Find_Replace_Command_Availability (S, Id);

         when Command_Close_Project_Search_Bar =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Move_Project_Search_Selection_Up
            | Command_Move_Project_Search_Selection_Down =>
            return Editor.Executor.Search_Commands
              .Project_Search_Command_Availability (S, Id);

         when Command_Problems_Focus_Editor
            | Command_Toggle_Bottom_Panel_Focus =>
            return Editor.Executor.Panel_Focus_Commands
              .Panel_Focus_Command_Availability (S, Id);

         when Command_File_Tree_Move_Up
            | Command_File_Tree_Move_Down
            | Command_File_Tree_Page_Up
            | Command_File_Tree_Page_Down =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_File_Tree_Open_Selected =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_File_Tree_Expand_Selected
            | Command_File_Tree_Collapse_Selected
            | Command_File_Tree_Toggle_Selected =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_File_Tree_Collapse_All =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_File_Tree_Expand_To_Active_File =>
            return Editor.Executor.File_Tree_Commands
              .File_Tree_Command_Availability (S, Id);

         when Command_Show_Recent_Projects =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Clear_Recent_Projects =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Open_Selected_Recent_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Remove_Selected_Recent_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Remove_Missing_Recent_Projects =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Validate_Keybindings
            | Command_Keybindings_Show
            | Command_Keybindings_Focus
            | Command_Keybindings_Filter_Conflicts
            | Command_Keybindings_Filter_Unbound
            | Command_Keybindings_Clear_Filter =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Startup_Show_Summary =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Configuration_Recover_Show
            | Command_Configuration_Audit =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Keybindings_Cancel_Capture =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Save_Keybindings
            | Command_Reload_Keybindings =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Keybindings_Assign_Selected =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Keybindings_Remove_Selected =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Keybindings_Reset_To_Defaults =>
            return Editor.Executor.Configuration_Commands
              .Configuration_Command_Availability (S, Id);

         when Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State =>
            return Editor.Executor.Workspace_Commands
              .Workspace_Command_Availability (S, Id);

         when Command_Toggle_Feature_Panel
            | Command_Show_Feature_Panel
            | Command_Hide_Feature_Panel
            | Command_Focus_Feature_Panel
            | Command_Clear_Feature_Panel
            | Command_Feature_Panel_Open_Selected
            | Command_Feature_Panel_Select_Next
            | Command_Feature_Panel_Select_Previous =>
            return Editor.Executor.Feature_Panel_Commands
              .Feature_Panel_Command_Availability (S, Id);

         when Command_Refresh_Outline =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Refresh_Outline_Project_Index
            | Command_Semantic_Refresh_Buffer
            | Command_Semantic_Refresh_Project_Index
            | Command_Goto_Declaration
            | Command_Goto_Body
            | Command_Goto_Spec
            | Command_Find_References
            | Command_Workspace_Symbols
            | Command_Show_Hover
            | Command_Show_Completions
            | Command_Rename_Symbol_Preview
            | Command_Rename_Symbol_Apply
            | Command_Semantic_Completion_Select_Next
            | Command_Semantic_Completion_Select_Previous
            | Command_Semantic_Completion_Accept
            | Command_Semantic_Popup_Dismiss =>
            return Editor.Executor.Semantic_Commands.Semantic_Command_Availability
              (S, Id);

         when Command_Language_Index_Clear
            | Command_Language_Index_Status =>
            return Editor.Executor.Semantic_Commands.Semantic_Command_Availability
              (S, Id);

         when Command_Clear_Outline =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Show_Outline =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Focus_Outline =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Open_Selected_Outline_Item =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Clear_Outline_Filter
            | Command_Clear_Outline_Filter_History =>
            return Editor.Executor.Outline_Commands
              .Outline_Command_Availability (S, Id);

         when Command_Show_Messages
            =>
            return Editor.Executor.Message_Commands
              .Message_Command_Availability (S, Id);

         when Command_Diagnostics_Show
            | Command_Diagnostics_Toggle_Info
            | Command_Diagnostics_Toggle_Warnings
            | Command_Diagnostics_Toggle_Errors
            | Command_Diagnostics_Show_All
            | Command_Diagnostics_Toggle_Editor_Source
            | Command_Diagnostics_Toggle_File_Source
            | Command_Diagnostics_Toggle_Project_Source
            | Command_Diagnostics_Toggle_External_Source
            | Command_Diagnostics_Toggle_Unknown_Source =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Search_Results_Focus_Query
            | Command_Search_Results_Query_History_Previous
            | Command_Search_Results_Query_History_Next
            | Command_Search_Results_Toggle_Case_Sensitive
            | Command_Show_Search_Results_Feature =>
            return Editor.Executor.Search_Results_Commands
              .Search_Results_Command_Availability (S, Id);

         when Command_Diagnostics_Open_Selected
            | Command_Diagnostic_Open_Source
            | Command_Diagnostics_Execute_Selected_Action
            | Command_Diagnostic_Apply_Quick_Fix =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostic_Suppress_Selected =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Info =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Warnings =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Errors =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Filter =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Filter_Build =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Filter_Source =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Diagnostics_Clear_Build =>
            return Editor.Executor.Diagnostics_Commands
              .Diagnostics_Command_Availability (S, Id);

         when Command_Search_Results_Search_Active_Buffer =>
            return Editor.Executor.Search_Results_Commands
              .Search_Results_Command_Availability (S, Id);

         when Command_Search_Results_Repeat_Active_Buffer =>
            return Editor.Executor.Search_Results_Commands
              .Search_Results_Command_Availability (S, Id);

         when Command_Clear_Search_Results_Feature
            | Command_Diagnostics_Clear =>
            if Id = Command_Clear_Search_Results_Feature then
               return Editor.Executor.Search_Results_Commands
                 .Search_Results_Command_Availability (S, Id);
            else
               return Editor.Executor.Diagnostics_Commands
                 .Diagnostics_Command_Availability (S, Id);
            end if;

         when Command_Toggle_Message_Info
            | Command_Toggle_Message_Warnings
            | Command_Toggle_Message_Errors
            | Command_Show_All_Messages
            | Command_Clear_Message_Filter =>
            return Editor.Executor.Message_Commands
              .Message_Command_Availability (S, Id);

         when Command_Clear_Messages
            | Command_Clear_Info_Messages
            | Command_Clear_Warning_Messages
            | Command_Clear_Error_Messages =>
            return Editor.Executor.Message_Commands
              .Message_Command_Availability (S, Id);

         when Command_Clear_Selected_Message
            | Command_Copy_Selected_Message_Text =>
            return Editor.Executor.Message_Commands
              .Message_Command_Availability (S, Id);

         when Command_Dismiss_Latest_Message | Command_Dismiss_All_Messages =>
            return Editor.Executor.Message_Commands
              .Message_Command_Availability (S, Id);

         when Command_Run_Project
            | Command_Run_Tests =>
            return Editor.Executor.Terminal_Commands
              .Terminal_Command_Availability (S, Id);

         when Command_Terminal_Toggle
            | Command_Terminal_Show
            | Command_Terminal_Hide
            | Command_Terminal_Focus
            | Command_Terminal_Clear
            | Command_Terminal_Clear_Output =>
            return Editor.Executor.Terminal_Commands
              .Terminal_Command_Availability (S, Id);

         when Command_Terminal_Select_Next_Task
            | Command_Terminal_Select_Previous_Task
            | Command_Terminal_Run_Selected_Task =>
            return Editor.Executor.Terminal_Commands
              .Terminal_Command_Availability (S, Id);

         when Command_Terminal_Rerun_Last_Task =>
            return Editor.Executor.Terminal_Commands
              .Terminal_Command_Availability (S, Id);

         when Command_Terminal_Cancel_Task =>
            return Editor.Executor.Terminal_Commands
              .Terminal_Command_Availability (S, Id);

         when Command_Build_UI_Toggle
            | Command_Build_UI_Show
            | Command_Build_UI_Hide
            | Command_Build_UI_Focus
            | Command_Build_Set_Mode_Default
            | Command_Build_Set_Mode_Debug
            | Command_Build_Set_Mode_Release
            | Command_Build_Set_Mode_Validation
            | Command_Build_Toggle_Diagnostics_Ingestion
            | Command_Build_Cycle_Output_Limit
            | Command_Build_Clear_Consent =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Refresh_Candidates =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Result_Focus =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Output_Details_Focus
            | Command_Build_Output_Details_Select_Stdout
            | Command_Build_Output_Details_Select_Stderr
            | Command_Build_Output_Details_Select_Merged =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Select_First_Candidate
            | Command_Build_Select_Next_Candidate
            | Command_Build_Select_Previous_Candidate =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Clear_Selected_Candidate =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Toggle_Option_Verbose
            | Command_Build_Toggle_Option_Keep_Going =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Acknowledge_Consent =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Run =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Cancel =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Build_Run_User_Opt_In_Test_Seam =>
            return Editor.Executor.Build_Commands
              .Build_Command_Availability (S, Id);

         when Command_Close_Project
            | Command_Clear_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Switch_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Open_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Project_Lifecycle_Command_Availability (S, Id);

         when Command_Open_File | Command_Switch_Buffer =>
            return Editor.Executor.File_Open_Commands
              .File_Open_Command_Availability (S, Id);
      end case;
   end Command_Availability;


end Editor.Executor.Availability;
