with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Commands;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Shared_Services;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Commands.Command_Kind;

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

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Summary (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Next (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Previous (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary (S);
         when others =>
            null;
      end case;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Kind;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Summary
     (S : in out Editor.State.State_Type)
   is
      Pending_Open : Natural := 0;
      Dirty_Open   : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Pending_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Dirty_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      if Dirty_Open = 0 then
         Report_Info (S, "No dirty pending close targets");
      else
         Report_Info
           (S, "Dirty pending close targets:" & Natural'Image (Dirty_Open)
            & " of" & Natural'Image (Pending_Open));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected next dirty pending close target");
      else
         Report_Info (S, "No dirty pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected previous dirty pending close target");
      else
         Report_Info (S, "No dirty pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Found     : Boolean := False;
      Row       : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Removed   : Boolean := False;
      Remaining : Natural := 0;
      Dirty_Remaining : Natural := 0;
      Fallback  : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Name      : Unbounded_String := Null_Unbounded_String;
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
         Report_Info (S, "No selected dirty pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, Row.Id)
      then
         Report_Info (S, "Selected pending close target is not dirty");
         return;
      end if;

      Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
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
         Dirty_Remaining := Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
         Report_Success
           (S, "Removed dirty pending close target " & To_String (Name)
            & "; pending close now has" & Natural'Image (Remaining)
            & " targets; Dirty:" & Natural'Image (Dirty_Remaining));
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
     (S : in out Editor.State.State_Type)
   is
      Count        : Natural := 0;
      Pending_Open : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count);

      if Count = 0 then
         Report_Info (S, "No dirty pending close targets");
      else
         Pending_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Count
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
         Report_Info
           (S, "Dirty prune prepared:" & Natural'Image (Count)
            & " of" & Natural'Image (Pending_Open) & " pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
     (S : in out Editor.State.State_Type)
   is
      Captured   : Natural := 0;
      Applicable : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Captured := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Report_Info
        (S, "Dirty prune preview targets:" & Natural'Image (Captured)
         & ";" & Natural'Image (Applicable) & " still applicable");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Prune_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected next dirty-prune preview target");
      else
         Report_Info (S, "No dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Prune_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected previous dirty-prune preview target");
      else
         Report_Info (S, "No dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
     (S : in out Editor.State.State_Type)
   is
      Was_Active : constant Boolean :=
        Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);

      if Was_Active then
         Report_Info (S, "Dirty-prune preview review already shown");
      else
         Report_Success (S, "Dirty-prune preview review shown");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
     (S : in out Editor.State.State_Type)
   is
      Was_Active : constant Boolean :=
        Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher);
   begin
      if not Was_Active then
         Report_Info (S, "Dirty-prune preview review already hidden");
         return;
      end if;

      Editor.Buffer_Switcher.Hide_Dirty_Prune_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Report_Success (S, "Dirty-prune preview review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      if Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S.Buffer_Switcher) then
         Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide (S);
      else
         Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show (S);
      end if;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffer_Switcher.Cancel_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Report_Info (S, "Dirty prune cancelled");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Found      : Boolean := False;
      Row        : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Removed    : Boolean := False;
      Remaining  : Natural := 0;
      Applicable : Natural := 0;
      Fallback   : Natural := 0;
      Name       : Unbounded_String := Null_Unbounded_String;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Row := Selected_Switcher_Buffer (S, Found);
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Report_Info (S, "No selected dirty-prune preview target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Report_Info (S, "Selected buffer is not a dirty-prune preview target");
         return;
      end if;

      Fallback := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Name := Row.Display_Label;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI,
         Row.Id, Removed, Remaining);

      if not Removed then
         Report_Info (S, "Selected buffer is not a dirty-prune preview target");
         return;
      end if;

      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);

      if Remaining = 0 then
         Report_Info (S, "Removed " & To_String (Name) & " from dirty-prune preview; no pending dirty-prune action");
      else
         Report_Success
           (S, "Removed " & To_String (Name)
            & " from dirty-prune preview; Dirty prune preview now has"
            & Natural'Image (Remaining) & " targets;"
            & Natural'Image (Applicable) & " still applicable");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
     (S : in out Editor.State.State_Type)
   is
      Removed : Natural := 0;
      Opened  : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
        and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
          (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Removed := Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Opened := Editor.Buffer_Switcher.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      if Removed = 0 then
         Report_Info (S, "No removed dirty-prune preview targets");
      else
         Report_Info
           (S, "Removed dirty-prune preview targets:" & Natural'Image (Removed)
            & ";" & Natural'Image (Opened) & " still open");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
        and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
          (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Next_Removed_Dirty_Prune_Target (S.Buffer_Switcher) then
         Report_Info (S, "Selected next removed dirty-prune preview target");
      else
         Report_Info (S, "No open removed dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher)
        and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
          (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Previous_Removed_Dirty_Prune_Target (S.Buffer_Switcher) then
         Report_Info (S, "Selected previous removed dirty-prune preview target");
      else
         Report_Info (S, "No open removed dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
     (S : in out Editor.State.State_Type)
   is
      Cleared   : Natural := 0;
      Remaining : Natural := 0;
      Fallback  : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Buffer_Switcher.Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI)
      then
         Report_Info (S, "No stale dirty-prune preview targets");
         return;
      end if;

      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Cleared, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      Normalize_Switcher_Preview_Target (S);

      if Remaining = 0 then
         Report_Info (S, "Dirty-prune preview cleared");
      else
         Report_Success
           (S, "Cleared" & Natural'Image (Cleared)
            & " stale dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary
     (S : in out Editor.State.State_Type)
   is
      Captured : Natural := 0;
      Stale    : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Captured := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Stale := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Report_Info
        (S, "Dirty-prune stale targets:" & Natural'Image (Stale)
         & " of" & Natural'Image (Captured));
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
     (S : in out Editor.State.State_Type)
   is
      Restored   : Boolean := False;
      Target     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name       : Unbounded_String := Null_Unbounded_String;
      Remaining  : Natural := 0;
      Fallback   : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
        (S.Buffer_Switcher)
      then
         if Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
            Report_Info (S, "No removed dirty-prune preview targets");
         else
            Report_Info (S, "No pending dirty-prune action");
         end if;
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI,
         Restored, Target, Name, Remaining);

      if not Restored then
         Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Target, Fallback);
      Report_Success (S, "Restored " & To_String (Name) & " to dirty-prune preview");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed;

end Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands;
