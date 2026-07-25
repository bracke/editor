with Editor.Commands.Editing_Ids;
with Editor.Commands.Navigation_Ids;
with Editor.Commands.Semantic_Ids;

package body Editor.Commands.Classification is

   function Is_Navigation_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Navigation_Ids.Is_Navigation_Command;


   function Is_Search_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Find_Show
            | Command_Find_Hide
            | Command_Find_Toggle
            | Command_Find_Query_Set
            | Command_Find_Query_Clear
            | Command_Find_Case_Toggle
            | Command_Find_Case_Clear
            | Command_Find_Whole_Word_Toggle
            | Command_Find_Whole_Word_Clear
            | Command_Find_From_Selection
            | Command_Find_From_Active_Word
            | Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Find_Reveal_Current
            | Command_Replace_Show
            | Command_Replace_Hide
            | Command_Replace_Toggle
            | Command_Replace_Text_Set
            | Command_Replace_Text_Clear
            | Command_Replace_Current
            | Command_Replace_All
            | Command_Run_Project_Search
            | Command_Rerun_Project_Search
            | Command_Open_Project_Search_Bar
            | Command_Toggle_Project_Search_Bar
            | Command_Close_Project_Search_Bar
            | Command_Run_Project_Search_From_Bar
            | Command_Project_Search_From_Selection
            | Command_Project_Search_From_Active_Word
            | Command_Project_Search_Active_Directory
            | Command_Clear_Project_Search
            | Command_Open_Selected_Project_Search_Result
            | Command_Move_Project_Search_Selection_Up
            | Command_Move_Project_Search_Selection_Down
            | Command_Next_Project_Search_Result
            | Command_Previous_Project_Search_Result
            | Command_First_Project_Search_Result
            | Command_Last_Project_Search_Result
            | Command_Reveal_Active_Project_Search_Result
            | Command_Project_Search_Scope_Selected_Directory
            | Command_Project_Search_Kind_Next
            | Command_Project_Search_Kind_Previous
            | Command_Project_Search_Kind_Clear
            | Command_Project_Search_Scope_Set
            | Command_Project_Search_Scope_Clear
            | Command_Project_Search_Case_Toggle
            | Command_Project_Search_Case_Clear
            | Command_Project_Search_Whole_Word_Toggle
            | Command_Project_Search_Whole_Word_Clear
            | Command_Project_Search_Regex_Toggle
            | Command_Project_Search_Regex_Clear
            | Command_Project_Search_Include_Filter_Set
            | Command_Project_Search_Exclude_Filter_Set
            | Command_Project_Search_Include_Filter_Clear
            | Command_Project_Search_Exclude_Filter_Clear
            | Command_Project_Search_Replace_Preview
            | Command_Project_Search_Replace_Toggle_Selected
            | Command_Project_Search_Replace_Include_Selected
            | Command_Project_Search_Replace_Exclude_Selected
            | Command_Project_Search_Replace_Include_File
            | Command_Project_Search_Replace_Exclude_File
            | Command_Project_Search_Replace_Include_All
            | Command_Project_Search_Replace_Exclude_All
            | Command_Project_Search_Replace_Selected
            | Command_Project_Search_Replace_All_Included
            | Command_Project_Search_Replace_Clear_Preview
            | Command_Show_Search_Results_Panel
            | Command_Focus_Search_Results
            | Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down
            | Command_Search_Results_Open_Selected =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Search_Command;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean
   is
   begin
      if Editor.Commands.Semantic_Ids.Is_Semantic_Command (Id) then
         return True;
      end if;

      case Id is
         when Command_Toggle_Problems_Panel
            | Command_Focus_Editor_Text
            | Command_Focus_Search_Results
            | Command_Focus_Problems
            | Command_Toggle_Bottom_Panel_Focus
            | Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down
            | Command_Search_Results_Open_Selected
            | Command_Problems_Move_Up
            | Command_Problems_Move_Down
            | Command_Problems_Page_Up
            | Command_Problems_Page_Down
            | Command_Problems_Open_Selected
            | Command_Problems_Filter_All
            | Command_Problems_Filter_Errors
            | Command_Problems_Filter_Warnings
            | Command_Problems_Filter_Info
            | Command_Problems_Filter_Hints
            | Command_Problems_Sort_By_Location
            | Command_Problems_Sort_By_Severity
            | Command_Problems_Sort_By_Source
            | Command_Problems_Group_By_Severity
            | Command_Problems_Group_By_Source
            | Command_Problems_Focus_Editor
            | Command_Focus_File_Tree
            | Command_File_Tree_Move_Up
            | Command_File_Tree_Move_Down
            | Command_File_Tree_Page_Up
            | Command_File_Tree_Page_Down
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
   end Is_Panel_Focus_Command;

   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean
     renames Editor.Commands.Editing_Ids.Is_Editing_Command;

end Editor.Commands.Classification;
