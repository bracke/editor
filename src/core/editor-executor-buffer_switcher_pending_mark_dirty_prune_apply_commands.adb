with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffers;
with Editor.Buffer_Switcher;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Shared_Services;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands is

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
   is
   begin
      return Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
   end Selected_Switcher_Buffer;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
     (S : in out Editor.State.State_Type)
   is
      Applied   : Natural := 0;
      Remaining : Natural := 0;
      Fallback  : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Apply_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Applied, Remaining);

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Applied = 0 then
         Report_Info (S, "No applicable dirty-prune targets");
      else
         Report_Success
           (S, "Pruned" & Natural'Image (Applied) & " dirty pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
     (S : in out Editor.State.State_Type)
   is
      Applied    : Natural := 0;
      Skipped    : Natural := 0;
      Remaining  : Natural := 0;
      Applicable : Natural := 0;
      Fallback   : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      if Applicable = 0 then
         Report_Info (S, "No applicable dirty-prune apply targets");
         return;
      end if;
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Applied, Skipped, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Applied = 0 then
         Report_Info (S, "No applicable dirty-prune apply targets");
      elsif Skipped > 0 then
         Report_Success
           (S, "Pruned" & Natural'Image (Applied)
            & " dirty-prune apply targets; skipped" & Natural'Image (Skipped));
      else
         Report_Success
           (S, "Pruned" & Natural'Image (Applied)
            & " dirty-prune apply targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffer_Switcher.Cancel_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Report_Info (S, "Dirty-prune apply cancelled");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
     (S : in out Editor.State.State_Type)
   is
      Count      : Natural := 0;
      Applicable : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
        (S.Buffer_Switcher);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Report_Info
        (S, "Dirty-prune apply targets:" & Natural'Image (Count)
         & ";" & Natural'Image (Applicable) & " still applicable");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Prune_Apply_Target
        (S.Buffer_Switcher)
      then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected next dirty-prune apply target");
      else
         Report_Info (S, "No dirty-prune apply targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Prune_Apply_Target
        (S.Buffer_Switcher)
      then
         Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Selected previous dirty-prune apply target");
      else
         Report_Info (S, "No dirty-prune apply targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Found     : Boolean := False;
      Row       : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Removed   : Boolean := False;
      Remaining : Natural := 0;
      Fallback  : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Row := Selected_Switcher_Buffer (S, Found);
      if not Found
        or else not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target
          (S.Buffer_Switcher, Row.Id)
      then
         Report_Info (S, "Selected buffer is not a dirty-prune apply target");
         return;
      end if;
      Fallback := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Row.Id, Removed, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Remaining = 0 then
         Report_Info (S, "Removed " & To_String (Row.Display_Label)
           & " from dirty-prune apply; no pending dirty-prune apply confirmation");
      else
         Report_Success
           (S, "Removed " & To_String (Row.Display_Label) & " from dirty-prune apply");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
     (S : in out Editor.State.State_Type)
   is
      Restored  : Boolean := False;
      Target    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name      : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Fallback  : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No removed dirty-prune apply targets");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Restored, Target, Name, Remaining);
      if not Restored then
         Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Selected_Action (S, Target, Fallback);
      Report_Success (S, "Restored " & To_String (Name) & " to dirty-prune apply");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
     (S : in out Editor.State.State_Type)
   is
      Cleared   : Natural := 0;
      Remaining : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher)
      then
         Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Cleared, Remaining);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      if Cleared = 0 then
         Report_Info (S, "No stale dirty-prune apply targets");
      else
         Report_Info (S, "Cleared" & Natural'Image (Cleared) & " stale dirty-prune apply target");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale;

end Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands;
