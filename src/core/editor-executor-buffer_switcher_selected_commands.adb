with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Feature_Messages;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Recent_Buffers;
with Editor.Render_Cache;

package body Editor.Executor.Buffer_Switcher_Selected_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Messages.Message_Severity;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_No_Selected_Switcher_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      Report_Info (S, "No selected buffer");
   end Report_No_Selected_Switcher_Buffer;

   function Active_Buffer_Switcher_Overlay
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Overlay_Focus.Is_Active
        (S.Overlay_Focus, Editor.Overlay_Focus.Buffer_Switcher_Overlay)
        and then Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher);
   end Active_Buffer_Switcher_Overlay;

   function Selected_Row
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
   begin
      return Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer
        (S, Found);
   end Selected_Row;

   function Selected_Open_Buffer_Availability
     (S : Editor.State.State_Type) return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      end if;

      Row := Selected_Row (S, Found);
      if not Found then
         return Editor.Commands.Unavailable ("No buffer selected");
      elsif Row.Id = Editor.Buffers.No_Buffer then
         return Editor.Commands.Unavailable ("Selected row is not a buffer");
      elsif not Editor.Buffers.Global_Contains (Row.Id) then
         return Editor.Commands.Unavailable ("Selected buffer is no longer open");
      end if;

      return Editor.Commands.Available;
   end Selected_Open_Buffer_Availability;

   procedure Execute_Buffer_Switcher_Selected_Close
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Name           : Unbounded_String := Null_Unbounded_String;
      Closed         : Boolean := False;
      Closed_Active  : Boolean := False;
   begin
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Buffers.Global_Contains (Row.Id) then
         Report_No_Selected_Switcher_Buffer (S);
         Editor.Executor.Buffer_Switcher_Shared
           .Recompute_Buffer_Switcher_After_Selected_Action
             (S, Editor.Buffers.No_Buffer, Fallback_Index);
         return;
      end if;

      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      if Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, Row.Id)
      then
         Editor.Buffers.Global_Set_Blocked_Close_Surfaced (Row.Id);
         if Row.Id = Editor.Buffers.Global_Active_Buffer then
            S.File_Info.Blocked_Close_Surfaced := True;
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
         declare
            Summary : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Global_Summary_For (Row.Id);
            Dirty_Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
              (Dirty_Count       => 1,
               Untitled_Count    => (if Summary.Has_Path then 0 else 1),
               File_Backed_Count => (if Summary.Has_Path then 1 else 0));
         begin
            Editor.Executor.Start_Dirty_Close_Prompt
              (S, Editor.State.Selected_Buffer_Close_Scope, False, Row.Id,
               Dirty_Summary);
         end;
         Editor.Executor.Buffer_Switcher_Shared
           .Recompute_Buffer_Switcher_After_Selected_Action
             (S, Row.Id, Fallback_Index);
         return;
      end if;

      Closed_Active := Row.Id = Editor.Buffers.Global_Active_Buffer;
      Editor.Buffers.Global_Close_Buffer (Row.Id, Closed);
      if Closed then
         Editor.Recent_Buffers.Remove (S.Recent_Buffers, Natural (Row.Id));
         Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
           (S, Natural (Row.Id));
         if Closed_Active then
            Editor.Feature_Messages.Reset_For_Buffer_Close
              (S.Feature_Messages,
               Editor.Executor.Active_Feature_Buffer_Token (S));
            Editor.Feature_Search_Results.Reset_For_Buffer_Close
              (S.Feature_Search_Results,
               Editor.Executor.Active_Feature_Buffer_Token (S));
            Editor.Feature_Panel_Controller.Rebuild_Active_Feature_Projection
              (S);
         end if;
         if Editor.Buffers.Global_Count = 0
           or else Editor.Buffers.Global_Active_Buffer =
             Editor.Buffers.No_Buffer
         then
            S.Active_Buffer_Token := 0;
         else
            Editor.Buffers.Load_Global_Active_Into_State (S);
         end if;
         Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
         Report_Info (S, "Closed " & To_String (Name));
         Editor.Executor.Buffer_Switcher_Shared
           .Recompute_Buffer_Switcher_After_Selected_Action
             (S, Editor.Buffers.No_Buffer, Fallback_Index);
      else
         Editor.Executor.Shared_Services.Report_Warning
           (S, "Close blocked: " & To_String (Name) &
             " has unsaved changes");
         Editor.Executor.Buffer_Switcher_Shared
           .Recompute_Buffer_Switcher_After_Selected_Action
             (S, Row.Id, Fallback_Index);
      end if;
   end Execute_Buffer_Switcher_Selected_Close;

   procedure Ensure_Selected_Open_Buffer
     (S              : in out Editor.State.State_Type;
      Row            : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Found          : Boolean;
      Fallback_Index : Natural;
      Available      : out Boolean)
   is
   begin
      Available := False;
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_No_Selected_Switcher_Buffer (S);
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      if not Editor.Buffers.Global_Contains (Row.Id) then
         Report_No_Selected_Switcher_Buffer (S);
         Editor.Executor.Buffer_Switcher_Shared
           .Recompute_Buffer_Switcher_After_Selected_Action
             (S, Editor.Buffers.No_Buffer, Fallback_Index);
         return;
      end if;

      Available := True;
   end Ensure_Selected_Open_Buffer;

   procedure Execute_Buffer_Switcher_Selected_Pin
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Name           : Unbounded_String := Null_Unbounded_String;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Pin_Buffer (Row.Id);
      Editor.Executor.Shared_Services.Report_Success (S, "Pinned " & To_String (Name));
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Pin;

   procedure Execute_Buffer_Switcher_Selected_Unpin
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Name           : Unbounded_String := Null_Unbounded_String;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Unpin_Buffer (Row.Id);
      Editor.Executor.Shared_Services.Report_Success (S, "Unpinned " & To_String (Name));
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Unpin;

   procedure Execute_Buffer_Switcher_Selected_Toggle_Pin
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Name           : Unbounded_String := Null_Unbounded_String;
      Was_Pinned     : Boolean := False;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      Was_Pinned := Editor.Buffers.Global_Is_Buffer_Pinned (Row.Id);
      Editor.Buffers.Global_Toggle_Buffer_Pin (Row.Id);
      if Was_Pinned then
         Editor.Executor.Shared_Services.Report_Success (S, "Unpinned " & To_String (Name));
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Pinned " & To_String (Name));
      end if;
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Toggle_Pin;

   procedure Execute_Buffer_Switcher_Selected_Group_Assign
     (S    : in out Editor.State.State_Type;
      Name : String)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Group          : constant String :=
        Editor.Executor.Trimmed_Command_Text (Name);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      if Group'Length = 0 then
         Report_Info (S, "No group name");
         return;
      end if;
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Assign_Buffer_Group (Row.Id, Group);
      Editor.Executor.Shared_Services.Report_Success
        (S, "Assigned " & To_String (Display) & " to group " & Group);
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Group_Assign;

   procedure Execute_Buffer_Switcher_Selected_Group_Clear
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Clear_Buffer_Group (Row.Id);
      Editor.Executor.Shared_Services.Report_Success
        (S, "Cleared group for " & To_String (Display));
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Group_Clear;

   procedure Execute_Buffer_Switcher_Selected_Label_Set
     (S     : in out Editor.State.State_Type;
      Label : String)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Text           : constant String :=
        Editor.Executor.Trimmed_Command_Text (Label);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      if Text'Length > Editor.Buffers.Max_Buffer_Label_Length then
         Report_Info (S, "Label too long");
         return;
      elsif not Editor.Executor.Valid_Buffer_Label_Text (Text) then
         Report_Info (S, "Invalid label");
         return;
      end if;
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      if Text'Length = 0 then
         Editor.Buffers.Global_Clear_Buffer_Label (Row.Id);
         Editor.Executor.Shared_Services.Report_Success
           (S, "Label cleared for " & To_String (Display));
      else
         Editor.Buffers.Global_Set_Buffer_Label (Row.Id, Text);
         Editor.Executor.Shared_Services.Report_Success
           (S, "Label set for " & To_String (Display) & ": " & Text);
      end if;
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Label_Set;

   procedure Execute_Buffer_Switcher_Selected_Label_Clear
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Clear_Buffer_Label (Row.Id);
      Editor.Executor.Shared_Services.Report_Success
        (S, "Label cleared for " & To_String (Display));
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Label_Clear;

   procedure Execute_Buffer_Switcher_Selected_Note_Set
     (S    : in out Editor.State.State_Type;
      Note : String)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Text           : constant String :=
        Editor.Executor.Trimmed_Command_Text (Note);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      if Text'Length > Editor.Buffers.Max_Buffer_Note_Length then
         Report_Info (S, "Note too long");
         return;
      end if;
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      if Text'Length = 0 then
         Editor.Buffers.Global_Clear_Buffer_Note (Row.Id);
         Editor.Executor.Shared_Services.Report_Success
           (S, "Note cleared for " & To_String (Display));
      else
         Editor.Buffers.Global_Set_Buffer_Note (Row.Id, Text);
         Editor.Executor.Shared_Services.Report_Success
           (S, "Note set for " & To_String (Display));
      end if;
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Note_Set;

   procedure Execute_Buffer_Switcher_Selected_Note_Clear
     (S : in out Editor.State.State_Type)
   is
      Found          : Boolean := False;
      Row            : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Row (S, Found);
      Fallback_Index : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Available      : Boolean := False;
      Display        : Unbounded_String := Null_Unbounded_String;
   begin
      Ensure_Selected_Open_Buffer (S, Row, Found, Fallback_Index, Available);
      if not Available then
         return;
      end if;
      Display := To_Unbounded_String
        (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Global_Clear_Buffer_Note (Row.Id);
      Editor.Executor.Shared_Services.Report_Success
        (S, "Note cleared for " & To_String (Display));
      Editor.Executor.Buffer_Switcher_Shared
        .Recompute_Buffer_Switcher_After_Selected_Action
          (S, Row.Id, Fallback_Index);
   end Execute_Buffer_Switcher_Selected_Note_Clear;

   function Buffer_Switcher_Selected_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Selected_Close
            | Editor.Commands.Command_Buffer_Switcher_Selected_Toggle_Pin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign
            | Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set
            | Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set =>
            return Selected_Open_Buffer_Availability (S);

         when Editor.Commands.Command_Buffer_Switcher_Selected_Pin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Unpin
            | Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear
            | Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear
            | Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear =>
            declare
               Availability : constant Editor.Commands.Command_Availability :=
                 Selected_Open_Buffer_Availability (S);
            begin
               if Availability.Status /= Editor.Commands.Command_Available then
                  return Availability;
               end if;
            end;

            Row := Selected_Row (S, Found);
            if Id = Editor.Commands.Command_Buffer_Switcher_Selected_Pin
              and then Found
              and then Row.Is_Pinned
            then
               return Editor.Commands.Unavailable ("Buffer already pinned");
            elsif Id = Editor.Commands.Command_Buffer_Switcher_Selected_Unpin
              and then Found
              and then not Row.Is_Pinned
            then
               return Editor.Commands.Unavailable ("Buffer is not pinned");
            elsif Id = Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear
              and then Found
              and then not Row.Has_Group
            then
               return Editor.Commands.Unavailable ("Buffer has no group");
            elsif Id = Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear
              and then Found
              and then not Row.Has_Label
            then
               return Editor.Commands.Unavailable ("Buffer has no label");
            elsif Id = Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear
              and then Found
              and then not Row.Has_Note
            then
               return Editor.Commands.Unavailable ("Buffer has no note");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Not a buffer switcher selected-row command");
      end case;
   end Buffer_Switcher_Selected_Command_Availability;

   procedure Execute_Buffer_Switcher_Selected_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind;
      Text : String)
   is
   begin
      case Kind is
         when Editor.Commands.Buffer_Switcher_Selected_Close =>
            Execute_Buffer_Switcher_Selected_Close (S);
         when Editor.Commands.Buffer_Switcher_Selected_Pin =>
            Execute_Buffer_Switcher_Selected_Pin (S);
         when Editor.Commands.Buffer_Switcher_Selected_Unpin =>
            Execute_Buffer_Switcher_Selected_Unpin (S);
         when Editor.Commands.Buffer_Switcher_Selected_Toggle_Pin =>
            Execute_Buffer_Switcher_Selected_Toggle_Pin (S);
         when Editor.Commands.Buffer_Switcher_Selected_Group_Assign =>
            Execute_Buffer_Switcher_Selected_Group_Assign (S, Text);
         when Editor.Commands.Buffer_Switcher_Selected_Group_Clear =>
            Execute_Buffer_Switcher_Selected_Group_Clear (S);
         when Editor.Commands.Buffer_Switcher_Selected_Label_Set =>
            Execute_Buffer_Switcher_Selected_Label_Set (S, Text);
         when Editor.Commands.Buffer_Switcher_Selected_Label_Clear =>
            Execute_Buffer_Switcher_Selected_Label_Clear (S);
         when Editor.Commands.Buffer_Switcher_Selected_Note_Set =>
            Execute_Buffer_Switcher_Selected_Note_Set (S, Text);
         when Editor.Commands.Buffer_Switcher_Selected_Note_Clear =>
            Execute_Buffer_Switcher_Selected_Note_Clear (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Selected_Kind;

   function Execute_Buffer_Switcher_Selected_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Before_Messages : constant Natural := Editor.Messages.Count (S.Messages);

      function Result_After_Command
        (Command : Editor.Commands.Command_Id)
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
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Selected_Close =>
            Execute_Buffer_Switcher_Selected_Close (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Pin =>
            Execute_Buffer_Switcher_Selected_Pin (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Unpin =>
            Execute_Buffer_Switcher_Selected_Unpin (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Toggle_Pin =>
            Execute_Buffer_Switcher_Selected_Toggle_Pin (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Group_Assign =>
            Report_Info (S, "No group name");
         when Editor.Commands.Command_Buffer_Switcher_Selected_Group_Clear =>
            Execute_Buffer_Switcher_Selected_Group_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Label_Set =>
            Report_Info (S, "No label text");
         when Editor.Commands.Command_Buffer_Switcher_Selected_Label_Clear =>
            Execute_Buffer_Switcher_Selected_Label_Clear (S);
         when Editor.Commands.Command_Buffer_Switcher_Selected_Note_Set =>
            Report_Info (S, "No note text");
         when Editor.Commands.Command_Buffer_Switcher_Selected_Note_Clear =>
            Execute_Buffer_Switcher_Selected_Note_Clear (S);
         when others =>
            return Editor.Command_Execution.No_Op (Id);
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (Id);
   end Execute_Buffer_Switcher_Selected_Command;

end Editor.Executor.Buffer_Switcher_Selected_Commands;
