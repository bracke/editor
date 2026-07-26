with Editor.Command_Kinds;
package body Editor.Commands.Project_File_Ids is

   function Is_Project_File_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Open_File
            | Command_Open_Project
            | Command_Switch_Project
            | Command_Show_Recent_Projects
            | Command_Open_Selected_Recent_Project
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project
            | Command_Close_Project
            | Command_Clear_Project
            | Command_Refresh_File_Tree
            | Command_Refresh_Project_Files
            | Command_Project_Files_Summary
            | Command_Reveal_Active_File_In_Tree
            | Command_New_Buffer
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Pin_Buffer
            | Command_Unpin_Buffer
            | Command_Toggle_Buffer_Pin
            | Command_Set_Buffer_Label
            | Command_Clear_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Clear_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note
            | Command_Assign_Buffer_Group
            | Command_Clear_Buffer_Group
            | Command_Switch_Buffer_Group
            | Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group
            | Command_Show_All_Buffer_Groups
            | Command_Cancel_Pending_Transition
            | Command_Retry_Pending_Transition
            | Command_Discard_Pending_Transition
            | Command_Next_Buffer
            | Command_Previous_Buffer
            | Command_Previous_Recent_Buffer
            | Command_Next_Recent_Buffer
            | Command_Switch_Buffer
            | Command_Save_File
            | Command_Save_File_As
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_Save_All
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
            | Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Project_File_Command;

   function Is_File_Content_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id in Command_Save_File | Command_Save_File_As | Command_Save_All;
   end Is_File_Content_Save_Command;

   function Is_Workspace_Structural_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Workspace_State;
   end Is_Workspace_Structural_Save_Command;

end Editor.Commands.Project_File_Ids;
