with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Buffer_Switcher;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Buffer_Switcher_Shared;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Feature_Messages;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Files;
use type Editor.Files.File_Copy_Status;
use type Editor.Files.File_Move_Status;
use type Editor.Files.File_Open_Status;
use type Editor.Files.File_Rename_Status;
use type Editor.Files.File_Save_Status;
use type Editor.Files.File_Delete_Status;
use type Editor.Files.File_External_Change_Status;
with Editor.History;
with Editor.Input_Field;
with Editor.Message_Producers;
with Editor.Messages;
use type Editor.Messages.Message_Severity;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Outline;
with Editor.Panels;
use type Editor.Panels.Bottom_Panel_Content;
with Editor.Pending_Transitions;
use type Editor.Pending_Transitions.Pending_Transition_Kind;
with Editor.Problems;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.Recent_Projects;
with Editor.Render_Cache;
with Editor.Search;
with Editor.Settings;
with Editor.State;
use type Editor.State.Dirty_Close_Scope;
use type Editor.State.File_Conflict_Kind;
with Editor.View;
with Editor.Build_UI;
with Editor.Executor.File_Open_Commands;

package body Editor.Executor.Buffer_Close_Commands is

   use Editor.Commands;

   function Count_Text
     (Count : Natural;
      One   : String;
      Many  : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both)
        & " " & (if Count = 1 then One else Many);
   end Count_Text;

   function Project_Lifecycle_Set_Contains
     (Ids : Editor.Buffers.Buffer_Id_Vectors.Vector;
      Id  : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      if Id = Editor.Buffers.No_Buffer or else Ids.Is_Empty then
         return False;
      end if;

      for Index in Ids.First_Index .. Ids.Last_Index loop
         if Ids.Element (Index) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Project_Lifecycle_Set_Contains;

   procedure Close_Clean_Buffer_For_Cleanup
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean)
   is
      Summary    : constant Editor.Buffers.Buffer_Summary :=
        Editor.Buffers.Global_Summary_For (Id);
      Was_Active : constant Boolean := Summary.Is_Active;
   begin
      Closed := False;
      if Summary.Id = Editor.Buffers.No_Buffer
        or else Summary.Is_Dirty
        or else Summary.Is_Pinned
      then
         return;
      end if;

      Editor.Buffers.Global_Close_Buffer (Id, Closed);
      if Closed then
         Editor.Executor.Buffer_Close_Prompt_Commands.Finalize_Cleanup_Buffer_Close (S, Id, Was_Active);
      end if;
   end Close_Clean_Buffer_For_Cleanup;

   function Natural_Text (Value : Natural) return String
   is
      Image : constant String := Natural'Image (Value);
   begin
      return Image (Image'First + 1 .. Image'Last);
   end Natural_Text;

   function Cleanup_Feedback
     (Closed         : Natural;
      Skipped_Dirty  : Natural;
      Skipped_Pinned : Natural;
      None           : String) return String
   is
      Message : Unbounded_String;
   begin
      if Closed = 0 then
         Message := To_Unbounded_String (None);
      else
         Message := To_Unbounded_String
           ("Buffers: closed " & Natural_Text (Closed));
      end if;

      if Skipped_Dirty > 0 then
         Append (Message, ", skipped " & Natural_Text (Skipped_Dirty) & " dirty");
      end if;
      if Skipped_Pinned > 0 then
         Append (Message, ", kept " & Natural_Text (Skipped_Pinned) & " pinned");
      end if;
      return To_String (Message);
   end Cleanup_Feedback;



   function Dirty_Buffer_Summary_For_Other_Buffers
     (Active : Editor.Buffers.Buffer_Id)
      return Editor.Dirty_Guards.Dirty_Buffer_Summary
   is
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
      Registry : constant Editor.Buffers.Buffer_Registry :=
        Editor.Buffers.Global_Registry_For_UI;
   begin
      for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
         declare
            Item : constant Editor.Buffers.Buffer_Summary :=
              Editor.Buffers.Summary_At (Registry, Index);
         begin
            if Item.Id /= Active and then Item.Is_Dirty then
               Summary.Dirty_Count := Summary.Dirty_Count + 1;
               if Item.Has_Path then
                  Summary.File_Backed_Count := Summary.File_Backed_Count + 1;
               else
                  Summary.Untitled_Count := Summary.Untitled_Count + 1;
               end if;
            end if;
         end;
      end loop;
      return Summary;
   end Dirty_Buffer_Summary_For_Other_Buffers;

   procedure Execute_Close_Other_Buffers
     (S : in out Editor.State.State_Type)
   is
      Active       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed_Total : Natural := 0;
      Skipped      : Natural := 0;
      Skipped_Pinned : Natural := 0;
      Closed       : Boolean := False;
      Progress     : Boolean := True;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Active := Editor.Buffers.Global_Active_Buffer;

      if Active = Editor.Buffers.No_Buffer then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      end if;

      declare
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
      begin
         for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, Index);
            begin
               if Summary.Id /= Editor.Buffers.No_Buffer
                 and then Summary.Id /= Active
               then
                  if Summary.Is_Pinned then
                     Skipped_Pinned := Skipped_Pinned + 1;
                  elsif Summary.Is_Dirty then
                     Skipped := Skipped + 1;
                  end if;
               end if;
            end;
         end loop;
      end;

      while Progress loop
         Progress := False;
         declare
            Registry : constant Editor.Buffers.Buffer_Registry :=
              Editor.Buffers.Global_Registry_For_UI;
         begin
            for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
               declare
                  Summary : constant Editor.Buffers.Buffer_Summary :=
                    Editor.Buffers.Summary_At (Registry, Index);
               begin
                  if Summary.Id /= Editor.Buffers.No_Buffer
                    and then Summary.Id /= Active
                    and then not Summary.Is_Pinned
                    and then not Summary.Is_Dirty
                  then
                     Close_Clean_Buffer_For_Cleanup (S, Summary.Id, Closed);
                     if Closed then
                        Closed_Total := Closed_Total + 1;
                        Progress := True;
                        exit;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;

      if Editor.Buffers.Global_Contains (Active) then
         Editor.Buffers.Global_Set_Active_Buffer (Active);
      end if;
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      Editor.Executor.Shared_Services.Report_Info (S, Cleanup_Feedback
          (Closed_Total, Skipped, Skipped_Pinned, "Buffers: no other unpinned clean buffers to close"));
   end Execute_Close_Other_Buffers;


   function Pending_Discard_Applies_To_Buffer
     (S      : Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Id     : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return Target.Has_Buffer
              and then Id = Editor.Buffers.Buffer_Id (Target.Buffer_Id);
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            declare
               Sets : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
                 Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
            begin
               return Project_Lifecycle_Set_Contains
                 (Sets.Project_Close_Affected, Id);
            end;
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            --  close-other discard review is
            --  scoped to the active buffer captured when the confirmation was
            --  opened.  Do not rebase the destructive discard set onto a later
            --  active-buffer change, because that would allow an unreviewed
            --  buffer to be discarded or the originally protected buffer to be
            --  closed.
            return Target.Has_Buffer
              and then Id /= Editor.Buffers.Buffer_Id (Target.Buffer_Id);
         when Editor.Pending_Transitions.Pending_Switch_Project =>
            declare
               Sets : constant Editor.Buffers.Buffer_Project_Lifecycle_Sets :=
                 Editor.Buffers.Global_Project_Lifecycle_Buffer_Sets (S.Project);
            begin
               return Project_Lifecycle_Set_Contains
                 (Sets.Project_Close_Affected, Id);
            end;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers
            | Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project
            | Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return True;
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return False;
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer
            | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
            | Editor.Pending_Transitions.No_Pending_Transition =>
            return False;
      end case;
   end Pending_Discard_Applies_To_Buffer;

   procedure Discard_Dirty_Buffers_For_Pending_Target
     (S            : in out Editor.State.State_Type;
      Target       : Editor.Pending_Transitions.Pending_Transition_Target;
      Closed_Count : out Natural;
      Kept_Count   : out Natural)
   is
      Closed : Boolean := False;
   begin
      Closed_Count := 0;
      Kept_Count := 0;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
         Count    : constant Natural := Editor.Buffers.Buffer_Count (Registry);
         type Buffer_Id_Array is array (Positive range <>) of Editor.Buffers.Buffer_Id;
         Targets  : Buffer_Id_Array (1 .. Natural'Max (Count, 1));
         Target_Count : Natural := 0;
      begin
         for Index in 1 .. Count loop
            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, Index);
            begin
               if Summary.Id /= Editor.Buffers.No_Buffer
                 and then Summary.Is_Dirty
                 and then Pending_Discard_Applies_To_Buffer (S, Target, Summary.Id)
               then
                  Target_Count := Target_Count + 1;
                  Targets (Target_Count) := Summary.Id;
               end if;
            end;
         end loop;

         for Index in 1 .. Target_Count loop
            if Editor.Buffers.Global_Contains (Targets (Index))
              and then Editor.Buffers.Global_Summary_For (Targets (Index)).Is_Dirty
            then
               Editor.Executor.Buffer_Close_Prompt_Commands.Close_Buffer_By_Discard (S, Targets (Index), Closed);
               if Closed then
                  Closed_Count := Closed_Count + 1;
               else
                  Kept_Count := Kept_Count + 1;
               end if;
            end if;
         end loop;
      end;
   end Discard_Dirty_Buffers_For_Pending_Target;

   procedure Continue_After_Pending_Discard
     (S      : in out Editor.State.State_Type;
      Target : Editor.Pending_Transitions.Pending_Transition_Target)
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            null;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
         Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_All_Buffers_Confirmed (S);
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            --  continue the operation against
            --  the reviewed active buffer captured in the pending transition,
            --  not whatever buffer happens to be active at confirmation time.
            if Target.Has_Buffer then
               Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_Other_Buffers_Confirmed
                 (S, Editor.Buffers.Buffer_Id (Target.Buffer_Id));
            else
               Editor.Pending_Transitions.Clear (S.Pending_Transitions);
               Editor.Executor.Shared_Services.Report_Warning (S, Editor.Commands.Reason_Close_Review_Stale);
            end if;
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            if Target.Has_Path then
               if Target.Kind = Editor.Pending_Transitions.Pending_Open_Recent_Project then
                  Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S,
                     To_String (Target.Path),
                     Refresh_Build_Candidates => True,
                     Apply_Workspace_Policy => False,
                     Recent_Project_Open => True);
               elsif Target.Kind = Editor.Pending_Transitions.Pending_Switch_Project then
                  Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S,
                     To_String (Target.Path),
                     Refresh_Build_Candidates => True,
                     Apply_Workspace_Policy => False,
                     Explicit_Switch => True);
               else
                  Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, To_String (Target.Path));
               end if;
            end if;
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            Editor.Executor.Workspace_Commands.Execute_Restore_Workspace_State (S);
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            Editor.Executor.Project_Lifecycle_Commands
              .Execute_Guarded_Close_Project (S);
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer
            | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
            | Editor.Pending_Transitions.No_Pending_Transition =>
            null;
      end case;
   end Continue_After_Pending_Discard;

   procedure Execute_Discard_Pending_Transition
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Closed : Natural := 0;
      Kept   : Natural := 0;
   begin
      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Executor.Shared_Services.Report_Info (S, Editor.Dirty_Guards.No_Pending_Transition_Message);
         return;
      end if;

      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      if Target.Kind in Editor.Pending_Transitions.Pending_Reload_Active_Buffer
          | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Reload/revert requires its own explicit confirmation");
         return;
      elsif Target.Kind = Editor.Pending_Transitions.Pending_Clear_Workspace_State then
         Editor.Executor.Shared_Services.Report_Warning (S, "Clear workspace requires Retry to confirm");
         return;
      end if;

      if not Editor.Executor.Pending_Transition_Policy.Pending_Target_Is_Valid (S, Target) then
         Editor.Pending_Transitions.Clear (S.Pending_Transitions);
         Editor.Executor.Shared_Services.Report_Warning (S, Editor.Dirty_Guards.Pending_Transition_No_Longer_Valid_Message);
         return;
      end if;

      Discard_Dirty_Buffers_For_Pending_Target (S, Target, Closed, Kept);
      if Kept > 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "Could not discard all affected dirty buffers");
         return;
      end if;

      --  pending close-buffer discard is a
      --  close confirmation for the reviewed buffer, not only a dirty-text
      --  discard operation.  If the buffer became clean while the transient
      --  pending transition was visible, the dirty-discard loop above has no
      --  dirty text to close; revalidate the original target and close it
      --  through the same cleanup path instead of silently clearing the
      --  transition and leaving the buffer open.
      if Target.Kind = Editor.Pending_Transitions.Pending_Close_Buffer
        and then Closed = 0
        and then Target.Has_Buffer
        and then Editor.Buffers.Global_Contains
          (Editor.Buffers.Buffer_Id (Target.Buffer_Id))
        and then not Editor.Buffers.Global_Summary_For
          (Editor.Buffers.Buffer_Id (Target.Buffer_Id)).Is_Dirty
      then
         declare
            Closed_Clean : Boolean := False;
         begin
            Editor.Executor.Buffer_Close_Prompt_Commands.Close_Buffer_By_Discard
              (S, Editor.Buffers.Buffer_Id (Target.Buffer_Id), Closed_Clean);
            if Closed_Clean then
               Closed := Closed + 1;
            end if;
         end;
      end if;

      if Editor.Buffers.Global_Count = 0
        or else Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
      then
         Text_Buffer.Clear (S.Buffer);
         S.File_Info := (others => <>);
         S.Buffer_Revision := 0;
         S.Active_Buffer_Token := 0;
         S.Line_Starts.Clear;
         S.Line_Starts.Append (0);
      else
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      Editor.Pending_Transitions.Clear (S.Pending_Transitions);
      Continue_After_Pending_Discard (S, Target);

      if Target.Kind = Editor.Pending_Transitions.Pending_Close_Buffer then
         if Closed > 0 then
            Editor.Executor.Shared_Services.Report_Info (S, "Buffer closed");
         else
            Editor.Executor.Shared_Services.Report_Info (S, "No affected dirty buffers to discard");
         end if;
      end if;
   end Execute_Discard_Pending_Transition;

   procedure Execute_Close_All_Buffers
     (S : in out Editor.State.State_Type)
   is
      Dirty_Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if Editor.Buffers.Global_Count = 0 then
         Editor.Executor.Shared_Services.Report_Info (S, "No buffers to close");
         return;
      end if;

      Dirty_Summary := Editor.Executor.Buffer_Close_Prompt_Commands.Dirty_Buffer_Summary_For_All_Buffers (S.Project);
      if Dirty_Summary.Dirty_Count > 0 then
         Editor.Executor.Buffer_Close_Prompt_Commands.Start_Dirty_Close_Prompt
           (S, Editor.State.All_Buffers_Close_Scope, True, Editor.Buffers.No_Buffer, Dirty_Summary);
         return;
      end if;

      Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_All_Buffers_Confirmed (S);
   end Execute_Close_All_Buffers;

   procedure Execute_Close_All_Clean_Buffers
     (S : in out Editor.State.State_Type)
   is
      Closed_Total : Natural := 0;
      Skipped      : Natural := 0;
      Skipped_Pinned : Natural := 0;
      Closed       : Boolean := False;
   begin
      if Editor.Executor.File_Lifecycle_Confirmation_Pending (S) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
         Buffer_Count : constant Natural := Editor.Buffers.Buffer_Count (Registry);
      begin
         if Buffer_Count > 0 then
            declare
               type Buffer_Id_Array is array (Positive range <>) of Editor.Buffers.Buffer_Id;
               Targets      : Buffer_Id_Array (1 .. Buffer_Count);
               Target_Count : Natural := 0;
            begin
               for Index in 1 .. Buffer_Count loop
                  declare
                     Summary : constant Editor.Buffers.Buffer_Summary :=
                       Editor.Buffers.Summary_At (Registry, Index);
                  begin
                     if Summary.Id /= Editor.Buffers.No_Buffer then
                        if Summary.Is_Pinned then
                           Skipped_Pinned := Skipped_Pinned + 1;
                        elsif Summary.Is_Dirty then
                           Skipped := Skipped + 1;
                        else
                           Target_Count := Target_Count + 1;
                           Targets (Target_Count) := Summary.Id;
                        end if;
                     end if;
                  end;
               end loop;

               for Index in 1 .. Target_Count loop
                  if Editor.Buffers.Global_Contains (Targets (Index)) then
                     declare
                        Summary : constant Editor.Buffers.Buffer_Summary :=
                          Editor.Buffers.Global_Summary_For (Targets (Index));
                     begin
                        if not Summary.Is_Pinned and then not Summary.Is_Dirty then
                           Close_Clean_Buffer_For_Cleanup (S, Targets (Index), Closed);
                           if Closed then
                              Closed_Total := Closed_Total + 1;
                           end if;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end if;
      end;

      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      if Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) then
         Editor.Executor.Buffer_Switcher_Shared.Recompute_Buffer_Switcher (S);
         Editor.Executor.Buffer_Switcher_Shared.Normalize_Switcher_Preview_Target (S);
      end if;
      Editor.Executor.Shared_Services.Report_Info (S, Cleanup_Feedback
          (Closed_Total, Skipped, Skipped_Pinned, "Buffers: no unpinned clean buffers to close"));
   end Execute_Close_All_Clean_Buffers;

   function Resolve_Active_Buffer_Close_Target
     (S : Editor.State.State_Type) return Editor.Buffers.Buffer_Id
   is
      pragma Unreferenced (S);
   begin
      --  file.close-buffer always targets the active buffer at
      --  command execution time.  It never derives a target from switcher,
      --  palette, quick-open, project-file, render, recent-buffer, or test
      --  override state.
      return Editor.Buffers.Global_Active_Buffer;
   end Resolve_Active_Buffer_Close_Target;

   function Active_Buffer_Close_Is_Blocked_By_Dirty_Guard
     (Id : Editor.Buffers.Buffer_Id) return Boolean
   is
   begin
      --  the close guard is read-only and consults only the
      --  canonical active-buffer dirty state.  It does not save, discard,
      --  clear dirty state, update the saved baseline, or mutate file paths.
      return Editor.Buffers.Is_Dirty
        (Editor.Buffers.Global_Registry_For_UI, Id);
   end Active_Buffer_Close_Is_Blocked_By_Dirty_Guard;

   procedure Mark_Active_Buffer_Close_Blocked
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id)
   is
   begin
      Editor.Buffers.Global_Set_Blocked_Close_Surfaced (Id);
      S.File_Info.Blocked_Close_Surfaced := True;
      if S.Active_Buffer_Token = Natural (Id) then
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      declare
         Guard : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
           Editor.Executor.Pending_Transition_Policy.Check_Dirty_Transition (S, Editor.Dirty_Guards.Close_Buffer_Transition);
      begin
         Editor.Executor.Pending_Transition_Policy.Set_Pending_Dirty_Transition (S,
            Editor.Executor.Pending_Transition_Policy.Pending_Target_For (Editor.Pending_Transitions.Pending_Close_Buffer,
               Display   => Editor.Buffers.Global_Display_Name (Id),
               Buffer_Id => Id),
            Guard);
      end;
   end Mark_Active_Buffer_Close_Blocked;

   procedure Close_Active_Buffer_Through_Canonical_Lifecycle
     (S      : in out Editor.State.State_Type;
      Id     : Editor.Buffers.Buffer_Id;
      Closed : out Boolean)
   is
   begin
      --  this is the one canonical open-buffer removal path used by
      --  file.close-buffer after the dirty guard has allowed the close.
      --  Buffer-local cleanup and deterministic post-close active selection are
      --  owned by Editor.Buffers.Global_Close_Buffer.
      Editor.Buffers.Global_Close_Buffer (Id, Closed);
   end Close_Active_Buffer_Through_Canonical_Lifecycle;

   procedure Finish_Active_Buffer_Close_Lifecycle
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id)
   is
   begin
      Editor.Recent_Buffers.Remove (S.Recent_Buffers, Natural (Id));
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
        (S, Natural (Id));
      Editor.Feature_Messages.Reset_For_Buffer_Close
        (S.Feature_Messages, Editor.Executor.Active_Feature_Buffer_Token (S));
      Editor.Feature_Search_Results.Reset_For_Buffer_Close
        (S.Feature_Search_Results, Editor.Executor.Active_Feature_Buffer_Token (S));
      Editor.Feature_Panel_Controller.Rebuild_Active_Feature_Projection (S);

      if Editor.Buffers.Global_Count = 0
        or else Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
      then
         S.Active_Buffer_Token := 0;
      else
         declare
            Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
              S.Language_Index;
            Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
              S.Language_Service;
         begin
            Editor.Buffers.Load_Global_Active_Into_State (S);
            S.Language_Index := Saved_Index;
            S.Language_Service := Saved_Service;
         end;
      end if;

      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
      if Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel)
        and then Editor.Panels.Active_Bottom_Content (S.Panels) =
          Editor.Panels.Problems_Content
      then
         declare
            Snapshot : constant Editor.Problems.Problems_Snapshot :=
              Editor.Problems.Build_Snapshot (S.Diagnostics);
         begin
            Editor.Problems.Ensure_Valid_Selection (S.Problems_View, Snapshot);
         end;
      end if;
   end Finish_Active_Buffer_Close_Lifecycle;

   procedure Execute_Close_Active_Buffer
     (S : in out Editor.State.State_Type)
   is
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed : Boolean := False;
      Candidate_Has_Path : Boolean := False;
      Candidate_Path     : Unbounded_String := Null_Unbounded_String;
      Candidate_Label    : Unbounded_String := Null_Unbounded_String;
   begin
      --  direct close is canonical active-buffer lifecycle work.
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      Editor.Buffers.Ensure_Global_Registry (S);

      --  /432: only sync State into the registry when State still
      --  owns the same active buffer.  A stale State must not be copied into
      --  the current active close target before the dirty guard runs.
      if S.Active_Buffer_Token = Natural (Editor.Buffers.Global_Active_Buffer)
      then
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Id := Resolve_Active_Buffer_Close_Target (S);

      if Id = Editor.Buffers.No_Buffer then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif not Editor.Buffers.Global_Contains (Id) then
         Editor.Executor.Shared_Services.Report_Error (S, "Could not close buffer");
         return;
      end if;

      if Active_Buffer_Close_Is_Blocked_By_Dirty_Guard (Id) then
         --  dirty active-buffer close now enters the explicit
         --  dirty-close review workflow directly instead of creating a
         --  separate pending close transition.  The surfaced marker remains
         --  observational; the save/discard/cancel decision is owned by the
         --  no-payload confirmation commands below.
         Editor.Buffers.Global_Set_Blocked_Close_Surfaced (Id);
         S.File_Info.Blocked_Close_Surfaced := True;
         if S.Active_Buffer_Token = Natural (Id) then
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
         declare
            Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary :=
              (Dirty_Count       => 1,
               Untitled_Count    => (if Editor.Buffers.Global_Summary_For (Id).Has_Path then 0 else 1),
               File_Backed_Count => (if Editor.Buffers.Global_Summary_For (Id).Has_Path then 1 else 0));
         begin
         Editor.Executor.Buffer_Close_Prompt_Commands.Start_Dirty_Close_Prompt
           (S, Editor.State.Active_Buffer_Close_Scope, False, Id, Summary);
         end;
         return;
      end if;

      Editor.Executor.File_Open_Commands.Candidate_For_Closed_Associated_Buffer (Id, Candidate_Has_Path, Candidate_Path, Candidate_Label);

      Close_Active_Buffer_Through_Canonical_Lifecycle (S, Id, Closed);
      if Closed then
         if Candidate_Has_Path then
            Editor.Executor.File_Open_Commands.Register_Reopen_Candidate_After_Close (S, To_String (Candidate_Path), To_String (Candidate_Label));
         end if;
         Finish_Active_Buffer_Close_Lifecycle (S, Id);
         Editor.Executor.Shared_Services.Report_Info (S, "Buffer closed");
      else
         Editor.Executor.Shared_Services.Report_Error (S, "Could not close buffer");
      end if;
   end Execute_Close_Active_Buffer;

   procedure Execute_Close_Buffer
     (S  : in out Editor.State.State_Type;
      Id : Editor.Buffers.Buffer_Id)
   is
   begin
      --  removed explicit-id close entry points must not create a
      --  second close model or permit inactive target selection.  The only
      --  close command path is the active-buffer file.close-buffer lifecycle.
      Editor.Buffers.Ensure_Global_Registry (S);
      if Id = Editor.Buffers.Global_Active_Buffer then
         Execute_Close_Active_Buffer (S);
      elsif Id = Editor.Buffers.No_Buffer then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
      else
         Editor.Executor.Shared_Services.Report_Error (S, "Could not close buffer");
      end if;
   end Execute_Close_Buffer;

   procedure Execute_Buffer_Close_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
   begin
      case Cmd.Kind is
         when Close_Buffer =>
            if Cmd.Buffer_Id = 0 then
               Execute_Close_Active_Buffer (S);
            else
               Execute_Close_Buffer (S, Editor.Buffers.Buffer_Id (Cmd.Buffer_Id));
            end if;

         when Close_Other_Buffers =>
            Execute_Close_Other_Buffers (S);

         when Close_All_Clean_Buffers =>
            Execute_Close_All_Clean_Buffers (S);

         when Discard_Pending_Transition =>
            Execute_Discard_Pending_Transition (S);

         when others =>
            raise Program_Error with "unsupported buffer close command kind";
      end case;
   end Execute_Buffer_Close_Kind;

end Editor.Executor.Buffer_Close_Commands;
