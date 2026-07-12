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

package body Editor.Files.Tests is

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

   overriding function Name (T : Files_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files");
   end Name;

   procedure Test_Load_Simple_File
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("load_simple.txt");
      Status : Editor.Files.File_Status;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "alpha" & ASCII.LF & "beta");
      Editor.State.Init (S);

      Status := Editor.Files.Load_File (Path, S);

      Assert (Status = Editor.Files.Ok, "Load_File should return Ok");
      Assert (Buffer_Text (S) = "alpha" & ASCII.LF & "beta",
        "Load_File should replace buffer with file text");
      Assert (not S.File_Info.Dirty, "Loaded file should be clean");
      Assert (To_String (S.File_Info.Path) = Path, "Loaded path should be stored");
      Remove_If_Exists (Path);
   end Test_Load_Simple_File;

   procedure Test_Load_CRLF_Normalizes_To_LF
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("load_crlf.txt");
      Status : Editor.Files.File_Status;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "a" & ASCII.CR & ASCII.LF & "b" & ASCII.CR & "c");
      Editor.State.Init (S);

      Status := Editor.Files.Load_File (Path, S);

      Assert (Status = Editor.Files.Ok, "CRLF file should load");
      Assert (Buffer_Text (S) = "a" & ASCII.LF & "b" & ASCII.LF & "c",
        "Load_File should normalize CRLF and bare CR to LF");
      Remove_If_Exists (Path);
   end Test_Load_CRLF_Normalizes_To_LF;

   procedure Test_Load_Missing_File
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("missing.txt");
      Status : Editor.Files.File_Status;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);
      Status := Editor.Files.Load_File (Path, S);
      Assert (Status = Editor.Files.Not_Found,
        "Missing file should return Not_Found");
   end Test_Load_Missing_File;

   procedure Test_Load_Rejects_NUL_And_Invalid_UTF8
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Nul_Path     : constant String := Temp_Path ("nul.txt");
      Invalid_Path : constant String := Temp_Path ("invalid_utf8.txt");
   begin
      Remove_If_Exists (Nul_Path);
      Remove_If_Exists (Invalid_Path);
      Write_Bytes (Nul_Path, "a" & ASCII.NUL & "b");
      Write_Bytes (Invalid_Path, String'(1 => Character'Val (16#C0#)));
      Editor.State.Init (S);

      Assert (Editor.Files.Load_File (Nul_Path, S) = Editor.Files.Decode_Error,
        "Embedded NUL should be rejected");
      Assert (Editor.Files.Load_File (Invalid_Path, S) = Editor.Files.Decode_Error,
        "Invalid UTF-8 should be rejected");
      Remove_If_Exists (Nul_Path);
      Remove_If_Exists (Invalid_Path);
   end Test_Load_Rejects_NUL_And_Invalid_UTF8;

   procedure Test_Load_Resets_State_And_History
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("reset.txt");
      Cmd    : Editor.Commands.Command;
      Status : Editor.Files.File_Status;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "line1" & ASCII.LF & "line2");
      Editor.State.Init (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Cmd.Kind := Editor.Commands.Move_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Status := Editor.Files.Load_File (Path, S);

      Assert (Status = Editor.Files.Ok, "Load should succeed");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0
        and then S.Carets (0).Anchor = 0,
        "Load should reset carets and selections to document start");
      Assert (Editor.History.Undo_Stack.Is_Empty
        and then Editor.History.Redo_Stack.Is_Empty,
        "Load should clear undo and redo history");
      Assert (Editor.State.Line_Count (S) = 2,
        "Load should rebuild line metadata");
      Remove_If_Exists (Path);
   end Test_Load_Resets_State_And_History;



   procedure Test_Open_File_Result_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("open_result.txt");
      Result : Editor.Files.File_Open_Result;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "open" & ASCII.LF & "me");

      Result := Editor.Files.Open_File (Path);

      Assert (Editor.Files.Is_Success (Result),
        "Open_File should return success for an existing regular file");
      Assert (To_String (Result.Contents) = "open" & ASCII.LF & "me",
        "Open_File should return normalized file contents");
      Assert (To_String (Result.Display_Name) = "open_result.txt",
        "Open_File should derive a basename display name");
      Remove_If_Exists (Path);
   end Test_Open_File_Result_Success;

   procedure Test_Open_File_Result_Failures
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Missing_Path : constant String := Temp_Path ("missing_open_result.txt");
      Dir_Path     : constant String := Temp_Path ("open_dir");
      Result       : Editor.Files.File_Open_Result;
   begin
      Remove_If_Exists (Missing_Path);
      Remove_If_Exists (Dir_Path);

      Result := Editor.Files.Open_File ("");
      Assert (Result.Status = Editor.Files.File_Open_Invalid_Path,
        "Open_File should reject an empty path");

      Result := Editor.Files.Open_File (Missing_Path);
      Assert (Result.Status = Editor.Files.File_Open_Not_Found,
        "Open_File should report a missing file");

      Ada.Directories.Create_Directory (Dir_Path);
      Result := Editor.Files.Open_File (Dir_Path);
      Assert (Result.Status = Editor.Files.File_Open_Is_Directory,
        "Open_File should report a directory path");
      Remove_If_Exists (Dir_Path);
   end Test_Open_File_Result_Failures;

   procedure Test_Execute_Open_File_Replaces_State_And_Publishes_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command;
      Path  : constant String := Temp_Path ("execute_open.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
      Snap  : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "new text");
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "old text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      S.File_Info.Dirty := False;
      Cmd.Kind := Editor.Commands.Move_Right;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Assert (Buffer_Text (S) = "new text",
        "Execute_Open_File should replace buffer contents");
      Assert (S.File_Info.Has_Path,
        "Execute_Open_File should mark current file as path-backed");
      Assert (To_String (S.File_Info.Path) = Path,
        "Execute_Open_File should store the opened path");
      Assert (To_String (S.File_Info.Display_Name) = "execute_open.txt",
        "Execute_Open_File should store the opened display name");
      Assert (not S.File_Info.Dirty,
        "Execute_Open_File should leave opened file clean");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0
        and then S.Carets (0).Anchor = 0,
        "Execute_Open_File should reset caret and selection to start");
      Assert (Editor.History.Undo_Stack.Is_Empty
        and then Editor.History.Redo_Stack.Is_Empty,
        "Execute_Open_File should clear undo and redo history");
      Assert (Editor.View.Scroll_X = 0 and then Editor.View.Scroll_Y = 0,
        "Execute_Open_File should reset scroll to top");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Execute_Open_File should publish a success message");
      Assert (M.Severity = Editor.Messages.Success_Message,
        "Execute_Open_File success should use success severity");
      Assert (To_String (M.Text) = "Opened execute_open.txt",
        "Execute_Open_File success should mention display name");

      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (To_String (Snap.File_Name) = "execute_open.txt",
        "Status snapshot path should use opened display name");
      Assert (not Snap.Is_Dirty,
        "Status snapshot dirty marker should be absent after successful open");
      Remove_If_Exists (Path);
   end Test_Execute_Open_File_Replaces_State_And_Publishes_Message;

   procedure Test_Execute_Open_File_Clears_Derived_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("derived_clear.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "replacement");
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "old" & ASCII.LF & "line" & ASCII.LF & "text");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "line");
      Editor.State.Add_Diagnostic
        (S, 0, 3, Editor.Diagnostics.Warning);
      Editor.Gutter_Markers.Add_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.State.Set_Gutter_Marker_Hover
        (S, 1, Editor.Gutter_Markers.Bookmark_Marker);
      Editor.Folding.Add_Fold (S.Folding, 0, 2);
      Editor.Folding.Toggle_Fold_At_Row (S.Folding, 0);

      Assert (S.Active_Find_Matches.Length > 0,
        "Test setup should create active Find matches before open");
      Assert (S.Diagnostics.Length > 0,
        "Test setup should create diagnostics before open");
      Assert (Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "Test setup should create a gutter marker before open");
      Assert (S.Gutter_Marker_Hover.Active,
        "Test setup should create marker hover before open");
      Assert (S.Folding.Ranges.Length > 0,
        "Test setup should create folding state before open");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Assert (Length (S.Active_Find_Query) = 0,
        "Successful open should clear active Find query");
      Assert (S.Active_Find_Matches.Length = 0,
        "Successful open should clear active Find matches");
      Assert (not Editor.Search.Has_Match (S.Active_Find_Match),
        "Successful open should clear the active Find match");
      Assert (S.Diagnostics.Length = 0,
        "Successful open should clear diagnostics");
      Assert (not Editor.Gutter_Markers.Has_Marker
        (S.Gutter_Markers, 1, Editor.Gutter_Markers.Bookmark_Marker),
        "Successful open should clear gutter markers");
      Assert (not S.Gutter_Marker_Hover.Active,
        "Successful open should clear marker hover");
      Assert (S.Folding.Ranges.Length = 0,
        "Successful open should clear folding state");
      Assert (Buffer_Text (S) = "replacement",
        "Successful open should still replace buffer contents");

      Remove_If_Exists (Path);
   end Test_Execute_Open_File_Clears_Derived_State;

   procedure Test_Execute_Open_File_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Missing_Path : constant String := Temp_Path ("execute_missing.txt");
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Missing_Path);
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "keep me");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String ("before.txt");
      S.File_Info.Display_Name := To_Unbounded_String ("before.txt");
      S.File_Info.Dirty := False;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Missing_Path);

      Assert (Buffer_Text (S) = "keep me",
        "Failed open should preserve buffer contents");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = "before.txt"
        and then To_String (S.File_Info.Display_Name) = "before.txt",
        "Failed open should preserve current file identity");
      Assert (not S.File_Info.Dirty,
        "Failed open should preserve dirty state");

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Failed open should publish an error message");
      Assert (M.Severity = Editor.Messages.Error_Message,
        "Failed open should use error severity");
      Assert (To_String (M.Text)'Length >= 12
        and then To_String (M.Text) (1 .. 12) = "Open failed:",
        "Failed open should use the open-failed prefix");
   end Test_Execute_Open_File_Failure_Preserves_State;

   procedure Test_Dirty_Buffer_Open_Is_Blocked
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("dirty_open_new_buffer.txt");
      Old_Id : Editor.Buffers.Buffer_Id;
      New_Id : Editor.Buffers.Buffer_Id;
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "replacement");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty buffer");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Old_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      New_Id := Editor.Buffers.Global_Active_Buffer;

      Assert (New_Id /= Old_Id,
        "Dirty-buffer open policy should create and activate a new buffer");
      Assert (Buffer_Text (S) = "replacement",
        "Dirty-buffer open policy should load replacement in the active buffer");
      Assert (not S.File_Info.Dirty,
        "Opened file buffer should be clean");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Old_Id);
      Assert (Buffer_Text (S) = "dirty buffer",
        "Dirty original buffer should remain available after open");
      Assert (S.File_Info.Dirty,
        "Dirty original buffer should preserve dirty state");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, New_Id);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found, "Dirty-buffer open policy should publish a message");
      Assert (M.Severity = Editor.Messages.Success_Message,
        "Dirty-buffer open policy should report successful open");
      Assert (To_String (M.Text) = "Opened dirty_open_new_buffer.txt",
        "Dirty-buffer open policy should use deterministic success text");
      Remove_If_Exists (Path);
   end Test_Dirty_Buffer_Open_Is_Blocked;


   procedure Test_Open_Already_Open_Path_Alias_Focuses_Existing
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("alias.txt");
      Alias_Path    : constant String :=
        "/tmp/editor-tests/../editor-tests/alias.txt";
      First_Id      : Editor.Buffers.Buffer_Id;
      Before_Count  : Natural;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk-one");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      First_Id := Editor.Buffers.Global_Active_Buffer;
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Write_Bytes (Path, "disk-two");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alias_Path);

      Assert (Editor.Buffers.Global_Count = Before_Count,
        "opening the same file through a relative alias must not duplicate buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = First_Id,
        "opening an already-open path alias should focus the existing buffer");
      Assert (Buffer_Text (S) = "disk-one!",
        "focusing an already-open file must not reread disk or lose dirty content");
      Assert (S.File_Info.Dirty,
        "focusing an already-open dirty file should preserve dirty state");
      Remove_If_Exists (Path);
   end Test_Open_Already_Open_Path_Alias_Focuses_Existing;

   procedure Test_Open_Read_Failures_Create_No_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Invalid_Path : constant String := Temp_Path ("invalid_utf8.txt");
      Missing_Path : constant String := Temp_Path ("missing.txt");
      Dir_Path     : constant String := Temp_Path ("dir");
      Before_Count : Natural;
      Before_Id    : Editor.Buffers.Buffer_Id;
   begin
      Remove_If_Exists (Invalid_Path);
      Remove_If_Exists (Missing_Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Invalid_Path, String'(1 => Character'Val (16#C0#)));
      Ada.Directories.Create_Directory (Dir_Path);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "active");
      S.File_Info.Display_Name := To_Unbounded_String ("active.txt");
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Missing_Path);
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Buffer_Text (S) = "active",
        "missing file open must not create a registry entry when none existed");

      Editor.Buffers.Ensure_Global_Registry (S);
      Before_Count := Editor.Buffers.Global_Count;
      Before_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Missing_Path);
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Active_Buffer = Before_Id
        and then Buffer_Text (S) = "active",
        "missing file open must preserve active buffer and create no partial buffer");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Dir_Path);
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Active_Buffer = Before_Id
        and then Buffer_Text (S) = "active",
        "directory path open must preserve active buffer and create no partial buffer");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Invalid_Path);
      Assert (Editor.Buffers.Global_Count = Before_Count
        and then Editor.Buffers.Global_Active_Buffer = Before_Id
        and then Buffer_Text (S) = "active",
        "decode/read failure must preserve active buffer and create no partial buffer");

      Remove_If_Exists (Invalid_Path);
      Remove_If_Exists (Dir_Path);
   end Test_Open_Read_Failures_Create_No_Buffer;


   procedure Test_File_Lifecycle_Command_Reference_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Covered : constant array (Positive range 1 .. 10) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Reopen_Closed_Buffer,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Rename_Buffer_File,
         Editor.Commands.Command_Delete_Buffer_File,
         Editor.Commands.Command_Copy_Buffer_File,
         Editor.Commands.Command_Move_Buffer_File);
      Desc  : Editor.Commands.Command_Descriptor;
      Id    : Editor.Commands.Command_Id;
      Found : Boolean := False;
      Seen  : array (Editor.Commands.Command_Effect_Classification_Id) of Boolean :=
        (others => False);

      procedure Assert_Contains
        (Haystack : String;
         Needle   : String;
         Context  : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Haystack, Needle) > 0,
           "command-reference text missing '" & Needle & "' for " & Context);
      end Assert_Contains;

      procedure Assert_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command,
           "absent/non-goal command must not gain reference surface: " & Name);
      end Assert_Absent;
   begin
      Assert (Editor.Commands.File_Lifecycle_Command_Reference_Coherent,
        "file lifecycle command reference helper must be coherent");

      for Expected of Covered loop
         Desc := Editor.Commands.Descriptor (Expected);
         Assert (Desc.Id = Expected
           and then Desc.Category = Editor.Commands.File_Category
           and then Desc.Family = Editor.Commands.File_Lifecycle_Family
           and then Desc.Effect_Classification =
             Editor.Commands.Command_Effect_Classification (Expected)
           and then Editor.Commands.Has_Command_Reference (Expected),
           "covered file lifecycle command missing descriptor-owned reference metadata");
         Assert (To_String (Desc.Summary) = Editor.Commands.Command_Summary (Expected)
           and then To_String (Desc.Availability_Summary) =
             Editor.Commands.Command_Availability_Summary (Expected)
           and then To_String (Desc.Mutation_Summary) =
             Editor.Commands.Command_Mutation_Summary (Expected)
           and then To_String (Desc.Filesystem_Effect_Summary) =
             Editor.Commands.Command_Filesystem_Effect_Summary (Expected)
           and then To_String (Desc.State_Preservation_Summary) =
             Editor.Commands.Command_State_Preservation_Summary (Expected)
           and then To_String (Desc.Non_Goal_Summary) =
             Editor.Commands.Command_Non_Goal_Summary (Expected),
           "descriptor fields must be derived from static command-reference constants");
         Assert (To_String (Desc.Summary)'Length > 0
           and then To_String (Desc.Availability_Summary)'Length > 0
           and then To_String (Desc.Mutation_Summary)'Length > 0
           and then To_String (Desc.Filesystem_Effect_Summary)'Length > 0
           and then To_String (Desc.State_Preservation_Summary)'Length > 0
           and then To_String (Desc.Non_Goal_Summary)'Length > 0,
           "all reference summaries must be present");
         Assert (Editor.Commands.Command_Family_Label (Desc.Family) = "File Operations"
           and then Editor.Commands.Command_Effect_Classification_Label
             (Desc.Effect_Classification)'Length > 0,
           "family/effect labels must be stable and discoverable");
         Assert (not Seen (Desc.Effect_Classification),
           "file lifecycle effect classifications must distinguish command semantics");
         Seen (Desc.Effect_Classification) := True;
      end loop;

      Assert_Contains (Editor.Commands.Command_Filesystem_Effect_Summary
        (Editor.Commands.Command_Save_File), "Writes", "file.save");
      Assert_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Save_File_As), "association", "file.save-as");
      Assert_Contains (Editor.Commands.Command_Filesystem_Effect_Summary
        (Editor.Commands.Command_Close_Active_Buffer), "no filesystem", "file.close-buffer");
      Assert_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Reopen_Closed_Buffer), "reopen candidate", "file.reopen-closed-buffer");
      Assert_Contains (Editor.Commands.Command_Non_Goal_Summary
        (Editor.Commands.Command_Reload_Active_Buffer), "dirty text", "file.reload-buffer");
      Assert_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Revert_Active_Buffer), "dirty", "file.revert-buffer");
      Assert_Contains (Editor.Commands.Command_Non_Goal_Summary
        (Editor.Commands.Command_Rename_Buffer_File), "overwrite", "file.rename-buffer-file");
      Assert_Contains (Editor.Commands.Command_State_Preservation_Summary
        (Editor.Commands.Command_Delete_Buffer_File), "Preserves active text", "file.delete-buffer-file");
      Assert_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Copy_Buffer_File), "Does not mutate", "file.copy-buffer-file");
      Assert_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Move_Buffer_File), "association", "file.move-buffer-file");

      Assert_Absent ("file.force-save");
      Assert_Absent ("file.force-close-buffer");
      Assert_Absent ("file.force-reload-buffer");
      Assert_Absent ("file.force-revert-buffer");
      Assert_Absent ("file.rename-buffer-file-overwrite");
      Assert_Absent ("file.delete-dirty-buffer");
      Assert_Absent ("file.force-delete-buffer-file");
      Assert_Absent ("file.copy-buffer-file-overwrite");
      Assert_Absent ("file.force-copy-buffer-file");
      Assert_Absent ("file.move-buffer-file-overwrite");
      Assert_Absent ("file.force-move-buffer-file");
      Assert_Absent ("file.open-copied-buffer-file");
      Assert_Absent ("file.open-moved-buffer-file");
      Assert_Absent ("file.copy-and-delete-buffer-file");
      Assert_Absent ("file.duplicate-buffer");
      Assert_Absent ("project.rename-files");
      Assert_Absent ("project.delete-files");
      Assert_Absent ("project.copy-files");
      Assert_Absent ("project.move-files");
      Assert_Absent ("workspace.rename-buffer-file");
      Assert_Absent ("workspace.delete-buffer-file");
      Assert_Absent ("workspace.copy-buffer-file");
      Assert_Absent ("workspace.move-buffer-file");
   end Test_File_Lifecycle_Command_Reference_Metadata;


   procedure Test_Command_Reference_Projection_And_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Summary       : Unbounded_String;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Before_Text   : constant String := "";
      Visible_Count : Natural := 0;
      Save_As_Rows  : Natural := 0;
      Rename_Rows   : Natural := 0;
      Delete_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;

      procedure Count_Row (C : Editor.Commands.Command_Palette_Candidate) is
      begin
         if Editor.Commands.Is_File_Lifecycle_Command (C.Id) then
            Visible_Count := Visible_Count + 1;
            Assert (C.Reference_Summary = Editor.Commands.Descriptor (C.Id).Summary
              and then C.Family = Editor.Commands.File_Lifecycle_Family
              and then C.Effect_Classification =
                Editor.Commands.Command_Effect_Classification (C.Id),
              "Command Palette reference projection must be descriptor-derived");
         end if;

         case C.Id is
            when Editor.Commands.Command_Save_File_As => Save_As_Rows := Save_As_Rows + 1;
            when Editor.Commands.Command_Rename_Buffer_File => Rename_Rows := Rename_Rows + 1;
            when Editor.Commands.Command_Delete_Buffer_File => Delete_Rows := Delete_Rows + 1;
            when Editor.Commands.Command_Copy_Buffer_File => Copy_Rows := Copy_Rows + 1;
            when Editor.Commands.Command_Move_Buffer_File => Move_Rows := Move_Rows + 1;
            when others => null;
         end case;
      end Count_Row;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "command-reference projection leaked persistence state containing '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Count_Row (Candidates (I));
         end loop;
      end if;

      Assert (Visible_Count >= 9,
        "palette-visible file lifecycle commands must project reference metadata");
      Assert (Save_As_Rows = 1,
        "explicit-target Save As is present once now that target prompt acquisition is canonical");
      Assert (Rename_Rows = 1 and then Delete_Rows = 1
        and then Copy_Rows = 1 and then Move_Rows = 1,
        "canonical associated-file operation rows remain unique");
      Assert (Buffer_Text (S) = Before_Text
        and then not S.File_Info.Has_Path
        and then not S.File_Info.Dirty
        and then Editor.Messages.Count (S.Messages) = 0,
        "reference projection must not execute commands or mutate editor state");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert_Summary_Excludes ("command reference");
      Assert_Summary_Excludes ("reference summary");
      Assert_Summary_Excludes ("availability summary");
      Assert_Summary_Excludes ("filesystem effect");
      Assert_Summary_Excludes ("effect classification");
      Assert_Summary_Excludes ("File Lifecycle");
      Assert_Summary_Excludes ("last viewed command");
      Assert_Summary_Excludes ("operation history");
      Assert_Summary_Excludes ("target history");
   end Test_Command_Reference_Projection_And_Boundaries;



   procedure Test_File_Lifecycle_Command_Reference_Accuracy_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Assert_Contains
        (Haystack : String;
         Needle   : String;
         Context  : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Haystack, Needle) > 0,
           "expected reference text '" & Needle & "' for " & Context);
      end Assert_Contains;

      procedure Assert_Not_Contains
        (Haystack : String;
         Needle   : String;
         Context  : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Haystack, Needle) = 0,
           "forbidden reference text '" & Needle & "' for " & Context);
      end Assert_Not_Contains;

      procedure Assert_Field
        (Id      : Editor.Commands.Command_Id;
         Field   : String;
         Needle  : String;
         Context : String) is
      begin
         if Field = "summary" then
            Assert_Contains (Editor.Commands.Command_Summary (Id), Needle, Context);
         elsif Field = "availability" then
            Assert_Contains (Editor.Commands.Command_Availability_Summary (Id), Needle, Context);
         elsif Field = "mutation" then
            Assert_Contains (Editor.Commands.Command_Mutation_Summary (Id), Needle, Context);
         elsif Field = "filesystem" then
            Assert_Contains (Editor.Commands.Command_Filesystem_Effect_Summary (Id), Needle, Context);
         elsif Field = "state" then
            Assert_Contains (Editor.Commands.Command_State_Preservation_Summary (Id), Needle, Context);
         elsif Field = "non-goal" then
            Assert_Contains (Editor.Commands.Command_Non_Goal_Summary (Id), Needle, Context);
         else
            Assert (False, "unknown reference field fixture");
         end if;
      end Assert_Field;
   begin
      Assert_Field (Editor.Commands.Command_Save_File, "summary", "associated file path", "file.save");
      Assert_Field (Editor.Commands.Command_Save_File, "mutation", "save baseline", "file.save");
      Assert_Field (Editor.Commands.Command_Save_File, "mutation", "dirty state", "file.save");
      Assert_Field (Editor.Commands.Command_Save_File, "filesystem", "Writes active buffer text", "file.save");
      Assert_Field (Editor.Commands.Command_Save_File, "non-goal", "new target path", "file.save");

      Assert_Field (Editor.Commands.Command_Save_File_As, "summary", "explicit target path", "file.save-as");
      Assert_Field (Editor.Commands.Command_Save_File_As, "mutation", "association", "file.save-as");
      Assert_Field (Editor.Commands.Command_Save_File_As, "filesystem", "explicit target path", "file.save-as");
      Assert_Field (Editor.Commands.Command_Save_File_As, "non-goal", "rename or move", "file.save-as");

      Assert_Field (Editor.Commands.Command_Close_Active_Buffer, "summary", "safe", "file.close-buffer");
      Assert_Field (Editor.Commands.Command_Close_Active_Buffer, "mutation", "open-buffer set", "file.close-buffer");
      Assert_Field (Editor.Commands.Command_Close_Active_Buffer, "filesystem", "no filesystem operation", "file.close-buffer");
      Assert_Field (Editor.Commands.Command_Close_Active_Buffer, "non-goal", "delete the associated file", "file.close-buffer");

      Assert_Field (Editor.Commands.Command_Reopen_Closed_Buffer, "summary", "canonical file-open behavior", "file.reopen-closed-buffer");
      Assert_Field (Editor.Commands.Command_Reopen_Closed_Buffer, "availability", "safe transient reopen candidate", "file.reopen-closed-buffer");
      Assert_Field (Editor.Commands.Command_Reopen_Closed_Buffer, "filesystem", "Reads the reopen candidate", "file.reopen-closed-buffer");
      Assert_Field (Editor.Commands.Command_Reopen_Closed_Buffer, "non-goal", "unsaved closed-buffer memory", "file.reopen-closed-buffer");

      Assert_Field (Editor.Commands.Command_Reload_Active_Buffer, "summary", "without discarding dirty text", "file.reload-buffer");
      Assert_Field (Editor.Commands.Command_Reload_Active_Buffer, "availability", "active clean associated buffer", "file.reload-buffer");
      Assert_Field (Editor.Commands.Command_Reload_Active_Buffer, "mutation", "active clean buffer text", "file.reload-buffer");
      Assert_Field (Editor.Commands.Command_Reload_Active_Buffer, "non-goal", "Does not discard dirty text", "file.reload-buffer");

      Assert_Field (Editor.Commands.Command_Revert_Active_Buffer, "summary", "Explicitly discards unsaved changes", "file.revert-buffer");
      Assert_Field (Editor.Commands.Command_Revert_Active_Buffer, "mutation", "clears dirty state", "file.revert-buffer");
      Assert_Field (Editor.Commands.Command_Revert_Active_Buffer, "filesystem", "after explicit discard", "file.revert-buffer");
      Assert_Field (Editor.Commands.Command_Revert_Active_Buffer, "non-goal", "recovery snapshots", "file.revert-buffer");

      Assert_Field (Editor.Commands.Command_Rename_Buffer_File, "summary", "updates association after filesystem success", "file.rename-buffer-file");
      Assert_Field (Editor.Commands.Command_Rename_Buffer_File, "mutation", "preserves text", "file.rename-buffer-file");
      Assert_Field (Editor.Commands.Command_Rename_Buffer_File, "filesystem", "Renames", "file.rename-buffer-file");
      Assert_Field (Editor.Commands.Command_Rename_Buffer_File, "non-goal", "write buffer text", "file.rename-buffer-file");

      Assert_Field (Editor.Commands.Command_Delete_Buffer_File, "summary", "clears association", "file.delete-buffer-file");
      Assert_Field (Editor.Commands.Command_Delete_Buffer_File, "mutation", "leaves the buffer open", "file.delete-buffer-file");
      Assert_Field (Editor.Commands.Command_Delete_Buffer_File, "filesystem", "Deletes", "file.delete-buffer-file");
      Assert_Field (Editor.Commands.Command_Delete_Buffer_File, "non-goal", "close the buffer", "file.delete-buffer-file");

      Assert_Field (Editor.Commands.Command_Copy_Buffer_File, "summary", "without changing association", "file.copy-buffer-file");
      Assert_Field (Editor.Commands.Command_Copy_Buffer_File, "mutation", "Preserves active buffer association", "file.copy-buffer-file");
      Assert_Field (Editor.Commands.Command_Copy_Buffer_File, "filesystem", "Copies", "file.copy-buffer-file");
      Assert_Field (Editor.Commands.Command_Copy_Buffer_File, "non-goal", "open the copied file", "file.copy-buffer-file");

      Assert_Field (Editor.Commands.Command_Move_Buffer_File, "summary", "updates association after filesystem success", "file.move-buffer-file");
      Assert_Field (Editor.Commands.Command_Move_Buffer_File, "mutation", "preserves text", "file.move-buffer-file");
      Assert_Field (Editor.Commands.Command_Move_Buffer_File, "filesystem", "Moves", "file.move-buffer-file");
      Assert_Field (Editor.Commands.Command_Move_Buffer_File, "non-goal", "write buffer text", "file.move-buffer-file");

      Assert_Not_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Copy_Buffer_File), "updates association", "file.copy-buffer-file");
      Assert_Not_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Delete_Buffer_File), "closes", "file.delete-buffer-file");
      Assert_Not_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Rename_Buffer_File), "save baseline", "file.rename-buffer-file");
      Assert_Not_Contains (Editor.Commands.Command_Mutation_Summary
        (Editor.Commands.Command_Move_Buffer_File), "save baseline", "file.move-buffer-file");
   end Test_File_Lifecycle_Command_Reference_Accuracy_Matrix;


   procedure Test_Command_Reference_Surface_Does_Not_Expand
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Id    : Editor.Commands.Command_Id;
      Found : Boolean := False;

      procedure Assert_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command,
           "reference metadata must not expose absent command " & Name);
      end Assert_Absent;
   begin
      Assert_Absent ("file.force-save");
      Assert_Absent ("file.force-save-as");
      Assert_Absent ("file.force-close-buffer");
      Assert_Absent ("file.force-reload-buffer");
      Assert_Absent ("file.force-revert-buffer");
      Assert_Absent ("file.rename-buffer-file-overwrite");
      Assert_Absent ("file.delete-dirty-buffer");
      Assert_Absent ("file.force-delete-buffer-file");
      Assert_Absent ("file.copy-buffer-file-overwrite");
      Assert_Absent ("file.force-copy-buffer-file");
      Assert_Absent ("file.move-buffer-file-overwrite");
      Assert_Absent ("file.force-move-buffer-file");
      Assert_Absent ("file.open-renamed-buffer-file");
      Assert_Absent ("file.open-copied-buffer-file");
      Assert_Absent ("file.open-moved-buffer-file");
      Assert_Absent ("file.copy-and-delete-buffer-file");
      Assert_Absent ("file.duplicate-buffer");
      Assert_Absent ("project.rename-files");
      Assert_Absent ("project.delete-files");
      Assert_Absent ("project.copy-files");
      Assert_Absent ("project.move-files");
      Assert_Absent ("workspace.rename-buffer-file");
      Assert_Absent ("workspace.delete-buffer-file");
      Assert_Absent ("workspace.copy-buffer-file");
      Assert_Absent ("workspace.move-buffer-file");
   end Test_Command_Reference_Surface_Does_Not_Expand;


   procedure Test_Availability_Reference_Separation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("availability_reference.txt");
      Before_Text   : constant String := "dirty reference separation";
      Static_Text    : constant String := Editor.Commands.Command_Availability_Summary
        (Editor.Commands.Command_Reload_Active_Buffer);
      No_Active      : Editor.Commands.Command_Availability;
      Dirty_Avail    : Editor.Commands.Command_Availability;
      Clean_Avail    : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk reference separation");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      No_Active := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Editor.Commands.Command_Availability_Summary
        (Editor.Commands.Command_Reload_Active_Buffer) = Static_Text,
        "static reference availability must not change in no-active state");

      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("availability_reference.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Dirty_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Dirty_Avail),
        "Executor must remain authoritative for dirty reload availability");
      Assert (Editor.Commands.Command_Availability_Summary
        (Editor.Commands.Command_Reload_Active_Buffer) = Static_Text,
        "reference availability text must remain stable for dirty associated buffer");
      Assert (Read_Bytes (Path) = "disk reference separation"
        and then Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty,
        "reference/availability checks must not read into state, write disk, or clean dirty text");

      S.File_Info.Dirty := False;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Clean_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Editor.Commands.Is_Available (Clean_Avail),
        "clean associated buffer availability remains Executor-derived");
      Assert (Editor.Commands.Command_Availability_Summary
        (Editor.Commands.Command_Reload_Active_Buffer) = Static_Text,
        "static reference availability must not follow Executor status");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "availability/reference checks must not emit command messages");
      Assert (Editor.Commands.Unavailable_Reason (No_Active)'Length >= 0,
        "no-active availability object is observed only to keep Executor path live");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Availability_Reference_Separation;


   procedure Test_Command_Palette_Reference_Projection_Consistency
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Candidates      : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Covered_Count   : Natural := 0;
      Save_Rows       : Natural := 0;
      Move_Rows       : Natural := 0;
      Before_Bound_Count : Natural := 0;

      procedure Inspect (C : Editor.Commands.Command_Palette_Candidate) is
      begin
         if Editor.Commands.Is_File_Lifecycle_Command (C.Id) then
            Covered_Count := Covered_Count + 1;
            Assert (C.Reference_Summary = Editor.Commands.Descriptor (C.Id).Summary
              and then C.Family = Editor.Commands.File_Lifecycle_Family
              and then C.Effect_Classification =
                Editor.Commands.Command_Effect_Classification (C.Id),
              "palette reference projection must remain descriptor-derived");
            Assert (C.Available = Editor.Commands.Is_Available
              (Editor.Executor.Command_Availability (S, C.Id)),
              "palette availability must remain Executor-derived");
         end if;

         if C.Id = Editor.Commands.Command_Save_File then
            Save_Rows := Save_Rows + 1;
         elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
            Move_Rows := Move_Rows + 1;
         end if;
      end Inspect;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Before_Bound_Count := Editor.Keybindings.Bound_Command_Count;
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("file");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Inspect (Candidates (I));
         end loop;
      end if;

      Assert (Covered_Count > 0,
        "file lifecycle query should project canonical command-reference rows");
      Assert (Save_Rows <= 1 and then Move_Rows <= 1,
        "canonical lifecycle commands must appear at most once in palette projection");
      Assert (Editor.Keybindings.Bound_Command_Count = Before_Bound_Count,
        "palette reference projection must not mutate active keybindings");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("overwrite force open moved copied renamed project workspace duplicate");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Assert (not Editor.Commands.Is_File_Lifecycle_Command (Candidates (I).Id)
              or else Editor.Commands.Has_Command_Reference (Candidates (I).Id),
              "removed-name query text must not create noncanonical reference rows");
         end loop;
      end if;
   end Test_Command_Palette_Reference_Projection_Consistency;

   procedure Test_Command_Reference_Canonical_Metadata_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Covered : constant array (Positive range 1 .. 10) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Reopen_Closed_Buffer,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Rename_Buffer_File,
         Editor.Commands.Command_Delete_Buffer_File,
         Editor.Commands.Command_Copy_Buffer_File,
         Editor.Commands.Command_Move_Buffer_File);
      Desc : Editor.Commands.Command_Descriptor;
      Non_Canonical : constant array (Positive range 1 .. 4) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Open_File,
         Editor.Commands.Command_Open_Project,
         Editor.Commands.Command_Save_Settings,
         Editor.Commands.Command_Open_Command_Palette);
   begin
      Assert (Editor.Commands.File_Lifecycle_Command_Reference_Coherent,
        "canonical descriptor-owned reference metadata must remain coherent");

      for Id of Covered loop
         Desc := Editor.Commands.Descriptor (Id);
         Assert (To_String (Desc.Summary) = Editor.Commands.Reference_Summary (Id)
           and then To_String (Desc.Availability_Summary) =
             Editor.Commands.Reference_Availability_Summary (Id)
           and then To_String (Desc.Mutation_Summary) =
             Editor.Commands.Reference_Mutation_Summary (Id)
           and then To_String (Desc.Filesystem_Effect_Summary) =
             Editor.Commands.Reference_Filesystem_Effect_Summary (Id)
           and then To_String (Desc.State_Preservation_Summary) =
             Editor.Commands.Reference_State_Preservation_Summary (Id)
           and then To_String (Desc.Non_Goal_Summary) =
             Editor.Commands.Reference_Non_Goal_Summary (Id)
           and then Desc.Family = Editor.Commands.Reference_Command_Family (Id)
           and then Desc.Effect_Classification =
             Editor.Commands.Reference_Effect_Classification (Id),
           "descriptor fields must project the canonical reference accessor for one owner");
         Assert (Editor.Commands.Command_Summary (Id) = Editor.Commands.Reference_Summary (Id)
           and then Editor.Commands.Command_Availability_Summary (Id) =
             Editor.Commands.Reference_Availability_Summary (Id)
           and then Editor.Commands.Command_Mutation_Summary (Id) =
             Editor.Commands.Reference_Mutation_Summary (Id)
           and then Editor.Commands.Command_Filesystem_Effect_Summary (Id) =
             Editor.Commands.Reference_Filesystem_Effect_Summary (Id)
           and then Editor.Commands.Command_State_Preservation_Summary (Id) =
             Editor.Commands.Reference_State_Preservation_Summary (Id)
           and then Editor.Commands.Command_Non_Goal_Summary (Id) =
             Editor.Commands.Reference_Non_Goal_Summary (Id)
           and then Editor.Commands.Command_Family (Id) =
             Editor.Commands.Reference_Command_Family (Id)
           and then Editor.Commands.Command_Effect_Classification (Id) =
             Editor.Commands.Reference_Effect_Classification (Id),
           "compatibility accessors must not become a duplicate metadata source");
      end loop;

      for Id of Non_Canonical loop
         Assert (not Editor.Commands.Has_Command_Reference (Id)
           and then Editor.Commands.Reference_Summary (Id) = ""
           and then Editor.Commands.Reference_Command_Family (Id) =
             Editor.Commands.No_Command_Family
           and then Editor.Commands.Reference_Effect_Classification (Id) =
             Editor.Commands.No_Command_Effect,
           "noncovered commands must not infer file lifecycle reference metadata");
      end loop;
   end Test_Command_Reference_Canonical_Metadata_Source;


   procedure Test_Command_Palette_Has_No_Reference_Fallbacks_Or_Caches
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Candidates     : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Seen_Save      : Natural := 0;
      Seen_Save_As   : Natural := 0;
      Seen_Rename    : Natural := 0;
      Seen_Delete    : Natural := 0;
      Seen_Copy      : Natural := 0;
      Seen_Move      : Natural := 0;
      Before_Bindings : Natural := 0;

      procedure Count (Id : Editor.Commands.Command_Id) is
      begin
         case Id is
            when Editor.Commands.Command_Save_File =>
               Seen_Save := Seen_Save + 1;
            when Editor.Commands.Command_Save_File_As =>
               Seen_Save_As := Seen_Save_As + 1;
            when Editor.Commands.Command_Rename_Buffer_File =>
               Seen_Rename := Seen_Rename + 1;
            when Editor.Commands.Command_Delete_Buffer_File =>
               Seen_Delete := Seen_Delete + 1;
            when Editor.Commands.Command_Copy_Buffer_File =>
               Seen_Copy := Seen_Copy + 1;
            when Editor.Commands.Command_Move_Buffer_File =>
               Seen_Move := Seen_Move + 1;
            when others =>
               null;
         end case;
      end Count;
   begin
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Before_Bindings := Editor.Keybindings.Bound_Command_Count;

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("file save rename delete copy move overwrite force open-target duplicate project workspace");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Count (Candidates (I).Id);
            if Editor.Commands.Is_File_Lifecycle_Command (Candidates (I).Id) then
               Assert (Candidates (I).Reference_Summary =
                 Editor.Commands.Descriptor (Candidates (I).Id).Summary
                 and then Candidates (I).Family =
                   Editor.Commands.Descriptor (Candidates (I).Id).Family
                 and then Candidates (I).Effect_Classification =
                   Editor.Commands.Descriptor (Candidates (I).Id).Effect_Classification,
                 "palette rows must be descriptor-derived without local fallback metadata");
            else
               Assert (not Editor.Commands.Has_Command_Reference (Candidates (I).Id),
                 "palette must not synthesize reference rows for noncovered commands");
            end if;
         end loop;
      end if;

      Assert (Seen_Save <= 1 and then Seen_Save_As <= 1
        and then Seen_Rename <= 1 and then Seen_Delete <= 1
        and then Seen_Copy <= 1 and then Seen_Move <= 1,
        "palette must not duplicate descriptor rows through reference fallback/cache paths");
      Assert (Editor.Keybindings.Bound_Command_Count = Before_Bindings,
        "reference projection must not repair or mutate keybindings");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("file.move-buffer-file-overwrite file.open-moved-buffer-file file.duplicate-buffer project.move-files");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Assert (Editor.Commands.Command_Effect_Classification (Candidates (I).Id) =
              Editor.Commands.Reference_Effect_Classification (Candidates (I).Id),
              "query text must not infer command-reference effect classifications");
         end loop;
      end if;
   end Test_Command_Palette_Has_No_Reference_Fallbacks_Or_Caches;


   procedure Test_Reference_Metadata_Persistence_And_Audit_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;

      procedure Assert_Excluded (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "reference projection state must not persist field: " & Needle);
      end Assert_Excluded;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("File Lifecycle writes-buffer-text-to-associated-file command reference");
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert_Excluded ("File Lifecycle");
      Assert_Excluded ("command reference");
      Assert_Excluded ("reference summary");
      Assert_Excluded ("availability summary");
      Assert_Excluded ("mutation summary");
      Assert_Excluded ("filesystem effect");
      Assert_Excluded ("state preservation");
      Assert_Excluded ("non-goal");
      Assert_Excluded ("effect classification");
      Assert_Excluded ("writes-buffer-text-to-associated-file");
      Assert_Excluded ("expanded command");
      Assert_Excluded ("collapsed command");
      Assert_Excluded ("last viewed command");
      Assert (Editor.Commands.File_Lifecycle_Command_Reference_Coherent,
        "audit-facing coherence check must be metadata-only and transient");
   end Test_Reference_Metadata_Persistence_And_Audit_Boundary;


   procedure Test_File_Lifecycle_Command_Reference_Final_Surface_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      Covered : constant array (Positive range 1 .. 10) of Editor.Commands.Command_Id :=
        (Editor.Commands.Command_Save_File,
         Editor.Commands.Command_Save_File_As,
         Editor.Commands.Command_Close_Active_Buffer,
         Editor.Commands.Command_Reopen_Closed_Buffer,
         Editor.Commands.Command_Reload_Active_Buffer,
         Editor.Commands.Command_Revert_Active_Buffer,
         Editor.Commands.Command_Rename_Buffer_File,
         Editor.Commands.Command_Delete_Buffer_File,
         Editor.Commands.Command_Copy_Buffer_File,
         Editor.Commands.Command_Move_Buffer_File);

      Expected_Names : constant array (Positive range 1 .. 10) of Unbounded_String :=
        (To_Unbounded_String ("file.save"),
         To_Unbounded_String ("file.save-as"),
         To_Unbounded_String ("file.close-buffer"),
         To_Unbounded_String ("file.reopen-closed-buffer"),
         To_Unbounded_String ("file.reload-buffer"),
         To_Unbounded_String ("file.revert-buffer"),
         To_Unbounded_String ("file.rename-buffer-file"),
         To_Unbounded_String ("file.delete-buffer-file"),
         To_Unbounded_String ("file.copy-buffer-file"),
         To_Unbounded_String ("file.move-buffer-file"));

      Expected_Effects : constant array (Positive range 1 .. 10) of Editor.Commands.Command_Effect_Classification_Id :=
        (Editor.Commands.Writes_Buffer_Text_To_Associated_File,
         Editor.Commands.Writes_Buffer_Text_To_Explicit_Target_And_Associates,
         Editor.Commands.Closes_Active_Buffer,
         Editor.Commands.Reopens_Safe_File_Reference,
         Editor.Commands.Rereads_Associated_File,
         Editor.Commands.Discards_Unsaved_Changes_And_Rereads,
         Editor.Commands.Renames_Associated_File,
         Editor.Commands.Deletes_Associated_File,
         Editor.Commands.Copies_Associated_File,
         Editor.Commands.Moves_Associated_File);

      Expected_Effect_Labels : constant array (Positive range 1 .. 10) of Unbounded_String :=
        (To_Unbounded_String ("writes-buffer-text-to-associated-file"),
         To_Unbounded_String ("writes-buffer-text-to-explicit-target-and-associates"),
         To_Unbounded_String ("closes-active-buffer"),
         To_Unbounded_String ("reopens-safe-file-reference"),
         To_Unbounded_String ("rereads-associated-file"),
         To_Unbounded_String ("discards-unsaved-changes-and-rereads"),
         To_Unbounded_String ("renames-associated-file"),
         To_Unbounded_String ("deletes-associated-file"),
         To_Unbounded_String ("copies-associated-file"),
         To_Unbounded_String ("moves-associated-file"));

      Frozen_Absent : constant array (Positive range 1 .. 25) of Unbounded_String :=
        (To_Unbounded_String ("file.force-save"),
         To_Unbounded_String ("file.force-save-as"),
         To_Unbounded_String ("file.force-close-buffer"),
         To_Unbounded_String ("file.force-reload-buffer"),
         To_Unbounded_String ("file.force-revert-buffer"),
         To_Unbounded_String ("file.rename-buffer-file-overwrite"),
         To_Unbounded_String ("file.delete-dirty-buffer"),
         To_Unbounded_String ("file.force-delete-buffer-file"),
         To_Unbounded_String ("file.copy-buffer-file-overwrite"),
         To_Unbounded_String ("file.force-copy-buffer-file"),
         To_Unbounded_String ("file.move-buffer-file-overwrite"),
         To_Unbounded_String ("file.force-move-buffer-file"),
         To_Unbounded_String ("file.open-renamed-buffer-file"),
         To_Unbounded_String ("file.open-copied-buffer-file"),
         To_Unbounded_String ("file.open-moved-buffer-file"),
         To_Unbounded_String ("file.copy-and-delete-buffer-file"),
         To_Unbounded_String ("file.duplicate-buffer"),
         To_Unbounded_String ("project.rename-files"),
         To_Unbounded_String ("project.delete-files"),
         To_Unbounded_String ("project.copy-files"),
         To_Unbounded_String ("project.move-files"),
         To_Unbounded_String ("workspace.rename-buffer-file"),
         To_Unbounded_String ("workspace.delete-buffer-file"),
         To_Unbounded_String ("workspace.copy-buffer-file"),
         To_Unbounded_String ("workspace.move-buffer-file"));

      Found_Id : Editor.Commands.Command_Id;
      Found    : Boolean;
      Count    : Natural := 0;

      procedure Assert_Field_Contains
        (Field   : String;
         Needle  : String;
         Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Field, Needle) > 0,
           "frozen reference field for " & Context &
           " must contain '" & Needle & "'");
      end Assert_Field_Contains;

      procedure Assert_Field_Not_Contains
        (Field   : String;
         Needle  : String;
         Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Field, Needle) = 0,
           "frozen reference field for " & Context &
           " must not contain '" & Needle & "'");
      end Assert_Field_Not_Contains;
   begin
      Assert (Editor.Commands.File_Lifecycle_Command_Reference_Coherent,
        "canonical command-reference coherence helper must pass before final freeze checks");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Has_Command_Reference (Id) then
            Count := Count + 1;
            Assert (Editor.Commands.Is_File_Lifecycle_Command (Id),
              "command-reference metadata must remain limited to file lifecycle commands");
         end if;
      end loop;
      Assert (Count = Covered'Length,
        "frozen command-reference surface must contain exactly the canonical ten commands");

      for I in Covered'Range loop
         declare
            Id   : constant Editor.Commands.Command_Id := Covered (I);
            Desc : constant Editor.Commands.Command_Descriptor := Editor.Commands.Descriptor (Id);
            Name : constant String := To_String (Expected_Names (I));
         begin
            Found_Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
            Assert (Found and then Found_Id = Id,
              "frozen stable command name must resolve to canonical descriptor: " & Name);
            Assert (Desc.Id = Id
              and then Editor.Commands.Has_Descriptor (Id)
              and then Editor.Commands.Stable_Command_Name (Id) = Name
              and then Desc.Category = Editor.Commands.File_Category
              and then Desc.Visibility = Editor.Commands.Palette_Command,
              "descriptor identity/category/visibility drifted for " & Name);
            Assert (Desc.Family = Editor.Commands.File_Lifecycle_Family
              and then Editor.Commands.Command_Family (Id) = Editor.Commands.File_Lifecycle_Family
              and then Editor.Commands.Command_Family_Label (Desc.Family) = "File Operations",
              "File Lifecycle family freeze drifted for " & Name);
            Assert (Desc.Effect_Classification = Expected_Effects (I)
              and then Editor.Commands.Command_Effect_Classification (Id) = Expected_Effects (I)
              and then Editor.Commands.Command_Effect_Classification_Label (Expected_Effects (I)) = To_String (Expected_Effect_Labels (I)),
              "effect-classification freeze drifted for " & Name);
            Assert (To_String (Desc.Summary) = Editor.Commands.Reference_Summary (Id)
              and then To_String (Desc.Availability_Summary) = Editor.Commands.Reference_Availability_Summary (Id)
              and then To_String (Desc.Mutation_Summary) = Editor.Commands.Reference_Mutation_Summary (Id)
              and then To_String (Desc.Filesystem_Effect_Summary) = Editor.Commands.Reference_Filesystem_Effect_Summary (Id)
              and then To_String (Desc.State_Preservation_Summary) = Editor.Commands.Reference_State_Preservation_Summary (Id)
              and then To_String (Desc.Non_Goal_Summary) = Editor.Commands.Reference_Non_Goal_Summary (Id)
              and then Desc.Family = Editor.Commands.Reference_Command_Family (Id)
              and then Desc.Effect_Classification = Editor.Commands.Reference_Effect_Classification (Id),
              "descriptor-owned metadata accessors drifted for " & Name);
            Assert (Editor.Commands.Command_Summary (Id) = Editor.Commands.Reference_Summary (Id)
              and then Editor.Commands.Command_Availability_Summary (Id) = Editor.Commands.Reference_Availability_Summary (Id)
              and then Editor.Commands.Command_Mutation_Summary (Id) = Editor.Commands.Reference_Mutation_Summary (Id)
              and then Editor.Commands.Command_Filesystem_Effect_Summary (Id) = Editor.Commands.Reference_Filesystem_Effect_Summary (Id)
              and then Editor.Commands.Command_State_Preservation_Summary (Id) = Editor.Commands.Reference_State_Preservation_Summary (Id)
              and then Editor.Commands.Command_Non_Goal_Summary (Id) = Editor.Commands.Reference_Non_Goal_Summary (Id),
              "public command-reference aliases must remain canonical for " & Name);
         end;
      end loop;

      Assert_Field_Contains (Editor.Commands.Command_Summary (Editor.Commands.Command_Save_File), "associated file path", "file.save summary");
      Assert_Field_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Save_File), "new target path", "file.save non-goal");
      Assert_Field_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Save_File_As), "association", "file.save-as mutation");
      Assert_Field_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Save_File_As), "rename or move", "file.save-as non-goal");
      Assert_Field_Contains (Editor.Commands.Command_Filesystem_Effect_Summary (Editor.Commands.Command_Close_Active_Buffer), "no filesystem operation", "file.close-buffer filesystem");
      Assert_Field_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Close_Active_Buffer), "delete the associated file", "file.close-buffer non-goal");
      Assert_Field_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Reopen_Closed_Buffer), "unsaved closed-buffer memory", "file.reopen-closed-buffer non-goal");
      Assert_Field_Contains (Editor.Commands.Command_Summary (Editor.Commands.Command_Reload_Active_Buffer), "without discarding dirty text", "file.reload-buffer summary");
      Assert_Field_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Revert_Active_Buffer), "recovery snapshots", "file.revert-buffer non-goal");
      Assert_Field_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Rename_Buffer_File), "after filesystem rename success", "file.rename-buffer-file mutation");
      Assert_Field_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Delete_Buffer_File), "Clears active buffer association", "file.delete-buffer-file mutation");
      Assert_Field_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Copy_Buffer_File), "Does not mutate association", "file.copy-buffer-file mutation");
      Assert_Field_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Move_Buffer_File), "after filesystem move success", "file.move-buffer-file mutation");
      Assert_Field_Not_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Copy_Buffer_File), "Updates active buffer association", "file.copy-buffer-file mutation");
      Assert_Field_Not_Contains (Editor.Commands.Command_Mutation_Summary (Editor.Commands.Command_Delete_Buffer_File), "Removes the active buffer", "file.delete-buffer-file mutation");
      Assert_Field_Not_Contains (Editor.Commands.Command_Non_Goal_Summary (Editor.Commands.Command_Rename_Buffer_File), "available", "file.rename-buffer-file non-goal");

      for Name of Frozen_Absent loop
         Found_Id := Editor.Commands.Command_Id_From_Stable_Name (To_String (Name), Found);
         Assert (not Found and then Found_Id = Editor.Commands.No_Command,
           "absent removed/force/overwrite/open-target/project command must remain absent: " & To_String (Name));
      end loop;
   end Test_File_Lifecycle_Command_Reference_Final_Surface_Freeze;


   procedure Test_Command_Reference_Projection_Availability_And_Render_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                  : Editor.State.State_Type;
      Candidates         : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Visible_Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
      Hidden_Snapshot    : Editor.Command_Palette.Command_Palette_Snapshot;
      Render_Before      : Editor.Render_Model.Render_Snapshot;
      Render_After       : Editor.Render_Model.Render_Snapshot;
      Config_Show        : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => True,
         Group_Empty_Query_By_Category => False,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings              => True,
         Show_Help_Row                 => False);
      Config_Hide        : constant Editor.Command_Palette.Command_Palette_Config :=
        (Max_Visible_Rows              => 12,
         Overlay_Width_In_Columns      => 72,
         Show_Unavailable_Commands     => True,
         Group_Empty_Query_By_Category => False,
         Show_Selected_Reason          => True,
         Show_Selected_Description     => True,
         Show_Keybindings              => False,
         Show_Help_Row                 => False);
      Before_Bindings    : Natural := 0;
      Before_Reference   : constant String := Editor.Commands.Command_Summary (Editor.Commands.Command_Move_Buffer_File);
      No_Active          : Editor.Commands.Command_Availability;
      Dirty_Avail        : Editor.Commands.Command_Availability;
      Clean_Avail        : Editor.Commands.Command_Availability;
      Path               : constant String := Temp_Path ("projection_availability.txt");
      Seen_Save          : Natural := 0;
      Seen_Move          : Natural := 0;
      Saw_Keybinding_On  : Boolean := False;
      Saw_Keybinding_Off : Boolean := False;
      Before_Audit       : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit        : Editor.Configuration_Audit.Configuration_State_Summary;
      Audit_Result       : Editor.Configuration_Audit.Configuration_Audit_Result;
      Route_Audit        : Editor.Command_Route_Audit.Route_Audit_Result;

      procedure Count_Row (Id : Editor.Commands.Command_Id) is
      begin
         if Id = Editor.Commands.Command_Save_File then
            Seen_Save := Seen_Save + 1;
         elsif Id = Editor.Commands.Command_Move_Buffer_File then
            Seen_Move := Seen_Move + 1;
         end if;
      end Count_Row;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "clean disk text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Keybindings.Reset_To_Defaults;
      Before_Bindings := Editor.Keybindings.Bound_Command_Count;

      No_Active := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (No_Active),
        "no-active availability remains Executor-derived");
      Assert (Editor.Commands.Command_Summary (Editor.Commands.Command_Move_Buffer_File) = Before_Reference,
        "reference metadata must be stable in no-active state");

      Editor.State.Load_Text (S, "dirty memory text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("projection_availability.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Dirty_Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Dirty_Avail),
        "dirty associated reload remains blocked by Executor availability");
      Assert (Read_Bytes (Path) = "clean disk text"
        and then Buffer_Text (S) = "dirty memory text"
        and then S.File_Info.Dirty,
        "reference projection/availability must not read disk into dirty text or clean state");

      S.File_Info.Dirty := False;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Clean_Avail := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Editor.Commands.Is_Available (Clean_Avail),
        "clean associated reload remains enabled only by Executor availability");
      Assert (Editor.Commands.Command_Summary (Editor.Commands.Command_Move_Buffer_File) = Before_Reference,
        "reference metadata must not follow Executor availability state");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("file.save");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      Editor.Command_Palette.Reconcile_Selection (Candidates, Editor.Commands.Command_Save_File);

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            Count_Row (Candidates (I).Id);
            Assert (Candidates (I).Reference_Summary = Editor.Commands.Descriptor (Candidates (I).Id).Summary,
              "Command Palette reference summary must be descriptor-derived");
            Assert (Candidates (I).Family = Editor.Commands.Descriptor (Candidates (I).Id).Family
              and then Candidates (I).Effect_Classification = Editor.Commands.Descriptor (Candidates (I).Id).Effect_Classification,
              "Command Palette family/effect projection must be descriptor-derived");
         end loop;
      end if;
      Assert (Seen_Save <= 1 and then Seen_Move <= 1,
        "Command Palette must not duplicate canonical lifecycle rows");

      Visible_Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config_Show);
      Hidden_Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config_Hide);
      for I in 1 .. Editor.Command_Palette.Row_Count (Visible_Snapshot) loop
         if Editor.Command_Palette.Row (Visible_Snapshot, I).Kind = Editor.Command_Palette.Command_Palette_Command_Row
           and then Editor.Command_Palette.Row (Visible_Snapshot, I).Has_Keybinding
         then
            Saw_Keybinding_On := True;
         end if;
      end loop;
      for I in 1 .. Editor.Command_Palette.Row_Count (Hidden_Snapshot) loop
         if Editor.Command_Palette.Row (Hidden_Snapshot, I).Kind = Editor.Command_Palette.Command_Palette_Command_Row
           and then not Editor.Command_Palette.Row (Hidden_Snapshot, I).Has_Keybinding
           and then Length (Editor.Command_Palette.Row (Hidden_Snapshot, I).Keybinding_Text) = 0
         then
            Saw_Keybinding_Off := True;
         end if;
      end loop;
      Assert (Saw_Keybinding_On and then Saw_Keybinding_Off,
        "keybinding display must remain active-binding/settings-controlled projection");

      Editor.Render_Model.Build_Render_Snapshot (S, Render_Before);
      Editor.Render_Model.Build_Render_Snapshot (S, Render_After);
      Assert (Render_Before.Length = Render_After.Length
        and then Render_Before.Is_Dirty = Render_After.Is_Dirty
        and then Render_Before.File_Name = Render_After.File_Name
        and then Editor.Commands.Command_Summary (Editor.Commands.Command_Move_Buffer_File) = Before_Reference,
        "render snapshots must be deterministic and must not own or repair reference metadata");

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit, Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit, Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Save_File);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Audit_Result, Before_Audit, After_Audit, "command-reference route/configuration audit");
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0
        and then Editor.Configuration_Audit.Status (Audit_Result) = Editor.Configuration_Audit.Configuration_Audit_Ok,
        "route/configuration audits must inspect without executing, repairing, or mutating state");
      Assert (Editor.Keybindings.Bound_Command_Count = Before_Bindings,
        "reference projection/render/audit must not mutate active keybindings");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "reference projection/render/audit must not emit command outcome messages");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Reference_Projection_Availability_And_Render_Freeze;


   procedure Test_Command_Reference_Persistence_Lifecycle_And_Behavior_Smoke_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Workspace  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary    : Unbounded_String;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Snap       : Editor.Render_Model.Render_Snapshot;
      Path       : constant String := Temp_Path ("behavior_save.txt");
      Save_As    : constant String := Temp_Path ("behavior_save_as.txt");
      Copy_To    : constant String := Temp_Path ("behavior_copy.txt");
      Move_To    : constant String := Temp_Path ("behavior_move.txt");
      Id         : Editor.Commands.Command_Id;
      Found      : Boolean;

      procedure Assert_Excluded (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence output must exclude command-reference projection state: " & Needle);
      end Assert_Excluded;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Remove_If_Exists (Copy_To);
      Remove_If_Exists (Move_To);
      Write_Bytes (Path, "original");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "memory");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("behavior_save.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("File Lifecycle command reference save copy move overwrite force");
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert_Excluded ("File Lifecycle");
      Assert_Excluded ("command reference");
      Assert_Excluded ("reference summary");
      Assert_Excluded ("availability summary");
      Assert_Excluded ("mutation summary");
      Assert_Excluded ("filesystem effect");
      Assert_Excluded ("state preservation");
      Assert_Excluded ("non-goal");
      Assert_Excluded ("effect classification");
      Assert_Excluded ("writes-buffer-text-to-associated-file");
      Assert_Excluded ("expanded command");
      Assert_Excluded ("collapsed command");
      Assert_Excluded ("reference display cache");
      Assert_Excluded ("reference audit cache");
      Assert (Buffer_Text (S) = "memory"
        and then Read_Bytes (Path) = "original"
        and then S.File_Info.Dirty,
        "palette/render/workspace reference projection must not execute save or filesystem operations");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = "memory"
        and then not S.File_Info.Dirty
        and then Buffer_Text (S) = "memory",
        "file.save behavior smoke must remain unchanged after reference freeze");

      Insert_Text_At (S, Buffer_Text (S)'Length, " as");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As);
      Assert (Ada.Directories.Exists (Save_As)
        and then Read_Bytes (Save_As) = "memory as"
        and then To_String (S.File_Info.Path) = Save_As
        and then not S.File_Info.Dirty,
        "file.save-as behavior smoke must remain unchanged after reference freeze");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_To);
      Assert (Ada.Directories.Exists (Copy_To)
        and then Read_Bytes (Copy_To) = "memory as"
        and then To_String (S.File_Info.Path) = Save_As,
        "file.copy-buffer-file smoke must preserve association and copy backing file");

      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_To);
      Assert (Ada.Directories.Exists (Move_To)
        and then not Ada.Directories.Exists (Save_As)
        and then To_String (S.File_Info.Path) = Move_To
        and then Buffer_Text (S) = "memory as"
        and then not S.File_Info.Dirty,
        "file.move-buffer-file smoke must update association after filesystem success without changing text");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.move-buffer-file-overwrite", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "behavior smoke must not expose overwrite command aliases");
      Assert (Editor.Commands.File_Lifecycle_Command_Reference_Coherent,
        "behavior smoke must leave static command-reference metadata coherent");

      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Remove_If_Exists (Copy_To);
      Remove_If_Exists (Move_To);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Save_As);
         Remove_If_Exists (Copy_To);
         Remove_If_Exists (Move_To);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Reference_Persistence_Lifecycle_And_Behavior_Smoke_Freeze;


procedure Test_File_Lifecycle_Cross_Command_Sequence_Milestone_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Initial        : constant String := Temp_Path ("initial.txt");
      Save_As_Path   : constant String := Temp_Path ("save_as.txt");
      Rename_Path    : constant String := Temp_Path ("rename.txt");
      Copy_Path      : constant String := Temp_Path ("copy.txt");
      Move_Path      : constant String := Temp_Path ("move.txt");
      Prompt_Save_As : constant String := Temp_Path ("prompt_save_as.txt");
      Prompt_Rename  : constant String := Temp_Path ("prompt_rename.txt");
      Prompt_Copy    : constant String := Temp_Path ("prompt_copy.txt");
      Prompt_Move    : constant String := Temp_Path ("prompt_move.txt");
      Direct_Copy    : constant String := Temp_Path ("direct_after_cancel_copy.txt");
      Start_Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Save_Text      : constant String := "text saved by save-as";
      Revert_Text    : constant String := "clean text before revert";
      Prompt_Text    : constant String := "prompted sequence text";

      procedure Cleanup is
      begin
         Remove_If_Exists (Initial);
         Remove_If_Exists (Save_As_Path);
         Remove_If_Exists (Rename_Path);
         Remove_If_Exists (Copy_Path);
         Remove_If_Exists (Move_Path);
         Remove_If_Exists (Prompt_Save_As);
         Remove_If_Exists (Prompt_Rename);
         Remove_If_Exists (Prompt_Copy);
         Remove_If_Exists (Prompt_Move);
         Remove_If_Exists (Direct_Copy);
      end Cleanup;

      procedure Expect_Clean_Association
        (Path : String;
         Text : String;
         Note : String) is
      begin
         Assert (To_String (S.File_Info.Path) = Path
           and then Buffer_Text (S) = Text
           and then not S.File_Info.Dirty
           and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
           and then Editor.Buffers.Global_Count >= 1,
           "clean association invariant failed after " & Note);
      end Expect_Clean_Association;

      procedure Prompt_And_Confirm
        (Id     : Editor.Commands.Command_Id;
         Target : String;
         Label  : String) is
      begin
         Editor.Messages.Clear (S.Messages);
         Editor.Executor.Execute_Command (S, Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
           and then S.File_Target_Prompt_Command = Id
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = Label
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "no-target invocation must open canonical prompt for " &
           Editor.Commands.Stable_Command_Name (Id));
         Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
         Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
         Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
           and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "prompt confirmation must clear transient state for " &
           Editor.Commands.Stable_Command_Name (Id));
      end Prompt_And_Confirm;
   begin
      Cleanup;
      Write_Bytes (Initial, Save_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Initial);
      Start_Id := Editor.Buffers.Global_Active_Buffer;
      Expect_Clean_Association (Initial, Save_Text, "open");

      Insert_Text_At (S, Buffer_Text (S)'Length + 1, " + edit");
      Assert (S.File_Info.Dirty, "edit must mark associated buffer dirty before save");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Expect_Clean_Association (Save_As_Path, Save_Text & " + edit", "direct save-as");
      Assert (Read_Bytes (Save_As_Path) = Save_Text & " + edit",
        "direct save-as must write exact buffer text");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Expect_Clean_Association (Save_As_Path, Save_Text & " + edit", "save after save-as");
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Closed_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Closed_Id /= Start_Id,
        "close must remove the active buffer from the open-buffer collection under retained policy");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Expect_Clean_Association (Save_As_Path, Save_Text & " + edit", "reopen");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Expect_Clean_Association (Save_As_Path, Save_Text & " + edit", "reload");

      Write_Bytes (Save_As_Path, Revert_Text);
      Insert_Text_At (S, Buffer_Text (S)'Length + 1, " dirty");
      Assert (S.File_Info.Dirty, "dirty state must exist before revert");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = Save_Text & " + edit" & " dirty"
        and then S.File_Info.Dirty,
        "reload must remain blocked for dirty associated buffers");
      Execute_Revert_And_Confirm (S);
      Expect_Clean_Association (Save_As_Path, Revert_Text, "revert");

      Insert_Text_At (S, Buffer_Text (S)'Length + 1, " dirty-blocked");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Path);
      Assert (To_String (S.File_Info.Path) = Save_As_Path
        and then not Ada.Directories.Exists (Rename_Path)
        and then S.File_Info.Dirty,
        "dirty rename must remain blocked and preserve association/text state");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Path);
      Assert (not Ada.Directories.Exists (Copy_Path)
        and then To_String (S.File_Info.Path) = Save_As_Path
        and then S.File_Info.Dirty,
        "dirty copy must remain blocked and preserve association/text state");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Path);
      Assert (not Ada.Directories.Exists (Move_Path)
        and then To_String (S.File_Info.Path) = Save_As_Path
        and then S.File_Info.Dirty,
        "dirty move must remain blocked and preserve association/text state");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (Ada.Directories.Exists (Save_As_Path)
        and then To_String (S.File_Info.Path) = Save_As_Path
        and then S.File_Info.Dirty,
        "dirty delete must remain blocked and preserve association/text state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Expect_Clean_Association (Save_As_Path, Revert_Text & " dirty-blocked", "save after blocked operations");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Path);
      Expect_Clean_Association (Rename_Path, Revert_Text & " dirty-blocked", "rename");
      Assert (not Ada.Directories.Exists (Save_As_Path)
        and then Ada.Directories.Exists (Rename_Path),
        "rename must update association only after filesystem success");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Path);
      Expect_Clean_Association (Rename_Path, Revert_Text & " dirty-blocked", "copy");
      Assert (Ada.Directories.Exists (Copy_Path)
        and then Read_Bytes (Copy_Path) = Revert_Text & " dirty-blocked",
        "copy must preserve active association and copy current disk text");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Path);
      Expect_Clean_Association (Move_Path, Revert_Text & " dirty-blocked", "move");
      Assert (not Ada.Directories.Exists (Rename_Path)
        and then Ada.Directories.Exists (Move_Path),
        "move must update association only after filesystem success");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (Move_Path)
        and then not S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = ""
        and then Buffer_Text (S) = Revert_Text & " dirty-blocked",
        "delete must clear association only after filesystem success and keep buffer text open");

      Editor.State.Load_Text (S, Prompt_Text);
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := False;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Prompt_And_Confirm (Editor.Commands.Command_Save_File_As, Prompt_Save_As, "Save As target");
      Expect_Clean_Association (Prompt_Save_As, Prompt_Text, "prompted save-as");
      Prompt_And_Confirm (Editor.Commands.Command_Rename_Buffer_File, Prompt_Rename, "Rename target");
      Expect_Clean_Association (Prompt_Rename, Prompt_Text, "prompted rename");
      Prompt_And_Confirm (Editor.Commands.Command_Copy_Buffer_File, Prompt_Copy, "Copy target");
      Expect_Clean_Association (Prompt_Rename, Prompt_Text, "prompted copy");
      Assert (Ada.Directories.Exists (Prompt_Copy)
        and then Read_Bytes (Prompt_Copy) = Prompt_Text,
        "prompted copy must not open or associate copied target");
      Prompt_And_Confirm (Editor.Commands.Command_Move_Buffer_File, Prompt_Move, "Move target");
      Expect_Clean_Association (Prompt_Move, Prompt_Text, "prompted move");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Direct_Copy & ".cancelled");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Direct_Copy & ".cancelled"),
        "prompt cancellation must remain non-mutating");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Ada.Directories.Exists (Direct_Copy)
        and then Read_Bytes (Direct_Copy) = Prompt_Text
        and then To_String (S.File_Info.Path) = Prompt_Move
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target execution after cancellation must bypass prompt and preserve association");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Direct_Copy & ".cleanup");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Direct_Copy & ".cleanup")
        and then To_String (S.File_Info.Path) = Prompt_Move,
        "lifecycle cleanup must clear prompt state without executing pending move");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy & ".after-cleanup");
      Assert (Ada.Directories.Exists (Direct_Copy & ".after-cleanup")
        and then To_String (S.File_Info.Path) = Prompt_Move,
        "direct command after lifecycle cleanup must remain canonical");

      Cleanup;
      Remove_If_Exists (Direct_Copy & ".after-cleanup");
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup;
         Remove_If_Exists (Direct_Copy & ".after-cleanup");
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Lifecycle_Cross_Command_Sequence_Milestone_Freeze;


   procedure Test_Save_Conflict_Keep_And_Overwrite_Are_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("save_conflict.txt");
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Assert (S.File_Info.File_Token_Known
        and then Length (S.File_Info.File_Token_Label) > 0,
        "open should capture a transient command-boundary file token");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");

      --  Simulate a command-boundary external modification after the buffer
      --  was opened and dirtied.  Use a different size as well as content so
      --  the best-effort token mismatch is deterministic on coarse filesystems.
      Write_Bytes (Path, "external disk replacement with different size");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "save should open a transient conflict prompt on token mismatch");
      Assert (S.File_Info.Dirty,
        "save conflict must preserve dirty buffer state");
      Assert (Read_Bytes (Path) = "external disk replacement with different size",
        "save conflict must not silently overwrite disk");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "conflict prompt should make normal save unavailable");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "Command unavailable while confirmation is pending.",
        "conflict prompt should use the lifecycle confirmation reason");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Keep_Buffer);
      Assert (not S.File_Conflict_Prompt_Active,
        "keep-buffer should dismiss the conflict prompt");
      Assert (S.File_Info.Dirty,
        "keep-buffer must keep dirty text");
      Assert (S.File_Info.External_Change_Surfaced,
        "keep-buffer should leave a visible conflict marker");
      Assert (Read_Bytes (Path) = "external disk replacement with different size",
        "keep-buffer must not write disk");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "later save should re-detect the unresolved external conflict");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Info.Dirty,
        "overwrite should clear dirty state only after successful write");
      Assert (not S.File_Conflict_Prompt_Active,
        "overwrite should clear the conflict prompt after success");
      Assert (Read_Bytes (Path) = "disk baseline dirty buffer",
        "overwrite should write the current buffer text explicitly");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_Conflict_Keep_And_Overwrite_Are_Explicit;

   procedure Test_File_Conflict_Overwrite_Resumes_Confirmed_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("overwrite_resume_close.txt");
      Buffer_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Buffer_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Write_Bytes (Path, "external disk replacement with different size");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Dirty_Close_Prompt_Active,
        "dirty close should open the confirmation prompt");
      Assert (Editor.Buffers.Global_Contains (Buffer_Id),
        "dirty close should keep the target buffer open");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Confirm_Close_Save);
      Assert (S.File_Conflict_Prompt_Active,
        "confirmed close-save should surface the file conflict prompt");
      Assert (not S.Dirty_Close_Prompt_Active,
        "confirming close-save should dismiss the dirty-close prompt");
      Assert (S.File_Info.Dirty,
        "the buffer should remain dirty until the conflict is resolved");
      Assert (Editor.Buffers.Global_Contains (Buffer_Id),
        "the buffer should remain open until overwrite resolves the conflict");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Conflict_Prompt_Active,
        "overwrite should clear the conflict prompt");
      Assert (not Editor.Buffers.Global_Contains (Buffer_Id),
        "overwrite should resume and complete the pending close");
      Assert (Editor.Buffers.Global_Count = 0,
        "resumed close should leave no buffers open");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer,
        "resumed close should leave no active buffer");
      Assert (Read_Bytes (Path) = "disk baseline!",
        "overwrite should write the current buffer text before closing");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Conflict_Overwrite_Resumes_Confirmed_Close;


   procedure Test_Clean_Save_Surfaces_External_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("clean_save_conflict.txt");
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "clean baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Assert (S.File_Info.File_Token_Known,
        "setup should capture the clean buffer token on open");
      Assert (not S.File_Info.Dirty,
        "setup should leave the opened buffer clean");

      --  A clean buffer still has lifecycle state: save must not hide a
      --  known external disk change behind the ordinary no-op message.
      Write_Bytes (Path, "clean disk changed externally with size delta");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "clean save should surface known external modification");
      Assert (S.File_Conflict_Prompt_Kind =
        Editor.State.External_Modified_While_Clean,
        "clean save should classify external modification while clean");
      Assert (not S.File_Info.Dirty,
        "clean external conflict must not dirty the buffer");
      Assert (S.File_Info.External_Change_Surfaced,
        "clean external conflict should show changed-on-disk status");
      Assert (Read_Bytes (Path) = "clean disk changed externally with size delta",
        "clean external conflict must not write disk");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not Editor.Commands.Is_Available (Availability),
        "clean conflict must not expose overwrite as available");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "Buffer is not dirty",
        "clean conflict overwrite should explain that the buffer is not dirty");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Keep_Buffer);
      Assert (not S.File_Conflict_Prompt_Active,
        "keep-buffer should dismiss clean conflict prompt");
      Assert (not S.File_Info.Dirty,
        "keep-buffer should preserve clean buffer state");
      Assert (S.File_Info.External_Change_Surfaced,
        "keep-buffer should preserve clean changed-on-disk marker");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clean_Save_Surfaces_External_Conflict;


   procedure Test_Save_All_Skips_External_Conflicts
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("save_all_conflict.txt");
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "save all baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");

      Write_Bytes (Path, "externally replaced save-all disk content");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_All);

      Assert (S.File_Info.Dirty,
        "save-all conflict skip must leave the buffer dirty");
      Assert (S.File_Info.External_Change_Surfaced,
        "save-all conflict skip should leave a visible changed-on-disk marker");
      Assert (Read_Bytes (Path) = "externally replaced save-all disk content",
        "save-all must not silently overwrite externally changed disk content");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message,
        "save-all conflict skip should report a warning summary");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "conflict needs attention") > 0,
        "save-all summary should report conflicts instead of ordinary write failures");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "file failed") = 0,
        "save-all conflict skips should not increase the ordinary failed-file count");
      Assert (Ada.Strings.Fixed.Index (To_String (M.Text), "unwritable backing file") = 0,
        "external conflicts should not be summarized as unwritable files");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_All_Skips_External_Conflicts;


   procedure Test_Generic_Cancel_Clears_Conflict_Prompt
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("cancel_conflict.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");
      Write_Bytes (Path, "external changed content with different size");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "setup should create a file conflict prompt");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
        "generic cancel should cancel the active file conflict prompt");
      Assert (S.File_Info.Dirty,
        "generic cancel must preserve dirty buffer state");
      Assert (Read_Bytes (Path) = "external changed content with different size",
        "generic cancel must not write disk");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Generic_Cancel_Clears_Conflict_Prompt;


   procedure Test_Replaced_Backing_File_Is_Conflict
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("replaced_conflict.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");

      Remove_If_Exists (Path);
      Ada.Directories.Create_Directory (Path);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "replaced backing file should open a conflict prompt");
      Assert (S.File_Conflict_Prompt_Kind = Editor.State.Backing_File_Replaced,
        "replaced backing file should be classified distinctly from ordinary unreadable files");
      Assert (S.File_Info.Dirty,
        "replaced backing file conflict must preserve dirty text");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Cancel);
      Assert (not S.File_Conflict_Prompt_Active,
        "cancel should clear replaced-file conflict prompt");
      Assert (S.File_Info.Dirty,
        "cancel of replaced-file conflict must preserve dirty state");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Replaced_Backing_File_Is_Conflict;

   procedure Test_Keep_Buffer_Preserves_Specific_Conflict_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("keep_missing_label.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");
      Remove_If_Exists (Path);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "missing backing file should open a conflict prompt");
      Assert (S.File_Conflict_Prompt_Kind =
        Editor.State.Backing_File_Deleted_While_Dirty,
        "missing backing file should keep its specific conflict kind");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Keep_Buffer);
      Assert (not S.File_Conflict_Prompt_Active,
        "keep-buffer should dismiss missing-file prompt");
      Assert (S.File_Info.Missing_Target_Surfaced,
        "keep-buffer should preserve the missing-on-disk marker");
      Assert (not S.File_Info.External_Change_Surfaced,
        "keep-buffer must not relabel missing files as changed-on-disk");
      Assert (S.File_Info.Dirty and then Buffer_Text (S) = "disk baseline dirty buffer",
        "keep-buffer must preserve dirty text for missing files");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Keep_Buffer_Preserves_Specific_Conflict_Label;


   procedure Test_Stale_Conflict_Prompt_Rejects_Disk_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("stale_conflict_disk.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");
      Write_Bytes (Path, "first external disk content with different size");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "setup should create a file conflict prompt");

      --  The prompt was opened against the first observed external disk
      --  version.  If the backing file changes again before confirmation,
      --  overwrite must reject the stale prompt rather than silently
      --  destroying a different disk version.
      Write_Bytes (Path, "second external disk content with another size");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Conflict_Prompt_Active,
        "stale disk conflict prompt should be dismissed");
      Assert (S.File_Info.Dirty,
        "stale disk conflict rejection must preserve dirty state");
      Assert (Read_Bytes (Path) = "second external disk content with another size",
        "stale disk conflict prompt must not overwrite new disk content");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Stale_Conflict_Prompt_Rejects_Disk_Change;


   procedure Test_Stale_Conflict_Prompt_Rejects_Buffer_Revision_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("stale_conflict_revision.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");
      Write_Bytes (Path, "external disk content with different size");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "setup should create a file conflict prompt");

      --  Simulate an out-of-band text mutation while the transient prompt is
      --  visible.  The prompt must not be accepted merely because the buffer
      --  is still dirty and still has the same path.
      Text_Buffer.Set_Text (S.Buffer, "locally changed after prompt");
      S.Buffer_Revision := S.Buffer_Revision + 1;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Overwrite_Disk);
      Assert (not S.File_Conflict_Prompt_Active,
        "stale conflict prompt should be dismissed");
      Assert (S.File_Info.Dirty,
        "stale conflict rejection must preserve dirty state");
      Assert (Read_Bytes (Path) = "external disk content with different size",
        "stale conflict prompt must not overwrite disk");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Stale_Conflict_Prompt_Rejects_Buffer_Revision_Change;



   procedure Test_Dirty_Reload_Confirmation_Rejects_Disk_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("stale_reload_pending.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "reload baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");

      --  Open a destructive dirty reload confirmation against one observed
      --  external disk version, then mutate the disk again before retry.
      --  The retry must reject the stale confirmation rather than discarding
      --  dirty text by reading a different disk version than the prompt named.
      Write_Bytes (Path, "first reload disk version with size delta");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "dirty reload should create an explicit confirmation");

      Write_Bytes (Path, "second reload disk version with another size");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Retry_Pending_Transition);

      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
        "stale dirty reload confirmation should be dismissed");
      Assert (S.File_Info.Dirty,
        "stale dirty reload rejection must preserve dirty state");
      Assert (Buffer_Text (S) = "reload baseline dirty buffer",
        "stale dirty reload rejection must preserve buffer text");
      Assert (Read_Bytes (Path) = "second reload disk version with another size",
        "stale dirty reload rejection must not write disk");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Dirty_Reload_Confirmation_Rejects_Disk_Change;


   procedure Test_File_Conflict_Reload_From_Disk_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("conflict_reload_action.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "reload action baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty buffer");

      --  Save detects the divergent disk version and opens a conflict prompt;
      --  only the explicit conflict reload action may discard dirty text.
      Write_Bytes (Path, "external reload action disk content with size delta");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Conflict_Prompt_Active,
        "reload action setup should create a conflict prompt");
      Assert (S.File_Info.Dirty,
        "reload action setup must preserve dirty text before confirmation");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_File_Conflict_Reload_From_Disk);

      Assert (not S.File_Conflict_Prompt_Active,
        "explicit conflict reload should clear the conflict prompt");
      Assert (not S.File_Info.Dirty,
        "explicit conflict reload should clear dirty state after successful read");
      Assert (Buffer_Text (S) = "external reload action disk content with size delta",
        "explicit conflict reload should replace text from current disk content");
      Assert (Read_Bytes (Path) = "external reload action disk content with size delta",
        "explicit conflict reload must not write disk");
      Assert (S.File_Info.File_Token_Known,
        "explicit conflict reload should capture the accepted disk token");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Conflict_Reload_From_Disk_Is_Explicit;

   procedure Test_File_Lifecycle_Command_Surface_Milestone_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_File_Lifecycle_Cross_Command_Sequence_Milestone_Freeze (T);
   end Test_File_Lifecycle_Command_Surface_Milestone_Freeze;

   overriding procedure Register_Tests (T : in out Files_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Simple_File'Access, "Load Simple File");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_CRLF_Normalizes_To_LF'Access, "Load CRLF Normalizes To LF");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Missing_File'Access, "Load Missing File");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Rejects_NUL_And_Invalid_UTF8'Access,
         "Load Rejects NUL And Invalid UTF8");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Load_Resets_State_And_History'Access,
         "Load Resets State And History");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_File_Result_Success'Access,
         "Open File Result Success");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_File_Result_Failures'Access,
         "Open File Result Failures");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_File_Replaces_State_And_Publishes_Message'Access,
         "Execute Open File Replaces State And Publishes Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_File_Clears_Derived_State'Access,
         "Execute Open File Clears Derived State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_File_Failure_Preserves_State'Access,
         "Execute Open File Failure Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Buffer_Open_Is_Blocked'Access,
         "Dirty Buffer Open Is Blocked");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Already_Open_Path_Alias_Focuses_Existing'Access,
         "Open Already Open Path Alias Focuses Existing");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Read_Failures_Create_No_Buffer'Access,
         "Open Read Failures Create No Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Conflict_Keep_And_Overwrite_Are_Explicit'Access,
         "Save Conflict Keep And Overwrite Are Explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Conflict_Overwrite_Resumes_Confirmed_Close'Access,
         "File Conflict Overwrite Resumes Confirmed Close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clean_Save_Surfaces_External_Conflict'Access,
         "Clean Save Surfaces External Conflict");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_All_Skips_External_Conflicts'Access,
         "Save All Skips External Conflicts");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Generic_Cancel_Clears_Conflict_Prompt'Access,
         "Generic Cancel Clears Conflict Prompt");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replaced_Backing_File_Is_Conflict'Access,
         "Replaced Backing File Is Conflict");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Keep_Buffer_Preserves_Specific_Conflict_Label'Access,
         "Keep Buffer Preserves Specific Conflict Label");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stale_Conflict_Prompt_Rejects_Disk_Change'Access,
         "Stale Conflict Prompt Rejects Disk Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stale_Conflict_Prompt_Rejects_Buffer_Revision_Change'Access,
         "Stale Conflict Prompt Rejects Buffer Revision Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Reload_Confirmation_Rejects_Disk_Change'Access,
         "Dirty Reload Confirmation Rejects Disk Change");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Conflict_Reload_From_Disk_Is_Explicit'Access,
         "File Conflict Reload From Disk Is Explicit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Command_Reference_Metadata'Access,
         "File Lifecycle Command Reference Metadata");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Reference_Projection_And_Boundaries'Access,
         "Command Reference Projection And Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Command_Reference_Accuracy_Matrix'Access,
         "File Lifecycle Command Reference Accuracy Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Reference_Surface_Does_Not_Expand'Access,
         "Command Reference Surface Does Not Expand");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Availability_Reference_Separation'Access,
         "Availability Reference Separation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Reference_Projection_Consistency'Access,
         "Command Palette Reference Projection Consistency");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Reference_Canonical_Metadata_Source'Access,
         "Command Reference Canonical Metadata Source");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Has_No_Reference_Fallbacks_Or_Caches'Access,
         "Command Palette Has No Reference Fallbacks Or Caches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reference_Metadata_Persistence_And_Audit_Boundary'Access,
         "Reference Metadata Persistence And Audit Boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Command_Reference_Final_Surface_Freeze'Access,
         "File Lifecycle Command Reference Final Surface Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Reference_Projection_Availability_And_Render_Freeze'Access,
         "Command Reference Projection Availability And Render Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Reference_Persistence_Lifecycle_And_Behavior_Smoke_Freeze'Access,
         "Command Reference Persistence Lifecycle And Behavior Smoke Freeze");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Command_Surface_Milestone_Freeze'Access,
         "File Lifecycle Command Surface Milestone Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Cross_Command_Sequence_Milestone_Freeze'Access,
         "File Lifecycle Cross Command Sequence Milestone Freeze");
   end Register_Tests;

end Editor.Files.Tests;
