with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.File_Conflict_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Files;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.File_Lifecycle_Commands is

   use Editor.Commands;

   function Result_After_Command
     (S               : Editor.State.State_Type;
      Command         : Editor.Commands.Command_Id;
      Before_Messages : Natural)
      return Editor.Command_Execution.Command_Execution_Result
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
               return Editor.Command_Execution.Unavailable (Command);
            end if;
         end if;
      end if;

      return Editor.Command_Execution.Executed (Command);
   end Result_After_Command;

   function Has_Buffer (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.State.Has_Active_Buffer (S);
   end Has_Buffer;

   function Associated_File_Operation_Availability
     (S             : Editor.State.State_Type;
      Dirty_Message : String) return Editor.Commands.Command_Availability
   is
      Active_Id : constant Editor.Buffers.Buffer_Id :=
        Editor.Buffers.Global_Active_Buffer;
      Effective_File : Editor.State.File_State := S.File_Info;
      Effective_Has_Buffer : Boolean := Has_Buffer (S);
   begin
      if Editor.Buffers.Global_Count = 0
        or else Active_Id = Editor.Buffers.No_Buffer
      then
         return Editor.Commands.Unavailable ("No active buffer.");
      end if;

      if S.Active_Buffer_Token /= Natural (Active_Id) then
         if not Editor.Buffers.Global_Contains (Active_Id) then
            return Editor.Commands.Unavailable ("No active buffer.");
         end if;

         Effective_File :=
           Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Active_Id).File_Info;
         Effective_Has_Buffer := True;
      end if;

      if not Effective_Has_Buffer then
         return Editor.Commands.Unavailable ("No active buffer.");
      elsif not Effective_File.Has_Path
        or else Length (Effective_File.Path) = 0
      then
         return Editor.Commands.Unavailable ("No file path for active buffer");
      elsif Effective_File.Dirty then
         return Editor.Commands.Unavailable (Dirty_Message);
      end if;

      return Editor.Commands.Available;
   end Associated_File_Operation_Availability;

   procedure Lifecycle_Command_Availability
     (S        : Editor.State.State_Type;
      Id       : Editor.Commands.Command_Id;
      Handled  : out Boolean;
      Result   : out Editor.Commands.Command_Availability)
   is
   begin
      Handled := True;
      Result := Editor.Commands.Available;

      if S.Dirty_Close_Prompt_Active then
         case Id is
            when Command_Confirm_Close_Save =>
               if S.Dirty_Close_Prompt_All_Buffers then
                  declare
                     Current : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
                       Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Buffer_Summary_For_All_Buffers (S.Project);
                  begin
                     if Current.Dirty_Count = 0 then
                        if Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_All_Buffer_Identity_Current (S) then
                           Result := Editor.Commands.Available;
                        else
                           Result := Editor.Commands.Unavailable
                             (Editor.Commands.Reason_Close_Review_Stale);
                        end if;
                        return;
                     elsif not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_All_Buffer_Review_Current (S) then
                        if not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_All_Buffer_Identity_Current (S)
                          or else not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_Current_Dirty_Set_Was_Reviewed (S)
                        then
                           Result := Editor.Commands.Unavailable
                             (Editor.Commands.Reason_Close_Review_Stale);
                           return;
                        end if;
                     end if;

                     if Current.File_Backed_Count = 0 then
                        Result := Editor.Commands.Unavailable
                          ("Save As required before saving this buffer");
                        return;
                     end if;
                  end;
               else
                  declare
                     Target : constant Editor.Buffers.Buffer_Id :=
                       Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
                  begin
                     if Target = Editor.Buffers.No_Buffer
                       or else not Editor.Buffers.Global_Contains (Target)
                     then
                        Result := Editor.Commands.Unavailable
                          ("Selected buffer is no longer open");
                        return;
                     else
                        declare
                           Summary : constant Editor.Buffers.Buffer_Summary :=
                             Editor.Buffers.Global_Summary_For (Target);
                        begin
                           if not Summary.Is_Dirty then
                              Result := Editor.Commands.Available;
                              return;
                           elsif not Summary.Has_Path then
                              Result := Editor.Commands.Unavailable
                                ("Save As required before saving this buffer");
                              return;
                           end if;
                        end;
                     end if;
                  end;
               end if;
               return;

            when Command_Confirm_Close_Discard =>
               if S.Dirty_Close_Prompt_All_Buffers then
                  if Editor.Buffers.Global_Count = 0 then
                     Result := Editor.Commands.Unavailable ("No buffers open");
                     return;
                  elsif not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_All_Buffer_Review_Current (S) then
                     if not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_All_Buffer_Identity_Current (S)
                       or else not Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Close_Current_Dirty_Set_Was_Reviewed (S)
                     then
                        Result := Editor.Commands.Unavailable
                          (Editor.Commands.Reason_Close_Review_Stale);
                        return;
                     end if;
                  end if;
               else
                  declare
                     Target : constant Editor.Buffers.Buffer_Id :=
                       Editor.Buffers.Buffer_Id (S.Dirty_Close_Prompt_Buffer);
                  begin
                     if Target = Editor.Buffers.No_Buffer
                       or else not Editor.Buffers.Global_Contains (Target)
                     then
                        Result := Editor.Commands.Unavailable
                          ("Selected buffer is no longer open");
                        return;
                     end if;
                  end;
               end if;
               return;

            when Command_Cancel_Close
               | Command_Cancel =>
               return;
            when No_Command =>
               Result := Editor.Commands.Unavailable ("No command");
               return;
            when others =>
               Result := Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
               return;
         end case;
      end if;

      if S.File_Conflict_Prompt_Active then
         case Id is
            when Command_File_Conflict_Overwrite_Disk =>
               if not S.File_Conflict_Prompt_Dirty then
                  Result := Editor.Commands.Unavailable ("Buffer is not dirty");
               end if;
               return;
            when Command_File_Conflict_Keep_Buffer
               | Command_File_Conflict_Reload_From_Disk
               | Command_File_Conflict_Cancel
               | Command_Cancel =>
               return;
            when No_Command =>
               Result := Editor.Commands.Unavailable ("No command");
               return;
            when others =>
               Result := Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
               return;
         end case;
      end if;

      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         if Editor.Executor.File_Lifecycle_Confirmation_Pending (S) then
            case Id is
               when Command_Save_File
                  | Command_Save_File_As
                  | Command_Save_All
                  | Command_Open_File
                  | Command_Accept_Quick_Open
                  | Command_Quick_Open_Create_From_Query
                  | Command_Quick_Open_Create_With_Parents_From_Query
                  | Command_Accept_Buffer_Switcher
                  | Command_Buffer_Switcher_Selected_Close
                  | Command_Buffer_Switcher_Mark_Close_Marked
                  | Command_Next_Buffer
                  | Command_Previous_Buffer
                  | Command_Next_Recent_Buffer
                  | Command_Previous_Recent_Buffer
                  | Command_Switch_Buffer
                  | Command_File_Tree_Open_Selected
                  | Command_File_Tree_Create_File
                  | Command_File_Tree_Create_Directory
                  | Command_File_Tree_Rename_Selected
                  | Command_File_Tree_Delete_Selected
                  | Command_Close_All_Clean_Buffers
                  | Command_Rename_Buffer_File
                  | Command_Delete_Buffer_File
                  | Command_Copy_Buffer_File
                  | Command_Move_Buffer_File
                  | Command_Insert_Newline
                  | Command_Undo
                  | Command_Redo
                  | Command_Edit_History_Clear
                  | Command_Cut
                  | Command_Paste
                  | Command_Selection_Delete
                  | Command_Line_Delete
                  | Command_Line_Duplicate
                  | Command_Line_Move_Up
                  | Command_Line_Move_Down
                  | Command_Indent_Increase
                  | Command_Indent_Decrease
                  | Command_Comment_Line
                  | Command_Uncomment_Line
                  | Command_Toggle_Line_Comment
                  | Command_Line_Join_Next
                  | Command_Line_Split_At_Caret
                  | Command_Trim_Trailing_Whitespace
                  | Command_Format_Buffer
                  | Command_Format_Selected_Text
                  | Command_Char_Delete_Previous
                  | Command_Char_Delete_Next
                  | Command_Word_Delete_Previous
                  | Command_Word_Delete_Next
                  | Command_Replace_Current
                  | Command_Replace_All =>
                  Result := Editor.Commands.Unavailable
                    ("Command unavailable while confirmation is pending");
                  return;
               when others =>
                  null;
            end case;
         end if;

         case Id is
            when Command_Close_All_Buffers
               | Command_Close_Other_Buffers
               | Command_Reload_Active_Buffer
               | Command_Revert_Active_Buffer
               | Command_Close_Active_Buffer
               | Command_Open_Project
               | Command_Switch_Project
               | Command_Open_Selected_Recent_Project
               | Command_Close_Project
               | Command_Clear_Project
               | Command_Restore_Workspace_State
               | Command_Project_Search_Replace_Preview
               | Command_Project_Search_Replace_Toggle_Selected
               | Command_Project_Search_Replace_Include_Selected
               | Command_Project_Search_Replace_Exclude_Selected
               | Command_Project_Search_Replace_Include_File
               | Command_Project_Search_Replace_Exclude_File
               | Command_Project_Search_Replace_Include_All
               | Command_Project_Search_Replace_Exclude_All
               | Command_Project_Search_Replace_Selected
               | Command_Project_Search_Replace_All_Included =>
               Result := Editor.Commands.Unavailable
                 ("Command unavailable while confirmation is pending");
               return;
            when others =>
               null;
         end case;
      end if;

      case Id is
         when Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close =>
            if S.Dirty_Close_Prompt_Active then
               Result := Editor.Commands.Available;
            else
               Result := Editor.Commands.Unavailable
                 ("No close confirmation pending");
            end if;
            return;

         when Command_Cancel_Pending_Transition
            | Command_Retry_Pending_Transition
            | Command_Discard_Pending_Transition =>
            if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
               Result := Editor.Commands.Unavailable
                 (Editor.Dirty_Guards.No_Pending_Transition_Message);
               return;
            end if;
            if Id = Command_Discard_Pending_Transition then
               declare
                  Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
                    Editor.Pending_Transitions.Target (S.Pending_Transitions);
               begin
                  if Target.Kind in Editor.Pending_Transitions.Pending_Reload_Active_Buffer
                      | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
                  then
                     Result := Editor.Commands.Unavailable
                       ("Reload/revert requires its own explicit confirmation");
                     return;
                  end if;
               end;
            end if;
            return;

         when Command_Save_File =>
            declare
               Active_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Active_Buffer;
               Effective_File : Editor.State.File_State := S.File_Info;
               Effective_Has_Buffer : Boolean := Has_Buffer (S);
            begin
               if Editor.Buffers.Global_Registry_Current_For (S)
                 and then Editor.Buffers.Global_Count > 0
                 and then Active_Id /= Editor.Buffers.No_Buffer
                 and then S.Active_Buffer_Token /= Natural (Active_Id)
               then
                  if not Editor.Buffers.Global_Contains (Active_Id) then
                     Result := Editor.Commands.Unavailable ("No active buffer.");
                     return;
                  end if;

                  Effective_File :=
                    Editor.Buffers.Buffer
                      (Editor.Buffers.Global_Registry_For_UI, Active_Id).File_Info;
                  Effective_Has_Buffer := True;
               end if;

               if not Effective_Has_Buffer then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
               elsif not Effective_File.Has_Path
                 or else Length (Effective_File.Path) = 0
               then
                  Result := Editor.Commands.Unavailable
                    ("No file path for active buffer");
               end if;
               return;
            end;

         when Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel =>
            if not S.File_Conflict_Prompt_Active then
               Result := Editor.Commands.Unavailable ("No active file conflict");
            end if;
            return;

         when Command_Reload_Active_Buffer =>
            declare
               Active_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Active_Buffer;
               Effective_File : Editor.State.File_State := S.File_Info;
               Effective_Has_Buffer : Boolean := Has_Buffer (S);
            begin
               if Editor.Buffers.Global_Count = 0
                 or else Active_Id = Editor.Buffers.No_Buffer
               then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
                  return;
               end if;

               if S.Active_Buffer_Token /= Natural (Active_Id) then
                  if not Editor.Buffers.Global_Contains (Active_Id) then
                     Result := Editor.Commands.Unavailable ("No active buffer.");
                     return;
                  end if;

                  Effective_File :=
                    Editor.Buffers.Buffer
                      (Editor.Buffers.Global_Registry_For_UI, Active_Id).File_Info;
                  Effective_Has_Buffer := True;
               end if;

               if not Effective_Has_Buffer then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
               elsif not Effective_File.Has_Path
                 or else Length (Effective_File.Path) = 0
               then
                  Result := Editor.Commands.Unavailable
                    ("No file path for active buffer");
               elsif Effective_File.Dirty then
                  Result := Editor.Commands.Unavailable
                    ("Dirty buffer cannot be reloaded");
               end if;
               return;
            end;

         when Command_Revert_Active_Buffer =>
            declare
               Active_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Active_Buffer;
               Effective_File : Editor.State.File_State := S.File_Info;
               Effective_Has_Buffer : Boolean := Has_Buffer (S);
            begin
               if Editor.Buffers.Global_Count = 0
                 or else Active_Id = Editor.Buffers.No_Buffer
               then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
                  return;
               end if;

               if S.Active_Buffer_Token /= Natural (Active_Id) then
                  if not Editor.Buffers.Global_Contains (Active_Id) then
                     Result := Editor.Commands.Unavailable ("No active buffer.");
                     return;
                  end if;

                  Effective_File :=
                    Editor.Buffers.Buffer
                      (Editor.Buffers.Global_Registry_For_UI, Active_Id).File_Info;
                  Effective_Has_Buffer := True;
               end if;

               if not Effective_Has_Buffer then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
               elsif not Effective_File.Has_Path
                 or else Length (Effective_File.Path) = 0
               then
                  Result := Editor.Commands.Unavailable
                    ("No file path for active buffer");
               elsif not Effective_File.Dirty then
                  Result := Editor.Commands.Unavailable
                    ("No changes to revert");
               end if;
               return;
            end;

         when Command_Rename_Buffer_File =>
            Result := Associated_File_Operation_Availability
              (S, "Dirty buffer file cannot be renamed");
            return;

         when Command_Delete_Buffer_File =>
            Result := Associated_File_Operation_Availability
              (S, "Dirty buffer file cannot be deleted");
            return;

         when Command_Copy_Buffer_File =>
            Result := Associated_File_Operation_Availability
              (S, "Dirty buffer file cannot be copied");
            return;

         when Command_Move_Buffer_File =>
            Result := Associated_File_Operation_Availability
              (S, "Dirty buffer file cannot be moved");
            return;

         when Command_Save_File_As =>
            if Editor.Buffers.Global_Count = 0
              or else Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
            then
               Result := Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return;

         when Command_Save_All =>
            if Editor.Buffers.Global_Dirty_File_Backed_Buffer_Count = 0
              and then not (S.File_Info.Dirty and then S.File_Info.Has_Path)
            then
               Result := Editor.Commands.Unavailable
                 (Editor.Dirty_Guards.No_Dirty_File_Backed_Buffers_Message);
            end if;
            return;

         when Command_Close_All_Buffers =>
            if Editor.Buffers.Global_Count = 0 then
               Result := Editor.Commands.Unavailable ("No buffers to close");
            end if;
            return;

         when Command_Close_All_Clean_Buffers =>
            if Editor.Buffers.Global_Unpinned_Clean_Buffer_Count = 0 then
               Result := Editor.Commands.Unavailable
                 (Editor.Dirty_Guards.No_Clean_Buffers_Message);
            end if;
            return;

         when Command_Reopen_Closed_Buffer =>
            if S.Has_Reopen_Candidate and then Length (S.Reopen_Candidate_Path) > 0 then
               Result := Editor.Commands.Available;
            else
               Result := Editor.Commands.Unavailable ("No closed buffer to reopen");
            end if;
            return;

         when Command_Close_Active_Buffer =>
            declare
               Active_Id : constant Editor.Buffers.Buffer_Id :=
                 Editor.Buffers.Global_Active_Buffer;
            begin
               if Editor.Buffers.Global_Count = 0
                 or else Active_Id = Editor.Buffers.No_Buffer
               then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
                  return;
               elsif S.Active_Buffer_Token /= Natural (Active_Id)
                 and then not Editor.Buffers.Global_Contains (Active_Id)
               then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
                  return;
               elsif not Has_Buffer (S)
                 and then S.Active_Buffer_Token = Natural (Active_Id)
               then
                  Result := Editor.Commands.Unavailable ("No active buffer.");
                  return;
               end if;
            end;
            return;

         when Command_Close_Other_Buffers =>
            if Editor.Buffers.Global_Count = 0 then
               Result := Editor.Commands.Unavailable ("No active buffer.");
            elsif not Has_Buffer (S) then
               Result := Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return;

         when others =>
            Handled := False;
            return;
      end case;
   end Lifecycle_Command_Availability;

   function Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      Handled : Boolean := False;
      Result  : Editor.Commands.Command_Availability :=
        Editor.Commands.Available;
   begin
      Lifecycle_Command_Availability (S, Id, Handled, Result);
      if Handled then
         return Result;
      end if;
      return Editor.Commands.Unavailable
        ("Command is not a file lifecycle command");
   end Lifecycle_Command_Availability;

   function Execute_Lifecycle_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Save_All =>
            Editor.Executor.File_Save_Basic_Commands.Execute_Save_All (S);

         when Command_File_Conflict_Keep_Buffer =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Keep_Buffer (S);

         when Command_File_Conflict_Reload_From_Disk =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Reload_From_Disk (S);

         when Command_File_Conflict_Overwrite_Disk =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Overwrite_Disk (S);

         when Command_File_Conflict_Cancel =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Cancel (S);

         when Command_Close_Other_Buffers =>
            Editor.Executor.Buffer_Close_Commands.Execute_Close_Other_Buffers (S);

         when Command_Close_All_Buffers =>
            Editor.Executor.Buffer_Close_Commands.Execute_Close_All_Buffers (S);

         when Command_Confirm_Close_Save =>
            Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Confirm_Close_Save (S);

         when Command_Confirm_Close_Discard =>
            Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Confirm_Close_Discard (S);

         when Command_Cancel_Close =>
            Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Cancel_Close (S);

         when Command_Close_All_Clean_Buffers =>
            Editor.Executor.Buffer_Close_Commands.Execute_Close_All_Clean_Buffers (S);

         when Command_Reopen_Closed_Buffer =>
            Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);

         when Command_Cancel_Pending_Transition =>
            Editor.Executor.File_Save_Commands.Execute_Cancel_Pending_Transition (S);

         when Command_Retry_Pending_Transition =>
            Editor.Executor.File_Save_Commands.Execute_Retry_Pending_Transition (S);

         when Command_Discard_Pending_Transition =>
            Editor.Executor.Buffer_Close_Commands.Execute_Discard_Pending_Transition (S);

         when others =>
            raise Program_Error with "unsupported lifecycle result command";
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (S, Id, Before_Messages);
   end Execute_Lifecycle_Result_Command;

   procedure Execute_Lifecycle_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Save_File =>
            Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

         when Save_File_As =>
            Editor.Executor.File_Save_Basic_Commands.Execute_Save_As
              (S, To_String (Cmd.Path));

         when Save_All =>
            Editor.Executor.File_Save_Basic_Commands.Execute_Save_All (S);

         when Reload_Active_Buffer =>
            Editor.Executor.File_Save_Basic_Commands
              .Execute_Reload_Active_Buffer (S);

         when Revert_Active_Buffer =>
            Editor.Executor.File_Save_Basic_Commands
              .Execute_Revert_Active_Buffer (S);

         when Rename_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File
              (S, To_String (Cmd.Path));

         when Delete_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File
              (S);

         when Copy_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File
              (S, To_String (Cmd.Path));

         when Move_Buffer_File =>
            Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File
              (S, To_String (Cmd.Path));

         when File_Conflict_Keep_Buffer =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Keep_Buffer (S);

         when File_Conflict_Reload_From_Disk =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Reload_From_Disk (S);

         when File_Conflict_Overwrite_Disk =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Overwrite_Disk (S);

         when File_Conflict_Cancel =>
            Editor.Executor.File_Conflict_Commands.Execute_File_Conflict_Cancel (S);

         when Cancel_Pending_Transition =>
            Editor.Executor.File_Save_Commands.Execute_Cancel_Pending_Transition (S);

         when Retry_Pending_Transition =>
            Editor.Executor.File_Save_Commands.Execute_Retry_Pending_Transition (S);

         when others =>
            raise Program_Error with "unsupported lifecycle command kind";
      end case;
   end Execute_Lifecycle_Kind;

   procedure Report_Info_Raw
     (S    : in out Editor.State.State_Type;
      Text : String)
   is
      Config : Editor.Messages.Message_Config;
   begin
      Editor.Messages.Push_Info
        (S.Messages, Text, Editor.Executor.Shared_Services.Current_Message_Time_Ms, Config);
   end Report_Info_Raw;

   function Active_File_External_Status
     (S : Editor.State.State_Type) return Editor.Files.File_External_Change_Status is
   begin
      return Editor.Executor.File_Save_Commands.Active_File_External_Status (S);
   end Active_File_External_Status;

   function External_Status_Code
     (Status : Editor.Files.File_External_Change_Status) return Natural is
   begin
      return Editor.Executor.File_Save_Commands.External_Status_Code (Status);
   end External_Status_Code;

   function Pending_File_State_Still_Current
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return Boolean is
   begin
      return Editor.Executor.File_Save_Commands.Pending_File_State_Still_Current (Target);
   end Pending_File_State_Still_Current;

end Editor.Executor.File_Lifecycle_Commands;
