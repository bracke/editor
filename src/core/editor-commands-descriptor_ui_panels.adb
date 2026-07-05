with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_UI_Panels is

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
         when Command_Toggle_Format_On_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Format On Save",
               Description => "Toggle automatic formatting before file saves.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Open_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open",
               Description => "Show project files and filter them by path.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open",
               Description => "Show or hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Accept_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Quick Open Result",
               Description => "Open or activate the selected Quick Open file.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open Result",
               Description => "Select the next visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open Result",
               Description => "Select the previous visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Query",
                  Description => "Replace the Quick Open query with literal text.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Query",
               Description => "Clear the Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open File Kind",
               Description => "Cycle Quick Open to the next file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open File Kind",
               Description => "Cycle Quick Open to the previous file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open File Kind",
               Description => "Clear the Quick Open file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Scope",
                  Description => "Set the Quick Open project-relative path scope.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Scope",
               Description => "Clear the Quick Open path scope.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_From_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Selected Directory",
               Description => "Scope Quick Open to the selected file directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Parent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open Parent Scope",
               Description => "Move Quick Open scope to the parent directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Reveal_Active =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in Quick Open",
               Description => "Show Quick Open with the active project file selected.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Scope_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Active Directory",
               Description => "Show Quick Open scoped to the active file directory.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Create_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File from Quick Open Query",
               Description => "Create an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Create_With_Parents_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File with Parent Directories from Quick Open Query",
               Description => "Create missing parent directories and an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Priority_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open Recent Priority",
               Description => "Toggle Quick Open between path ordering and recent-file priority ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Priority_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Priority",
               Description => "Restore Quick Open to deterministic path ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List",
               Description => "Inspect and switch among currently open buffers",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Accept_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch To Selected Buffer",
               Description => "Switch to the selected open buffer-list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Buffer List Row",
               Description => "Select the next open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Buffer List Row",
               Description => "Select the previous open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Open Buffer List Filter",
               Description => "Clear the active open-buffer list filter.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Pinned Buffers",
               Description => "Show only pinned open buffers in the Open Buffer List.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Group",
               Description => "Show only open buffers in the named session-local group.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Label",
               Description => "Show only open buffers with the named session-local label.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Noted =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Noted Buffers",
               Description => "Show only open buffers that have session-local notes.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Default",
               Description => "Use the default Open Buffer List order.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Recent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Recent",
               Description => "Order Open Buffer List rows by recent activation.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Name =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Name",
               Description => "Order Open Buffer List rows by display name.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Pinned First",
               Description => "Order pinned open buffers before unpinned buffers in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Group",
               Description => "Order grouped open buffers by group name in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Label",
               Description => "Order labeled open buffers by label text in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Open Buffer List Sort",
               Description => "Cycle to the next Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Open Buffer List Sort",
               Description => "Cycle to the previous Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Selected Buffer List Row",
               Description => "Close the selected open buffer from the buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Selected Open Buffer",
               Description => "Pin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Unpin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Selected Open Buffer",
               Description => "Unpin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Toggle_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected Open Buffer Pin",
               Description => "Toggle pin state for the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Assign =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Open Buffer Group",
               Description => "Assign the selected open buffer to a session-local group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Group",
               Description => "Clear the selected open buffer group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Label",
               Description => "Set the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Label",
               Description => "Clear the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Note",
               Description => "Set the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Note",
               Description => "Clear the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Open Buffer List Preview",
               Description => "Show or hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List Preview",
               Description => "Show a compact read-only preview for the selected open buffer.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List Preview",
               Description => "Hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Next_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Next Line",
               Description => "Scroll the selected-buffer preview down by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Previous_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Previous Line",
               Description => "Scroll the selected-buffer preview up by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Center Open Buffer List Preview on Cursor",
               Description => "Return the selected-buffer preview to that buffer's cursor line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Mark_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Buffer Mark", Description => "Mark or unmark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Set =>
            return Make_Descriptor (Id => Id, Name => "Mark Selected Open Buffer", Description => "Mark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear =>
            return Make_Descriptor (Id => Id, Name => "Unmark Selected Open Buffer", Description => "Clear the mark from the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_All =>
            return Make_Descriptor (Id => Id, Name => "Clear Open Buffer List Marks", Description => "Clear all temporary Open Buffer List marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Invert_Visible =>
            return Make_Descriptor (Id => Id, Name => "Invert Visible Open Buffer List Marks", Description => "Invert marks for the currently visible open-buffer rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Visible =>
            return Make_Descriptor (Id => Id, Name => "Mark Visible Open Buffers", Description => "Mark all currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            return Make_Descriptor (Id => Id, Name => "Clear Visible Buffer Marks", Description => "Clear marks from currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pinned =>
            return Make_Descriptor (Id => Id, Name => "Mark Pinned Open Buffers", Description => "Mark all currently open pinned buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Group", Description => "Mark all currently open buffers in a session-local group.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Label", Description => "Mark all currently open buffers with a session-local label.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Noted =>
            return Make_Descriptor (Id => Id, Name => "Mark Noted Open Buffers", Description => "Mark all currently open buffers that have session-local notes.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Close_Marked =>
            return Make_Descriptor (Id => Id, Name => "Prepare Close Marked Open Buffers", Description => "Prepare confirmation for closing all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Marked Buffer Action", Description => "Confirm the pending marked buffer action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Marked Buffer Action", Description => "Cancel the pending marked buffer action without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Pin Marked Open Buffers", Description => "Pin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Unpin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Unpin Marked Open Buffers", Description => "Unpin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Metadata =>
            return Make_Descriptor (Id => Id, Name => "Clear Marked Buffer Details", Description => "Clear group, label, and note details from all marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Assign =>
            return Make_Descriptor (Id => Id, Name => "Assign Group to Marked Open Buffers", Description => "Assign a group to all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Group from Marked Open Buffers", Description => "Clear group names from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Label on Marked Open Buffers", Description => "Set a label on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Label from Marked Open Buffers", Description => "Clear labels from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Note on Marked Open Buffers", Description => "Set a note on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Note from Marked Open Buffers", Description => "Clear notes from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Marked Buffer Review", Description => "Show or hide a marked-only review view in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Marked Buffer Review", Description => "Show only currently marked open buffers in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Marked Buffer Review", Description => "Return the open-buffer list to its normal view.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pending Marked Close Review", Description => "Show or hide the captured pending marked-close target review in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pending Marked Close Review", Description => "Show captured pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pending Marked Close Review", Description => "Hide pending marked-close target review without cancelling the pending action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pending Marked Close Target", Description => "Move open-buffer list selection to the next captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pending Marked Close Target", Description => "Move open-buffer list selection to the previous captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pending Marked Close", Description => "Report captured and still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Pending Marked Close Target", Description => "Remove the selected buffer from the captured pending marked-close targets without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Pruned Pending Marked Close Target", Description => "Restore the most recently pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pruned Pending Marked Close Targets", Description => "Report pruned pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the next still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the previous still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pruned Pending Marked Close Review", Description => "Show or hide pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pruned Pending Marked Close Review", Description => "Show still-open pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pruned Pending Marked Close Review", Description => "Hide pruned pending marked-close target review without restoring targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Selected Pruned Pending Marked Close Target", Description => "Restore the selected still-open pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Targets", Description => "Report dirty still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the next dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the previous dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Pending Marked Close Target", Description => "Remove the selected dirty pending marked-close target without closing, saving, discarding, or changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Pending Marked Close Prune", Description => "Capture all currently dirty pending marked-close targets for explicit bulk pruning.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Prune Apply Confirmation", Description => "Capture the current dirty-prune preview targets for explicit apply confirmation without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Dirty Prune Apply", Description => "Confirm and prune captured dirty-prune apply targets that are still open, pending, and dirty.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Prune Apply Confirmation", Description => "Clear the pending dirty-prune apply confirmation without mutating preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Prune Apply Targets", Description => "Report captured and still-applicable dirty-prune apply confirmation targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Apply Review", Description => "Toggle review of captured dirty-prune apply targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Apply Review", Description => "Show captured dirty-prune apply targets in the Open Buffer List without confirming them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Apply Review", Description => "Return the open-buffer list to its normal view without clearing dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Apply Target", Description => "Remove the selected buffer from dirty-prune apply confirmation without mutating the preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Apply Target", Description => "Restore the most recently removed buffer to dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Apply Targets", Description => "Report targets removed from the current dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Apply Targets", Description => "Remove stale targets from dirty-prune apply confirmation without recording removals or pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Apply Targets", Description => "Report stale targets in the pending dirty-prune apply confirmation without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Pending Marked Close Prune", Description => "Clear the prepared dirty pending marked-close prune without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Prune", Description => "Report captured and still-applicable dirty pending marked-close prune targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Preview Review", Description => "Toggle review of captured dirty-prune preview targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Preview Review", Description => "Show captured dirty-prune preview targets in the Open Buffer List without applying them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Preview Review", Description => "Return the open-buffer list to its normal view without clearing the dirty-prune preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Preview Target", Description => "Remove the selected buffer from the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Preview Target", Description => "Restore the most recently removed buffer to the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Preview Targets", Description => "Report dirty-prune preview targets removed from the current prepared preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Preview Targets", Description => "Remove stale targets from the prepared dirty-prune preview without pruning active pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Preview Targets", Description => "Report stale targets in the prepared dirty-prune preview without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Marked Open Buffer", Description => "Move the open-buffer list selection to the next marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Marked Open Buffer", Description => "Move the open-buffer list selection to the previous marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Buffer Marks", Description => "Report the current count of marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Open_Command_Palette =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Command Palette",
               Description => "Open the command palette overlay for command discovery and execution.",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Palette_Show_Command_Help =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Command Help",
               Description => "Toggle display-only help for the selected command palette command without executing it.",
               Category    => Overlay_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Theme =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Theme",
               Description => "Switch between available editor themes.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Light =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Light",
               Description => "Use the light editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Dark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Dark",
               Description => "Use the dark editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel",
               Description => "",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Toggle_Minimap =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Minimap",
               Description => "Show or hide the minimap.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Scrollbars =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Scrollbars",
               Description => "Show or hide editor scrollbars.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Numbers",
               Description => "Show or hide gutter line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Number_Mode =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Number Mode",
               Description => "Cycle the editor line-number display mode.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Absolute_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Absolute Line Numbers",
               Description => "Show absolute document line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Relative_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Relative Line Numbers",
               Description => "Show relative distances in the gutter",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Hybrid_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hybrid Line Numbers",
               Description => "Show the current line as absolute and other lines as relative",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Current_Line_Highlight =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Current Line Highlight",
               Description => "Show or hide the current-line highlights",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Blink =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Blink",
               Description => "Enable or disable cursor blinking.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Syntax_Colouring =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Syntax Colouring",
               Description => "Enable or disable syntax colouring",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Diagnostics =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Diagnostics",
               Description => "Show or hide diagnostic decorations",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Problems_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Problems",
               Description => "Show or hide the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Style =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Style",
               Description => "Cycle cursor style",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line",
               Description => "Show a line-number input for jumping in the active buffer",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Go to Line",
               Description => "Toggle the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Prefill_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Current Line",
               Description => "Prefill the go-to-line input from the active caret line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Go to Line Query",
                  Description => "Replace the go-to-line input with the entered line number",
                  Category    => Navigation_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Goto_Line_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Go to Line Query",
               Description => "Clear the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Accept_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Accept Go to Line",
               Description => "Jump to the line entered in the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Focus_Editor_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Editor",
               Description => "Return keyboard focus to editor text",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Search_Results =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Project Search Results",
               Description => "Focus Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Problems =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Problems",
               Description => "Move keyboard focus to the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bottom_Panel_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bottom Panel Focus",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Up",
               Description => "Move the focused Problems selection up",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Down",
               Description => "Move the focused Problems selection down",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Problem",
               Description => "Open the currently selected Problems row",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Problems",
               Description => "Clear the Problems severity filter.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Errors",
               Description => "Filter the Problems panel to errors.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Warnings",
               Description => "Filter the Problems panel to warnings.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Info",
               Description => "Filter the Problems panel to info diagnostics.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Filter_Hints =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Problem Hints",
               Description => "Filter the Problems panel to hints.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Location =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Location",
               Description => "Sort Problems rows by source location.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Severity =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Severity",
               Description => "Sort Problems rows by diagnostic severity.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Sort_By_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Problems by Source",
               Description => "Sort Problems rows by source file.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Group_By_Severity =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Group Problems by Severity",
               Description => "Group Problems review rows by diagnostic severity.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Group_By_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Group Problems by Source",
               Description => "Group Problems review rows by source file.",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Focus_Editor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Focus Editor",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_UI_Panels";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_UI_Panels;
