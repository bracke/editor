with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands;
with Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands;
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
      return Editor.Executor.Buffer_Switcher_Shared.Selected_Switcher_Buffer (S, Found);
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
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Review_Toggle (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Review_Show =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Review_Show (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Review_Hide =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Review_Hide (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Next =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Next (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Previous =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Previous (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Summary =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Summary (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Remove_Selected =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Remove_Selected (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Summary (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Next =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Next (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Previous (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Show (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide (S);
        when Editor.Commands.Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Review_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned (S);
         when Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Next
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Editor.Commands.Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Commands
              .Execute_Buffer_Switcher_Pending_Mark_Dirty_Kind (S, Kind);
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
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed (S);
        when Editor.Commands.Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale =>
            Editor.Executor.Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Commands.Execute_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale (S);

         when others =>
            Execute_Buffer_Switcher_Pending_Mark_Kind
              (S, Editor.Commands.Command_For_Id (Id).Kind);
      end case;

      Editor.Render_Cache.Invalidate_All;
      return Result_After_Command (Id);
   end Execute_Buffer_Switcher_Pending_Mark_Command;

end Editor.Executor.Buffer_Switcher_Pending_Mark_Commands;
