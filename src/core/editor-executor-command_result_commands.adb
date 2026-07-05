with Text_Buffer;
with Editor.State;
use type Editor.State.Dirty_Close_Scope;
use type Editor.State.Semantic_Popup_Kind;
with Editor.Cursors;    use Editor.Cursors;
with Editor.Commands;   use Editor.Commands;
with Editor.History;    use Editor.History;
with Ada.Containers;    use Ada.Containers;

with Editor.Invariants;
with Editor.Navigation; use Editor.Navigation;
with Editor.Executor.History;
with Editor.Executor.Structural;
with Editor.Executor.Navigation;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Availability;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.Shared_Services;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Message_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Executor.Buffer_Metadata_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Feature_Panel_Commands;
with Editor.Executor.Editor_Preferences_Commands;
with Editor.Executor.Editing_Commands;
with Editor.Executor.Terminal_Commands;
with Editor.Executor.Build_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Overlay_Commands;
with Editor.Executor.Semantic_Commands;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Buffer_Switcher_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Preview_Commands;
with Editor.Executor.Buffer_Switcher_Selected_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Executor.Configuration_Commands;
with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Selection_Commands;
with Editor.Executor.Edits;
with Editor.Executor.Rectangular;
with Editor.Executor.Clipboard;
with Editor.Rectangle_Selection;
with Editor.UTF8;
with Editor.Unicode;
with Editor.Files;
use type Editor.Files.File_Rename_Status;
use type Editor.Files.File_Copy_Status;
use type Editor.Files.File_Move_Status;
use type Editor.Files.File_Open_Status;
with Editor.Search;
use type Editor.Search.Search_Match_Index;
with Editor.Messages;
with Editor.Clipboard;
with Editor.Project;
use type Editor.Project.Project_File_Refresh_Status;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.View;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
use type Editor.Buffers.Buffer_Ownership_Kind;
with Editor.Panels;
with Editor.Render_Cache;
with Editor.Dirty_Lines;
with Editor.Diagnostics;
with Editor.Layout;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Selection;
use type Editor.Selection.Selection_Validation_Status;
with Editor.Input_Field;
with Editor.Quick_Open;
with Editor.Quick_Open_Markers;
use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
use type Editor.Quick_Open.Quick_Open_Priority_Mode;
with Editor.Buffer_Switcher;
use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
with Editor.Go_To_Line;
with Editor.Project_Search;
use type Editor.Project_Search.Project_Search_Result_Id;
use type Editor.Project_Search.Project_Replace_Preview_Status;
with Editor.Bookmarks;
with Editor.Build_Command;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Project_Search_Bar;
use type Editor.Project_Search.Project_Search_File_Kind_Filter;
use type Editor.Project_Search_Bar.Project_Search_Bar_Field;
with Editor.Search_Results;
with Editor.Problems;
with Editor.Panel_Focus;
with Editor.Overlay_Focus;
with Editor.Command_Palette;
with Editor.Keybindings;
use type Editor.Keybindings.Keybinding_Validation_Status;
with Editor.Settings;
with Editor.Theme;
with Editor.Settings_Management;
with Editor.Configuration_Recovery;
with Editor.Startup_Readiness;
use type Editor.Settings_Management.Setting_Update_Status;
with Editor.Keybinding_Config;
with Editor.Keybinding_Management;
use type Editor.Keybinding_Management.Keybinding_Action_Status;
use type Editor.Keybinding_Management.Keybinding_Capture_State;
with Editor.Line_Numbers;
with Editor.Cursor;
with Editor.Minimap;
with Editor.Scrollbars;
with Editor.Workspace_Persistence;
with Editor.Recent_Projects;
with Editor.Dirty_Guards;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Editor.Command_Execution;
use type Editor.Command_Execution.Command_Execution_Status;
with Editor.External_Producers;
use type Editor.External_Producers.Build_Run_Status;
use type Editor.External_Producers.Process_Run_Status;
with Editor.Build_UI;
use type Editor.Build_UI.Public_Build_Tool_Selection;
use type Editor.Build_UI.Build_Candidate_Refresh_Status;
with Editor.Terminal_Tasks;
with Editor.Build_Candidates;
with Editor.Build_UI_Actions;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Working_Context;
with Editor.Build_Public_Request;
with Editor.Guided_Prompts;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Messages;
with Editor.Feature_Search_Results;
use type Editor.Feature_Search_Results.External_Result_Set_Kind;
with Editor.Feature_Diagnostics;
use type Editor.Feature_Diagnostics.Diagnostic_Id;
with Editor.Navigation_History;
with Editor.Recent_Buffers;
with Editor.Message_Producers;
with Editor.Outline;
use type Editor.Outline.Outline_Item_Kind;
use type Editor.Outline.Outline_Freshness;
with Editor.Outline_Extractor;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
use type Editor.Ada_Language_Service.Service_Status;
with Editor.Ada_Live_Semantic_Diagnostics;
with Editor.Ada_Diagnostic_Action_Execution;
use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Effect;
use type Editor.Ada_Diagnostic_Action_Execution.Diagnostic_Action_Execution_Status;
with Editor.Ada_Diagnostic_Command_Projection;
use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
with Editor.Ada_Project_Index;
with Editor.Syntax_Semantics;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Characters.Handling;
with Ada.Strings.Fixed;
with Ada.Strings;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.Text_IO;
with Ada.IO_Exceptions;

with Editor.Executor;
use Editor.Executor;
use type Editor.Messages.Message_Severity;

package body Editor.Executor.Command_Result_Commands is

   function Is_Terminal_Task_Command
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Id in Editor.Commands.Command_Terminal_Toggle
        .. Editor.Commands.Command_Terminal_Cancel_Task;
   end Is_Terminal_Task_Command;

   function Execute_Command_With_Result
     (S     : in out Editor.State.State_Type;
      Id    : Editor.Commands.Command_Id;
      Shift : Boolean := False) return Command_Execution_Result
   is
      Availability : Editor.Commands.Command_Availability;
      Cmd          : Editor.Commands.Command;
      Before_Messages : Natural := 0;
      Before_Caret    : Editor.Cursors.Cursor_Index := 0;
      Before_Anchor   : Editor.Cursors.Cursor_Index := 0;
      Before_Length   : Natural := 0;
      Before_Buffer   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_File_Tree_Row : Natural := 0;

      function Is_Boundary_Navigation_Command
        (Command : Editor.Commands.Command_Id) return Boolean
      is
      begin
         case Command is
            when Editor.Commands.Command_Move_Left
               | Editor.Commands.Command_Move_Right
               | Editor.Commands.Command_Move_Up
               | Editor.Commands.Command_Move_Down
               | Editor.Commands.Command_Move_Line_Start
               | Editor.Commands.Command_Move_Line_End
               | Editor.Commands.Command_Move_Document_Start
               | Editor.Commands.Command_Move_Document_End
               | Editor.Commands.Command_Move_Word_Left
               | Editor.Commands.Command_Move_Word_Right
               | Editor.Commands.Command_Page_Up
               | Editor.Commands.Command_Page_Down
               | Editor.Commands.Command_Goto_Start
               | Editor.Commands.Command_Goto_End =>
               return True;
            when others =>
               return False;
         end case;
      end Is_Boundary_Navigation_Command;

      function Navigation_State_Unchanged return Boolean
      is
      begin
         return Before_Caret = Safe_Caret (S)
           and then Before_Anchor = Safe_Anchor (S)
           and then Before_Length = Buffer_Length (S);
      end Navigation_State_Unchanged;

      function Is_Buffer_Switch_Command
        (Command : Editor.Commands.Command_Id) return Boolean
      is
      begin
         return Command = Editor.Commands.Command_Next_Buffer
           or else Command = Editor.Commands.Command_Previous_Buffer
           or else Command = Editor.Commands.Command_Previous_Recent_Buffer
           or else Command = Editor.Commands.Command_Next_Recent_Buffer;
      end Is_Buffer_Switch_Command;

      function Is_Ordinary_Buffer_Switch_Command
        (Command : Editor.Commands.Command_Id) return Boolean
      is
      begin
         return Command = Editor.Commands.Command_Next_Buffer
           or else Command = Editor.Commands.Command_Previous_Buffer;
      end Is_Ordinary_Buffer_Switch_Command;

      function Buffer_Is_Clean_Empty_Untitled
        (Id : Editor.Buffers.Buffer_Id) return Boolean
      is
         Summary : constant Editor.Buffers.Buffer_Summary :=
           Editor.Buffers.Global_Summary_For (Id);
      begin
         return not Summary.Has_Path
           and then not Summary.Is_Dirty
           and then Editor.State.Current_Text
             (Editor.Buffers.Buffer
                (Editor.Buffers.Global_Registry_For_UI, Id)) = "";
      end Buffer_Is_Clean_Empty_Untitled;

      function Scratch_Only_Buffer_Cycle
        (Before : Editor.Buffers.Buffer_Id) return Boolean
      is
         After : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Global_Active_Buffer;
      begin
         if Before = Editor.Buffers.No_Buffer
           or else After = Editor.Buffers.No_Buffer
           or else Before = After
           or else Editor.Buffers.Global_Count /= 2
           or else not Editor.Buffers.Global_Contains (Before)
           or else not Editor.Buffers.Global_Contains (After)
         then
            return False;
         end if;

         return Buffer_Is_Clean_Empty_Untitled (Before)
           and then Buffer_Is_Clean_Empty_Untitled (After);
      end Scratch_Only_Buffer_Cycle;

      function Is_File_Tree_Navigation_Command
        (Command : Editor.Commands.Command_Id) return Boolean
      is
      begin
         case Command is
            when Editor.Commands.Command_File_Tree_Move_Up
               | Editor.Commands.Command_File_Tree_Move_Down
               | Editor.Commands.Command_File_Tree_Page_Up
               | Editor.Commands.Command_File_Tree_Page_Down =>
               return True;
            when others =>
               return False;
         end case;
      end Is_File_Tree_Navigation_Command;

      function Result_After_Command
        (Command : Editor.Commands.Command_Id) return Command_Execution_Result
      is
         Found : Boolean := False;
         Msg   : Editor.Messages.Editor_Message;
      begin
         if Editor.Messages.Count (S.Messages) > Before_Messages then
            Msg := Editor.Messages.Active_Message (S.Messages, Found);
            if Found then
               if Editor.Messages.Severity (Msg) =
                 Editor.Messages.Error_Message
               then
                  return Editor.Command_Execution.Failed (Command);
               elsif Editor.Messages.Severity (Msg) =
                 Editor.Messages.Warning_Message
               then
                  case Command is
                     when Editor.Commands.Command_Reload_Settings
                        | Editor.Commands.Command_Reload_Keybindings
                        | Editor.Commands.Command_Validate_Keybindings =>
                        return Editor.Command_Execution.Executed (Command);
                     when others =>
                        return Editor.Command_Execution.Unavailable (Command);
                  end case;
               end if;
            end if;
         end if;

         return Editor.Command_Execution.Executed (Command);
      end Result_After_Command;

   begin
      if Id = Editor.Commands.No_Command then
         return Editor.Command_Execution.No_Op (Id);
      end if;

      if Id /= Editor.Commands.Command_Restore_Workspace_State
        and then Id /= Editor.Commands.Command_Reload_Active_Buffer
      then
         Clear_Restore_Feedback_Current (S);
      end if;

      if Id /= Editor.Commands.Command_Build_Run
        and then Id /= Editor.Commands.Command_Build_Cancel
        and then Editor.Build_Command.Has_Queued_Public_Build_Job (S)
      then
         declare
            Build_Result : Editor.External_Producers.Build_Command_Result;
            Completed    : constant Boolean :=
              Editor.Build_Command.Poll_Public_Build_Run_Completion
                (S, Build_Result);
         begin
            if Completed then
               Editor.Executor.Shared_Services.Report_Info (S, To_String (Build_Result.Command_Message));
               Editor.Render_Cache.Invalidate_All;
            end if;
         end;
      end if;

      if (Id = Editor.Commands.Command_Next_Buffer
          or else Id = Editor.Commands.Command_Previous_Buffer)
        and then Editor.Buffers.Global_Count = 1
      then
         if Id = Editor.Commands.Command_Next_Buffer then
            Editor.Executor.Buffer_Navigation_Commands.Execute_Next_Buffer (S);
         else
            Editor.Executor.Buffer_Navigation_Commands.Execute_Previous_Buffer (S);
         end if;
         return Editor.Command_Execution.No_Op (Id);
      end if;

      if Is_Terminal_Task_Command (Id) then
         Editor.Executor.Terminal_Commands.Ensure_Terminal_Project_Tasks (S);
      end if;

      Availability := Command_Availability (S, Id);
      if not Editor.Commands.Is_Available (Availability) then
         declare
            Reason : constant String := Editor.Commands.Unavailable_Reason (Availability);
            Allow_Stale_Close_Cleanup : constant Boolean :=
              S.Dirty_Close_Prompt_Active
              and then
                (Id = Editor.Commands.Command_Confirm_Close_Save
                 or else Id = Editor.Commands.Command_Confirm_Close_Discard)
              and then
                (Reason = "Selected buffer is no longer open"
                 or else Reason = Editor.Commands.Reason_Close_Review_Stale);
         begin
            if not Allow_Stale_Close_Cleanup then
               if Id = Editor.Commands.Command_Build_Run
                 and then Editor.Build_Result_Summary.Retain_Pre_Run_Unavailable_Summary
               then
                  S.Latest_Build_Result :=
                    Editor.Build_Result_Summary.Replace_Latest_Build_Result_Summary
                      (S.Latest_Build_Result,
                       Editor.Build_Result_Summary.Summary_From_Unavailable_Message
                         (Reason));
                  S.Latest_Build_Output_Details :=
                    Editor.Build_Output_Details.Replace_Latest_Build_Output_Details
                      (S.Latest_Build_Output_Details,
                       Editor.Build_Output_Details.Build_Unavailable_Output_Details
                         (Reason));
               end if;
               if Id = Editor.Commands.Command_Diagnostics_Filter_Build
                 and then Reason = "No build diagnostics"
               then
                  Editor.Executor.Shared_Services.Report_Info (S, Editor.Feature_Diagnostics.Message_No_Build_Diagnostics);
               elsif (Id = Editor.Commands.Command_Diagnostics_Select_Next
                      or else Id = Editor.Commands.Command_Diagnostics_Select_Previous)
                 and then Reason = "No visible diagnostics"
               then
                  Editor.Executor.Shared_Services.Report_Info (S, Editor.Feature_Diagnostics.Message_No_Visible_Diagnostic);
               elsif Id = Editor.Commands.Command_Focus_Outline
                 and then Reason =
                   Editor.Outline.Reason_Feature_Panel_Already_Focused
               then
                  Editor.Executor.Shared_Services.Report_Info (S, Editor.Outline.Message_Outline_Focused);
               elsif Reason =
                 "Command unavailable while confirmation is pending."
               then
                  Editor.Executor.Shared_Services.Report_Warning (S, Reason);
               else
                  Editor.Executor.Shared_Services.Report_Info (S, Reason);
               end if;
               if Id = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix then
                  Editor.State.Clear_Quick_Fix_Workflow (S);
               end if;
               Editor.Render_Cache.Invalidate_All;
               return Editor.Command_Execution.Unavailable (Id);
            end if;
         end;
      end if;

      if Editor.Executor.File_Target_Prompt_Commands
        .Command_Requires_File_Target_Prompt (Id)
      then
         Editor.Executor.File_Target_Prompt_Commands.Open_File_Target_Prompt (S, Id);
         return Editor.Command_Execution.Executed (Id);
      end if;

      Before_Messages := Editor.Messages.Count (S.Messages);

      case Id is
         when Editor.Commands.Command_Palette_Show_Command_Help
            | Editor.Commands.Command_Cancel =>
            return Editor.Executor.Command_Surface_Commands
              .Execute_Command_Surface_Result_Command (S, Id);

         when Editor.Commands.Command_Run_Project
            | Editor.Commands.Command_Run_Tests =>
            return Editor.Executor.Terminal_Commands
              .Execute_Project_Task_Command (S, Id);

         when Editor.Commands.Command_Terminal_Toggle
            | Editor.Commands.Command_Terminal_Show
            | Editor.Commands.Command_Terminal_Hide
            | Editor.Commands.Command_Terminal_Focus
            | Editor.Commands.Command_Terminal_Clear
            | Editor.Commands.Command_Terminal_Clear_Output
            | Editor.Commands.Command_Terminal_Select_Next_Task
            | Editor.Commands.Command_Terminal_Select_Previous_Task
            | Editor.Commands.Command_Terminal_Run_Selected_Task
            | Editor.Commands.Command_Terminal_Rerun_Last_Task
            | Editor.Commands.Command_Terminal_Cancel_Task =>
            return Editor.Executor.Terminal_Commands.Execute_Terminal_Command
              (S, Id);

         when Editor.Commands.Command_Build_UI_Toggle
            | Editor.Commands.Command_Build_UI_Show
            | Editor.Commands.Command_Build_UI_Hide
            | Editor.Commands.Command_Build_UI_Focus
            | Editor.Commands.Command_Build_Result_Focus
            | Editor.Commands.Command_Build_Output_Details_Focus =>
            return Editor.Executor.Panel_Focus_Commands
              .Execute_Panel_Focus_Command (S, Id);

         when Editor.Commands.Command_Build_Refresh_Candidates
            | Editor.Commands.Command_Build_Select_First_Candidate
            | Editor.Commands.Command_Build_Select_Next_Candidate
            | Editor.Commands.Command_Build_Select_Previous_Candidate
            | Editor.Commands.Command_Build_Clear_Selected_Candidate
            | Editor.Commands.Command_Build_Set_Mode_Default
            | Editor.Commands.Command_Build_Set_Mode_Debug
            | Editor.Commands.Command_Build_Set_Mode_Release
            | Editor.Commands.Command_Build_Set_Mode_Validation
            | Editor.Commands.Command_Build_Toggle_Diagnostics_Ingestion
            | Editor.Commands.Command_Build_Cycle_Output_Limit
            | Editor.Commands.Command_Build_Toggle_Option_Verbose
            | Editor.Commands.Command_Build_Toggle_Option_Keep_Going
            | Editor.Commands.Command_Build_Acknowledge_Consent
            | Editor.Commands.Command_Build_Clear_Consent
            | Editor.Commands.Command_Build_Run
            | Editor.Commands.Command_Build_Cancel
            | Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam
            | Editor.Commands.Command_Build_Output_Details_Select_Stdout
            | Editor.Commands.Command_Build_Output_Details_Select_Stderr
            | Editor.Commands.Command_Build_Output_Details_Select_Merged =>
            return Editor.Executor.Build_Commands.Execute_Build_Command (S, Id);

         when Editor.Commands.Command_Undo
            | Editor.Commands.Command_Redo
            | Editor.Commands.Command_Edit_History_Clear
            | Editor.Commands.Command_Copy
            | Editor.Commands.Command_Cut
            | Editor.Commands.Command_Paste
            | Editor.Commands.Command_Clipboard_Clear =>
            return Editor.Executor.Editing_Commands.Execute_Editing_Command
              (S, Id, Shift);

         when Editor.Commands.Command_Select_All
            | Editor.Commands.Command_Selection_Clear
            | Editor.Commands.Command_Select_Word =>
            return Editor.Executor.Selection_Commands
              .Execute_Selection_Result_Command (S, Id);

         when Editor.Commands.Command_Line_Delete
            | Editor.Commands.Command_Line_Duplicate
            | Editor.Commands.Command_Line_Move_Up
            | Editor.Commands.Command_Line_Move_Down
            | Editor.Commands.Command_Indent_Increase
            | Editor.Commands.Command_Indent_Decrease
            | Editor.Commands.Command_Comment_Line
            | Editor.Commands.Command_Uncomment_Line
            | Editor.Commands.Command_Toggle_Line_Comment
            | Editor.Commands.Command_Line_Join_Next
            | Editor.Commands.Command_Line_Split_At_Caret
            | Editor.Commands.Command_Trim_Trailing_Whitespace
            | Editor.Commands.Command_Format_Buffer
            | Editor.Commands.Command_Format_Selected_Text
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next
            | Editor.Commands.Command_Selection_Delete =>
            return Editor.Executor.Editing_Commands.Execute_Editing_Command
              (S, Id, Shift);

         when Editor.Commands.Command_Show_Recent_Projects
            | Editor.Commands.Command_Clear_Recent_Projects
            | Editor.Commands.Command_Open_Selected_Recent_Project
            | Editor.Commands.Command_Remove_Selected_Recent_Project
            | Editor.Commands.Command_Remove_Missing_Recent_Projects
            | Editor.Commands.Command_Select_Next_Recent_Project
            | Editor.Commands.Command_Select_Previous_Recent_Project =>
            return Editor.Executor.Project_Lifecycle_Commands
              .Execute_Project_Lifecycle_Result_Command (S, Id);

         when Editor.Commands.Command_Refresh_Project_Files
            | Editor.Commands.Command_Project_Files_Summary
            | Editor.Commands.Command_Reveal_Active_File_In_Tree =>
            return Editor.Executor.File_Tree_Commands
              .Execute_File_Tree_Result_Command (S, Id);

         when Editor.Commands.Command_Save_All
            | Editor.Commands.Command_File_Conflict_Keep_Buffer
            | Editor.Commands.Command_File_Conflict_Reload_From_Disk
            | Editor.Commands.Command_File_Conflict_Overwrite_Disk
            | Editor.Commands.Command_File_Conflict_Cancel
            | Editor.Commands.Command_Close_Other_Buffers
            | Editor.Commands.Command_Close_All_Buffers
            | Editor.Commands.Command_Confirm_Close_Save
            | Editor.Commands.Command_Confirm_Close_Discard
            | Editor.Commands.Command_Cancel_Close
            | Editor.Commands.Command_Close_All_Clean_Buffers =>
            return Editor.Executor.File_Lifecycle_Commands
              .Execute_Lifecycle_Result_Command (S, Id);


         when Editor.Commands.Command_Pin_Buffer
            | Editor.Commands.Command_Unpin_Buffer
            | Editor.Commands.Command_Toggle_Buffer_Pin
            | Editor.Commands.Command_Set_Buffer_Label
            | Editor.Commands.Command_Edit_Buffer_Label
            | Editor.Commands.Command_Clear_Buffer_Label
            | Editor.Commands.Command_Show_Buffer_Label
            | Editor.Commands.Command_Set_Buffer_Note
            | Editor.Commands.Command_Edit_Buffer_Note
            | Editor.Commands.Command_Clear_Buffer_Note
            | Editor.Commands.Command_Show_Buffer_Note
            | Editor.Commands.Command_Assign_Buffer_Group
            | Editor.Commands.Command_Clear_Buffer_Group
            | Editor.Commands.Command_Switch_Buffer_Group
            | Editor.Commands.Command_Next_Buffer_Group
            | Editor.Commands.Command_Previous_Buffer_Group
            | Editor.Commands.Command_Show_All_Buffer_Groups =>
            return Editor.Executor.Buffer_Metadata_Commands
              .Execute_Buffer_Metadata_Result_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Selected_Close
            | Editor.Commands.Command_Buffer_Switcher_Selected_Pin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Unpin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Toggle_Pin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign
            | Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear
            | Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set
            | Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear
            | Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set
            | Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear =>
            return Editor.Executor.Buffer_Switcher_Selected_Commands
              .Execute_Buffer_Switcher_Selected_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Preview_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Preview_Show
            | Editor.Commands.Command_Buffer_Switcher_Preview_Hide
            | Editor.Commands.Command_Buffer_Switcher_Preview_Next_Line
            | Editor.Commands.Command_Buffer_Switcher_Preview_Previous_Line
            | Editor.Commands.Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Editor.Executor.Buffer_Switcher_Preview_Commands
              .Execute_Buffer_Switcher_Preview_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Mark_Toggle =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Execute_Buffer_Switcher_Mark_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Mark_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear_All
            | Editor.Commands.Command_Buffer_Switcher_Mark_Invert_Visible
            | Editor.Commands.Command_Buffer_Switcher_Mark_Visible
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Visible
            | Editor.Commands.Command_Buffer_Switcher_Mark_Pinned
            | Editor.Commands.Command_Buffer_Switcher_Mark_Group
            | Editor.Commands.Command_Buffer_Switcher_Mark_Label
            | Editor.Commands.Command_Buffer_Switcher_Mark_Noted
            | Editor.Commands.Command_Buffer_Switcher_Mark_Close_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Pin_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Unpin_Marked
            | Editor.Commands.Command_Buffer_Switcher_Mark_Clear_Metadata
            | Editor.Commands.Command_Buffer_Switcher_Mark_Group_Assign
            | Editor.Commands.Command_Buffer_Switcher_Mark_Group_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Label_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Label_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Note_Set
            | Editor.Commands.Command_Buffer_Switcher_Mark_Note_Clear
            | Editor.Commands.Command_Buffer_Switcher_Mark_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Mark_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Mark_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Mark_Next
            | Editor.Commands.Command_Buffer_Switcher_Mark_Previous
            | Editor.Commands.Command_Buffer_Switcher_Mark_Summary
            | Editor.Commands.Command_Buffer_Switcher_Mark_Confirm
            | Editor.Commands.Command_Buffer_Switcher_Mark_Cancel =>
            return Editor.Executor.Buffer_Switcher_Mark_Commands
              .Execute_Buffer_Switcher_Mark_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            return Editor.Executor.Buffer_Switcher_Pending_Mark_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Command (S, Id);

         when Editor.Commands.Command_Reopen_Closed_Buffer
            | Editor.Commands.Command_Cancel_Pending_Transition
            | Editor.Commands.Command_Retry_Pending_Transition
            | Editor.Commands.Command_Discard_Pending_Transition =>
            return Editor.Executor.File_Lifecycle_Commands
              .Execute_Lifecycle_Result_Command (S, Id);

         when Editor.Commands.Command_Save_Settings
            | Editor.Commands.Command_Reload_Settings
            | Editor.Commands.Command_Reset_Settings_To_Defaults
            | Editor.Commands.Command_Save_Keybindings
            | Editor.Commands.Command_Reload_Keybindings
            | Editor.Commands.Command_Validate_Keybindings
            | Editor.Commands.Command_Startup_Show_Summary
            | Editor.Commands.Command_Configuration_Recover_Show
            | Editor.Commands.Command_Configuration_Audit
            | Editor.Commands.Command_Configuration_Reset_Settings
            | Editor.Commands.Command_Configuration_Reset_Keybindings
            | Editor.Commands.Command_Configuration_Reset_Workspace
            | Editor.Commands.Command_Configuration_Reset_Recent_Projects
            | Editor.Commands.Command_Configuration_Reset_All
            | Editor.Commands.Command_Configuration_Reset_All_Confirm
            | Editor.Commands.Command_Configuration_Reset_All_Cancel
            | Editor.Commands.Command_Configuration_Save_Clean_Settings
            | Editor.Commands.Command_Configuration_Save_Clean_Keybindings
            | Editor.Commands.Command_Configuration_Save_Clean_Workspace
            | Editor.Commands.Command_Configuration_Save_Clean_Recent_Projects
            | Editor.Commands.Command_Keybindings_Show
              .. Editor.Commands.Command_Keybindings_Cancel_Capture =>
            return Editor.Executor.Configuration_Commands
              .Execute_Configuration_Result_Command (S, Id);

         when Editor.Commands.Command_Save_Workspace_State
            | Editor.Commands.Command_Restore_Workspace_State
            | Editor.Commands.Command_Clear_Workspace_State =>
            return Editor.Executor.Workspace_Commands
              .Execute_Workspace_Result_Command (S, Id);

         when Editor.Commands.Command_Toggle_Feature_Panel
            | Editor.Commands.Command_Show_Feature_Panel
            | Editor.Commands.Command_Hide_Feature_Panel
            | Editor.Commands.Command_Focus_Feature_Panel
            | Editor.Commands.Command_Clear_Feature_Panel
            | Editor.Commands.Command_Feature_Panel_Select_Next
            | Editor.Commands.Command_Feature_Panel_Select_Previous
            | Editor.Commands.Command_Feature_Panel_Open_Selected =>
            return Editor.Executor.Feature_Panel_Commands
              .Execute_Feature_Panel_Command (S, Id);

         when Editor.Commands.Command_Refresh_Outline
            | Editor.Commands.Command_Refresh_Outline_Project_Index
            | Editor.Commands.Command_Clear_Outline
            | Editor.Commands.Command_Show_Outline
            | Editor.Commands.Command_Focus_Outline
            | Editor.Commands.Command_Open_Selected_Outline_Item
            | Editor.Commands.Command_Next_Outline_Symbol
            | Editor.Commands.Command_Previous_Outline_Symbol
            | Editor.Commands.Command_Reveal_Current_Outline_Symbol
            | Editor.Commands.Command_Select_Current_Outline_Symbol
            | Editor.Commands.Command_Select_Next_Outline_Item
            | Editor.Commands.Command_Select_Previous_Outline_Item
            | Editor.Commands.Command_Focus_Outline_Filter
            | Editor.Commands.Command_Filter_Outline
            | Editor.Commands.Command_Clear_Outline_Filter
            | Editor.Commands.Command_Toggle_Outline_Filter
            | Editor.Commands.Command_Outline_Filter_History_Previous
            | Editor.Commands.Command_Outline_Filter_History_Next
            | Editor.Commands.Command_Clear_Outline_Filter_History =>
            return Editor.Executor.Outline_Commands.Execute_Outline_Command
              (S, Id, Cmd);

         when Editor.Commands.Command_Semantic_Refresh_Buffer
            | Editor.Commands.Command_Semantic_Refresh_Project_Index
            | Editor.Commands.Command_Language_Index_Clear
            | Editor.Commands.Command_Language_Index_Status
            | Editor.Commands.Command_Goto_Declaration
            | Editor.Commands.Command_Goto_Body
            | Editor.Commands.Command_Goto_Spec
            | Editor.Commands.Command_Find_References
            | Editor.Commands.Command_Workspace_Symbols
            | Editor.Commands.Command_Show_Hover
            | Editor.Commands.Command_Show_Completions
            | Editor.Commands.Command_Rename_Symbol_Preview
            | Editor.Commands.Command_Rename_Symbol_Apply
            | Editor.Commands.Command_Semantic_Completion_Select_Next
            | Editor.Commands.Command_Semantic_Completion_Select_Previous
            | Editor.Commands.Command_Semantic_Completion_Accept
            | Editor.Commands.Command_Semantic_Popup_Dismiss =>
            return Editor.Executor.Semantic_Commands.Execute_Semantic_Command
              (S, Id, Cmd);

         when Editor.Commands.Command_Show_Messages
            | Editor.Commands.Command_Clear_Messages =>
            return Editor.Executor.Message_Commands.Execute_Message_Command
              (S, Id);

         when Editor.Commands.Command_Search_Results_Search_Active_Buffer
            | Editor.Commands.Command_Search_Results_Focus_Query
            | Editor.Commands.Command_Search_Results_Repeat_Active_Buffer
            | Editor.Commands.Command_Search_Results_Query_History_Previous
            | Editor.Commands.Command_Search_Results_Query_History_Next
            | Editor.Commands.Command_Search_Results_Toggle_Case_Sensitive
            | Editor.Commands.Command_Show_Search_Results_Feature
            | Editor.Commands.Command_Clear_Search_Results_Feature =>
            return Editor.Executor.Search_Results_Commands
              .Execute_Search_Results_Command (S, Id);

         when Editor.Commands.Command_Diagnostics_Show
            | Editor.Commands.Command_Diagnostics_Clear
            | Editor.Commands.Command_Diagnostics_Toggle_Info
            | Editor.Commands.Command_Diagnostics_Toggle_Warnings
            | Editor.Commands.Command_Diagnostics_Toggle_Errors
            | Editor.Commands.Command_Diagnostics_Show_All
            | Editor.Commands.Command_Diagnostics_Clear_Filter
            | Editor.Commands.Command_Diagnostics_Filter_Errors
            | Editor.Commands.Command_Diagnostics_Filter_Warnings
            | Editor.Commands.Command_Diagnostics_Filter_Info_Notes
            | Editor.Commands.Command_Diagnostics_Filter_Source
            | Editor.Commands.Command_Diagnostics_Filter_Build
            | Editor.Commands.Command_Diagnostics_Clear_Build
            | Editor.Commands.Command_Diagnostics_Open_Selected
            | Editor.Commands.Command_Diagnostic_Open_Source
            | Editor.Commands.Command_Diagnostic_Suppress_Selected
            | Editor.Commands.Command_Diagnostic_Show_Suppressed
            | Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed
            | Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed
            | Editor.Commands.Command_Diagnostic_Clear_Suppressed
            | Editor.Commands.Command_Diagnostics_Execute_Selected_Action
            | Editor.Commands.Command_Diagnostic_Apply_Quick_Fix
            | Editor.Commands.Command_Diagnostics_Select_Next
            | Editor.Commands.Command_Diagnostics_Select_Previous
            | Editor.Commands.Command_Diagnostics_Clear_Selected
            | Editor.Commands.Command_Diagnostics_Copy_Selected_Text
            | Editor.Commands.Command_Diagnostics_Clear_Info
            | Editor.Commands.Command_Diagnostics_Clear_Warnings
            | Editor.Commands.Command_Diagnostics_Clear_Errors
            | Editor.Commands.Command_Diagnostics_Toggle_Editor_Source
            | Editor.Commands.Command_Diagnostics_Toggle_File_Source
            | Editor.Commands.Command_Diagnostics_Toggle_Project_Source
            | Editor.Commands.Command_Diagnostics_Toggle_External_Source
            | Editor.Commands.Command_Diagnostics_Toggle_Unknown_Source
            =>
            return Editor.Executor.Diagnostics_Commands
              .Execute_Diagnostics_Feature_Command (S, Id);

         when Editor.Commands.Command_Clear_Selected_Message
            | Editor.Commands.Command_Copy_Selected_Message_Text
            | Editor.Commands.Command_Clear_Info_Messages
            | Editor.Commands.Command_Clear_Warning_Messages
            | Editor.Commands.Command_Clear_Error_Messages
            | Editor.Commands.Command_Toggle_Message_Info
            | Editor.Commands.Command_Toggle_Message_Warnings
            | Editor.Commands.Command_Toggle_Message_Errors
            | Editor.Commands.Command_Show_All_Messages
            | Editor.Commands.Command_Clear_Message_Filter
            | Editor.Commands.Command_Dismiss_Latest_Message
            | Editor.Commands.Command_Dismiss_All_Messages =>
            return Editor.Executor.Message_Commands.Execute_Message_Command
              (S, Id);

         when Editor.Commands.Command_Toggle_Theme
            | Editor.Commands.Command_Set_Theme_Light
            | Editor.Commands.Command_Set_Theme_Dark
            | Editor.Commands.Command_Toggle_Minimap
            | Editor.Commands.Command_Toggle_Scrollbars
            | Editor.Commands.Command_Toggle_Line_Numbers
            | Editor.Commands.Command_Toggle_Format_On_Save
            | Editor.Commands.Command_Toggle_Line_Number_Mode
            | Editor.Commands.Command_Set_Absolute_Line_Numbers
            | Editor.Commands.Command_Set_Relative_Line_Numbers
            | Editor.Commands.Command_Set_Hybrid_Line_Numbers
            | Editor.Commands.Command_Toggle_Current_Line_Highlight
            | Editor.Commands.Command_Toggle_Cursor_Blink
            | Editor.Commands.Command_Toggle_Syntax_Colouring
            | Editor.Commands.Command_Toggle_Diagnostics
            | Editor.Commands.Command_Toggle_Cursor_Style =>
            return Editor.Executor.Editor_Preferences_Commands
              .Execute_Editor_Preferences_Command (S, Id);

         when others =>
            null;
      end case;

      Before_Caret := Safe_Caret (S);
      Before_Anchor := Safe_Anchor (S);
      Before_Length := Buffer_Length (S);
      Before_Buffer := Editor.Buffers.Global_Active_Buffer;
      Before_File_Tree_Row :=
        Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View);
      Cmd := Editor.Commands.Command_For_Id (Id, Shift);
      if Cmd.Kind = Editor.Commands.Insert_Text_Input then
         declare
            Line_Status : Editor.Executor.Edits.Line_Edit_Status;
         begin
            Cmd.Pos := Before_Caret;
            Cmd.Has_Position := True;
            Execute_No_Log_With_Status (S, Cmd, Line_Status);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            Editor.Executor.Editing_Commands.Report_Line_Edit_Status
              (S, Id, Line_Status);
            Editor.Render_Cache.Invalidate_All;
         end;
      else
         Execute_No_Log (S, Cmd);
      end if;
      Sync_Current_Outline_Symbol_From_Caret (S);
      if Is_Boundary_Navigation_Command (Id)
        and then Navigation_State_Unchanged
      then
         return Editor.Command_Execution.No_Op (Id);
      elsif Is_Buffer_Switch_Command (Id)
        and then Before_Buffer = Editor.Buffers.Global_Active_Buffer
      then
         return Editor.Command_Execution.No_Op (Id);
      elsif Is_Ordinary_Buffer_Switch_Command (Id)
        and then Scratch_Only_Buffer_Cycle (Before_Buffer)
      then
         return Editor.Command_Execution.No_Op (Id);
      elsif Is_File_Tree_Navigation_Command (Id)
        and then Before_File_Tree_Row =
          Editor.File_Tree_View.Selected_Row_Index (S.File_Tree_View)
      then
         return Editor.Command_Execution.No_Op (Id);
      end if;
      return Result_After_Command (Id);
   end Execute_Command_With_Result;

end Editor.Executor.Command_Result_Commands;
