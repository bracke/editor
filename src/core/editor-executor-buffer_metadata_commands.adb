with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Navigation_Commands;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Buffer_Metadata_Commands is

   use Editor.Commands;
   use type Editor.Buffers.Buffer_Id;

   function Buffer_Metadata_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      function Has_Buffer return Boolean is
      begin
         return Editor.State.Has_Active_Buffer (S);
      end Has_Buffer;
   begin
      case Id is
         when Command_Pin_Buffer =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif Editor.Buffers.Global_Is_Buffer_Pinned
              (Editor.Buffers.Global_Active_Buffer)
            then
               return Editor.Commands.Unavailable ("Buffer already pinned");
            end if;
            return Editor.Commands.Available;

         when Command_Unpin_Buffer =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Is_Buffer_Pinned
              (Editor.Buffers.Global_Active_Buffer)
            then
               return Editor.Commands.Unavailable ("Buffer is not pinned");
            end if;
            return Editor.Commands.Available;

         when Command_Toggle_Buffer_Pin
            | Command_Set_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note
            | Command_Assign_Buffer_Group =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Buffer_Label =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Has_Buffer_Label
              (Editor.Buffers.Global_Active_Buffer)
            then
               return Editor.Commands.Unavailable ("Active buffer has no label");
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Buffer_Note =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Has_Buffer_Note
              (Editor.Buffers.Global_Active_Buffer)
            then
               return Editor.Commands.Unavailable ("Active buffer has no note");
            end if;
            return Editor.Commands.Available;

         when Command_Clear_Buffer_Group =>
            if not Has_Buffer then
               return Editor.Commands.Unavailable ("No active buffer.");
            elsif not Editor.Buffers.Global_Has_Buffer_Group
              (Editor.Buffers.Global_Active_Buffer)
            then
               return Editor.Commands.Unavailable ("Active buffer has no group");
            end if;
            return Editor.Commands.Available;

         when Command_Switch_Buffer_Group =>
            if not Editor.Buffers.Global_Has_Buffer_Groups then
               return Editor.Commands.Unavailable ("No buffer groups");
            end if;
            return Editor.Commands.Available;

         when Command_Show_All_Buffer_Groups =>
            if not Editor.Buffers.Global_Has_Active_Buffer_Group then
               return Editor.Commands.Unavailable ("No active buffer group");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a buffer metadata command");
      end case;
   end Buffer_Metadata_Command_Availability;

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

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   function Trimmed_Command_Text (Text : String) return String
      renames Editor.Executor.Trimmed_Command_Text;

   procedure Execute_Pin_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
         return;
      end if;
      Editor.Buffers.Global_Pin_Buffer (Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Report_Success (S, "Pinned " & Editor.Buffers.Global_Display_Name (Id));
   end Execute_Pin_Buffer;

   procedure Execute_Unpin_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
         return;
      end if;
      Editor.Buffers.Global_Unpin_Buffer (Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Report_Success (S, "Unpinned " & Editor.Buffers.Global_Display_Name (Id));
   end Execute_Unpin_Buffer;

   procedure Execute_Toggle_Buffer_Pin
     (S : in out Editor.State.State_Type)
   is
      Id         : Editor.Buffers.Buffer_Id;
      Was_Pinned : Boolean := False;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
         return;
      end if;
      Was_Pinned := Editor.Buffers.Global_Is_Buffer_Pinned (Id);
      Editor.Buffers.Global_Toggle_Buffer_Pin (Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      if Was_Pinned then
         Report_Success (S, "Unpinned " & Editor.Buffers.Global_Display_Name (Id));
      else
         Report_Success (S, "Pinned " & Editor.Buffers.Global_Display_Name (Id));
      end if;
   end Execute_Toggle_Buffer_Pin;

   function Valid_Buffer_Label_Text (Text : String) return Boolean is
   begin
      for C of Text loop
         if C = Character'Val (10) or else C = Character'Val (13) then
            return False;
         elsif Character'Pos (C) < 32 or else Character'Pos (C) = 127 then
            return False;
         elsif not ((C >= 'a' and then C <= 'z')
                    or else (C >= 'A' and then C <= 'Z')
                    or else (C >= '0' and then C <= '9')
                    or else C = ' '
                    or else C = '-'
                    or else C = '_'
                    or else C = '.')
         then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Buffer_Label_Text;

   procedure Execute_Set_Buffer_Label
     (S : in out Editor.State.State_Type; Label : String)
   is
      Id : Editor.Buffers.Buffer_Id;
      Text : constant String := Trimmed_Command_Text (Label);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif Text'Length > Editor.Buffers.Max_Buffer_Label_Length then
         Report_Info (S, "Label too long");
      elsif Text'Length = 0 then
         Editor.Buffers.Global_Clear_Buffer_Label (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Label cleared for " & Editor.Buffers.Global_Display_Name (Id));
      elsif not Valid_Buffer_Label_Text (Text) then
         Report_Info (S, "Invalid label");
      else
         Editor.Buffers.Global_Set_Buffer_Label (Id, Text);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Label set for " & Editor.Buffers.Global_Display_Name (Id) & ": " & Text);
      end if;
   end Execute_Set_Buffer_Label;

   procedure Execute_Clear_Buffer_Label
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif not Editor.Buffers.Global_Has_Buffer_Label (Id) then
         Report_Info (S, "No label for " & Editor.Buffers.Global_Display_Name (Id));
      else
         Editor.Buffers.Global_Clear_Buffer_Label (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Label cleared for " & Editor.Buffers.Global_Display_Name (Id));
      end if;
   end Execute_Clear_Buffer_Label;

   procedure Execute_Show_Buffer_Label
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif not Editor.Buffers.Global_Has_Buffer_Label (Id) then
         Report_Info (S, "No label for " & Editor.Buffers.Global_Display_Name (Id));
      else
         Report_Info (S, Editor.Buffers.Global_Display_Name (Id) & " label: " & Editor.Buffers.Global_Buffer_Label (Id));
      end if;
   end Execute_Show_Buffer_Label;

   procedure Execute_Set_Buffer_Note
     (S : in out Editor.State.State_Type; Note : String)
   is
      Id : Editor.Buffers.Buffer_Id;
      Text : constant String := Trimmed_Command_Text (Note);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif Text'Length > Editor.Buffers.Max_Buffer_Note_Length then
         Report_Info (S, "Note too long");
      elsif Text'Length = 0 then
         Editor.Buffers.Global_Clear_Buffer_Note (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Note cleared for " & Editor.Buffers.Global_Display_Name (Id));
      else
         Editor.Buffers.Global_Set_Buffer_Note (Id, Text);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Note set for " & Editor.Buffers.Global_Display_Name (Id));
      end if;
   end Execute_Set_Buffer_Note;

   procedure Execute_Clear_Buffer_Note
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif not Editor.Buffers.Global_Has_Buffer_Note (Id) then
         Report_Info (S, "No note for " & Editor.Buffers.Global_Display_Name (Id));
      else
         Editor.Buffers.Global_Clear_Buffer_Note (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Note cleared for " & Editor.Buffers.Global_Display_Name (Id));
      end if;
   end Execute_Clear_Buffer_Note;

   procedure Execute_Show_Buffer_Note
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif not Editor.Buffers.Global_Has_Buffer_Note (Id) then
         Report_Info (S, "No note for " & Editor.Buffers.Global_Display_Name (Id));
      else
         Report_Info (S, Editor.Buffers.Global_Display_Name (Id) & ": " & Editor.Buffers.Global_Buffer_Note (Id));
      end if;
   end Execute_Show_Buffer_Note;

   procedure Execute_Assign_Buffer_Group
     (S : in out Editor.State.State_Type; Name : String)
   is
      Id : Editor.Buffers.Buffer_Id;
      Group : constant String := Trimmed_Command_Text (Name);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif Group'Length = 0 then
         Report_Info (S, "No group name");
      else
         Editor.Buffers.Global_Assign_Buffer_Group (Id, Group);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Assigned " & Editor.Buffers.Global_Display_Name (Id) & " to group " & Group);
      end if;
   end Execute_Assign_Buffer_Group;

   procedure Execute_Clear_Buffer_Group
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Id := Editor.Buffers.Global_Active_Buffer;
      if Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No active buffer.");
      elsif not Editor.Buffers.Global_Has_Buffer_Group (Id) then
         Report_Info (S, "Active buffer has no group");
      else
         Editor.Buffers.Global_Clear_Buffer_Group (Id);
         Editor.Buffers.Load_Global_Active_Into_State (S);
         Report_Success (S, "Removed " & Editor.Buffers.Global_Display_Name (Id) & " from group");
      end if;
   end Execute_Clear_Buffer_Group;

   procedure Activate_First_Buffer_In_Active_Group
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      if Editor.Buffers.Global_Has_Active_Buffer_Group then
         Target := Editor.Buffers.Global_First_Buffer_In_Group
           (Editor.Buffers.Global_Active_Buffer_Group);
         if Target /= Editor.Buffers.No_Buffer then
            Editor.Buffers.Global_Set_Active_Buffer (Target);
            Editor.Buffers.Load_Global_Active_Into_State (S);
         end if;
      end if;
   end Activate_First_Buffer_In_Active_Group;

   procedure Execute_Switch_Buffer_Group
     (S : in out Editor.State.State_Type; Name : String)
   is
      Group : constant String := Trimmed_Command_Text (Name);
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      if Group'Length = 0 then
         Report_Info (S, "No group name");
      elsif not Editor.Buffers.Global_Has_Buffer_Groups then
         Report_Info (S, "No buffer groups");
      else
         Editor.Buffers.Global_Set_Active_Buffer_Group (Group);
         if Editor.Buffers.Global_Has_Active_Buffer_Group
           and then Editor.Buffers.Global_Active_Buffer_Group = Group
         then
            Activate_First_Buffer_In_Active_Group (S);
            Report_Success (S, "Active group: " & Group);
         else
            Report_Info (S, "No buffer group " & Group);
         end if;
      end if;
   end Execute_Switch_Buffer_Group;

   procedure Execute_Show_All_Buffer_Groups
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Editor.Buffers.Global_Has_Active_Buffer_Group then
         Report_Info (S, "No active buffer group");
      else
         Editor.Buffers.Global_Clear_Active_Buffer_Group;
         Report_Success (S, "Showing all buffers");
      end if;
   end Execute_Show_All_Buffer_Groups;

   function Execute_Buffer_Metadata_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);
   begin
      case Id is
         when Command_Pin_Buffer =>
            Execute_Pin_Buffer (S);

         when Command_Unpin_Buffer =>
            Execute_Unpin_Buffer (S);

         when Command_Toggle_Buffer_Pin =>
            Execute_Toggle_Buffer_Pin (S);

         when Command_Set_Buffer_Label
            | Command_Edit_Buffer_Label =>
            Report_Info (S, "No label text");

         when Command_Clear_Buffer_Label =>
            Execute_Clear_Buffer_Label (S);

         when Command_Show_Buffer_Label =>
            Execute_Show_Buffer_Label (S);

         when Command_Set_Buffer_Note
            | Command_Edit_Buffer_Note =>
            Report_Info (S, "No note text");

         when Command_Clear_Buffer_Note =>
            Execute_Clear_Buffer_Note (S);

         when Command_Show_Buffer_Note =>
            Execute_Show_Buffer_Note (S);

         when Command_Assign_Buffer_Group =>
            Report_Info (S, "No group name");

         when Command_Clear_Buffer_Group =>
            Execute_Clear_Buffer_Group (S);

         when Command_Switch_Buffer_Group =>
            Report_Info (S, "No group name");

         when Command_Next_Buffer_Group =>
            Editor.Executor.Buffer_Navigation_Commands
              .Execute_Next_Buffer_Group (S);

         when Command_Previous_Buffer_Group =>
            Editor.Executor.Buffer_Navigation_Commands
              .Execute_Previous_Buffer_Group (S);

         when Command_Show_All_Buffer_Groups =>
            Execute_Show_All_Buffer_Groups (S);

         when others =>
            raise Program_Error with "unsupported buffer metadata result command";
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (S, Id, Before_Messages);
   end Execute_Buffer_Metadata_Result_Command;

end Editor.Executor.Buffer_Metadata_Commands;
