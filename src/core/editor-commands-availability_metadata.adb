with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Workflow_Messages;

package body Editor.Commands.Availability_Metadata is

   function Available return Command_Availability is
   begin
      return (Status => Command_Available, Reason => Null_Unbounded_String);
   end Available;

   function Unavailable
     (Reason : String) return Command_Availability
   is
   begin
      return
        (Status => Command_Unavailable,
         Reason => To_Unbounded_String
           (Editor.Commands.Workflow_Messages.Normalize_Workflow_Message
              (Reason)));
   end Unavailable;

   function Is_Available
     (Availability : Command_Availability) return Boolean
   is
   begin
      return Availability.Status = Command_Available;
   end Is_Available;

   function Unavailable_Reason
     (Availability : Command_Availability) return String
   is
   begin
      return Editor.Commands.Workflow_Messages.Normalize_Workflow_Message
        (To_String (Availability.Reason));
   end Unavailable_Reason;

   function Is_Concrete_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id /= No_Command;
   end Is_Concrete_Command;

   function Requires_Context
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when No_Command
            | Command_Close_Goto_Line
            | Command_Accept_Goto_Line
            | Command_Goto_Line_Query_Set
            | Command_Goto_Line_Query_Clear
            | Command_Find_Hide
            | Command_Find_Query_Set
            | Command_Find_Query_Clear
            | Command_Replace_Hide
            | Command_Replace_Text_Set
            | Command_Replace_Text_Clear
            | Command_Replace_Current
            | Command_Replace_All
            | Command_Close_Buffer_Switcher
            | Command_Accept_Buffer_Switcher
            | Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result
            | Command_Buffer_Switcher_Filter_Group
            | Command_Buffer_Switcher_Filter_Label
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Mark_Group
            | Command_Buffer_Switcher_Mark_Label
            | Command_Buffer_Switcher_Mark_Group_Assign
            | Command_Buffer_Switcher_Mark_Label_Set
            | Command_Buffer_Switcher_Mark_Note_Set
            | Command_Buffer_Switcher_Mark_Review_Toggle
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous
            | Command_Buffer_Switcher_Pending_Mark_Summary
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
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
            | Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous
            | Command_Buffer_Switcher_Mark_Summary
            | Command_Build_Run_User_Opt_In_Test_Seam
            | Command_Build_Cancel
            | Command_Open_File
            | Command_Open_Project
            | Command_Switch_Project
            | Command_Save_File_As
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_Switch_Buffer
            | Command_Run_Project_Search
            | Command_Toggle_Project_Search_Bar
            | Command_Open_Selected_Project_Search_Result
            | Command_Search_Results_Open_Selected
            | Command_Problems_Open_Selected
            | Command_File_Tree_Open_Selected
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_File_Tree_Expand_Selected
            | Command_File_Tree_Collapse_Selected
            | Command_File_Tree_Toggle_Selected
            | Command_File_Tree_Collapse_All
            | Command_File_Tree_Expand_To_Active_File
            | Command_Toggle_Feature_Panel
            | Command_Show_Feature_Panel
            | Command_Hide_Feature_Panel
            | Command_Focus_Feature_Panel
            | Command_Clear_Feature_Panel
            | Command_Feature_Panel_Select_Next
            | Command_Feature_Panel_Select_Previous
            | Command_Feature_Panel_Open_Selected
            | Command_Refresh_Outline
            | Command_Refresh_Outline_Project_Index
            | Command_Goto_Declaration
            | Command_Goto_Body
            | Command_Goto_Spec
            | Command_Find_References
            | Command_Workspace_Symbols
            | Command_Show_Hover
            | Command_Show_Completions
            | Command_Rename_Symbol_Preview
            | Command_Rename_Symbol_Apply
            | Command_Semantic_Refresh_Buffer
            | Command_Semantic_Refresh_Project_Index
            | Command_Language_Index_Clear
            | Command_Language_Index_Status
            | Command_Clear_Outline
            | Command_Show_Outline
            | Command_Focus_Outline
            | Command_Open_Selected_Outline_Item
            | Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol
            | Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol
            | Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item
            | Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Clear_Outline_Filter
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next
            | Command_Clear_Outline_Filter_History
            | Command_Show_Messages
            | Command_Clear_Messages
            | Command_Search_Results_Search_Active_Buffer
            | Command_Search_Results_Focus_Query
            | Command_Search_Results_Repeat_Active_Buffer
            | Command_Search_Results_Query_History_Previous
            | Command_Search_Results_Query_History_Next
            | Command_Search_Results_Toggle_Case_Sensitive
            | Command_Show_Search_Results_Feature
            | Command_Clear_Search_Results_Feature
            | Command_Diagnostics_Show
            | Command_Diagnostics_Clear
            | Command_Diagnostics_Toggle_Info
            | Command_Diagnostics_Toggle_Warnings
            | Command_Diagnostics_Toggle_Errors
            | Command_Diagnostics_Show_All
            | Command_Diagnostics_Clear_Filter
            | Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes
            | Command_Diagnostics_Filter_Source
            | Command_Diagnostics_Filter_Build
            | Command_Diagnostics_Clear_Build
            | Command_Diagnostics_Open_Selected
            | Command_Diagnostic_Open_Source
            | Command_Diagnostic_Suppress_Selected
            | Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed
            | Command_Diagnostic_Apply_Quick_Fix
            | Command_Diagnostics_Execute_Selected_Action
            | Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous
            | Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text
            | Command_Diagnostics_Clear_Info
            | Command_Diagnostics_Clear_Warnings
            | Command_Diagnostics_Clear_Errors
            | Command_Diagnostics_Toggle_Editor_Source
            | Command_Diagnostics_Toggle_File_Source
            | Command_Diagnostics_Toggle_Project_Source
            | Command_Diagnostics_Toggle_External_Source
            | Command_Diagnostics_Toggle_Unknown_Source
            | Command_Clear_Selected_Message
            | Command_Copy_Selected_Message_Text
            | Command_Clear_Info_Messages
            | Command_Clear_Warning_Messages
            | Command_Clear_Error_Messages
            | Command_Toggle_Message_Info
            | Command_Toggle_Message_Warnings
            | Command_Toggle_Message_Errors
            | Command_Show_All_Messages
            | Command_Clear_Message_Filter =>
            return True;
         when others =>
            return False;
      end case;
   end Requires_Context;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Concrete_Command (Id);
   end Has_Availability_Handler;

end Editor.Commands.Availability_Metadata;
