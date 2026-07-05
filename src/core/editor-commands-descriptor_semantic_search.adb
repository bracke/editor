with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Semantic_Search is

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
         when Command_Next_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Diagnostic",
               Description => "Jump to the next diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Diagnostic",
               Description => "Jump to the previous diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bookmark",
               Description => "Bookmarks: toggle a bookmark on the current row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Next_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Bookmark",
               Description => "Bookmarks: jump to the next bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Bookmark",
               Description => "Bookmarks: jump to the previous bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Bookmarks",
               Description => "Bookmarks: clear bookmarks in the active buffer",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_All_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear All Bookmarks",
               Description => "Bookmarks: clear bookmarks in all open buffers",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Toggle_Current_Location =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmark: Toggle Current Location",
               Description => "Toggle a session-local bookmark at the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Clear_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Clear All",
               Description => "Clear all session-local bookmarks",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Next",
               Description => "Select the next bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Previous",
               Description => "Select the previous bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Next",
               Description => "Open the next bookmark after the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Previous",
               Description => "Open the previous bookmark before the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Open Selected",
               Description => "Open the selected bookmark through the existing file-open path",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Reveal Current",
               Description => "Select the bookmark nearest to the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Remove Selected",
               Description => "Remove the selected session-local bookmark row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Show",
               Description => "Show the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Hide",
               Description => "Hide the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Hidden_Command);
         when Command_Bookmark_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Toggle",
               Description => "Toggle the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Find_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find",
               Description => "Show a literal find prompt for the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Find",
               Description => "Hide Find and clear the current find text",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find",
               Description => "Toggle the Find prompt for the current buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Find Query",
                  Description => "Replace the Find text for the active buffer",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Find_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Query",
               Description => "Clear the Find text for the active buffer",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Case Sensitivity",
               Description => "Toggle Find between case-insensitive and case-sensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Case Sensitivity",
               Description => "Reset Find to case-insensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Whole Word",
               Description => "Toggle Find between substring and whole-word matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Whole Word",
               Description => "Reset Find to substring matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Selection",
               Description => "Use the active single-line selection as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Active Word",
               Description => "Use the word under the primary caret as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Next in Active Buffer",
               Description => "Move to the next literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Previous in Active Buffer",
               Description => "Move to the previous literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_First =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find First in Active Buffer",
               Description => "Move to the first literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Last =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Last in Active Buffer",
               Description => "Move to the last literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Find Match",
               Description => "Select the Find match at or after the current caret without moving the caret",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Replace_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Replace", Description => "Show the literal Replace field attached to Find", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Replace", Description => "Hide Replace and clear the replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Replace", Description => "Toggle the Replace field", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Text_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor (Id => Id, Name => "Set Replace Text", Description => "Set the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
            begin
               D.Bindable := False; return D;
            end;
         when Command_Replace_Text_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Replace Text", Description => "Clear the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Current =>
            return Make_Descriptor (Id => Id, Name => "Replace Current Find Match", Description => "Replace the selected Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_All =>
            return Make_Descriptor (Id => Id, Name => "Replace All Find Matches", Description => "Replace every current Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Goto_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto Start",
               Description => "Move to document start",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto End",
               Description => "Move to document end",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Rerun_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rerun Project Search",
               Description => "Rerun the current Project Search query.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search",
               Description => "Toggle Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Selection",
               Description => "Search Project for the active single-line selection.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Active Word",
               Description => "Search Project for the word under the primary caret.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Directory",
               Description => "Search the active file directory for the active selection or word.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Project Search Result",
               Description => "Open the selected project search result.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Next_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Result",
               Description => "Move to the next Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Result",
               Description => "Move to the previous Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_First_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "First Project Search Result",
               Description => "Select the first Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Last_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Last Project Search Result",
               Description => "Select the last Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Reveal_Active_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active Project Search Result",
               Description => "Reveal the active buffer in Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Scope_Selected_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Project Search to Selected Directory",
               Description => "Scope Project Search to the selected result's directory.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Kind Filter",
               Description => "Select the next Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Kind Filter",
               Description => "Select the previous Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Kind Filter",
               Description => "Clear the Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Scope",
                  Description => "Set the Project Search path scope.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Scope",
               Description => "Clear the Project Search path scope.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Case Sensitivity",
               Description => "Toggle case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Case Sensitivity",
               Description => "Clear case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Whole Word",
               Description => "Toggle whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Whole Word",
               Description => "Clear whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Regex",
               Description => "Toggle regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Regex",
               Description => "Clear regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Include_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Include Filter",
                  Description => "Set the Project Search include path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Exclude_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Exclude Filter",
                  Description => "Set the Project Search exclude path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Include_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Include Filter",
               Description => "Clear the Project Search include path filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Exclude_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Exclude Filter",
               Description => "Clear the Project Search exclude path filter.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Replace_Preview =>
            return Make_Descriptor (Id => Id, Name => "Preview Project Search Replacements", Description => "Preview replacements for current Project Search results.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Toggle_Selected =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Project Search Replacement", Description => "Include or exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_Selected =>
            return Make_Descriptor (Id => Id, Name => "Include Selected Project Search Replacement", Description => "Include the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_Selected =>
            return Make_Descriptor (Id => Id, Name => "Exclude Selected Project Search Replacement", Description => "Exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_File =>
            return Make_Descriptor (Id => Id, Name => "Include File Project Search Replacements", Description => "Include all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_File =>
            return Make_Descriptor (Id => Id, Name => "Exclude File Project Search Replacements", Description => "Exclude all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_All =>
            return Make_Descriptor (Id => Id, Name => "Include All Project Search Replacements", Description => "Include all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_All =>
            return Make_Descriptor (Id => Id, Name => "Exclude All Project Search Replacements", Description => "Exclude all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Selected =>
            return Make_Descriptor (Id => Id, Name => "Replace Selected Project Search Match", Description => "Replace the selected Project Search match.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_All_Included =>
            return Make_Descriptor (Id => Id, Name => "Replace All Included Project Search Matches", Description => "Replace all included Project Search matches.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Clear_Preview =>
            return Make_Descriptor (Id => Id, Name => "Clear Project Search Replacement Preview", Description => "Clear Project Search replacement preview without changing files.", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Show_Search_Results_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Up",
               Description => "Move the Project Search result selection up.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Down",
               Description => "Move the Project Search result selection down.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Search Result",
               Description => "Open the selected Search Result.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Reset_Settings_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings to Defaults",
               Description => "Reset global editor preferences to built-in defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Validate_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Validate Keybindings",
               Description => "Validate active keybindings against known commands and conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Keybindings",
               Description => "Show the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Keybindings",
               Description => "Focus the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Assign_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Keybinding",
               Description => "Start explicit shortcut capture for the selected bindable command.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Keybinding",
               Description => "Remove the selected user keybinding or selected chord.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Reset_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings to Defaults",
               Description => "Request explicit reset of user keybinding overrides to defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Conflicts =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Keybinding Conflicts",
               Description => "Show keybindings with active/default conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Unbound =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Unbound Commands",
               Description => "Show bindable commands that currently have no active shortcut.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Keybinding Filter",
               Description => "Clear the keybinding filter text.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Cancel_Capture =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Keybinding Capture",
               Description => "Cancel pending keybinding capture or replacement confirmation.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Startup_Show_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Startup Summary",
               Description => "Show the startup and recovery summary without loading, saving, or repairing configuration.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Recover_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Configuration Recovery",
               Description => "Show bounded configuration recovery status for settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Audit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Review Configuration",
               Description => "Review configuration and recovery readiness without changing settings.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings Domain",
               Description => "Reset settings to safe defaults without touching keybindings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings Domain",
               Description => "Reset keybindings to safe defaults without touching settings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Workspace Domain",
               Description => "Clear structural workspace state without touching settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Recent Projects Domain",
               Description => "Clear recent projects without touching settings, keybindings, or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset All Configuration Domains",
               Description => "Request explicit confirmation before resetting settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Confirm =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Reset All Configuration Domains",
               Description => "Confirm the pending reset-all request; project files and dirty buffers are not changed.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Reset All Configuration Domains",
               Description => "Cancel the pending reset-all confirmation without changing configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Settings",
               Description => "Write supported settings fields only; does not write other configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Keybindings",
               Description => "Write normalized valid keybindings only; does not write settings or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Workspace",
               Description => "Write structural workspace fields only; does not write settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Recent Projects",
               Description => "Write lightweight recent project entries only; does not write workspace or settings data.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Restore_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Restore Workspace",
               Description => "Restore saved workspace/session state without saving or restoring unsaved text.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Workspace State",
               Description => "Delete the saved structural workspace/session state for the current project; does not delete project files.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Feature Panel",
               Description => "Show or hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Feature Panel",
               Description => "Show the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Hide_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Feature Panel",
               Description => "Hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Feature Panel",
               Description => "Move focus to the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Feature Panel",
               Description => "Clear feature panel rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Feature_Panel_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Next",
               Description => "Select the next feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Previous",
               Description => "Select the previous feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Feature Panel Row",
               Description => "Open the selected feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline",
               Description => "Refresh Outline for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Outline_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline Project Index",
               Description => "Refresh the Ada language index from known project Ada source files for Outline navigation.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Declaration =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Declaration",
               Description => "Open the declaration target for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Body =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Body",
               Description => "Open the body target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Spec =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Spec",
               Description => "Open the spec target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Find_References =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find References",
               Description => "Show indexed references for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Workspace_Symbols =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Workspace Symbols",
               Description => "Show indexed workspace symbols matching the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Show_Hover =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Hover",
               Description => "Show indexed language details for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Show_Completions =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Completions",
               Description => "Show indexed language completion candidates matching the selected Outline symbol prefix.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Completion_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Completion",
               Description => "Move to the next item in the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Completion_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Completion",
               Description => "Move to the previous item in the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Completion_Accept =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Accept Completion",
               Description => "Insert the selected item from the visible completion menu.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Semantic_Popup_Dismiss =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss Semantic Popup",
               Description => "Close the visible hover or completion popup.",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Rename_Symbol_Preview =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Preview Rename Symbol",
               Description => "Preview the indexed rename impact for the selected Outline symbol without editing files.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Rename_Symbol_Apply =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Apply Rename Symbol",
               Description => "Apply a conflict-free indexed rename for the selected Outline symbol in the active buffer.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Colouring",
               Description => "Refresh Ada semantic colouring data for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Project Index",
               Description => "Refresh known project Ada source files in the language index and update semantic colouring for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Language Index",
               Description => "Clear the Ada language index without changing files or buffers.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Status =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Language Index Status",
               Description => "Show the Ada language index file count, symbol count, overflow state, and fingerprint.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline",
               Description => "Clear Outline rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Outline",
               Description => "Show the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline",
               Description => "Move focus to the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Outline Item",
               Description => "Open the selected Outline item.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Outline Symbol",
               Description => "Reveal and select the current outline symbol without moving the editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Next_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Outline Symbol",
               Description => "Move the editor caret to the next Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Outline Symbol",
               Description => "Move the editor caret to the previous Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline Filter",
               Description => "Focus the Outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Filter_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Outline Symbols",
               Description => "Apply the Outline filter to the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter",
               Description => "Clear the Outline filter and show all Outline items.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Outline Filter",
               Description => "Toggle focus for the local outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Previous Filter",
               Description => "Replace the active outline filter with the previous session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Next Filter",
               Description => "Replace the active outline filter with the next session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter_History =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter History",
               Description => "Clear session-local outline filter history without changing accepted outline rows.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Show_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show Panel",
               Description => "Show the session-local Messages feature panel without diagnostics, LSP, search, persistence, or background collection.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear",
               Description => "Clear session-local Messages rows without mutating outline state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Search_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Buffer",
               Description => "Search the current active buffer snapshot with the current literal search query and replace Search Results rows.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Focus_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Search Query",
               Description => "Focus the session-local Search Results query input without mutating editor text.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Repeat_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Repeat Active Buffer Search",
               Description => "Rerun the last literal Search Results query against the current active buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Search Query",
               Description => "Move the active Search Results query input to the previous session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Search Query",
               Description => "Move the active Search Results query input to the next session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Toggle_Case_Sensitive =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Search Case Sensitivity",
               Description => "Toggle literal Search Results case sensitivity without adding regex or fuzzy behavior.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Show_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search Results without running a new search.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Results",
               Description => "Clear Project Search Results without changing files, Outline, or Messages.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics",
               Description => "Show the current Diagnostics panel without scanning, background collection, or changing editor text.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics",
               Description => "Clear session-local Diagnostics rows without mutating Outline, Messages, or Search Results.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Info Diagnostics",
               Description => "Show or hide informational Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Warning Diagnostics",
               Description => "Show or hide warning Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Error Diagnostics",
               Description => "Show or hide error Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Diagnostics",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics Filter",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Error Diagnostics",
               Description => "Show only error Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Warning Diagnostics",
               Description => "Show only warning Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Info_Notes =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Info and Note Diagnostics",
               Description => "Show only informational Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics from Selected Source",
               Description => "Show only Diagnostics rows from the selected diagnostic source.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Diagnostics",
               Description => "Show Diagnostics reported by the last build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Build Diagnostics",
               Description => "Clear only build-produced Diagnostics rows without mutating Build result or output details.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Diagnostic",
               Description => "Open the file location for the selected Diagnostic when available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Open_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Open Source",
               Description => "Open the source location for the selected Diagnostic row from any diagnostic surface.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Suppress_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Suppress Selected",
               Description => "Request suppression for the selected Diagnostic when suppression is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Show_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Show Suppressed",
               Description => "Show the session suppressed Diagnostic count and latest suppressed row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Restore_Last_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Restore Last Suppressed",
               Description => "Restore the most recently suppressed Diagnostic for review.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Restore_Selected_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Restore Selected Suppressed",
               Description => "Restore the selected suppressed Diagnostic for review.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Clear_Suppressed =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Clear Suppressed",
               Description => "Clear suppressed Diagnostics without restoring them.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostic_Apply_Quick_Fix =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Diagnostic: Apply Quick Fix",
               Description => "Apply the selected Diagnostic quick fix when a fix is available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Execute_Selected_Action =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Execute Selected Diagnostic Action",
               Description => "Execute the primary code action for the selected Diagnostic when available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Diagnostic",
               Description => "Move selection to the next visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Diagnostic",
               Description => "Move selection to the previous visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Diagnostic",
               Description => "Clear the selected Diagnostic.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Copy_Selected_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Copy Selected Diagnostic Text",
               Description => "Copy deterministic text for the selected Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Info Diagnostics",
               Description => "Clear info Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Warning Diagnostics",
               Description => "Clear warning Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Error Diagnostics",
               Description => "Clear error Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Editor_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Editor Diagnostics",
               Description => "Show or hide editor Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_File_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle File Diagnostics",
               Description => "Show or hide file Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Project_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Diagnostics",
               Description => "Show or hide project Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_External_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle External Diagnostics",
               Description => "Show or hide external Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Unknown_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Unknown Diagnostics",
               Description => "Show or hide Diagnostics rows from unknown sources.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Selected_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Selected",
               Description => "Clear the selected session-local Messages row by stable Message_Id.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Copy_Selected_Message_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Copy Selected Text",
               Description => "Copy deterministic selected Messages row text without exposing internal ids.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Info_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Info",
               Description => "Clear informational Messages rows while preserving filters and warnings/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Warning_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Warnings",
               Description => "Clear warning Messages rows while preserving filters and info/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Error_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Errors",
               Description => "Clear error Messages rows while preserving filters and info/warnings.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Info",
               Description => "Toggle visibility for informational Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Warnings",
               Description => "Toggle visibility for warning Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Errors",
               Description => "Toggle visibility for error Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show All Messages",
               Description => "Clear Messages filters and show all session-local Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Message_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Filter",
               Description => "Clear Messages filter text and restore all severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Dismiss_Latest_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss Latest Message",
               Description => "Dismiss the most recent message.",
               Category    => Message_Category,
               Visibility  => Hidden_Command);
         when Command_Dismiss_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss All Messages",
               Description => "Dismiss all messages.",
               Category    => Message_Category,
               Visibility  => Palette_Command);
         when others =>
            raise Program_Error with "command is not owned by Descriptor_Semantic_Search";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Semantic_Search;
