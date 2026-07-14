with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Executor.Bookmark_Commands;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.Buffer_Metadata_Commands;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Executor.Buffer_Switcher_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
with Editor.Executor.Buffer_Switcher_Preview_Commands;
with Editor.Executor.Buffer_Switcher_Selected_Commands;
with Editor.Executor.Buffer_Switcher_Surface_Commands;
with Editor.Executor.Clipboard;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Configuration_Commands;
with Editor.Executor.Diagnostics_Commands;
with Editor.Executor.Diagnostics_Navigation_Commands;
with Editor.Executor.Diagnostics_Problems_Commands;
with Editor.Executor.Editor_Preferences_Commands;
with Editor.Executor.Feature_Panel_Commands;
with Editor.Executor.File_Lifecycle_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.File_Tree_Delete_Commands;
with Editor.Executor.File_Tree_Mutation_Commands;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Executor.History;
with Editor.Executor.Message_Commands;
with Editor.Executor.Navigation_Commands;
with Editor.Executor.Editor_Preferences_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Executor.Panel_Focus_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Shared_Services;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Executor.Semantic_Commands;
with Editor.Executor.Semantic_Completion_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Problems;
with Editor.Invariants;

package body Editor.Executor.Command_Kind_Routing is

   use type Editor.Commands.Command_Kind;

   function Try_Execute_Non_Edit_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      use Editor.Commands;

      procedure Check_And_Mark_Handled (Handled : out Boolean) is
      begin
         Editor.Invariants.Check (S);
         Handled := True;
      end Check_And_Mark_Handled;

      procedure Run_Search_Results_Command (Id : Editor.Commands.Command_Id);

      procedure Run_Search_Results_Command (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Search_Results_Commands
             .Execute_Search_Results_Command (S, Id);
         pragma Unreferenced (Result);
         begin
            null;
         end Run_Search_Results_Command;

      procedure Run_Message_Command (Id : Editor.Commands.Command_Id);

      procedure Run_Message_Command (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Message_Commands.Execute_Message_Command (S, Id);
         pragma Unreferenced (Result);
      begin
         null;
      end Run_Message_Command;

      procedure Run_Outline_Command (Id : Editor.Commands.Command_Id);

      procedure Run_Outline_Command (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Outline_Commands.Execute_Outline_Command (S, Id, Cmd);
         pragma Unreferenced (Result);
      begin
         null;
      end Run_Outline_Command;

      procedure Run_Editor_Preferences_Command
        (Id : Editor.Commands.Command_Id);

      procedure Run_Editor_Preferences_Command
        (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Editor_Preferences_Commands
             .Execute_Editor_Preferences_Command (S, Id);
         pragma Unreferenced (Result);
      begin
         null;
      end Run_Editor_Preferences_Command;

      procedure Run_Semantic_Command (Id : Editor.Commands.Command_Id);

      procedure Run_Semantic_Command (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Semantic_Commands.Execute_Semantic_Command
             (S, Id, Cmd);
         pragma Unreferenced (Result);
      begin
         null;
      end Run_Semantic_Command;

      procedure Run_Diagnostics_Feature_Command
        (Id : Editor.Commands.Command_Id);

      procedure Run_Diagnostics_Feature_Command
        (Id : Editor.Commands.Command_Id)
      is
         Result : constant Editor.Command_Execution.Command_Execution_Result :=
           Editor.Executor.Diagnostics_Commands
             .Execute_Diagnostics_Feature_Command (S, Id);
         pragma Unreferenced (Result);
      begin
         null;
      end Run_Diagnostics_Feature_Command;

      Handled : Boolean := False;
   begin
      case Cmd.Kind is
         when Undo | Redo =>
            Editor.Executor.History.Execute (S, Cmd);
            Check_And_Mark_Handled (Handled);

         when Break_Group =>
            Editor.Executor.History.Break_Group;
            Check_And_Mark_Handled (Handled);

         when Run_Project
            | Run_Tests
            | Terminal_Toggle
            | Terminal_Show
            | Terminal_Hide
            | Terminal_Focus
            | Terminal_Clear
            | Terminal_Clear_Output
            | Terminal_Select_Next_Task
            | Terminal_Select_Previous_Task
            | Terminal_Run_Selected_Task
            | Terminal_Rerun_Last_Task
            | Terminal_Cancel_Task =>
            Check_And_Mark_Handled (Handled);

         when Copy_Selection | Cut_Selection | Paste_Clipboard | Clear_Clipboard =>
            Editor.Executor.Clipboard.Execute (S, Cmd);
            Check_And_Mark_Handled (Handled);

         when Open_Goto_Line
            | Prefill_Goto_Line_Current
            | Toggle_Goto_Line
            | Close_Goto_Line
            | Accept_Goto_Line
            | Goto_Line_Query_Set
            | Goto_Line_Query_Clear
            | Goto_Line_Insert_Text
            | Goto_Line_Backspace
            | Goto_Line_Delete_Forward
            | Goto_Line_Move_Cursor_Left
            | Goto_Line_Move_Cursor_Right
            =>
            Editor.Executor.Navigation_Commands.Execute_Goto_Line_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Check_And_Mark_Handled (Handled);

         when Open_Quick_Open
            | Close_Quick_Open
            | Toggle_Quick_Open
            | Accept_Quick_Open
            | Quick_Open_Next_Result
            | Quick_Open_Previous_Result
            | Quick_Open_Query_Set
            | Quick_Open_Query_Clear
            | Quick_Open_Kind_Next
            | Quick_Open_Kind_Previous
            | Quick_Open_Kind_Clear
            | Quick_Open_Scope_Set
            | Quick_Open_Scope_Clear
            | Quick_Open_Scope_From_Selected
            | Quick_Open_Scope_Parent
            | Quick_Open_Reveal_Active
            | Quick_Open_Scope_Active_Directory
            | Quick_Open_Create_From_Query
            | Quick_Open_Create_With_Parents_From_Query
            | Quick_Open_Priority_Toggle
            | Quick_Open_Priority_Clear
            | Quick_Open_Insert_Text
            | Quick_Open_Backspace
            | Quick_Open_Delete_Forward
            | Quick_Open_Move_Cursor_Left
            | Quick_Open_Move_Cursor_Right
            | Open_Command_Palette
            | Palette_Show_Command_Help =>
            Editor.Executor.Command_Surface_Commands.Execute_Command_Surface_Kind
              (S, Cmd.Kind, To_String (Cmd.Text));
            Check_And_Mark_Handled (Handled);

         when Active_Find_Show
            | Active_Find_Hide
            | Active_Find_Toggle
            | Active_Find_Query_Set
            | Active_Find_Query_Clear
            | Active_Find_Case_Toggle
            | Active_Find_Case_Clear
            | Active_Find_Whole_Word_Toggle
            | Active_Find_Whole_Word_Clear
            | Active_Find_From_Selection
            | Active_Find_From_Active_Word
            | Active_Find_Next
            | Active_Find_Previous
            | Active_Find_First
            | Active_Find_Last
            | Active_Find_Reveal_Current
            | Active_Replace_Show
            | Active_Replace_Hide
            | Active_Replace_Toggle
            | Active_Replace_Text_Set
            | Active_Replace_Text_Clear
            | Active_Replace_Current
            | Active_Replace_All
            | Active_Find_Input_Insert_Text
            | Active_Find_Input_Backspace
            | Active_Find_Input_Delete_Forward
            | Active_Find_Input_Move_Cursor_Left
            | Active_Find_Input_Move_Cursor_Right =>
            case Cmd.Kind is
               when Active_Find_Show =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
               when Active_Find_Hide =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
               when Active_Find_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Toggle (S);
               when Active_Find_Query_Set =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query
                    (S, To_String (Cmd.Text));
               when Active_Find_Query_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Clear_Query (S);
               when Active_Find_Case_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Toggle (S);
               when Active_Find_Case_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Clear (S);
               when Active_Find_Whole_Word_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Toggle (S);
               when Active_Find_Whole_Word_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Clear (S);
               when Active_Find_From_Selection =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_From_Selection (S);
               when Active_Find_From_Active_Word =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_From_Active_Word (S);
               when Active_Find_Next =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
               when Active_Find_Previous =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Previous (S);
               when Active_Find_First =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_First (S);
               when Active_Find_Last =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Last (S);
               when Active_Find_Reveal_Current =>
                  Editor.Executor.Find_Replace_Commands.Execute_Find_Reveal_Current (S);
               when Active_Replace_Show =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
               when Active_Replace_Hide =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Hide (S);
               when Active_Replace_Toggle =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Toggle (S);
               when Active_Replace_Text_Set =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text
                    (S, To_String (Cmd.Text));
               when Active_Replace_Text_Clear =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Clear_Text (S);
               when Active_Replace_Current =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
               when Active_Replace_All =>
                  Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
               when Active_Find_Input_Insert_Text =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Insert_Text (S, To_String (Cmd.Text));
               when Active_Find_Input_Backspace =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Backspace (S);
               when Active_Find_Input_Delete_Forward =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Delete_Forward (S);
               when Active_Find_Input_Move_Cursor_Left =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Move_Cursor_Left (S);
               when Active_Find_Input_Move_Cursor_Right =>
                  Editor.Executor.Find_Replace_Input_Commands
                    .Execute_Active_Find_Input_Move_Cursor_Right (S);
               when others =>
                  raise Program_Error with "unsupported find/replace command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Navigation_Back
            | Navigation_Forward
            | Navigation_History_Clear =>
            Editor.Executor.Navigation_Commands.Execute_Navigation_History_Kind
              (S, Cmd.Kind);
            Check_And_Mark_Handled (Handled);

         when Previous_Recent_Buffer
            | Next_Recent_Buffer
            | Next_Buffer_Group
            | Previous_Buffer_Group
            | Next_Buffer
            | Previous_Buffer
            | Switch_Buffer =>
            case Cmd.Kind is
               when Next_Buffer_Group =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Next_Buffer_Group (S);

               when Previous_Buffer_Group =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Previous_Buffer_Group (S);

               when Next_Buffer =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Next_Buffer (S);

               when Previous_Buffer =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Previous_Buffer (S);

               when Previous_Recent_Buffer =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Previous_Recent_Buffer (S);

               when Next_Recent_Buffer =>
                  Editor.Executor.Buffer_Navigation_Commands
                    .Execute_Next_Recent_Buffer (S);

               when Switch_Buffer =>
                  Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
                      (S, Editor.Buffers.Buffer_Id (Cmd.Buffer_Id));

               when others =>
                  raise Program_Error with
                    "unsupported buffer navigation command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Open_Buffer_Switcher
            | Close_Buffer_Switcher
            | Accept_Buffer_Switcher
            | Buffer_Switcher_Next_Result
            | Buffer_Switcher_Previous_Result
            | Buffer_Switcher_Insert_Text
            | Buffer_Switcher_Backspace
            | Buffer_Switcher_Delete_Forward
            | Buffer_Switcher_Move_Cursor_Left
            | Buffer_Switcher_Move_Cursor_Right
            | Buffer_Switcher_Filter_Clear
            | Buffer_Switcher_Filter_Pinned
            | Buffer_Switcher_Filter_Group
            | Buffer_Switcher_Filter_Label
            | Buffer_Switcher_Filter_Noted
            | Buffer_Switcher_Sort_Default
            | Buffer_Switcher_Sort_Recent
            | Buffer_Switcher_Sort_Name
            | Buffer_Switcher_Sort_Pinned
            | Buffer_Switcher_Sort_Group
            | Buffer_Switcher_Sort_Label
            | Buffer_Switcher_Sort_Next
            | Buffer_Switcher_Sort_Previous =>
            Editor.Executor.Buffer_Switcher_Surface_Commands
              .Execute_Buffer_Switcher_Surface_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Check_And_Mark_Handled (Handled);

         when Buffer_Switcher_Selected_Close
            | Buffer_Switcher_Selected_Pin
            | Buffer_Switcher_Selected_Unpin
            | Buffer_Switcher_Selected_Toggle_Pin
            | Buffer_Switcher_Selected_Group_Assign
            | Buffer_Switcher_Selected_Group_Clear
            | Buffer_Switcher_Selected_Label_Set
            | Buffer_Switcher_Selected_Label_Clear
            | Buffer_Switcher_Selected_Note_Set
            | Buffer_Switcher_Selected_Note_Clear =>
            Editor.Executor.Buffer_Switcher_Selected_Commands
              .Execute_Buffer_Switcher_Selected_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Check_And_Mark_Handled (Handled);

         when Buffer_Switcher_Preview_Toggle
            | Buffer_Switcher_Preview_Show
            | Buffer_Switcher_Preview_Hide
            | Buffer_Switcher_Preview_Next_Line
            | Buffer_Switcher_Preview_Previous_Line
            | Buffer_Switcher_Preview_Center_Cursor =>
            Editor.Executor.Buffer_Switcher_Preview_Commands
              .Execute_Buffer_Switcher_Preview_Kind (S, Cmd.Kind);
            Check_And_Mark_Handled (Handled);

         when Buffer_Switcher_Mark_Toggle
            | Buffer_Switcher_Mark_Set
            | Buffer_Switcher_Mark_Clear
            | Buffer_Switcher_Mark_Clear_All
            | Buffer_Switcher_Mark_Invert_Visible
            | Buffer_Switcher_Mark_Visible
            | Buffer_Switcher_Mark_Clear_Visible
            | Buffer_Switcher_Mark_Pinned
            | Buffer_Switcher_Mark_Group
            | Buffer_Switcher_Mark_Label
            | Buffer_Switcher_Mark_Noted
            | Buffer_Switcher_Mark_Close_Marked
            | Buffer_Switcher_Mark_Confirm
            | Buffer_Switcher_Mark_Cancel
            | Buffer_Switcher_Mark_Pin_Marked
            | Buffer_Switcher_Mark_Unpin_Marked
            | Buffer_Switcher_Mark_Clear_Metadata
            | Buffer_Switcher_Mark_Group_Assign
            | Buffer_Switcher_Mark_Group_Clear
            | Buffer_Switcher_Mark_Label_Set
            | Buffer_Switcher_Mark_Label_Clear
            | Buffer_Switcher_Mark_Note_Set
            | Buffer_Switcher_Mark_Note_Clear
            | Buffer_Switcher_Mark_Review_Toggle
            | Buffer_Switcher_Mark_Review_Show
            | Buffer_Switcher_Mark_Review_Hide
            | Buffer_Switcher_Mark_Next
            | Buffer_Switcher_Mark_Previous
            | Buffer_Switcher_Mark_Summary =>
            Editor.Executor.Buffer_Switcher_Mark_Commands
              .Execute_Buffer_Switcher_Mark_Kind
                (S, Cmd.Kind, To_String (Cmd.Text));
            Check_And_Mark_Handled (Handled);

         when Buffer_Switcher_Pending_Mark_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Review_Show
            | Buffer_Switcher_Pending_Mark_Review_Hide
            | Buffer_Switcher_Pending_Mark_Next
            | Buffer_Switcher_Pending_Mark_Previous
            | Buffer_Switcher_Pending_Mark_Summary
            | Buffer_Switcher_Pending_Mark_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Buffer_Switcher_Pending_Mark_Pruned_Next
            | Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
            | Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Kind (S, Cmd.Kind);
            Check_And_Mark_Handled (Handled);

         when Toggle_Feature_Panel
            | Show_Feature_Panel
            | Hide_Feature_Panel
            | Focus_Feature_Panel
            | Clear_Feature_Panel
            | Feature_Panel_Select_Next
            | Feature_Panel_Select_Previous
            | Feature_Panel_Open_Selected =>
            declare
               procedure Run (Id : Editor.Commands.Command_Id) is
                  Result : constant Editor.Command_Execution.Command_Execution_Result :=
                    Editor.Executor.Feature_Panel_Commands.Execute_Feature_Panel_Command
                      (S, Id);
                  pragma Unreferenced (Result);
               begin
                  null;
               end Run;
            begin
            case Cmd.Kind is
               when Toggle_Feature_Panel =>
                  Run (Command_Toggle_Feature_Panel);
               when Show_Feature_Panel =>
                  Run (Command_Show_Feature_Panel);
               when Hide_Feature_Panel =>
                  Run (Command_Hide_Feature_Panel);
               when Focus_Feature_Panel =>
                  Run (Command_Focus_Feature_Panel);
               when Clear_Feature_Panel =>
                  Run (Command_Clear_Feature_Panel);
               when Feature_Panel_Select_Next =>
                  Run (Command_Feature_Panel_Select_Next);
               when Feature_Panel_Select_Previous =>
                  Run (Command_Feature_Panel_Select_Previous);
               when Feature_Panel_Open_Selected =>
                  Run (Command_Feature_Panel_Open_Selected);
               when others =>
                  raise Program_Error with "unsupported feature-panel command kind";
            end case;
            end;
            Check_And_Mark_Handled (Handled);

         when Goto_Declaration
            | Goto_Body
            | Goto_Spec
            | Find_References
            | Workspace_Symbols
            | Show_Hover
            | Show_Completions
            | Semantic_Completion_Select_Next
            | Semantic_Completion_Select_Previous
            | Semantic_Completion_Accept
            | Semantic_Popup_Dismiss
            | Rename_Symbol_Preview
            | Rename_Symbol_Apply
            | Semantic_Refresh_Buffer
            | Semantic_Refresh_Project_Index
            | Language_Index_Clear
            | Language_Index_Status =>
            case Cmd.Kind is
               when Goto_Declaration =>
                  Run_Semantic_Command (Command_Goto_Declaration);

               when Goto_Body =>
                  Run_Semantic_Command (Command_Goto_Body);

               when Goto_Spec =>
                  Run_Semantic_Command (Command_Goto_Spec);

               when Find_References =>
                  Run_Semantic_Command (Command_Find_References);

               when Workspace_Symbols =>
                  Run_Semantic_Command (Command_Workspace_Symbols);

               when Show_Hover =>
                  Run_Semantic_Command (Command_Show_Hover);

               when Show_Completions =>
                  Run_Semantic_Command (Command_Show_Completions);

               when Rename_Symbol_Preview =>
                  Run_Semantic_Command (Command_Rename_Symbol_Preview);

               when Rename_Symbol_Apply =>
                  Run_Semantic_Command (Command_Rename_Symbol_Apply);

               when Semantic_Refresh_Buffer =>
                  Run_Semantic_Command (Command_Semantic_Refresh_Buffer);

               when Semantic_Refresh_Project_Index =>
                  Run_Semantic_Command (Command_Semantic_Refresh_Project_Index);

               when Language_Index_Clear =>
                  Run_Semantic_Command (Command_Language_Index_Clear);

               when Language_Index_Status =>
                  Run_Semantic_Command (Command_Language_Index_Status);

               when Semantic_Completion_Select_Next =>
                  Editor.Executor.Semantic_Completion_Commands
                    .Execute_Semantic_Completion_Kind
                      (S, Semantic_Completion_Select_Next);

               when Semantic_Completion_Select_Previous =>
                  Editor.Executor.Semantic_Completion_Commands
                    .Execute_Semantic_Completion_Kind
                      (S, Semantic_Completion_Select_Previous);

               when Semantic_Completion_Accept =>
                  Editor.Executor.Semantic_Completion_Commands
                    .Execute_Semantic_Completion_Kind
                      (S, Semantic_Completion_Accept);

               when Semantic_Popup_Dismiss =>
                  Editor.Executor.Semantic_Completion_Commands
                    .Execute_Semantic_Completion_Kind
                      (S, Semantic_Popup_Dismiss);

               when others =>
                  raise Program_Error with "unsupported semantic command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Refresh_Outline
            | Refresh_Outline_Project_Index
            | Clear_Outline
            | Show_Outline
            | Focus_Outline
            | Open_Selected_Outline_Item
            | Select_Current_Outline_Symbol
            | Reveal_Current_Outline_Symbol
            | Next_Outline_Symbol
            | Previous_Outline_Symbol
            | Select_Next_Outline_Item
            | Select_Previous_Outline_Item
            | Focus_Outline_Filter
            | Filter_Outline
            | Clear_Outline_Filter
            | Toggle_Outline_Filter
            | Outline_Filter_History_Previous
            | Outline_Filter_History_Next
            | Clear_Outline_Filter_History =>
            case Cmd.Kind is
               when Refresh_Outline =>
                  Run_Outline_Command (Command_Refresh_Outline);

               when Refresh_Outline_Project_Index =>
                  Run_Outline_Command (Command_Refresh_Outline_Project_Index);

               when Clear_Outline =>
                  Run_Outline_Command (Command_Clear_Outline);

               when Show_Outline =>
                  Run_Outline_Command (Command_Show_Outline);

               when Focus_Outline =>
                  Run_Outline_Command (Command_Focus_Outline);

               when Open_Selected_Outline_Item =>
                  Run_Outline_Command (Command_Open_Selected_Outline_Item);

               when Select_Current_Outline_Symbol =>
                  Run_Outline_Command (Command_Select_Current_Outline_Symbol);

               when Reveal_Current_Outline_Symbol =>
                  Run_Outline_Command (Command_Reveal_Current_Outline_Symbol);

               when Next_Outline_Symbol =>
                  Run_Outline_Command (Command_Next_Outline_Symbol);

               when Previous_Outline_Symbol =>
                  Run_Outline_Command (Command_Previous_Outline_Symbol);

               when Select_Next_Outline_Item =>
                  Run_Outline_Command (Command_Select_Next_Outline_Item);

               when Select_Previous_Outline_Item =>
                  Run_Outline_Command (Command_Select_Previous_Outline_Item);

               when Focus_Outline_Filter =>
                  Run_Outline_Command (Command_Focus_Outline_Filter);

               when Filter_Outline =>
                  Run_Outline_Command (Command_Filter_Outline);

               when Clear_Outline_Filter =>
                  Run_Outline_Command (Command_Clear_Outline_Filter);

               when Toggle_Outline_Filter =>
                  Run_Outline_Command (Command_Toggle_Outline_Filter);

               when Outline_Filter_History_Previous =>
                  Run_Outline_Command (Command_Outline_Filter_History_Previous);

               when Outline_Filter_History_Next =>
                  Run_Outline_Command (Command_Outline_Filter_History_Next);

               when Clear_Outline_Filter_History =>
                  Run_Outline_Command (Command_Clear_Outline_Filter_History);

               when others =>
                  raise Program_Error with "unsupported outline command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Show_Messages
            | Clear_Messages
            | Clear_Selected_Message
            | Copy_Selected_Message_Text
            | Clear_Info_Messages
            | Clear_Warning_Messages
            | Clear_Error_Messages
            | Toggle_Message_Info
            | Toggle_Message_Warnings
            | Toggle_Message_Errors
            | Show_All_Messages
            | Clear_Message_Filter =>
            case Cmd.Kind is
               when Show_Messages =>
                  Run_Message_Command (Command_Show_Messages);

               when Clear_Messages =>
                  Run_Message_Command (Command_Clear_Messages);

               when Clear_Selected_Message =>
                  Run_Message_Command (Command_Clear_Selected_Message);

               when Copy_Selected_Message_Text =>
                  Run_Message_Command (Command_Copy_Selected_Message_Text);

               when Clear_Info_Messages =>
                  Run_Message_Command (Command_Clear_Info_Messages);

               when Clear_Warning_Messages =>
                  Run_Message_Command (Command_Clear_Warning_Messages);

               when Clear_Error_Messages =>
                  Run_Message_Command (Command_Clear_Error_Messages);

               when Toggle_Message_Info =>
                  Run_Message_Command (Command_Toggle_Message_Info);

               when Toggle_Message_Warnings =>
                  Run_Message_Command (Command_Toggle_Message_Warnings);

               when Toggle_Message_Errors =>
                  Run_Message_Command (Command_Toggle_Message_Errors);

               when Show_All_Messages =>
                  Run_Message_Command (Command_Show_All_Messages);

               when Clear_Message_Filter =>
                  Run_Message_Command (Command_Clear_Message_Filter);

               when others =>
                  raise Program_Error with
                    "unsupported message command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Save_Settings
            | Reload_Settings
            | Reset_Settings_To_Defaults
            | Save_Keybindings
            | Reload_Keybindings
            | Validate_Keybindings
            | Startup_Show_Summary
            | Configuration_Recover_Show
            | Configuration_Audit
            | Configuration_Reset_Settings
            | Configuration_Reset_Keybindings
            | Configuration_Reset_Workspace
            | Configuration_Reset_Recent_Projects
            | Configuration_Reset_All
            | Configuration_Reset_All_Confirm
            | Configuration_Reset_All_Cancel
            | Configuration_Save_Clean_Settings
            | Configuration_Save_Clean_Keybindings
            | Configuration_Save_Clean_Workspace
            | Configuration_Save_Clean_Recent_Projects =>
            Editor.Executor.Configuration_Commands.Execute_Configuration_Kind
              (S, Cmd.Kind);
            Check_And_Mark_Handled (Handled);

         when Save_Workspace_State
            | Restore_Workspace_State
            | Clear_Workspace_State =>
            case Cmd.Kind is
               when Save_Workspace_State =>
                  Editor.Executor.Workspace_Commands
                    .Execute_Save_Workspace_State (S);

               when Restore_Workspace_State =>
                  Editor.Executor.Workspace_Commands
                    .Execute_Restore_Workspace_State (S);

               when Clear_Workspace_State =>
                  Editor.Executor.Workspace_Commands
                    .Execute_Clear_Workspace_State (S);

               when others =>
                  raise Program_Error with
                    "unsupported workspace command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Open_File
            | New_Buffer
            | Reopen_Closed_Buffer =>
            case Cmd.Kind is
               when Open_File =>
                  if Length (Cmd.Path) = 0 then
                     Editor.Executor.Shared_Services.Report_Info
                       (S, "Open File requires a path");
                  else
                     declare
                        Before_Location : constant
                          Editor.Navigation_History.Navigation_Location :=
                            Editor.Executor.Current_Navigation_Location
                              (S, Editor.Navigation_History.Navigation_Reason_Unknown);
                        Target_Path : constant String := To_String (Cmd.Path);
                     begin
                        Editor.Executor.File_Open_Commands.Execute_Open_File
                          (S, Target_Path);
                        if S.File_Info.Has_Path
                          and then To_String (S.File_Info.Path) = Target_Path
                        then
                           Editor.Executor.Record_Navigation_If_Target_Changed
                             (S, Before_Location,
                              Editor.Executor.Structured_File_Navigation_Target
                                (Target_Path));
                        end if;
                     end;
                  end if;

               when New_Buffer =>
                  Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);

               when Reopen_Closed_Buffer =>
                  Editor.Executor.File_Open_Commands
                    .Execute_Reopen_Closed_Buffer (S);

               when others =>
                  raise Program_Error with "unsupported file open command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Open_Project
            | Switch_Project
            | Show_Recent_Projects
            | Open_Selected_Recent_Project
            | Clear_Recent_Projects
            | Remove_Selected_Recent_Project
            | Remove_Missing_Recent_Projects
            | Select_Next_Recent_Project
            | Select_Previous_Recent_Project
            | Close_Project
            | Clear_Project =>
            case Cmd.Kind is
               when Open_Project =>
                  if Length (Cmd.Path) = 0 then
                     Editor.Executor.Shared_Services.Report_Info
                       (S, "Open Project requires a path");
                  else
                     Editor.Executor.Project_Lifecycle_Commands
                       .Execute_Open_Project (S, To_String (Cmd.Path));
                  end if;

               when Switch_Project =>
                  if Length (Cmd.Path) = 0 then
                     Editor.Executor.Shared_Services.Report_Info
                       (S, "Switch Project requires a target project");
                  else
                     Editor.Executor.Project_Lifecycle_Commands
                       .Execute_Open_Project
                         (S,
                          To_String (Cmd.Path),
                          Refresh_Build_Candidates => True,
                          Apply_Workspace_Policy => False,
                          Explicit_Switch => True);
                  end if;

               when Show_Recent_Projects =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Show_Recent_Projects (S);

               when Open_Selected_Recent_Project =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Open_Selected_Recent_Project (S);

               when Clear_Recent_Projects =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Clear_Recent_Projects (S);

               when Remove_Selected_Recent_Project =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Remove_Selected_Recent_Project (S);

               when Remove_Missing_Recent_Projects =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Remove_Missing_Recent_Projects (S);

               when Select_Next_Recent_Project =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Select_Next_Recent_Project (S);

               when Select_Previous_Recent_Project =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Select_Previous_Recent_Project (S);

               when Close_Project | Clear_Project =>
                  Editor.Executor.Project_Lifecycle_Commands
                    .Execute_Guarded_Close_Project (S);

               when others =>
                  raise Program_Error with
                    "unsupported project lifecycle command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Refresh_File_Tree
            | Refresh_Project_Files
            | Project_Files_Summary
            | Reveal_Active_File_In_Tree
            | Focus_File_Tree
            | File_Tree_Move_Up
            | File_Tree_Move_Down
            | File_Tree_Page_Up
            | File_Tree_Page_Down
            | File_Tree_Open_Selected
            | File_Tree_Create_File
            | File_Tree_Create_Directory
            | File_Tree_Rename_Selected
            | File_Tree_Delete_Selected
            | File_Tree_Expand_Selected
            | File_Tree_Collapse_Selected
            | File_Tree_Toggle_Selected
            | File_Tree_Collapse_All
            | File_Tree_Expand_To_Active_File =>
            case Cmd.Kind is
               when Refresh_File_Tree =>
                  Editor.Executor.Project_File_Index_Commands
                    .Execute_Refresh_File_Tree (S);

               when Refresh_Project_Files =>
                  Editor.Executor.Project_File_Index_Commands
                    .Execute_Refresh_Project_Files (S);

               when Project_Files_Summary =>
                  Editor.Executor.Project_File_Index_Commands
                    .Execute_Project_Files_Summary (S);

               when Reveal_Active_File_In_Tree =>
                  Editor.Executor.Project_File_Index_Commands
                    .Execute_Reveal_Active_File_In_Tree (S);

               when Focus_File_Tree =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_Focus_File_Tree (S);

               when File_Tree_Move_Up =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Move_Up (S);

               when File_Tree_Move_Down =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Move_Down (S);

               when File_Tree_Page_Up =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Page_Up (S);

               when File_Tree_Page_Down =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Page_Down (S);

               when File_Tree_Open_Selected =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Open_Selected (S);

               when File_Tree_Create_File =>
                  Editor.Executor.File_Tree_Mutation_Commands
                    .Execute_File_Tree_Create_File (S, Cmd);

               when File_Tree_Create_Directory =>
                  Editor.Executor.File_Tree_Mutation_Commands
                    .Execute_File_Tree_Create_Directory (S, Cmd);

               when File_Tree_Rename_Selected =>
                  Editor.Executor.File_Tree_Mutation_Commands
                    .Execute_File_Tree_Rename_Selected (S, Cmd);

               when File_Tree_Delete_Selected =>
                  Editor.Executor.File_Tree_Delete_Commands
                    .Execute_File_Tree_Delete_Selected (S, Cmd);

               when File_Tree_Expand_Selected =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Expand_Selected (S);

               when File_Tree_Collapse_Selected =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Collapse_Selected (S);

               when File_Tree_Toggle_Selected =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Toggle_Selected (S);

               when File_Tree_Collapse_All =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Collapse_All (S);

               when File_Tree_Expand_To_Active_File =>
                  Editor.Executor.File_Tree_Navigation_Commands
                    .Execute_File_Tree_Expand_To_Active_File (S);

               when others =>
                  raise Program_Error with "unsupported file tree command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Save_File
            | Save_File_As
            | Save_All
            | Reload_Active_Buffer
            | Revert_Active_Buffer
            | Rename_Buffer_File
            | Delete_Buffer_File
            | Copy_Buffer_File
            | Move_Buffer_File
            | File_Conflict_Keep_Buffer
            | File_Conflict_Reload_From_Disk
            | File_Conflict_Overwrite_Disk
            | File_Conflict_Cancel
            | Cancel_Pending_Transition
            | Retry_Pending_Transition =>
            Editor.Executor.File_Lifecycle_Commands.Execute_Lifecycle_Kind
              (S, Cmd);
            Check_And_Mark_Handled (Handled);

         when Close_Buffer
            | Close_Other_Buffers
            | Close_All_Clean_Buffers
            | Discard_Pending_Transition =>
            Editor.Executor.Buffer_Close_Commands.Execute_Buffer_Close_Kind
              (S, Cmd);
            Check_And_Mark_Handled (Handled);

         when Pin_Buffer
            | Unpin_Buffer
            | Toggle_Buffer_Pin
            | Set_Buffer_Label
            | Edit_Buffer_Label
            | Clear_Buffer_Label
            | Show_Buffer_Label
            | Set_Buffer_Note
            | Edit_Buffer_Note
            | Clear_Buffer_Note
            | Show_Buffer_Note
            | Assign_Buffer_Group
            | Clear_Buffer_Group
            | Switch_Buffer_Group
            | Show_All_Buffer_Groups =>
            case Cmd.Kind is
               when Pin_Buffer =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Pin_Buffer (S);

               when Unpin_Buffer =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Unpin_Buffer (S);

               when Toggle_Buffer_Pin =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Toggle_Buffer_Pin
                    (S);

               when Set_Buffer_Label | Edit_Buffer_Label =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Set_Buffer_Label
                    (S, To_String (Cmd.Text));

               when Clear_Buffer_Label =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Clear_Buffer_Label
                    (S);

               when Show_Buffer_Label =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Show_Buffer_Label
                    (S);

               when Set_Buffer_Note | Edit_Buffer_Note =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Set_Buffer_Note
                    (S, To_String (Cmd.Text));

               when Clear_Buffer_Note =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Clear_Buffer_Note
                    (S);

               when Show_Buffer_Note =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Show_Buffer_Note
                    (S);

               when Assign_Buffer_Group =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Assign_Buffer_Group
                    (S, To_String (Cmd.Text));

               when Clear_Buffer_Group =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Clear_Buffer_Group
                    (S);

               when Switch_Buffer_Group =>
                  Editor.Executor.Buffer_Metadata_Commands.Execute_Switch_Buffer_Group
                    (S, To_String (Cmd.Text));

               when Show_All_Buffer_Groups =>
                  Editor.Executor.Buffer_Metadata_Commands
                    .Execute_Show_All_Buffer_Groups (S);

               when others =>
                  raise Program_Error with
                    "unsupported buffer metadata command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Toggle_Theme
            | Toggle_Minimap
            | Toggle_Scrollbars
            | Toggle_Format_On_Save
            | Toggle_Line_Number_Mode
            | Set_Theme_Light
            | Set_Theme_Dark
            | Toggle_Cursor_Blink =>
            case Cmd.Kind is
               when Toggle_Theme =>
                  Run_Editor_Preferences_Command (Command_Toggle_Theme);

               when Toggle_Minimap =>
                  Run_Editor_Preferences_Command (Command_Toggle_Minimap);

               when Toggle_Scrollbars =>
                  Run_Editor_Preferences_Command (Command_Toggle_Scrollbars);

               when Toggle_Format_On_Save =>
                  Run_Editor_Preferences_Command (Command_Toggle_Format_On_Save);

               when Toggle_Line_Number_Mode =>
                  Run_Editor_Preferences_Command (Command_Toggle_Line_Number_Mode);

               when Toggle_Cursor_Blink =>
                  Run_Editor_Preferences_Command (Command_Toggle_Cursor_Blink);

               when Set_Theme_Light =>
                  Run_Editor_Preferences_Command (Command_Set_Theme_Light);

               when Set_Theme_Dark =>
                  Run_Editor_Preferences_Command (Command_Set_Theme_Dark);

               when others =>
                  raise Program_Error with
                    "unsupported editor preferences command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Toggle_Problems_Panel
            | Focus_Editor_Text
            | Focus_Search_Results
            | Focus_Problems
            | Toggle_Bottom_Panel_Focus =>
            case Cmd.Kind is
               when Toggle_Problems_Panel =>
                  Editor.Executor.Panel_Focus_Commands.Execute_Toggle_Problems_Panel
                    (S);
               when Focus_Editor_Text =>
                  Editor.Executor.Panel_Focus_Commands.Execute_Focus_Editor_Text
                    (S);
               when Focus_Search_Results =>
                  Editor.Executor.Panel_Focus_Commands.Execute_Focus_Search_Results
                    (S);
               when Focus_Problems =>
                  Editor.Executor.Panel_Focus_Commands.Execute_Focus_Problems (S);
               when Toggle_Bottom_Panel_Focus =>
                  Editor.Executor.Panel_Focus_Commands
                    .Execute_Toggle_Bottom_Panel_Focus (S);
               when others =>
                  raise Program_Error with "unsupported panel-focus command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Next_Diagnostic
            | Previous_Diagnostic
            | Problems_Move_Up
            | Problems_Move_Down
            | Problems_Page_Up
            | Problems_Page_Down
            | Problems_Open_Selected
            | Problems_Filter_All
            | Problems_Filter_Errors
            | Problems_Filter_Warnings
            | Problems_Filter_Info
            | Problems_Filter_Hints
            | Problems_Sort_By_Location
            | Problems_Sort_By_Severity
            | Problems_Sort_By_Source
            | Problems_Group_By_Severity
            | Problems_Group_By_Source
            | Problems_Focus_Editor
            | Diagnostics_Show
            | Diagnostics_Clear
            | Diagnostics_Toggle_Info
            | Diagnostics_Toggle_Warnings
            | Diagnostics_Toggle_Errors
            | Diagnostics_Show_All
            | Diagnostics_Clear_Filter
            | Diagnostics_Filter_Errors
            | Diagnostics_Filter_Warnings
            | Diagnostics_Filter_Info_Notes
            | Diagnostics_Filter_Source
            | Diagnostics_Filter_Build
            | Diagnostics_Clear_Build
            | Diagnostics_Open_Selected
            | Diagnostic_Open_Source
            | Diagnostic_Suppress_Selected
            | Diagnostic_Show_Suppressed
            | Diagnostic_Restore_Last_Suppressed
            | Diagnostic_Restore_Selected_Suppressed
            | Diagnostic_Clear_Suppressed
            | Diagnostic_Apply_Quick_Fix
            | Diagnostics_Execute_Selected_Action
            | Diagnostics_Select_Next
            | Diagnostics_Select_Previous
            | Diagnostics_Clear_Selected
            | Diagnostics_Copy_Selected_Text
            | Diagnostics_Clear_Info
            | Diagnostics_Clear_Warnings
            | Diagnostics_Clear_Errors
            | Diagnostics_Toggle_Editor_Source
            | Diagnostics_Toggle_File_Source
            | Diagnostics_Toggle_Project_Source
            | Diagnostics_Toggle_External_Source
            | Diagnostics_Toggle_Unknown_Source =>
            case Cmd.Kind is
               when Diagnostics_Show =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Show);

               when Diagnostics_Clear =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Clear);

               when Diagnostics_Toggle_Info =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Toggle_Info);

               when Diagnostics_Toggle_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_Warnings);

               when Diagnostics_Toggle_Errors =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Toggle_Errors);

               when Diagnostics_Show_All =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Show_All);

               when Diagnostics_Clear_Filter =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Clear_Filter);

               when Diagnostics_Filter_Errors =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Filter_Errors);

               when Diagnostics_Filter_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Filter_Warnings);

               when Diagnostics_Filter_Info_Notes =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Filter_Info_Notes);

               when Diagnostics_Filter_Source =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Filter_Source);

               when Diagnostics_Filter_Build =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Filter_Build);

               when Diagnostics_Clear_Build =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Clear_Build);

               when Diagnostics_Open_Selected =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Open_Selected);

               when Next_Diagnostic =>
                  Editor.Executor.Diagnostics_Navigation_Commands
                    .Execute_Next_Diagnostic (S);

               when Previous_Diagnostic =>
                  Editor.Executor.Diagnostics_Navigation_Commands
                    .Execute_Previous_Diagnostic (S);

               when Diagnostic_Open_Source =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostic_Open_Source);

               when Diagnostic_Suppress_Selected =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Suppress_Selected);

               when Diagnostic_Show_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Show_Suppressed);

               when Diagnostic_Restore_Last_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Restore_Last_Suppressed);

               when Diagnostic_Restore_Selected_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Restore_Selected_Suppressed);

               when Diagnostic_Clear_Suppressed =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Clear_Suppressed);

               when Diagnostic_Apply_Quick_Fix =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostic_Apply_Quick_Fix);

               when Diagnostics_Execute_Selected_Action =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Execute_Selected_Action);

               when Diagnostics_Select_Next =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Select_Next);

               when Diagnostics_Select_Previous =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Select_Previous);

               when Diagnostics_Clear_Selected =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Clear_Selected);

               when Diagnostics_Copy_Selected_Text =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Copy_Selected_Text);

               when Diagnostics_Clear_Info =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Clear_Info);

               when Diagnostics_Clear_Warnings =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Clear_Warnings);

               when Diagnostics_Clear_Errors =>
                  Run_Diagnostics_Feature_Command (Command_Diagnostics_Clear_Errors);

               when Diagnostics_Toggle_Editor_Source =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_Editor_Source);

               when Diagnostics_Toggle_File_Source =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_File_Source);

               when Diagnostics_Toggle_Project_Source =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_Project_Source);

               when Diagnostics_Toggle_External_Source =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_External_Source);

               when Diagnostics_Toggle_Unknown_Source =>
                  Run_Diagnostics_Feature_Command
                    (Command_Diagnostics_Toggle_Unknown_Source);

               when Problems_Move_Up =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Move_Up (S);

               when Problems_Move_Down =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Move_Down (S);

               when Problems_Page_Up =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Page_Up (S);

               when Problems_Page_Down =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Page_Down (S);

               when Problems_Open_Selected =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Open_Selected (S);

               when Problems_Filter_All =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_All);

               when Problems_Filter_Errors =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Errors);

               when Problems_Filter_Warnings =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Warnings);

               when Problems_Filter_Info =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Info);

               when Problems_Filter_Hints =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Filter
                      (S, Editor.Problems.Problems_Show_Hints);

               when Problems_Sort_By_Location =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Location);

               when Problems_Sort_By_Severity =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Severity);

               when Problems_Sort_By_Source =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Sort
                      (S, Editor.Problems.Problems_Sort_By_Source);

               when Problems_Group_By_Severity =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Group
                      (S, Editor.Problems.Problems_Group_By_Severity);

               when Problems_Group_By_Source =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Group
                      (S, Editor.Problems.Problems_Group_By_Source);

               when Problems_Focus_Editor =>
                  Editor.Executor.Diagnostics_Problems_Commands
                    .Execute_Problems_Focus_Editor (S);

               when others =>
                  raise Program_Error with
                    "unsupported diagnostics command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when Toggle_Bookmark
            | Next_Bookmark
            | Previous_Bookmark
            | Clear_Bookmarks
            | Clear_All_Bookmarks
            | Bookmark_Toggle_Current_Location
            | Bookmark_Clear_All
            | Bookmark_Next
            | Bookmark_Previous
            | Bookmark_Goto_Next
            | Bookmark_Goto_Previous
            | Bookmark_Open_Selected
            | Bookmark_Reveal_Current
            | Bookmark_Remove_Selected
            | Bookmark_Show
            | Bookmark_Hide
            | Bookmark_Toggle =>
            Editor.Executor.Bookmark_Commands.Execute_Bookmark_Kind
              (S, Cmd.Kind);
            Check_And_Mark_Handled (Handled);

         when Run_Project_Search
            | Rerun_Project_Search
            | Open_Project_Search_Bar
            | Toggle_Project_Search_Bar
            | Close_Project_Search_Bar
            | Run_Project_Search_From_Bar
            | Project_Search_Bar_Insert_Text
            | Project_Search_Bar_Backspace
            | Project_Search_Bar_Delete_Forward
            | Project_Search_Bar_Move_Cursor_Left
            | Project_Search_Bar_Move_Cursor_Right
            | Project_Search_From_Selection
            | Project_Search_From_Active_Word
            | Project_Search_Active_Directory
            | Clear_Project_Search
            | Open_Selected_Project_Search_Result
            | Move_Project_Search_Selection_Up
            | Move_Project_Search_Selection_Down
            | Next_Project_Search_Result
            | Previous_Project_Search_Result
            | First_Project_Search_Result
            | Last_Project_Search_Result
            | Reveal_Active_Project_Search_Result
            | Project_Search_Scope_Selected_Directory
            | Project_Search_Kind_Next
            | Project_Search_Kind_Previous
            | Project_Search_Kind_Clear
            | Project_Search_Scope_Set
            | Project_Search_Scope_Clear
            | Project_Search_Case_Toggle
            | Project_Search_Case_Clear
            | Project_Search_Whole_Word_Toggle
            | Project_Search_Whole_Word_Clear
            | Project_Search_Regex_Toggle
            | Project_Search_Regex_Clear
            | Project_Search_Include_Filter_Set
            | Project_Search_Exclude_Filter_Set
            | Project_Search_Include_Filter_Clear
            | Project_Search_Exclude_Filter_Clear
            | Project_Search_Replace_Preview
            | Project_Search_Replace_Toggle_Selected
            | Project_Search_Replace_Include_Selected
            | Project_Search_Replace_Exclude_Selected
            | Project_Search_Replace_Include_File
            | Project_Search_Replace_Exclude_File
            | Project_Search_Replace_Include_All
            | Project_Search_Replace_Exclude_All
            | Project_Search_Replace_Selected
            | Project_Search_Replace_All_Included
            | Project_Search_Replace_Clear_Preview
            | Show_Search_Results_Panel =>
            Editor.Executor.Search_Commands.Execute_Project_Search_Kind
              (S, Cmd);
            Check_And_Mark_Handled (Handled);

         when Search_Results_Move_Up
            | Search_Results_Move_Down
            | Search_Results_Page_Up
            | Search_Results_Page_Down
            | Search_Results_Open_Selected
            | Search_Results_Search_Active_Buffer
            | Search_Results_Focus_Query
            | Search_Results_Repeat_Active_Buffer
            | Search_Results_Query_History_Previous
            | Search_Results_Query_History_Next
            | Search_Results_Toggle_Case_Sensitive
            | Show_Search_Results_Feature
            | Clear_Search_Results_Feature
            | Search_Results_Close_Or_Hide =>
            case Cmd.Kind is
               when Search_Results_Move_Up =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Move_Up (S);

               when Search_Results_Move_Down =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Move_Down (S);

               when Search_Results_Page_Up =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Page_Up (S);

               when Search_Results_Page_Down =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Page_Down (S);

               when Search_Results_Open_Selected =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Open_Selected (S);

               when Search_Results_Close_Or_Hide =>
                  Editor.Executor.Search_Results_Commands
                    .Execute_Search_Results_Close_Or_Hide (S);

               when Search_Results_Search_Active_Buffer =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Search_Active_Buffer);

               when Search_Results_Focus_Query =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Focus_Query);

               when Search_Results_Repeat_Active_Buffer =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Repeat_Active_Buffer);

               when Search_Results_Query_History_Previous =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Query_History_Previous);

               when Search_Results_Query_History_Next =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Query_History_Next);

               when Search_Results_Toggle_Case_Sensitive =>
                  Run_Search_Results_Command
                    (Command_Search_Results_Toggle_Case_Sensitive);

               when Show_Search_Results_Feature =>
                  Run_Search_Results_Command
                    (Command_Show_Search_Results_Feature);

               when Clear_Search_Results_Feature =>
                  Run_Search_Results_Command
                    (Command_Clear_Search_Results_Feature);

               when others =>
                  raise Program_Error with
                    "unsupported search-results command kind";
            end case;
            Check_And_Mark_Handled (Handled);

         when others =>
            null;
      end case;

      return Handled;
   end Try_Execute_Non_Edit_Kind;

end Editor.Executor.Command_Kind_Routing;
