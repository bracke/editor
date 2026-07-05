with Editor.Commands.Descriptor_Factory;

package body Editor.Commands.Descriptor_Semantic_Panels is

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
            raise Program_Error with "command is not owned by Descriptor_Semantic_Panels";
      end case;
   end Descriptor;

end Editor.Commands.Descriptor_Semantic_Panels;
