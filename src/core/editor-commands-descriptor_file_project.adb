with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_File_Project is

   function Make_Descriptor
     (Id          : Command_Id;
      Name        : String;
      Description : String;
      Category    : Command_Category;
      Visibility  : Command_Visibility) return Command_Descriptor
   is
      Effective_Description : constant String :=
        (if Id = No_Command then Description
         elsif Description'Length = 0 then "Execute " & Name & "."
         else Description);
   begin
      return Descriptor_Factory.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Command_Name (Id),
         Label         => Name,
         Description   => Effective_Description,
         Category      => Category,
         Visible       => Visibility = Palette_Command,
         Bindable      => Id /= No_Command
           and then not Is_Public_Build_Command (Id),
         Destructive   => Is_Destructive_Command (Id),
         Lifecycle     => Is_Lifecycle_Command (Id),
         Configuration => Is_Configuration_Command (Id));
   end Make_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      case Id is
         when Command_Save_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save File",
               Description => "Save the active buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_File_As =>
            --  target acquisition is canonical, so Save As is
            --  projected and bindable through the transient file-target prompt.
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Save File As",
               Description   => "Save the current buffer to an explicit path.",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Reload_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload File",
               Description => "Reload the active clean file-backed buffer from disk; dirty buffers are blocked.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Revert_Active_Buffer =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Revert File",
               Description   => "Discard unsaved changes in the active file-backed buffer by rereading disk contents",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_File_Conflict_Keep_Buffer =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Keep Buffer Changes",
               Description   => "Dismiss the active file conflict without reading or writing",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Reload_From_Disk =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Reload Conflict From Disk",
               Description   => "Replace the conflicted buffer from disk after explicit confirmation",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Overwrite_Disk =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Overwrite Disk From Buffer",
               Description   => "Overwrite the conflicted backing file with current buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Cancel =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Cancel File Conflict",
               Description   => "Cancel the active file conflict prompt and preserve buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_Rename_Buffer_File =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Rename Buffer File",
               Description   => "Rename the active clean file-backed buffer's backing file to an explicit path",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Delete_Buffer_File =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Delete Buffer File",
               Description   => "Delete the active clean file-backed buffer's backing file and keep the buffer open as unsaved text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Copy_Buffer_File =>
            return Descriptor_Factory.Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Copy Buffer File",
               Description   => "Copy the active clean file-backed buffer's backing file to an explicit path without changing the active association",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Close_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Quick Open",
               Description => "Hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Close_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List",
               Description => "Hide the open-buffer list",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Open_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open File",
               Description => "Open a file",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Open_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Project",
               Description => "Open a folder as the current project",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Project",
               Description => "Switch explicitly to another project after any required dirty-buffer review.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Show_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Recent Projects",
               Description => "Show known project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Recent Project",
               Description => "Open the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Clear_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Recent Projects",
               Description => "Forget the list of recent project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Remove_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Recent Project",
               Description => "Forget the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Remove_Missing_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Missing Recent Projects",
               Description => "Forget recent projects whose paths are unavailable",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Close_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Project",
               Description => "Close the current project and project-scoped UI state; does not delete project files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Context",
               Description => "Clear the current project root and project-scoped UI state.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh File Tree",
               Description => "Refresh the project File Tree.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Project_Files =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Project Files",
               Description => "Refresh the project file list for Quick Open.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Project_Files_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Files Summary",
               Description => "Show the current project file count.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Active_File_In_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in File Tree",
               Description => "Select the active file in the project File Tree without opening files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_New_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "New Buffer",
               Description => "Create a new untitled buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Buffer",
               Description => "Close the active buffer; dirty buffers open a save/discard/cancel review.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Save",
               Description => "Save dirty file-backed close candidates, then close only successfully saved buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Discard =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Discard",
               Description => "Explicitly discard dirty close candidates without deleting backing files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Close",
               Description => "Cancel the active dirty-buffer close review without mutating buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Reopen_Closed_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reopen Closed Buffer",
               Description => "Reopen the most recently closed clean file-backed buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Other_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Other Buffers",
               Description => "Close every non-active clean buffer and leave dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Buffers",
               Description => "Close all buffers, requiring explicit confirmation when dirty buffers would be discarded.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Clean_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Clean Buffers",
               Description => "Close clean buffers while leaving dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Pin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Buffer",
               Description => "Mark the active buffer as pinned for this session.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Unpin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Buffer",
               Description => "Clear the active buffer pinned marker.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Buffer_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Buffer Pin",
               Description => "Toggle the active buffer pinned state.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Label",
               Description => "Set or replace the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Label",
               Description => "Clear the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Label",
               Description => "Edit the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Label",
               Description => "Show the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Note",
               Description => "Set or replace the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Note",
               Description => "Clear the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Note",
               Description => "Edit the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Note",
               Description => "Show the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Assign_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Buffer Group",
               Description => "Assign the active buffer to a session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Group",
               Description => "Remove the active buffer from its session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer Group",
               Description => "Switch the active buffer group filter by name.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer Group",
               Description => "Cycle to the next existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer Group",
               Description => "Cycle to the previous existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Buffer_Groups =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Buffer Groups",
               Description => "Clear the active buffer group filter and show all open buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Pending Transition",
               Description => "Cancel the blocked operation without saving or discarding files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Retry_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Retry Pending Transition",
               Description => "Retry the blocked operation after unsaved changes are resolved.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Discard_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Discard and Continue Pending Transition",
               Description => "Explicitly discard affected dirty buffers and continue the blocked project operation.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer",
               Description => "Switch to the next open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer",
               Description => "Switch to the previous open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Recent Buffer",
               Description => "Switch to the most recently used non-active open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Recent Buffer",
               Description => "Move forward through recent-buffer traversal",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer",
               Description => "",
               Category    => File_Category,
               Visibility  => Hidden_Command);
         when Command_Close_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Go to Line",
               Description => "Close the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Open_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search",
               Description => "Show Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Close_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Project Search",
               Description => "Hide Project Search without changing files.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Clear_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Query",
               Description => "Clear the Project Search query, replacement text, and retained results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Focus_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus File Tree",
               Description => "Move keyboard focus to the project file tree",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected File",
               Description => "Open or toggle the selected File Tree row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File",
               Description => "Create an empty file under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create Directory",
               Description => "Create a directory under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Rename_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rename File or Directory",
               Description => "Rename the selected project file or directory from explicit input.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Delete_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete File or Directory",
               Description => "Delete the selected project file or directory after explicit confirmation text.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand Selected File Tree Item",
               Description => "Expand the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse Selected File Tree Item",
               Description => "Collapse the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Toggle_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected File Tree Item",
               Description => "Toggle the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse All File Tree Directories",
               Description => "Collapse all directories in the File Tree view state only.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_To_Active_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand File Tree to Active File",
               Description => "Expand parent directories and select the active project file.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Save_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save All",
               Description => "Save all dirty file-backed buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Settings",
               Description => "Save global editor preferences.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Settings",
               Description => "Reload global editor preferences from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Keybindings",
               Description => "Save global keybinding overrides.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Keybindings",
               Description => "Reload global keybinding overrides from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Workspace State",
               Description => "Save structural workspace/session state; does not save dirty file contents.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_File_Project";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_File_Project;
