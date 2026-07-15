with Editor.Test_Temp;
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

package body Editor.Files.Save_Reload_Tests is

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


   procedure Test_Open_Save_And_Reload_Update_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("baseline.txt");
      Open_Generation : Natural;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "one");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Assert (S.File_Info.Has_Path and then S.File_Info.Baseline_Valid,
        "open should establish a file-backed baseline");
      Assert (not S.File_Info.Dirty,
        "opened file-backed buffer should be clean");
      Open_Generation := S.File_Info.Saved_Generation;
      Assert (Open_Generation = Editor.State.Current_Buffer_Revision (S),
        "open baseline should match the loaded buffer generation");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid,
        "save should preserve the clean file-backed baseline");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "save should record the saved buffer generation");

      Write_Bytes (Path, "two" & ASCII.LF & "three");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "two" & ASCII.LF & "three",
        "clean reload should replace content from disk");
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid,
        "clean reload should leave the buffer clean with a valid baseline");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "reload should record the replacement generation");
      Remove_If_Exists (Path);
   end Test_Open_Save_And_Reload_Update_Baseline;

   procedure Test_Failed_Save_Does_Not_Update_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("failed_save.txt");
      Dir_Path : constant String := Temp_Path ("failed_save_dir");
      Saved_Generation : Natural;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Path, "original");
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Saved_Generation := S.File_Info.Saved_Generation;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("failed_save_dir");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (S.File_Info.Dirty,
        "failed save should preserve dirty state");
      Assert (S.File_Info.Baseline_Valid,
        "failed save should preserve the previous baseline marker");
      Assert (S.File_Info.Saved_Generation = Saved_Generation,
        "failed save must not record a new saved generation");
      Assert (Buffer_Text (S) = "original!",
        "failed save should preserve dirty content");
      Remove_If_Exists (Dir_Path);
      Remove_If_Exists (Path);
   end Test_Failed_Save_Does_Not_Update_Baseline;

   procedure Test_Dirty_Reload_Is_Blocked_And_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("dirty_reload.txt");
      Before_Generation : Natural;
      Before_Caret : Editor.Cursors.Caret_State;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk-one");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 3, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Generation := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Write_Bytes (Path, "disk-two");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = "disk-one!",
        "dirty reload should not discard in-memory edits");
      Assert (S.File_Info.Dirty,
        "dirty reload should preserve the dirty marker");
      Assert (S.File_Info.Saved_Generation = Before_Generation,
        "blocked dirty reload should not update baseline generation");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "blocked dirty reload should preserve cursor and selection");
      Remove_If_Exists (Path);
   end Test_Dirty_Reload_Is_Blocked_And_Preserves_State;

   procedure Test_Missing_And_Read_Failure_Reload_Preserve_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("missing_reload.txt");
      Dir_Path : constant String := Temp_Path ("reload_dir");
      Before_Generation : Natural;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Path, "safe");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Before_Generation := S.File_Info.Saved_Generation;

      Remove_If_Exists (Path);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "safe"
        and then not S.File_Info.Dirty
        and then S.File_Info.Has_Path,
        "missing-file reload should preserve clean file-backed state");
      Assert (S.File_Info.Saved_Generation = Before_Generation,
        "missing-file reload should not update baseline generation");

      Ada.Directories.Create_Directory (Dir_Path);
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("reload_dir");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "safe"
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Generation,
        "read-failure reload should preserve content, dirty state, and baseline");
      Remove_If_Exists (Dir_Path);
   end Test_Missing_And_Read_Failure_Reload_Preserve_Buffer;

   procedure Test_Open_Already_Open_Changed_File_Does_Not_Reread
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("already_open_changed.txt");
      First_Id : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "loaded");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Before_Count := Editor.Buffers.Global_Count;
      Write_Bytes (Path, "changed on disk");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Active_Buffer = First_Id,
        "opening an already-open changed file should focus the existing buffer only");
      Assert (Buffer_Text (S) = "loaded",
        "opening an already-open file must not reread changed disk content");
      Remove_If_Exists (Path);
   end Test_Open_Already_Open_Changed_File_Does_Not_Reread;

   procedure Test_Save_Writes_Buffer_And_Cleans_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("save.txt");
      Status : Editor.Files.File_Status;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "hello" & ASCII.LF & "world");
      S.File_Info.Dirty := True;

      Status := Editor.Files.Save_File (Path, S);

      Assert (Status = Editor.Files.Ok, "Save_File should return Ok");
      Assert (Read_Bytes (Path) = "hello" & ASCII.LF & "world",
        "Save_File should write buffer bytes with LF line separators");
      Assert (not S.File_Info.Dirty, "Save_File should mark state clean");
      Assert (To_String (S.File_Info.Path) = Path, "Save_File should store path");
      Remove_If_Exists (Path);
   end Test_Save_Writes_Buffer_And_Cleans_State;

   procedure Test_Format_On_Save_Trims_Before_File_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("format_on_save_trims.txt");
   begin
      Editor.Settings.Set_Format_On_Save (False);
      Remove_If_Exists (Path);

      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "one  " & ASCII.LF & "two" & ASCII.HT);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("format_on_save_trims.txt");
      Editor.State.Set_Dirty (S, True);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Toggle_Format_On_Save);
      Assert (Editor.Settings.Format_On_Save,
              "format-on-save toggle should enable the persisted setting");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Read_Bytes (Path) = "one" & ASCII.LF & "two",
              "format-on-save should trim trailing spaces before writing");
      Assert (not Editor.State.Is_Dirty (S),
              "format-on-save save should leave the buffer clean after write");

      Editor.Settings.Set_Format_On_Save (False);
      Remove_If_Exists (Path);
   end Test_Format_On_Save_Trims_Before_File_Save;

   procedure Test_Edit_After_Save_Marks_Dirty
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("dirty.txt");
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "x");
      Assert (Editor.Files.Save_File (Path, S) = Editor.Files.Ok,
        "Initial save should succeed");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'y'));
      Assert (S.File_Info.Dirty, "Edit after save should mark state dirty");
      Remove_If_Exists (Path);
   end Test_Edit_After_Save_Marks_Dirty;

   procedure Test_Save_Without_Path_Returns_Invalid_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Assert (Editor.Files.Save_File ("", S) = Editor.Files.Invalid_Path,
        "Empty save path should be invalid");
   end Test_Save_Without_Path_Returns_Invalid_Path;

   procedure Test_Save_File_Result_Writes_Contents
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("save_result.txt");
      Result : Editor.Files.File_Save_Result;
   begin
      Remove_If_Exists (Path);

      Result := Editor.Files.Save_File (Path, "alpha" & ASCII.LF & "beta");

      Assert (Editor.Files.Is_Success (Result),
        "Save_File(Path, Contents) should return a successful save result");
      Assert (Result.Status = Editor.Files.File_Save_Ok,
        "Successful save result should carry File_Save_Ok");
      Assert (Read_Bytes (Path) = "alpha" & ASCII.LF & "beta",
        "Save_File(Path, Contents) should write the supplied contents exactly");
      Assert (To_String (Result.Display_Name) = "save_result.txt",
        "Save_File(Path, Contents) should derive a basename display name");
      Remove_If_Exists (Path);
   end Test_Save_File_Result_Writes_Contents;

   procedure Test_Save_File_Result_Rejects_Invalid_And_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Dir_Path : constant String := Temp_Path ("save_result_dir");
      Result   : Editor.Files.File_Save_Result;
   begin
      Remove_If_Exists (Dir_Path);

      Result := Editor.Files.Save_File ("", "ignored");
      Assert (Result.Status = Editor.Files.File_Save_Invalid_Path,
        "Pure Save_File should reject an empty path");
      Assert (not Editor.Files.Is_Success (Result),
        "Invalid-path save result should not be successful");

      Ada.Directories.Create_Directory (Dir_Path);
      Result := Editor.Files.Save_File (Dir_Path, "ignored");
      Assert (Result.Status = Editor.Files.File_Save_Is_Directory,
        "Pure Save_File should reject directory paths");
      Assert (Editor.Files.Status_Message (Result) = "path is a directory",
        "Directory save failure should have deterministic message text");
      Remove_If_Exists (Dir_Path);
   end Test_Save_File_Result_Rejects_Invalid_And_Directory;

   procedure Test_Save_File_Result_Reports_Missing_Parent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Parent : constant String := Temp_Path ("missing_parent");
      Path   : constant String := Ada.Directories.Compose (Parent, "new.adb");
      Result : Editor.Files.File_Save_Result;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Parent);

      Result := Editor.Files.Save_File (Path, "contents");

      Assert (Result.Status = Editor.Files.File_Save_Parent_Unavailable,
        "save must report a missing parent separately");
      Assert (Editor.Files.Status_Message (Result) = "parent directory is unavailable",
        "missing-parent save has deterministic status text");
      Assert (not Ada.Directories.Exists (Parent),
        "save must not create parent directories silently");
   end Test_Save_File_Result_Reports_Missing_Parent;

   procedure Test_Reload_Missing_Target_Surfaces_State_And_Preserves_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("reload_missing.txt");
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Remove_If_Exists (Path);

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = "disk baseline",
        "failed reload must preserve existing buffer text");
      Assert (not S.File_Info.Dirty,
        "failed clean reload must not fabricate dirty state");
      Assert (S.File_Info.Last_Reload_Failed
        and then S.File_Info.Missing_Target_Surfaced,
        "missing reload must surface transient missing-target state");
      Summary := Editor.Buffers.Global_Summary_For
        (Editor.Buffers.Global_Active_Buffer);
      Assert (Summary.Last_Reload_Failed
        and then Summary.Missing_Target_Surfaced,
        "missing reload state must propagate to buffer summaries");
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Missing_Target_Surfaces_State_And_Preserves_Text;

   procedure Test_Revert_Missing_Target_Preserves_Dirty_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("revert_missing.txt");
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Remove_If_Exists (Path);

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (Buffer_Text (S) = "disk baseline dirty",
        "failed revert must preserve dirty buffer text");
      Assert (S.File_Info.Dirty,
        "failed revert must preserve dirty state");
      Assert (S.File_Info.Last_Revert_Failed
        and then S.File_Info.Missing_Target_Surfaced,
        "failed revert must surface missing backing-file state");
      Summary := Editor.Buffers.Global_Summary_For
        (Editor.Buffers.Global_Active_Buffer);
      Assert (Summary.Last_Revert_Failed
        and then Summary.Missing_Target_Surfaced,
        "failed revert state must propagate to buffer summaries");
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Missing_Target_Preserves_Dirty_Text;


   procedure Test_Reload_Pending_Becomes_Stale_After_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("reload_pending_stale.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "reload of dirty buffer should create a transient confirmation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Write_Bytes (Path, "external replacement");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (Buffer_Text (S) = "disk baseline dirty",
        "stale reload confirmation must not reload after save resolved dirty text");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "stale reload confirmation must be cleared after retry rejection");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Reload confirmation is no longer valid",
        "stale reload confirmation should report that the reload confirmation is no longer valid");
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Pending_Becomes_Stale_After_Save;

   procedure Test_Revert_Pending_Becomes_Stale_After_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("revert_pending_stale.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "revert of dirty buffer should create a transient confirmation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Write_Bytes (Path, "external replacement");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (Buffer_Text (S) = "disk baseline dirty",
        "stale revert confirmation must not discard text after save resolved dirty text");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "stale revert confirmation must be cleared after retry rejection");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Revert confirmation is no longer valid",
        "stale revert confirmation should report that the revert confirmation is no longer valid");
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Pending_Becomes_Stale_After_Save;


   procedure Test_Reload_Revert_Cancel_Messages_Are_Specific
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("reload_revert_cancel.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty reload starts an explicit confirmation before cancel");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "reload cancel clears only the transient confirmation");
      Assert (Buffer_Text (S) = "disk baseline dirty" and then S.File_Info.Dirty,
        "reload cancel preserves dirty buffer text and dirty state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Reload cancelled.",
        "reload cancel must name the file lifecycle operation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty revert starts an explicit confirmation before cancel");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "revert cancel clears only the transient confirmation");
      Assert (Buffer_Text (S) = "disk baseline dirty" and then S.File_Info.Dirty,
        "revert cancel preserves dirty buffer text and dirty state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Revert cancelled.",
        "revert cancel must name the file lifecycle operation");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Revert_Cancel_Messages_Are_Specific;


   procedure Test_File_Lifecycle_Confirmation_Blocks_Save_All_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("pending_blocks_save_all.txt");
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty reload should create a lifecycle confirmation");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "file-lifecycle confirmation should not advertise Save Current");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "Command unavailable while confirmation is pending.",
        "Save Current unavailable reason should match pending confirmation policy");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File_As);
      Assert (not Editor.Commands.Is_Available (Availability),
        "file-lifecycle confirmation should not advertise Save As");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "Command unavailable while confirmation is pending.",
        "Save As unavailable reason should match pending confirmation policy");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_All);
      Assert (not Editor.Commands.Is_Available (Availability),
        "file-lifecycle confirmation should not advertise Save All");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "Command unavailable while confirmation is pending.",
        "Save All unavailable reason should match pending confirmation policy");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "rejected Save Current must leave reload confirmation pending");
      Assert (S.File_Info.Dirty,
        "rejected Save Current must preserve dirty text/state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Command unavailable while confirmation is pending.",
        "rejected Save Current should report pending confirmation policy");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "rejected Save As must leave reload confirmation pending");
      Assert (S.File_Info.Dirty,
        "rejected Save As must preserve dirty text/state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Command unavailable while confirmation is pending.",
        "rejected Save As should report pending confirmation policy");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_All);

      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "rejected Save All must leave reload confirmation pending");
      Assert (S.File_Info.Dirty,
        "rejected Save All must preserve dirty text/state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Command unavailable while confirmation is pending.",
        "rejected Save All should report pending confirmation policy");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Lifecycle_Confirmation_Blocks_Save_All_Command;


   procedure Test_File_Lifecycle_Confirmation_Blocks_Target_Changing_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      type Command_List is array (Positive range <>) of Editor.Commands.Command_Id;
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("pending_blocks_target_routes.txt");
      Active_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Availability : Editor.Commands.Command_Availability;
      Blocked      : constant Command_List :=
        (Editor.Commands.Command_Open_File,
         Editor.Commands.Command_Accept_Quick_Open,
         Editor.Commands.Command_Quick_Open_Create_From_Query,
         Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query,
         Editor.Commands.Command_Accept_Buffer_Switcher,
         Editor.Commands.Command_Next_Buffer,
         Editor.Commands.Command_Previous_Buffer,
         Editor.Commands.Command_Next_Recent_Buffer,
         Editor.Commands.Command_Previous_Recent_Buffer,
         Editor.Commands.Command_Switch_Buffer,
         Editor.Commands.Command_File_Tree_Open_Selected,
         Editor.Commands.Command_File_Tree_Create_File,
         Editor.Commands.Command_File_Tree_Create_Directory,
         Editor.Commands.Command_File_Tree_Rename_Selected,
         Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Editor.Buffers.Global_Set_Active_Buffer (Active_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty reload should create a lifecycle confirmation");

      for Command of Blocked loop
         Availability := Editor.Executor.Command_Availability (S, Command);
         Assert (not Editor.Commands.Is_Available (Availability),
           "lifecycle confirmation should hide target-changing command "
           & Editor.Commands.Stable_Command_Name (Command));
         Assert (Editor.Commands.Unavailable_Reason (Availability) =
           "Command unavailable while confirmation is pending.",
           "target-changing command should use pending-confirmation reason");
      end loop;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Next_Buffer);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "rejected buffer switch must leave reload confirmation pending");
      Assert (Editor.Buffers.Global_Active_Buffer = Active_Id,
        "rejected buffer switch must not change the captured reload target");
      Assert (Buffer_Text (S) = "disk baseline dirty" and then S.File_Info.Dirty,
        "rejected target-changing route must preserve dirty text/state");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Lifecycle_Confirmation_Blocks_Target_Changing_Routes;


   procedure Test_File_Lifecycle_Confirmation_Blocks_Text_Mutations
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      type Command_List is array (Positive range <>) of Editor.Commands.Command_Id;
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("pending_blocks_text_mutations.txt");
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
      Blocked      : constant Command_List :=
        (Editor.Commands.Command_Insert_Newline,
         Editor.Commands.Command_Undo,
         Editor.Commands.Command_Redo,
         Editor.Commands.Command_Edit_History_Clear,
         Editor.Commands.Command_Cut,
         Editor.Commands.Command_Paste,
         Editor.Commands.Command_Selection_Delete,
         Editor.Commands.Command_Line_Delete,
         Editor.Commands.Command_Line_Duplicate,
         Editor.Commands.Command_Line_Move_Up,
         Editor.Commands.Command_Line_Move_Down,
         Editor.Commands.Command_Indent_Increase,
         Editor.Commands.Command_Indent_Decrease,
         Editor.Commands.Command_Comment_Line,
         Editor.Commands.Command_Uncomment_Line,
         Editor.Commands.Command_Toggle_Line_Comment,
         Editor.Commands.Command_Line_Join_Next,
         Editor.Commands.Command_Line_Split_At_Caret,
         Editor.Commands.Command_Trim_Trailing_Whitespace,
         Editor.Commands.Command_Char_Delete_Previous,
         Editor.Commands.Command_Char_Delete_Next,
         Editor.Commands.Command_Word_Delete_Previous,
         Editor.Commands.Command_Word_Delete_Next,
         Editor.Commands.Command_Replace_Current,
         Editor.Commands.Command_Replace_All);
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty reload should create a lifecycle confirmation before blocking edits");

      for Command of Blocked loop
         Availability := Editor.Executor.Command_Availability (S, Command);
         Assert (not Editor.Commands.Is_Available (Availability),
           "lifecycle confirmation should hide text mutation command "
           & Editor.Commands.Stable_Command_Name (Command));
         Assert (Editor.Commands.Unavailable_Reason (Availability) =
           "Command unavailable while confirmation is pending.",
           "text mutation command should use pending-confirmation reason");
      end loop;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Insert_Newline);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "rejected text mutation must leave reload confirmation pending");
      Assert (Buffer_Text (S) = "disk baseline dirty" and then S.File_Info.Dirty,
        "rejected text mutation must preserve dirty text/state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Command unavailable while confirmation is pending.",
        "rejected text mutation should report pending confirmation policy");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Lifecycle_Confirmation_Blocks_Text_Mutations;


   procedure Test_Save_As_Invalidates_Derived_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Target : constant String := Temp_Path ("save_as_derived.txt");
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Insert_Text_At (S, 0, "save as derived state");

      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
        "save-as test starts with non-stale project search state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);

      Assert (Ada.Directories.Exists (Target),
        "save-as still writes the explicit target");
      Assert (not S.File_Info.Dirty,
        "successful save-as still clears dirty state");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search)
        and then not Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
        "successful save-as keeps search and replace-preview live when no query is active");
      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Target);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Target);
         raise;
   end Test_Save_As_Invalidates_Derived_State;

   procedure Test_Lifecycle_Guidance_Projects_Read_Recovery_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "clean text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Temp_Path ("guidance_read.txt"));
      S.File_Info.Display_Name := To_Unbounded_String ("guidance_read.txt");
      S.File_Info.Dirty := False;

      S.File_Info.Last_Reload_Failed := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "unreadable") > 0,
        "status guidance should expose reload failure as unreadable backing state");

      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Last_Revert_Failed := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "unreadable") > 0,
        "status guidance should expose revert failure as unreadable backing state");

      S.File_Info.Last_Revert_Failed := False;
      S.File_Info.External_Change_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "External change") > 0,
        "status guidance should expose external-change recovery state");
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Lifecycle_Guidance_Projects_Read_Recovery_Markers;

   procedure Test_Open_Buffer_Guidance_Projects_Recovery_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => Editor.Buffers.Buffer_Id (1),
         Display_Name => To_Unbounded_String ("row.txt"),
         Is_Dirty     => False,
         Is_Active    => False,
         Has_Path     => True,
         Path         => To_Unbounded_String (Editor.Test_Temp.Base & "/project/demo.adb"),
         Last_Save_Failed   => False,
         Last_Reload_Failed => True,
         Last_Revert_Failed => False,
         Missing_Target_Surfaced    => False,
         Unreadable_Target_Surfaced => False,
         Unwritable_Target_Surfaced => False,
         External_Change_Surfaced   => False,
         Blocked_Close_Surfaced     => False,
         Is_Pinned               => False,
         Has_Group               => False,
         Group_Name              => Null_Unbounded_String,
         Has_Label               => False,
         Label_Text              => Null_Unbounded_String,
         Has_Note                => False,
         Note_Text               => Null_Unbounded_String);
   begin
      Editor.State.Init (S);

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "unreadable") > 0,
        "open-buffer guidance should expose reload failure markers");

      Summary.Last_Reload_Failed := False;
      Summary.Unwritable_Target_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "not writable") > 0,
        "open-buffer guidance should expose unwritable backing markers");

      Summary.Unwritable_Target_Surfaced := False;
      Summary.External_Change_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "External change") > 0,
        "open-buffer guidance should expose external-change markers");
   end Test_Open_Buffer_Guidance_Projects_Recovery_Markers;

   procedure Test_File_Tree_Guidance_Projects_Open_Buffer_Recovery_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("tree_hint.txt");
      Node  : Editor.File_Tree.File_Tree_Node_Summary :=
        (Id            => Editor.File_Tree.File_Tree_Node_Id (1),
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.File_Node,
         Name          => To_Unbounded_String ("tree_hint.txt"),
         Absolute_Path => To_Unbounded_String (Path),
         Relative_Path => To_Unbounded_String ("tree_hint.txt"),
         Depth         => 0,
         Is_Expanded   => False,
         Has_Children  => False);
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "tree hint baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      S.File_Info.Last_Reload_Failed := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node),
                 "unreadable") > 0,
        "file-tree guidance should expose open-buffer reload failures before generic focus hints");

      S.File_Info.Last_Reload_Failed := False;
      S.File_Info.Unwritable_Target_Surfaced := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node),
                 "unwritable") > 0,
        "file-tree guidance should expose open-buffer unwritable state before generic focus hints");

      S.File_Info.Unwritable_Target_Surfaced := False;
      S.File_Info.Dirty := True;
      S.File_Info.External_Change_Surfaced := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.File_Tree_Row_Hint (S, Node),
                 "conflict pending") > 0,
        "file-tree guidance should expose dirty open-buffer conflict state before generic focus hints");

      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Path);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Path);
         raise;
   end Test_File_Tree_Guidance_Projects_Open_Buffer_Recovery_Markers;

   procedure Test_Save_All_Invalidates_Derived_State_After_Restoring_Original_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Active_Path : constant String := Temp_Path ("save_all_active.txt");
      Saved_Path  : constant String := Temp_Path ("save_all_inactive.txt");
      Active_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Saved_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Saved_Path);
      Write_Bytes (Active_Path, "active clean");
      Write_Bytes (Saved_Path, "inactive clean");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Saved_Path);
      Saved_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      Editor.Buffers.Global_Set_Active_Buffer (Active_Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
        "save-all test starts with restored active buffer search state not stale");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_All);

      Assert (Editor.Buffers.Global_Active_Buffer = Active_Id,
        "save-all should restore the original active buffer after saving inactive buffers");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search)
        and then not Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
        "save-all should keep search and replace-preview live after restoring the original active buffer when no query is active");
      Assert (Read_Bytes (Saved_Path) = "inactive clean dirty",
        "save-all still writes the inactive dirty file-backed buffer");
      Assert (not Editor.Buffers.Buffer
                (Editor.Buffers.Global_Registry_For_UI, Saved_Id).File_Info.Dirty,
        "save-all still clears the saved inactive buffer dirty state");

      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Saved_Path);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Saved_Path);
         raise;
   end Test_Save_All_Invalidates_Derived_State_After_Restoring_Original_Buffer;



   procedure Test_Save_All_Summarizes_Recovery_Failure_Kinds
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Missing_Source : constant String := Temp_Path ("save_all_missing_source.txt");
      Dir_Source     : constant String := Temp_Path ("save_all_dir_source.txt");
      Missing_Parent : constant String := Temp_Path ("save_all_missing_parent");
      Missing_Path   : constant String := Ada.Directories.Compose (Missing_Parent, "lost.txt");
      Dir_Path       : constant String := Temp_Path ("save_all_dir_target");
      Missing_Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Dir_Id         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
      Missing_State  : Editor.State.State_Type;
      Dir_State      : Editor.State.State_Type;
   begin
      Remove_If_Exists (Missing_Source);
      Remove_If_Exists (Dir_Source);
      Remove_If_Exists (Missing_Parent);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Missing_Source, "missing source");
      Write_Bytes (Dir_Source, "dir source");
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Missing_Source);
      Missing_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      S.File_Info.Path := To_Unbounded_String (Missing_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("lost.txt");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Dir_Source);
      Dir_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_all_dir_target");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_All);

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message,
        "save-all mixed recovery failures should report one warning outcome");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "2 files failed") > 0,
        "save-all warning should retain the aggregate failed-file count");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "missing or invalid backing path") > 0,
        "save-all warning should summarize missing-parent/path failures");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "unwritable backing file") > 0,
        "save-all warning should summarize unwritable/is-directory failures");

      Missing_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, Missing_Id);
      Dir_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, Dir_Id);
      Assert (Missing_State.File_Info.Dirty
        and then Missing_State.File_Info.Missing_Target_Surfaced,
        "save-all missing-parent failure must preserve dirty text and marker");
      Assert (Dir_State.File_Info.Dirty
        and then Dir_State.File_Info.Unwritable_Target_Surfaced,
        "save-all directory target failure must preserve dirty text and unwritable marker");

      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Missing_Source);
      Remove_If_Exists (Dir_Source);
      Remove_If_Exists (Dir_Path);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Missing_Source);
         Remove_If_Exists (Dir_Source);
         Remove_If_Exists (Dir_Path);
         raise;
   end Test_Save_All_Summarizes_Recovery_Failure_Kinds;

   procedure Test_Dirty_Recovery_Markers_Take_Guidance_Precedence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("dirty_recovery_precedence.txt");
      Summary : Editor.Buffers.Buffer_Summary;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "dirty recovery baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");

      S.File_Info.Last_Save_Failed := True;
      S.File_Info.Missing_Target_Surfaced := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Summary := Editor.Buffers.Global_Summary_For
        (Editor.Buffers.Global_Active_Buffer);

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "missing") > 0,
        "dirty status guidance must expose missing backing state before generic retry-save text");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "missing") > 0,
        "active dirty open-buffer guidance must expose missing backing state before generic save hints");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Summary.Display_Name),
                 "missing target") > 0,
        "dirty buffer display labels must prefer recovery markers over generic retry-save labels");

      S.File_Info.Missing_Target_Surfaced := False;
      S.File_Info.Unwritable_Target_Surfaced := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Summary := Editor.Buffers.Global_Summary_For
        (Editor.Buffers.Global_Active_Buffer);

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "not writable") > 0,
        "dirty status guidance must expose unwritable backing state before retry-save text");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Summary.Display_Name),
                 "unwritable target") > 0,
        "dirty buffer display labels must prefer unwritable markers over generic retry-save labels");

      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Path);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Path);
         raise;
   end Test_Dirty_Recovery_Markers_Take_Guidance_Precedence;

   procedure Test_Active_Row_Guidance_Uses_Buffer_Summary_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => Editor.Buffers.Buffer_Id (1),
         Display_Name => To_Unbounded_String ("active-summary.txt"),
         Is_Dirty     => True,
         Is_Active    => True,
         Has_Path     => True,
         Path         => To_Unbounded_String (Editor.Test_Temp.Base & "/project/demo.adb"),
         Last_Save_Failed   => True,
         Last_Reload_Failed => False,
         Last_Revert_Failed => False,
         Missing_Target_Surfaced    => True,
         Unreadable_Target_Surfaced => False,
         Unwritable_Target_Surfaced => False,
         External_Change_Surfaced   => False,
         Blocked_Close_Surfaced     => False,
         Is_Pinned               => False,
         Has_Group               => False,
         Group_Name              => Null_Unbounded_String,
         Has_Label               => False,
         Label_Text              => Null_Unbounded_String,
         Has_Note                => False,
         Note_Text               => Null_Unbounded_String);
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "active row summary baseline");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Temp_Path ("active_summary.txt"));
      S.File_Info.Display_Name := To_Unbounded_String ("active_summary.txt");
      S.File_Info.Dirty := True;
      --  Deliberately leave the active State_Type without recovery markers.
      --  The row hint must still honor the supplied active-row summary rather
      --  than falling back to generic active dirty save/retry hints.

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "missing") > 0,
        "active dirty row guidance must use supplied summary recovery markers");

      Summary.Missing_Target_Surfaced := False;
      Summary.Unreadable_Target_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "unreadable") > 0,
        "active dirty row guidance must expose summary unreadable markers");

      Summary.Unreadable_Target_Surfaced := False;
      Summary.Unwritable_Target_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "not writable") > 0,
        "active dirty row guidance must expose summary unwritable markers");
   end Test_Active_Row_Guidance_Uses_Buffer_Summary_Markers;

   procedure Test_Inactive_Dirty_Recovery_Markers_Take_Guidance_Precedence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => Editor.Buffers.Buffer_Id (2),
         Display_Name => To_Unbounded_String ("inactive.txt"),
         Is_Dirty     => True,
         Is_Active    => False,
         Has_Path     => True,
         Path         => To_Unbounded_String (Editor.Test_Temp.Base & "/project/demo.adb"),
         Last_Save_Failed   => True,
         Last_Reload_Failed => False,
         Last_Revert_Failed => False,
         Missing_Target_Surfaced    => True,
         Unreadable_Target_Surfaced => False,
         Unwritable_Target_Surfaced => False,
         External_Change_Surfaced   => False,
         Blocked_Close_Surfaced     => False,
         Is_Pinned               => False,
         Has_Group               => False,
         Group_Name              => Null_Unbounded_String,
         Has_Label               => False,
         Label_Text              => Null_Unbounded_String,
         Has_Note                => False,
         Note_Text               => Null_Unbounded_String);
   begin
      Editor.State.Init (S);

      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "missing") > 0,
        "inactive dirty open-buffer guidance must expose missing backing state before generic retry-save text");

      Summary.Missing_Target_Surfaced := False;
      Summary.Unwritable_Target_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "not writable") > 0,
        "inactive dirty open-buffer guidance must expose unwritable backing state before generic retry-save text");

      Summary.Unwritable_Target_Surfaced := False;
      Summary.External_Change_Surfaced := True;
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Open_Buffer_Row_Hint (S, Summary),
                 "conflict pending") > 0,
        "inactive dirty open-buffer guidance must expose conflict state before generic retry-save text");
   end Test_Inactive_Dirty_Recovery_Markers_Take_Guidance_Precedence;


   procedure Test_Display_Name_For_Path_Returns_Basename
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Current_Directory, "display_name.txt");
   begin
      Assert (Editor.Files.Display_Name_For_Path (Path) = "display_name.txt",
        "Display_Name_For_Path should return the basename for normal paths");
      Assert (Editor.Files.Display_Name_For_Path ("") = "Untitled",
        "Display_Name_For_Path should return Untitled for an empty path");
   end Test_Display_Name_For_Path_Returns_Basename;

   procedure Test_Execute_Save_On_Opened_File_Writes_And_Cleans
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("execute_save.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "saved text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("execute_save.txt");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Read_Bytes (Path) = "saved text",
        "Execute_Save should write current buffer contents to current path");
      Assert (S.File_Info.Has_Path,
        "Execute_Save should preserve path-backed file identity");
      Assert (To_String (S.File_Info.Path) = Path,
        "Execute_Save should preserve the current file path");
      Assert (To_String (S.File_Info.Display_Name) = "execute_save.txt",
        "Execute_Save should preserve/refresh the display name");
      Assert (not S.File_Info.Dirty,
        "Execute_Save should clear dirty state after successful write");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Execute_Save should publish a success message");
      Assert (M.Severity = Editor.Messages.Success_Message,
        "Execute_Save success should use success severity");
      Assert (To_String (M.Text) = "Saved file",
        "Execute_Save success message should use canonical text");
      Remove_If_Exists (Path);
   end Test_Execute_Save_On_Opened_File_Writes_And_Cleans;

   procedure Test_Execute_Save_Untitled_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled text");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (not S.File_Info.Has_Path,
        "Execute_Save on an untitled buffer should not invent a path");
      Assert (To_String (S.File_Info.Display_Name) = "Untitled",
        "Execute_Save on an untitled buffer should preserve display name");
      Assert (S.File_Info.Dirty,
        "Execute_Save failure should preserve dirty state");
      Assert (Buffer_Text (S) = "untitled text",
        "Execute_Save failure should preserve buffer contents");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Execute_Save untitled failure should publish a message");
      Assert (M.Severity = Editor.Messages.Info_Message,
        "Execute_Save untitled failure should use informational severity");
      Assert (To_String (M.Text) = "No file path for active buffer",
        "Execute_Save untitled failure should use deterministic text");
   end Test_Execute_Save_Untitled_Preserves_State;

   procedure Test_Execute_Save_Failure_Preserves_File_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Dir_Path : constant String := Temp_Path ("execute_save_dir");
      Found    : Boolean := False;
      M        : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "preserve on failed save");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("before.adb");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Dir_Path
        and then To_String (S.File_Info.Display_Name) = "before.adb",
        "Execute_Save failure should preserve current file identity");
      Assert (S.File_Info.Dirty,
        "Execute_Save failure should preserve dirty state");
      Assert (Buffer_Text (S) = "preserve on failed save",
        "Execute_Save failure should preserve buffer contents");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Execute_Save failure should publish a message");
      Assert (M.Severity = Editor.Messages.Error_Message,
        "Execute_Save failure should use error severity");
      Assert (To_String (M.Text) = "Could not save file.",
        "Execute_Save failure should report the save failure reason");
      Remove_If_Exists (Dir_Path);
   end Test_Execute_Save_Failure_Preserves_File_Identity;

   procedure Test_Execute_Save_As_Writes_Identity_And_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("execute_save_as.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
      Snap  : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "save as text");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);

      Assert (Read_Bytes (Path) = "save as text",
        "Execute_Save_As should write current buffer contents to requested path");
      Assert (S.File_Info.Has_Path,
        "Execute_Save_As should set path-backed file identity on success");
      Assert (To_String (S.File_Info.Path) = Path,
        "Execute_Save_As should store the requested path on success");
      Assert (To_String (S.File_Info.Display_Name) = "execute_save_as.txt",
        "Execute_Save_As should derive display name from requested path");
      Assert (not S.File_Info.Dirty,
        "Execute_Save_As should clear dirty state after successful write");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Execute_Save_As should publish a success message");
      Assert (M.Severity = Editor.Messages.Success_Message,
        "Execute_Save_As success should use success severity");
      Assert (To_String (M.Text) = "Saved file as",
        "Execute_Save_As success message should use deterministic Save As text");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (To_String (Snap.File_Name) = "execute_save_as.txt",
        "Status snapshot should show the Save As display name");
      Assert (not Snap.Is_Dirty,
        "Status snapshot dirty marker should disappear after successful Save As");
      Remove_If_Exists (Path);
   end Test_Execute_Save_As_Writes_Identity_And_Status;

   procedure Test_Execute_Save_As_Invalid_Path_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "keep save-as text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("before.txt");
      S.File_Info.Display_Name := To_Unbounded_String ("before.txt");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, "");

      Assert (Buffer_Text (S) = "keep save-as text",
        "Failed Save As should preserve buffer contents");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = "before.txt"
        and then To_String (S.File_Info.Display_Name) = "before.txt",
        "Failed Save As should preserve previous file identity");
      Assert (S.File_Info.Dirty,
        "Failed Save As should preserve dirty state");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Failed Save As should publish a message");
      Assert (M.Severity = Editor.Messages.Error_Message,
        "Failed Save As should use error severity");
      Assert (To_String (M.Text) = "No target path for Save As",
        "Failed Save As should use deterministic no-target text");
   end Test_Execute_Save_As_Invalid_Path_Preserves_State;

   procedure Test_Execute_Save_As_Directory_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Dir_Path : constant String := Temp_Path ("execute_save_as_dir");
      Found    : Boolean := False;
      M        : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "keep save-as directory text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("before-save-as.adb");
      S.File_Info.Display_Name := To_Unbounded_String ("before-save-as.adb");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Dir_Path);

      Assert (Buffer_Text (S) = "keep save-as directory text",
        "Directory Save As failure should preserve buffer contents");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = "before-save-as.adb"
        and then To_String (S.File_Info.Display_Name) = "before-save-as.adb",
        "Directory Save As failure should preserve previous file identity");
      Assert (S.File_Info.Dirty,
        "Directory Save As failure should preserve dirty state");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Directory Save As failure should publish a message");
      Assert (M.Severity = Editor.Messages.Error_Message,
        "Directory Save As failure should use error severity");
      Assert (To_String (M.Text) = "Invalid Save As target",
        "Directory Save As failure should report deterministic invalid-target feedback");
      Remove_If_Exists (Dir_Path);
   end Test_Execute_Save_As_Directory_Preserves_State;

   procedure Test_Save_As_Does_Not_Reset_Editor_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("save_as_preserve.txt");
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Scroll_X : Natural;
      Before_Scroll_Y : Natural;
   begin
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "abc" & ASCII.LF & "def");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 3,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "def");
      Editor.State.Add_Diagnostic (S, 0, 1, Editor.Diagnostics.Warning);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Folding.Add_Fold (S.Folding, 0, 1);
      Editor.View.Set_Scroll (4, 2);
      S.File_Info.Dirty := True;
      Before_Caret := S.Carets (0);
      Before_Scroll_X := Editor.View.Scroll_X;
      Before_Scroll_Y := Editor.View.Scroll_Y;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);

      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "Save As should not reset caret or selection state");
      Assert (Editor.View.Scroll_X = Before_Scroll_X
        and then Editor.View.Scroll_Y = Before_Scroll_Y,
        "Save As should not reset scroll position");
      Assert (S.Active_Find_Matches.Length > 0,
        "Save As should not clear active Find matches");
      Assert (S.Diagnostics.Length > 0,
        "Save As should not clear diagnostics");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 0, Editor.Gutter_Markers.Bookmark_Marker),
        "Save As should not clear gutter markers");
      Assert (S.Folding.Ranges.Length > 0,
        "Save As should not clear folding state");
      Remove_If_Exists (Path);
   end Test_Save_As_Does_Not_Reset_Editor_State;



   procedure Test_Save_Availability_Rejects_Untitled
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Availability : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "unsaved untitled");
      S.File_Info.Dirty := True;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      Assert (not Editor.Commands.Is_Available (Availability),
        "Save command should be unavailable for an untitled buffer");
      Assert (Editor.Commands.Unavailable_Reason (Availability) = "No file path for active buffer",
        "Save unavailable reason for untitled buffers should be deterministic");
   end Test_Save_Availability_Rejects_Untitled;

   procedure Test_Save_Availability_Allows_File_Backed_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Path : constant String := Temp_Path ("save_availability.txt");
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "file-backed text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_availability.txt");
      S.File_Info.Dirty := True;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      Assert (Editor.Commands.Is_Available (Availability),
        "Save command should be available for a file-backed buffer");
   end Test_Save_Availability_Allows_File_Backed_Buffer;

   procedure Test_Failed_Save_Preserves_Cursor_Selection_And_Message_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Dir_Path : constant String := Temp_Path ("failed_save_dir");
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Text   : constant String := "alpha" & ASCII.LF & "beta";
      Found    : Boolean := False;
      M        : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("failed_save.adb");
      S.File_Info.Dirty := True;
      Before_Caret := S.Carets (0);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Buffer_Text (S) = Before_Text,
        "Failed save should preserve buffer content");
      Assert (S.File_Info.Dirty,
        "Failed save should preserve dirty state");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "Failed save should preserve cursor and selection");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "Failed save should emit one primary visible message");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "Failed save should publish an error message");
      Assert (To_String (M.Text) = "Could not save file.",
        "Failed save feedback should be deterministic");
      Remove_If_Exists (Dir_Path);
   end Test_Failed_Save_Preserves_Cursor_Selection_And_Message_Count;

   procedure Test_Save_As_Empty_Path_Uses_Deterministic_Error
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "save as explicit path required");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, "");

      Assert (not S.File_Info.Has_Path,
        "Failed Save As should not convert untitled buffer to file-backed");
      Assert (S.File_Info.Dirty,
        "Failed Save As should preserve dirty state");
      Assert (Buffer_Text (S) = "save as explicit path required",
        "Failed Save As should preserve buffer content");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "Failed Save As should emit one primary visible message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "Failed Save As should use error severity");
      Assert (To_String (M.Text) = "No target path for Save As",
        "Failed Save As should use deterministic no-target feedback");
   end Test_Save_As_Empty_Path_Uses_Deterministic_Error;


   procedure Test_Missing_Backing_File_Save_Recreates_Explicitly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("missing_recreate.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "recreated by explicit save");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("missing_recreate.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 7;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Ada.Directories.Exists (Path),
        "Explicit save should recreate a missing backing file under current policy");
      Assert (Read_Bytes (Path) = "recreated by explicit save",
        "Recreated backing file should contain current buffer text");
      Assert (not S.File_Info.Dirty,
        "Successful recreate save should clear dirty state");
      Assert (S.File_Info.Baseline_Valid,
        "Successful recreate save should keep a valid baseline");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "Successful recreate save should update saved generation");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message,
        "Recreate save should publish a success message");
      Assert (To_String (M.Text) = "Saved file",
        "Recreate save feedback should be deterministic");
      Remove_If_Exists (Path);
   end Test_Missing_Backing_File_Save_Recreates_Explicitly;

   procedure Test_Directory_Target_Preserves_Editing_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Dir_Path      : constant String := Temp_Path ("directory_target");
      Before_Text   : constant String := "line one" & ASCII.LF & "line two";
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Saved  : Natural := 0;
      Before_X      : Natural := 0;
      Before_Y      : Natural := 0;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
      Snap          : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 2,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.View.Set_Scroll (6, 3);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("directory_target.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 42;
      Before_Caret := S.Carets (0);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_X := Editor.View.Scroll_X;
      Before_Y := Editor.View.Scroll_Y;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Buffer_Text (S) = Before_Text,
        "Directory-target failed save should preserve buffer content");
      Assert (S.File_Info.Dirty,
        "Directory-target failed save should preserve dirty state");
      Assert (S.File_Info.Saved_Generation = Before_Saved,
        "Directory-target failed save should preserve saved generation");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "Directory-target failed save should preserve cursor and selection");
      Assert (Editor.View.Scroll_X = Before_X and then Editor.View.Scroll_Y = Before_Y,
        "Directory-target failed save should preserve viewport");
      Assert (not Ada.Directories.Exists
        (Ada.Directories.Compose (Dir_Path, "directory_target.adb")),
        "Directory-target failed save must not create an implicit child file");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "Directory-target failed save should publish an error");
      Assert (To_String (M.Text) = "Could not save file.",
        "Directory-target failure feedback should be deterministic");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Is_Dirty,
        "Status snapshot should keep dirty marker after failed save");
      Assert (To_String (Snap.File_Name) = "directory_target.adb",
        "Status snapshot should keep active buffer label after failed save");
      Remove_If_Exists (Dir_Path);
   end Test_Directory_Target_Preserves_Editing_Context;

   procedure Test_Failed_Save_Preserves_Undo_Redo_And_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Dir_Path      : constant String := Temp_Path ("history_dir");
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Saved  : Natural := 0;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'a'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'b'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (not Editor.History.Undo_Stack.Is_Empty,
        "Test setup should have undo history before failed save");
      Assert (not Editor.History.Redo_Stack.Is_Empty,
        "Test setup should have redo history before failed save");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("history.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 11;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Saved := S.File_Info.Saved_Generation;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Editor.History.Undo_Stack.Length = Before_Undo,
        "Failed save should preserve undo history");
      Assert (Editor.History.Redo_Stack.Length = Before_Redo,
        "Failed save should preserve redo history");
      Assert (S.File_Info.Saved_Generation = Before_Saved,
        "Failed save should not update saved baseline generation");
      Assert (S.File_Info.Baseline_Valid,
        "Failed save should preserve baseline validity");
      Remove_If_Exists (Dir_Path);
   end Test_Failed_Save_Preserves_Undo_Redo_And_Baseline;

   procedure Test_Save_File_Uses_Temporary_File_For_Existing_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path : constant String := Temp_Path ("atomic_existing.txt");
      Temp : constant String := Ada.Directories.Compose
        (Ada.Directories.Containing_Directory (Path),
         "." & Ada.Directories.Simple_Name (Path) & ".editor-save.tmp");
      Result : Editor.Files.File_Save_Result;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Temp);
      Write_Bytes (Path, "old contents");

      Result := Editor.Files.Save_File (Path, "new contents");

      Assert (Editor.Files.Is_Success (Result),
        "Save_File should succeed for an existing regular target");
      Assert (Read_Bytes (Path) = "new contents",
        "Save_File should replace target with complete new contents");
      Assert (not Ada.Directories.Exists (Temp),
        "Save_File should clean temporary save file after success");
      Remove_If_Exists (Path);
      Remove_If_Exists (Temp);
   end Test_Save_File_Uses_Temporary_File_For_Existing_Target;

   overriding function Name (T : Save_Reload_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Save_Reload.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Save_Reload_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Save_And_Reload_Update_Baseline'Access, "Open Save And Reload Update Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Does_Not_Update_Baseline'Access, "Failed Save Does Not Update Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Reload_Is_Blocked_And_Preserves_State'Access, "Dirty Reload Is Blocked And Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Missing_And_Read_Failure_Reload_Preserve_Buffer'Access, "Missing And Read Failure Reload Preserve Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Already_Open_Changed_File_Does_Not_Reread'Access, "Open Already Open Changed File Does Not Reread");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Writes_Buffer_And_Cleans_State'Access, "Save Writes Buffer And Cleans State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_On_Save_Trims_Before_File_Save'Access, "Format On Save Trims Before File Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Edit_After_Save_Marks_Dirty'Access, "Edit After Save Marks Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Without_Path_Returns_Invalid_Path'Access, "Save Without Path Returns Invalid Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Writes_Contents'Access, "Save File Result Writes Contents");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Rejects_Invalid_And_Directory'Access, "Save File Result Rejects Invalid And Directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Reports_Missing_Parent'Access, "Save File Result Reports Missing Parent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Missing_Target_Surfaces_State_And_Preserves_Text'Access, "Reload Missing Target Surfaces State And Preserves Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Missing_Target_Preserves_Dirty_Text'Access, "Revert Missing Target Preserves Dirty Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Pending_Becomes_Stale_After_Save'Access, "Reload Pending Becomes Stale After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Pending_Becomes_Stale_After_Save'Access, "Revert Pending Becomes Stale After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Revert_Cancel_Messages_Are_Specific'Access, "Reload Revert Cancel Messages Are Specific");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Save_All_Command'Access, "File Lifecycle Confirmation Blocks Save All Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Target_Changing_Routes'Access, "File Lifecycle Confirmation Blocks Target Changing Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Text_Mutations'Access, "File Lifecycle Confirmation Blocks Text Mutations");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Invalidates_Derived_State'Access, "Save As Invalidates Derived State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Lifecycle_Guidance_Projects_Read_Recovery_Markers'Access, "Lifecycle Guidance Projects Read Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Guidance_Projects_Recovery_Markers'Access, "Open Buffer Guidance Projects Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Guidance_Projects_Open_Buffer_Recovery_Markers'Access, "File Tree Guidance Projects Open Buffer Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_All_Invalidates_Derived_State_After_Restoring_Original_Buffer'Access, "Save All Invalidates Derived State After Restoring Original Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_All_Summarizes_Recovery_Failure_Kinds'Access, "Save All Summarizes Recovery Failure Kinds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Recovery_Markers_Take_Guidance_Precedence'Access, "Dirty Recovery Markers Take Guidance Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Row_Guidance_Uses_Buffer_Summary_Markers'Access, "Active Row Guidance Uses Buffer Summary Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Inactive_Dirty_Recovery_Markers_Take_Guidance_Precedence'Access, "Inactive Dirty Recovery Markers Take Guidance Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Display_Name_For_Path_Returns_Basename'Access, "Display Name For Path Returns Basename");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_On_Opened_File_Writes_And_Cleans'Access, "Execute Save On Opened File Writes And Cleans");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_Untitled_Preserves_State'Access, "Execute Save Untitled Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_Failure_Preserves_File_Identity'Access, "Execute Save Failure Preserves File Identity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Writes_Identity_And_Status'Access, "Execute Save As Writes Identity And Status");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Invalid_Path_Preserves_State'Access, "Execute Save As Invalid Path Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Directory_Preserves_State'Access, "Execute Save As Directory Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Does_Not_Reset_Editor_State'Access, "Save As Does Not Reset Editor State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Rejects_Untitled'Access, "Save Availability Rejects Untitled");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Allows_File_Backed_Buffer'Access, "Save Availability Allows File Backed Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Preserves_Cursor_Selection_And_Message_Count'Access, "Failed Save Preserves Cursor Selection And Message Count");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Empty_Path_Uses_Deterministic_Error'Access, "Save As Empty Path Uses Deterministic Error");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Missing_Backing_File_Save_Recreates_Explicitly'Access, "Missing Backing File Save Recreates Explicitly");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Directory_Target_Preserves_Editing_Context'Access, "Directory Target Preserves Editing Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Preserves_Undo_Redo_And_Baseline'Access, "Failed Save Preserves Undo Redo And Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Uses_Temporary_File_For_Existing_Target'Access, "Save File Uses Temporary File For Existing Target");
   end Register_Tests;

end Editor.Files.Save_Reload_Tests;
