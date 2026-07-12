with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Shared_Services;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands is

   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Buffers.Buffer_Id;

   procedure Report_Info
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Info;

   procedure Report_Success
     (S    : in out Editor.State.State_Type;
      Text : String) renames Editor.Executor.Shared_Services.Report_Success;

   procedure Recompute_Buffer_Switcher
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher;

   procedure Normalize_Switcher_Preview_Target
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target;

   procedure Recompute_Buffer_Switcher_After_Selected_Action
     (S              : in out Editor.State.State_Type;
      Preferred_Id   : Editor.Buffers.Buffer_Id;
      Fallback_Index : Natural)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Selected_Action;

   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
      renames Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer;

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, 1);
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Report_Info (S, "No pending marked targets remain open");
      else
         Report_Success (S, "Pending marked review shown");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Review_Show;

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S,
         Editor.Buffers.No_Buffer,
         Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher));
      Report_Success (S, "Pending marked review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Review_Hide;

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Has_Pending_Marked_Review (S.Buffer_Switcher) then
         Execute_Buffer_Switcher_Pending_Mark_Review_Hide (S);
      else
         Execute_Buffer_Switcher_Pending_Mark_Review_Show (S);
      end if;
   end Execute_Buffer_Switcher_Pending_Mark_Review_Toggle;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary
     (S : in out Editor.State.State_Type)
   is
      Pruned_Count : Natural := 0;
      Open_Count : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pruned pending close targets");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Pruned_Count := Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher);
      Open_Count := Editor.Buffer_Switcher.Open_Pruned_Pending_Marked_Close_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Report_Info
        (S, "Pruned pending close targets:" & Natural'Image (Pruned_Count)
         & ";" & Natural'Image (Open_Count) & " still open");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pruned pending close targets");
      elsif Editor.Buffer_Switcher.Select_Next_Pruned_Pending_Marked_Buffer
        (S.Buffer_Switcher)
      then
         Report_Success (S, "Selected next pruned pending close target");
      else
         Report_Info (S, "No open pruned pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pruned pending close targets");
      elsif Editor.Buffer_Switcher.Select_Previous_Pruned_Pending_Marked_Buffer
        (S.Buffer_Switcher)
      then
         Report_Success (S, "Selected previous pruned pending close target");
      else
         Report_Info (S, "No open pruned pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Show_Pruned_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Report_Success (S, "Pruned pending review shown");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Pruned_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Report_Success (S, "Pruned pending review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review
        (S.Buffer_Switcher)
      then
         Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide (S);
      else
         Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show (S);
      end if;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle;

   procedure Execute_Buffer_Switcher_Pending_Mark_Summary
     (S : in out Editor.State.State_Type)
   is
      Captured_Count : constant Natural :=
        Editor.Buffer_Switcher.Pending_Marked_Target_Count (S.Buffer_Switcher);
      Open_Count : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Open_Count := Editor.Buffer_Switcher.Pending_Marked_Open_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Report_Info
        (S, "Pending marked close:" & Natural'Image (Captured_Count)
         & " targets;" & Natural'Image (Open_Count) & " still open");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Next_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected next pending close target");
      else
         Report_Info (S, "No pending marked targets remain open");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Previous_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected previous pending close target");
      else
         Report_Info (S, "No pending marked targets remain open");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Found    : Boolean := False;
      Row      : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Switcher_Buffer (S, Found);
      Removed  : Boolean := False;
      Remaining : Natural := 0;
      Fallback : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Name     : Unbounded_String := Null_Unbounded_String;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Row.Id)
      then
         Report_Info (S, "No selected pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Row.Id,
         Removed,
         Remaining);

      if not Removed then
         Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Remaining = 0 then
         Report_Info (S, "No pending marked targets remain");
      else
         Report_Success
           (S, "Removed " & To_String (Name) & " from pending close; pending close now has"
            & Natural'Image (Remaining) & " targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Remove_Selected;

   procedure Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
     (S : in out Editor.State.State_Type)
   is
      Restored  : Boolean := False;
      Target    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name      : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Fallback  : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets (S.Buffer_Switcher) then
         Report_Info (S, "No pruned pending close targets");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Last_Pruned_Pending_Marked_Close_Target
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Restored,
         Target,
         Name,
         Remaining);

      if not Restored then
         if Length (Name) = 0 then
            Name := To_Unbounded_String
              (Editor.Buffer_Switcher.Last_Pruned_Pending_Marked_Close_Target_Name (S.Buffer_Switcher));
         end if;
         Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action (S, Target, Fallback);
      if Remaining = 1 then
         Report_Success (S, "Restored 1 pending close target");
      else
         Report_Success (S, "Restored " & To_String (Name) & " to pending close");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned;

   procedure Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
     (S : in out Editor.State.State_Type)
   is
      Found    : Boolean := False;
      Row      : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Selected_Switcher_Buffer (S, Found);
      Restored : Boolean := False;
      Remaining : Natural := 0;
      Name     : Unbounded_String := Null_Unbounded_String;
      Fallback : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Row.Id)
      then
         Report_Info (S, "No selected pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Report_Info (S, "Selected buffer is not a pruned pending close target");
         return;
      end if;

      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Pruned_Pending_Marked_Close_Target
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         Row.Id,
         Restored,
         Name,
         Remaining);

      if not Restored then
         Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action (S, Row.Id, Fallback);
      Report_Success (S, "Restored " & To_String (Name) & " to pending close");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned;

end Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands;
