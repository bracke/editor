with AUnit.Assertions; use AUnit.Assertions;
with Ada.Containers;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Configuration_Audit;
with Editor.Clipboard;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.Command_Palette_Projection;
with Editor.Executor.Shared_Services;
with Editor.Executor.Buffer_Close_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Selection_Commands;
with Editor.Files;
with Editor.Files.Test_Helpers; use Editor.Files.Test_Helpers;
with Editor.File_Tree;
with Editor.Buffers;
with Editor.Feature_Panel;
with Editor.History;
with Editor.Diagnostics;
with Editor.Dirty_Guards;
with Editor.Folding;
with Editor.Gutter_Markers;
with Editor.Render_Model;
with Editor.Render_Packet;
with Editor.Project_Search;
with Editor.Quick_Open;
with Editor.Recent_Buffers;
with Editor.State;
with Editor.Test_Helper;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Lifecycle_Guidance;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Overlay_Focus;
with Editor.Pending_Transitions;
with Editor.Search;
with Editor.Settings;
with Editor.View;
with Editor.Workspace_Persistence;
with Text_Buffer;

package body Editor.Files.Copy_Move_Association_Tests is

   use type Editor.Files.File_Status;
   use type Editor.Files.File_Open_Status;
   use type Editor.Files.File_Save_Status;
   use type Editor.Files.File_Move_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Command_Palette.Command_Palette_Row_Kind;
   use type Editor.Commands.Command_Family_Id;
   use type Editor.Commands.Command_Effect_Classification_Id;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Messages.Message_Severity;
   use type Editor.Navigation_History.Navigation_History_Reason;
   use type Editor.Configuration_Audit.Configuration_Audit_Status;
   use type Editor.State.File_Conflict_Kind;
   use type Editor.Overlay_Focus.Overlay_Target;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Workspace_Persistence.Workspace_Feature_Panel_Id;
   use type Editor.Workspace_Persistence.Workspace_Quick_Open_File_Kind_Filter;
   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   procedure Test_Copy_Command_Surface_And_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p453_surface.txt");
      Target       : constant String := Temp_Path ("p453_surface_copy.txt");
      Existing     : constant String := Temp_Path ("p453_surface_existing.txt");
      Cmd_Id       : Editor.Commands.Command_Id;
      Found        : Boolean := False;
      Descriptor   : Editor.Commands.Command_Descriptor;
      Availability : Editor.Commands.Command_Availability;
      M            : Editor.Messages.Editor_Message;
   begin
      Cmd_Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.copy-buffer-file", Found);
      Assert (Found and then Cmd_Id = Editor.Commands.Command_Copy_Buffer_File,
        "file.copy-buffer-file must resolve to canonical command id");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Copy_Buffer_File) = "file.copy-buffer-file",
        "copy must expose canonical stable command name");

      Descriptor := Editor.Commands.Descriptor
        (Editor.Commands.Command_Copy_Buffer_File);
      Assert (Descriptor.Category = Editor.Commands.File_Category
        and then Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Descriptor.Bindable
        and then not Descriptor.Destructive
        and then Descriptor.Lifecycle,
        "copy descriptor must be visible bindable File lifecycle command");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "copy unavailable without active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "no active buffer must emit deterministic message");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled copy text");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "copy unavailable for untitled active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no path must emit deterministic message");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Write_Bytes (Path, "copy dirty guard disk");
      Write_Bytes (Existing, "existing target");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "copy unavailable for dirty active associated buffer");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Path)
        and then Read_Bytes (Path) = "copy dirty guard disk"
        and then S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "copy dirty guard disk dirty",
        "dirty copy must be blocked before target validation, filesystem copy, or mutation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, "   ");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Invalid copy target"
        and then not Ada.Directories.Exists (Target),
        "blank target must fail before filesystem copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Copy target already exists"
        and then Read_Bytes (Existing) = "existing target"
        and then To_String (S.File_Info.Path) = Path,
        "existing target must be blocked without overwrite or association change");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Existing);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Command_Surface_And_Validation;


   procedure Test_Copy_Success_Preserves_Buffer_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p453_success.txt");
      Target        : constant String := Temp_Path ("p453_success_copy.txt");
      Rename_Target : constant String := Temp_Path ("p453_success_renamed.txt");
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Rename_Target);
      Write_Bytes (Path, "copy source disk text");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "source");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "target");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied",
        "successful copy must emit one deterministic success message");
      Assert (Ada.Directories.Exists (Path)
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Path) = "copy source disk text"
        and then Read_Bytes (Target) = "copy source disk text"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.Buffers.Global_Count = 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then To_String (S.Active_Find_Query) = "source"
        and then To_String (S.Active_Replace_Text) = "target",
        "success must copy disk source and preserve association/text/baseline/dirty/history/features");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file renamed"
        and then not Ada.Directories.Exists (Path)
        and then Ada.Directories.Exists (Rename_Target)
        and then Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Rename_Target,
        "rename after copy must operate on original association, not the copied target");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Rename_Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Rename_Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Success_Preserves_Buffer_State;


   procedure Test_Copy_Failure_And_Active_Isolation_Are_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Active_Path    : constant String := Temp_Path ("p453_active.txt");
      Inactive_Path  : constant String := Temp_Path ("p453_inactive.txt");
      Missing_Target : constant String := Ada.Directories.Compose
        (Temp_Path ("p453_missing_parent"), "copy.txt");
      Reopen_Path    : constant String := Temp_Path ("p453_reopen.txt");
      Active_Text    : Unbounded_String;
      Inactive_Text  : Unbounded_String;
      Active_Id      : Editor.Buffers.Buffer_Id;
      Inactive_Id    : Editor.Buffers.Buffer_Id;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Write_Bytes (Reopen_Path, "reopen disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty inactive");
      Inactive_Text := To_Unbounded_String (Buffer_Text (S));
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Active_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Missing_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not copy buffer file",
        "target parent filesystem failure must emit deterministic copy failure");
      Assert (not Ada.Directories.Exists (Missing_Target)
        and then Ada.Directories.Exists (Active_Path)
        and then Read_Bytes (Active_Path) = "active disk"
        and then To_String (S.File_Info.Path) = Active_Path
        and then Buffer_Text (S) = To_String (Active_Text)
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "filesystem failure must preserve active association/text/dirty/history/reopen candidate");

      Assert (Editor.Buffers.Global_Contains (Inactive_Id)
        and then Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
        and then Text_Buffer.UTF8_Text
          (Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).Buffer) =
             To_String (Inactive_Text),
        "failed copy must not mutate inactive buffer text or dirty state");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Missing_Target);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Failure_And_Active_Isolation_Are_Atomic;


   procedure Test_Copy_Source_And_Target_Failures_Preserve_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Path       : constant String := Temp_Path ("p453_missing_source.txt");
      Target     : constant String := Temp_Path ("p453_missing_source_copy.txt");
      Target_Dir : constant String := Temp_Path ("p453_existing_target_dir");
      Before_Text : Unbounded_String;
      Before_Path : Unbounded_String;
      Before_Base : Natural;
      Found      : Boolean := False;
      M          : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Target_Dir);
      Write_Bytes (Path, "disappearing source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;

      --  Source validation belongs to execution, not availability.  A file
      --  that disappears after the buffer was opened must fail atomically and
      --  must not adopt the requested target as buffer state.
      Remove_If_Exists (Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not copy buffer file"
        and then not Ada.Directories.Exists (Target)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty,
        "completeness: missing source must preserve association/text/baseline/dirty state");

      Write_Bytes (Path, "restored source");
      Editor.Messages.Clear (S.Messages);
      Ada.Directories.Create_Directory (Target_Dir);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target_Dir);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Copy target already exists"
        and then Ada.Directories.Exists (Target_Dir)
        and then Ada.Directories.Kind (Target_Dir) = Ada.Directories.Directory
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Dirty,
        "completeness: existing target directory must be treated as collision without mutation");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Target_Dir);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Target_Dir);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Source_And_Target_Failures_Preserve_State;


   procedure Test_Copy_File_Lifecycle_Interactions_Stay_On_Original_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("p453_lifecycle.txt");
      Target      : constant String := Temp_Path ("p453_lifecycle_copy.txt");
      Rename_Path : constant String := Temp_Path ("p453_lifecycle_renamed.txt");
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Rename_Path);
      Write_Bytes (Path, "lifecycle original");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Insert_Text_At (S, Buffer_Text (S)'Length, " saved");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Path
        and then S.File_Info.Dirty,
        "completeness: dirty lifecycle source must remain blocked before save");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Read_Bytes (Path) = "lifecycle original saved"
        and then Read_Bytes (Target) = "lifecycle original saved"
        and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty,
        "completeness: copy after save must copy disk source and keep original association");

      Insert_Text_At (S, Buffer_Text (S)'Length, " unsaved");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "lifecycle original saved"
        and then To_String (S.File_Info.Path) = Path
        and then Read_Bytes (Target) = "lifecycle original saved"
        and then not S.File_Info.Dirty,
        "completeness: revert after copy must reread the original associated path, not the copied file");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Path);
      Assert (Ada.Directories.Exists (Rename_Path)
        and then not Ada.Directories.Exists (Path)
        and then Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Rename_Path,
        "completeness: rename after copy must rename only the original associated source");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (Rename_Path)
        and then Ada.Directories.Exists (Target)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "completeness: delete after copy must delete the original association and leave copied target external");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Rename_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Rename_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_File_Lifecycle_Interactions_Stay_On_Original_Path;


procedure Test_Copy_Validation_Order_And_Active_Source_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Active_Path   : constant String := Temp_Path ("p454_active_source.txt");
      Inactive_Path : constant String := Temp_Path ("p454_inactive_source.txt");
      Target        : constant String := Temp_Path ("p454_active_copy.txt");
      Existing      : constant String := Temp_Path ("p454_existing_target.txt");
      Active_Id     : Editor.Buffers.Buffer_Id;
      Inactive_Id   : Editor.Buffers.Buffer_Id;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Write_Bytes (Existing, "existing target must survive");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, "   ");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer."
        and then not Ada.Directories.Exists (Target)
        and then Read_Bytes (Existing) = "existing target must survive",
        "no-active validation must precede target validation and filesystem copy");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty untitled copy source");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer"
        and then Read_Bytes (Existing) = "existing target must survive"
        and then S.File_Info.Dirty,
        "no-path validation must precede dirty and target-collision validation");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " unsaved");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, "");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then not Ada.Directories.Exists (Target)
        and then Read_Bytes (Active_Path) = "active disk"
        and then S.File_Info.Dirty,
        "dirty associated buffers must be blocked before missing-target validation or filesystem copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then Read_Bytes (Existing) = "existing target must survive",
        "dirty guard must precede target-collision validation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Active_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Copy target already exists"
        and then To_String (S.File_Info.Path) = Active_Path
        and then not S.File_Info.Dirty,
        "source-as-target copy must be a deterministic non-mutating collision");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty inactive");
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Read_Bytes (Target) = Read_Bytes (Active_Path)
        and then To_String (S.File_Info.Path) = Active_Path
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Editor.Buffers.Global_Count = 2
        and then Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty,
        "copy source must be execution-time active buffer, not switcher/quick-open/palette/inactive state");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Existing);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Validation_Order_And_Active_Source_Reliability;


   procedure Test_Copy_Preserves_Transient_State_On_Success_And_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p454_transient_source.txt");
      Target        : constant String := Temp_Path ("p454_transient_copy.txt");
      Missing_Target : constant String := Ada.Directories.Compose
        (Temp_Path ("p454_missing_parent"), "copy.txt");
      Reopen_Path   : constant String := Temp_Path ("p454_reopen_source.txt");
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Back   : Ada.Containers.Count_Type;
      Before_Fwd    : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
      Copy_Rows     : Natural := 0;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "transient disk");
      Write_Bytes (Reopen_Path, "reopen disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "transient");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "stable");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (Editor.Buffers.Global_Active_Buffer),
          Has_File_Path => True,
          File_Path => S.File_Info.Path,
          Display_Path => S.File_Info.Path,
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Find_Next));

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;
      Before_Caret := S.Carets (0);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Copy_Buffer_File then
               Copy_Rows := Copy_Rows + 1;
            end if;
         end loop;
      end if;
      declare
         Packet : Editor.Render_Packet.Render_Packet;
      begin
         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Render_Packet.Build_Render_Packet (Packet);
      end;
      Assert (Editor.Commands.Is_Available (Availability)
        and then Copy_Rows = 1
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Dirty
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = "transient"
        and then To_String (S.Active_Replace_Text) = "stable"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard",
        "availability, palette projection, and render must be read-only for copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Editor.Messages.Count (S.Messages) = 1
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "transient disk"
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor
        and then To_String (S.Active_Find_Query) = "transient"
        and then To_String (S.Active_Replace_Text) = "stable"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "successful copy must preserve text, association, baseline, dirty, UI transient, history, clipboard, navigation, and reopen state");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Missing_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not copy buffer file"
        and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor
        and then To_String (S.Active_Find_Query) = "transient"
        and then To_String (S.Active_Replace_Text) = "stable"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "filesystem copy failure must be non-mutating except for one copy failure message");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Missing_Target);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Preserves_Transient_State_On_Success_And_Failure;


   procedure Test_Copy_File_Lifecycle_And_Persistence_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("p454_lifecycle_source.txt");
      Target      : constant String := Temp_Path ("p454_lifecycle_copy.txt");
      Save_As     : constant String := Temp_Path ("p454_lifecycle_save_as.txt");
      Rename_Path : constant String := Temp_Path ("p454_lifecycle_renamed.txt");
      Workspace   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary     : Unbounded_String;
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence: workspace summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Save_As);
      Remove_If_Exists (Rename_Path);
      Write_Bytes (Path, "lifecycle original");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then To_String (S.File_Info.Path) = Path
        and then Read_Bytes (Target) = "lifecycle original",
        "copy success must leave original association active");

      Insert_Text_At (S, Buffer_Text (S)'Length, " saved");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = "lifecycle original saved"
        and then Read_Bytes (Target) = "lifecycle original"
        and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty,
        "save after copy must write only the original associated path");

      Write_Bytes (Path, "lifecycle disk reload");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "lifecycle disk reload"
        and then To_String (S.File_Info.Path) = Path
        and then Read_Bytes (Target) = "lifecycle original",
        "reload after copy must read the original associated path");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "lifecycle disk reload"
        and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty,
        "revert after copy must use the original associated path and preserved baseline policy");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Path);
      Assert (Ada.Directories.Exists (Rename_Path)
        and then not Ada.Directories.Exists (Path)
        and then Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Rename_Path,
        "rename after copy must rename only the original associated source");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (Rename_Path)
        and then Ada.Directories.Exists (Target)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "delete after copy must delete only the original associated source");

      Editor.State.Load_Text (S, "save-as text");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target & ".second");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Save_As)
        and then Read_Bytes (Target & ".second") = "save-as text",
        "Save As remains the path-association operation that can make an untitled buffer eligible for copy");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert_Summary_Excludes ("Buffer file copied");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("copy target");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("external modification");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Target & ".second");
      Remove_If_Exists (Save_As);
      Remove_If_Exists (Rename_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Target & ".second");
         Remove_If_Exists (Save_As);
         Remove_If_Exists (Rename_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_File_Lifecycle_And_Persistence_Reliability;




   procedure Test_Copy_Integrated_Workflow_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      A_Path       : constant String := Temp_Path ("p455_a.txt");
      A_Copy       : constant String := Temp_Path ("p455_a_copy.txt");
      A_Dirty_Copy : constant String := Temp_Path ("p455_a_dirty_copy.txt");
      A_Copy2      : constant String := Temp_Path ("p455_a_copy2.txt");
      A_Renamed    : constant String := Temp_Path ("p455_a_renamed.txt");
      A1_Copy      : constant String := Temp_Path ("p455_a1_copy.txt");
      B_Save_As    : constant String := Temp_Path ("p455_b_save_as.txt");
      B_Copy       : constant String := Temp_Path ("p455_b_copy.txt");
      C_Path       : constant String := Temp_Path ("p455_c.txt");
      C_Copy       : constant String := Temp_Path ("p455_c_copy.txt");
      C_Save_As    : constant String := Temp_Path ("p455_c_save_as.txt");
      C_Missing_Parent : constant String := Temp_Path ("p455_missing_parent");
      C_Missing_Copy   : constant String := Ada.Directories.Compose
        (C_Missing_Parent, "copy.txt");
      A_Id         : Editor.Buffers.Buffer_Id;
      B_Id         : Editor.Buffers.Buffer_Id;
      C_Id         : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;

      procedure Expect_Message (Text : String; Label : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found
           and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "integrated copy workflow: " & Label);
      end Expect_Message;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A_Copy);
      Remove_If_Exists (A_Dirty_Copy);
      Remove_If_Exists (A_Copy2);
      Remove_If_Exists (A_Renamed);
      Remove_If_Exists (A1_Copy);
      Remove_If_Exists (B_Save_As);
      Remove_If_Exists (B_Copy);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C_Copy);
      Remove_If_Exists (C_Save_As);
      Remove_If_Exists (C_Missing_Copy);
      Remove_If_Exists (C_Missing_Parent);
      Write_Bytes (A_Path, "A disk");
      Write_Bytes (C_Path, "C disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, 0, "B untitled");
      Before_Count := Natural (Editor.Buffers.Global_Count);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A_Copy);
      Expect_Message ("Buffer file copied", "clean associated A copies successfully");
      Assert (Read_Bytes (A_Copy) = "A disk"
        and then To_String (S.File_Info.Path) = A_Path
        and then Buffer_Text (S) = "A disk"
        and then not S.File_Info.Dirty
        and then Editor.Buffers.Global_Active_Buffer = A_Id
        and then Natural (Editor.Buffers.Global_Count) = Before_Count,
        "successful copy must use active source A, keep A associated, keep buffers open, and not open target");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A_Dirty_Copy);
      Expect_Message ("Unsaved changes require confirmation.", "dirty A is blocked before target/filesystem work");
      Assert (not Ada.Directories.Exists (A_Dirty_Copy)
        and then To_String (S.File_Info.Path) = A_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "A disk dirty",
        "dirty-blocked copy preserves A text, association, and dirty state");

      Execute_Revert_And_Confirm (S);
      Write_Bytes (A_Copy2, "existing target");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A_Copy2);
      Expect_Message ("Copy target already exists", "existing target is a no-overwrite collision");
      Assert (Read_Bytes (A_Copy2) = "existing target"
        and then To_String (S.File_Info.Path) = A_Path
        and then not S.File_Info.Dirty,
        "collision must not overwrite, Save As, or adopt target");
      Remove_If_Exists (A_Copy2);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A_Copy2);
      Expect_Message ("Buffer file copied", "A copies again after collision target is removed");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A_Renamed);
      Assert (To_String (S.File_Info.Path) = A_Renamed
        and then Ada.Directories.Exists (A_Renamed)
        and then Ada.Directories.Exists (A_Copy)
        and then Ada.Directories.Exists (A_Copy2),
        "rename after copy must rename the original association, not copied targets");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A1_Copy);
      Expect_Message ("Buffer file copied", "renamed A copies from renamed source");
      Assert (Read_Bytes (A1_Copy) = Read_Bytes (A_Renamed)
        and then To_String (S.File_Info.Path) = A_Renamed,
        "post-rename copy source must remain the active buffer association");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, B_Copy);
      Expect_Message ("No file path for active buffer", "untitled B reports no path before dirty/target validation");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, B_Save_As);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, B_Copy);
      Expect_Message ("Buffer file copied", "B becomes eligible only through Save As");
      Assert (Read_Bytes (B_Copy) = "B untitled"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B_Save_As)
        and then not S.File_Info.Dirty,
        "Save As remains the operation that gives B an association for later copy");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, C_Id);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (A_Renamed);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, "   ");
      Expect_Message ("Invalid copy target", "invalid target is deterministic and non-mutating");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, C_Missing_Copy);
      Expect_Message ("Could not copy buffer file", "filesystem failure is deterministic and non-mutating");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, C_Copy);
      Expect_Message ("Buffer file copied", "C copies successfully after failures");
      Assert (Read_Bytes (C_Copy) = "C disk"
        and then To_String (S.File_Info.Path) = C_Path
        and then Buffer_Text (S) = "C disk"
        and then To_String (S.Active_Find_Query) = ""
        and then To_String (S.Active_Replace_Text) = ""
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Renamed
        and then Natural (Editor.Buffers.Global_Count) = Before_Count,
        "copy success/failure preserves Find/Replace, Clipboard, reopen candidate, association, text, and collection");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (C_Path)
        and then Ada.Directories.Exists (C_Copy)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "delete after copy deletes only C's original association");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, C_Save_As);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (C_Save_As)
        and then Read_Bytes (C_Copy) = "C disk"
        and then Natural (Editor.Buffers.Global_Count) = Before_Count,
        "Save As and reload after delete remain independent from copied target");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A_Copy);
      Remove_If_Exists (A_Dirty_Copy);
      Remove_If_Exists (A_Copy2);
      Remove_If_Exists (A_Renamed);
      Remove_If_Exists (A1_Copy);
      Remove_If_Exists (B_Save_As);
      Remove_If_Exists (B_Copy);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C_Copy);
      Remove_If_Exists (C_Save_As);
      Remove_If_Exists (C_Missing_Copy);
      Remove_If_Exists (C_Missing_Parent);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (A_Copy);
         Remove_If_Exists (A_Dirty_Copy);
         Remove_If_Exists (A_Copy2);
         Remove_If_Exists (A_Renamed);
         Remove_If_Exists (A1_Copy);
         Remove_If_Exists (B_Save_As);
         Remove_If_Exists (B_Copy);
         Remove_If_Exists (C_Path);
         Remove_If_Exists (C_Copy);
         Remove_If_Exists (C_Save_As);
         Remove_If_Exists (C_Missing_Copy);
         Remove_If_Exists (C_Missing_Parent);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Integrated_Workflow_Coherence;


   procedure Test_Copy_Read_Only_Feature_And_Availability_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Path           : constant String := Temp_Path ("p455_read_only_source.txt");
      Target         : constant String := Temp_Path ("p455_read_only_copy.txt");
      Reopen_Path    : constant String := Temp_Path ("p455_read_only_reopen.txt");
      Before_Text    : Unbounded_String;
      Before_Path    : Unbounded_String;
      Before_Base    : Natural;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Back    : Ada.Containers.Count_Type;
      Before_Fwd     : Ada.Containers.Count_Type;
      Snap           : Editor.Render_Model.Render_Snapshot;
      Availability   : Editor.Commands.Command_Availability;
      Candidates     : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Copy_Rows      : Natural := 0;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "read only source");
      Write_Bytes (Reopen_Path, "reopen source");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Goto_Line (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "read only");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "side effect");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("read-only clipboard"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (Editor.Buffers.Global_Active_Buffer),
          Has_File_Path => True,
          File_Path => S.File_Info.Path,
          Display_Path => S.File_Info.Path,
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Copy_Buffer_File then
               Copy_Rows := Copy_Rows + 1;
            end if;
         end loop;
      end if;
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Editor.Commands.Is_Available (Availability)
        and then Copy_Rows = 1
        and then not Snap.Is_Dirty
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Path)
        and then Read_Bytes (Path) = "read only source"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (Editor.Clipboard.Get_Text) = "read-only clipboard"
        and then To_String (S.Active_Find_Query) = "read only"
        and then To_String (S.Active_Replace_Text) = "side effect"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "render, availability, palette projection, and workspace snapshot must not copy/probe target, mutate buffers, or repair copy state");
      Assert_Summary_Excludes ("Buffer file copied");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("copy target");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("external modification");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found
        and then To_String (M.Text) = "Buffer file copied"
        and then Editor.Messages.Count (S.Messages) = 1
        and then Read_Bytes (Target) = "read only source"
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then To_String (Editor.Clipboard.Get_Text) = "read-only clipboard"
        and then To_String (S.Active_Find_Query) = "read only"
        and then To_String (S.Active_Replace_Text) = "side effect"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "successful copy must preserve feature state and emit only the copy success message");
      Assert_Summary_Excludes ("Buffer file copied");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("copy target");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes (Target);
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("external modification");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Read_Only_Feature_And_Availability_Boundaries;


   procedure Test_Copy_Undo_Redo_Message_And_Surface_Non_Goals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p455_history_source.txt");
      Target       : constant String := Temp_Path ("p455_history_copy.txt");
      Fail_Parent  : constant String := Temp_Path ("p455_history_missing_parent");
      Fail_Target  : constant String := Ada.Directories.Compose (Fail_Parent, "copy.txt");
      Before_Undo  : Ada.Containers.Count_Type;
      Before_Redo  : Ada.Containers.Count_Type;
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;

      procedure Assert_Absent (Name : String) is
         Id : Editor.Commands.Command_Id;
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found,
           "non-goal command must not be exposed: " & Name);
      end Assert_Absent;
   begin
      Assert_Absent ("file.copy-all-buffers");
      Assert_Absent ("file.copy-project-file");
      Assert_Absent ("file.copy-dirty-buffer");
      Assert_Absent ("file.copy-untitled-buffer");
      Assert_Absent ("file.force-copy-buffer-file");
      Assert_Absent ("file.copy-buffer-file-overwrite");
      Assert_Absent ("file.duplicate-buffer");
      Assert_Absent ("file.duplicate-buffer-file");
      Assert_Absent ("file.open-copied-buffer-file");
      Assert_Absent ("workspace.copy-buffer-file");
      Assert_Absent ("project.copy-files");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Write_Bytes (Path, "history source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " edit");
      for I in 1 .. 5 loop
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      end loop;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Buffer file copied"
        and then Editor.Messages.Count (S.Messages) = 1
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Read_Bytes (Target) = "history source",
        "successful copy must create no undo/redo entry and only the copy success message");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "history source"
        and then To_String (S.File_Info.Path) = To_String (Before_Path),
        "edit.undo must not undo the filesystem copy or alter copy association");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "history source"
        and then To_String (S.File_Info.Path) = To_String (Before_Path),
        "edit.redo must not redo or reinterpret the filesystem copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Fail_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then Editor.Messages.Count (S.Messages) = 1
        and then not Ada.Directories.Exists (Fail_Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path),
        "dirty post-redo state must block failed-target copy before target validation or filesystem work");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Fail_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Could not copy buffer file"
        and then Editor.Messages.Count (S.Messages) = 1
        and then not Ada.Directories.Exists (Fail_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "filesystem copy failure preserves history stacks and emits only copy failure");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Fail_Target);
         Remove_If_Exists (Fail_Parent);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Undo_Redo_Message_And_Surface_Non_Goals;
procedure Test_Copy_Source_Validation_And_Target_Canonicalization
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Active_Path   : constant String := Temp_Path ("p456_active_source.txt");
      Inactive_Path : constant String := Temp_Path ("p456_inactive_source.txt");
      Target        : constant String := Temp_Path ("p456_active_copy.txt");
      Target_2      : constant String := Temp_Path ("p456_active_copy_2.txt");
      Existing      : constant String := Temp_Path ("p456_existing_target.txt");
      Reopen_Path   : constant String := Temp_Path ("p456_reopen_source.txt");
      Active_Id     : Editor.Buffers.Buffer_Id;
      Inactive_Id   : Editor.Buffers.Buffer_Id;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Target_2);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Write_Bytes (Existing, "existing target");
      Write_Bytes (Reopen_Path, "reopen disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer."
        and then not Ada.Directories.Exists (Target),
        "no-active validation must run before source, target, or filesystem work");

      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, "   ");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no-path must be reported before dirty state or invalid target");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then Read_Bytes (Existing) = "existing target"
        and then not Ada.Directories.Exists (Target),
        "dirty guard must precede target collision and all filesystem effects");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Active_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Copy target already exists"
        and then To_String (S.File_Info.Path) = Active_Path,
        "source-equals-target must remain a deterministic no-overwrite collision");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " inactive dirty");
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Read_Bytes (Target) = Read_Bytes (Active_Path)
        and then To_String (S.File_Info.Path) = Active_Path
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Editor.Buffers.Global_Count = 2
        and then Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
        and then To_String (Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "copy source must be execution-time active buffer only and must ignore UI/reopen/inactive fallbacks");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target_2);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Read_Bytes (Target_2) = Read_Bytes (Active_Path)
        and then Editor.Buffers.Global_Count = 2,
        "repeated copy must remain canonical filesystem copy without opening copied targets");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Target_2);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Target_2);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Source_Validation_And_Target_Canonicalization;


   procedure Test_Copy_Read_Only_Persistence_And_No_Removed_Name_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p456_persist_source.txt");
      Target        : constant String := Temp_Path ("p456_persist_copy.txt");
      Fail_Parent   : constant String := Temp_Path ("p456_persist_missing_parent");
      Fail_Target   : constant String := Ada.Directories.Compose (Fail_Parent, "copy.txt");
      Reopen_Path   : constant String := Temp_Path ("p456_persist_reopen.txt");
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
      Copy_Rows     : Natural := 0;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence cleanup: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "persistence disk");
      Write_Bytes (Reopen_Path, "removed copy history target overwrite force duplicate open-copied file-watch project-copy audit cache");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "removed copy history");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "overwrite policy");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard copy history target path"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("removed copy cache");
      Editor.Executor.Selection_Commands.Execute_Clear_Selection_Command (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " edit");
      for I in 1 .. 5 loop
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      end loop;

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Copy_Buffer_File then
               Copy_Rows := Copy_Rows + 1;
            end if;
         end loop;
      end if;
      declare
         Packet : Editor.Render_Packet.Render_Packet;
      begin
         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Render_Packet.Build_Render_Packet (Packet);
      end;
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Editor.Commands.Is_Available (Availability)
        and then Copy_Rows = 1
        and then not Ada.Directories.Exists (Target)
        and then not Ada.Directories.Exists (Fail_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "render/availability/palette/workspace snapshot must not copy, probe, infer, or mutate copy state");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("copy target");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("force-copy");
      Assert_Summary_Excludes ("open-copied");
      Assert_Summary_Excludes ("duplicate-buffer");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-copy");
      Assert_Summary_Excludes ("audit cache");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found and then To_String (M.Text) = "Buffer file copied"
        and then Editor.Messages.Count (S.Messages) = 1
        and then Read_Bytes (Target) = "persistence disk"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard copy history target path"
        and then To_String (S.Active_Find_Query) = "removed copy history"
        and then To_String (S.Active_Replace_Text) = "overwrite policy"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "successful copy must be filesystem-only and preserve editor state exactly");
      Assert_Summary_Excludes ("Buffer file copied");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("copy target");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes (Target);
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("force-copy");
      Assert_Summary_Excludes ("open-copied");
      Assert_Summary_Excludes ("duplicate-buffer");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-copy");
      Assert_Summary_Excludes ("audit cache");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Fail_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not copy buffer file"
        and then Editor.Messages.Count (S.Messages) = 1
        and then not Ada.Directories.Exists (Fail_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "filesystem failure must preserve association, text, baseline, history, and omit target history");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Fail_Target);
         Remove_If_Exists (Fail_Parent);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Copy_Read_Only_Persistence_And_No_Removed_Name_State;



procedure Test_Move_Canonical_State_And_Persistence_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Active_Path   : constant String := Temp_Path ("p460_active_source.txt");
      Inactive_Path : constant String := Temp_Path ("p460_inactive_source.txt");
      Target        : constant String := Temp_Path ("p460_active_moved.txt");
      Fail_Parent   : constant String := Temp_Path ("p460_missing_parent");
      Fail_Target   : constant String := Ada.Directories.Compose (Fail_Parent, "move.txt");
      Reopen_Path   : constant String := Temp_Path ("p460_reopen_candidate.txt");
      Active_Id     : Editor.Buffers.Buffer_Id;
      Inactive_Id   : Editor.Buffers.Buffer_Id;
      Before_Text   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Move_Rows     : Natural := 0;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence cleanup: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Write_Bytes (Reopen_Path, "removed move history moved path target overwrite force open-moved duplicate copy-and-delete file-watch project-move audit cache");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " inactive dirty edit");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "removed move history");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "overwrite policy");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text
        (To_Unbounded_String ("clipboard moved path target history"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("removed open-moved cache");
      Editor.Executor.Selection_Commands.Execute_Clear_Selection_Command (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " active edit");
      for I in 1 .. 12 loop
         Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      end loop;

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Move_Buffer_File then
               Move_Rows := Move_Rows + 1;
            end if;
         end loop;
      end if;
      declare
         Packet : Editor.Render_Packet.Render_Packet;
      begin
         Editor.Input_Bridge.Set_State_For_Test (S);
         Editor.Render_Packet.Build_Render_Packet (Packet);
      end;
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Editor.Commands.Is_Available (Availability)
        and then Move_Rows = 1
        and then Ada.Directories.Exists (Active_Path)
        and then not Ada.Directories.Exists (Target)
        and then not Ada.Directories.Exists (Fail_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = Active_Path
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "availability/palette/render/workspace snapshots must not infer, probe, move, or mutate move state");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move target");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("force-move");
      Assert_Summary_Excludes ("open-moved");
      Assert_Summary_Excludes ("copy-and-delete");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-move");
      Assert_Summary_Excludes ("audit cache");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found and then To_String (M.Text) = "Buffer file moved"
        and then Editor.Messages.Count (S.Messages) = 1
        and then not Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "active disk"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = Target
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Editor.Buffers.Global_Count = 2
        and then To_String (Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path
        and then Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard moved path target history"
        and then To_String (S.Active_Find_Query) = "removed move history"
        and then To_String (S.Active_Replace_Text) = "overwrite policy"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "canonical move must move only active associated disk file, update association after success, and preserve editor state");
      Assert_Summary_Excludes ("Buffer file moved");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("force-move");
      Assert_Summary_Excludes ("open-moved");
      Assert_Summary_Excludes ("copy-and-delete");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-move");
      Assert_Summary_Excludes ("audit cache");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Fail_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found and then To_String (M.Text) = "Could not move buffer file"
        and then Editor.Messages.Count (S.Messages) = 1
        and then Ada.Directories.Exists (Target)
        and then not Ada.Directories.Exists (Fail_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = Target
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "filesystem failure must preserve moved association, text, baseline, dirty state, history, and reopen candidate state");
      Assert_Summary_Excludes ("Could not move buffer file");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move target");
      Assert_Summary_Excludes (Fail_Target);
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-move");
      Assert_Summary_Excludes ("audit cache");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Fail_Target);
      Remove_If_Exists (Fail_Parent);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Fail_Target);
         Remove_If_Exists (Fail_Parent);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Canonical_State_And_Persistence_Cleanup;


   procedure Test_Move_Blocked_Outcomes_Ignore_Removed_Name_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("p460_blocked_source.txt");
      Target        : constant String := Temp_Path ("p460_blocked_target.txt");
      Existing      : constant String := Temp_Path ("p460_blocked_existing.txt");
      Untitled_Tgt  : constant String := Temp_Path ("p460_blocked_untitled_target.txt");
      Dirty_Tgt     : constant String := Temp_Path ("p460_blocked_dirty_target.txt");
      Reopen_Path   : constant String := Temp_Path ("p460_blocked_reopen_candidate.txt");
      Before_Text   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;

      procedure Assert_Message (Text : String; Context : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "blocked cleanup message policy: " & Context);
      end Assert_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "blocked cleanup persistence summary must exclude '" &
           Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Untitled_Tgt);
      Remove_If_Exists (Dirty_Tgt);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Source, "blocked source disk");
      Write_Bytes (Existing, "collision target");
      Write_Bytes (Reopen_Path, "removed move target history overwrite open-moved duplicate copy-and-delete project-move file-watch audit cache");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Editor.Clipboard.Set_Text
        (To_Unbounded_String ("blocked clipboard move history"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("removed moved path");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      Assert_Message ("No active buffer.", "no active buffer checked first");
      Assert (not Ada.Directories.Exists (Target)
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path
        and then To_String (Editor.Clipboard.Get_Text) =
          "blocked clipboard move history",
        "no-active move must ignore target path, removed-name reopen state, and clipboard state");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Untitled_Tgt);
      Assert_Message ("No file path for active buffer",
        "no-path is retained before dirty and target validation");
      Assert (not Ada.Directories.Exists (Untitled_Tgt)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "untitled dirty text dirty",
        "dirty untitled move must report no-path and preserve text without creating target state");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("removed moved path");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "removed move history");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "target history overwrite");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Dirty_Tgt);
      Assert_Message ("Unsaved changes require confirmation.",
        "dirty associated buffer checked before target validation");
      Assert (Ada.Directories.Exists (Source)
        and then not Ada.Directories.Exists (Dirty_Tgt)
        and then To_String (S.File_Info.Path) = Source
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (S.Active_Find_Query) = "removed move history"
        and then To_String (S.Active_Replace_Text) = "target history overwrite"
        and then To_String (Editor.Clipboard.Get_Text) =
          "blocked clipboard move history"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "dirty blocked move must preserve association, text, baseline, history, find/replace, clipboard, and reopen candidate");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, "   ");
      Assert_Message ("Invalid move target",
        "blank explicit target rejected without filesystem move");
      Assert (Ada.Directories.Exists (Source)
        and then To_String (S.File_Info.Path) = Source
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "invalid target must not mutate canonical clean source state");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Existing);
      Assert_Message ("Move target already exists",
        "target collision blocks overwrite before filesystem move");
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Directories.Exists (Source)
        and then Ada.Directories.Exists (Existing)
        and then Read_Bytes (Existing) = "collision target"
        and then To_String (S.File_Info.Path) = Source
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (S.Active_Find_Query) = "removed move history"
        and then To_String (S.Active_Replace_Text) = "target history overwrite"
        and then To_String (Editor.Clipboard.Get_Text) =
          "blocked clipboard move history"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "collision must preserve source, target, editor state, and removed-name-like transient state without overwrite");
      Assert_Summary_Excludes ("Move target already exists");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("target history");
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("open-moved");
      Assert_Summary_Excludes ("duplicate");
      Assert_Summary_Excludes ("copy-and-delete");
      Assert_Summary_Excludes ("project-move");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("audit cache");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Untitled_Tgt);
      Remove_If_Exists (Dirty_Tgt);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Untitled_Tgt);
         Remove_If_Exists (Dirty_Tgt);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Blocked_Outcomes_Ignore_Removed_Name_State;



   procedure Test_Cross_Command_Source_Validation_And_Association_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Active_Path    : constant String := Temp_Path ("p461_source_active.txt");
      Inactive_Path  : constant String := Temp_Path ("p461_source_inactive.txt");
      Rename_Target  : constant String := Temp_Path ("p461_source_renamed.txt");
      Copy_Target    : constant String := Temp_Path ("p461_source_copied.txt");
      Move_Target    : constant String := Temp_Path ("p461_source_moved.txt");
      Existing       : constant String := Temp_Path ("p461_source_existing.txt");
      Deleted_Save   : constant String := Temp_Path ("p461_source_after_delete_save_as.txt");
      Active_Id      : Editor.Buffers.Buffer_Id;
      Inactive_Id    : Editor.Buffers.Buffer_Id;
      Count_0        : Natural;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;

      procedure Assert_Message (Text : String; Context : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "cross-command message policy: " & Context);
      end Assert_Message;

      procedure Assert_Active_Buffer_File_Operations_Coherent
        (Expected_Path : String;
         Expected_Text : String;
         Context       : String) is
      begin
         Assert (Editor.Buffers.Global_Active_Buffer = Active_Id
           and then Editor.Buffers.Global_Count = Count_0
           and then S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = Expected_Path
           and then Buffer_Text (S) = Expected_Text
           and then not S.File_Info.Dirty
           and then Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
           and then To_String (Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path,
           "coherent active-buffer file operation state: " & Context);
      end Assert_Active_Buffer_File_Operations_Coherent;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Deleted_Save);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Write_Bytes (Existing, "existing target");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty inactive");
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Count_0 := Editor.Buffers.Global_Count;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Target);
      Assert_Message ("Buffer file renamed", "rename active source");
      Assert (not Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Rename_Target)
        and then Read_Bytes (Rename_Target) = "active disk",
        "rename must operate on active association only");
      Assert_Active_Buffer_File_Operations_Coherent
        (Rename_Target, "active disk", "after rename");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Target);
      Assert_Message ("Buffer file copied", "copy preserves renamed association");
      Assert (Ada.Directories.Exists (Copy_Target)
        and then Read_Bytes (Copy_Target) = Read_Bytes (Rename_Target),
        "copy after rename copies current active association");
      Assert_Active_Buffer_File_Operations_Coherent
        (Rename_Target, "active disk", "after copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Target);
      Assert_Message ("Buffer file moved", "move updates association");
      Assert (not Ada.Directories.Exists (Rename_Target)
        and then Ada.Directories.Exists (Move_Target)
        and then Read_Bytes (Move_Target) = "active disk"
        and then Ada.Directories.Exists (Copy_Target),
        "move after copy moves current association and does not adopt or open copy target");
      Assert_Active_Buffer_File_Operations_Coherent
        (Move_Target, "active disk", "after move");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Existing);
      Assert_Message ("Rename target already exists", "rename collision shared no-overwrite policy");
      Assert_Active_Buffer_File_Operations_Coherent
        (Move_Target, "active disk", "after rename collision");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      Assert_Message ("Copy target already exists", "copy collision shared no-overwrite policy");
      Assert_Active_Buffer_File_Operations_Coherent
        (Move_Target, "active disk", "after copy collision");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Existing);
      Assert_Message ("Move target already exists", "move collision shared no-overwrite policy");
      Assert_Active_Buffer_File_Operations_Coherent
        (Move_Target, "active disk", "after move collision");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Buffer file deleted", "delete clears only after filesystem success");
      Assert (not Ada.Directories.Exists (Move_Target)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "active disk"
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Editor.Buffers.Global_Count = Count_0
        and then Ada.Directories.Exists (Copy_Target)
        and then Ada.Directories.Exists (Inactive_Path),
        "delete clears active association and applies no-path dirty policy without touching copy target or inactive buffer");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Temp_Path ("p461_after_delete_rename.txt"));
      Assert_Message ("No file path for active buffer", "rename after delete sees no association");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Temp_Path ("p461_after_delete_copy.txt"));
      Assert_Message ("No file path for active buffer", "copy after delete sees no association");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Temp_Path ("p461_after_delete_move.txt"));
      Assert_Message ("No file path for active buffer", "move after delete sees no association");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Deleted_Save);
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Deleted_Save
        and then not S.File_Info.Dirty
        and then Ada.Directories.Exists (Deleted_Save),
        "Save As after delete is the explicit operation that creates a new association");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Deleted_Save);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Rename_Target);
         Remove_If_Exists (Copy_Target);
         Remove_If_Exists (Move_Target);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Deleted_Save);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Cross_Command_Source_Validation_And_Association_Coherence;


   procedure Test_Cross_Command_Failure_Dirty_And_Feature_State_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("p461_failure_source.txt");
      Missing_Move  : constant String := Temp_Path ("p461_failure_move.txt");
      Missing_Copy  : constant String := Temp_Path ("p461_failure_copy.txt");
      Existing      : constant String := Temp_Path ("p461_failure_existing.txt");
      Rename_Target : constant String := Temp_Path ("p461_failure_renamed.txt");
      Move_Target   : constant String := Temp_Path ("p461_failure_moved.txt");
      Delete_Save   : constant String := Temp_Path ("p461_failure_save_as.txt");
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;

      procedure Assert_Message (Text : String; Context : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "failure message policy: " & Context);
      end Assert_Message;

      procedure Snapshot_State is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Path := S.File_Info.Path;
         Before_Base := S.File_Info.Saved_Generation;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
      end Snapshot_State;

      procedure Assert_Preserved (Context : String) is
      begin
         Assert (S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Before_Path)
           and then Buffer_Text (S) = To_String (Before_Text)
           and then S.File_Info.Saved_Generation = Before_Base
           and then Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo
           and then To_String (S.Active_Find_Query) = ""
           and then To_String (S.Active_Replace_Text) = "replacement"
           and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
           and then S.Has_Reopen_Candidate
           and then To_String (S.Reopen_Candidate_Path) = Source,
           "failed/blocked file operation preserves editor state: " & Context);
      end Assert_Preserved;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Missing_Move);
      Remove_If_Exists (Missing_Copy);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Delete_Save);
      Write_Bytes (Source, "failure disk");
      Write_Bytes (Existing, "existing target");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "replacement");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Source);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen candidate");

      Snapshot_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "   ");
      Assert_Message ("Invalid rename target", "rename invalid target");
      Assert_Preserved ("invalid rename target");

      Snapshot_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      Assert_Message ("Copy target already exists", "copy collision");
      Assert_Preserved ("copy collision");
      Assert (Read_Bytes (Existing) = "existing target",
        "copy collision must not overwrite target");

      Remove_If_Exists (Source);
      Snapshot_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Missing_Move);
      Assert_Message ("Could not move buffer file", "move source filesystem failure");
      Assert_Preserved ("move filesystem failure");
      Assert (not Ada.Directories.Exists (Missing_Move),
        "failed move must not adopt or create target path");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Missing_Copy);
      Assert_Message ("Could not copy buffer file", "copy source filesystem failure");
      Assert_Preserved ("copy filesystem failure");
      Assert (not Ada.Directories.Exists (Missing_Copy),
        "failed copy must not create target path");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Could not delete buffer file", "delete source filesystem failure");
      Assert_Preserved ("delete filesystem failure");

      Write_Bytes (Source, "failure disk");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Snapshot_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Target);
      Assert_Message ("Dirty buffer preserved.", "dirty rename blocked before target work");
      Assert_Preserved ("dirty rename blocked");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Existing);
      Assert_Message ("Unsaved changes require confirmation.", "dirty copy blocked before collision");
      Assert_Preserved ("dirty copy blocked");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Target);
      Assert_Message ("Unsaved changes require confirmation.", "dirty move blocked");
      Assert_Preserved ("dirty move blocked");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Dirty buffer preserved.", "dirty delete blocked");
      Assert_Preserved ("dirty delete blocked");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      if S.File_Conflict_Prompt_Active then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      end if;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Target);
      Assert_Message ("Buffer file renamed", "save makes rename eligible");
      Assert (To_String (S.File_Info.Path) = Rename_Target
        and then not S.File_Info.Dirty
        and then Ada.Directories.Exists (Rename_Target),
        "successful save restores eligibility for active-buffer file operations");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Target);
      Assert_Message ("Buffer file moved", "move after saved rename uses new association");
      Assert (To_String (S.File_Info.Path) = Move_Target
        and then Ada.Directories.Exists (Move_Target)
        and then not Ada.Directories.Exists (Rename_Target),
        "move after rename observes current association");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Buffer file deleted", "delete after move uses moved association");
      Assert (not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then not Ada.Directories.Exists (Move_Target),
        "delete after move clears association only after deleting moved file");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Delete_Save);
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Delete_Save
        and then not S.File_Info.Dirty,
        "Save As after delete creates clean associated buffer for later operations");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Source);
      Remove_If_Exists (Missing_Move);
      Remove_If_Exists (Missing_Copy);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Delete_Save);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Source);
         Remove_If_Exists (Missing_Move);
         Remove_If_Exists (Missing_Copy);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Rename_Target);
         Remove_If_Exists (Move_Target);
         Remove_If_Exists (Delete_Save);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Cross_Command_Failure_Dirty_And_Feature_State_Preservation;


   procedure Test_Read_Only_Lifecycle_Persistence_And_Removed_Name_State_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("p461_readonly_source.txt");
      Renamed       : constant String := Temp_Path ("p461_readonly_renamed.txt");
      Copied        : constant String := Temp_Path ("p461_readonly_copied.txt");
      Moved         : constant String := Temp_Path ("p461_readonly_moved.txt");
      Reopened      : constant String := Temp_Path ("p461_readonly_reopened.txt");
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Base   : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Rename_Rows   : Natural := 0;
      Delete_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;
      Found         : Boolean := False;
      Msg           : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;

      procedure Snapshot_State is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Path := S.File_Info.Path;
         Before_Base := S.File_Info.Saved_Generation;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
      end Snapshot_State;

      procedure Assert_Read_Only_Preserved (Context : String) is
      begin
         Assert (S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Before_Path)
           and then Buffer_Text (S) = To_String (Before_Text)
           and then S.File_Info.Saved_Generation = Before_Base
           and then Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo
           and then Ada.Directories.Exists (To_String (Before_Path)),
           "read-only path must not mutate file-operation state: " & Context);
      end Assert_Read_Only_Preserved;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Reopened);
      Write_Bytes (Source, "readonly disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Insert_Text_At (S, Buffer_Text (S)'Length, " edited");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Snapshot_State;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
        "rename availability observes clean associated active buffer");
      Assert_Read_Only_Preserved ("rename availability");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
        "delete availability observes clean associated active buffer");
      Assert_Read_Only_Preserved ("delete availability");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
        "copy availability observes clean associated active buffer");
      Assert_Read_Only_Preserved ("copy availability");
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability),
        "move availability observes clean associated active buffer");
      Assert_Read_Only_Preserved ("move availability");

      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            case Candidates (I).Id is
               when Editor.Commands.Command_Rename_Buffer_File =>
                  Rename_Rows := Rename_Rows + 1;
               when Editor.Commands.Command_Delete_Buffer_File =>
                  Delete_Rows := Delete_Rows + 1;
               when Editor.Commands.Command_Copy_Buffer_File =>
                  Copy_Rows := Copy_Rows + 1;
               when Editor.Commands.Command_Move_Buffer_File =>
                  Move_Rows := Move_Rows + 1;
               when others =>
                  null;
            end case;
         end loop;
      end if;
      Assert (Rename_Rows = 1 and then Delete_Rows = 1
        and then Copy_Rows = 1 and then Move_Rows = 1,
        "Command Palette projects exactly one canonical row for each active-buffer associated-file operation");
      Assert_Read_Only_Preserved ("command palette projection");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert_Read_Only_Preserved ("workspace snapshot");
      Assert_Summary_Excludes ("last rename");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("rename history");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("copy history");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("target history");
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("external modification");
      Assert_Summary_Excludes ("audit cache");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (Msg.Text) = "Buffer file renamed",
        "rename succeeds before lifecycle close/reopen check");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copied);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Moved,
        "only close creates reopen candidate and it references current moved association");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Moved
        and then Buffer_Text (S) = "readonly disk edited",
        "reopen after rename/copy/move uses current associated path and not copied target");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Reopened);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (not S.File_Info.Has_Path and then S.File_Info.Dirty,
        "delete after reopened save-as applies retained no-associated-file state");
      Assert_Summary_Excludes ("Buffer file deleted");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("renamed path");
      Assert_Summary_Excludes ("operation history");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("trash");

      Remove_If_Exists (Source);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Reopened);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Renamed);
         Remove_If_Exists (Copied);
         Remove_If_Exists (Moved);
         Remove_If_Exists (Reopened);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Read_Only_Lifecycle_Persistence_And_Removed_Name_State_Exclusion;

procedure Test_Final_Association_Lifecycle_And_Failure_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Active_Path    : constant String := Temp_Path ("p463_assoc_active.txt");
      Inactive_Path  : constant String := Temp_Path ("p463_assoc_inactive.txt");
      Renamed        : constant String := Temp_Path ("p463_assoc_renamed.txt");
      Copied         : constant String := Temp_Path ("p463_assoc_copied.txt");
      Moved          : constant String := Temp_Path ("p463_assoc_moved.txt");
      Save_As_Path   : constant String := Temp_Path ("p463_assoc_after_delete_save_as.txt");
      Missing_Target : constant String := Temp_Path ("p463_assoc_missing_move.txt");
      Reopened       : constant String := Temp_Path ("p463_assoc_reopened.txt");
      Active_Id      : Editor.Buffers.Buffer_Id;
      Inactive_Id    : Editor.Buffers.Buffer_Id;
      Count_0        : Natural;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
      Before_Text    : Unbounded_String;
      Before_Path    : Unbounded_String;
      Before_Base    : Natural;
      Before_Dirty   : Boolean;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;

      procedure Assert_Message (Text : String; Context : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "final family one-primary-message failed for " & Context);
      end Assert_Message;

      procedure Snapshot_State is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Path := S.File_Info.Path;
         Before_Base := S.File_Info.Saved_Generation;
         Before_Dirty := S.File_Info.Dirty;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
      end Snapshot_State;

      procedure Assert_Failed_State_Preserved (Context : String) is
      begin
         Assert (S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = To_String (Before_Path)
           and then Buffer_Text (S) = To_String (Before_Text)
           and then S.File_Info.Saved_Generation = Before_Base
           and then S.File_Info.Dirty = Before_Dirty
           and then Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo
           and then Editor.Buffers.Global_Active_Buffer = Active_Id
           and then Editor.Buffers.Global_Count = Count_0
           and then Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
           and then To_String (Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path,
           "failed filesystem operation mutated frozen state: " & Context);
      end Assert_Failed_State_Preserved;

      procedure Assert_Clean_Active_State
        (Expected_Path : String;
         Context       : String) is
      begin
         Assert (S.File_Info.Has_Path
           and then To_String (S.File_Info.Path) = Expected_Path
           and then Buffer_Text (S) = "active disk"
           and then not S.File_Info.Dirty
           and then Editor.Buffers.Global_Active_Buffer = Active_Id
           and then Editor.Buffers.Global_Count = Count_0
           and then Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
           and then To_String (Editor.Buffers.Buffer
             (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path,
           "active association/text/buffer collection freeze failed " & Context);
      end Assert_Clean_Active_State;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "lifecycle/persistence freeze leaked '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Save_As_Path);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopened);
      Write_Bytes (Active_Path, "active disk");
      Write_Bytes (Inactive_Path, "inactive disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Inactive_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty inactive");
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Active_Id);
      Count_0 := Editor.Buffers.Global_Count;

      Remove_If_Exists (Active_Path);
      Snapshot_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Assert_Message ("Could not rename buffer file", "rename filesystem failure");
      Assert_Failed_State_Preserved ("rename source missing");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copied);
      Assert_Message ("Could not copy buffer file", "copy filesystem failure");
      Assert_Failed_State_Preserved ("copy source missing");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Missing_Target);
      Assert_Message ("Could not move buffer file", "move filesystem failure");
      Assert_Failed_State_Preserved ("move source missing");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Could not delete buffer file", "delete filesystem failure");
      Assert_Failed_State_Preserved ("delete source missing");
      Assert (not Ada.Directories.Exists (Renamed)
        and then not Ada.Directories.Exists (Copied)
        and then not Ada.Directories.Exists (Missing_Target),
        "filesystem failures must not adopt, open, or create targets");

      Write_Bytes (Active_Path, "active disk");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Assert_Message ("Buffer file renamed", "rename success");
      Assert (not Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Renamed)
        and then Read_Bytes (Renamed) = "active disk",
        "rename performs only filesystem rename and updates after success");
      Assert_Clean_Active_State (Renamed, "after rename");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copied);
      Assert_Message ("Buffer file copied", "copy success");
      Assert (Ada.Directories.Exists (Copied)
        and then Ada.Directories.Exists (Renamed)
        and then Read_Bytes (Copied) = Read_Bytes (Renamed),
        "copy performs only filesystem copy and never adopts target");
      Assert_Clean_Active_State (Renamed, "after copy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      Assert_Message ("Buffer file moved", "move success");
      Assert (not Ada.Directories.Exists (Renamed)
        and then Ada.Directories.Exists (Moved)
        and then Ada.Directories.Exists (Copied),
        "move performs only filesystem move and does not touch copied target");
      Assert_Clean_Active_State (Moved, "after move");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert_Clean_Active_State (Moved, "after save/reload uses moved association");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty edit");
      Execute_Revert_And_Confirm (S);
      Assert_Clean_Active_State (Moved, "after revert uses moved association");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Moved,
        "close remains the only lifecycle command creating reopen candidates");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Moved
        and then Buffer_Text (S) = "active disk",
        "reopen uses canonical file read and current moved association");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Reopened);
      Assert (To_String (S.File_Info.Path) = Reopened
        and then Ada.Directories.Exists (Reopened),
        "Save As is the explicit path-changing text-write command");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Buffer file deleted", "delete success");
      Assert (not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "active disk"
        and then not Ada.Directories.Exists (Reopened)
        and then Ada.Directories.Exists (Copied),
        "delete clears association only after filesystem delete and preserves text/copy target");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Assert_Message ("No file path for active buffer", "rename after delete no-path");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copied);
      Assert_Message ("No file path for active buffer", "copy after delete no-path before collision");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      Assert_Message ("No file path for active buffer", "move after delete no-path before collision");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Save_As_Path
        and then not S.File_Info.Dirty,
        "after delete only Save As creates the new association used by later operations");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Message ("Buffer file deleted", "delete after save-as target");
      Assert (not S.File_Info.Has_Path
        and then not Ada.Directories.Exists (Save_As_Path),
        "delete after Save As uses the Save As association");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert_Summary_Excludes ("last rename");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("last copy");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("renamed path");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes ("copied path");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("operation history");
      Assert_Summary_Excludes ("target history");
      Assert_Summary_Excludes ("overwrite");
      Assert_Summary_Excludes ("force");
      Assert_Summary_Excludes ("open-target");
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("external modification");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Save_As_Path);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Reopened);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Renamed);
         Remove_If_Exists (Copied);
         Remove_If_Exists (Moved);
         Remove_If_Exists (Save_As_Path);
         Remove_If_Exists (Missing_Target);
         Remove_If_Exists (Reopened);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Final_Association_Lifecycle_And_Failure_Freeze;





   procedure Test_Copy_Read_Only_Persistence_And_No_Removed_Name_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Copy_Read_Only_Feature_And_Availability_Boundaries (T);
   end Test_Copy_Read_Only_Persistence_And_No_Removed_Name_Routes;

   procedure Test_Copy_Canonical_Surface_And_Removed_Name_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Copy_Source_Validation_And_Target_Canonicalization (T);
   end Test_Copy_Canonical_Surface_And_Removed_Name_Cleanup;

   procedure Test_Move_Canonical_Surface_And_Removed_Name_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Move_Canonical_State_And_Persistence_Cleanup (T);
   end Test_Move_Canonical_Surface_And_Removed_Name_Cleanup;

   procedure Test_Canonical_Family_Surface_And_Shared_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Final_Association_Lifecycle_And_Failure_Freeze (T);
   end Test_Canonical_Family_Surface_And_Shared_Boundaries;

   procedure Test_Final_Family_Surface_Validation_And_Readonly_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Final_Association_Lifecycle_And_Failure_Freeze (T);
   end Test_Final_Family_Surface_Validation_And_Readonly_Freeze;





   overriding function Name (T : Copy_Move_Association_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Copy_Move_Association.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Copy_Move_Association_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Command_Surface_And_Validation'Access, "Copy Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Success_Preserves_Buffer_State'Access, "Copy Success Preserves Buffer State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Failure_And_Active_Isolation_Are_Atomic'Access, "Copy Failure And Active Isolation Are Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Source_And_Target_Failures_Preserve_State'Access, "Copy Source And Target Failures Preserve State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_File_Lifecycle_Interactions_Stay_On_Original_Path'Access, "Copy File Lifecycle Interactions Stay On Original Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Validation_Order_And_Active_Source_Reliability'Access, "Copy Validation Order And Active Source Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Preserves_Transient_State_On_Success_And_Failure'Access, "Copy Preserves Transient State On Success And Failure");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_File_Lifecycle_And_Persistence_Reliability'Access, "Copy File Lifecycle And Persistence Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Integrated_Workflow_Coherence'Access, "Copy Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Feature_And_Availability_Boundaries'Access, "Copy Read Only Feature And Availability Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Undo_Redo_Message_And_Surface_Non_Goals'Access, "Copy Undo Redo Message And Surface Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Source_Validation_And_Target_Canonicalization'Access, "Copy Source Validation And Target Canonicalization");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Persistence_And_No_Removed_Name_State'Access, "Copy Read Only Persistence And No Removed Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Canonical_State_And_Persistence_Cleanup'Access, "Move Canonical State And Persistence Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Blocked_Outcomes_Ignore_Removed_Name_State'Access, "Move Blocked Outcomes Ignore Removed Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cross_Command_Source_Validation_And_Association_Coherence'Access, "Cross Command Source Validation And Association Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cross_Command_Failure_Dirty_And_Feature_State_Preservation'Access, "Cross Command Failure Dirty And Feature State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Read_Only_Lifecycle_Persistence_And_Removed_Name_State_Exclusion'Access, "Read Only Lifecycle Persistence And Removed Name State Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Final_Association_Lifecycle_And_Failure_Freeze'Access, "Final Association Lifecycle And Failure Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Persistence_And_No_Removed_Name_Routes'Access, "Copy Read Only Persistence And No Removed Name Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Canonical_Surface_And_Removed_Name_Cleanup'Access, "Copy Canonical Surface And Removed Name Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Canonical_Surface_And_Removed_Name_Cleanup'Access, "Move Canonical Surface And Removed Name Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Family_Surface_And_Shared_Boundaries'Access, "Canonical Family Surface And Shared Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Final_Family_Surface_Validation_And_Readonly_Freeze'Access, "Final Family Surface Validation And Readonly Freeze");
   end Register_Tests;

end Editor.Files.Copy_Move_Association_Tests;
