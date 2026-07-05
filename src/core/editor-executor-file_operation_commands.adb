with Ada.Directories;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Ada_Language_Service;
with Editor.Ada_Project_Index;
with Editor.Buffers;
use type Editor.Buffers.Buffer_Id;
with Editor.Build_UI;
with Editor.Executor;
with Editor.Executor.Shared_Services;
use Editor.Executor.Shared_Services;
with Editor.Feature_Diagnostics;
with Editor.Files;
use type Editor.Files.File_Copy_Status;
use type Editor.Files.File_Delete_Status;
use type Editor.Files.File_Move_Status;
use type Editor.Files.File_Rename_Status;
with Editor.Outline;
with Editor.Project;
with Editor.Project_Search;
with Editor.State;

package body Editor.Executor.File_Operation_Commands is
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

      --  completeness pass 170: file lifecycle changes make
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

   function Resolve_Active_Buffer_Associated_File_Operation_Source
     (S : in out Editor.State.State_Type) return Boolean
   is
      Active_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      --  Canonical active-buffer associated-file operation source policy for
      --  file.rename-buffer-file, file.delete-buffer-file,
      --  file.copy-buffer-file, and file.move-buffer-file.  The source is
      --  the execution-time active global buffer only; no UI selection,
      --  history, workspace, recent-project, render, reopen-candidate, or
      --  test override source may broaden it.
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
         Editor.Buffers.Load_Global_Active_Into_State (S);
      end if;

      return True;
   end Resolve_Active_Buffer_Associated_File_Operation_Source;

   function Validate_Active_Buffer_Associated_Path_For_File_Operation
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Shared associated-path policy: commands operate only on the active
      --  buffer's current associated path.  Missing/empty paths fail before
      --  dirty guards, target checks, or filesystem operations; paths are not
      --  invented, repaired, or inferred from UI/persistence/history state.
      return S.File_Info.Has_Path and then Length (S.File_Info.Path) > 0;
   end Validate_Active_Buffer_Associated_Path_For_File_Operation;

   function Require_Clean_Active_Associated_Buffer_For_File_Operation
     (S : Editor.State.State_Type) return Boolean is
   begin
      --  Shared dirty guard.  Dirty associated buffers do not reach target
      --  validation or filesystem work, and this guard performs no save,
      --  save-as, discard, prompt, recovery, dirty-prune, or state repair.
      return not S.File_Info.Dirty;
   end Require_Clean_Active_Associated_Buffer_For_File_Operation;

   function Validate_Associated_File_Operation_Target_Path
     (Path : String) return Boolean is
   begin
      --  Rename/copy/move targets must be explicit and non-blank.  Deeper
      --  filesystem-specific failures remain owned by the canonical
      --  filesystem helpers without mutating editor state first.
      return Path'Length > 0
        and then Ada.Strings.Fixed.Trim (Path, Ada.Strings.Both)'Length > 0;
   end Validate_Associated_File_Operation_Target_Path;

   function Validate_Associated_File_Operation_Target_Collision
     (S    : Editor.State.State_Type;
      Path : String) return Boolean is
   begin
      --  Shared no-overwrite policy for rename/copy/move.  Same-source
      --  targets and existing files/directories are deterministic
      --  collisions, not no-ops, overwrites, prompts, or repairs.
      if S.File_Info.Has_Path
        and then Length (S.File_Info.Path) > 0
        and then To_String (S.File_Info.Path) = Path
      then
         return True;
      end if;

      return Ada.Directories.Exists (Path);
   exception
      when Ada.Directories.Name_Error =>
         return False;
      when others =>
         --  Unknown/prohibited target inspection is treated as execution
         --  failure by the filesystem helper rather than overwrite approval.
         return False;
   end Validate_Associated_File_Operation_Target_Collision;

   function Rename_Associated_File_Through_Canonical_Filesystem
     (S    : Editor.State.State_Type;
      Path : String) return Editor.Files.File_Rename_Result
   is
   begin
      --  This is the only filesystem effect of file.rename-buffer-file. It
      --  renames the old active associated path to the explicit target path;
      --  it never serializes, writes, saves-as, reloads, reverts, closes, or
      --  reopens buffer text.
      return Editor.Files.Rename_File
        (Source => To_String (S.File_Info.Path),
         Target => Path);
   end Rename_Associated_File_Through_Canonical_Filesystem;

   procedure Update_Association_After_Rename_Success
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Rename_Result)
   is
   begin
      --  Call only after the filesystem rename succeeds. Text, saved-baseline
      --  revision identity, clean state, Undo/Redo, caret, selection, find,
      --  clipboard, navigation, and text-entry state are intentionally left
      --  untouched.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Target_Path;
      S.File_Info.Display_Name := Result.Display_Name;
      --  Preserve the retained clean/diagnostic state exactly; validation
      --  already guarantees that dirty buffers never reach this point.
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Update_Association_After_Rename_Success;

   procedure Execute_Rename_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Previous_File : Editor.State.File_State;
      Result        : Editor.Files.File_Rename_Result;
   begin
      if S.File_Conflict_Prompt_Active
        or else (Editor.Executor.File_Lifecycle_Confirmation_Pending (S)
                 and then not S.Dirty_Close_Prompt_Active)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      if not Resolve_Active_Buffer_Associated_File_Operation_Source (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      end if;

      Previous_File := S.File_Info;

      if not Validate_Active_Buffer_Associated_Path_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif not Require_Clean_Active_Associated_Buffer_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer file cannot be renamed");
         return;
      elsif not Validate_Associated_File_Operation_Target_Path (Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid rename target");
         return;
      elsif Validate_Associated_File_Operation_Target_Collision (S, Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Rename target already exists");
         return;
      end if;

      Result := Rename_Associated_File_Through_Canonical_Filesystem (S, Path);

      if Editor.Files.Is_Success (Result) then
         Update_Association_After_Rename_Success (S, Result);
         --  pass 182: active-buffer filesystem rename changes both
         --  the old indexed source path and the adopted target association.
         --  Invalidate both path spellings plus the stable buffer token so
         --  indexed Outline/body/spec/semantic targets cannot survive the
         --  rename until an explicit language-index refresh rebuilds them.
         if Previous_File.Has_Path and then Length (Previous_File.Path) > 0 then
            Editor.Ada_Project_Index.Invalidate_Path
              (S.Language_Index, To_String (Previous_File.Path));
         end if;
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after rename");
         Editor.Executor.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Buffer file renamed");
      else
         S.File_Info := Previous_File;
         Editor.Buffers.Sync_Global_Active_From_State (S);

         if Result.Status = Editor.Files.File_Rename_Invalid_Target then
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid rename target");
         elsif Result.Status = Editor.Files.File_Rename_Target_Exists then
            Editor.Executor.Shared_Services.Report_Error (S, "Rename target already exists");
         else
            Editor.Executor.Shared_Services.Report_Error (S, "Could not rename buffer file");
         end if;
      end if;
   end Execute_Rename_Buffer_File;

   function Delete_Associated_File_Through_Canonical_Filesystem
     (S : Editor.State.State_Type) return Editor.Files.File_Delete_Result
   is
   begin
      --  This is the only filesystem effect of file.delete-buffer-file. It
      --  deletes the active associated regular file and never writes buffer
      --  text, renames, closes, reopens, snapshots, or moves anything to trash.
      return Editor.Files.Delete_File (To_String (S.File_Info.Path));
   end Delete_Associated_File_Through_Canonical_Filesystem;

   procedure Clear_Association_After_Delete_Success
     (S : in out Editor.State.State_Type)
   is
   begin
      --  Call only after filesystem delete success. The text and existing
      --  transient feature state are preserved; the buffer becomes an
      --  unsaved dirty untitled buffer so close/save/reload/revert/rename
      --  observe the retained no-associated-file policy.
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := False;
      S.File_Info.Saved_Generation := 0;
      S.File_Info.Last_Save_Failed := False;
      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unreadable_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.External_Change_Surfaced := False;
      S.File_Info.Blocked_Close_Surfaced := False;
      Editor.State.Refresh_Dirty_Lines (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Clear_Association_After_Delete_Success;

   procedure Execute_Delete_Buffer_File
     (S : in out Editor.State.State_Type)
   is
      Previous_File : Editor.State.File_State;
      Result        : Editor.Files.File_Delete_Result;
   begin
      if S.File_Conflict_Prompt_Active
        or else (Editor.Executor.File_Lifecycle_Confirmation_Pending (S)
                 and then not S.Dirty_Close_Prompt_Active)
      then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      if not Resolve_Active_Buffer_Associated_File_Operation_Source (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      end if;

      Previous_File := S.File_Info;

      if not Validate_Active_Buffer_Associated_Path_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif not Require_Clean_Active_Associated_Buffer_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer file cannot be deleted");
         return;
      end if;

      Result := Delete_Associated_File_Through_Canonical_Filesystem (S);

      if Editor.Files.Is_Success (Result) then
         Clear_Association_After_Delete_Success (S);
         --  pass 182: deletion clears the active association before
         --  ordinary lifecycle invalidation runs, so explicitly invalidate the
         --  previous backing path as well as the active buffer token.
         if Previous_File.Has_Path and then Length (Previous_File.Path) > 0 then
            Editor.Ada_Project_Index.Invalidate_Path
              (S.Language_Index, To_String (Previous_File.Path));
         end if;
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after delete");
         Editor.Executor.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Buffer file deleted");
      else
         S.File_Info := Previous_File;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Error (S, "Could not delete buffer file");
      end if;
   end Execute_Delete_Buffer_File;

   function Copy_Associated_File_Through_Canonical_Filesystem
     (S    : Editor.State.State_Type;
      Path : String) return Editor.Files.File_Copy_Result
   is
   begin
      --  This is the only filesystem effect of file.copy-buffer-file. It
      --  copies the active associated backing file to the explicit target;
      --  it never serializes buffer memory, saves, save-as, reloads, reverts,
      --  renames, deletes, closes, opens, or creates reopen candidates.
      return Editor.Files.Copy_File
        (Source => To_String (S.File_Info.Path),
         Target => Path);
   end Copy_Associated_File_Through_Canonical_Filesystem;

   procedure Execute_Copy_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Previous_File : Editor.State.File_State;
      Result        : Editor.Files.File_Copy_Result;
   begin
      if Editor.Executor.File_Lifecycle_Confirmation_Pending (S) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      if not Resolve_Active_Buffer_Associated_File_Operation_Source (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      end if;

      Previous_File := S.File_Info;

      if not Validate_Active_Buffer_Associated_Path_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif not Require_Clean_Active_Associated_Buffer_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer file cannot be copied");
         return;
      elsif not Validate_Associated_File_Operation_Target_Path (Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid copy target");
         return;
      elsif Validate_Associated_File_Operation_Target_Collision (S, Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Copy target already exists");
         return;
      end if;

      Result := Copy_Associated_File_Through_Canonical_Filesystem (S, Path);

      if Editor.Files.Is_Success (Result) then
         --  Copy has no editor-state adoption step. Preserve association,
         --  text, saved baseline, dirty state, open-buffer collection,
         --  Undo/Redo, caret/selection, find/replace, clipboard, navigation,
         --  text-entry, and reopen candidate state exactly.
         S.File_Info := Previous_File;
         Editor.Buffers.Sync_Global_Active_From_State (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Buffer file copied");
      else
         S.File_Info := Previous_File;
         Editor.Buffers.Sync_Global_Active_From_State (S);

         if Result.Status = Editor.Files.File_Copy_Invalid_Target then
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid copy target");
         elsif Result.Status = Editor.Files.File_Copy_Target_Exists then
            Editor.Executor.Shared_Services.Report_Error (S, "Copy target already exists");
         else
            Editor.Executor.Shared_Services.Report_Error (S, "Could not copy buffer file");
         end if;
      end if;
   end Execute_Copy_Buffer_File;


   function Move_Associated_File_Through_Canonical_Filesystem
     (S    : Editor.State.State_Type;
      Path : String) return Editor.Files.File_Move_Result
   is
   begin
      --  This is the only filesystem effect of file.move-buffer-file. It
      --  moves the active associated backing file to the explicit target;
      --  it never serializes buffer memory, saves, save-as, reloads, reverts,
      --  invokes the rename/copy/delete commands, closes, opens, or creates
      --  reopen candidates.
      return Editor.Files.Move_File
        (Source => To_String (S.File_Info.Path),
         Target => Path);
   end Move_Associated_File_Through_Canonical_Filesystem;

   procedure Update_Association_After_Move_Success
     (S      : in out Editor.State.State_Type;
      Result : Editor.Files.File_Move_Result)
   is
   begin
      --  Call only after filesystem move success. Text, saved-baseline text,
      --  clean state, Undo/Redo, caret, selection, find, clipboard,
      --  navigation, text-entry state, and open-buffer collection are left
      --  untouched except for the active buffer path/display association.
      S.File_Info.Has_Path := True;
      S.File_Info.Path := Result.Target_Path;
      S.File_Info.Display_Name := Result.Display_Name;
      --  Preserve the retained clean/diagnostic state exactly; validation
      --  already guarantees that dirty buffers never reach this point.
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Update_Association_After_Move_Success;

   procedure Execute_Move_Buffer_File
     (S    : in out Editor.State.State_Type;
      Path : String)
   is
      Previous_File : Editor.State.File_State;
      Result        : Editor.Files.File_Move_Result;
   begin
      if Editor.Executor.File_Lifecycle_Confirmation_Pending (S) then
         Editor.Executor.Shared_Services.Report_Warning (S, "Command unavailable while confirmation is pending");
         return;
      end if;

      if not Resolve_Active_Buffer_Associated_File_Operation_Source (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No active buffer.");
         return;
      end if;

      Previous_File := S.File_Info;

      if not Validate_Active_Buffer_Associated_Path_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "No file path for active buffer");
         return;
      elsif not Require_Clean_Active_Associated_Buffer_For_File_Operation (S) then
         Editor.Executor.Shared_Services.Report_Info (S, "Dirty buffer file cannot be moved");
         return;
      elsif not Validate_Associated_File_Operation_Target_Path (Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Invalid move target");
         return;
      elsif Validate_Associated_File_Operation_Target_Collision (S, Path) then
         Editor.Executor.Shared_Services.Report_Error (S, "Move target already exists");
         return;
      end if;

      Result := Move_Associated_File_Through_Canonical_Filesystem (S, Path);

      if Editor.Files.Is_Success (Result) then
         Update_Association_After_Move_Success (S, Result);
         --  pass 182: active-buffer filesystem move is a lifecycle
         --  mutation for language-index targets.  Drop the old source path,
         --  the new adopted path, and the buffer-token row before reporting
         --  success.
         if Previous_File.Has_Path and then Length (Previous_File.Path) > 0 then
            Editor.Ada_Project_Index.Invalidate_Path
              (S.Language_Index, To_String (Previous_File.Path));
         end if;
         File_Lifecycle_Invalidate_Derived_State
           (S, "Derived state is stale after move");
         Editor.Executor.Rebuild_Language_Index_After_File_Lifecycle (S);
         Editor.Executor.Shared_Services.Report_Success (S, "Buffer file moved");
      else
         S.File_Info := Previous_File;
         Editor.Buffers.Sync_Global_Active_From_State (S);

         if Result.Status = Editor.Files.File_Move_Invalid_Target then
            Editor.Executor.Shared_Services.Report_Error (S, "Invalid move target");
         elsif Result.Status = Editor.Files.File_Move_Target_Exists then
            Editor.Executor.Shared_Services.Report_Error (S, "Move target already exists");
         else
            Editor.Executor.Shared_Services.Report_Error (S, "Could not move buffer file");
         end if;
      end if;
   end Execute_Move_Buffer_File;

end Editor.Executor.File_Operation_Commands;
