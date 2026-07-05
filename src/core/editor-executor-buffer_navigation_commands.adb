with Editor.Buffers;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.File_Open_Commands;
with Editor.Recent_Buffers;
with Editor.State;

package body Editor.Executor.Buffer_Navigation_Commands is

   use Editor.Commands;
   use type Editor.Buffers.Buffer_Id;

   function Buffer_Navigation_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group =>
            if not Editor.Buffers.Global_Has_Buffer_Groups then
               return Editor.Commands.Unavailable ("No buffer groups");
            end if;
            return Editor.Commands.Available;

         when Command_Next_Buffer | Command_Previous_Buffer =>
            if Editor.Buffers.Global_Count = 0 then
               return Editor.Commands.Unavailable ("No open buffers");
            elsif Editor.Buffers.Global_Count = 1 then
               return Editor.Commands.Unavailable ("Only one buffer open");
            end if;
            return Editor.Commands.Available;

         when Command_Previous_Recent_Buffer =>
            if Editor.Buffers.Global_Count < 2 then
               return Editor.Commands.Unavailable ("No previous buffer");
            elsif not Editor.Recent_Buffers.Has_Previous
              (S.Recent_Buffers,
               Natural (Editor.Buffers.Global_Active_Buffer))
            then
               return Editor.Commands.Unavailable ("No previous buffer");
            end if;
            return Editor.Commands.Available;

         when Command_Next_Recent_Buffer =>
            if Editor.Buffers.Global_Count < 2 then
               return Editor.Commands.Unavailable ("No next buffer");
            elsif not Editor.Recent_Buffers.Has_Next (S.Recent_Buffers) then
               return Editor.Commands.Unavailable ("No next buffer");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Command is not a buffer navigation command");
      end case;
   end Buffer_Navigation_Command_Availability;

   procedure Clear_Restore_Feedback_Current
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Clear_Restore_Feedback_Current;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Execute_Switch_Buffer
     (S                : in out Editor.State.State_Type;
      Id               : Editor.Buffers.Buffer_Id;
      Recent_Traversal : Boolean := False;
      Emit_Feedback    : Boolean := True)
      renames Editor.Executor.File_Open_Commands.Execute_Switch_Buffer;

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

   procedure Execute_Next_Buffer_Group
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Editor.Buffers.Global_Has_Buffer_Groups then
         Report_Info (S, "No buffer groups");
      else
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Buffers.Global_Cycle_Active_Buffer_Group (True);
         Activate_First_Buffer_In_Active_Group (S);
         Report_Success (S, "Active group: " & Editor.Buffers.Global_Active_Buffer_Group);
      end if;
   end Execute_Next_Buffer_Group;

   procedure Execute_Previous_Buffer_Group
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      if not Editor.Buffers.Global_Has_Buffer_Groups then
         Report_Info (S, "No buffer groups");
      else
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Buffers.Global_Cycle_Active_Buffer_Group (False);
         Activate_First_Buffer_In_Active_Group (S);
         Report_Success (S, "Active group: " & Editor.Buffers.Global_Active_Buffer_Group);
      end if;
   end Execute_Previous_Buffer_Group;

   procedure Execute_Next_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      --  Direct buffer navigation must continue as normal use.
      Clear_Restore_Feedback_Current (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      if Editor.Buffers.Global_Count = 0 then
         Report_Info (S, "No open buffers");
         return;
      elsif Editor.Buffers.Global_Count = 1 then
         Report_Info (S, "Only one buffer open");
         return;
      end if;
      Id := Editor.Buffers.Global_Next_Buffer;
      if Id /= Editor.Buffers.No_Buffer then
         Execute_Switch_Buffer (S, Id);
      end if;
   end Execute_Next_Buffer;

   procedure Execute_Previous_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id : Editor.Buffers.Buffer_Id;
   begin
      --  Direct buffer navigation must continue as normal use.
      Clear_Restore_Feedback_Current (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      if Editor.Buffers.Global_Count = 0 then
         Report_Info (S, "No open buffers");
         return;
      elsif Editor.Buffers.Global_Count = 1 then
         Report_Info (S, "Only one buffer open");
         return;
      end if;
      Id := Editor.Buffers.Global_Previous_Buffer;
      if Id /= Editor.Buffers.No_Buffer then
         Execute_Switch_Buffer (S, Id);
      end if;
   end Execute_Previous_Buffer;

   procedure Execute_Previous_Recent_Buffer
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Recent_Buffers.Buffer_Key := Editor.Recent_Buffers.No_Buffer_Key;
      Active : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Attempts : Natural := 0;
      Limit : Natural := 0;
   begin
      Clear_Restore_Feedback_Current (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Active := Editor.Buffers.Global_Active_Buffer;
      Limit := Editor.Buffers.Global_Count + Editor.Recent_Buffers.Count (S.Recent_Buffers) + 1;

      if Editor.Buffers.Global_Count < 2 then
         Report_Info (S, "Buffer: no previous buffer");
         return;
      end if;

      loop
         Target := Editor.Recent_Buffers.Previous_Target
           (S.Recent_Buffers, Natural (Active));
         exit when Target = Editor.Recent_Buffers.No_Buffer_Key;
         exit when Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target))
           and then Editor.Buffers.Buffer_Id (Target) /= Active;
         Editor.Recent_Buffers.Remove (S.Recent_Buffers, Target);
         Attempts := Attempts + 1;
         exit when Attempts > Limit;
      end loop;

      if Target = Editor.Recent_Buffers.No_Buffer_Key
        or else not Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target))
        or else Editor.Buffers.Buffer_Id (Target) = Active
      then
         Report_Info (S, "Buffer: no previous buffer");
         return;
      end if;

      Execute_Switch_Buffer
        (S, Editor.Buffers.Buffer_Id (Target),
         Recent_Traversal => True,
         Emit_Feedback    => False);
      Report_Info (S, "Buffer: previous");
   end Execute_Previous_Recent_Buffer;

   procedure Execute_Next_Recent_Buffer
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Recent_Buffers.Buffer_Key := Editor.Recent_Buffers.No_Buffer_Key;
      Active : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Attempts : Natural := 0;
      Limit : Natural := 0;
   begin
      Clear_Restore_Feedback_Current (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Active := Editor.Buffers.Global_Active_Buffer;
      Limit := Editor.Buffers.Global_Count + Editor.Recent_Buffers.Count (S.Recent_Buffers) + 1;

      if Editor.Buffers.Global_Count < 2 then
         Report_Info (S, "Buffer: no next buffer");
         return;
      end if;

      loop
         Target := Editor.Recent_Buffers.Next_Target (S.Recent_Buffers);
         exit when Target = Editor.Recent_Buffers.No_Buffer_Key;
         exit when Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target))
           and then Editor.Buffers.Buffer_Id (Target) /= Active;
         Editor.Recent_Buffers.Remove (S.Recent_Buffers, Target);
         Attempts := Attempts + 1;
         exit when Attempts > Limit;
      end loop;

      if Target = Editor.Recent_Buffers.No_Buffer_Key
        or else not Editor.Buffers.Global_Contains (Editor.Buffers.Buffer_Id (Target))
        or else Editor.Buffers.Buffer_Id (Target) = Active
      then
         Report_Info (S, "Buffer: no next buffer");
         return;
      end if;

      Execute_Switch_Buffer
        (S, Editor.Buffers.Buffer_Id (Target),
         Recent_Traversal => True,
         Emit_Feedback    => False);
      Report_Info (S, "Buffer: next");
   end Execute_Next_Recent_Buffer;

   procedure Execute_Buffer_Navigation_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Next_Buffer_Group =>
            Execute_Next_Buffer_Group (S);

         when Previous_Buffer_Group =>
            Execute_Previous_Buffer_Group (S);

         when Next_Buffer =>
            Execute_Next_Buffer (S);

         when Previous_Buffer =>
            Execute_Previous_Buffer (S);

         when Previous_Recent_Buffer =>
            Execute_Previous_Recent_Buffer (S);

         when Next_Recent_Buffer =>
            Execute_Next_Recent_Buffer (S);

         when Switch_Buffer =>
            Execute_Switch_Buffer (S, Editor.Buffers.Buffer_Id (Cmd.Buffer_Id));

         when others =>
            raise Program_Error with "unsupported buffer navigation command kind";
      end case;
   end Execute_Buffer_Navigation_Kind;

end Editor.Executor.Buffer_Navigation_Commands;
