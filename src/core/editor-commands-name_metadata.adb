with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Commands.Name_Metadata is

   function Stable_Command_Name
     (Id : Command_Id) return String
   is
      Raw    : constant String := Command_Id'Image (Id);
      First  : Positive := Raw'First;
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Id = Command_Palette_Show_Command_Help then
         return "command-palette.show-command-help";
      elsif Id = Command_Open_Project then
         return "project.open";
      elsif Id = Command_Open_File then
         return "file.open";
      elsif Id = Command_Refresh_Outline then
         return "outline.refresh";
      elsif Id = Command_Refresh_Outline_Project_Index then
         return "outline.refresh-project-index";
      elsif Id = Command_Goto_Declaration then
         return "outline.goto-declaration";
      elsif Id = Command_Goto_Body then
         return "outline.goto-body";
      elsif Id = Command_Goto_Spec then
         return "outline.goto-spec";
      elsif Id = Command_Find_References then
         return "semantic.find-references";
      elsif Id = Command_Workspace_Symbols then
         return "semantic.workspace-symbols";
      elsif Id = Command_Show_Hover then
         return "semantic.show-hover";
      elsif Id = Command_Show_Completions then
         return "semantic.show-completions";
      elsif Id = Command_Semantic_Completion_Select_Next then
         return "semantic.completion.select-next";
      elsif Id = Command_Semantic_Completion_Select_Previous then
         return "semantic.completion.select-previous";
      elsif Id = Command_Semantic_Completion_Accept then
         return "semantic.completion.accept";
      elsif Id = Command_Semantic_Popup_Dismiss then
         return "semantic.popup.dismiss";
      elsif Id = Command_Rename_Symbol_Preview then
         return "semantic.rename-symbol-preview";
      elsif Id = Command_Rename_Symbol_Apply then
         return "semantic.rename-symbol-apply";
      elsif Id = Command_Semantic_Refresh_Buffer then
         return "semantic.refresh-buffer";
      elsif Id = Command_Semantic_Refresh_Project_Index then
         return "semantic.refresh-project-index";
      elsif Id = Command_Language_Index_Clear then
         return "language.index.clear";
      elsif Id = Command_Language_Index_Status then
         return "language.index.status";
      elsif Id = Command_Clear_Outline then
         return "outline.clear";
      elsif Id = Command_Show_Outline then
         return "outline.show";
      elsif Id = Command_Focus_Outline then
         return "outline.focus";
      elsif Id = Command_Open_Selected_Outline_Item then
         return "outline.open-selected";
      elsif Id = Command_Select_Current_Outline_Symbol then
         return "outline.select-current-symbol";
      elsif Id = Command_Select_Next_Outline_Item then
         return "outline.select-next";
      elsif Id = Command_Select_Previous_Outline_Item then
         return "outline.select-previous";
      elsif Id = Command_Run_Project then
         return "project.run";
      elsif Id = Command_Run_Tests then
         return "project.test";
      elsif Id = Command_Terminal_Toggle then
         return "terminal.toggle";
      elsif Id = Command_Terminal_Show then
         return "terminal.show";
      elsif Id = Command_Terminal_Hide then
         return "terminal.hide";
      elsif Id = Command_Terminal_Focus then
         return "terminal.focus";
      elsif Id = Command_Terminal_Clear then
         return "terminal.clear";
      elsif Id = Command_Terminal_Clear_Output then
         return "terminal.clear-output";
      elsif Id = Command_Terminal_Select_Next_Task then
         return "terminal.select-next-task";
      elsif Id = Command_Terminal_Select_Previous_Task then
         return "terminal.select-previous-task";
      elsif Id = Command_Terminal_Run_Selected_Task then
         return "terminal.run-selected-task";
      elsif Id = Command_Terminal_Rerun_Last_Task then
         return "terminal.rerun-last-task";
      elsif Id = Command_Terminal_Cancel_Task then
         return "terminal.cancel-task";
      elsif Id = Command_Build_Run then
         return "build.run";
      elsif Id = Command_Build_UI_Toggle then
         return "build.ui.toggle";
      elsif Id = Command_Build_UI_Show then
         return "build.ui.show";
      elsif Id = Command_Build_UI_Hide then
         return "build.ui.hide";
      elsif Id = Command_Build_UI_Focus then
         return "build.ui.focus";
      elsif Id = Command_Build_Result_Focus then
         return "build.result.focus";
      elsif Id = Command_Build_Output_Details_Focus then
         return "build.output-details.focus";
      elsif Id = Command_Build_Output_Details_Select_Stdout then
         return "build.output-details.select-stdout";
      elsif Id = Command_Build_Output_Details_Select_Stderr then
         return "build.output-details.select-stderr";
      elsif Id = Command_Build_Output_Details_Select_Merged then
         return "build.output-details.select-merged";
      elsif Id = Command_Build_Refresh_Candidates then
         return "build.refresh-candidates";
      elsif Id = Command_Build_Select_First_Candidate then
         return "build.select-first-candidate";
      elsif Id = Command_Build_Select_Next_Candidate then
         return "build.select-next-candidate";
      elsif Id = Command_Build_Select_Previous_Candidate then
         return "build.select-previous-candidate";
      elsif Id = Command_Build_Clear_Selected_Candidate then
         return "build.clear-selected-candidate";
      elsif Id = Command_Build_Set_Mode_Default then
         return "build.set-mode-default";
      elsif Id = Command_Build_Set_Mode_Debug then
         return "build.set-mode-debug";
      elsif Id = Command_Build_Set_Mode_Release then
         return "build.set-mode-release";
      elsif Id = Command_Build_Set_Mode_Validation then
         return "build.set-mode-validation";
      elsif Id = Command_Build_Toggle_Diagnostics_Ingestion then
         return "build.toggle-diagnostics-ingestion";
      elsif Id = Command_Build_Cycle_Output_Limit then
         return "build.cycle-output-limit";
      elsif Id = Command_Build_Toggle_Option_Verbose then
         return "build.toggle-option-verbose";
      elsif Id = Command_Build_Toggle_Option_Keep_Going then
         return "build.toggle-option-keep-going";
      elsif Id = Command_Build_Acknowledge_Consent then
         return "build.acknowledge-consent";
      elsif Id = Command_Build_Clear_Consent then
         return "build.clear-consent";
      elsif Id = Command_Build_Cancel then
         return "build.cancel";
      elsif Id = Command_Build_Run_User_Opt_In_Test_Seam then
         return "build.run-user-opt-in-test-seam";
      elsif Id = Command_Diagnostics_Show then
         return "diagnostics.show";
      elsif Id = Command_Startup_Show_Summary then
         return "startup.show-summary";
      elsif Id = Command_Configuration_Recover_Show then
         return "configuration.recover-show";
      elsif Id = Command_Configuration_Audit then
         return "configuration.audit";
      elsif Id = Command_Configuration_Reset_Settings then
         return "configuration.reset-settings";
      elsif Id = Command_Configuration_Reset_Keybindings then
         return "configuration.reset-keybindings";
      elsif Id = Command_Configuration_Reset_Workspace then
         return "configuration.reset-workspace";
      elsif Id = Command_Configuration_Reset_Recent_Projects then
         return "configuration.reset-recent-projects";
      elsif Id = Command_Configuration_Reset_All then
         return "configuration.reset-all";
      elsif Id = Command_Configuration_Reset_All_Confirm then
         return "configuration.reset-all.confirm";
      elsif Id = Command_Configuration_Reset_All_Cancel then
         return "configuration.reset-all.cancel";
      elsif Id = Command_Configuration_Save_Clean_Settings then
         return "configuration.save-clean-settings";
      elsif Id = Command_Configuration_Save_Clean_Keybindings then
         return "configuration.save-clean-keybindings";
      elsif Id = Command_Configuration_Save_Clean_Workspace then
         return "configuration.save-clean-workspace";
      elsif Id = Command_Configuration_Save_Clean_Recent_Projects then
         return "configuration.save-clean-recent-projects";
      elsif Id = Command_Save_Keybindings then
         return "keybindings.save";
      elsif Id = Command_Reload_Keybindings then
         return "keybindings.load";
      elsif Id = Command_Keybindings_Show then
         return "keybindings.show";
      elsif Id = Command_Keybindings_Focus then
         return "keybindings.focus";
      elsif Id = Command_Keybindings_Assign_Selected then
         return "keybindings.assign-selected";
      elsif Id = Command_Keybindings_Remove_Selected then
         return "keybindings.remove-selected";
      elsif Id = Command_Keybindings_Reset_To_Defaults then
         return "keybindings.reset-to-defaults";
      elsif Id = Command_Keybindings_Filter_Conflicts then
         return "keybindings.filter-conflicts";
      elsif Id = Command_Keybindings_Filter_Unbound then
         return "keybindings.filter-unbound";
      elsif Id = Command_Keybindings_Clear_Filter then
         return "keybindings.clear-filter";
      elsif Id = Command_Keybindings_Cancel_Capture then
         return "keybindings.cancel-capture";
      elsif Id = Command_Save_Workspace_State then
         return "workspace.save";
      elsif Id = Command_Restore_Workspace_State then
         return "workspace.restore";
      elsif Id = Command_Clear_Workspace_State then
         return "workspace.clear";
      elsif Id = Command_Switch_Project then
         return "project.switch";
      elsif Id = Command_Show_Recent_Projects then
         return "recent-projects.show";
      elsif Id = Command_Open_Selected_Recent_Project then
         return "recent-projects.open-selected";
      elsif Id = Command_Clear_Recent_Projects then
         return "recent-projects.clear";
      elsif Id = Command_Remove_Selected_Recent_Project then
         return "recent-projects.remove-selected";
      elsif Id = Command_Remove_Missing_Recent_Projects then
         return "recent-projects.remove-missing";
      elsif Id = Command_Select_Next_Recent_Project then
         return "recent-projects.select-next";
      elsif Id = Command_Select_Previous_Recent_Project then
         return "recent-projects.select-previous";
      elsif Id = Command_Diagnostics_Filter_Errors then
         return "diagnostics.filter-errors";
      elsif Id = Command_Diagnostics_Filter_Warnings then
         return "diagnostics.filter-warnings";
      elsif Id = Command_Diagnostics_Filter_Info_Notes then
         return "diagnostics.filter-info-notes";
      elsif Id = Command_Diagnostics_Filter_Source then
         return "diagnostics.filter-source";
      elsif Id = Command_Diagnostics_Filter_Build then
         return "diagnostics.filter-producer-build";
      elsif Id = Command_Diagnostics_Clear_Build then
         return "diagnostics.clear-build";
      elsif Id = Command_Diagnostics_Open_Selected then
         return "diagnostics.open-selected";
      elsif Id = Command_Diagnostic_Open_Source then
         return "ada.diagnostic.open-source";
      elsif Id = Command_Diagnostic_Suppress_Selected then
         return "ada.diagnostic.suppress";
      elsif Id = Command_Diagnostic_Show_Suppressed then
         return "ada.diagnostic.show-suppressed";
      elsif Id = Command_Diagnostic_Restore_Last_Suppressed then
         return "ada.diagnostic.restore-suppressed";
      elsif Id = Command_Diagnostic_Restore_Selected_Suppressed then
         return "ada.diagnostic.restore-selected-suppressed";
      elsif Id = Command_Diagnostic_Clear_Suppressed then
         return "ada.diagnostic.clear-suppressed";
      elsif Id = Command_Diagnostic_Apply_Quick_Fix then
         return "ada.diagnostic.apply-quick-fix";
      elsif Id = Command_Diagnostics_Execute_Selected_Action then
         return "diagnostics.execute-selected-action";
      elsif Id = Command_Diagnostics_Select_Next then
         return "diagnostics.next";
      elsif Id = Command_Diagnostics_Select_Previous then
         return "diagnostics.previous";
      elsif Id = Command_Navigation_Back then
         return "navigation.back";
      elsif Id = Command_Navigation_Forward then
         return "navigation.forward";
      elsif Id = Command_Navigation_History_Clear then
         return "navigation.history.clear";
      elsif Id = Command_Undo then
         return "edit.undo";
      elsif Id = Command_Redo then
         return "edit.redo";
      elsif Id = Command_Edit_History_Clear then
         return "edit.history.clear";
      elsif Id = Command_Copy then
         return "edit.copy";
      elsif Id = Command_Cut then
         return "edit.cut";
      elsif Id = Command_Paste then
         return "edit.paste";
      elsif Id = Command_Clipboard_Clear then
         return "edit.clipboard.clear";
      elsif Id = Command_Select_Left then
         return "selection.extend-left";
      elsif Id = Command_Select_Right then
         return "selection.extend-right";
      elsif Id = Command_Select_Up then
         return "selection.extend-up";
      elsif Id = Command_Select_Down then
         return "selection.extend-down";
      elsif Id = Command_Select_Word_Left then
         return "selection.extend-word-left";
      elsif Id = Command_Select_Word_Right then
         return "selection.extend-word-right";
      elsif Id = Command_Select_Word then
         return "selection.select-word";
      elsif Id = Command_Select_Line then
         return "selection.select-line";
      elsif Id = Command_Select_Line_Start then
         return "selection.extend-line-start";
      elsif Id = Command_Select_Line_End then
         return "selection.extend-line-end";
      elsif Id = Command_Select_Document_Start then
         return "selection.extend-buffer-start";
      elsif Id = Command_Select_Document_End then
         return "selection.extend-buffer-end";
      elsif Id = Command_Select_All then
         return "selection.select-all";
      elsif Id = Command_Selection_Clear then
         return "selection.clear";
      elsif Id = Command_Selection_Delete then
         return "selection.delete";
      elsif Id = Command_Line_Delete then
         return "edit.line.delete";
      elsif Id = Command_Line_Duplicate then
         return "edit.line.duplicate";
      elsif Id = Command_Line_Move_Up then
         return "edit.line.move-up";
      elsif Id = Command_Line_Move_Down then
         return "edit.line.move-down";
      elsif Id = Command_Indent_Increase then
         return "edit.indent.increase";
      elsif Id = Command_Indent_Decrease then
         return "edit.indent.decrease";
      elsif Id = Command_Comment_Line then
         return "edit.comment.line";
      elsif Id = Command_Uncomment_Line then
         return "edit.uncomment.line";
      elsif Id = Command_Toggle_Line_Comment then
         return "edit.comment.toggle-line";
      elsif Id = Command_Line_Join_Next then
         return "edit.line.join-next";
      elsif Id = Command_Line_Split_At_Caret then
         return "edit.line.split-at-caret";
      elsif Id = Command_Trim_Trailing_Whitespace then
         return "edit.trim-trailing-whitespace";
      elsif Id = Command_Format_Buffer then
         return "edit.format-buffer";
      elsif Id = Command_Format_Selected_Text then
         return "edit.format.selection";
      elsif Id = Command_Toggle_Format_On_Save then
         return "file.format-on-save";
      elsif Id = Command_Char_Delete_Previous then
         return "edit.char.delete-previous";
      elsif Id = Command_Char_Delete_Next then
         return "edit.char.delete-next";
      elsif Id = Command_Word_Delete_Previous then
         return "edit.word.delete-previous";
      elsif Id = Command_Word_Delete_Next then
         return "edit.word.delete-next";
      elsif Id = Command_Save_File then
         return "file.save";
      elsif Id = Command_Save_File_As then
         return "file.save-as";
      elsif Id = Command_Save_All then
         return "file.save-all";
      elsif Id = Command_Reload_Active_Buffer then
         return "file.reload-buffer";
      elsif Id = Command_Revert_Active_Buffer then
         return "file.revert-buffer";
      elsif Id = Command_File_Conflict_Keep_Buffer then
         return "file-conflict.keep-buffer";
      elsif Id = Command_File_Conflict_Reload_From_Disk then
         return "file-conflict.reload-from-disk";
      elsif Id = Command_File_Conflict_Overwrite_Disk then
         return "file-conflict.overwrite-disk";
      elsif Id = Command_File_Conflict_Cancel then
         return "file-conflict.cancel";
      elsif Id = Command_Rename_Buffer_File then
         return "file.rename-buffer-file";
      elsif Id = Command_Delete_Buffer_File then
         return "file.delete-buffer-file";
      elsif Id = Command_Copy_Buffer_File then
         return "file.copy-buffer-file";
      elsif Id = Command_Move_Buffer_File then
         return "file.move-buffer-file";
      elsif Id = Command_Goto_Line then
         return "navigation.goto-line.show";
      elsif Id = Command_Goto_Line_Toggle then
         return "navigation.goto-line.toggle";
      elsif Id = Command_Goto_Line_Prefill_Current then
         return "navigation.goto-line.prefill-current";
      elsif Id = Command_Goto_Line_Query_Set then
         return "navigation.goto-line.query.set";
      elsif Id = Command_Goto_Line_Query_Clear then
         return "navigation.goto-line.query.clear";
      elsif Id = Command_Close_Goto_Line then
         return "navigation.goto-line.hide";
      elsif Id = Command_Accept_Goto_Line then
         return "navigation.goto-line.accept";
      elsif Id = Command_Find_Show then
         return "edit.find.show";
      elsif Id = Command_Find_Hide then
         return "edit.find.hide";
      elsif Id = Command_Find_Toggle then
         return "edit.find.toggle";
      elsif Id = Command_Find_Query_Set then
         return "edit.find.query.set";
      elsif Id = Command_Find_Query_Clear then
         return "edit.find.query.clear";
      elsif Id = Command_Find_Case_Toggle then
         return "edit.find.case.toggle";
      elsif Id = Command_Find_Case_Clear then
         return "edit.find.case.clear";
      elsif Id = Command_Find_Whole_Word_Toggle then
         return "edit.find.whole-word.toggle";
      elsif Id = Command_Find_Whole_Word_Clear then
         return "edit.find.whole-word.clear";
      elsif Id = Command_Find_From_Selection then
         return "edit.find.from-selection";
      elsif Id = Command_Find_From_Active_Word then
         return "edit.find.from-active-word";
      elsif Id = Command_Active_Find_Next then
         return "edit.find.next";
      elsif Id = Command_Active_Find_Previous then
         return "edit.find.previous";
      elsif Id = Command_Find_First then
         return "edit.find.first";
      elsif Id = Command_Find_Last then
         return "edit.find.last";
      elsif Id = Command_Find_Reveal_Current then
         return "edit.find.reveal-current";
      elsif Id = Command_Replace_Show then
         return "edit.replace.show";
      elsif Id = Command_Replace_Hide then
         return "edit.replace.hide";
      elsif Id = Command_Replace_Toggle then
         return "edit.replace.toggle";
      elsif Id = Command_Replace_Text_Set then
         return "edit.replace.text.set";
      elsif Id = Command_Replace_Text_Clear then
         return "edit.replace.text.clear";
      elsif Id = Command_Replace_Current then
         return "edit.replace.current";
      elsif Id = Command_Replace_All then
         return "edit.replace.all";
      elsif Id = Command_Toggle_Bookmark then
         return "bookmarks.toggle";
      elsif Id = Command_Next_Bookmark then
         return "bookmarks.next";
      elsif Id = Command_Previous_Bookmark then
         return "bookmarks.previous";
      elsif Id = Command_Clear_Bookmarks then
         return "bookmarks.clear-buffer";
      elsif Id = Command_Clear_All_Bookmarks then
         return "bookmarks.clear-all";
      elsif Id = Command_Bookmark_Toggle_Current_Location then
         return "bookmark.toggle-current-location";
      elsif Id = Command_Bookmark_Clear_All then
         return "bookmark.clear-all";
      elsif Id = Command_Bookmark_Next then
         return "bookmark.next";
      elsif Id = Command_Bookmark_Previous then
         return "bookmark.previous";
      elsif Id = Command_Bookmark_Goto_Next then
         return "bookmark.goto-next";
      elsif Id = Command_Bookmark_Goto_Previous then
         return "bookmark.goto-previous";
      elsif Id = Command_Bookmark_Open_Selected then
         return "bookmark.open-selected";
      elsif Id = Command_Bookmark_Reveal_Current then
         return "bookmark.reveal-current";
      elsif Id = Command_Bookmark_Remove_Selected then
         return "bookmark.remove-selected";
      elsif Id = Command_Bookmark_Show then
         return "bookmark.show";
      elsif Id = Command_Bookmark_Hide then
         return "bookmark.hide";
      elsif Id = Command_Bookmark_Toggle then
         return "bookmark.toggle";
      elsif Id = Command_Open_Quick_Open then
         return "quick-open.show";
      elsif Id = Command_Close_Quick_Open then
         return "project.quick-open.hide";
      elsif Id = Command_Toggle_Quick_Open then
         return "project.quick-open.toggle";
      elsif Id = Command_Accept_Quick_Open then
         return "quick-open.open-selected";
      elsif Id = Command_Quick_Open_Next_Result then
         return "project.quick-open.next";
      elsif Id = Command_Quick_Open_Previous_Result then
         return "project.quick-open.previous";
      elsif Id = Command_Quick_Open_Query_Set then
         return "project.quick-open.query.set";
      elsif Id = Command_Quick_Open_Query_Clear then
         return "project.quick-open.query.clear";
      elsif Id = Command_Quick_Open_Kind_Next then
         return "project.quick-open.kind.next";
      elsif Id = Command_Quick_Open_Kind_Previous then
         return "project.quick-open.kind.previous";
      elsif Id = Command_Quick_Open_Kind_Clear then
         return "project.quick-open.kind.clear";
      elsif Id = Command_Quick_Open_Scope_Set then
         return "project.quick-open.scope.set";
      elsif Id = Command_Quick_Open_Scope_Clear then
         return "project.quick-open.scope.clear";
      elsif Id = Command_Quick_Open_Scope_From_Selected then
         return "project.quick-open.scope.from-selected";
      elsif Id = Command_Quick_Open_Scope_Parent then
         return "project.quick-open.scope.parent";
      elsif Id = Command_Quick_Open_Reveal_Active then
         return "project.quick-open.reveal-active";
      elsif Id = Command_Quick_Open_Scope_Active_Directory then
         return "project.quick-open.scope.active-directory";
      elsif Id = Command_Quick_Open_Create_From_Query then
         return "project.quick-open.create-from-query";
      elsif Id = Command_Quick_Open_Create_With_Parents_From_Query then
         return "project.quick-open.create-with-parents-from-query";
      elsif Id = Command_Quick_Open_Priority_Toggle then
         return "project.quick-open.priority.toggle";
      elsif Id = Command_Quick_Open_Priority_Clear then
         return "project.quick-open.priority.clear";
      elsif Id = Command_Run_Project_Search then
         return "project.search.run";
      elsif Id = Command_Open_Project_Search_Bar then
         return "project.search.show";
      elsif Id = Command_Toggle_Project_Search_Bar then
         return "project.search.toggle";
      elsif Id = Command_Close_Project_Search_Bar then
         return "project.search.hide";
      elsif Id = Command_Run_Project_Search_From_Bar then
         return "project.search.query.set";
      elsif Id = Command_Project_Search_From_Selection then
         return "project.search.from-selection";
      elsif Id = Command_Project_Search_From_Active_Word then
         return "project.search.from-active-word";
      elsif Id = Command_Project_Search_Active_Directory then
         return "project.search.active-directory";
      elsif Id = Command_Clear_Project_Search then
         return "project.search.query.clear";
      elsif Id = Command_Next_Project_Search_Result then
         return "project.search.next";
      elsif Id = Command_Previous_Project_Search_Result then
         return "project.search.previous";
      elsif Id = Command_First_Project_Search_Result then
         return "project.search.first";
      elsif Id = Command_Last_Project_Search_Result then
         return "project.search.last";
      elsif Id = Command_Reveal_Active_Project_Search_Result then
         return "project.search.reveal-active-result";
      elsif Id = Command_Project_Search_Scope_Selected_Directory then
         return "project.search.scope.selected-directory";
      elsif Id = Command_Open_Selected_Project_Search_Result then
         return "project.search.open-selected";
      elsif Id = Command_Project_Search_Kind_Next then
         return "project.search.kind.next";
      elsif Id = Command_Project_Search_Kind_Previous then
         return "project.search.kind.previous";
      elsif Id = Command_Project_Search_Kind_Clear then
         return "project.search.kind.clear";
      elsif Id = Command_Project_Search_Scope_Set then
         return "project.search.scope.set";
      elsif Id = Command_Project_Search_Scope_Clear then
         return "project.search.scope.clear";
      elsif Id = Command_Project_Search_Case_Toggle then
         return "project.search.case.toggle";
      elsif Id = Command_Project_Search_Case_Clear then
         return "project.search.case.clear";
      elsif Id = Command_Project_Search_Whole_Word_Toggle then
         return "project.search.whole-word.toggle";
      elsif Id = Command_Project_Search_Whole_Word_Clear then
         return "project.search.whole-word.clear";
      elsif Id = Command_Project_Search_Regex_Toggle then
         return "project.search.regex.toggle";
      elsif Id = Command_Project_Search_Regex_Clear then
         return "project.search.regex.clear";
      elsif Id = Command_Project_Search_Include_Filter_Set then
         return "project.search.include.set";
      elsif Id = Command_Project_Search_Exclude_Filter_Set then
         return "project.search.exclude.set";
      elsif Id = Command_Project_Search_Include_Filter_Clear then
         return "project.search.include.clear";
      elsif Id = Command_Project_Search_Exclude_Filter_Clear then
         return "project.search.exclude.clear";
      elsif Id = Command_Project_Search_Replace_Preview then
         return "project.search.replace.preview";
      elsif Id = Command_Project_Search_Replace_Toggle_Selected then
         return "project.search.replace.toggle-selected";
      elsif Id = Command_Project_Search_Replace_Include_Selected then
         return "project.search.replace.include-selected";
      elsif Id = Command_Project_Search_Replace_Exclude_Selected then
         return "project.search.replace.exclude-selected";
      elsif Id = Command_Project_Search_Replace_Include_File then
         return "project.search.replace.include-file";
      elsif Id = Command_Project_Search_Replace_Exclude_File then
         return "project.search.replace.exclude-file";
      elsif Id = Command_Project_Search_Replace_Include_All then
         return "project.search.replace.include-all";
      elsif Id = Command_Project_Search_Replace_Exclude_All then
         return "project.search.replace.exclude-all";
      elsif Id = Command_Project_Search_Replace_Selected then
         return "project.search.replace.selected";
      elsif Id = Command_Project_Search_Replace_All_Included then
         return "project.search.replace.all-included";
      elsif Id = Command_Project_Search_Replace_Clear_Preview then
         return "project.search.replace.clear-preview";
      elsif Id = Command_Refresh_File_Tree then
         return "file-tree.refresh";
      elsif Id = Command_Refresh_Project_Files then
         return "project.files.refresh";
      elsif Id = Command_Project_Files_Summary then
         return "project.files.summary";
      elsif Id = Command_Reveal_Active_File_In_Tree then
         return "file-tree.reveal-active-file";
      elsif Id = Command_Focus_File_Tree then
         return "file-tree.focus";
      elsif Id = Command_File_Tree_Move_Up then
         return "file-tree.move-up";
      elsif Id = Command_File_Tree_Move_Down then
         return "file-tree.move-down";
      elsif Id = Command_File_Tree_Page_Up then
         return "file-tree.page-up";
      elsif Id = Command_File_Tree_Page_Down then
         return "file-tree.page-down";
      elsif Id = Command_File_Tree_Open_Selected then
         return "file-tree.open-selected";
      elsif Id = Command_File_Tree_Create_File then
         return "file-tree.create-file";
      elsif Id = Command_File_Tree_Create_Directory then
         return "file-tree.create-directory";
      elsif Id = Command_File_Tree_Rename_Selected then
         return "file-tree.rename-selected";
      elsif Id = Command_File_Tree_Delete_Selected then
         return "file-tree.delete-selected";
      elsif Id = Command_File_Tree_Expand_Selected then
         return "file-tree.expand-selected";
      elsif Id = Command_File_Tree_Collapse_Selected then
         return "file-tree.collapse-selected";
      elsif Id = Command_File_Tree_Toggle_Selected then
         return "file-tree.toggle-selected";
      elsif Id = Command_File_Tree_Collapse_All then
         return "file-tree.collapse-all";
      elsif Id = Command_File_Tree_Expand_To_Active_File then
         return "file-tree.expand-to-active-file";
      elsif Id = Command_Open_Buffer_Switcher then
         return "buffers.switcher.open";
      elsif Id = Command_Close_Buffer_Switcher then
         return "buffers.switcher.close";
      elsif Id = Command_Accept_Buffer_Switcher then
         return "buffers.switcher.accept";
      elsif Id = Command_Buffer_Switcher_Next_Result then
         return "buffers.switcher.next";
      elsif Id = Command_Buffer_Switcher_Previous_Result then
         return "buffers.switcher.previous";
      elsif Id = Command_Buffer_Switcher_Filter_Clear then
         return "buffers.switcher.filter.clear";
      elsif Id = Command_Buffer_Switcher_Filter_Pinned then
         return "buffers.switcher.filter.pinned";
      elsif Id = Command_Buffer_Switcher_Filter_Group then
         return "buffers.switcher.filter.group";
      elsif Id = Command_Buffer_Switcher_Filter_Label then
         return "buffers.switcher.filter.label";
      elsif Id = Command_Buffer_Switcher_Filter_Noted then
         return "buffers.switcher.filter.noted";
      elsif Id = Command_Buffer_Switcher_Sort_Default then
         return "buffers.switcher.sort.default";
      elsif Id = Command_Buffer_Switcher_Sort_Recent then
         return "buffers.switcher.sort.recent";
      elsif Id = Command_Buffer_Switcher_Sort_Name then
         return "buffers.switcher.sort.name";
      elsif Id = Command_Buffer_Switcher_Sort_Pinned then
         return "buffers.switcher.sort.pinned";
      elsif Id = Command_Buffer_Switcher_Sort_Group then
         return "buffers.switcher.sort.group";
      elsif Id = Command_Buffer_Switcher_Sort_Label then
         return "buffers.switcher.sort.label";
      elsif Id = Command_Buffer_Switcher_Sort_Next then
         return "buffers.switcher.sort.next";
      elsif Id = Command_Buffer_Switcher_Sort_Previous then
         return "buffers.switcher.sort.previous";
      elsif Id = Command_Buffer_Switcher_Selected_Close then
         return "buffers.switcher.selected.close";
      elsif Id = Command_Buffer_Switcher_Selected_Pin then
         return "buffers.switcher.selected.pin";
      elsif Id = Command_Buffer_Switcher_Selected_Unpin then
         return "buffers.switcher.selected.unpin";
      elsif Id = Command_Buffer_Switcher_Selected_Toggle_Pin then
         return "buffers.switcher.selected.toggle-pin";
      elsif Id = Command_Buffer_Switcher_Selected_Group_Assign then
         return "buffers.switcher.selected.group.assign";
      elsif Id = Command_Buffer_Switcher_Selected_Group_Clear then
         return "buffers.switcher.selected.group.clear";
      elsif Id = Command_Buffer_Switcher_Selected_Label_Set then
         return "buffers.switcher.selected.label.set";
      elsif Id = Command_Buffer_Switcher_Selected_Label_Clear then
         return "buffers.switcher.selected.label.clear";
      elsif Id = Command_Buffer_Switcher_Selected_Note_Set then
         return "buffers.switcher.selected.note.set";
      elsif Id = Command_Buffer_Switcher_Selected_Note_Clear then
         return "buffers.switcher.selected.note.clear";
      elsif Id = Command_Buffer_Switcher_Preview_Toggle then
         return "buffers.switcher.preview.toggle";
      elsif Id = Command_Buffer_Switcher_Preview_Show then
         return "buffers.switcher.preview.show";
      elsif Id = Command_Buffer_Switcher_Preview_Hide then
         return "buffers.switcher.preview.hide";
      elsif Id = Command_Buffer_Switcher_Preview_Next_Line then
         return "buffers.switcher.preview.next-line";
      elsif Id = Command_Buffer_Switcher_Preview_Previous_Line then
         return "buffers.switcher.preview.previous-line";
      elsif Id = Command_Buffer_Switcher_Preview_Center_Cursor then
         return "buffers.switcher.preview.center-cursor";
      elsif Id = Command_Buffer_Switcher_Mark_Toggle then
         return "buffers.switcher.mark.toggle";
      elsif Id = Command_Buffer_Switcher_Mark_Set then
         return "buffers.switcher.mark.set";
      elsif Id = Command_Buffer_Switcher_Mark_Clear then
         return "buffers.switcher.mark.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_All then
         return "buffers.switcher.mark.clear-all";
      elsif Id = Command_Buffer_Switcher_Mark_Invert_Visible then
         return "buffers.switcher.mark.invert-visible";
      elsif Id = Command_Buffer_Switcher_Mark_Visible then
         return "buffers.switcher.mark.visible";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_Visible then
         return "buffers.switcher.mark.clear-visible";
      elsif Id = Command_Buffer_Switcher_Mark_Pinned then
         return "buffers.switcher.mark.pinned";
      elsif Id = Command_Buffer_Switcher_Mark_Group then
         return "buffers.switcher.mark.group";
      elsif Id = Command_Buffer_Switcher_Mark_Label then
         return "buffers.switcher.mark.label";
      elsif Id = Command_Buffer_Switcher_Mark_Noted then
         return "buffers.switcher.mark.noted";
      elsif Id = Command_Buffer_Switcher_Mark_Close_Marked then
         return "buffers.switcher.mark.close-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Confirm then
         return "buffers.switcher.mark.confirm";
      elsif Id = Command_Buffer_Switcher_Mark_Cancel then
         return "buffers.switcher.mark.cancel";
      elsif Id = Command_Buffer_Switcher_Mark_Pin_Marked then
         return "buffers.switcher.mark.pin-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Unpin_Marked then
         return "buffers.switcher.mark.unpin-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_Metadata then
         return "buffers.switcher.mark.clear-metadata";
      elsif Id = Command_Buffer_Switcher_Mark_Group_Assign then
         return "buffers.switcher.mark.group.assign";
      elsif Id = Command_Buffer_Switcher_Mark_Group_Clear then
         return "buffers.switcher.mark.group.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Label_Set then
         return "buffers.switcher.mark.label.set";
      elsif Id = Command_Buffer_Switcher_Mark_Label_Clear then
         return "buffers.switcher.mark.label.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Note_Set then
         return "buffers.switcher.mark.note.set";
      elsif Id = Command_Buffer_Switcher_Mark_Note_Clear then
         return "buffers.switcher.mark.note.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Toggle then
         return "buffers.switcher.mark.review.toggle";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Show then
         return "buffers.switcher.mark.review.show";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Hide then
         return "buffers.switcher.mark.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Toggle then
         return "buffers.switcher.pending-mark.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Show then
         return "buffers.switcher.pending-mark.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Hide then
         return "buffers.switcher.pending-mark.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Next then
         return "buffers.switcher.pending-mark.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Previous then
         return "buffers.switcher.pending-mark.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Summary then
         return "buffers.switcher.pending-mark.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Remove_Selected then
         return "buffers.switcher.pending-mark.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned then
         return "buffers.switcher.pending-mark.restore-last-pruned";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Summary then
         return "buffers.switcher.pending-mark.pruned-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Next then
         return "buffers.switcher.pending-mark.pruned-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Previous then
         return "buffers.switcher.pending-mark.pruned-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle then
         return "buffers.switcher.pending-mark.pruned-review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show then
         return "buffers.switcher.pending-mark.pruned-review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide then
         return "buffers.switcher.pending-mark.pruned-review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned then
         return "buffers.switcher.pending-mark.restore-selected-pruned";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Summary then
         return "buffers.switcher.pending-mark.dirty-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Next then
         return "buffers.switcher.pending-mark.dirty-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Previous then
         return "buffers.switcher.pending-mark.dirty-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview then
         return "buffers.switcher.pending-mark.dirty-prune.preview";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply then
         return "buffers.switcher.pending-mark.dirty-prune.apply";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm then
         return "buffers.switcher.pending-mark.dirty-prune.apply.confirm";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel then
         return "buffers.switcher.pending-mark.dirty-prune.apply.cancel";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next then
         return "buffers.switcher.pending-mark.dirty-prune.apply.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.apply.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-prune.apply.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed then
         return "buffers.switcher.pending-mark.dirty-prune.apply.restore-last-removed";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale then
         return "buffers.switcher.pending-mark.dirty-prune.apply.clear-stale";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.stale-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel then
         return "buffers.switcher.pending-mark.dirty-prune.cancel";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next then
         return "buffers.switcher.pending-mark.dirty-prune.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle then
         return "buffers.switcher.pending-mark.dirty-prune.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show then
         return "buffers.switcher.pending-mark.dirty-prune.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide then
         return "buffers.switcher.pending-mark.dirty-prune.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-prune.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed then
         return "buffers.switcher.pending-mark.dirty-prune.restore-last-removed";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.removed-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next then
         return "buffers.switcher.pending-mark.dirty-prune.removed-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.removed-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale then
         return "buffers.switcher.pending-mark.dirty-prune.clear-stale";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.stale-summary";
      elsif Id = Command_Buffer_Switcher_Mark_Next then
         return "buffers.switcher.mark.next";
      elsif Id = Command_Buffer_Switcher_Mark_Previous then
         return "buffers.switcher.mark.previous";
      elsif Id = Command_Buffer_Switcher_Mark_Summary then
         return "buffers.switcher.mark.summary";
      elsif Id = Command_Previous_Recent_Buffer then
         return "buffers.recent.previous";
      elsif Id = Command_Focus_Problems then
         return "problems.focus";
      elsif Id = Command_Problems_Move_Up then
         return "problems.selection.previous";
      elsif Id = Command_Problems_Move_Down then
         return "problems.selection.next";
      elsif Id = Command_Problems_Page_Up then
         return "problems.page-up";
      elsif Id = Command_Problems_Page_Down then
         return "problems.page-down";
      elsif Id = Command_Problems_Open_Selected then
         return "problems.open-selected";
      elsif Id = Command_Problems_Filter_All then
         return "problems.filter.all";
      elsif Id = Command_Problems_Filter_Errors then
         return "problems.filter.errors";
      elsif Id = Command_Problems_Filter_Warnings then
         return "problems.filter.warnings";
      elsif Id = Command_Problems_Filter_Info then
         return "problems.filter.info";
      elsif Id = Command_Problems_Filter_Hints then
         return "problems.filter.hints";
      elsif Id = Command_Problems_Sort_By_Location then
         return "problems.sort.location";
      elsif Id = Command_Problems_Sort_By_Severity then
         return "problems.sort.severity";
      elsif Id = Command_Problems_Sort_By_Source then
         return "problems.sort.source";
      elsif Id = Command_Problems_Group_By_Severity then
         return "problems.group.severity";
      elsif Id = Command_Problems_Group_By_Source then
         return "problems.group.source";
      elsif Id = Command_Problems_Focus_Editor then
         return "problems.focus-editor";
      elsif Id = Command_Next_Outline_Symbol then
         return "outline.next-symbol";
      elsif Id = Command_Previous_Outline_Symbol then
         return "outline.previous-symbol";
      elsif Id = Command_Reveal_Current_Outline_Symbol then
         return "outline.reveal-current-symbol";
      elsif Id = Command_Focus_Outline_Filter then
         return "outline.filter.focus";
      elsif Id = Command_Clear_Outline_Filter then
         return "outline.filter.clear";
      elsif Id = Command_Toggle_Outline_Filter then
         return "outline.filter.toggle";
      elsif Id = Command_Outline_Filter_History_Previous then
         return "outline.filter.history.previous";
      elsif Id = Command_Outline_Filter_History_Next then
         return "outline.filter.history.next";
      elsif Id = Command_Next_Recent_Buffer then
         return "buffers.recent.next";
      elsif Id = Command_Close_Other_Buffers then
         return "file.close-other-buffers";
      elsif Id = Command_Close_All_Buffers then
         return "file.close-all-buffers";
      elsif Id = Command_Close_All_Clean_Buffers then
         return "file.close-clean-buffers";
      elsif Id = Command_Confirm_Close_Save then
         return "buffer.confirm-close-save";
      elsif Id = Command_Confirm_Close_Discard then
         return "buffer.confirm-close-discard";
      elsif Id = Command_Cancel_Close then
         return "buffer.cancel-close";
      elsif Id = Command_Pin_Buffer then
         return "buffers.pin";
      elsif Id = Command_Unpin_Buffer then
         return "buffers.unpin";
      elsif Id = Command_Toggle_Buffer_Pin then
         return "buffers.toggle-pin";
      elsif Id = Command_Set_Buffer_Label then
         return "buffers.label.set";
      elsif Id = Command_Clear_Buffer_Label then
         return "buffers.label.clear";
      elsif Id = Command_Edit_Buffer_Label then
         return "buffers.label.edit";
      elsif Id = Command_Show_Buffer_Label then
         return "buffers.label.show";
      elsif Id = Command_Set_Buffer_Note then
         return "buffers.note.set";
      elsif Id = Command_Clear_Buffer_Note then
         return "buffers.note.clear";
      elsif Id = Command_Edit_Buffer_Note then
         return "buffers.note.edit";
      elsif Id = Command_Show_Buffer_Note then
         return "buffers.note.show";
      elsif Id = Command_Assign_Buffer_Group then
         return "buffers.group.assign";
      elsif Id = Command_Clear_Buffer_Group then
         return "buffers.group.clear";
      elsif Id = Command_Switch_Buffer_Group then
         return "buffers.group.switch";
      elsif Id = Command_Next_Buffer_Group then
         return "buffers.group.next";
      elsif Id = Command_Previous_Buffer_Group then
         return "buffers.group.previous";
      elsif Id = Command_Close_Active_Buffer then
         return "file.close-buffer";
      elsif Id = Command_Reopen_Closed_Buffer then
         return "file.reopen-closed-buffer";
      elsif Id = Command_Show_All_Buffer_Groups then
         return "buffers.group.show-all";
      elsif Id = Command_Discard_Pending_Transition then
         return "lifecycle.pending.discard";
      end if;

      if Raw'Length >= 8 and then Raw (Raw'First .. Raw'First + 7) = "COMMAND_" then
         First := Raw'First + 8;
      end if;

      for I in First .. Raw'Last loop
         if Raw (I) = '_' then
            Append (Result, "-");
         else
            Append (Result, Ada.Characters.Handling.To_Lower (Raw (I)));
         end if;
      end loop;
      return To_String (Result);
   end Stable_Command_Name;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id
   is
      N : constant String := Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both));
   begin
      --  product workflow names.  These are the daily-use command
      --  ids documented for the product surface.  Removed and spelling-only
      --  variants intentionally do not resolve here.
      if N = "command-palette.show-command-help"
      then
         Found := True;
         return Command_Palette_Show_Command_Help;
      elsif N = "project.open" or else N = "open-project" then
         Found := True;
         return Command_Open_Project;
      elsif N = "project.close" then
         Found := True;
         return Command_Close_Project;
      elsif N = "project.switch" then
         Found := True;
         return Command_Switch_Project;
      elsif N = "project.reopen-recent"
      then
         Found := True;
         return Command_Open_Selected_Recent_Project;
      elsif N = "file.open" or else N = "open-file" then
         Found := True;
         return Command_Open_File;
      elsif N = "file.save" then
         Found := True;
         return Command_Save_File;
      elsif N = "file.save-as"
      then
         Found := True;
         return Command_Save_File_As;
      elsif N = "file.reload" then
         Found := True;
         return Command_Reload_Active_Buffer;
      elsif N = "file.revert" then
         Found := True;
         return Command_Revert_Active_Buffer;
      elsif N = "file-tree.refresh"
      then
         Found := True;
         return Command_Refresh_File_Tree;
      elsif N = "file-tree.open-selected"
      then
         Found := True;
         return Command_File_Tree_Open_Selected;
      elsif N = "file-tree.rename"
      then
         Found := True;
         return Command_File_Tree_Rename_Selected;
      elsif N = "file-tree.delete"
      then
         Found := True;
         return Command_File_Tree_Delete_Selected;
      elsif N = "file-tree.create-file"
      then
         Found := True;
         return Command_File_Tree_Create_File;
      elsif N = "file-tree.create-directory"
      then
         Found := True;
         return Command_File_Tree_Create_Directory;
      elsif N = "quick-open.show"
      then
         Found := True;
         return Command_Open_Quick_Open;
      elsif N = "quick-open.open-selected"
      then
         Found := True;
         return Command_Accept_Quick_Open;
      elsif N = "search.project" then
         Found := True;
         return Command_Run_Project_Search;
      elsif N = "search.open-selected"
      then
         Found := True;
         return Command_Open_Selected_Project_Search_Result;
      elsif N = "outline.refresh" then
         Found := True;
         return Command_Refresh_Outline;
      elsif N = "outline.refresh-project-index" then
         Found := True;
         return Command_Refresh_Outline_Project_Index;
      elsif N = "outline.goto-declaration" then
         Found := True;
         return Command_Goto_Declaration;
      elsif N = "outline.goto-body" then
         Found := True;
         return Command_Goto_Body;
      elsif N = "outline.goto-spec" then
         Found := True;
         return Command_Goto_Spec;
      elsif N = "semantic.find-references" then
         Found := True;
         return Command_Find_References;
      elsif N = "semantic.workspace-symbols"
        or else N = "workspace.symbols"
        or else N = "workspace-symbols"
      then
         Found := True;
         return Command_Workspace_Symbols;
      elsif N = "semantic.show-hover" then
         Found := True;
         return Command_Show_Hover;
      elsif N = "semantic.show-completions" then
         Found := True;
         return Command_Show_Completions;
      elsif N = "semantic.completion.select-next" then
         Found := True;
         return Command_Semantic_Completion_Select_Next;
      elsif N = "semantic.completion.select-previous" then
         Found := True;
         return Command_Semantic_Completion_Select_Previous;
      elsif N = "semantic.completion.accept" then
         Found := True;
         return Command_Semantic_Completion_Accept;
      elsif N = "semantic.popup.dismiss" then
         Found := True;
         return Command_Semantic_Popup_Dismiss;
      elsif N = "semantic.rename-symbol-preview"
        or else N = "refactor.rename-symbol-preview"
        or else N = "refactor.rename-symbol"
      then
         Found := True;
         return Command_Rename_Symbol_Preview;
      elsif N = "semantic.rename-symbol-apply"
        or else N = "refactor.rename-symbol-apply"
      then
         Found := True;
         return Command_Rename_Symbol_Apply;
      elsif N = "semantic.refresh-buffer" then
         Found := True;
         return Command_Semantic_Refresh_Buffer;
      elsif N = "semantic.refresh-project-index" then
         Found := True;
         return Command_Semantic_Refresh_Project_Index;
      elsif N = "language.index.clear" then
         Found := True;
         return Command_Language_Index_Clear;
      elsif N = "language.index.status" then
         Found := True;
         return Command_Language_Index_Status;
      elsif N = "outline.show" then
         Found := True;
         return Command_Show_Outline;
      elsif N = "outline.focus" then
         Found := True;
         return Command_Focus_Outline;
      elsif N = "outline.clear" then
         Found := True;
         return Command_Clear_Outline;
      elsif N = "outline.open-selected"
      then
         Found := True;
         return Command_Open_Selected_Outline_Item;
      elsif N = "outline.select-current-symbol"
        or else N = "select-current-outline-symbol"
      then
         Found := True;
         return Command_Select_Current_Outline_Symbol;
      elsif N = "outline.select-next"
        or else N = "select-next-outline-item"
      then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.select-previous"
        or else N = "select-previous-outline-item"
      then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "build.output.show" then
         Found := True;
         return Command_Build_UI_Show;
      elsif N = "build.output.toggle" then
         Found := True;
         return Command_Build_UI_Toggle;
      elsif N = "build.output.hide" then
         Found := True;
         return Command_Build_UI_Hide;
      elsif N = "build.output.focus" then
         Found := True;
         return Command_Build_UI_Focus;
      elsif N = "buffer.switch-next"
      then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.switch-previous"
      then
         Found := True;
         return Command_Previous_Buffer;
      elsif N = "buffer.close-all-clean"
      then
         Found := True;
         return Command_Close_All_Clean_Buffers;
      elsif N = "workspace.save" then
         Found := True;
         return Command_Save_Workspace_State;
      elsif N = "workspace.restore" then
         Found := True;
         return Command_Restore_Workspace_State;
      elsif N = "workspace.clear" then
         Found := True;
         return Command_Clear_Workspace_State;
      elsif N = "project.run" then
         Found := True;
         return Command_Run_Project;
      elsif N = "project.test" or else N = "test.run" then
         Found := True;
         return Command_Run_Tests;
      elsif N = "terminal.toggle" then
         Found := True;
         return Command_Terminal_Toggle;
      elsif N = "terminal.show" then
         Found := True;
         return Command_Terminal_Show;
      elsif N = "terminal.hide" then
         Found := True;
         return Command_Terminal_Hide;
      elsif N = "terminal.focus" then
         Found := True;
         return Command_Terminal_Focus;
      elsif N = "terminal.clear" then
         Found := True;
         return Command_Terminal_Clear;
      elsif N = "terminal.clear-output" then
         Found := True;
         return Command_Terminal_Clear_Output;
      elsif N = "terminal.select-next-task" then
         Found := True;
         return Command_Terminal_Select_Next_Task;
      elsif N = "terminal.select-previous-task" then
         Found := True;
         return Command_Terminal_Select_Previous_Task;
      elsif N = "terminal.run-selected-task" then
         Found := True;
         return Command_Terminal_Run_Selected_Task;
      elsif N = "terminal.rerun-last-task" then
         Found := True;
         return Command_Terminal_Rerun_Last_Task;
      elsif N = "terminal.cancel-task" then
         Found := True;
         return Command_Terminal_Cancel_Task;
      elsif N = "build.run" then
         Found := True;
         return Command_Build_Run;
      elsif N = "build.ui.toggle" then
         Found := True;
         return Command_Build_UI_Toggle;
      elsif N = "build.ui.show" then
         Found := True;
         return Command_Build_UI_Show;
      elsif N = "build.ui.hide" then
         Found := True;
         return Command_Build_UI_Hide;
      elsif N = "build.ui.focus" then
         Found := True;
         return Command_Build_UI_Focus;
      elsif N = "build.result.focus" then
         Found := True;
         return Command_Build_Result_Focus;
      elsif N = "build.output-details.focus" then
         Found := True;
         return Command_Build_Output_Details_Focus;
      elsif N = "build.output-details.select-stdout" then
         Found := True;
         return Command_Build_Output_Details_Select_Stdout;
      elsif N = "build.output-details.select-stderr" then
         Found := True;
         return Command_Build_Output_Details_Select_Stderr;
      elsif N = "build.output-details.select-merged" then
         Found := True;
         return Command_Build_Output_Details_Select_Merged;
      elsif N = "build.refresh-candidates" then
         Found := True;
         return Command_Build_Refresh_Candidates;
      elsif N = "build.select-first-candidate" then
         Found := True;
         return Command_Build_Select_First_Candidate;
      elsif N = "build.select-next-candidate" then
         Found := True;
         return Command_Build_Select_Next_Candidate;
      elsif N = "build.select-previous-candidate" then
         Found := True;
         return Command_Build_Select_Previous_Candidate;
      elsif N = "build.clear-selected-candidate" then
         Found := True;
         return Command_Build_Clear_Selected_Candidate;
      elsif N = "build.set-mode-default" then
         Found := True;
         return Command_Build_Set_Mode_Default;
      elsif N = "build.set-mode-debug" then
         Found := True;
         return Command_Build_Set_Mode_Debug;
      elsif N = "build.set-mode-release" then
         Found := True;
         return Command_Build_Set_Mode_Release;
      elsif N = "build.set-mode-validation" then
         Found := True;
         return Command_Build_Set_Mode_Validation;
      elsif N = "build.toggle-diagnostics-ingestion" then
         Found := True;
         return Command_Build_Toggle_Diagnostics_Ingestion;
      elsif N = "build.cycle-output-limit" then
         Found := True;
         return Command_Build_Cycle_Output_Limit;
      elsif N = "build.toggle-option-verbose" then
         Found := True;
         return Command_Build_Toggle_Option_Verbose;
      elsif N = "build.toggle-option-keep-going" then
         Found := True;
         return Command_Build_Toggle_Option_Keep_Going;
      elsif N = "build.acknowledge-consent" then
         Found := True;
         return Command_Build_Acknowledge_Consent;
      elsif N = "build.clear-consent" then
         Found := True;
         return Command_Build_Clear_Consent;
      elsif N = "build.cancel" then
         Found := True;
         return Command_Build_Cancel;
      elsif N = "build.run-user-opt-in-test-seam" then
         Found := True;
         return Command_Build_Run_User_Opt_In_Test_Seam;
      elsif N = "diagnostics.show" or else N = "diagnostics-show" then
         Found := True;
         return Command_Diagnostics_Show;
      elsif N = "diagnostics.hide" then
         --  accepts the public Problems-style dot-form hide command name
         --  without adding diagnostic row/source/filter payloads.  Reuse the
         --  generic feature-panel hide route so persisted command identity and
         --  panel mutation boundaries remain unchanged.
         Found := True;
         return Command_Hide_Feature_Panel;
      elsif N = "diagnostics.focus" then
         --  Same no-payload command-name policy as diagnostics.hide: focusing the
         --  panel is a generic panel action, not a Diagnostics row action.
         Found := True;
         return Command_Focus_Feature_Panel;
      elsif N = "diagnostics.clear" then
         Found := True;
         return Command_Diagnostics_Clear;
      elsif N = "diagnostics.next" then
         Found := True;
         return Command_Diagnostics_Select_Next;
      elsif N = "diagnostics.previous" then
         Found := True;
         return Command_Diagnostics_Select_Previous;
      elsif N = "diagnostics.open-selected" then
         Found := True;
         return Command_Diagnostics_Open_Selected;
      elsif N = "ada.diagnostic.open-source" then
         Found := True;
         return Command_Diagnostic_Open_Source;
      elsif N = "ada.diagnostic.suppress" then
         Found := True;
         return Command_Diagnostic_Suppress_Selected;
      elsif N = "ada.diagnostic.show-suppressed" then
         Found := True;
         return Command_Diagnostic_Show_Suppressed;
      elsif N = "ada.diagnostic.restore-suppressed" then
         Found := True;
         return Command_Diagnostic_Restore_Last_Suppressed;
      elsif N = "ada.diagnostic.restore-selected-suppressed" then
         Found := True;
         return Command_Diagnostic_Restore_Selected_Suppressed;
      elsif N = "ada.diagnostic.clear-suppressed" then
         Found := True;
         return Command_Diagnostic_Clear_Suppressed;
      elsif N = "ada.diagnostic.apply-quick-fix" then
         Found := True;
         return Command_Diagnostic_Apply_Quick_Fix;
      elsif N = "diagnostics.execute-selected-action"
        or else N = "diagnostics.code-action"
      then
         Found := True;
         return Command_Diagnostics_Execute_Selected_Action;
      elsif N = "diagnostics.filter-all" then
         Found := True;
         return Command_Diagnostics_Show_All;
      elsif N = "diagnostics.filter-clear" then
         Found := True;
         return Command_Diagnostics_Clear_Filter;
      elsif N = "diagnostics.filter-errors" then
         Found := True;
         return Command_Diagnostics_Filter_Errors;
      elsif N = "diagnostics.filter-warnings" then
         Found := True;
         return Command_Diagnostics_Filter_Warnings;
      elsif N = "diagnostics.filter-info-notes" then
         Found := True;
         return Command_Diagnostics_Filter_Info_Notes;
      elsif N = "diagnostics.filter-source" then
         Found := True;
         return Command_Diagnostics_Filter_Source;
      elsif N = "diagnostics.filter-producer-build" then
         Found := True;
         return Command_Diagnostics_Filter_Build;
      elsif N = "diagnostics.clear-build" then
         Found := True;
         return Command_Diagnostics_Clear_Build;
      elsif N = "navigation.goto-line.show" or else N = "navigation.goto-line" then
         Found := True;
         return Command_Goto_Line;
      elsif N = "navigation.goto-line.toggle" then
         Found := True;
         return Command_Goto_Line_Toggle;
      elsif N = "navigation.goto-line.prefill-current" then
         Found := True;
         return Command_Goto_Line_Prefill_Current;
      elsif N = "navigation.goto-line.query.set" then
         Found := True;
         return Command_Goto_Line_Query_Set;
      elsif N = "navigation.goto-line.query.clear" then
         Found := True;
         return Command_Goto_Line_Query_Clear;
      elsif N = "navigation.goto-line.hide" then
         Found := True;
         return Command_Close_Goto_Line;
      elsif N = "navigation.goto-line.accept" then
         Found := True;
         return Command_Accept_Goto_Line;
      elsif N = "cursor.word-left" then
         Found := True;
         return Command_Move_Word_Left;
      elsif N = "cursor.word-right" then
         Found := True;
         return Command_Move_Word_Right;
      elsif N = "selection.extend-left" then
         Found := True;
         return Command_Select_Left;
      elsif N = "selection.extend-right" then
         Found := True;
         return Command_Select_Right;
      elsif N = "selection.extend-up" then
         Found := True;
         return Command_Select_Up;
      elsif N = "selection.extend-down" then
         Found := True;
         return Command_Select_Down;
      elsif N = "selection.extend-word-left" then
         Found := True;
         return Command_Select_Word_Left;
      elsif N = "selection.extend-word-right" then
         Found := True;
         return Command_Select_Word_Right;
      elsif N = "selection.extend-line-start" then
         Found := True;
         return Command_Select_Line_Start;
      elsif N = "selection.extend-line-end" then
         Found := True;
         return Command_Select_Line_End;
      elsif N = "selection.extend-buffer-start" then
         Found := True;
         return Command_Select_Document_Start;
      elsif N = "selection.extend-buffer-end" then
         Found := True;
         return Command_Select_Document_End;
      elsif N = "selection.select-word" then
         Found := True;
         return Command_Select_Word;
      elsif N = "selection.select-line" then
         Found := True;
         return Command_Select_Line;
      elsif N = "selection.expand-to-line" then
         Found := True;
         return Command_Select_Line;
      elsif N = "edit.delete-word-backward" then
         Found := True;
         return Command_Word_Delete_Previous;
      elsif N = "edit.delete-word-forward" then
         Found := True;
         return Command_Word_Delete_Next;
      elsif N = "edit.duplicate-line" then
         Found := True;
         return Command_Line_Duplicate;
      elsif N = "edit.move-line-up" then
         Found := True;
         return Command_Line_Move_Up;
      elsif N = "edit.move-line-down" then
         Found := True;
         return Command_Line_Move_Down;
      elsif N = "edit.join-lines" then
         Found := True;
         return Command_Line_Join_Next;
      elsif N = "edit.split-line" then
         Found := True;
         return Command_Line_Split_At_Caret;
      elsif N = "edit.undo" then
         Found := True;
         return Command_Undo;
      elsif N = "edit.redo" then
         Found := True;
         return Command_Redo;
      elsif N = "edit.history.clear" then
         Found := True;
         return Command_Edit_History_Clear;
      elsif N = "edit.copy" then
         Found := True;
         return Command_Copy;
      elsif N = "edit.cut" then
         Found := True;
         return Command_Cut;
      elsif N = "edit.paste" then
         Found := True;
         return Command_Paste;
      elsif N = "edit.clipboard.clear" then
         Found := True;
         return Command_Clipboard_Clear;
      elsif N = "selection.select-all" or else N = "edit.select-all" then
         Found := True;
         return Command_Select_All;
      elsif N = "selection.clear" or else N = "edit.selection.clear" then
         Found := True;
         return Command_Selection_Clear;
      elsif N = "selection.delete" then
         Found := True;
         return Command_Selection_Delete;
      elsif N = "edit.line.delete" then
         Found := True;
         return Command_Line_Delete;
      elsif N = "edit.line.duplicate" then
         Found := True;
         return Command_Line_Duplicate;
      elsif N = "edit.line.move-up" then
         Found := True;
         return Command_Line_Move_Up;
      elsif N = "edit.line.move-down" then
         Found := True;
         return Command_Line_Move_Down;
      elsif N = "edit.indent.increase" then
         Found := True;
         return Command_Indent_Increase;
      elsif N = "edit.indent.decrease" then
         Found := True;
         return Command_Indent_Decrease;
      elsif N = "edit.comment.line" then
         Found := True;
         return Command_Comment_Line;
      elsif N = "edit.uncomment.line" then
         Found := True;
         return Command_Uncomment_Line;
      elsif N = "edit.comment.toggle-line" then
         Found := True;
         return Command_Toggle_Line_Comment;
      elsif N = "edit.line.join-next" then
         Found := True;
         return Command_Line_Join_Next;
      elsif N = "edit.line.split-at-caret" then
         Found := True;
         return Command_Line_Split_At_Caret;
      elsif N = "edit.trim-trailing-whitespace" then
         Found := True;
         return Command_Trim_Trailing_Whitespace;
      elsif N = "edit.format-buffer"
        or else N = "edit.format.document"
        or else N = "format-buffer"
      then
         Found := True;
         return Command_Format_Buffer;
      elsif N = "edit.format.selection"
        or else N = "format-selection"
      then
         Found := True;
         return Command_Format_Selected_Text;
      elsif N = "file.format-on-save"
        or else N = "edit.format.on-save"
      then
         Found := True;
         return Command_Toggle_Format_On_Save;
      elsif N = "edit.char.delete-previous" then
         Found := True;
         return Command_Char_Delete_Previous;
      elsif N = "edit.char.delete-next" then
         Found := True;
         return Command_Char_Delete_Next;
      elsif N = "edit.word.delete-previous" then
         Found := True;
         return Command_Word_Delete_Previous;
      elsif N = "edit.word.delete-next" then
         Found := True;
         return Command_Word_Delete_Next;
      elsif N = "file.save-all" then
         Found := True;
         return Command_Save_All;
      elsif N = "file.reload-from-disk" or else N = "file.reload-buffer" then
         Found := True;
         return Command_Reload_Active_Buffer;
      elsif N = "file.revert-buffer" then
         Found := True;
         return Command_Revert_Active_Buffer;
      elsif N = "file-conflict.keep-buffer" then
         Found := True;
         return Command_File_Conflict_Keep_Buffer;
      elsif N = "file-conflict.reload-from-disk" then
         Found := True;
         return Command_File_Conflict_Reload_From_Disk;
      elsif N = "file-conflict.overwrite-disk" then
         Found := True;
         return Command_File_Conflict_Overwrite_Disk;
      elsif N = "file-conflict.cancel" then
         Found := True;
         return Command_File_Conflict_Cancel;
      elsif N = "file.rename-buffer-file" then
         Found := True;
         return Command_Rename_Buffer_File;
      elsif N = "file.delete-buffer-file" then
         Found := True;
         return Command_Delete_Buffer_File;
      elsif N = "file.copy-buffer-file" then
         Found := True;
         return Command_Copy_Buffer_File;
      elsif N = "file.move-buffer-file" then
         Found := True;
         return Command_Move_Buffer_File;
      elsif N = "file.close-buffer"
        or else N = "buffer.close-active"
      then
         Found := True;
         return Command_Close_Active_Buffer;
      elsif N = "file.close-all-buffers"
        or else N = "buffer.close-all"
      then
         Found := True;
         return Command_Close_All_Buffers;
      elsif N = "buffer.confirm-close-save" then
         Found := True;
         return Command_Confirm_Close_Save;
      elsif N = "buffer.confirm-close-discard" then
         Found := True;
         return Command_Confirm_Close_Discard;
      elsif N = "buffer.cancel-close" then
         Found := True;
         return Command_Cancel_Close;
      elsif N = "file.close-other-buffers"
        or else N = "buffer.close-other"
      then
         Found := True;
         return Command_Close_Other_Buffers;
      elsif N = "file.close-clean-buffers"
        or else N = "buffer.close-clean"
        or else N = "buffer-list.close-clean"
        or else N = "buffer.list.close-clean"
      then
         Found := True;
         return Command_Close_All_Clean_Buffers;
      elsif N = "file.reopen-closed-buffer" then
         Found := True;
         return Command_Reopen_Closed_Buffer;
      elsif N = "buffer.close-selected"
        or else N = "buffer-list.close-selected"
        or else N = "buffers.switcher.selected.close"
      then
         Found := True;
         return Command_Buffer_Switcher_Selected_Close;
      elsif N = "lifecycle.pending.discard" then
         Found := True;
         return Command_Discard_Pending_Transition;
      elsif N = "file.reveal-active-in-tree"
        or else N = "file-tree.reveal-active-file"
      then
         Found := True;
         return Command_Reveal_Active_File_In_Tree;
      elsif N = "file-tree.focus" then
         Found := True;
         return Command_Focus_File_Tree;
      elsif N = "file-tree.move-up" then
         Found := True;
         return Command_File_Tree_Move_Up;
      elsif N = "file-tree.move-down" then
         Found := True;
         return Command_File_Tree_Move_Down;
      elsif N = "file-tree.page-up" then
         Found := True;
         return Command_File_Tree_Page_Up;
      elsif N = "file-tree.page-down" then
         Found := True;
         return Command_File_Tree_Page_Down;
      elsif N = "file-tree.rename-selected" then
         Found := True;
         return Command_File_Tree_Rename_Selected;
      elsif N = "file-tree.delete-selected" then
         Found := True;
         return Command_File_Tree_Delete_Selected;
      elsif N = "file-tree.expand-selected" then
         Found := True;
         return Command_File_Tree_Expand_Selected;
      elsif N = "file-tree.collapse-selected" then
         Found := True;
         return Command_File_Tree_Collapse_Selected;
      elsif N = "file-tree.toggle-selected" then
         Found := True;
         return Command_File_Tree_Toggle_Selected;
      elsif N = "file-tree.collapse-all" then
         Found := True;
         return Command_File_Tree_Collapse_All;
      elsif N = "file-tree.expand-to-active-file" then
         Found := True;
         return Command_File_Tree_Expand_To_Active_File;
      elsif N = "buffer.list.show" or else N = "buffer.list.focus"
        or else N = "buffer-list.show" or else N = "buffer-list.focus"
        or else N = "buffer.list.toggle" or else N = "buffer-list.toggle"
        or else N = "buffers.switcher.open" then
         --  canonical open-buffer list names.  Preserve the
         --  historical buffers.switcher.* stable names while allowing the
         --  multi-buffer navigation command surface to use buffer.list.*.
         Found := True;
         return Command_Open_Buffer_Switcher;
      elsif N = "buffer.list.hide" or else N = "buffer-list.hide"
        or else N = "buffers.switcher.close" then
         Found := True;
         return Command_Close_Buffer_Switcher;
      elsif N = "buffer.switch-selected" or else N = "buffer-list.switch-selected"
        or else N = "buffers.switcher.accept" then
         Found := True;
         return Command_Accept_Buffer_Switcher;
      elsif N = "buffer.next" then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.previous" then
         Found := True;
         return Command_Previous_Buffer;
      elsif N = "buffer-list.select-next"
        or else N = "buffer.list.select-next"
        or else N = "buffers.switcher.next"
      then
         Found := True;
         return Command_Buffer_Switcher_Next_Result;
      elsif N = "buffer-list.select-previous"
        or else N = "buffer.list.select-previous"
        or else N = "buffers.switcher.previous"
      then
         Found := True;
         return Command_Buffer_Switcher_Previous_Result;
      elsif N = "edit.find.show" then
         Found := True;
         return Command_Find_Show;
      elsif N = "edit.find.hide" then
         Found := True;
         return Command_Find_Hide;
      elsif N = "edit.find.toggle" then
         Found := True;
         return Command_Find_Toggle;
      elsif N = "edit.find.query.set" then
         Found := True;
         return Command_Find_Query_Set;
      elsif N = "edit.find.query.clear" then
         Found := True;
         return Command_Find_Query_Clear;
      elsif N = "edit.find.case.toggle" then
         Found := True;
         return Command_Find_Case_Toggle;
      elsif N = "edit.find.case.clear" then
         Found := True;
         return Command_Find_Case_Clear;
      elsif N = "edit.find.whole-word.toggle" then
         Found := True;
         return Command_Find_Whole_Word_Toggle;
      elsif N = "edit.find.whole-word.clear" then
         Found := True;
         return Command_Find_Whole_Word_Clear;
      elsif N = "edit.find.from-selection" then
         Found := True;
         return Command_Find_From_Selection;
      elsif N = "edit.find.from-active-word" then
         Found := True;
         return Command_Find_From_Active_Word;
      elsif N = "edit.find.next" then
         Found := True;
         return Command_Active_Find_Next;
      elsif N = "edit.find.previous" then
         Found := True;
         return Command_Active_Find_Previous;
      elsif N = "edit.find.first" then
         Found := True;
         return Command_Find_First;
      elsif N = "edit.find.last" then
         Found := True;
         return Command_Find_Last;
      elsif N = "edit.find.reveal-current" then
         Found := True;
         return Command_Find_Reveal_Current;
      elsif N = "edit.replace.show" then
         Found := True;
         return Command_Replace_Show;
      elsif N = "edit.replace.hide" then
         Found := True;
         return Command_Replace_Hide;
      elsif N = "edit.replace.toggle" then
         Found := True;
         return Command_Replace_Toggle;
      elsif N = "edit.replace.text.set" then
         Found := True;
         return Command_Replace_Text_Set;
      elsif N = "edit.replace.text.clear" then
         Found := True;
         return Command_Replace_Text_Clear;
      elsif N = "edit.replace.current" then
         Found := True;
         return Command_Replace_Current;
      elsif N = "edit.replace.all" then
         Found := True;
         return Command_Replace_All;
      elsif N = "project.search.regex.toggle" then
         Found := True;
         return Command_Project_Search_Regex_Toggle;
      elsif N = "project.search.regex.clear" then
         Found := True;
         return Command_Project_Search_Regex_Clear;
      elsif N = "project.search.include.set" then
         Found := True;
         return Command_Project_Search_Include_Filter_Set;
      elsif N = "project.search.exclude.set" then
         Found := True;
         return Command_Project_Search_Exclude_Filter_Set;
      elsif N = "project.search.run" then
         Found := True;
         return Command_Run_Project_Search;
      elsif N = "project.search.show" then
         Found := True;
         return Command_Open_Project_Search_Bar;
      elsif N = "project.search.toggle" then
         Found := True;
         return Command_Toggle_Project_Search_Bar;
      elsif N = "project.search.hide" then
         Found := True;
         return Command_Close_Project_Search_Bar;
      elsif N = "project.search.query.set" then
         Found := True;
         return Command_Run_Project_Search_From_Bar;
      elsif N = "project.search.from-selection" then
         Found := True;
         return Command_Project_Search_From_Selection;
      elsif N = "project.search.from-active-word" then
         Found := True;
         return Command_Project_Search_From_Active_Word;
      elsif N = "project.search.active-directory" then
         Found := True;
         return Command_Project_Search_Active_Directory;
      elsif N = "project.search.query.clear" then
         Found := True;
         return Command_Clear_Project_Search;
      elsif N = "project.search.open-selected" then
         Found := True;
         return Command_Open_Selected_Project_Search_Result;
      elsif N = "project.search.next" then
         Found := True;
         return Command_Next_Project_Search_Result;
      elsif N = "project.search.previous" then
         Found := True;
         return Command_Previous_Project_Search_Result;
      elsif N = "project.search.first" then
         Found := True;
         return Command_First_Project_Search_Result;
      elsif N = "project.search.last" then
         Found := True;
         return Command_Last_Project_Search_Result;
      elsif N = "project.search.reveal-active-result" then
         Found := True;
         return Command_Reveal_Active_Project_Search_Result;
      elsif N = "project.search.scope.selected-directory" then
         Found := True;
         return Command_Project_Search_Scope_Selected_Directory;
      elsif N = "project.search.kind.next" then
         Found := True;
         return Command_Project_Search_Kind_Next;
      elsif N = "project.search.kind.previous" then
         Found := True;
         return Command_Project_Search_Kind_Previous;
      elsif N = "project.search.kind.clear" then
         Found := True;
         return Command_Project_Search_Kind_Clear;
      elsif N = "project.search.scope.set" then
         Found := True;
         return Command_Project_Search_Scope_Set;
      elsif N = "project.search.scope.clear" then
         Found := True;
         return Command_Project_Search_Scope_Clear;
      elsif N = "project.search.case.toggle" then
         Found := True;
         return Command_Project_Search_Case_Toggle;
      elsif N = "project.search.case.clear" then
         Found := True;
         return Command_Project_Search_Case_Clear;
      elsif N = "project.search.whole-word.toggle" then
         Found := True;
         return Command_Project_Search_Whole_Word_Toggle;
      elsif N = "project.search.whole-word.clear" then
         Found := True;
         return Command_Project_Search_Whole_Word_Clear;
      elsif N = "project.search.include.clear" then
         Found := True;
         return Command_Project_Search_Include_Filter_Clear;
      elsif N = "project.search.exclude.clear" then
         Found := True;
         return Command_Project_Search_Exclude_Filter_Clear;
      elsif N = "project.search.replace.preview" then
         Found := True;
         return Command_Project_Search_Replace_Preview;
      elsif N = "project.search.replace.toggle-selected" then
         Found := True;
         return Command_Project_Search_Replace_Toggle_Selected;
      elsif N = "project.search.replace.include-selected" then
         Found := True;
         return Command_Project_Search_Replace_Include_Selected;
      elsif N = "project.search.replace.exclude-selected" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_Selected;
      elsif N = "project.search.replace.include-file" then
         Found := True;
         return Command_Project_Search_Replace_Include_File;
      elsif N = "project.search.replace.exclude-file" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_File;
      elsif N = "project.search.replace.include-all" then
         Found := True;
         return Command_Project_Search_Replace_Include_All;
      elsif N = "project.search.replace.exclude-all" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_All;
      elsif N = "project.search.replace.selected" then
         Found := True;
         return Command_Project_Search_Replace_Selected;
      elsif N = "project.search.replace.all-included" then
         Found := True;
         return Command_Project_Search_Replace_All_Included;
      elsif N = "project.search.replace.clear-preview" then
         Found := True;
         return Command_Project_Search_Replace_Clear_Preview;
      elsif N = "problems.focus" then
         Found := True;
         return Command_Focus_Problems;
      elsif N = "problems.selection.previous" then
         Found := True;
         return Command_Problems_Move_Up;
      elsif N = "problems.selection.next" then
         Found := True;
         return Command_Problems_Move_Down;
      elsif N = "problems.page-up" then
         Found := True;
         return Command_Problems_Page_Up;
      elsif N = "problems.page-down" then
         Found := True;
         return Command_Problems_Page_Down;
      elsif N = "problems.open-selected" then
         Found := True;
         return Command_Problems_Open_Selected;
      elsif N = "problems.filter.all" then
         Found := True;
         return Command_Problems_Filter_All;
      elsif N = "problems.filter.errors" then
         Found := True;
         return Command_Problems_Filter_Errors;
      elsif N = "problems.filter.warnings" then
         Found := True;
         return Command_Problems_Filter_Warnings;
      elsif N = "problems.filter.info" then
         Found := True;
         return Command_Problems_Filter_Info;
      elsif N = "problems.filter.hints" then
         Found := True;
         return Command_Problems_Filter_Hints;
      elsif N = "problems.sort.location" then
         Found := True;
         return Command_Problems_Sort_By_Location;
      elsif N = "problems.sort.severity" then
         Found := True;
         return Command_Problems_Sort_By_Severity;
      elsif N = "problems.sort.source" then
         Found := True;
         return Command_Problems_Sort_By_Source;
      elsif N = "problems.group.severity" then
         Found := True;
         return Command_Problems_Group_By_Severity;
      elsif N = "problems.group.source" then
         Found := True;
         return Command_Problems_Group_By_Source;
      elsif N = "problems.focus-editor" then
         Found := True;
         return Command_Problems_Focus_Editor;
      elsif N = "outline.next-symbol" then
         Found := True;
         return Command_Next_Outline_Symbol;
      elsif N = "outline.previous-symbol" then
         Found := True;
         return Command_Previous_Outline_Symbol;
      elsif N = "outline.reveal-current-symbol" then
         Found := True;
         return Command_Reveal_Current_Outline_Symbol;
      elsif N = "outline.filter.focus" or else N = "focus-outline-filter" then
         Found := True;
         return Command_Focus_Outline_Filter;
      elsif N = "outline.filter.clear" or else N = "clear-outline-filter" then
         Found := True;
         return Command_Clear_Outline_Filter;
      elsif N = "outline.filter.toggle" or else N = "toggle-outline-filter" then
         Found := True;
         return Command_Toggle_Outline_Filter;
      elsif N = "outline.filter.history.previous"
        or else N = "outline-filter-history-previous"
      then
         Found := True;
         return Command_Outline_Filter_History_Previous;
      elsif N = "outline.filter.history.next"
        or else N = "outline-filter-history-next"
      then
         Found := True;
         return Command_Outline_Filter_History_Next;
      elsif N = "outline.filter.next-match" then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.filter.previous-match" then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "open-quick-open" or else N = "project.quick-open.show" then
         Found := True;
         return Command_Open_Quick_Open;
      elsif N = "close-quick-open" or else N = "project.quick-open.hide" then
         Found := True;
         return Command_Close_Quick_Open;
      elsif N = "toggle-quick-open" or else N = "project.quick-open.toggle" then
         Found := True;
         return Command_Toggle_Quick_Open;
      elsif N = "accept-quick-open" or else N = "project.quick-open.open-selected" then
         Found := True;
         return Command_Accept_Quick_Open;
      elsif N = "quick-open-next-result" or else N = "project.quick-open.next" then
         Found := True;
         return Command_Quick_Open_Next_Result;
      elsif N = "quick-open-previous-result" or else N = "project.quick-open.previous" then
         Found := True;
         return Command_Quick_Open_Previous_Result;
      elsif N = "quick-open-query-set" or else N = "project.quick-open.query.set" then
         Found := True;
         return Command_Quick_Open_Query_Set;
      elsif N = "quick-open-query-clear" or else N = "project.quick-open.query.clear" then
         Found := True;
         return Command_Quick_Open_Query_Clear;
      elsif N = "quick-open-kind-next" or else N = "project.quick-open.kind.next" then
         Found := True;
         return Command_Quick_Open_Kind_Next;
      elsif N = "quick-open-kind-previous" or else N = "project.quick-open.kind.previous" then
         Found := True;
         return Command_Quick_Open_Kind_Previous;
      elsif N = "quick-open-kind-clear" or else N = "project.quick-open.kind.clear" then
         Found := True;
         return Command_Quick_Open_Kind_Clear;
      elsif N = "quick-open-scope-set" or else N = "project.quick-open.scope.set" then
         Found := True;
         return Command_Quick_Open_Scope_Set;
      elsif N = "quick-open-scope-clear" or else N = "project.quick-open.scope.clear" then
         Found := True;
         return Command_Quick_Open_Scope_Clear;
      elsif N = "quick-open-scope-from-selected" or else N = "project.quick-open.scope.from-selected" then
         Found := True;
         return Command_Quick_Open_Scope_From_Selected;
      elsif N = "quick-open-scope-parent" or else N = "project.quick-open.scope.parent" then
         Found := True;
         return Command_Quick_Open_Scope_Parent;
      elsif N = "quick-open-reveal-active" or else N = "project.quick-open.reveal-active" then
         Found := True;
         return Command_Quick_Open_Reveal_Active;
      elsif N = "quick-open-scope-active-directory"
        or else N = "project.quick-open.scope.active-directory"
      then
         Found := True;
         return Command_Quick_Open_Scope_Active_Directory;
      elsif N = "quick-open-create-from-query"
        or else N = "project.quick-open.create-from-query"
      then
         Found := True;
         return Command_Quick_Open_Create_From_Query;
      elsif N = "quick-open-create-with-parents-from-query"
        or else N = "project.quick-open.create-with-parents-from-query"
      then
         Found := True;
         return Command_Quick_Open_Create_With_Parents_From_Query;
      elsif N = "quick-open-priority-toggle"
        or else N = "project.quick-open.priority.toggle"
      then
         Found := True;
         return Command_Quick_Open_Priority_Toggle;
      elsif N = "quick-open-priority-clear"
        or else N = "project.quick-open.priority.clear"
      then
         Found := True;
         return Command_Quick_Open_Priority_Clear;
      end if;

      for Id in Command_Id loop
         if Is_Bindable_Command (Id) and then Stable_Command_Name (Id) = N then
            Found := True;
            return Id;
         end if;
      end loop;
      Found := False;
      return No_Command;
   end Command_Id_From_Stable_Name;


end Editor.Commands.Name_Metadata;
