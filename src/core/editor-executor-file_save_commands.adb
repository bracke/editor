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
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Semantic_Index_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Feature_Diagnostics;
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
with Editor.Invariants;
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
with Editor.Executor.Buffer_Close_Prompt_Commands;
with Editor.Executor.Buffer_Close_Commands;

package body Editor.Executor.File_Save_Commands is

   use Editor.Commands;

   procedure Clear_Dirty_Close_Prompt
     (S : in out Editor.State.State_Type) renames
       Editor.Executor.Buffer_Close_Prompt_Commands.Clear_Dirty_Close_Prompt;

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

   function External_Status_Code
     (Status : Editor.Files.File_External_Change_Status) return Natural
   is
   begin
      case Status is
         when Editor.Files.File_External_Status_Unknown => return 0;
         when Editor.Files.File_External_Status_Unchanged => return 1;
         when Editor.Files.File_External_Status_Modified => return 2;
         when Editor.Files.File_External_Status_Missing => return 3;
         when Editor.Files.File_External_Status_Unreadable => return 4;
         when Editor.Files.File_External_Status_Replaced => return 5;
      end case;
   end External_Status_Code;

   function External_Status_From_Code
     (Code : Natural) return Editor.Files.File_External_Change_Status
   is
   begin
      case Code is
         when 1 => return Editor.Files.File_External_Status_Unchanged;
         when 2 => return Editor.Files.File_External_Status_Modified;
         when 3 => return Editor.Files.File_External_Status_Missing;
         when 4 => return Editor.Files.File_External_Status_Unreadable;
         when 5 => return Editor.Files.File_External_Status_Replaced;
         when others => return Editor.Files.File_External_Status_Unknown;
      end case;
   end External_Status_From_Code;

   function Pending_File_State_Still_Current
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Boolean
   is
      Expected : constant Editor.Files.File_External_Change_Status :=
        External_Status_From_Code (Target.Observed_File_Status_Code);
      Current  : Editor.Files.File_External_Change_Status;
   begin
      if not Target.Has_Observed_File_Status then
         return True;
      elsif not Target.Has_Path or else Length (Target.Path) = 0 then
         return False;
      end if;

      --  If the prompt observed a regular file, compare the current disk
      --  metadata to the token captured at prompt creation.  This treats both
      --  initially-unchanged and initially-modified regular files as valid
      --  only while the same disk version is still present.  Non-regular or
      --  inaccessible states are validated by classification.
      case Expected is
         when Editor.Files.File_External_Status_Unchanged
            | Editor.Files.File_External_Status_Modified =>
            if not Target.Has_Observed_File_Token then
               return False;
            end if;
            Current := Editor.Files.External_Change_Status
              (To_String (Target.Path),
               True,
               To_String (Target.Observed_File_Token_Label));
            return Current = Editor.Files.File_External_Status_Unchanged;
         when Editor.Files.File_External_Status_Missing
            | Editor.Files.File_External_Status_Unreadable
            | Editor.Files.File_External_Status_Replaced =>
            Current := Editor.Files.External_Change_Status
              (To_String (Target.Path), True, "");
            return Current = Expected;
         when Editor.Files.File_External_Status_Unknown =>
            return True;
      end case;
   end Pending_File_State_Still_Current;

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

   function File_Conflict_Prompt_Disk_State_Is_Current
     (S : Editor.State.State_Type) return Boolean
   is
      Status : Editor.Files.File_External_Change_Status;
   begin
      if Length (S.File_Conflict_Prompt_Path) = 0 then
         return False;
      end if;

      --  Compare current metadata with the disk state captured at prompt
      --  creation.  For a modified regular file this requires the same
      --  observed token; for missing/replaced/unreadable files it requires
      --  the same current failure classification.  This prevents a prompt
      --  opened for one external disk version from later overwriting or
      --  reloading a different disk version silently.
      Status := Editor.Files.External_Change_Status
        (To_String (S.File_Conflict_Prompt_Path),
         True,
         To_String (S.File_Conflict_Prompt_Token_Label));

      case S.File_Conflict_Prompt_Kind is
         when Editor.State.External_Modified_While_Clean
            | Editor.State.External_Modified_While_Dirty =>
            return Status = Editor.Files.File_External_Status_Unchanged;
         when Editor.State.Backing_File_Deleted_While_Clean
            | Editor.State.Backing_File_Deleted_While_Dirty
            | Editor.State.Save_Target_Parent_Missing =>
            return Status = Editor.Files.File_External_Status_Missing;
         when Editor.State.Backing_File_Unreadable =>
            return Status = Editor.Files.File_External_Status_Unreadable;
         when Editor.State.Backing_File_Replaced =>
            return Status = Editor.Files.File_External_Status_Replaced;
         when others =>
            return False;
      end case;
   end File_Conflict_Prompt_Disk_State_Is_Current;

   function File_Conflict_Prompt_Is_Valid
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      if not S.File_Conflict_Prompt_Active
        or else S.File_Conflict_Prompt_Buffer = 0
        or else not Editor.Buffers.Global_Contains
          (Editor.Buffers.Buffer_Id (S.File_Conflict_Prompt_Buffer))
      then
         return False;
      end if;

      declare
         Buffer_State : constant Editor.State.State_Type :=
           Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI,
              Editor.Buffers.Buffer_Id (S.File_Conflict_Prompt_Buffer));
      begin
         return Buffer_State.File_Info.Has_Path
           and then Editor.Recent_Projects.Normalized_Root_Path
             (To_String (Buffer_State.File_Info.Path)) =
               Editor.Recent_Projects.Normalized_Root_Path
                 (To_String (S.File_Conflict_Prompt_Path))
           and then Buffer_State.File_Info.Dirty = S.File_Conflict_Prompt_Dirty
           and then Editor.State.Current_Buffer_Revision (Buffer_State) =
             S.File_Conflict_Prompt_Buffer_Revision
           and then File_Conflict_Prompt_Disk_State_Is_Current (S);
      end;
   end File_Conflict_Prompt_Is_Valid;

   procedure Load_File_Conflict_Buffer
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Conflict_Prompt_Buffer /= 0
        and then Editor.Buffers.Global_Contains
          (Editor.Buffers.Buffer_Id (S.File_Conflict_Prompt_Buffer))
      then
         Editor.Buffers.Global_Set_Active_Buffer
           (Editor.Buffers.Buffer_Id (S.File_Conflict_Prompt_Buffer));
         Editor.Executor.Semantic_Index_Commands
           .Load_Global_Active_Preserving_Language_Index (S);
      end if;
   end Load_File_Conflict_Buffer;

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
         Editor.Executor.Semantic_Index_Commands
           .Load_Global_Active_Preserving_Language_Index (S);
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


   procedure Execute_Retry_Pending_Transition
     (S : in out Editor.State.State_Type)
   is
      Target : Editor.Pending_Transitions.Pending_Transition_Target;
      Guard  : Editor.Dirty_Guards.Dirty_Transition_Result;
   begin
      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Executor.Shared_Services.Report_Info (S, Editor.Dirty_Guards.No_Pending_Transition_Message);
         return;
      end if;

      Target := Editor.Pending_Transitions.Target (S.Pending_Transitions);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      if not Editor.Executor.Pending_Transition_Policy.Pending_Target_Is_Valid (S, Target) then
         if Target.Kind = Editor.Pending_Transitions.Pending_Restore_Workspace
           and then Target.Has_Path
           and then Editor.Project.Has_Project (S.Project)
           and then Editor.Recent_Projects.Normalized_Root_Path
             (Editor.Project.Root_Path (S.Project)) =
               Editor.Recent_Projects.Normalized_Root_Path (To_String (Target.Path))
           and then not Ada.Directories.Exists
             (Editor.Workspace_Persistence.Session_File_Path
                (To_String (Target.Path)))
         then
            Editor.Pending_Transitions.Clear (S.Pending_Transitions);
            Editor.Executor.Shared_Services.Report_Info (S, "No workspace state");
         else
            Editor.Pending_Transitions.Clear (S.Pending_Transitions);
            --  completeness: stale dirty reload/revert prompts are
            --  file-lifecycle confirmations, not generic project/close
            --  transitions.  Report the lifecycle operation that was rejected
            --  so users know no disk reload/revert occurred and their in-memory
            --  text was preserved.
            case Target.Kind is
               when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
                  Editor.Executor.Shared_Services.Report_Warning (S, "Reload confirmation is no longer valid");
               when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
                  Editor.Executor.Shared_Services.Report_Warning (S, "Revert confirmation is no longer valid");
               when others =>
                  Editor.Executor.Shared_Services.Report_Warning (S, Editor.Dirty_Guards.Pending_Transition_No_Longer_Valid_Message);
            end case;
         end if;
         return;
      end if;

      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_All_Buffers_Confirmed (S);
            return;
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            Editor.Executor.Buffer_Close_Prompt_Commands.Execute_Close_Other_Buffers_Confirmed (S, Editor.Buffers.Buffer_Id (Target.Buffer_Id));
            return;
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            if Editor.Buffers.Global_Contains
              (Editor.Buffers.Buffer_Id (Target.Buffer_Id))
            then
               declare
                  Target_Id : constant Editor.Buffers.Buffer_Id :=
                    Editor.Buffers.Buffer_Id (Target.Buffer_Id);
               begin
                  Editor.Buffers.Global_Set_Active_Buffer (Target_Id);
                  if S.Active_Buffer_Token = Natural (Target_Id) then
                     Editor.Buffers.Sync_Global_Active_From_State (S);
                  else
                     Editor.Executor.Semantic_Index_Commands
                       .Load_Global_Active_Preserving_Language_Index (S);
                  end if;
               end;
               declare
                  Reload_Path    : constant Unbounded_String := S.File_Info.Path;
                  Reload_Display : constant Unbounded_String := S.File_Info.Display_Name;
                  Result         : constant Editor.Files.File_Open_Result :=
                    Read_Active_Buffer_Associated_File_For_Reload (S);
               begin
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
                     Editor.Pending_Transitions.Clear (S.Pending_Transitions);
                     Editor.Executor.Shared_Services.Report_Error (S, Read_Failure_Recovery_Message (Result, "reload"));
                     return;
                  end if;
                  Apply_Reloaded_Text_After_Read (S, Result.Contents);
                  Apply_Reload_Buffer_Local_Lifecycle (S);
                  Update_Saved_Baseline_After_Reload (S, Reload_Path, Reload_Display);
                  File_Lifecycle_Invalidate_Derived_State
                    (S, "Derived state is stale after reload");
                  Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
                  Editor.Pending_Transitions.Clear (S.Pending_Transitions);
                  Editor.Executor.Shared_Services.Report_Success (S, "Buffer reloaded");
               end;
            end if;
            return;
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            if Editor.Buffers.Global_Contains
              (Editor.Buffers.Buffer_Id (Target.Buffer_Id))
            then
               declare
                  Target_Id : constant Editor.Buffers.Buffer_Id :=
                    Editor.Buffers.Buffer_Id (Target.Buffer_Id);
               begin
                  Editor.Buffers.Global_Set_Active_Buffer (Target_Id);
                  if S.Active_Buffer_Token = Natural (Target_Id) then
                     Editor.Buffers.Sync_Global_Active_From_State (S);
                  else
                     Editor.Executor.Semantic_Index_Commands
                       .Load_Global_Active_Preserving_Language_Index (S);
                  end if;
               end;
               declare
                  Revert_Path    : constant Unbounded_String := S.File_Info.Path;
                  Revert_Display : constant Unbounded_String := S.File_Info.Display_Name;
                  Result         : constant Editor.Files.File_Open_Result :=
                    Read_Active_Buffer_Associated_File_For_Revert (S);
               begin
                  if not Editor.Files.Is_Success (Result) then
                     S.File_Info.Last_Revert_Failed := True;
                     S.File_Info.Missing_Target_Surfaced :=
                       Result.Status = Editor.Files.File_Open_Not_Found;
                     S.File_Info.Unreadable_Target_Surfaced :=
                       Result.Status in Editor.Files.File_Open_Permission_Denied
                         | Editor.Files.File_Open_Read_Error
                         | Editor.Files.File_Open_Decode_Error
                         | Editor.Files.File_Open_Is_Directory
                         | Editor.Files.File_Open_Invalid_Path;
                     Editor.Buffers.Sync_Global_Active_From_State (S);
                     Editor.Pending_Transitions.Clear (S.Pending_Transitions);
                     Editor.Executor.Shared_Services.Report_Error (S, Read_Failure_Recovery_Message (Result, "revert"));
                     return;
                  end if;
                  Apply_Reverted_Text_After_Read (S, Result.Contents);
                  Apply_Revert_Buffer_Local_Lifecycle (S);
                  Update_Saved_Baseline_After_Revert (S, Revert_Path, Revert_Display);
                  File_Lifecycle_Invalidate_Derived_State
                    (S, "Derived state is stale after revert");
                  Editor.Executor.Semantic_Index_Commands.Rebuild_Language_Index_After_File_Lifecycle (S);
                  Editor.Pending_Transitions.Clear (S.Pending_Transitions);
                  Editor.Executor.Shared_Services.Report_Success (S, "Buffer reverted");
               end;
            end if;
            return;
         when others =>
            null;
      end case;

      Guard := Editor.Executor.Pending_Transition_Policy.Check_Pending_Transition (S, Target);
      if not Editor.Dirty_Guards.Is_Allowed (Guard) then
         Editor.Executor.Shared_Services.Report_Warning (S, Editor.Dirty_Guards.Save_Or_Resolve_Changes_First_Message);
         return;
      end if;

      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Editor.Buffers.Buffer_Id (Target.Buffer_Id));
         when Editor.Pending_Transitions.Pending_Close_All_Buffers
            | Editor.Pending_Transitions.Pending_Close_Other_Buffers
            | Editor.Pending_Transitions.Pending_Reload_Active_Buffer
            | Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            null;
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
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
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            Editor.Executor.Workspace_Commands.Execute_Restore_Workspace_State (S);
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            Editor.Executor.Project_Lifecycle_Commands
              .Execute_Guarded_Close_Project (S);
         when Editor.Pending_Transitions.No_Pending_Transition =>
            null;
      end case;

      --  Do not clear a still-valid pending transition just because dirty
      --  state was resolved.  Project-open failures remain retryable; successful
      --  project opens and workspace restores clear themselves through their
      --  normal guarded path.  Close-buffer retry clears once the target buffer
      --  has actually gone away.
      Editor.Executor.Pending_Transition_Policy.Invalidate_Pending_Transition_If_Stale (S);
   end Execute_Retry_Pending_Transition;

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

   procedure Execute_Cancel_Pending_Transition
     (S : in out Editor.State.State_Type)
   is
   begin
      if not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Executor.Shared_Services.Report_Info
           (S, Editor.Dirty_Guards.No_Pending_Transition_Message);
         return;
      end if;

      declare
         Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
           Editor.Pending_Transitions.Target (S.Pending_Transitions);
         Message : constant String :=
           (case Target.Kind is
              when Editor.Pending_Transitions.Pending_Switch_Project =>
                 "Switch project cancelled",
              when Editor.Pending_Transitions.Pending_Close_Project
                 | Editor.Pending_Transitions.Pending_Clear_Project =>
                 "Close project cancelled",
              when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
                 "Clear workspace cancelled",
              when Editor.Pending_Transitions.Pending_Open_Project
                 | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
                 "Project open cancelled",
              when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
                 "Reload cancelled",
              when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
                 "Revert cancelled",
              when others =>
                 Editor.Dirty_Guards.Pending_Transition_Canceled_Message);
      begin
         Editor.Pending_Transitions.Clear (S.Pending_Transitions);
         Editor.Executor.Shared_Services.Report_Info (S, Message);
      end;
   end Execute_Cancel_Pending_Transition;

end Editor.Executor.File_Save_Commands;
