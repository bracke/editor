with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Messages;
with Editor.Overlay_Focus;
with Editor.Render_Cache;

package body Editor.Executor.Buffer_Switcher_Pending_Mark_Commands is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Buffer_Switcher.Pending_Marked_Action_Kind;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Kind;
   use type Editor.Messages.Message_Severity;

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

   procedure Recompute_Buffer_Switcher_After_Marked_Action
     (S : in out Editor.State.State_Type)
      renames Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher_After_Marked_Action;

   function Selected_Switcher_Buffer
     (S     : Editor.State.State_Type;
      Found : out Boolean) return Editor.Buffer_Switcher.Buffer_Switcher_Row
      renames Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer;

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

   function Selected_Pending_Close_Target_Availability
     (S              : Editor.State.State_Type;
      Required_Dirty : Boolean := False;
      Required_Pruned : Boolean := False)
      return Editor.Commands.Command_Availability
   is
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      if not Active_Buffer_Switcher_Overlay (S) then
         return Editor.Commands.Unavailable ("No active overlay");
      elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         return Editor.Commands.Unavailable ("No pending marked action");
      end if;

      Row := Selected_Row (S, Found);
      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Row.Id)
      then
         if Required_Dirty then
            return Editor.Commands.Unavailable
              ("No selected dirty pending close target");
         elsif Required_Pruned then
            return Editor.Commands.Unavailable
              ("No selected pruned pending close target");
         else
            return Editor.Commands.Unavailable
              ("No selected pending close target");
         end if;
      elsif not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         return Editor.Commands.Unavailable
           ("Selected buffer is not a pending close target");
      elsif Required_Dirty
        and then not Editor.Buffers.Is_Dirty
          (Editor.Buffers.Global_Registry_For_UI, Row.Id)
      then
         return Editor.Commands.Unavailable
           ("Selected pending close target is not dirty");
      elsif Required_Pruned
        and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target
          (S.Buffer_Switcher, Row.Id)
      then
         return Editor.Commands.Unavailable
           ("Selected buffer is not a pruned pending close target");
      end if;

      return Editor.Commands.Available;
   end Selected_Pending_Close_Target_Availability;

   function Buffer_Switcher_Pending_Mark_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability
   is
   begin
      case Id is
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            return Selected_Pending_Close_Target_Availability (S);

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            return Selected_Pending_Close_Target_Availability
              (S, Required_Dirty => True);

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            return Selected_Pending_Close_Target_Availability
              (S, Required_Pruned => True);

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            elsif not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pruned pending close targets");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Previous =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            elsif Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
               return Editor.Commands.Unavailable
                 ("No pending marked targets remain open");
            end if;
            for I in 1 .. Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) loop
               if Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target
                 (S.Buffer_Switcher,
                  Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, I).Id)
               then
                  return Editor.Commands.Available;
               end if;
            end loop;
            return Editor.Commands.Unavailable
              ("No pending marked targets remain open");

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            end if;
            for I in 1 .. Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) loop
               declare
                  Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
                    Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, I);
               begin
                  if Row.Is_Dirty
                    and then Editor.Buffer_Switcher.Row_Is_Pending_Marked_Target
                      (S.Buffer_Switcher, Row.Id)
                  then
                     return Editor.Commands.Available;
                  end if;
               end;
            end loop;
            return Editor.Commands.Unavailable
              ("No dirty pending close targets");

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
              Editor.Buffer_Switcher.Pending_Marked_Close
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            elsif Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
              (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 0
            then
               return Editor.Commands.Unavailable
                 ("No dirty pending close targets");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune apply confirmation");
            elsif Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
              (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI) = 0
            then
               return Editor.Commands.Unavailable
                 ("No applicable dirty-prune apply targets");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply
              (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets
                (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune apply confirmation");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Prune_Review
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("Dirty-prune preview review is not active");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            else
               declare
                  Found : Boolean := False;
                  Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
                    Selected_Row (S, Found);
               begin
                  if not Found or else Row.Id = Editor.Buffers.No_Buffer then
                     return Editor.Commands.Unavailable
                       ("No selected dirty-prune preview target");
                  elsif not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target
                    (S.Buffer_Switcher, Row.Id)
                  then
                     return Editor.Commands.Unavailable
                       ("Selected buffer is not a dirty-prune preview target");
                  end if;
               end;
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
              (S.Buffer_Switcher)
            then
               if Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
                 (S.Buffer_Switcher)
               then
                  return Editor.Commands.Unavailable
                    ("No removed dirty-prune preview targets");
               else
                  return Editor.Commands.Unavailable
                    ("No pending dirty-prune action");
               end if;
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
                (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets
              (S.Buffer_Switcher)
            then
               if Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
                 (S.Buffer_Switcher)
               then
                  return Editor.Commands.Unavailable
                    ("No open removed dirty-prune preview targets");
               else
                  return Editor.Commands.Unavailable
                    ("No pending dirty-prune action");
               end if;
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            elsif not Editor.Buffer_Switcher.Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
              (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI)
            then
               return Editor.Commands.Unavailable
                 ("No stale dirty-prune preview targets");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pending dirty-prune action");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
              Editor.Buffer_Switcher.No_Pending_Marked_Action
            then
               return Editor.Commands.Unavailable ("No pending marked action");
            elsif not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("No pruned pending close targets");
            elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Next
              or else Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            then
               for I in 1 .. Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) loop
                  if Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target
                    (S.Buffer_Switcher,
                     Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, I).Id)
                  then
                     return Editor.Commands.Available;
                  end if;
               end loop;
               return Editor.Commands.Unavailable
                 ("No open pruned pending close targets");
            end if;
            return Editor.Commands.Available;

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            if not Active_Buffer_Switcher_Overlay (S) then
               return Editor.Commands.Unavailable ("No active overlay");
            elsif not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review
              (S.Buffer_Switcher)
            then
               return Editor.Commands.Unavailable
                 ("Pruned pending review not active");
            end if;
            return Editor.Commands.Available;

         when others =>
            return Editor.Commands.Unavailable
              ("Not a buffer switcher pending mark command");
      end case;
   end Buffer_Switcher_Pending_Mark_Command_Availability;

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, 1);
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked targets remain open");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Pending marked review shown");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Review_Show;

   procedure Execute_Buffer_Switcher_Pending_Mark_Review_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Pending marked review hidden");
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

   procedure Execute_Buffer_Switcher_Pending_Mark_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Next_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected next pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked targets remain open");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Previous_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected previous pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked targets remain open");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Previous;


   procedure Execute_Buffer_Switcher_Pending_Mark_Remove_Selected
     (S : in out Editor.State.State_Type)
   is
      Found    : Boolean := False;
      Row      : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Removed  : Boolean := False;
      Remaining : Natural := 0;
      Fallback : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Name     : Unbounded_String := Null_Unbounded_String;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No selected pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a pending close target");
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
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      if Remaining = 0 then
         Recompute_Buffer_Switcher_After_Selected_Action
           (S, Editor.Buffers.No_Buffer, Fallback);
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked targets remain");
      else
         Recompute_Buffer_Switcher_After_Selected_Action
           (S, Editor.Buffers.No_Buffer, Fallback);
         Editor.Executor.Shared_Services.Report_Success
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Close_Targets (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pruned pending close targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action (S, Target, Fallback);
      if Remaining = 1 then
         Editor.Executor.Shared_Services.Report_Success (S, "Restored 1 pending close target");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Restored " & To_String (Name) & " to pending close");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary
     (S : in out Editor.State.State_Type)
   is
      Pruned_Count : Natural := 0;
      Open_Count   : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Pruned_Count := Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S.Buffer_Switcher);
      Open_Count := Editor.Buffer_Switcher.Open_Pruned_Pending_Marked_Close_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      if Pruned_Count = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No pruned pending close targets");
      else
         Editor.Executor.Shared_Services.Report_Info
           (S, "Pruned pending close targets:" & Natural'Image (Pruned_Count)
            & ";" & Natural'Image (Open_Count) & " still open");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary;


   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Next_Pruned_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected next pruned pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No open pruned pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Previous_Pruned_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected previous pruned pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No open pruned pending close targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffer_Switcher.Show_Pruned_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, 1);
      if Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No open pruned pending close targets");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Pruned pending review shown");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Buffer_Switcher.Hide_Pruned_Pending_Marked_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher_After_Marked_Action (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Pruned pending review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide;

   procedure Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S.Buffer_Switcher) then
         Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide (S);
      else
         Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show (S);
      end if;
   end Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle;

   procedure Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
     (S : in out Editor.State.State_Type)
   is
      Found     : Boolean := False;
      Row       : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Restored  : Boolean := False;
      Name      : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Fallback  : constant Natural := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) /=
        Editor.Buffer_Switcher.Pending_Marked_Close
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No selected pruned pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a pruned pending close target");
         return;
      end if;

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
         if Length (Name) = 0 then
            Name := To_Unbounded_String (Editor.Buffers.Global_Display_Name (Row.Id));
         end if;
         Editor.Executor.Shared_Services.Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action (S, Row.Id, Fallback);
      Editor.Executor.Shared_Services.Report_Success (S, "Restored " & To_String (Name) & " to pending close");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned;


   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Summary
     (S : in out Editor.State.State_Type)
   is
      Pending_Open : Natural := 0;
      Dirty_Open   : Natural := 0;
   begin
      if Editor.Buffer_Switcher.Pending_Marked_Action (S.Buffer_Switcher) =
        Editor.Buffer_Switcher.No_Pending_Marked_Action
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Pending_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Dirty_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      if Dirty_Open = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty pending close targets");
      else
         Editor.Executor.Shared_Services.Report_Info
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected next dirty pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty pending close targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Pending_Marked_Buffer (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected previous dirty pending close target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty pending close targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      if not Found
        or else Row.Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No selected dirty pending close target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected pending close target is not dirty");
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
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a pending close target");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);

      if Remaining = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked targets remain");
      else
         Dirty_Remaining := Editor.Buffer_Switcher.Pending_Marked_Open_Dirty_Count
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
         Editor.Executor.Shared_Services.Report_Success
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count);

      if Count = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty pending close targets");
      else
         Pending_Open := Editor.Buffer_Switcher.Pending_Marked_Open_Count
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
         Editor.Executor.Shared_Services.Report_Info
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Captured := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Editor.Executor.Shared_Services.Report_Info
        (S, "Dirty prune preview targets:" & Natural'Image (Captured)
         & ";" & Natural'Image (Applicable) & " still applicable");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Prune_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected next dirty-prune preview target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty-prune preview targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Prune_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected previous dirty-prune preview target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty-prune preview targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);

      if Was_Active then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty-prune preview review already shown");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Dirty-prune preview review shown");
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
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty-prune preview review already hidden");
         return;
      end if;

      Editor.Buffer_Switcher.Hide_Dirty_Prune_Review (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Editor.Executor.Shared_Services.Report_Success (S, "Dirty-prune preview review hidden");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffer_Switcher.Cancel_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Editor.Executor.Shared_Services.Report_Info (S, "Dirty prune cancelled");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Row := Selected_Switcher_Buffer (S, Found);
      if not Found or else Row.Id = Editor.Buffers.No_Buffer then
         Editor.Executor.Shared_Services.Report_Info (S, "No selected dirty-prune preview target");
         return;
      end if;

      if not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target
        (S.Buffer_Switcher, Row.Id)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a dirty-prune preview target");
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
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a dirty-prune preview target");
         return;
      end if;

      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);

      if Remaining = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "Removed " & To_String (Name) & " from dirty-prune preview; no pending dirty-prune action");
      else
         Editor.Executor.Shared_Services.Report_Success
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Removed := Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Opened := Editor.Buffer_Switcher.Open_Removed_Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);

      if Removed = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No removed dirty-prune preview targets");
      else
         Editor.Executor.Shared_Services.Report_Info
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Next_Removed_Dirty_Prune_Target (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected next removed dirty-prune preview target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No open removed dirty-prune preview targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
      elsif Editor.Buffer_Switcher.Select_Previous_Removed_Dirty_Prune_Target (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected previous removed dirty-prune preview target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No open removed dirty-prune preview targets");
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Buffer_Switcher.Has_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI)
      then
         Editor.Executor.Shared_Services.Report_Info (S, "No stale dirty-prune preview targets");
         return;
      end if;

      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Cleared, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      Normalize_Switcher_Preview_Target (S);

      if Remaining = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty-prune preview cleared");
      else
         Editor.Executor.Shared_Services.Report_Success
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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Captured := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);
      Stale := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Editor.Executor.Shared_Services.Report_Info
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
            Editor.Executor.Shared_Services.Report_Info (S, "No removed dirty-prune preview targets");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         end if;
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI,
         Restored, Target, Name, Remaining);

      if not Restored then
         Editor.Executor.Shared_Services.Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Target, Fallback);
      Editor.Executor.Shared_Services.Report_Success (S, "Restored " & To_String (Name) & " to dirty-prune preview");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
     (S : in out Editor.State.State_Type)
   is
      Applied   : Natural := 0;
      Remaining : Natural := 0;
      Fallback  : constant Natural :=
        Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune action");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Apply_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Applied, Remaining);

      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Applied = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No applicable dirty-prune targets");
      else
         Editor.Executor.Shared_Services.Report_Success
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
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      if Applicable = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No applicable dirty-prune apply targets");
         return;
      end if;
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Applied, Skipped, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action
        (S, Editor.Buffers.No_Buffer, Fallback);
      if Applied = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No applicable dirty-prune apply targets");
      elsif Skipped > 0 then
         Editor.Executor.Shared_Services.Report_Success
           (S, "Pruned" & Natural'Image (Applied)
            & " dirty-prune apply targets; skipped" & Natural'Image (Skipped));
      else
         Editor.Executor.Shared_Services.Report_Success
           (S, "Pruned" & Natural'Image (Applied)
            & " dirty-prune apply targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffer_Switcher.Cancel_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      Editor.Executor.Shared_Services.Report_Info (S, "Dirty-prune apply cancelled");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
     (S : in out Editor.State.State_Type)
   is
      Count      : Natural := 0;
      Applicable : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Count := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (S.Buffer_Switcher);
      Applicable := Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Editor.Executor.Shared_Services.Report_Info
        (S, "Dirty-prune apply targets:" & Natural'Image (Count)
         & ";" & Natural'Image (Applicable) & " still applicable");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
     (S : in out Editor.State.State_Type) is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
      elsif Editor.Buffer_Switcher.Select_Next_Dirty_Prune_Apply_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected next dirty-prune apply target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty-prune apply targets");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
     (S : in out Editor.State.State_Type) is
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
      elsif Editor.Buffer_Switcher.Select_Previous_Dirty_Prune_Apply_Target (S.Buffer_Switcher) then
         Normalize_Switcher_Preview_Target (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Selected previous dirty-prune apply target");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "No dirty-prune apply targets");
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
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Row := Selected_Switcher_Buffer (S, Found);
      if not Found or else not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target (S.Buffer_Switcher, Row.Id) then
         Editor.Executor.Shared_Services.Report_Info (S, "Selected buffer is not a dirty-prune apply target");
         return;
      end if;
      Fallback := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Row.Id, Removed, Remaining);
      Recompute_Buffer_Switcher_After_Selected_Action (S, Editor.Buffers.No_Buffer, Fallback);
      if Remaining = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "Removed " & To_String (Row.Display_Label) & " from dirty-prune apply; no pending dirty-prune apply confirmation");
      else
         Editor.Executor.Shared_Services.Report_Success (S, "Removed " & To_String (Row.Display_Label) & " from dirty-prune apply");
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
      if not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No removed dirty-prune apply targets");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Restored, Target, Name, Remaining);
      if not Restored then
         Editor.Executor.Shared_Services.Report_Info (S, "Could not restore " & To_String (Name) & "; buffer is no longer open");
         return;
      end if;
      Recompute_Buffer_Switcher_After_Selected_Action (S, Target, Fallback);
      Editor.Executor.Shared_Services.Report_Success (S, "Restored " & To_String (Name) & " to dirty-prune apply");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed;

   procedure Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
     (S : in out Editor.State.State_Type)
   is
      Cleared   : Natural := 0;
      Remaining : Natural := 0;
   begin
      if not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S.Buffer_Switcher) then
         Editor.Executor.Shared_Services.Report_Info (S, "No pending dirty-prune apply confirmation");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Apply_Targets
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Cleared, Remaining);
      Recompute_Buffer_Switcher (S);
      Normalize_Switcher_Preview_Target (S);
      if Cleared = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No stale dirty-prune apply targets");
      else
         Editor.Executor.Shared_Services.Report_Info (S, "Cleared" & Natural'Image (Cleared) & " stale dirty-prune apply target");
      end if;
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale;

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
         Editor.Executor.Shared_Services.Report_Info (S, "No pending marked action");
         return;
      end if;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Open_Count := Editor.Buffer_Switcher.Pending_Marked_Open_Count
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Editor.Executor.Shared_Services.Report_Info
        (S, "Pending marked close:" & Natural'Image (Captured_Count)
         & " targets;" & Natural'Image (Open_Count) & " still open");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Buffer_Switcher_Pending_Mark_Summary;

   procedure Execute_Apply_Inspection_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
   is
   begin
      if Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show then
         Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review
           (S.Buffer_Switcher);
         Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
         Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Dirty-prune apply review shown");
      elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide then
         Editor.Buffer_Switcher.Hide_Dirty_Prune_Apply_Review
           (S.Buffer_Switcher);
         Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
         Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Dirty-prune apply review hidden");
      elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle then
         Editor.Buffer_Switcher.Toggle_Dirty_Prune_Apply_Review
           (S.Buffer_Switcher);
         Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
         Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
         Report_Success (S, "Dirty-prune apply review toggled");
      elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next then
         if Editor.Buffer_Switcher.Select_Next_Removed_Dirty_Prune_Apply_Target
           (S.Buffer_Switcher)
         then
            Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
            Report_Success
              (S, "Selected next removed dirty-prune apply target");
         else
            Report_Info (S, "No open removed dirty-prune apply targets");
         end if;
      elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous then
         if Editor.Buffer_Switcher.Select_Previous_Removed_Dirty_Prune_Apply_Target
           (S.Buffer_Switcher)
         then
            Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
            Report_Success
              (S, "Selected previous removed dirty-prune apply target");
         else
            Report_Info (S, "No open removed dirty-prune apply targets");
         end if;
      elsif Id = Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary then
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Report_Info
           (S,
            "Dirty-prune apply stale targets:"
            & Natural'Image
              (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Stale_Target_Count
                 (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI))
            & " of"
            & Natural'Image
              (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
                 (S.Buffer_Switcher)));
      else
         Editor.Buffers.Ensure_Global_Registry (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Report_Info
           (S,
            "Removed dirty-prune apply targets:"
            & Natural'Image
              (Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
                 (S.Buffer_Switcher))
            & ";"
            & Natural'Image
              (Editor.Buffer_Switcher.Open_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count
                 (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI))
            & " still open");
      end if;
   end Execute_Apply_Inspection_Command;

   procedure Execute_Buffer_Switcher_Pending_Mark_Kind
     (S    : in out Editor.State.State_Type;
      Kind : Editor.Commands.Command_Kind)
   is
   begin
      case Kind is
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Review_Toggle =>
            Execute_Buffer_Switcher_Pending_Mark_Review_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Review_Show =>
            Execute_Buffer_Switcher_Pending_Mark_Review_Show (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Review_Hide =>
            Execute_Buffer_Switcher_Pending_Mark_Review_Hide (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Next (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Previous (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Summary (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Remove_Selected =>
            Execute_Buffer_Switcher_Pending_Mark_Remove_Selected (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Next (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned (S);
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
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply (S);
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
   end Execute_Buffer_Switcher_Pending_Mark_Kind;

   function Execute_Buffer_Switcher_Pending_Mark_Command
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
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary =>
            Execute_Apply_Inspection_Command (S, Id);

         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed (S);
         when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale =>
            Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale (S);

         when others =>
            Execute_Buffer_Switcher_Pending_Mark_Kind
              (S, Editor.Commands.Command_For_Id (Id).Kind);
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (Id);
   end Execute_Buffer_Switcher_Pending_Mark_Command;

end Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
