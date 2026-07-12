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
with Editor.Build_UI;
with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Executor.Pending_Transition_Policy;
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Feature_Diagnostics;
with Editor.Files;
use type Editor.Files.File_Open_Status;
use type Editor.Files.File_Save_Status;
use type Editor.Files.File_External_Change_Status;
with Editor.History;
with Editor.Outline;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Project_Search;
with Editor.Render_Cache;
with Editor.Settings;
with Editor.State;
use type Editor.State.File_Conflict_Kind;
with Editor.View;

package body Editor.Executor.File_Save_Basic_Commands is

   procedure Clear_Dirty_Close_Prompt
     (S : in out Editor.State.State_Type) renames
       Editor.Executor.Buffer_Close_Prompt_Commands.Clear_Dirty_Close_Prompt;

   procedure Load_Global_Active_Preserving_Language_Index
     (S : in out Editor.State.State_Type)
   is
      Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
        S.Language_Index;
      Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
        S.Language_Service;
   begin
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.Language_Index := Saved_Index;
      S.Language_Service := Saved_Service;
   end Load_Global_Active_Preserving_Language_Index;

   function Count_Text
     (Count : Natural;
      One   : String;
      Many  : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both)
        & " " & (if Count = 1 then One else Many);
   end Count_Text;

   function Save_Failure_Recovery_Message
     (Result : Editor.Files.File_Save_Result) return String
   is
      pragma Unreferenced (Result);
   begin
      return "Could not save file";
   end Save_Failure_Recovery_Message;

   function Read_Failure_Recovery_Message
     (Result    : Editor.Files.File_Open_Result;
      Operation : String) return String
   is
      pragma Unreferenced (Result);
   begin
      return "Could not " & Operation & " buffer";
   end Read_Failure_Recovery_Message;

   procedure Resolve_Active_Buffer_Save_Target
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Canonical active-buffer save target resolver.  The target
      --  is the active global buffer at command execution time; no switcher,
      --  palette, quick-open, project-file, render, most-recently-edited, or
      --  first-dirty fallback participates in file.save target selection.
      Editor.Buffers.Ensure_Global_Registry (S);

      if Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer then
         if S.Active_Buffer_Token /= Natural (Editor.Buffers.Global_Active_Buffer) then
            Editor.Buffers.Load_Global_Active_Into_State (S);
         else
            Editor.Buffers.Sync_Global_Active_From_State (S);
         end if;
      end if;
   end Resolve_Active_Buffer_Save_Target;

   function Active_Buffer_Save_Target_Available
     (S : Editor.State.State_Type) return Boolean is
   begin
      return Editor.State.Has_Active_Buffer (S);
   end Active_Buffer_Save_Target_Available;

   function Validate_Active_Buffer_Save_Target
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      --  Canonical save-path validation.  file.save accepts only
      --  the active buffer's associated path and never invents, prompts, or
      --  falls back to Save As, workspace, recent-project, project-root,
      --  switcher, quick-open, or file-tree paths.
      return S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0;
   end Validate_Active_Buffer_Save_Target;

   function Serialize_Active_Buffer_Current_Text_For_Save
     (S : Editor.State.State_Type) return String
   is
   begin
      --  Canonical save serialization.  The source is exactly the
      --  active buffer's in-memory text; rendered rows, disk contents,
      --  clipboard, find/project-search snippets, and formatting helpers are
      --  not consulted.
      return Editor.State.Current_Text (S);
   end Serialize_Active_Buffer_Current_Text_For_Save;

   function Write_Active_Buffer_Text_To_File
     (S : Editor.State.State_Type) return Editor.Files.File_Save_Result
   is
   begin
      --  Canonical file write path for active-buffer file.save.
      --  Only the active buffer's associated path is written; workspace,
      --  settings, recent-projects, Save All, autosave, backup, and format-on
      --  save paths are outside this command.
      return Editor.Files.Save_File
        (Path     => To_String (S.File_Info.Path),
         Contents => Serialize_Active_Buffer_Current_Text_For_Save (S));
   end Write_Active_Buffer_Text_To_File;

   procedure File_Lifecycle_Invalidate_Derived_State
     (S      : in out Editor.State.State_Type;
      Reason : String);


   procedure Clear_File_Conflict_Prompt
     (S : in out Editor.State.State_Type)
   is
   begin
      S.File_Conflict_Prompt_Active := False;
      S.File_Conflict_Prompt_Buffer := 0;
      S.File_Conflict_Prompt_Path := Null_Unbounded_String;
      S.File_Conflict_Prompt_Display := Null_Unbounded_String;
      S.File_Conflict_Prompt_Kind := Editor.State.No_File_Conflict;
      S.File_Conflict_Prompt_Dirty := False;
      S.File_Conflict_Prompt_Buffer_Revision := 0;
      S.File_Conflict_Prompt_Token_Label := Null_Unbounded_String;
      S.File_Conflict_Close_After_Overwrite := False;
      S.File_Conflict_Close_After_Overwrite_Buffer := 0;
      S.File_Conflict_Close_After_Overwrite_Selected := False;
      S.File_Conflict_Close_After_Overwrite_All_Buffers := False;
   end Clear_File_Conflict_Prompt;

   function Active_File_External_Status
     (S : Editor.State.State_Type) return Editor.Files.File_External_Change_Status
   is
   begin
      if not S.File_Info.Has_Path or else Length (S.File_Info.Path) = 0 then
         return Editor.Files.File_External_Status_Unknown;
      end if;
      return Editor.Files.External_Change_Status
        (To_String (S.File_Info.Path),
         S.File_Info.File_Token_Known,
         To_String (S.File_Info.File_Token_Label));
   end Active_File_External_Status;

   function Active_Save_Target_Is_Existing_Unwritable
     (S : Editor.State.State_Type) return Boolean
   is
      use type Ada.Directories.File_Kind;
      Path : constant String := To_String (S.File_Info.Path);
   begin
      --  Command-boundary save preflight only.  This probes metadata and the
      --  host writability bit for the active file-backed target; it performs
      --  no write, chmod, repair, reload, or content mutation.
      return S.File_Info.Has_Path
        and then Path'Length > 0
        and then Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
        and then not Editor.Files.Existing_File_Is_Writable (Path);
   exception
      when others =>
         return False;
   end Active_Save_Target_Is_Existing_Unwritable;

   function Active_Save_Target_Is_Existing_Nonregular
     (S : Editor.State.State_Type) return Boolean
   is
      use type Ada.Directories.File_Kind;
      Path : constant String := To_String (S.File_Info.Path);
   begin
      return S.File_Info.Has_Path
        and then Path'Length > 0
        and then Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) /= Ada.Directories.Ordinary_File;
   exception
      when others =>
         return False;
   end Active_Save_Target_Is_Existing_Nonregular;

   procedure Capture_Active_File_Token
     (S : in out Editor.State.State_Type)
   is
      Found : Boolean := False;
      Label : Unbounded_String := Null_Unbounded_String;
   begin
      if S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0 then
         Label := To_Unbounded_String
           (Editor.Files.Current_Token_Label (To_String (S.File_Info.Path), Found));
      end if;
      S.File_Info.File_Token_Known := Found;
      S.File_Info.File_Token_Label := Label;
   end Capture_Active_File_Token;

   function Conflict_Kind_For_Status
     (Status : Editor.Files.File_External_Change_Status;
      Dirty  : Boolean) return Editor.State.File_Conflict_Kind
   is
   begin
      case Status is
         when Editor.Files.File_External_Status_Modified =>
            return (if Dirty then Editor.State.External_Modified_While_Dirty
                    else Editor.State.External_Modified_While_Clean);
         when Editor.Files.File_External_Status_Missing =>
            return (if Dirty then Editor.State.Backing_File_Deleted_While_Dirty
                    else Editor.State.Backing_File_Deleted_While_Clean);
         when Editor.Files.File_External_Status_Unreadable =>
            return Editor.State.Backing_File_Unreadable;
         when Editor.Files.File_External_Status_Replaced =>
            return Editor.State.Backing_File_Replaced;
         when others =>
            return Editor.State.No_File_Conflict;
      end case;
   end Conflict_Kind_For_Status;

   procedure Start_File_Conflict_Prompt
     (S      : in out Editor.State.State_Type;
      Kind   : Editor.State.File_Conflict_Kind;
      Reason : String)
   is
   begin
      S.File_Conflict_Prompt_Active := True;
      S.File_Conflict_Prompt_Buffer := Natural (Editor.Buffers.Global_Active_Buffer);
      S.File_Conflict_Prompt_Path := S.File_Info.Path;
      S.File_Conflict_Prompt_Display := S.File_Info.Display_Name;
      S.File_Conflict_Prompt_Kind := Kind;
      S.File_Conflict_Prompt_Dirty := S.File_Info.Dirty;
      S.File_Conflict_Prompt_Buffer_Revision :=
        Editor.State.Current_Buffer_Revision (S);
      --  Capture the disk state observed when the prompt is opened.  This is
      --  a transient validation token only; it is not the buffer's last-loaded
      --  token and is never persisted.  Confirmation actions use it to reject
      --  prompts if the backing file changes again before the user chooses.
      declare
         Found : Boolean := False;
         Label : constant String :=
           Editor.Files.Current_Token_Label
             (To_String (S.File_Info.Path), Found);
      begin
         S.File_Conflict_Prompt_Token_Label :=
           (if Found then To_Unbounded_String (Label)
            else Null_Unbounded_String);
      end;
      S.File_Info.External_Change_Surfaced :=
        Kind in Editor.State.External_Modified_While_Clean
          | Editor.State.External_Modified_While_Dirty
          | Editor.State.Backing_File_Replaced;
      S.File_Info.Missing_Target_Surfaced :=
        Kind in Editor.State.Backing_File_Deleted_While_Clean
          | Editor.State.Backing_File_Deleted_While_Dirty
          | Editor.State.Save_Target_Parent_Missing;
      S.File_Info.Unreadable_Target_Surfaced :=
        Kind = Editor.State.Backing_File_Unreadable;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Shared_Services.Report_Warning (S, Reason);
   end Start_File_Conflict_Prompt;

   procedure Mark_Active_Buffer_Saved
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      --  Canonical saved-baseline update path.  Call only after a
      --  successful active-buffer file write.  This is the only place where
      --  file.save clears dirty state or advances the saved generation.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Path;
      S.File_Info.Display_Name := Result.Display_Name;
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Capture_Active_File_Token (S);
      Clear_File_Conflict_Prompt (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Active_Buffer_Saved;

   procedure Apply_Format_On_Save_If_Enabled
     (S : in out Editor.State.State_Type)
   is
      Cmd    : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Editor.Commands.Command_Format_Buffer);
   begin
      if not Editor.Settings.Format_On_Save then
         return;
      end if;

      Editor.Executor.Execute_No_Log (S, Cmd);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Apply_Format_On_Save_If_Enabled;

   procedure Execute_Save
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Files.File_Save_Result;
   begin
      --  Active-buffer save is an explicit file-content persistence command.
      --  keeps it on one canonical path: execution-time active
      --  buffer target, associated-path validation, current-text
      --  serialization, active-buffer file write, post-success baseline
      --  update, retained clean no-op, and deterministic failure reporting.
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      if S.File_Conflict_Prompt_Active
        or else (Editor.Executor.File_Lifecycle_Confirmation_Pending (S)
                 and then not S.Dirty_Close_Prompt_Active)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;
      Resolve_Active_Buffer_Save_Target (S);

      if not Active_Buffer_Save_Target_Available (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif not Validate_Active_Buffer_Save_Target (S) then
         S.File_Info.Last_Save_Failed := True;
         S.File_Info.Missing_Target_Surfaced := True;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      end if;

      declare
         External_Status : constant Editor.Files.File_External_Change_Status :=
           Active_File_External_Status (S);
         Conflict_Kind : constant Editor.State.File_Conflict_Kind :=
           Conflict_Kind_For_Status (External_Status, S.File_Info.Dirty);
      begin
         --  requires command-boundary detection for both dirty and
         --  clean file-backed buffers.  A clean buffer has no edits to save,
         --  but a known changed/deleted/replaced/unreadable backing file is
         --  still user-visible lifecycle state and must not be hidden behind
         --  the ordinary "No changes to save" no-op.
         if Conflict_Kind /= Editor.State.No_File_Conflict then
            Start_File_Conflict_Prompt
              (S, Conflict_Kind,
               (case External_Status is
                  when Editor.Files.File_External_Status_Modified =>
                     "File changed on disk; choose how to proceed.",
                  when Editor.Files.File_External_Status_Missing =>
                     "Backing file missing.",
                  when Editor.Files.File_External_Status_Unreadable =>
                     "File is not readable.",
                  when Editor.Files.File_External_Status_Replaced =>
                     "Backing file was replaced; choose how to proceed.",
                  when others =>
                     "File conflict detected; choose how to proceed."));
            return;
         end if;
      end;

      if Active_Save_Target_Is_Existing_Unwritable (S) then
         S.File_Info.Last_Save_Failed := True;
         S.File_Info.Unwritable_Target_Surfaced := True;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Error (S, "File is not writable");
         return;
      end if;

      Apply_Format_On_Save_If_Enabled (S);

      if not S.File_Info.Dirty then
         Editor.Executor.Shared_Services.Report_Info (S, "No changes to save");
         return;
      end if;

      Result := Write_Active_Buffer_Text_To_File (S);

      if Editor.Files.Is_Success (Result) then
         Mark_Active_Buffer_Saved (S, Result);
         Clear_Dirty_Close_Prompt (S);
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after save");
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         if S.File_Info.Has_Path and then Editor.Executor.Visible_Restore_Message_In_History (S) then
            Editor.Executor.Shared_Services.Report_Success_Append (S, "Saved " & To_String (S.File_Info.Display_Name));
         else
            Editor.Executor.Shared_Services.Report_Success_Append (S, "Saved file");
         end if;
      else
         S.File_Info.Last_Save_Failed := True;
         S.File_Info.Missing_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_No_Current_Path
             | Editor.Files.File_Save_Invalid_Path
             | Editor.Files.File_Save_Parent_Unavailable;
         S.File_Info.Unwritable_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_Permission_Denied
             | Editor.Files.File_Save_Write_Error
             | Editor.Files.File_Save_Is_Directory;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Error (S, Save_Failure_Recovery_Message (Result));
      end if;
   end Execute_Save;

   function Resolve_Active_Buffer_Reload_Target
     (S : in out Editor.State.State_Type) return Boolean
   is
      Active_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      --  Canonical active-buffer reload resolver.  Execution binds
      --  file.reload-buffer to the active buffer identity only; it does not
      --  consult buffer-switcher selection, quick-open selection, command
      --  palette context, reopen candidates, workspace ordering, or any
      --  fallback file path.
      Editor.Buffers.Ensure_Global_Registry (S);
      Active_Id := Editor.Buffers.Global_Active_Buffer;

      if Editor.Buffers.Global_Count = 0
        or else Active_Id = Editor.Buffers.No_Buffer
        or else not Editor.Buffers.Global_Contains (Active_Id)
      then
         return False;
      end if;

      if S.Active_Buffer_Token = Natural (Active_Id) then
         Editor.Buffers.Sync_Global_Active_From_State (S);
      else
         Load_Global_Active_Preserving_Language_Index (S);
      end if;

      return True;
   end Resolve_Active_Buffer_Reload_Target;

   function Resolve_Active_Buffer_Revert_Target
     (S : in out Editor.State.State_Type) return Boolean is
   begin
      --  Revert binds to the same active-buffer identity mechanism as reload,
      --  but remains a distinct destructive dirty-buffer command.  This
      --  helper keeps revert tests anchored to active-buffer-only
      --  targeting without introducing any alternate path source.
      return Resolve_Active_Buffer_Reload_Target (S);
   end Resolve_Active_Buffer_Revert_Target;

   function Validate_Active_Buffer_Associated_Path_For_Reload
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Canonical reload path validation.  Reload uses only the active
      --  buffer's existing association; it never invents a path from Save As
      --  history, workspace state, recent projects, file-tree selection,
      --  quick-open state, buffer-switcher state, display names, or reopen
      --  candidates.
      return S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0;
   end Validate_Active_Buffer_Associated_Path_For_Reload;

   function Validate_Active_Buffer_Associated_Path_For_Revert
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Revert may read only the active buffer's existing association.  It
      --  never derives a path from quick open, workspace state, recent
      --  projects, display labels, reload history, or reopen candidates.
      return Validate_Active_Buffer_Associated_Path_For_Reload (S);
   end Validate_Active_Buffer_Associated_Path_For_Revert;

   function Dirty_Buffer_Reload_Blocked
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Canonical dirty reload guard.  Dirty associated buffers are blocked
      --  before any filesystem read; reload never saves, Save As, discards,
      --  force-reloads, clears dirty state, or stores dirty text.
      return S.File_Info.Dirty;
   end Dirty_Buffer_Reload_Blocked;

   function Read_Active_Buffer_Associated_File_For_Reload
     (S : Editor.State.State_Type) return Editor.Files.File_Open_Result is
   begin
      --  Canonical file-read integration.  This is the only filesystem read
      --  on the file.reload-buffer path and it is reached only by execution
      --  after no-active/no-path/dirty validation has succeeded.
      return Editor.Files.Open_File (To_String (S.File_Info.Path));
   end Read_Active_Buffer_Associated_File_For_Reload;

   procedure Apply_Reloaded_Text_After_Read
     (S        : in out Editor.State.State_Type;
      Contents : Unbounded_String)
   is
      procedure Set_Reloaded_Text (B : in out Text_Buffer.Buffer_Type) is
      begin
         Text_Buffer.Set_Text (B, To_String (Contents));
      end Set_Reloaded_Text;
   begin
      --  Successful-read text replacement is active-buffer-only and happens
      --  only after the canonical file read has succeeded.
      Editor.State.Mutate_Buffer (S, Set_Reloaded_Text'Access);
   end Apply_Reloaded_Text_After_Read;

   procedure Apply_Reload_Buffer_Local_Lifecycle
     (S : in out Editor.State.State_Type) is
   begin
      --  Successful reload is not an undoable edit.  The prior edit stacks
      --  describe a different document state, so they are discarded only
      --  after the canonical read has succeeded.  Clipboard and unrelated
      --  feature state are deliberately left untouched.
      Editor.History.Undo_Stack.Clear;
      Editor.History.Redo_Stack.Clear;

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 0,
            Anchor                => 0,
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      S.Preferred_Column := 0;
      S.Rect_Select_Active := False;
      S.Rect_Anchor_Row := 0;
      S.Rect_Anchor_Col := 0;
      Editor.View.Reset_Scroll;
   end Apply_Reload_Buffer_Local_Lifecycle;

   procedure File_Lifecycle_Invalidate_Derived_State
     (S      : in out Editor.State.State_Type;
      Reason : String)
   is
      Source_Path : constant String :=
        (if S.File_Info.Has_Path then To_String (S.File_Info.Path) else "");
      Relative_Path : constant String :=
        (if Source_Path'Length > 0
           and then Editor.Project.Has_Project (S.Project)
           and then Editor.Project.Is_Under_Project (S.Project, Source_Path)
         then Editor.Project.Relative_Path (S.Project, Source_Path)
         else "");
   begin
      --  File content lifecycle operations stale derived state through
      --  Executor-owned runtime state only.  They do not refresh outline,
      --  search, diagnostics, build, quick-open, render, or persistence data.
      S.Active_Find_Stale := True;
      Editor.Outline.Clear (S.Outline);
      S.Outline_Cursor_Key_Valid := False;
      Editor.Project_Search.Mark_Stale_Unconditionally (S.Project_Search);
      Editor.Project_Search.Mark_Replace_Preview_Stale (S.Project_Search);
      Editor.Feature_Diagnostics.Mark_Diagnostics_For_Buffer_Stale
        (S.Feature_Diagnostics, S.Active_Buffer_Token);

      if Source_Path'Length > 0 then
         Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
           (S.Feature_Diagnostics, Source_Path, Source_Path);
      end if;

      if Relative_Path'Length > 0 then
         Editor.Feature_Diagnostics.Mark_Diagnostics_For_Source_Path_Stale
           (S.Feature_Diagnostics, Relative_Path, Relative_Path);
      end if;

      --  file lifecycle changes make
      --  parser-owned Outline/semantic targets stale.  Drop any indexed row
      --  for the active buffer token so Save As/rename/delete/reload/revert
      --  cannot leave the old path/revision/fingerprint available to language
      --  navigation.  Also remove the current source path when available.
      if Source_Path'Length > 0 then
         Editor.Ada_Project_Index.Invalidate_Path (S.Language_Index, Source_Path);
         Editor.Ada_Language_Service.Invalidate_Path
           (S.Language_Service, Source_Path);
      end if;
      if S.Active_Buffer_Token /= 0 then
         Editor.Ada_Project_Index.Invalidate_Buffer
           (S.Language_Index, S.Active_Buffer_Token);
         Editor.Ada_Language_Service.Invalidate_Buffer
           (S.Language_Service, S.Active_Buffer_Token);
      end if;

      if To_String (S.Build_UI.Selected_Build_Candidate_Id)'Length > 0 then
         S.Build_UI.Selected_Candidate_Stale := True;
         S.Build_UI.Consent_Acknowledged := False;
         S.Build_UI.Pending_Public_Build_Request := False;
         S.Build_UI.Candidate_Selection_Message := To_Unbounded_String (Reason);
         S.Build_UI.Validation_Status :=
           Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale;
         S.Build_UI.Validation_Message := To_Unbounded_String
           (Editor.Build_UI.Validation_Message
              (Editor.Build_UI.Build_UI_Rejected_Selected_Candidate_Stale));
      end if;
   end File_Lifecycle_Invalidate_Derived_State;

   procedure Update_Saved_Baseline_After_Reload
     (S              : in out Editor.State.State_Type;
      Reload_Path    : Unbounded_String;
      Reload_Display : Unbounded_String)
   is
   begin
      --  Canonical reload baseline/dirty update path.  It is invoked only
      --  after a successful read and active-buffer text replacement.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Reload_Path;
      S.File_Info.Display_Name := Reload_Display;
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Capture_Active_File_Token (S);
      Clear_File_Conflict_Prompt (S);
      Editor.State.Reset_Dirty_Line_Baseline (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Update_Saved_Baseline_After_Reload;

   procedure Execute_Reload_Active_Buffer
     (S : in out Editor.State.State_Type)
   is
      Result : Editor.Files.File_Open_Result;
   begin
      --  Canonical file.reload-buffer path: active-buffer target,
      --  retained validation order, associated-path-only read, dirty guard,
      --  canonical file read, text replacement after read success, baseline
      --  update after replacement, and retained buffer-local lifecycle policy.
      if not Resolve_Active_Buffer_Reload_Target (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif not Validate_Active_Buffer_Associated_Path_For_Reload (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif Dirty_Buffer_Reload_Blocked (S) then
         Editor.Executor.Pending_Transition_Policy.Set_Pending_Dirty_Transition (S,
            Editor.Executor.Pending_Transition_Policy.Pending_Target_For (Editor.Pending_Transitions.Pending_Reload_Active_Buffer,
               Path => To_String (S.File_Info.Path),
               Display => To_String (S.File_Info.Display_Name),
               Buffer_Id => Editor.Buffers.Global_Active_Buffer),
            Editor.Dirty_Guards.Blocked
              ((Dirty_Count       => 1,
                Untitled_Count    => (if S.File_Info.Has_Path then 0 else 1),
                File_Backed_Count => (if S.File_Info.Has_Path then 1 else 0)),
               "Dirty buffer cannot be reloaded"));
         return;
      end if;

      declare
         Reload_Path    : constant Unbounded_String := S.File_Info.Path;
         Reload_Display : constant Unbounded_String := S.File_Info.Display_Name;
      begin
         Result := Read_Active_Buffer_Associated_File_For_Reload (S);

         if not Editor.Files.Is_Success (Result) then
            S.File_Info.Last_Reload_Failed := True;
            S.File_Info.Missing_Target_Surfaced :=
              Result.Status = Editor.Files.File_Open_Not_Found;
            S.File_Info.Unreadable_Target_Surfaced :=
              Result.Status in Editor.Files.File_Open_Permission_Denied
                | Editor.Files.File_Open_Read_Error
                | Editor.Files.File_Open_Decode_Error
                | Editor.Files.File_Open_Is_Directory
                | Editor.Files.File_Open_Invalid_Path;
            Editor.Buffers.Sync_Global_Active_From_State (S);
            Editor.Executor.Shared_Services.Report_Error (S, Read_Failure_Recovery_Message (Result, "reload"));
            return;
         end if;

         Apply_Reloaded_Text_After_Read (S, Result.Contents);
         Apply_Reload_Buffer_Local_Lifecycle (S);
         Update_Saved_Baseline_After_Reload
           (S, Reload_Path, Reload_Display);
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after reload");
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Buffer reloaded");
      end;
   end Execute_Reload_Active_Buffer;

   function Dirty_Buffer_Revert_Eligible
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Revert is the explicit dirty-buffer counterpart to reload.  Clean
      --  buffers are no-ops and are not reread here.
      return S.File_Info.Dirty;
   end Dirty_Buffer_Revert_Eligible;

   function Read_Active_Buffer_Associated_File_For_Revert
     (S : Editor.State.State_Type) return Editor.Files.File_Open_Result is
   begin
      --  Reuse canonical file-read behavior.  This is reached only during
      --  command execution after active-buffer, associated-path, and dirty
      --  eligibility checks have succeeded.
      return Editor.Files.Open_File (To_String (S.File_Info.Path));
   end Read_Active_Buffer_Associated_File_For_Revert;

   procedure Apply_Reverted_Text_After_Read
     (S        : in out Editor.State.State_Type;
      Contents : Unbounded_String)
   is
   begin
      --  The revert replacement has the same destructive text-replacement
      --  lifecycle as a successful reload, but is only legal for dirty
      --  associated buffers and only after a successful read.
      Apply_Reloaded_Text_After_Read (S, Contents);
   end Apply_Reverted_Text_After_Read;

   procedure Apply_Revert_Buffer_Local_Lifecycle
     (S : in out Editor.State.State_Type) is
   begin
      Apply_Reload_Buffer_Local_Lifecycle (S);
   end Apply_Revert_Buffer_Local_Lifecycle;

   procedure Update_Saved_Baseline_After_Revert
     (S              : in out Editor.State.State_Type;
      Revert_Path    : Unbounded_String;
      Revert_Display : Unbounded_String) is
   begin
      Update_Saved_Baseline_After_Reload (S, Revert_Path, Revert_Display);
   end Update_Saved_Baseline_After_Revert;

   procedure Execute_Revert_Active_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Canonical file.revert-buffer path: active-buffer target,
      --  associated-path-only read, explicit dirty eligibility, no clean
      --  reload side effect, canonical file read, text replacement only after
      --  read success, baseline update only after replacement, and retained
      --  buffer-local destructive text-replacement lifecycle policy.
      if not Resolve_Active_Buffer_Revert_Target (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif not Validate_Active_Buffer_Associated_Path_For_Revert (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif not Dirty_Buffer_Revert_Eligible (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No changes to revert");
         return;
      else
         Editor.Executor.Pending_Transition_Policy.Set_Pending_Dirty_Transition (S,
            Editor.Executor.Pending_Transition_Policy.Pending_Target_For (Editor.Pending_Transitions.Pending_Revert_Active_Buffer,
               Path => To_String (S.File_Info.Path),
               Display => To_String (S.File_Info.Display_Name),
               Buffer_Id => Editor.Buffers.Global_Active_Buffer),
            Editor.Dirty_Guards.Blocked
              ((Dirty_Count       => 1,
                Untitled_Count    => (if S.File_Info.Has_Path then 0 else 1),
                File_Backed_Count => (if S.File_Info.Has_Path then 1 else 0)),
               (if Active_File_External_Status (S) =
                     Editor.Files.File_External_Status_Modified
                then "Revert changes to disk version? Disk version has changed since file was opened."
                elsif Active_File_External_Status (S) =
                     Editor.Files.File_External_Status_Missing
                then "Revert changes to disk version? Backing file is missing."
                elsif Active_File_External_Status (S) =
                     Editor.Files.File_External_Status_Replaced
                then "Revert changes to disk version? Backing file was replaced."
                else "Revert changes to disk version?")));
         return;
      end if;
   end Execute_Revert_Active_Buffer;

   procedure Execute_Save_All
     (S : in out Editor.State.State_Type)
   is
      Original : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Saved             : Natural := 0;
      Failed            : Natural := 0;
      Missing_Failed    : Natural := 0;
      Unwritable_Failed : Natural := 0;
      Other_Failed      : Natural := 0;
      Conflicted        : Natural := 0;
      Untitled          : Natural := 0;

      procedure Load_Current_Global_Active_Preserving_Language_Index is
         Saved_Index : constant Editor.Ada_Project_Index.Index_State :=
           S.Language_Index;
         Saved_Service : constant Editor.Ada_Language_Service.Service_State :=
           S.Language_Service;
      begin
         Editor.Buffers.Load_Global_Active_Into_State (S);
         S.Language_Index := Saved_Index;
         S.Language_Service := Saved_Service;
      end Load_Current_Global_Active_Preserving_Language_Index;

      function Save_Current_File_Backed_Buffer
        (Status : out Editor.Files.File_Save_Status) return Boolean
      is
         Result : Editor.Files.File_Save_Result;
      begin
         Status := Editor.Files.File_Save_No_Current_Path;
         if not S.File_Info.Has_Path or else Length (S.File_Info.Path) = 0 then
            return False;
         end if;

         declare
            External_Status : constant Editor.Files.File_External_Change_Status :=
              Active_File_External_Status (S);
         begin
            if Conflict_Kind_For_Status (External_Status, S.File_Info.Dirty) /=
              Editor.State.No_File_Conflict
              and then External_Status /= Editor.Files.File_External_Status_Missing
              and then not Active_Save_Target_Is_Existing_Nonregular (S)
            then
               Status := Editor.Files.File_Save_Write_Error;
               S.File_Info.Last_Save_Failed := True;
               S.File_Info.External_Change_Surfaced :=
                 External_Status = Editor.Files.File_External_Status_Modified;
               S.File_Info.Missing_Target_Surfaced :=
                 External_Status = Editor.Files.File_External_Status_Missing;
               S.File_Info.Unreadable_Target_Surfaced :=
                 External_Status in Editor.Files.File_External_Status_Unreadable
                   | Editor.Files.File_External_Status_Replaced;
               Editor.Buffers.Sync_Global_Active_From_State (S);
               return False;
            end if;
         end;

         if Active_Save_Target_Is_Existing_Unwritable (S) then
            Status := Editor.Files.File_Save_Permission_Denied;
            S.File_Info.Last_Save_Failed := True;
            S.File_Info.Unwritable_Target_Surfaced := True;
            Editor.Buffers.Sync_Global_Active_From_State (S);
            return False;
         end if;

         Apply_Format_On_Save_If_Enabled (S);

         Result := Editor.Files.Save_File
           (Path     => To_String (S.File_Info.Path),
            Contents => Editor.State.Current_Text (S));

         Status := Result.Status;

         if Editor.Files.Is_Success (Result) then
            S.File_Info.Has_Path := True;
            S.File_Info.Path := Result.Path;
            S.File_Info.Display_Name := Result.Display_Name;
            S.File_Info.Dirty := False;
            S.File_Info.Baseline_Valid := True;
            S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
            S.File_Info.Last_Save_Failed := False;
            S.File_Info.Missing_Target_Surfaced := False;
            S.File_Info.Blocked_Close_Surfaced := False;
            S.File_Info.Last_Reload_Failed := False;
            S.File_Info.Last_Revert_Failed := False;
            S.File_Info.Unreadable_Target_Surfaced := False;
            S.File_Info.Unwritable_Target_Surfaced := False;
            S.File_Info.External_Change_Surfaced := False;
            Capture_Active_File_Token (S);
            Clear_File_Conflict_Prompt (S);
            File_Lifecycle_Invalidate_Derived_State
              (S, "Derived state is stale after save");
            Editor.State.Reset_Dirty_Line_Baseline (S);
            Editor.Buffers.Sync_Global_Active_From_State (S);
            return True;
         else
            S.File_Info.Last_Save_Failed := True;
            S.File_Info.Missing_Target_Surfaced :=
              Result.Status in Editor.Files.File_Save_No_Current_Path
                | Editor.Files.File_Save_Invalid_Path
                | Editor.Files.File_Save_Parent_Unavailable;
            S.File_Info.Unwritable_Target_Surfaced :=
              Result.Status in Editor.Files.File_Save_Permission_Denied
                | Editor.Files.File_Save_Write_Error
                | Editor.Files.File_Save_Is_Directory;
            Editor.Buffers.Sync_Global_Active_From_State (S);
            return False;
         end if;
      end Save_Current_File_Backed_Buffer;
   begin
      if Editor.Executor.File_Lifecycle_Confirmation_Pending (S) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Original := Editor.Buffers.Global_Active_Buffer;
      Untitled := Editor.Buffers.Global_Dirty_Untitled_Buffer_Count;

      declare
         Registry : constant Editor.Buffers.Buffer_Registry :=
           Editor.Buffers.Global_Registry_For_UI;
      begin
         for Index in 1 .. Editor.Buffers.Buffer_Count (Registry) loop
            declare
               Summary : constant Editor.Buffers.Buffer_Summary :=
                 Editor.Buffers.Summary_At (Registry, Index);
               Buffer_State : Editor.State.State_Type;
            begin
               if Summary.Id /= Editor.Buffers.No_Buffer then
                  Buffer_State := Editor.Buffers.Buffer (Registry, Summary.Id);
                  if Buffer_State.File_Info.Dirty
                    and then Buffer_State.File_Info.Has_Path
                  then
                     Editor.Buffers.Global_Set_Active_Buffer (Summary.Id);
                     Load_Current_Global_Active_Preserving_Language_Index;
                     declare
                        Status : Editor.Files.File_Save_Status;
                     begin
                        if Save_Current_File_Backed_Buffer (Status) then
                           Saved := Saved + 1;
                        elsif Status = Editor.Files.File_Save_Write_Error
                          and then
                            (S.File_Info.External_Change_Surfaced
                             or else S.File_Info.Missing_Target_Surfaced
                             or else S.File_Info.Unreadable_Target_Surfaced)
                        then
                           --  command-boundary conflict skips are
                           --  not failed writes.  They are deliberate
                           --  no-write decisions requiring explicit user
                           --  resolution.  Keep them out of the ordinary
                           --  failed-file count so the summary can say
                           --  "Saved N files; M conflicts need attention"
                           --  without implying that a write was attempted.
                           Conflicted := Conflicted + 1;
                        else
                           Failed := Failed + 1;
                           case Status is
                              when Editor.Files.File_Save_No_Current_Path
                                 | Editor.Files.File_Save_Invalid_Path
                                 | Editor.Files.File_Save_Parent_Unavailable =>
                                 Missing_Failed := Missing_Failed + 1;
                              when Editor.Files.File_Save_Permission_Denied
                                 | Editor.Files.File_Save_Write_Error
                                 | Editor.Files.File_Save_Is_Directory =>
                                 Unwritable_Failed := Unwritable_Failed + 1;
                              when Editor.Files.File_Save_Ok =>
                                 Other_Failed := Other_Failed + 1;
                           end case;
                        end if;
                     end;
                  end if;
               end if;
            end;
         end loop;
      end;

      if Original /= Editor.Buffers.No_Buffer
        and then Editor.Buffers.Global_Contains (Original)
      then
         Editor.Buffers.Global_Set_Active_Buffer (Original);
         Load_Current_Global_Active_Preserving_Language_Index;
      end if;

      if Saved > 0 then
         --  Save All may have saved only inactive buffers.  The per-buffer
         --  save path marks state stale while each buffer is temporarily
         --  active, but restoring the original active buffer reloads its
         --  snapshot.  Reassert the editor-level stale state after restore so
         --  project search, replace previews, diagnostics, outline, and build
         --  candidate state cannot remain apparently current after any saved
         --  file-backed buffer changed on disk.
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after save all");
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      declare
         Message : Unbounded_String := Null_Unbounded_String;

         procedure Append (Text : String) is
         begin
            if Length (Message) > 0 then
               Ada.Strings.Unbounded.Append (Message, "; ");
            end if;
            Ada.Strings.Unbounded.Append (Message, Text);
         end Append;
      begin
         if Saved > 0 then
            Append ("Saved " & Count_Text (Saved, "file", "files"));
         end if;

         if Failed > 0 then
            Append (Count_Text (Failed, "file failed", "files failed"));
            if Missing_Failed > 0 then
               Append
                 (Count_Text
                    (Missing_Failed,
                     "missing or invalid backing path",
                     "missing or invalid backing paths"));
            end if;
            if Unwritable_Failed > 0 then
               Append
                 (Count_Text
                    (Unwritable_Failed,
                     "unwritable backing file",
                     "unwritable backing files"));
            end if;
            if Other_Failed > 0 then
               Append
                 (Count_Text
                    (Other_Failed,
                     "other save failure",
                     "other save failures"));
            end if;
         end if;

         if Conflicted > 0 then
            Append
              (Count_Text
                 (Conflicted,
                  "conflict needs attention",
                  "conflicts need attention"));
         end if;

         if Untitled > 0 then
            Append
              (Count_Text
                 (Untitled,
                  "untitled buffer still has unsaved changes",
                  "untitled buffers still have unsaved changes"));
         end if;

         if Length (Message) = 0 then
            Editor.Executor.Shared_Services.Report_Info (S, Editor.Dirty_Guards.No_Dirty_File_Backed_Buffers_Message);
         elsif Failed > 0 or else Conflicted > 0 then
            Editor.Executor.Shared_Services.Report_Warning (S, To_String (Message));
         else
            Editor.Executor.Shared_Services.Report_Success (S, To_String (Message));
         end if;
      end;
   end Execute_Save_All;

   function Save_As_Target_Parent_Missing
     (Path : String) return Boolean
   is
      Dir : constant String := Ada.Directories.Containing_Directory (Path);
   begin
      return Dir'Length > 0 and then not Ada.Directories.Exists (Dir);
   exception
      when others =>
         return False;
   end Save_As_Target_Parent_Missing;

   procedure Resolve_Active_Buffer_Save_As_Source
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Canonical Save As source resolver.  Save As binds to the
      --  active global buffer at command execution time only; switcher rows,
      --  palette rows, quick-open results, render focus, most-recently-edited
      --  buffers, first-dirty buffers, Save All expansion, and workspace order
      --  are not Save As sources.
      Resolve_Active_Buffer_Save_Target (S);
   end Resolve_Active_Buffer_Save_As_Source;

   function Validate_Save_As_Target_Path
     (Path : String) return Boolean
   is
      Found    : Boolean := False;
      Existing : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      --  Canonical target contract: the path must be explicit and
      --  must not identify a different open buffer.  No target history, recent
      --  project fallback, workspace fallback, project-root fallback, switcher
      --  fallback, quick-open fallback, chooser state, or write probe is used.
      if Path'Length = 0 then
         return False;
      end if;

      Existing := Editor.Buffers.Global_Find_By_Path (Path, Found);
      return not Found or else Existing = Editor.Buffers.Global_Active_Buffer;
   end Validate_Save_As_Target_Path;

   function Serialize_Active_Buffer_Current_Text_For_Save_As
     (S : Editor.State.State_Type) return String
   is
   begin
      --  Save As shares the canonical in-memory save serializer.  Rendered
      --  rows, disk rereads, clipboard/find/search text, formatting helpers,
      --  whitespace trimming, final-newline insertion, and newline conversion
      --  are outside this command.
      return Serialize_Active_Buffer_Current_Text_For_Save (S);
   end Serialize_Active_Buffer_Current_Text_For_Save_As;

   function Write_Active_Buffer_Text_To_Save_As_Target
     (S    : Editor.State.State_Type;
      Path : String) return Editor.Files.File_Save_Result
   is
   begin
      --  The only intended filesystem effect of file.save-as is this explicit
      --  target write.  Workspace/settings/recent-project files, old associated
      --  paths, inactive buffers, autosave files, backups, locks, and logs are
      --  not reachable from this helper.
      return Editor.Files.Save_File
        (Path     => Path,
         Contents => Serialize_Active_Buffer_Current_Text_For_Save_As (S));
   end Write_Active_Buffer_Text_To_Save_As_Target;

   procedure Update_Active_Buffer_Path_After_Save_As
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      --  Call only after the explicit target write succeeds.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Path;
      S.File_Info.Display_Name := Result.Display_Name;
   end Update_Active_Buffer_Path_After_Save_As;

   procedure Update_Saved_Baseline_After_Save_As
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Call only after the explicit target write succeeds and after the
      --  active buffer association has been updated to that target.
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Editor.State.Reset_Dirty_Line_Baseline (S);
   end Update_Saved_Baseline_After_Save_As;

   procedure Mark_Active_Buffer_Saved_As
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Save_Result)
   is
   begin
      Update_Active_Buffer_Path_After_Save_As (S, Result);
      Update_Saved_Baseline_After_Save_As (S);
      --  completeness: Save As is an explicit file lifecycle
      --  recovery path.  A successful Save As establishes a new backing disk
      --  version, so the transient token must advance and any prior conflict
      --  prompt/marker for the old path must be cleared.
      Capture_Active_File_Token (S);
      Clear_File_Conflict_Prompt (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Active_Buffer_Saved_As;

   procedure Execute_Save_As
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Previous_File  : Editor.State.File_State;
      Previous_Dirty : Boolean := False;
      Previous_Saved : Natural := 0;
      Previous_Valid : Boolean := False;
      Result         : Editor.Files.File_Save_Result;
      Parent_Missing : Boolean := False;
   begin
      --  Canonical Save As: execution-time active-buffer source,
      --  explicit target validation, exact current-text serialization, explicit
      --  target write, then active-buffer association/baseline/dirty update only
      --  after write success.
      Editor.Executor.Clear_Restore_Feedback_Current (S);
      if S.File_Conflict_Prompt_Active
        or else (Editor.Executor.File_Lifecycle_Confirmation_Pending (S)
                 and then not S.Dirty_Close_Prompt_Active)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;
      Resolve_Active_Buffer_Save_As_Source (S);

      if not Active_Buffer_Save_Target_Available (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      elsif Path'Length = 0 then
         Editor.Executor.Shared_Services.Report_Error (S, "No target path for Save As");
         return;
      elsif not Validate_Save_As_Target_Path (Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid Save As target");
         return;
      end if;

      Apply_Format_On_Save_If_Enabled (S);

      Previous_File := S.File_Info;
      Previous_Dirty := S.File_Info.Dirty;
      Previous_Saved := S.File_Info.Saved_Generation;
      Previous_Valid := S.File_Info.Baseline_Valid;

      Parent_Missing := Save_As_Target_Parent_Missing (Path);
      Result := Write_Active_Buffer_Text_To_Save_As_Target (S, Path);

      if Editor.Files.Is_Success (Result) then
         Mark_Active_Buffer_Saved_As (S, Result);
         Clear_Dirty_Close_Prompt (S);
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after save as");
         if Editor.Project.Has_Project (S.Project)
           and then Editor.Project.Is_Under_Project (S.Project, Path)
         then
            declare
               Tree_Result : Editor.File_Tree.File_Tree_Scan_Result;
               Selection_Disappeared : Boolean := False;
            begin
               Editor.Executor.Project_File_Index_Commands.Refresh_Project_File_State
                 (S, Tree_Result, Selection_Disappeared, False);
            end;
         end if;
         Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Saved file as");
      else
         --  Preserve all editor-owned success state on failure.  No association,
         --  saved baseline, dirty state, Undo/Redo, Find/Replace, Clipboard,
         --  caret, selection, navigation, or text-entry state is advanced.
         S.File_Info := Previous_File;
         S.File_Info.Dirty := Previous_Dirty;
         S.File_Info.Saved_Generation := Previous_Saved;
         S.File_Info.Baseline_Valid := Previous_Valid;
         S.File_Info.Last_Save_Failed := True;
         S.File_Info.Missing_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_No_Current_Path
             | Editor.Files.File_Save_Invalid_Path
             | Editor.Files.File_Save_Parent_Unavailable;
         S.File_Info.Unwritable_Target_Surfaced :=
           Result.Status in Editor.Files.File_Save_Permission_Denied
             | Editor.Files.File_Save_Write_Error
             | Editor.Files.File_Save_Is_Directory;
         Editor.Buffers.Sync_Global_Active_From_State (S);

         if Result.Status = Editor.Files.File_Save_Is_Directory
           or else Result.Status = Editor.Files.File_Save_No_Current_Path
           or else
             (Result.Status = Editor.Files.File_Save_Invalid_Path
              and then not Parent_Missing)
         then
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid Save As target");
         elsif Result.Status = Editor.Files.File_Save_Parent_Unavailable
           or else Parent_Missing
         then
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         elsif Result.Status = Editor.Files.File_Save_Permission_Denied then
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         else
            Editor.Executor.Shared_Services.Report_Error (S, "Could not save file as");
         end if;
      end if;
   end Execute_Save_As;

end Editor.Executor.File_Save_Basic_Commands;
