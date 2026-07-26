with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Stable_Names;

package body Editor.Commands.Search_Terms is

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
      elsif N = "project.open" then
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
      elsif N = "file.open" then
         Found := True;
         return Command_Open_File;
      elsif N = "file.save" then
         Found := True;
         return Command_Save_File;
      elsif N = "file.save-as"
      then
         Found := True;
         return Command_Save_File_As;
      elsif N = "file-tree.refresh"
      then
         Found := True;
         return Command_Refresh_File_Tree;
      elsif N = "file-tree.open-selected"
      then
         Found := True;
         return Command_File_Tree_Open_Selected;
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
      elsif N = "semantic.workspace-symbols" then
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
      elsif N = "semantic.rename-symbol-preview" then
         Found := True;
         return Command_Rename_Symbol_Preview;
      elsif N = "semantic.rename-symbol-apply" then
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
      elsif N = "outline.select-current-symbol" then
         Found := True;
         return Command_Select_Current_Outline_Symbol;
      elsif N = "outline.select-next" then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.select-previous" then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "buffer.switch-next"
      then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.switch-previous"
      then
         Found := True;
         return Command_Previous_Buffer;
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
      elsif N = "project.test" then
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
      elsif N = "diagnostics.show" then
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
      elsif N = "diagnostics.execute-selected-action" then
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
      elsif N = "navigation.goto-line.show" then
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
      elsif N = "selection.select-all" then
         Found := True;
         return Command_Select_All;
      elsif N = "selection.clear" then
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
      elsif N = "edit.format-buffer" then
         Found := True;
         return Command_Format_Buffer;
      elsif N = "edit.format.selection" then
         Found := True;
         return Command_Format_Selected_Text;
      elsif N = "file.format-on-save" then
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
      elsif N = "file.reload-buffer" then
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
      elsif N = "file.close-buffer" then
         Found := True;
         return Command_Close_Active_Buffer;
      elsif N = "file.close-all-buffers" then
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
      elsif N = "file.close-other-buffers" then
         Found := True;
         return Command_Close_Other_Buffers;
      elsif N = "file.close-clean-buffers" then
         Found := True;
         return Command_Close_All_Clean_Buffers;
      elsif N = "file.reopen-closed-buffer" then
         Found := True;
         return Command_Reopen_Closed_Buffer;
      elsif N = "buffers.switcher.selected.close" then
         Found := True;
         return Command_Buffer_Switcher_Selected_Close;
      elsif N = "lifecycle.pending.discard" then
         Found := True;
         return Command_Discard_Pending_Transition;
      elsif N = "file-tree.reveal-active-file" then
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
      elsif N = "buffers.switcher.open" then
         Found := True;
         return Command_Open_Buffer_Switcher;
      elsif N = "buffers.switcher.close" then
         Found := True;
         return Command_Close_Buffer_Switcher;
      elsif N = "buffers.switcher.accept" then
         Found := True;
         return Command_Accept_Buffer_Switcher;
      elsif N = "buffer.next" then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.previous" then
         Found := True;
         return Command_Previous_Buffer;
      elsif N = "buffers.switcher.next" then
         Found := True;
         return Command_Buffer_Switcher_Next_Result;
      elsif N = "buffers.switcher.previous" then
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
      elsif N = "outline.filter.focus" then
         Found := True;
         return Command_Focus_Outline_Filter;
      elsif N = "outline.filter.clear" then
         Found := True;
         return Command_Clear_Outline_Filter;
      elsif N = "outline.filter.toggle" then
         Found := True;
         return Command_Toggle_Outline_Filter;
      elsif N = "outline.filter.history.previous" then
         Found := True;
         return Command_Outline_Filter_History_Previous;
      elsif N = "outline.filter.history.next" then
         Found := True;
         return Command_Outline_Filter_History_Next;
      elsif N = "outline.filter.next-match" then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.filter.previous-match" then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "quick-open.show" then
         Found := True;
         return Command_Open_Quick_Open;
      elsif N = "project.quick-open.hide" then
         Found := True;
         return Command_Close_Quick_Open;
      elsif N = "project.quick-open.toggle" then
         Found := True;
         return Command_Toggle_Quick_Open;
      elsif N = "quick-open.open-selected" then
         Found := True;
         return Command_Accept_Quick_Open;
      elsif N = "project.quick-open.next" then
         Found := True;
         return Command_Quick_Open_Next_Result;
      elsif N = "project.quick-open.previous" then
         Found := True;
         return Command_Quick_Open_Previous_Result;
      elsif N = "project.quick-open.query.set" then
         Found := True;
         return Command_Quick_Open_Query_Set;
      elsif N = "project.quick-open.query.clear" then
         Found := True;
         return Command_Quick_Open_Query_Clear;
      elsif N = "project.quick-open.kind.next" then
         Found := True;
         return Command_Quick_Open_Kind_Next;
      elsif N = "project.quick-open.kind.previous" then
         Found := True;
         return Command_Quick_Open_Kind_Previous;
      elsif N = "project.quick-open.kind.clear" then
         Found := True;
         return Command_Quick_Open_Kind_Clear;
      elsif N = "project.quick-open.scope.set" then
         Found := True;
         return Command_Quick_Open_Scope_Set;
      elsif N = "project.quick-open.scope.clear" then
         Found := True;
         return Command_Quick_Open_Scope_Clear;
      elsif N = "project.quick-open.scope.from-selected" then
         Found := True;
         return Command_Quick_Open_Scope_From_Selected;
      elsif N = "project.quick-open.scope.parent" then
         Found := True;
         return Command_Quick_Open_Scope_Parent;
      elsif N = "project.quick-open.reveal-active" then
         Found := True;
         return Command_Quick_Open_Reveal_Active;
      elsif N = "project.quick-open.scope.active-directory" then
         Found := True;
         return Command_Quick_Open_Scope_Active_Directory;
      elsif N = "project.quick-open.create-from-query" then
         Found := True;
         return Command_Quick_Open_Create_From_Query;
      elsif N = "project.quick-open.create-with-parents-from-query" then
         Found := True;
         return Command_Quick_Open_Create_With_Parents_From_Query;
      elsif N = "project.quick-open.priority.toggle" then
         Found := True;
         return Command_Quick_Open_Priority_Toggle;
      elsif N = "project.quick-open.priority.clear" then
         Found := True;
         return Command_Quick_Open_Priority_Clear;
      end if;

      for Id in Command_Id loop
         if Is_Bindable_Command (Id) and then Editor.Commands.Stable_Names.Stable_Command_Name (Id) = N then
            Found := True;
            return Id;
         end if;
      end loop;
      Found := False;
      return No_Command;
   end Command_Id_From_Stable_Name;


end Editor.Commands.Search_Terms;
