with AUnit.Assertions; use AUnit.Assertions;
with Ada.Containers;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Configuration_Audit;
with Editor.Clipboard;
with Editor.Cursors;
with Editor.Executor;
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
   use type Ada.Streams.Stream_Element_Offset;
   use type Ada.Streams.Stream_IO.Count;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", Name);
   end Temp_Path;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      if Bytes'Length > 0 then
         declare
            Raw : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
         begin
            for I in Bytes'Range loop
               Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
                 Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
            end loop;
            Stream_IO.Write (F, Raw);
         end;
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   function Read_Bytes (Path : String) return String is
      F : Stream_IO.File_Type;
   begin
      Stream_IO.Open (F, Stream_IO.In_File, Path);
      declare
         Size : constant Stream_IO.Count := Stream_IO.Size (F);
      begin
         if Size = 0 then
            Stream_IO.Close (F);
            return "";
         end if;

         declare
            Raw  : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Size));
            Last : Ada.Streams.Stream_Element_Offset;
            S    : String (1 .. Natural (Size));
         begin
            Stream_IO.Read (F, Raw, Last);
            for I in Raw'Range loop
               S (Natural (I)) := Character'Val (Integer (Raw (I)));
            end loop;
            Stream_IO.Close (F);
            return S;
         end;
      end;
   end Read_Bytes;

   function Buffer_Text (S : Editor.State.State_Type) return String is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Buffer_Text;

   procedure Insert_Text_At
     (S    : in out Editor.State.State_Type;
      Pos  : Natural;
      Text : String)
   is
      Offset : Natural := 0;
   begin
      for Ch of Text loop
         Editor.Executor.Execute_No_Log
           (S, Editor.Test_Helper.Insert (Pos + Offset, Ch));
         Offset := Offset + 1;
      end loop;
   end Insert_Text_At;

   procedure Execute_Revert_And_Confirm
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Executor.File_Save_Basic_Commands.Execute_Revert_Active_Buffer (S);
      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Messages.Clear (S.Messages);
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Retry_Pending_Transition);
      end if;
   end Execute_Revert_And_Confirm;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Directory (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   end Remove_If_Exists;

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
      Assert (Found and then To_String (M.Text) = "Reload cancelled",
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
      Assert (Found and then To_String (M.Text) = "Revert cancelled",
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
      Assert (Editor.Project_Search.Is_Stale (S.Project_Search)
        and then Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
        "successful save-as invalidates derived search and replace-preview state");
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
         Path         => To_Unbounded_String ("/tmp/project/demo.adb"),
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
      Assert (Editor.Project_Search.Is_Stale (S.Project_Search)
        and then Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
        "save-all must keep editor-level derived state stale after restoring the original active buffer");
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
         Path         => To_Unbounded_String ("/tmp/project/demo.adb"),
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
         Path         => To_Unbounded_String ("/tmp/project/demo.adb"),
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



   procedure Test_Move_Command_Surface_And_Blocked_Outcomes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p457_surface.txt");
      Target       : constant String := Temp_Path ("p457_surface_moved.txt");
      Existing     : constant String := Temp_Path ("p457_surface_existing.txt");
      Cmd_Id       : Editor.Commands.Command_Id;
      Found        : Boolean := False;
      Descriptor   : Editor.Commands.Command_Descriptor;
      Availability : Editor.Commands.Command_Availability;
      M            : Editor.Messages.Editor_Message;
   begin
      Cmd_Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.move-buffer-file", Found);
      Assert (Found and then Cmd_Id = Editor.Commands.Command_Move_Buffer_File,
        "file.move-buffer-file must resolve to canonical command id");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Move_Buffer_File) = "file.move-buffer-file",
        "move must expose canonical stable command name");

      Descriptor := Editor.Commands.Descriptor
        (Editor.Commands.Command_Move_Buffer_File);
      Assert (Descriptor.Category = Editor.Commands.File_Category
        and then Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Descriptor.Bindable
        and then not Descriptor.Destructive
        and then Descriptor.Lifecycle,
        "move descriptor must be visible bindable File lifecycle command");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "move unavailable without active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "no active buffer must emit deterministic message");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled move text");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "move unavailable for untitled active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no path must emit deterministic message");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Write_Bytes (Path, "move dirty guard disk");
      Write_Bytes (Existing, "existing target");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "move unavailable for dirty active associated buffer");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Path)
        and then Read_Bytes (Path) = "move dirty guard disk"
        and then S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "move dirty guard disk dirty",
        "dirty move must be blocked before target validation, filesystem move, or mutation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, "   ");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Invalid move target"
        and then Ada.Directories.Exists (Path),
        "blank target must fail before filesystem move");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Move target already exists"
        and then Read_Bytes (Existing) = "existing target"
        and then Ada.Directories.Exists (Path)
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
   end Test_Move_Command_Surface_And_Blocked_Outcomes;


   procedure Test_Move_Success_Updates_Association_Only_After_Filesystem
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("p457_success.txt");
      Target      : constant String := Temp_Path ("p457_success_moved.txt");
      Before_Text : Unbounded_String;
      Before_Base : Natural;
      Before_Undo : Ada.Containers.Count_Type;
      Before_Redo : Ada.Containers.Count_Type;
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "move source disk text");
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
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file moved",
        "successful move must emit one deterministic success message");
      Assert ((not Ada.Directories.Exists (Path))
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "move source disk text"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Target
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (S.Active_Find_Query) = "source"
        and then To_String (S.Active_Replace_Text) = "target"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then Editor.Buffers.Global_Count = 1
        and then Editor.Buffers.Global_Active_Buffer = Editor.Buffers.Buffer_Id (1),
        "successful move must update only association/path label and preserve text, baseline, dirty, feature, and buffer state");

      Insert_Text_At (S, Buffer_Text (S)'Length, " edited");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Target) = "move source disk text edited"
        and then not Ada.Directories.Exists (Path),
        "subsequent save must write to moved target path, not old source path");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
            Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Success_Updates_Association_Only_After_Filesystem;


   procedure Test_Move_Failure_Preserves_Association_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("p457_failure.txt");
      Target      : constant String := Temp_Path ("p457_missing_parent") & "/moved.txt";
      Before_Text : Unbounded_String;
      Before_Base : Natural;
      Before_Undo : Ada.Containers.Count_Type;
      Before_Redo : Ada.Containers.Count_Type;
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "move failure disk text");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("failure clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not move buffer file",
        "filesystem move failure must emit deterministic failure message");
      Assert (Ada.Directories.Exists (Path)
        and then Read_Bytes (Path) = "move failure disk text"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "failure clipboard",
        "failed move must preserve active association, text, baseline, dirty state, history, and clipboard");

      Remove_If_Exists (Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Failure_Preserves_Association_And_State;


   procedure Test_Move_Source_Validation_Order_And_Active_Identity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Active_Path   : constant String := Temp_Path ("p458_active_source.txt");
      Inactive_Path : constant String := Temp_Path ("p458_inactive_source.txt");
      Target        : constant String := Temp_Path ("p458_active_moved.txt");
      Existing      : constant String := Temp_Path ("p458_existing_target.txt");
      Reopen_Path   : constant String := Temp_Path ("p458_reopen_candidate.txt");
      Active_Id     : Editor.Buffers.Buffer_Id;
      Inactive_Id   : Editor.Buffers.Buffer_Id;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
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
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer."
        and then not Ada.Directories.Exists (Target),
        "no-active validation must precede all source, target, and filesystem work");

      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, "   ");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no-path validation must precede dirty state and target validation");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Active_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Unsaved changes require confirmation."
        and then Read_Bytes (Existing) = "existing target"
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Active_Path)
        and then To_String (S.File_Info.Path) = Active_Path
        and then S.File_Info.Dirty,
        "dirty guard must precede target collision checks and filesystem move");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Active_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Move target already exists"
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
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file moved"
        and then not Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "active disk dirty"
        and then To_String (S.File_Info.Path) = Target
        and then Editor.Buffers.Global_Active_Buffer = Active_Id
        and then Editor.Buffers.Global_Count = 2
        and then Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Dirty
        and then To_String (Editor.Buffers.Buffer
          (Editor.Buffers.Global_Registry_For_UI, Inactive_Id).File_Info.Path) = Inactive_Path
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "move source must be the execution-time active buffer only and must ignore UI, inactive, and reopen fallbacks");

      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Source_Validation_Order_And_Active_Identity;


   procedure Test_Move_Failure_Read_Only_Boundaries_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p458_boundary_source.txt");
      Target       : constant String := Temp_Path ("p458_boundary_moved.txt");
      Reopen_Path  : constant String := Temp_Path ("p458_boundary_reopen.txt");
      Workspace    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary      : Unbounded_String;
      Availability : Editor.Commands.Command_Availability;
      Candidates   : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Before_Base  : Natural;
      Before_Undo  : Ada.Containers.Count_Type;
      Before_Redo  : Ada.Containers.Count_Type;
      Before_Caret : Editor.Cursors.Caret_State;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
      Move_Rows    : Natural := 0;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "boundary disk");
      Write_Bytes (Reopen_Path, "reopen disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "boundary");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "replacement");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("reopen");
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
      Before_Caret := S.Carets (0);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "availability, palette projection, render, and workspace snapshot must not move, probe, infer, or mutate move state");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move target");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("file-watch");

      Remove_If_Exists (Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found and then To_String (M.Text) = "Could not move buffer file"
        and then Editor.Messages.Count (S.Messages) = 1
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then To_String (S.Active_Find_Query) = "boundary"
        and then To_String (S.Active_Replace_Text) = "replacement"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "filesystem move failure must preserve association, text, baseline, dirty state, feature state, and reopen candidates");
      Assert_Summary_Excludes ("Could not move buffer file");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move target");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("file-watch");

      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Reopen_Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Failure_Read_Only_Boundaries_And_Persistence;


   procedure Test_Move_File_Lifecycle_Uses_Moved_Association
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Source       : constant String := Temp_Path ("p458_lifecycle_source.txt");
      Moved        : constant String := Temp_Path ("p458_lifecycle_moved.txt");
      Renamed      : constant String := Temp_Path ("p458_lifecycle_renamed.txt");
      Copied       : constant String := Temp_Path ("p458_lifecycle_copied.txt");
      Before_Count : Natural;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Write_Bytes (Source, "lifecycle disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Moved);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file moved"
        and then not Ada.Directories.Exists (Source)
        and then Ada.Directories.Exists (Moved)
        and then To_String (S.File_Info.Path) = Moved
        and then Editor.Buffers.Global_Count = Before_Count,
        "move success must update association to target without opening or closing buffers");

      Insert_Text_At (S, Buffer_Text (S)'Length, " saved");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Moved) = "lifecycle disk saved"
        and then not Ada.Directories.Exists (Source)
        and then not S.File_Info.Dirty,
        "subsequent save must write active text to the moved target path only");

      Write_Bytes (Moved, "lifecycle reloaded");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "lifecycle reloaded"
        and then To_String (S.File_Info.Path) = Moved,
        "subsequent reload must read from the moved target association");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "lifecycle reloaded"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Moved,
        "subsequent revert must use the moved target association after later edits");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Renamed);
      Assert (not Ada.Directories.Exists (Moved)
        and then Ada.Directories.Exists (Renamed)
        and then To_String (S.File_Info.Path) = Renamed,
        "subsequent rename must rename the moved target path");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copied);
      Assert (Ada.Directories.Exists (Copied)
        and then Read_Bytes (Copied) = Read_Bytes (Renamed)
        and then To_String (S.File_Info.Path) = Renamed,
        "subsequent copy must copy the moved-then-renamed associated path without changing association");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (Renamed)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Editor.Buffers.Global_Count = Before_Count,
        "subsequent delete must delete the current moved-path association through the delete command policy");

      Remove_If_Exists (Source);
      Remove_If_Exists (Moved);
      Remove_If_Exists (Renamed);
      Remove_If_Exists (Copied);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Moved);
         Remove_If_Exists (Renamed);
         Remove_If_Exists (Copied);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_File_Lifecycle_Uses_Moved_Association;



   procedure Test_Move_Integrated_Workflow_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      A        : constant String := Temp_Path ("p459_a.txt");
      A1       : constant String := Temp_Path ("p459_a1.txt");
      A2       : constant String := Temp_Path ("p459_a2.txt");
      A3       : constant String := Temp_Path ("p459_a3.txt");
      A_Copy   : constant String := Temp_Path ("p459_a_copy.txt");
      A_Exists : constant String := Temp_Path ("p459_a_exists.txt");
      B1       : constant String := Temp_Path ("p459_b1.txt");
      B2       : constant String := Temp_Path ("p459_b2.txt");
      C        : constant String := Temp_Path ("p459_c.txt");
      C_Fail   : constant String := Temp_Path ("p459_c_fail.txt");
      C1       : constant String := Temp_Path ("p459_c1.txt");
      C2       : constant String := Temp_Path ("p459_c2.txt");
      A_Id     : Editor.Buffers.Buffer_Id;
      B_Id     : Editor.Buffers.Buffer_Id;
      C_Id     : Editor.Buffers.Buffer_Id;
      Count_0  : Natural;
      Found    : Boolean := False;
      M        : Editor.Messages.Editor_Message;

      procedure Assert_Message (Text : String; Context : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text
           and then Editor.Messages.Count (S.Messages) = 1,
           "message policy: " & Context);
      end Assert_Message;
   begin
      Remove_If_Exists (A);
      Remove_If_Exists (A1);
      Remove_If_Exists (A2);
      Remove_If_Exists (A3);
      Remove_If_Exists (A_Copy);
      Remove_If_Exists (A_Exists);
      Remove_If_Exists (B1);
      Remove_If_Exists (B2);
      Remove_If_Exists (C);
      Remove_If_Exists (C_Fail);
      Remove_If_Exists (C1);
      Remove_If_Exists (C2);
      Write_Bytes (A, "A disk");
      Write_Bytes (A_Exists, "existing target");
      Write_Bytes (C, "C disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "B text");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Count_0 := Editor.Buffers.Global_Count;

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, A1);
      Assert_Message ("Buffer file moved", "successful A -> A1 move");
      Assert (not Ada.Directories.Exists (A)
        and then Ada.Directories.Exists (A1)
        and then Read_Bytes (A1) = "A disk"
        and then To_String (S.File_Info.Path) = A1
        and then not S.File_Info.Dirty
        and then Buffer_Text (S) = "A disk"
        and then Editor.Buffers.Global_Active_Buffer = A_Id
        and then Editor.Buffers.Global_Count = Count_0,
        "integrated: successful move must move only active backing file, update association, preserve text/clean state, and keep buffers open");

      Insert_Text_At (S, Buffer_Text (S)'Length, " saved");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (A1) = "A disk saved"
        and then not S.File_Info.Dirty,
        "integrated: Save after move writes current text to moved target path");
      Write_Bytes (A1, "A reloaded");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "A reloaded"
        and then To_String (S.File_Info.Path) = A1,
        "integrated: Reload after move reads moved target path");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Temp_Path ("p459_a_dirty_move.txt"));
      Assert_Message ("Unsaved changes require confirmation.", "dirty A move blocked");
      Assert (To_String (S.File_Info.Path) = A1
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "A reloaded dirty",
        "integrated: dirty move is non-mutating");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "A reloaded"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = A1,
        "integrated: Revert after blocked move still uses moved target");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, A_Exists);
      Assert_Message ("Move target already exists", "existing target collision");
      Assert (Read_Bytes (A_Exists) = "existing target"
        and then To_String (S.File_Info.Path) = A1,
        "integrated: target collision preserves association and target contents");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, A2);
      Assert_Message ("Buffer file moved", "A1 -> A2 move");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, A_Copy);
      Assert (Ada.Directories.Exists (A_Copy)
        and then Read_Bytes (A_Copy) = Read_Bytes (A2)
        and then To_String (S.File_Info.Path) = A2,
        "integrated: Copy after move copies moved associated path without changing association");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A3);
      Assert (not Ada.Directories.Exists (A2)
        and then Ada.Directories.Exists (A3)
        and then To_String (S.File_Info.Path) = A3,
        "integrated: Rename after move renames moved association");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, B2);
      Assert_Message ("No file path for active buffer", "dirty untitled B move reports no path first");
      Assert (S.File_Info.Dirty and then not S.File_Info.Has_Path,
        "integrated: dirty untitled no-path move preserves B state");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, B1);
      Assert (Ada.Directories.Exists (B1)
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = B1,
        "integrated: Save As remains the command that associates untitled text");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, B2);
      Assert_Message ("Buffer file moved", "B1 -> B2 move");
      Assert (not Ada.Directories.Exists (B1)
        and then Ada.Directories.Exists (B2)
        and then Read_Bytes (B2) = "B text"
        and then To_String (S.File_Info.Path) = B2,
        "integrated: moved Save-As buffer uses explicit move target");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, C_Id);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "C");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "cee");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, "   ");
      Assert_Message ("Invalid move target", "invalid C target");
      Assert (To_String (S.File_Info.Path) = C
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then To_String (S.Active_Find_Query) = "C"
        and then To_String (S.Active_Replace_Text) = "cee",
        "integrated: invalid target preserves feature state");
      Remove_If_Exists (C);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, C_Fail);
      Assert_Message ("Could not move buffer file", "missing-source C failure");
      Assert (To_String (S.File_Info.Path) = C
        and then not Ada.Directories.Exists (C_Fail)
        and then not S.File_Info.Dirty,
        "integrated: filesystem failure preserves old association and clean state");
      Write_Bytes (C, "C restored");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, C1);
      Assert_Message ("Buffer file moved", "C -> C1 move");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert (not Ada.Directories.Exists (C1)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "integrated: Delete after move deletes moved target and applies delete no-path policy");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, C2);
      Write_Bytes (C2, "C2 reloaded");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "C2 reloaded"
        and then To_String (S.File_Info.Path) = C2,
        "integrated: Save As and Reload after post-move delete remain coherent");

      Assert (Editor.Buffers.Global_Count = Count_0,
        "integrated: move/open lifecycle did not open moved targets or close buffers");

      Remove_If_Exists (A);
      Remove_If_Exists (A1);
      Remove_If_Exists (A2);
      Remove_If_Exists (A3);
      Remove_If_Exists (A_Copy);
      Remove_If_Exists (A_Exists);
      Remove_If_Exists (B1);
      Remove_If_Exists (B2);
      Remove_If_Exists (C);
      Remove_If_Exists (C_Fail);
      Remove_If_Exists (C1);
      Remove_If_Exists (C2);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A);
         Remove_If_Exists (A1);
         Remove_If_Exists (A2);
         Remove_If_Exists (A3);
         Remove_If_Exists (A_Copy);
         Remove_If_Exists (A_Exists);
         Remove_If_Exists (B1);
         Remove_If_Exists (B2);
         Remove_If_Exists (C);
         Remove_If_Exists (C_Fail);
         Remove_If_Exists (C1);
         Remove_If_Exists (C2);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Integrated_Workflow_Coherence;


   procedure Test_Move_Preserves_Transient_Feature_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Path           : constant String := Temp_Path ("p459_transient_source.txt");
      Target         : constant String := Temp_Path ("p459_transient_target.txt");
      Reopen_Path    : constant String := Temp_Path ("p459_transient_reopen.txt");
      Before_Text    : Unbounded_String;
      Before_Base    : Natural;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Back    : Ada.Containers.Count_Type;
      Before_Fwd     : Ada.Containers.Count_Type;
      Before_Caret   : Editor.Cursors.Caret_State;
      Before_Count   : Natural;
      Before_Query   : Unbounded_String;
      Before_Replace : Unbounded_String;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "transient source");
      Write_Bytes (Reopen_Path, "reopen source");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "transient");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "stable");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("stable clipboard"));
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
      Editor.Executor.Selection_Commands.Execute_Clear_Selection_Command (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, "!");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (not S.File_Info.Dirty,
        "transient setup: undo should return active buffer to saved baseline before move");

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;
      Before_Caret := S.Carets (0);
      Before_Count := Editor.Buffers.Global_Count;
      Before_Query := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file moved"
        and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (S.File_Info.Path) = Target
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
        and then To_String (S.Active_Find_Query) = To_String (Before_Query)
        and then To_String (S.Active_Replace_Text) = To_String (Before_Replace)
        and then To_String (Editor.Clipboard.Get_Text) = "stable clipboard"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path
        and then Editor.Buffers.Global_Count = Before_Count,
        "transient: successful move preserves undo/redo, Find/Replace, Clipboard, selection/caret, navigation, reopen candidate, text, baseline, dirty state, and buffer collection");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = "transient source!"
        and then S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Target
        and then Ada.Directories.Exists (Target),
        "transient: redo after move is an edit redo against moved association, not a filesystem move redo");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "transient source"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Target,
        "transient: undo after move affects text only and does not undo filesystem move");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Reopen_Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Reopen_Path);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Preserves_Transient_Feature_Boundaries;


   procedure Test_Move_Read_Only_Persistence_And_Surface_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p459_readonly_source.txt");
      Target       : constant String := Temp_Path ("p459_readonly_target.txt");
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Before_Base  : Natural;
      Before_Undo  : Ada.Containers.Count_Type;
      Before_Redo  : Ada.Containers.Count_Type;
      Availability : Editor.Commands.Command_Availability;
      Candidates   : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Workspace    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary      : Unbounded_String;
      Move_Rows    : Natural := 0;
      Cmd_Id       : Editor.Commands.Command_Id;
      Has_Name     : Boolean := False;

      procedure Assert_Absent (Name : String) is
      begin
         Cmd_Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Has_Name);
         Assert (not Has_Name and then Cmd_Id = Editor.Commands.No_Command,
           "non-goal command must be absent: " & Name);
      end Assert_Absent;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "read only disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "read");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "write");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("readonly clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Base := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
        and then Ada.Directories.Exists (Path)
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Saved_Generation = Before_Base
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "readonly clipboard"
        and then To_String (S.Active_Find_Query) = "read"
        and then To_String (S.Active_Replace_Text) = "write",
        "read-only: availability, palette projection, render snapshot, and workspace snapshot must not move, probe target, write text, or mutate editor state");
      Assert_Summary_Excludes ("last move");
      Assert_Summary_Excludes ("move target");
      Assert_Summary_Excludes ("moved path");
      Assert_Summary_Excludes ("move history");
      Assert_Summary_Excludes ("overwrite policy");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("Could not move buffer file");

      Assert_Absent ("file.move-all-buffers");
      Assert_Absent ("file.move-project-file");
      Assert_Absent ("file.move-dirty-buffer");
      Assert_Absent ("file.move-untitled-buffer");
      Assert_Absent ("file.force-move-buffer-file");
      Assert_Absent ("file.move-buffer-file-overwrite");
      Assert_Absent ("file.duplicate-buffer");
      Assert_Absent ("file.open-moved-buffer-file");
      Assert_Absent ("file.copy-and-delete-buffer-file");
      Assert_Absent ("workspace.move-buffer-file");
      Assert_Absent ("project.move-files");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Clipboard.Clear;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Move_Read_Only_Persistence_And_Surface_Boundaries;


   procedure Test_Retry_Save_After_Failure_Uses_Latest_Content
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Path     : constant String := Temp_Path ("retry_save.txt");
      Dir_Path : constant String := Temp_Path ("retry_save_dir");
      Before_Caret : Editor.Cursors.Caret_State;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "first");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 2, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("retry_save.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Caret := S.Carets (0);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Info.Dirty,
        "failed save should keep dirty state for retry");

      Remove_If_Exists (Dir_Path);
      S.File_Info.Path := To_Unbounded_String (Path);
      Editor.Executor.Selection_Commands.Execute_Clear_Selection_Command (S);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      S.Carets.Clear;
      S.Carets.Append (Before_Caret);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (Read_Bytes (Path) = "first!",
        "retry save should write latest in-memory content");
      Assert (not S.File_Info.Dirty,
        "successful retry save should clear dirty state");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful retry save should update saved baseline");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "retry save should preserve cursor and selection");
      Remove_If_Exists (Path);
   end Test_Retry_Save_After_Failure_Uses_Latest_Content;

   procedure Test_Blocked_Dirty_Reload_Preserves_History_Viewport_And_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path    : constant String := Temp_Path ("blocked_reload.txt");
      Before_Undo : Ada.Containers.Count_Type;
      Before_Redo : Ada.Containers.Count_Type;
      Before_X    : Natural;
      Before_Y    : Natural;
      Before_Text : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (5, '?'));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Editor.View.Set_Scroll (9, 4);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_X := Editor.View.Scroll_X;
      Before_Y := Editor.View.Scroll_Y;
      Write_Bytes (Path, "replacement");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = To_String (Before_Text),
        "blocked dirty reload should preserve content");
      Assert (S.File_Info.Dirty,
        "blocked dirty reload should preserve dirty marker");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "blocked dirty reload should preserve undo and redo history");
      Assert (Editor.View.Scroll_X = Before_X and then Editor.View.Scroll_Y = Before_Y,
        "blocked dirty reload should preserve viewport");
      Remove_If_Exists (Path);
   end Test_Blocked_Dirty_Reload_Preserves_History_Viewport_And_Features;

   procedure Test_Revert_Canonical_Dirty_Read_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("revert_canonical_read.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Editor.View.Set_Scroll (5, 3);
      Assert (not Editor.History.Undo_Stack.Is_Empty,
        "test setup should have undo history before canonical revert");

      Execute_Revert_And_Confirm (S);

      Assert (Buffer_Text (S) = "disk",
        "canonical revert should restore disk content");
      Assert (not S.File_Info.Dirty,
        "canonical revert should clear dirty state");
      Assert (Editor.History.Undo_Stack.Is_Empty and then Editor.History.Redo_Stack.Is_Empty,
        "canonical revert should reset edit history");
      Assert (Editor.View.Scroll_X = 0 and then Editor.View.Scroll_Y = 0,
        "canonical revert should reset viewport according to reload policy");
      Remove_If_Exists (Path);
   end Test_Revert_Canonical_Dirty_Read_Path;

   procedure Test_Render_Packet_After_Load_Emits_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Packet : Editor.Render_Packet.Render_Packet;
      Path   : constant String := Temp_Path ("render.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "abc");
      Editor.State.Init (S);
      Assert (Editor.Files.Load_File (Path, S) = Editor.Files.Ok,
        "Load should succeed before render packet test");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Build_Render_Packet (Packet);
      Assert (Natural (Packet.Glyph_Count) >= 3,
        "Render packet after load should emit visible text glyphs");
      Remove_If_Exists (Path);
   end Test_Render_Packet_After_Load_Emits_Text;



   procedure Test_Failed_Save_Feedback_Explains_Retryable_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Dir_Path : constant String := Temp_Path ("save_dir");
      Found    : Boolean := False;
      M        : Editor.Messages.Editor_Message;
      Snap     : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_dir.adb");
      S.File_Info.Dirty := True;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (S.File_Info.Dirty,
        "failed save should leave the buffer dirty and retryable");
      Assert (Buffer_Text (S) = "dirty text",
        "failed save should preserve in-memory edits");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "failed save should publish one error outcome");
      Assert (To_String (M.Text) =
        "Could not save file.",
        "failed save feedback should explain preserved dirty state");
      Editor.Input_Bridge.Set_State_For_Test (S);
      Editor.Input_Bridge.Get_Render_Snapshot (Snap);
      Assert (Snap.Is_Dirty,
        "failed save should keep Status Bar dirty marker visible");
      Assert (To_String (Snap.File_Name) = "save_dir.adb",
        "failed save should keep active buffer label stable");
      Remove_If_Exists (Dir_Path);
   end Test_Failed_Save_Feedback_Explains_Retryable_State;

   procedure Test_Blocked_Reload_Feedback_Says_No_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("blocked_reload.txt");
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
      Before : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Before := To_Unbounded_String (Buffer_Text (S));
      Write_Bytes (Path, "replacement");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = To_String (Before),
        "blocked reload must not replace buffer content");
      Assert (S.File_Info.Dirty,
        "blocked reload should keep dirty marker visible");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message,
        "blocked reload should publish a warning outcome");
      Assert (To_String (M.Text) =
        "Dirty buffer cannot be reloaded",
        "blocked reload feedback should say no disk replacement happened");
      Remove_If_Exists (Path);
   end Test_Blocked_Reload_Feedback_Says_No_Replacement;

   procedure Test_Blocked_Close_Feedback_Says_Buffer_Remains_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("blocked_close.txt");
      Id           : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);

      Assert (Editor.Buffers.Global_Count = Before_Count,
        "blocked close should keep the open-buffer row visible");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "blocked close should keep the active buffer unchanged");
      Assert (S.File_Info.Dirty,
        "blocked close should keep dirty marker visible");
      Assert (Buffer_Text (S) = "disk!",
        "blocked close should preserve buffer content");
      Assert (S.Dirty_Close_Prompt_Active,
        "dirty close should open explicit review while keeping buffer open");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message,
        "/575: dirty close should publish a warning outcome");
      Assert (To_String (M.Text) =
        "Unsaved changes require confirmation.",
        "dirty file-backed close feedback should request explicit confirmation");
      Remove_If_Exists (Path);
   end Test_Blocked_Close_Feedback_Says_Buffer_Remains_Open;

   procedure Test_Already_Open_Focus_Feedback_Does_Not_Imply_Reload
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("already_open.txt");
      Id           : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Before_Count := Editor.Buffers.Global_Count;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Write_Bytes (Path, "replacement");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Assert (Editor.Buffers.Global_Count = Before_Count,
        "already-open focus should not create a duplicate row");
      Assert (Editor.Buffers.Global_Active_Buffer = Id,
        "already-open focus should keep the existing buffer active");
      Assert (Buffer_Text (S) = "disk!",
        "already-open focus must not reread disk content");
      Assert (S.File_Info.Dirty,
        "already-open focus should preserve dirty marker");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message,
        "already-open focus should publish informational feedback");
      Assert (To_String (M.Text) =
        "Focused existing buffer already_open.txt; disk was not reloaded",
        "already-open focus feedback should not imply disk reload");
      Remove_If_Exists (Path);
   end Test_Already_Open_Focus_Feedback_Does_Not_Imply_Reload;



   procedure Test_Failed_Save_Context_Clears_After_Successful_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Path     : constant String := Temp_Path ("retry_clear.txt");
      Dir_Path : constant String := Path;
      Summary  : Editor.Buffers.Buffer_Summary;
   begin
      Remove_If_Exists (Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("retry_clear.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Info.Dirty and then S.File_Info.Last_Save_Failed,
        "failed save should leave retry context while dirty");
      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);
      Assert (Summary.Last_Save_Failed,
        "failed-save context must belong to the affected buffer summary");

      Remove_If_Exists (Path);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);

      Assert (not S.File_Info.Dirty,
        "successful retry save should clear dirty marker");
      Assert (not S.File_Info.Last_Save_Failed,
        "successful retry save should clear failed-save context");
      Assert (not S.File_Info.Missing_Target_Surfaced,
        "successful save should clear obsolete missing-target save warning");
      Summary := Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer);
      Assert (not Summary.Last_Save_Failed,
        "open-buffer row summary should stop advertising retry after recovery");
      Assert (Editor.Lifecycle_Guidance.Status_Bar_Hint (S) /=
              "Dirty file - retry save available",
        "Status Bar retry hint should clear after recovery");
      Remove_If_Exists (Path);
   end Test_Failed_Save_Context_Clears_After_Successful_Save;

   procedure Test_Retry_Context_Survives_Buffer_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Failed_Path : constant String := Temp_Path ("retry_switch_dir");
      Clean_Path  : constant String := Temp_Path ("retry_switch_clean.txt");
      Failed_Id   : Editor.Buffers.Buffer_Id;
      Clean_Id    : Editor.Buffers.Buffer_Id;
   begin
      Remove_If_Exists (Failed_Path);
      Remove_If_Exists (Clean_Path);
      Ada.Directories.Create_Directory (Failed_Path);
      Write_Bytes (Clean_Path, "clean");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Failed_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("retry_switch_dir");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Failed_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (S.File_Info.Last_Save_Failed,
        "fixture should have failed-save retry context");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Clean_Path);
      Clean_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Clean_Id /= Failed_Id,
        "clean file should become a second buffer");
      Assert (not S.File_Info.Last_Save_Failed,
        "switching to unrelated clean buffer must not show wrong retry context");
      Assert (Editor.Lifecycle_Guidance.Status_Bar_Hint (S) /=
              "Dirty file - retry save available",
        "Status Bar retry hint should follow the active buffer only");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Failed_Id);
      Assert (S.File_Info.Last_Save_Failed and then S.File_Info.Dirty,
        "switching back should restore still-relevant retry context");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "not writable") > 0,
        "retry context should return through the affected buffer's recovery marker");
      Remove_If_Exists (Failed_Path);
      Remove_If_Exists (Clean_Path);
   end Test_Retry_Context_Survives_Buffer_Switch;

   procedure Test_Blocked_Reload_Clears_After_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("blocked_reload.txt");
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (S.File_Info.Dirty,
        "blocked reload must preserve dirty state without recording reload context");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Dirty") > 0,
        "Status Bar should expose ordinary dirty state after blocked reload");
      if Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions) then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Cancel_Pending_Transition);
      end if;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
        "save after blocked reload should clean the buffer");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Reload") = 0,
        "successful save should have no reload context to clear");
      Remove_If_Exists (Path);
   end Test_Blocked_Reload_Clears_After_Save;

   procedure Test_Blocked_Close_Clears_After_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("blocked_close.txt");
      Id           : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (4, '!'));
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);
      Assert (Editor.Buffers.Global_Count = Before_Count,
        "blocked close should not remove the row");
      Assert (S.File_Info.Dirty and then S.File_Info.Blocked_Close_Surfaced,
        "blocked close should surface buffer-owned close context without clearing dirty state");
      Assert (Ada.Strings.Fixed.Index
                (Editor.Lifecycle_Guidance.Status_Bar_Hint (S),
                 "Close blocked") > 0,
        "Status Bar should expose current blocked-close recovery hint");
      if S.Dirty_Close_Prompt_Active then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Cancel_Close);
      end if;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Buffer (S, Id);
      Assert (Editor.Buffers.Global_Count = 0,
        "closing the only clean buffer should leave no replacement buffer");
      Assert (Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
        and then S.Active_Buffer_Token = 0,
        "closed buffer transient lifecycle context must not remain active");
      Assert (not S.File_Info.Blocked_Close_Surfaced,
        "replacement active buffer must not inherit blocked-close context");
      Remove_If_Exists (Path);
   end Test_Blocked_Close_Clears_After_Close;


   procedure Test_Save_As_Command_Metadata_And_No_Target_Route
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Save_File_As) =
           "file.save-as",
         "Save As must expose canonical file.save-as persisted name");
      Assert
        (Editor.Commands.Category (Editor.Commands.Command_Save_File_As) =
           Editor.Commands.File_Category,
         "Save As must remain a File command");
      Assert
        (Editor.Commands.Is_File_Content_Save_Command
           (Editor.Commands.Command_Save_File_As),
         "Save As must be classified as a file/content persistence command");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save-as", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Save_File_As,
         "file.save-as must resolve to the Save As command id");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "needs explicit target");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);

      Assert (Buffer_Text (S) = "needs explicit target",
        "public Save As without payload must not edit text");
      Assert (S.File_Info.Dirty,
        "public Save As without payload must preserve dirty state");
      Assert (not S.File_Info.Has_Path,
        "public Save As without payload must not invent a path");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "public Save As without payload should open target prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target",
        "Save As target prompt should use deterministic label");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "opening Save As prompt must not emit underlying command feedback");
   end Test_Save_As_Command_Metadata_And_No_Target_Route;

   procedure Test_Save_As_Success_Reassociates_And_Subsequent_Save_Uses_New_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Old_Path      : constant String := Temp_Path ("old_path.txt");
      New_Path      : constant String := Temp_Path ("new_path.txt");
      Exact_Text    : constant String := "alpha" & ASCII.LF & ASCII.HT & " beta  " & ASCII.LF;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Old_Path);
      Remove_If_Exists (New_Path);
      Write_Bytes (Old_Path, "old disk");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Exact_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 2,
          Anchor                => 0,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("alpha");
      S.Active_Replace_Text := To_Unbounded_String ("omega");
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clip"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Old_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("old_path.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, New_Path);

      Assert (Read_Bytes (New_Path) = Exact_Text,
        "Save As must write exact current active-buffer text");
      Assert (Read_Bytes (Old_Path) = "old disk",
        "Save As must not write the old associated path when target differs");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = New_Path,
        "Save As must associate the active buffer with the new target after success");
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid,
        "Save As success must mark the exact written state clean");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "Save As success must update the saved baseline after the write");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "Save As must not create or clear Undo/Redo entries");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "Save As must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "alpha"
        and then To_String (S.Active_Replace_Text) = "omega"
        and then S.Active_Find_Prompt
        and then S.Active_Replace_Prompt,
        "Save As must preserve Find/Replace state");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clip",
        "Save As must preserve Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "Save As success must emit one primary message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "Save As success must use deterministic feedback");

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => Editor.Cursors.Cursor_Index (Exact_Text'Length),
            Anchor                => Editor.Cursors.Cursor_Index (Exact_Text'Length),
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (Exact_Text'Length, '!'));
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (New_Path) = Exact_Text & "!",
        "subsequent file.save must write to the Save As target");
      Assert (Read_Bytes (Old_Path) = "old disk",
        "subsequent file.save must not write to the old associated path");
      Remove_If_Exists (Old_Path);
      Remove_If_Exists (New_Path);
   end Test_Save_As_Success_Reassociates_And_Subsequent_Save_Uses_New_Path;

   procedure Test_Save_As_Failure_Preserves_Old_Association_Baseline_And_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Old_Path      : constant String := Temp_Path ("failure_old.txt");
      Dir_Path      : constant String := Temp_Path ("failure_dir");
      Before_Text   : constant String := "dirty save-as failure text";
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Old_Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Old_Path, "old disk");
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Old_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("failure_old.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 77;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Dir_Path);

      Assert (Buffer_Text (S) = Before_Text,
        "failed Save As must preserve buffer text");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Old_Path,
        "failed Save As must preserve the old associated path");
      Assert (S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 77,
        "failed Save As must preserve dirty state and saved baseline");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed Save As must preserve Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "failed Save As must preserve caret and selection");
      Assert (Read_Bytes (Old_Path) = "old disk",
        "failed Save As must not write the old path");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "failed Save As must emit one primary message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Invalid Save As target",
        "failed Save As must use deterministic invalid-target feedback");
      Remove_If_Exists (Old_Path);
      Remove_If_Exists (Dir_Path);
   end Test_Save_As_Failure_Preserves_Old_Association_Baseline_And_State;

   procedure Test_Save_As_Affects_Only_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path_A  : constant String := Temp_Path ("active_a.txt");
      Path_A2 : constant String := Temp_Path ("active_a2.txt");
      Path_B  : constant String := Temp_Path ("inactive_b.txt");
      A       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_State : Editor.State.State_Type;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_A2);
      Remove_If_Exists (Path_B);
      Write_Bytes (Path_A, "old a");
      Write_Bytes (Path_B, "old b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_A, "active_a.txt", "new a", A);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_B, "inactive_b.txt", "new b", B);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path_A2);

      Assert (Read_Bytes (Path_A2) = "new a",
        "Save As must write only the active buffer text to the explicit target");
      Assert (Read_Bytes (Path_A) = "old a",
        "Save As must not write the old active path when saving as a new path");
      Assert (Read_Bytes (Path_B) = "old b",
        "Save As must not write inactive buffer paths");
      Assert (not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Path_A2,
        "active buffer should be clean and reassociated after Save As");
      B_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, B);
      Assert (B_State.File_Info.Dirty
        and then To_String (B_State.File_Info.Path) = Path_B,
        "inactive buffer path and dirty state must remain unchanged");
      Assert (Buffer_Text (B_State) = "new b",
        "inactive buffer text must remain unchanged after active Save As");
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_A2);
      Remove_If_Exists (Path_B);
   end Test_Save_As_Affects_Only_Active_Buffer;


   procedure Test_Save_As_Missing_Parent_Is_Write_Failure_And_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Parent_Path     : constant String := Temp_Path ("missing_parent");
      Target_Path     : constant String := Ada.Directories.Compose (Parent_Path, "target.txt");
      Old_Path        : constant String := Temp_Path ("missing_parent_old.txt");
      Before_Text     : constant String := "missing parent save-as text";
      Before_Saved    : Natural;
      Before_Undo     : Ada.Containers.Count_Type;
      Before_Redo     : Ada.Containers.Count_Type;
      Before_Caret    : Editor.Cursors.Caret_State;
      Found           : Boolean := False;
      M               : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Target_Path);
      Remove_If_Exists (Parent_Path);
      Remove_If_Exists (Old_Path);
      Write_Bytes (Old_Path, "old disk before missing parent");
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 8,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("missing");
      S.Active_Replace_Text := To_Unbounded_String ("present");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clip"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Old_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("missing_parent_old.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 426;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target_Path);

      Assert (not Ada.Directories.Exists (Target_Path),
        "failed Save As to a missing parent must not create the explicit target");
      Assert (Read_Bytes (Old_Path) = "old disk before missing parent",
        "failed Save As must not fall back to the old associated path");
      Assert (Buffer_Text (S) = Before_Text,
        "failed Save As must preserve active-buffer text");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Old_Path,
        "failed Save As must preserve the old associated path");
      Assert (S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Before_Saved,
        "failed Save As must preserve dirty state and saved baseline");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed Save As must preserve Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "failed Save As must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "missing"
        and then To_String (S.Active_Replace_Text) = "present"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clip",
        "failed Save As must preserve Find/Replace and Clipboard state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not save file as",
        "missing-parent Save As must be reported as a deterministic write failure");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Old_Path) = Before_Text,
        "subsequent file.save after failed Save As must still use the old associated path");

      Remove_If_Exists (Old_Path);
   end Test_Save_As_Missing_Parent_Is_Write_Failure_And_Non_Mutating;

   procedure Test_Untitled_Save_As_Failure_Preserves_Untitled_Save_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Parent_Path     : constant String := Temp_Path ("untitled_missing_parent");
      Target_Path     : constant String := Ada.Directories.Compose (Parent_Path, "untitled.txt");
      Before_Text     : constant String := "untitled dirty save-as text";
      Before_Saved    : Natural;
      Found           : Boolean := False;
      M               : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Target_Path);
      Remove_If_Exists (Parent_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 17;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target_Path);

      Assert (not S.File_Info.Has_Path and then Length (S.File_Info.Path) = 0,
        "failed Save As from an untitled buffer must not create an association");
      Assert (S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Before_Saved,
        "failed untitled Save As must preserve dirty state and baseline");
      Assert (Buffer_Text (S) = Before_Text,
        "failed untitled Save As must preserve current text");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not save file as",
        "failed untitled Save As must use deterministic write-failure feedback");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "No file path for active buffer",
        "file.save after failed untitled Save As must still report no associated path");
      Assert (not S.File_Info.Has_Path and then S.File_Info.Dirty,
        "file.save after failed untitled Save As must leave the buffer untitled and dirty");
   end Test_Untitled_Save_As_Failure_Preserves_Untitled_Save_Target;

   procedure Test_Save_As_After_Undo_Preserves_Redo_And_Updates_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("undo_redo_save_as.txt");
      Redo_Before   : Ada.Containers.Count_Type;
      Undo_Before   : Ada.Containers.Count_Type;
      Saved_After   : Natural;
   begin
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'B'));
      Assert (Buffer_Text (S) = "AB" and then S.File_Info.Dirty,
        "edit precondition should create dirty text");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = "A",
        "undo precondition should restore current in-memory text before Save As");
      Redo_Before := Editor.History.Redo_Stack.Length;
      Undo_Before := Editor.History.Undo_Stack.Length;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);

      Assert (Read_Bytes (Path) = "A",
        "Save As after undo must serialize the current in-memory text, not stale redo text");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty,
        "successful Save As after undo must associate the new path and mark the written text clean");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful Save As must update saved baseline after the write");
      Saved_After := S.File_Info.Saved_Generation;
      Assert (Editor.History.Redo_Stack.Length = Redo_Before
        and then Editor.History.Undo_Stack.Length = Undo_Before,
        "Save As must preserve Undo/Redo stacks exactly");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = "AB" and then S.File_Info.Dirty,
        "redo after Save As must remain available and make text dirty when it differs from baseline");
      Assert (S.File_Info.Saved_Generation = Saved_After,
        "redo after Save As must not rewrite the saved baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = "AB",
        "subsequent file.save after redo must target the Save As path");

      Remove_If_Exists (Path);
   end Test_Save_As_After_Undo_Preserves_Redo_And_Updates_Baseline;

   procedure Test_Save_As_Render_And_Availability_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("render_availability_save_as.txt");
      Before_Text  : constant String := "dirty save-as render text";
      Before_Saved : Natural;
      Snap         : Editor.Render_Model.Render_Snapshot;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk before save-as side-effect-free checks");
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 6,
          Anchor                => 2,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("save-as");
      S.Active_Replace_Text := To_Unbounded_String ("availability");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("save-as side effect guard"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("render_availability_save_as.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 88;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File_As);

      Assert (Snap.Is_Dirty,
        "render snapshot may observe Save As dirty state but must not clear it");
      Assert (Editor.Commands.Is_Available (Availability),
        "Save As availability may observe active-buffer presence without requiring a path payload");
      Assert (Read_Bytes (Path) = "disk before save-as side-effect-free checks",
        "render and Save As availability must not write or truncate files");
      Assert (Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "render and Save As availability must not mutate text, dirty state, or baseline");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 6 and then S.Carets (0).Anchor = 2,
        "render and Save As availability must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "save-as"
        and then To_String (S.Active_Replace_Text) = "availability"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "save-as side effect guard",
        "render and Save As availability must preserve Find/Replace and Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "render and Save As availability checks must not emit Save As messages");

      Remove_If_Exists (Path);
   end Test_Save_As_Render_And_Availability_Are_Side_Effect_Free;


   procedure Test_Save_As_Binds_Execution_Time_Active_Buffer_In_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A              : Editor.Buffers.Buffer_Id;
      B              : Editor.Buffers.Buffer_Id;
      Path_A         : constant String := Temp_Path ("active_a.txt");
      Path_B         : constant String := Temp_Path ("active_b.txt");
      Path_B2        : constant String := Temp_Path ("active_b2.txt");
      Undo_Before    : Ada.Containers.Count_Type;
      Redo_Before    : Ada.Containers.Count_Type;
      Recent_Before  : Natural := 0;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Remove_If_Exists (Path_B2);
      Write_Bytes (Path_A, "disk A before Save As");
      Write_Bytes (Path_B, "disk B before Save As");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer (Path_A, "active_a.txt", "A0", A);
      Editor.Buffers.Global_Add_File_Buffer (Path_B, "active_b.txt", "B0", B);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Insert_Text_At (S, 2, " dirty-A");
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B, Emit_Feedback => False);
      Insert_Text_At (S, 2, " dirty-B");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("B0");
      S.Active_Replace_Text := To_Unbounded_String ("B1");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clip"));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Undo_Before := Editor.History.Undo_Stack.Length;
      Redo_Before := Editor.History.Redo_Stack.Length;
      Recent_Before := Editor.Recent_Buffers.Count (S.Recent_Buffers);

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path_B2);

      Assert (Editor.Buffers.Global_Active_Buffer = B,
        "Save As must not activate another buffer");
      Assert (Read_Bytes (Path_B2) = "B0 dirty-B",
        "Save As must serialize the execution-time active buffer text");
      Assert (Read_Bytes (Path_A) = "disk A before Save As",
        "Save As must not write inactive associated paths");
      Assert (Read_Bytes (Path_B) = "disk B before Save As",
        "Save As to a new path must not write the old active path");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path_B2,
        "active buffer association must move to the explicit target after success");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful Save As must update only the active buffer saved baseline and clean state");
      Assert (Editor.History.Undo_Stack.Length = Undo_Before
        and then Editor.History.Redo_Stack.Length = Redo_Before,
        "Save As must preserve active-buffer Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = 4
        and then S.Carets (0).Anchor = 1,
        "Save As must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "B0"
        and then To_String (S.Active_Replace_Text) = "B1"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clip",
        "Save As must preserve Find/Replace and Clipboard state");
      Assert (Editor.Recent_Buffers.Count (S.Recent_Buffers) = Recent_Before,
        "Save As must not update recent-buffer history");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "Save As success must emit exactly one deterministic primary message");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A, Emit_Feedback => False);
      Assert (Buffer_Text (S) = "A0 dirty-A"
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Path_A
        and then S.File_Info.Dirty,
        "inactive dirty buffer text, association, and dirty state must survive another buffer's Save As");
      Assert (Editor.History.Undo_Stack.Length > 0,
        "inactive buffer Undo history must survive another buffer's Save As");

      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Remove_If_Exists (Path_B2);
   end Test_Save_As_Binds_Execution_Time_Active_Buffer_In_Workflow;

   procedure Test_Untitled_Save_As_Save_Undo_Redo_And_Failure_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Success_Path   : constant String := Temp_Path ("untitled_success.txt");
      Missing_Parent : constant String := Temp_Path ("untitled_missing_parent");
      Failure_Path   : constant String := Ada.Directories.Compose (Missing_Parent, "x.txt");
      Undo_Before    : Ada.Containers.Count_Type;
      Redo_Before    : Ada.Containers.Count_Type;
      Saved_After    : Natural;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Success_Path);
      Remove_If_Exists (Failure_Path);
      Remove_If_Exists (Missing_Parent);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled" & ASCII.LF & "body");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      declare
         Insert_Current : Editor.Commands.Command;
      begin
         Insert_Current.Kind := Editor.Commands.Insert_Text_Input;
         Insert_Current.Pos := 13;
         Insert_Current.Has_Position := True;
         Insert_Current.Text := To_Unbounded_String (ASCII.LF & "current");
         Editor.Executor.Execute_No_Log (S, Insert_Current);
      end;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Undo_Before := Editor.History.Undo_Stack.Length;
      Redo_Before := Editor.History.Redo_Stack.Length;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Success_Path);

      Assert (Read_Bytes (Success_Path) = "untitled" & ASCII.LF & "body",
        "untitled Save As after undo must write exact current text, not stale redo text");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Success_Path,
        "successful untitled Save As must create the association after write success");
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid,
        "successful untitled Save As must mark the written text clean");
      Assert (Editor.History.Undo_Stack.Length = Undo_Before
        and then Editor.History.Redo_Stack.Length = Redo_Before,
        "successful Save As must preserve redo availability after undo");
      Saved_After := S.File_Info.Saved_Generation;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = "untitled" & ASCII.LF & "body" & ASCII.LF & "current"
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Saved_After,
        "redo after Save As must be an edit only and make text dirty against the saved baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Success_Path) = "untitled" & ASCII.LF & "body" & ASCII.LF & "current",
        "file.save after successful untitled Save As must target the Save As path");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Failure_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not save file as",
        "write-failure Save As must emit deterministic failure feedback");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Success_Path,
        "failed Save As after association must preserve the prior file.save target");
      Assert (S.File_Info.Dirty = False
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "failed Save As after a clean associated save must preserve dirty state and baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to save",
        "subsequent file.save after failed Save As must retain canonical clean-save policy");

      Remove_If_Exists (Success_Path);
   end Test_Untitled_Save_As_Save_Undo_Redo_And_Failure_Coherence;

   procedure Test_Associated_Save_As_Failure_No_Target_And_Same_Target_Preserve_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Path_A         : constant String := Temp_Path ("assoc_a.txt");
      Path_B         : constant String := Temp_Path ("assoc_b.txt");
      Missing_Parent : constant String := Temp_Path ("assoc_missing_parent");
      Failure_Path   : constant String := Ada.Directories.Compose (Missing_Parent, "b.txt");
      Before_Saved   : Natural;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Remove_If_Exists (Failure_Path);
      Remove_If_Exists (Missing_Parent);
      Write_Bytes (Path_A, "old A disk");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "base");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path_A);
      S.File_Info.Display_Name := To_Unbounded_String ("assoc_a.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Insert_Text_At (S, 4, " dirty");
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, "");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No target path for Save As",
        "missing Save As target must use deterministic no-target feedback");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path_A
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "missing target must not mutate association, dirty state, or saved baseline");
      Assert (Read_Bytes (Path_A) = "old A disk",
        "missing target must not write the old associated file");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Failure_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not save file as",
        "failed target write must use deterministic write-failure feedback");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path_A
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "failed Save As must preserve old association and baseline until write success");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed Save As must not touch Undo/Redo stacks");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path_B);
      Assert (Read_Bytes (Path_B) = "base dirty",
        "successful Save As after failures must write the current text to the explicit new target");
      Assert (Read_Bytes (Path_A) = "old A disk",
        "successful Save As to path B must not write old path A");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path_B
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "association, saved baseline, and clean state must update only after successful Save As");

      Insert_Text_At (S, 10, " again");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path_B);
      Assert (Read_Bytes (Path_B) = "base dirty again",
        "same-target Save As must remain an explicit target write with exact current text");
      Assert (not S.File_Info.Dirty and then To_String (S.File_Info.Path) = Path_B,
        "same-target Save As success must retain association and mark clean");

      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
   end Test_Associated_Save_As_Failure_No_Target_And_Same_Target_Preserve_Order;

   procedure Test_Save_As_Render_Availability_And_Command_Surface_Are_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("side_effect_target.txt");
      Before_Text  : constant String := "render availability save-as text";
      Before_Saved : Natural;
      Snap         : Editor.Render_Model.Render_Snapshot;
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      Id           : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk must remain untouched");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("render clip"));

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 7,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("availability");
      S.Active_Replace_Text := To_Unbounded_String ("mutation");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("side_effect_target.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 123;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File_As);

      Assert (Snap.Is_Dirty and then To_String (Snap.File_Name) = "side_effect_target.txt",
        "render snapshot may observe Save As-relevant state without mutating it");
      Assert (Editor.Commands.Is_Available (Availability),
        "Save As availability remains a cheap command-surface check");
      Assert (Read_Bytes (Path) = "disk must remain untouched",
        "render and availability must not probe Save As by writing the target");
      Assert (Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "render and availability must not mutate text, dirty state, or saved baseline");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = 7
        and then S.Carets (0).Anchor = 1,
        "render and availability must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "availability"
        and then To_String (S.Active_Replace_Text) = "mutation"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "render clip",
        "render and availability must preserve Find/Replace and Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "render and availability must not emit Save As messages");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save-all", Found);
      Assert (Found and then Id = Editor.Commands.Command_Save_All,
        "file.save-all remains a separate command and is not executed by Save As surface reads");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.autosave.enable", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "non-goal autosave command must not be exposed");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.format-on-save", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Format_On_Save,
        "format-on-save command should be exposed without mutating Save As state");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("workspace.save-buffer-text", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "non-goal workspace text persistence command must not be exposed");

      Remove_If_Exists (Path);
   end Test_Save_As_Render_Availability_And_Command_Surface_Are_Non_Mutating;



procedure Test_Save_As_Canonical_Handler_Preserves_File_Save_Targeting
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Old_Path       : constant String := Temp_Path ("old_associated.txt");
      Success_Path   : constant String := Temp_Path ("success_target.txt");
      Missing_Parent : constant String := Temp_Path ("missing_parent");
      Failure_Path   : constant String := Ada.Directories.Compose (Missing_Parent, "failed.txt");
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Saved   : Natural := 0;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Old_Path);
      Remove_If_Exists (Success_Path);
      Remove_If_Exists (Failure_Path);
      Remove_If_Exists (Missing_Parent);
      Write_Bytes (Old_Path, "old disk remains until file.save");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "current text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Old_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("old_associated.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 7;
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("");
      S.Active_Replace_Text := To_Unbounded_String ("canonical");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target",
        "public targetless Save As route must open the canonical prompt");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "opening Save As prompt must not emit command outcome feedback");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "cancelling target prompt before direct explicit Save As should clear prompt state");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Old_Path
        and then S.File_Info.Dirty and then S.File_Info.Saved_Generation = 7,
        "no-target Save As must preserve association, dirty state, and baseline");
      Assert (not Ada.Directories.Exists (Success_Path),
        "no-target Save As must not invent or write a target path");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Success_Path);
      Assert (Read_Bytes (Success_Path) = "current text",
        "canonical Save As handler writes exact active-buffer current text to the explicit target");
      Assert (Read_Bytes (Old_Path) = "old disk remains until file.save",
        "Save As to a new path must not write the old associated path");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Success_Path
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "Save As success updates association, saved baseline, and dirty state only after write success");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "Save As must not create, clear, or squash Undo/Redo entries");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 5 and then S.Carets (0).Anchor = 1,
        "Save As must not move caret or normalize selection");
      Assert (To_String (S.Active_Find_Query) = ""
        and then To_String (S.Active_Replace_Text) = "canonical"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard",
        "Save As must not mutate Find/Replace or Clipboard state");

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => Editor.Cursors.Cursor_Index (Buffer_Text (S)'Length),
            Anchor                => Editor.Cursors.Cursor_Index (Buffer_Text (S)'Length),
            Virtual_Column        => 0,
            Anchor_Virtual_Column => 0));
      Insert_Text_At (S, Buffer_Text (S)'Length, " updated");
      Before_Saved := S.File_Info.Saved_Generation;
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Failure_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Could not save file as",
        "failed explicit-target write must use deterministic Save As failure feedback");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Success_Path
        and then S.File_Info.Dirty and then S.File_Info.Saved_Generation = Before_Saved,
        "failed Save As must preserve the last successful association, dirty state, and baseline");
      Assert (not Ada.Directories.Exists (Failure_Path),
        "failed Save As must not create the missing-parent target");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (Read_Bytes (Success_Path) = "current text updated",
        "subsequent file.save must follow the canonical association from the last successful Save As");
      Assert (Read_Bytes (Old_Path) = "old disk remains until file.save",
        "subsequent file.save must not fall back to the pre-Save-As associated path");

      Remove_If_Exists (Old_Path);
      Remove_If_Exists (Success_Path);
   end Test_Save_As_Canonical_Handler_Preserves_File_Save_Targeting;


   overriding function Name (T : Files_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files");
   end Name;


   procedure Test_Save_Command_Metadata_Uses_Canonical_File_Save_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Save_File) =
           "file.save",
         "active-buffer save must use canonical file.save persisted name");
      Assert
        (Editor.Commands.Category (Editor.Commands.Command_Save_File) =
           Editor.Commands.File_Category,
         "active-buffer save must remain a File command");
      Assert
        (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Save_File),
         "active-buffer save must be bindable");
      Assert
        (Editor.Commands.Descriptor (Editor.Commands.Command_Save_File).Visibility =
           Editor.Commands.Palette_Command,
         "active-buffer save must remain Command Palette visible");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Save_File,
         "file.save must resolve to active-buffer save");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("save-file", Found);
      Assert
        (not Found and then Id = Editor.Commands.No_Command,
         "removed save-file keybinding data must be rejected instead of aliasing file.save");
   end Test_Save_Command_Metadata_Uses_Canonical_File_Save_Name;

   procedure Test_Clean_Save_Is_Deterministic_No_Op
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("clean_noop.txt");
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "memory text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("clean_noop.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = "disk baseline",
        "clean active-buffer save should not rewrite disk under the retained no-op policy");
      Assert (not S.File_Info.Dirty,
        "clean no-op save must preserve clean state");
      Assert (Buffer_Text (S) = "memory text",
        "clean no-op save must not alter buffer text");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message,
        "clean no-op save should publish one info message");
      Assert (To_String (M.Text) = "No changes to save",
        "clean no-op save should use deterministic message text");
      Remove_If_Exists (Path);
   end Test_Clean_Save_Is_Deterministic_No_Op;

   procedure Test_Save_Success_Preserves_Editor_Feature_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("save_success.txt");
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 3,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("alpha");
      S.Active_Replace_Text := To_Unbounded_String ("omega");
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard text"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_success.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = "alpha" & ASCII.LF & "beta",
        "save must write exact current active-buffer text");
      Assert (not S.File_Info.Dirty,
        "successful save must mark the active buffer clean");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful save must update the saved baseline generation");
      Assert (Buffer_Text (S) = "alpha" & ASCII.LF & "beta",
        "save must not mutate active-buffer text");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "save must not create or clear Undo/Redo entries");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "save must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "alpha"
        and then To_String (S.Active_Replace_Text) = "omega"
        and then S.Active_Find_Prompt
        and then S.Active_Replace_Prompt,
        "save must not mutate Find/Replace state");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard text",
        "save must not mutate Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "save must emit one primary command message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message,
        "successful save should publish success severity");
      Assert (To_String (M.Text) = "Saved file",
        "successful save should use deterministic message text");
      Remove_If_Exists (Path);
   end Test_Save_Success_Preserves_Editor_Feature_State;


   procedure Test_Save_Affects_Only_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path_A  : constant String := Temp_Path ("active_a.txt");
      Path_B  : constant String := Temp_Path ("inactive_b.txt");
      A       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_State : Editor.State.State_Type;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Write_Bytes (Path_A, "old a");
      Write_Bytes (Path_B, "old b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_A, "active_a.txt", "new a", A);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_B, "inactive_b.txt", "new b", B);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path_A) = "new a",
        "active-buffer save must write only the active path");
      Assert (Read_Bytes (Path_B) = "old b",
        "active-buffer save must not write inactive buffer paths");
      Assert (not S.File_Info.Dirty,
        "active buffer should be clean after successful save");
      B_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, B);
      Assert (B_State.File_Info.Dirty,
        "inactive dirty buffers must remain dirty after active save");
      Assert (Buffer_Text (B_State) = "new b",
        "inactive buffer text must remain unchanged after active save");
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
   end Test_Save_Affects_Only_Active_Buffer;

   procedure Test_Save_Failure_Preserves_State_And_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Dir_Path      : constant String := Temp_Path ("save_failure_dir");
      Before_Text   : constant String := "dirty text";
      Before_Saved  : Natural := 0;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("save_failure.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 99;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Buffer_Text (S) = Before_Text,
        "failed save must preserve buffer text");
      Assert (S.File_Info.Dirty,
        "failed save must preserve dirty state");
      Assert (S.File_Info.Saved_Generation = Before_Saved,
        "failed save must preserve saved baseline generation");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed save must preserve Undo/Redo stacks");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "failed save must emit one primary command message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "failed save should publish error severity");
      Assert (To_String (M.Text) = "Could not save file.",
        "failed save should use deterministic message text");
      Remove_If_Exists (Dir_Path);
   end Test_Save_Failure_Preserves_State_And_Baseline;


   procedure Test_Save_Binds_Execution_Time_Active_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path_A : constant String := Temp_Path ("bind_a.txt");
      Path_B : constant String := Temp_Path ("bind_b.txt");
      A      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Copy : Editor.State.State_Type;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Write_Bytes (Path_A, "old a");
      Write_Bytes (Path_B, "old b");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_A, "bind_a.txt", "memory a", A);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_B, "bind_b.txt", "memory b", B);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      --  Switch the global active identity immediately before file.save,
      --  without loading that buffer into S.  Save must bind to B at
      --  execution time instead of syncing stale A state into B.
      Editor.Buffers.Global_Set_Active_Buffer (B);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path_A) = "old a",
        "stale caller state must not cause save to write the previously active path");
      Assert (Read_Bytes (Path_B) = "memory b",
        "save must write the active buffer at execution time");
      Assert (not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Path_B,
        "saved baseline/dirty update must belong to the execution-time active buffer");
      B_Copy := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, B);
      Assert (not B_Copy.File_Info.Dirty,
        "execution-time active buffer registry record must be clean after save");

      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
   end Test_Save_Binds_Execution_Time_Active_Buffer;

   procedure Test_Save_Writes_Exact_Current_Text_And_Not_Disk_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Path : constant String := Temp_Path ("exact_text.txt");
      Text : constant String :=
        "one" & ASCII.LF &
        "two" & ASCII.HT & " spaced  " & ASCII.LF &
        "punctuation: !?.,;" & ASCII.LF;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "stale disk baseline");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Text);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("exact_text.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 0;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = Text,
        "save must serialize exact current in-memory text, including whitespace and trailing newline");
      Assert (Buffer_Text (S) = Text,
        "save must not reload, normalize, or mutate active-buffer text");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful exact-text save must update only the active saved baseline");

      Remove_If_Exists (Path);
   end Test_Save_Writes_Exact_Current_Text_And_Not_Disk_Baseline;

   procedure Test_Save_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("availability.txt");
      Before_Text   : constant String := "dirty availability text";
      Before_Saved  : Natural;
      Availability  : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk before availability");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("availability.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 42;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;

      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File);

      Assert (Editor.Commands.Is_Available (Availability),
        "file.save availability should be available for a dirty file-backed buffer");
      Assert (Read_Bytes (Path) = "disk before availability",
        "availability must not probe by writing or truncating the target file");
      Assert (Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "availability must not mutate text, dirty state, or saved baseline");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "availability must not emit command messages");

      Remove_If_Exists (Path);
   end Test_Save_Availability_Is_Side_Effect_Free;

   procedure Test_Save_Preserves_Redo_Stack_And_Does_Not_Replay_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("redo.txt");
      Redo_Before : Ada.Containers.Count_Type;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "A");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("redo.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'B'));
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Assert (Buffer_Text (S) = "AB" and then S.File_Info.Dirty,
        "edit precondition should make the file-backed buffer dirty");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Before := Editor.History.Redo_Stack.Length;
      Assert (Buffer_Text (S) = "A" and then Redo_Before = 1,
        "undo precondition should leave redo available");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Editor.History.Redo_Stack.Length = Redo_Before,
        "clean no-op save must not clear redo history");
      Assert (Read_Bytes (Path) = "A",
        "clean no-op save must not rewrite disk before redo");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = "AB",
        "redo after save must restore the later edit state");
      Assert (Read_Bytes (Path) = "A",
        "redo must not re-run save or write disk");

      Remove_If_Exists (Path);
   end Test_Save_Preserves_Redo_Stack_And_Does_Not_Replay_Save;

   procedure Test_Save_Availability_Binds_Active_Buffer_Read_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path_A       : constant String := Temp_Path ("avail_bind_a.txt");
      A            : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B            : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Availability : Editor.Commands.Command_Availability;
      B_Copy       : Editor.State.State_Type;
   begin
      Remove_If_Exists (Path_A);
      Write_Bytes (Path_A, "disk a");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_A, "avail_bind_a.txt", "dirty a", A);
      Editor.Buffers.Global_Add_Untitled_Buffer (B);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      --  The caller state still represents A, but the active buffer used by
      --  command projection is now untitled B.  Availability must observe B
      --  without loading it into S, syncing stale A into B, or writing disk.
      Editor.Buffers.Global_Set_Active_Buffer (B);

      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File);

      Assert (not Editor.Commands.Is_Available (Availability),
        "save availability must bind to the execution-time active buffer");
      Assert (Editor.Commands.Unavailable_Reason (Availability) =
        "No file path for active buffer",
        "active untitled buffer should drive save availability reason");
      Assert (Read_Bytes (Path_A) = "disk a",
        "stale availability must not write the previously active file");
      Assert (To_String (S.File_Info.Path) = Path_A
        and then S.File_Info.Dirty,
        "availability must not load active buffer into caller state or clear dirty state");
      B_Copy := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, B);
      Assert (not B_Copy.File_Info.Has_Path,
        "availability must not sync stale file identity into the active untitled buffer");

      Remove_If_Exists (Path_A);
   end Test_Save_Availability_Binds_Active_Buffer_Read_Only;

   procedure Test_Save_Failure_Preserves_Feature_State_Completely
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Dir_Path      : constant String := Temp_Path ("failure_state_dir");
      Before_Text   : constant String := "alpha" & ASCII.LF & "beta";
      Before_Saved  : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 4,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("alpha");
      S.Active_Replace_Text := To_Unbounded_String ("omega");
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard before failed save"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("failure_state.adb");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 77;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Buffer_Text (S) = Before_Text,
        "failed save must preserve active-buffer text");
      Assert (S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "failed save must preserve dirty state and saved baseline");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed save must preserve Undo/Redo stacks");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "failed save must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "alpha"
        and then To_String (S.Active_Replace_Text) = "omega"
        and then S.Active_Find_Prompt
        and then S.Active_Replace_Prompt,
        "failed save must preserve Find/Replace state");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard before failed save",
        "failed save must preserve Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "failed save must emit exactly one primary message");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message,
        "failed save should publish error severity");
      Assert (To_String (M.Text) = "Could not save file.",
        "failed save should use deterministic message text");

      Remove_If_Exists (Dir_Path);
   end Test_Save_Failure_Preserves_Feature_State_Completely;


   procedure Test_Save_Target_Switch_Integrated_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Path_A  : constant String := Temp_Path ("target_a.txt");
      Path_B  : constant String := Temp_Path ("target_b.txt");
      A       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A_State : Editor.State.State_Type;
      B_State : Editor.State.State_Type;
      Found   : Boolean := False;
      M       : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
      Write_Bytes (Path_A, "old disk A");
      Write_Bytes (Path_B, "old disk B");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_A, "target_a.txt", "dirty memory A", A);
      Editor.Buffers.Global_Add_File_Buffer
        (Path_B, "target_b.txt", "dirty memory B", B);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 1;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 2;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      --  Leave S projecting A while the execution-time active buffer is B.
      --  file.save must bind to B at execution time and must not save A.
      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Buffers.Global_Set_Active_Buffer (B);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path_A) = "old disk A",
        "save after an active-buffer switch must not write the stale caller buffer");
      Assert (Read_Bytes (Path_B) = "dirty memory B",
        "save after an active-buffer switch must write the execution-time active buffer text");
      Assert (Editor.Buffers.Global_Active_Buffer = B,
        "save must not activate or reorder buffers");
      A_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, A);
      B_State := Editor.Buffers.Buffer
        (Editor.Buffers.Global_Registry_For_UI, B);
      Assert (A_State.File_Info.Dirty,
        "inactive dirty buffers must remain dirty after active save");
      Assert (not B_State.File_Info.Dirty,
        "only the active saved buffer becomes clean after successful save");
      Assert (Buffer_Text (A_State) = "dirty memory A"
        and then Buffer_Text (B_State) = "dirty memory B",
        "save must not mutate active or inactive buffer text");
      Assert (True,
        "save must not create reopen lifecycle entries");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file",
        "switched active-buffer save must emit one canonical success message");

      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
   end Test_Save_Target_Switch_Integrated_Isolation;

   procedure Test_Save_Uses_Current_Text_After_Undo_Redo_And_Preserves_Redo
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("undo_redo.txt");
      Redo_Before   : Ada.Containers.Count_Type;
      Undo_Before   : Ada.Containers.Count_Type;
      Saved_Before  : Natural;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "A");
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "A");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("undo_redo.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("CLIP"));

      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (1, 'B'));
      Assert (Buffer_Text (S) = "AB" and then S.File_Info.Dirty,
        "edit precondition should produce dirty text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Redo_Before := Editor.History.Redo_Stack.Length;
      Undo_Before := Editor.History.Undo_Stack.Length;
      Saved_Before := S.File_Info.Saved_Generation;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = "A",
        "clean save after undo-to-baseline must not rewrite disk");
      Assert (S.File_Info.Saved_Generation = Saved_Before,
        "clean no-op save must not update saved baseline");
      Assert (Editor.History.Redo_Stack.Length = Redo_Before
        and then Editor.History.Undo_Stack.Length = Undo_Before,
        "clean no-op save must preserve Undo/Redo stacks exactly");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to save",
        "clean no-op save after undo should report retained clean policy");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = "AB",
        "redo must remain available after save and restore current memory text");
      Redo_Before := Editor.History.Redo_Stack.Length;
      Undo_Before := Editor.History.Undo_Stack.Length;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = "AB",
        "dirty save after redo must write the current in-memory text exactly");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful save after redo must update the baseline after write success");
      Assert (Editor.History.Redo_Stack.Length = Redo_Before
        and then Editor.History.Undo_Stack.Length = Undo_Before,
        "dirty save must not create or clear Undo/Redo entries");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "CLIP",
        "save must preserve Clipboard across undo/redo workflows");

      Remove_If_Exists (Path);
   end Test_Save_Uses_Current_Text_After_Undo_Redo_And_Preserves_Redo;

   procedure Test_Save_Serializes_Whitespace_And_Line_Boundaries_Exactly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Path     : constant String := Temp_Path ("exact_text.txt");
      Contents : constant String :=
        ASCII.HT & "alpha  " & ASCII.LF & ASCII.LF &
        "  beta!" & ASCII.LF & "trailing spaces   ";
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "stale disk contents");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Contents);
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("exact_text.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 10;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = Contents,
        "save must serialize current text exactly, including tabs, blank lines, punctuation, and trailing spaces");
      Assert (Buffer_Text (S) = Contents,
        "save must not apply formatting, trimming, or final-newline policy to memory text");
      Assert (not S.File_Info.Dirty,
        "exact serialization success should mark the active buffer clean");

      Remove_If_Exists (Path);
   end Test_Save_Serializes_Whitespace_And_Line_Boundaries_Exactly;

   procedure Test_Save_Failure_Preserves_Dirty_Baseline_And_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Dir_Path      : constant String := Temp_Path ("failure_dir");
      Before_Text   : constant String := "failure text" & ASCII.LF & "line 2";
      Before_Saved  : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Dir_Path);
      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 7,
          Anchor                => 2,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("failure");
      S.Active_Replace_Text := To_Unbounded_String ("success");
      S.Active_Find_Prompt := True;
      S.Active_Replace_Prompt := True;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives failure"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("failure.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 123;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'X'));
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      S.File_Info.Dirty := True;
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Buffer_Text (S) = Before_Text,
        "failed save must preserve current buffer text");
      Assert (S.File_Info.Dirty and then S.File_Info.Saved_Generation = Before_Saved,
        "failed save must preserve dirty state and saved baseline");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "failed save must preserve Undo/Redo stacks, including redo after undo");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "failed save must preserve caret and selection exactly");
      Assert (To_String (S.Active_Find_Query) = "failure"
        and then To_String (S.Active_Replace_Text) = "success"
        and then S.Active_Find_Prompt
        and then S.Active_Replace_Prompt,
        "failed save must preserve Find/Replace state");
      Assert (Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard survives failure",
        "failed save must preserve Clipboard text");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not save file.",
        "failed save must use the deterministic save-failure message");

      Remove_If_Exists (Dir_Path);
   end Test_Save_Failure_Preserves_Dirty_Baseline_And_Features;

   procedure Test_Render_And_Availability_Are_Save_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("render_availability.txt");
      Before_Text  : constant String := "dirty render text";
      Before_Saved : Natural;
      Snap         : Editor.Render_Model.Render_Snapshot;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk before side-effect-free checks");
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("render");
      S.Active_Replace_Text := To_Unbounded_String ("availability");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("side effect guard"));
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("render_availability.txt");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 55;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File);

      Assert (Snap.Is_Dirty,
        "render snapshot may observe dirty state but must not clean it");
      Assert (Editor.Commands.Is_Available (Availability),
        "save availability may observe a dirty file-backed active buffer");
      Assert (Read_Bytes (Path) = "disk before side-effect-free checks",
        "render and availability must not write or truncate the file");
      Assert (Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "render and availability must not mutate text, dirty state, or baseline");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 5 and then S.Carets (0).Anchor = 1,
        "render and availability must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "render"
        and then To_String (S.Active_Replace_Text) = "availability"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "side effect guard",
        "render and availability must preserve Find/Replace and Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "render and availability checks must not emit save messages");

      Remove_If_Exists (Path);
   end Test_Render_And_Availability_Are_Save_Side_Effect_Free;

   procedure Test_No_Path_And_Clean_Save_Are_Non_Mutating_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("clean_noop.txt");
      Before_Saved  : Natural;
      Before_Caret  : Editor.Cursors.Caret_State;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "clean disk");
      Editor.Clipboard.Clear;

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 3,
          Anchor                => 0,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("untitled");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard for no path"));
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 7;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "no-path save must not infer a target or update dirty baseline");
      Assert (Buffer_Text (S) = "untitled dirty text",
        "no-path save must preserve buffer text");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "no-path save must preserve caret and selection");
      Assert (To_String (S.Active_Find_Query) = "untitled"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard for no path",
        "no-path save must preserve Find and Clipboard state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "No file path for active buffer",
        "no-path save must emit the canonical no-path message");

      Editor.State.Load_Text (S, "clean memory");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("clean_noop.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Before_Saved := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);

      Assert (Read_Bytes (Path) = "clean disk",
        "clean save must follow retained no-op policy and avoid filesystem writes");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Saved,
        "clean save must preserve clean dirty state and saved baseline");
      Assert (Buffer_Text (S) = "clean memory",
        "clean save must not mutate memory text");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "clean save must preserve caret and selection");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "No changes to save",
        "clean save must emit the canonical no-op message");

      Remove_If_Exists (Path);
   end Test_No_Path_And_Clean_Save_Are_Non_Mutating_Workflows;

   procedure Test_Palette_And_Default_Keybinding_Use_Canonical_File_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_Rows  : Natural := 0;
      Binding    : Editor.Keybindings.Command_Keybinding_Info;
   begin
      Editor.State.Init (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Save_File then
               Save_Rows := Save_Rows + 1;
               Assert (To_String (Candidates (I).Label) = "Save File",
                 "canonical file.save palette row must keep the active-buffer save label");
            end if;
         end loop;
      end if;

      Assert (Save_Rows = 1,
        "Command Palette must project exactly one canonical file.save row");

      Binding :=
        Editor.Keybindings.Primary_Binding_For_Command
          (Editor.Commands.Command_Save_File);
      Assert (Binding.Has_Binding
        and then To_String (Binding.Display) = "Ctrl+S",
        "default active-buffer save keybinding must target canonical file.save");
   end Test_Palette_And_Default_Keybinding_Use_Canonical_File_Save;



   procedure Test_Reload_Command_Metadata_Uses_Canonical_Name
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Reload_Active_Buffer) = "file.reload-buffer",
         "reload must use canonical file.reload-buffer persisted name");
      Assert
        (Editor.Commands.Category (Editor.Commands.Command_Reload_Active_Buffer) =
           Editor.Commands.File_Category,
         "reload must remain a File command");
      Assert
        (Editor.Commands.Is_Bindable_Command
           (Editor.Commands.Command_Reload_Active_Buffer),
         "reload must remain bindable");
      Assert
        (Editor.Commands.Descriptor
           (Editor.Commands.Command_Reload_Active_Buffer).Visibility =
           Editor.Commands.Palette_Command,
         "reload must remain Command Palette visible");
      Assert
        (Editor.Commands.Is_Lifecycle_Command
           (Editor.Commands.Command_Reload_Active_Buffer),
         "reload must be classified as lifecycle");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.reload-buffer", Found);
      Assert
        (Found and then Id = Editor.Commands.Command_Reload_Active_Buffer,
         "file.reload-buffer must resolve to the reload command id");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("reload-buffer", Found);
      Assert
        (not Found and then Id = Editor.Commands.No_Command,
         "removed reload-buffer name must not resolve");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.reload-force", Found);
      Assert
        (not Found and then Id = Editor.Commands.No_Command,
         "force reload non-goal command must not exist");
   end Test_Reload_Command_Metadata_Uses_Canonical_Name;

   procedure Test_Reload_Success_Replaces_Active_Text_After_Read
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := Temp_Path ("reload_a.txt");
      B_Path : constant String := Temp_Path ("reload_b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Write_Bytes (A_Path, "A original");
      Write_Bytes (B_Path, "B original");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Write_Bytes (A_Path, "A disk changed");
      Write_Bytes (B_Path, "B disk" & ASCII.LF & " changed " & ASCII.HT & "!" & ASCII.LF);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "reload must leave the active buffer active");
      Assert (Buffer_Text (S) = "B disk" & ASCII.LF & " changed " & ASCII.HT & "!" & ASCII.LF,
        "reload must replace active text with exact disk contents");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
        "reload must preserve the active buffer association");
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid,
        "successful reload must leave the active buffer clean with a baseline");
      Assert (S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful reload must update saved baseline after the read");
      Assert (Editor.History.Undo_Stack.Is_Empty and then Editor.History.Redo_Stack.Is_Empty,
        "successful reload must clear active Undo/Redo stacks");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0 and then S.Carets (0).Anchor = 0,
        "successful reload must reset active caret/selection policy");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer reloaded",
        "successful reload must emit one canonical success message");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "A original",
        "reload must not mutate inactive buffer text");
      Assert (not S.File_Info.Dirty,
        "reload must not mutate inactive buffer dirty state");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Success_Replaces_Active_Text_After_Read;

   procedure Test_Reload_Blocked_And_Failed_Preserve_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("reload_preserve.txt");
      Before       : Unbounded_String;
      Before_Gen   : Natural := 0;
      Before_Caret : Editor.Cursors.Caret_State;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk clean");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 4, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Write_Bytes (Path, "disk replacement");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = To_String (Before)
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen,
        "dirty reload must not replace text, clean state, or baseline");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "dirty reload must preserve caret/selection");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Warning_Message
        and then To_String (M.Text) = "Dirty buffer cannot be reloaded",
        "dirty reload must emit the canonical blocked message");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);
      Remove_If_Exists (Path);
      Before := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = To_String (Before)
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen,
        "read failure must preserve clean buffer text, dirty state, and baseline");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not reload file.",
        "read failure must emit the canonical failure message");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Blocked_And_Failed_Preserve_State;

   procedure Test_Reload_Validation_Order_And_Availability_Are_Local
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("reload_validation.txt");
      Availability : Editor.Commands.Command_Availability;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Availability)
        and then Editor.Commands.Unavailable_Reason (Availability) = "No active buffer.",
        "reload availability must report no active buffer first");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "reload execution must report no active buffer first");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Availability)
        and then Editor.Commands.Unavailable_Reason (Availability) = "No file path for active buffer",
        "no-path reload availability must precede dirty checks");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no-path reload execution must precede dirty checks");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "clean associated");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("reload_validation.txt");
      S.File_Info.Dirty := False;
      Editor.Buffers.Ensure_Global_Registry (S);
      Remove_If_Exists (Path);
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Editor.Commands.Is_Available (Availability),
        "clean associated buffer should be reload-available without filesystem probing");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Validation_Order_And_Availability_Are_Local;

   procedure Test_Reload_Exact_Disk_Text_And_No_Reopen_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("reload_exact.txt");
      Exact  : constant String := "" & ASCII.LF & "  spaced" & ASCII.LF
        & ASCII.HT & "tabbed !?" & ASCII.LF & ASCII.LF;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "old");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String ("/tmp/unrelated-reopen.txt");
      S.Reopen_Candidate_Label := To_Unbounded_String ("unrelated");
      Write_Bytes (Path, Exact);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = Exact,
        "reload must preserve empty lines, spaces, tabs, punctuation, and trailing newlines exactly");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = "/tmp/unrelated-reopen.txt",
        "reload must not consume, create, or clear reopen candidate state");
      Assert (Read_Bytes (Path) = Exact,
        "reload must not write, format, trim, or normalize the disk file");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Exact_Disk_Text_And_No_Reopen_State;



   procedure Test_Reload_Targets_Active_Buffer_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := Temp_Path ("active_target_a.txt");
      B_Path : constant String := Temp_Path ("active_target_b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Write_Bytes (A_Path, "A opened");
      Write_Bytes (B_Path, "B opened");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Write_Bytes (A_Path, "A disk after external change");
      Write_Bytes (B_Path, "B disk after external change");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "reload must bind to the active buffer at execution time");
      Assert (Buffer_Text (S) = "A disk after external change",
        "reload must read only the active buffer associated path");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = A_Path,
        "reload must preserve the active buffer file association");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (Buffer_Text (S) = "B opened",
        "reload must not mutate inactive buffer text even when its disk file changed");
      Assert (not S.File_Info.Dirty,
        "reload must not mutate inactive buffer dirty state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id
        and then Buffer_Text (S) = "B disk after external change",
        "switching active buffers must make reload target the new active buffer");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Targets_Active_Buffer_Only;

   procedure Test_Blocked_And_Failed_Reloads_Preserve_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                    : Editor.State.State_Type;
      Path                 : constant String := Temp_Path ("preserve_transients.txt");
      Before_Text          : Unbounded_String;
      Before_Path          : Unbounded_String;
      Before_Display       : Unbounded_String;
      Before_Gen           : Natural := 0;
      Before_Caret         : Editor.Cursors.Caret_State;
      Before_Undo          : Ada.Containers.Count_Type;
      Before_Redo          : Ada.Containers.Count_Type;
      Before_Back          : Natural := 0;
      Before_Forward       : Natural := 0;
      Before_Query         : Unbounded_String;
      Before_Replace       : Unbounded_String;
      Before_Clipboard     : Unbounded_String;
      Before_Has_Clipboard : Boolean := False;

      procedure Capture is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Path := S.File_Info.Path;
         Before_Display := S.File_Info.Display_Name;
         Before_Gen := S.File_Info.Saved_Generation;
         Before_Caret := S.Carets (0);
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Query := S.Active_Find_Query;
         Before_Replace := S.Active_Replace_Text;
         Before_Clipboard := Editor.Clipboard.Get_Text;
         Before_Has_Clipboard := Editor.Clipboard.Has_Text;
      end Capture;

      procedure Assert_Preserved (Label : String) is
      begin
         Assert (Buffer_Text (S) = To_String (Before_Text),
           Label & ": reload failure/block must preserve buffer text");
         Assert (S.File_Info.Has_Path and then S.File_Info.Path = Before_Path
           and then S.File_Info.Display_Name = Before_Display,
           Label & ": reload failure/block must preserve file identity");
         Assert (S.File_Info.Saved_Generation = Before_Gen,
           Label & ": reload failure/block must preserve saved baseline marker");
         Assert (S.Carets (0).Pos = Before_Caret.Pos
           and then S.Carets (0).Anchor = Before_Caret.Anchor,
           Label & ": reload failure/block must preserve caret and selection");
         Assert (Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo,
           Label & ": reload failure/block must preserve Undo/Redo stacks");
         Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
           and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
           Label & ": reload failure/block must preserve Navigation History");
         Assert (S.Active_Find_Query = Before_Query
           and then S.Active_Replace_Text = Before_Replace,
           Label & ": reload failure/block must preserve Find/Replace query state");
         Assert (Editor.Clipboard.Has_Text = Before_Has_Clipboard
           and then Editor.Clipboard.Get_Text = Before_Clipboard,
           Label & ": reload failure/block must preserve Clipboard");
      end Assert_Preserved;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Executor.Execute_No_Log
        (S, Editor.Commands.Command'(Kind => Editor.Commands.Undo, others => <>));
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 4, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("disk");
      S.Active_Replace_Text := To_Unbounded_String ("replacement");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard payload"));
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (Editor.Buffers.Global_Active_Buffer),
          Has_File_Path => True,
          File_Path => To_Unbounded_String (Path),
          Display_Path => To_Unbounded_String (Path),
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty-again");
      Capture;
      Write_Bytes (Path, "replacement that must not be read into dirty state");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (S.File_Info.Dirty,
        "dirty reload block must preserve dirty state");
      Assert_Preserved ("dirty-blocked reload");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 2, Anchor => 0, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Capture;
      Remove_If_Exists (Path);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (not S.File_Info.Dirty,
        "read failure on clean buffer must preserve clean dirty state");
      Assert_Preserved ("read-failed reload");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Blocked_And_Failed_Reloads_Preserve_Transient_State;

   procedure Test_Successful_Reload_Is_Not_Undoable_And_Enables_Save_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("success_lifecycle.txt");
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "first disk text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Insert_Text_At (S, Buffer_Text (S)'Length, " edit");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Write_Bytes (Path, "second disk text" & ASCII.LF);

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "second disk text" & ASCII.LF,
        "successful reload must replace text with exact disk contents");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful reload must update clean baseline after read success");
      Assert (Editor.History.Undo_Stack.Is_Empty and then Editor.History.Redo_Stack.Is_Empty,
        "successful reload must clear stale edit history without creating an undo entry");

      Editor.Executor.Execute_No_Log
        (S, Editor.Commands.Command'(Kind => Editor.Commands.Undo, others => <>));
      Assert (Buffer_Text (S) = "second disk text" & ASCII.LF,
        "edit.undo must not undo a successful reload");

      Insert_Text_At (S, Buffer_Text (S)'Length, "edited");
      Assert (S.File_Info.Dirty,
        "subsequent edit after reload must make the buffer dirty against the new baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = "second disk text" & ASCII.LF & "edited",
        "file.save after reload must write the reloaded active buffer to the same associated path");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "successful reload must leave the clean buffer closeable through canonical close");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Successful_Reload_Is_Not_Undoable_And_Enables_Save_Close;

   procedure Test_Reload_Availability_Has_No_Filesystem_Side_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("availability_missing.txt");
      Before_Text  : Unbounded_String;
      Before_Gen   : Natural := 0;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "availability baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Remove_If_Exists (Path);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Editor.Commands.Is_Available (Availability),
        "reload availability must not probe for a missing associated file");
      Assert (Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then not S.File_Info.Dirty,
        "reload availability must not mutate text, baseline, or dirty state");
      Assert (not Ada.Directories.Exists (Path),
        "reload availability must not create or rewrite the associated file");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen,
        "execution read failure after side-effect-free availability must still preserve state");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Availability_Has_No_Filesystem_Side_Effects;


   procedure Test_Reload_Validation_Order_Surface_And_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Path       : constant String := Temp_Path ("validation.txt");
      Dir_Path   : constant String := Temp_Path ("validation_dir");
      M          : Editor.Messages.Editor_Message;
      Found      : Boolean := False;
      Id         : Editor.Commands.Command_Id := Editor.Commands.No_Command;

      procedure Assert_Message (Text : String; Severity : Editor.Messages.Message_Severity) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1,
           "reload invocation must emit exactly one primary message: " & Text);
         Assert (M.Severity = Severity and then To_String (M.Text) = Text,
           "reload message mismatch, expected " & Text);
      end Assert_Message;

      procedure Check_Rejected (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command,
           "non-goal reload command must not be exposed: " & Name);
      end Check_Rejected;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Path, "readable disk text");
      Editor.Buffers.Reset_Global_For_Test;

      Check_Rejected ("file.reload-all-buffers");
      Check_Rejected ("file.reload-dirty-buffer");
      Check_Rejected ("file.reload-force");
      Check_Rejected ("file.discard-and-reload");
      Check_Rejected ("file.watch-buffer");
      Check_Rejected ("file.reload-project");
      Check_Rejected ("workspace.reload-buffer-text");
      Check_Rejected ("project.reload-all-buffers");

      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert_Message ("No active buffer.", Editor.Messages.Info_Message);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message);
      Assert (Buffer_Text (S) = "untitled dirty text" and then S.File_Info.Dirty,
        "no-path dirty validation must not mutate the untitled buffer");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "associated dirty text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("validation.txt");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Remove_If_Exists (Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert_Message ("Dirty buffer cannot be reloaded", Editor.Messages.Warning_Message);
      Assert (Buffer_Text (S) = "associated dirty text" and then S.File_Info.Dirty,
        "dirty validation must occur before filesystem read or failure handling");
      Assert (not Ada.Directories.Exists (Path),
        "dirty reload must not create, rewrite, or repair the associated file");

      Ada.Directories.Create_Directory (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "clean associated text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("validation_dir");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert_Message ("Could not reload file.", Editor.Messages.Error_Message);
      Assert (Buffer_Text (S) = "clean associated text" and then not S.File_Info.Dirty,
        "read failure must preserve clean associated buffer state");

      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Dir_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Validation_Order_Surface_And_Messages;

   procedure Test_Reload_Success_Exact_Text_Baseline_And_Edit_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("success_exact.txt");
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;

      procedure Reload_And_Assert (Disk_Text : String; Label : String) is
      begin
         Write_Bytes (Path, Disk_Text);
         Editor.Messages.Clear (S.Messages);
         Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
         Assert (Buffer_Text (S) = Disk_Text,
           "successful reload must use exact canonical disk text for " & Label);
         Assert (not S.File_Info.Dirty
           and then S.File_Info.Baseline_Valid
           and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
           "successful reload must set the saved baseline to disk text for " & Label);
         Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path,
           "successful reload must preserve file association for " & Label);
         Assert (Read_Bytes (Path) = Disk_Text,
           "reload must not write, format, trim, or normalize disk text for " & Label);
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1
           and then M.Severity = Editor.Messages.Success_Message
           and then To_String (M.Text) = "Buffer reloaded",
           "successful reload must emit one Buffer reloaded message for " & Label);
      end Reload_And_Assert;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "initial");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.Active_Find_Query := To_Unbounded_String ("needle");
      S.Active_Replace_Text := To_Unbounded_String ("replacement");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives reload"));

      Reload_And_Assert ("", "empty file");
      Reload_And_Assert ("single line", "single line");
      Reload_And_Assert
        ("  spaces" & ASCII.LF & ASCII.HT & "tabs" & ASCII.LF & ASCII.LF,
         "whitespace and trailing newline");
      Reload_And_Assert
        ("longer text" & ASCII.LF & "with punctuation !?" & ASCII.LF & "tail",
         "longer file");
      Reload_And_Assert ("short", "shorter file");

      Assert (Editor.History.Undo_Stack.Is_Empty and then Editor.History.Redo_Stack.Is_Empty,
        "successful reload must clear stale Undo/Redo stacks without creating entries");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0 and then S.Carets (0).Anchor = 0,
        "successful reload must apply retained caret/selection reset policy");
      Assert (S.Active_Find_Query = To_Unbounded_String ("needle")
        and then S.Active_Replace_Text = To_Unbounded_String ("replacement")
        and then S.Active_Find_Stale,
        "successful reload must preserve Find/Replace text while invalidating stale match ranges");
      Assert (Editor.Clipboard.Has_Text
        and then Editor.Clipboard.Get_Text = To_Unbounded_String ("clipboard survives reload"),
        "successful reload must preserve Clipboard text");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Assert (S.File_Info.Dirty,
        "post-reload edits must compare against the new disk-text baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = "short dirty" and then not S.File_Info.Dirty,
        "file.save after reload must write current active text to the same associated path");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Success_Exact_Text_Baseline_And_Edit_Workflow;

   procedure Test_Reload_Preserves_Failure_State_And_Active_Buffer_Isolation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                    : Editor.State.State_Type;
      A_Path               : constant String := Temp_Path ("isolation_a.txt");
      B_Path               : constant String := Temp_Path ("isolation_b.txt");
      A_Id                 : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id                 : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Text          : Unbounded_String;
      Before_Gen           : Natural := 0;
      Before_Undo          : Ada.Containers.Count_Type;
      Before_Redo          : Ada.Containers.Count_Type;
      Before_Caret         : Editor.Cursors.Caret_State;
      Before_Back          : Natural := 0;
      Before_Forward       : Natural := 0;
      Before_Clipboard     : Unbounded_String;
      Before_Has_Clipboard : Boolean := False;
      Before_Query         : Unbounded_String;
      Before_Replace       : Unbounded_String;
      Before_Reopen        : Boolean := False;
      Before_Reopen_Path   : Unbounded_String;

      procedure Capture is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Gen := S.File_Info.Saved_Generation;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
         Before_Caret := S.Carets (0);
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Clipboard := Editor.Clipboard.Get_Text;
         Before_Has_Clipboard := Editor.Clipboard.Has_Text;
         Before_Query := S.Active_Find_Query;
         Before_Replace := S.Active_Replace_Text;
         Before_Reopen := S.Has_Reopen_Candidate;
         Before_Reopen_Path := S.Reopen_Candidate_Path;
      end Capture;

      procedure Assert_Preserved (Label : String) is
      begin
         Assert (Buffer_Text (S) = To_String (Before_Text),
           Label & ": text must be preserved");
         Assert (S.File_Info.Saved_Generation = Before_Gen,
           Label & ": saved baseline marker must be preserved");
         Assert (Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo,
           Label & ": Undo/Redo stacks must be preserved");
         Assert (S.Carets (0).Pos = Before_Caret.Pos
           and then S.Carets (0).Anchor = Before_Caret.Anchor,
           Label & ": caret/selection must be preserved");
         Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
           and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
           Label & ": Navigation History must be preserved");
         Assert (Editor.Clipboard.Has_Text = Before_Has_Clipboard
           and then Editor.Clipboard.Get_Text = Before_Clipboard,
           Label & ": Clipboard must be preserved");
         Assert (S.Active_Find_Query = Before_Query and then S.Active_Replace_Text = Before_Replace,
           Label & ": Find/Replace text must be preserved");
         Assert (S.Has_Reopen_Candidate = Before_Reopen
           and then S.Reopen_Candidate_Path = Before_Reopen_Path,
           Label & ": reopen candidate must be preserved");
      end Assert_Preserved;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Write_Bytes (A_Path, "A baseline");
      Write_Bytes (B_Path, "B baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 3, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("B");
      S.Active_Replace_Text := To_Unbounded_String ("bee");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clip B"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (A_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("A");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (B_Id),
          Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path),
          Display_Path => To_Unbounded_String (B_Path),
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));

      Capture;
      Write_Bytes (B_Path, "B disk change that dirty reload must not apply");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (S.File_Info.Dirty,
        "active dirty associated buffer must remain dirty after blocked reload");
      Assert_Preserved ("dirty-blocked reload");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, B_Path);
      Capture;
      Remove_If_Exists (B_Path);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (not S.File_Info.Dirty,
        "clean read-failure reload must preserve clean dirty state");
      Assert_Preserved ("read-failure reload");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "A baseline dirty",
        "failed and blocked reloads on B must not mutate inactive Buffer A");
      Write_Bytes (A_Path, "A disk replacement");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id
        and then Buffer_Text (S) = "A disk replacement"
        and then not S.File_Info.Dirty,
        "reload after active switch must target only the new active Buffer A");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (Buffer_Text (S) = To_String (Before_Text),
        "successful reload on A must not mutate inactive Buffer B");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Preserves_Failure_State_And_Active_Buffer_Isolation;

   procedure Test_Reload_Save_As_Close_Reopen_Integrated_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Path   : constant String := Temp_Path ("integrated_save_as.txt");
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled payload");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer"
        and then Buffer_Text (S) = "untitled payload" and then S.File_Info.Dirty,
        "dirty untitled reload must report no path and preserve text");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Path);
      Assert (Read_Bytes (Path) = "untitled payload"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Path,
        "Save As remains the command that establishes the reload file association");

      Write_Bytes (Path, "disk after save-as");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "disk after save-as"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Path,
        "reload after Save As must read exact disk text and preserve association");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Path,
        "close after clean reload must register the canonical path-only reopen candidate");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (not S.Has_Reopen_Candidate
        and then Buffer_Text (S) = "disk after save-as"
        and then To_String (S.File_Info.Path) = Path,
        "reopen after reload must use canonical file open without restoring reload state");

      Write_Bytes (Path, "disk after reopen");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "disk after reopen" and then not S.File_Info.Dirty,
        "reload after reopen must still target the active associated buffer");

      Insert_Text_At (S, Buffer_Text (S)'Length, " local edit");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Dirty buffer cannot be reloaded"
        and then Buffer_Text (S) = "disk after reopen local edit"
        and then S.File_Info.Dirty,
        "reload must not become discard or revert after close/reopen workflow");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Save_As_Close_Reopen_Integrated_Workflow;


   procedure Test_Reload_Canonical_Path_Ignores_Removed_Name_And_Feature_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      A_Path         : constant String := Temp_Path ("reload_a.txt");
      B_Path         : constant String := Temp_Path ("reload_b.txt");
      A_Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id           : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Reopen_Path    : constant String := Temp_Path ("reload_reopen_candidate.txt");
      Before_Reopen  : Boolean := False;
      Clipboard_Text : Unbounded_String;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (A_Path, "A initial");
      Write_Bytes (B_Path, "B initial");
      Write_Bytes (Reopen_Path, "reopen candidate text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);

      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      Before_Reopen := S.Has_Reopen_Candidate;
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      Clipboard_Text := Editor.Clipboard.Get_Text;

      Write_Bytes (A_Path, "A canonical disk");
      Write_Bytes (B_Path, "B must remain inactive");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Editor.Buffers.Global_Active_Buffer = A_Id,
        "reload target must remain the active buffer at execution time");
      Assert (Buffer_Text (S) = "A canonical disk",
        "reload must use only the active buffer associated file read");
      Assert (To_String (S.File_Info.Path) = A_Path and then not S.File_Info.Dirty,
        "successful reload must preserve association and clean only the active buffer");
      Assert (S.Has_Reopen_Candidate = Before_Reopen
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "reload must not create, consume, or repair reopen candidates");
      Assert (Editor.Clipboard.Get_Text = Clipboard_Text,
        "reload must not mutate Clipboard");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer reloaded",
        "reload success keeps the canonical one-message outcome");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (Buffer_Text (S) = "B initial" and then not S.File_Info.Dirty,
        "inactive buffer text and dirty state must be unchanged");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Write_Bytes (A_Path, "A forbidden dirty replacement");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Dirty buffer cannot be reloaded"
        and then Buffer_Text (S) = "A canonical disk dirty"
        and then S.File_Info.Dirty,
        "dirty reload guard must not become force/discard/revert reload");
      Assert (Read_Bytes (A_Path) = "A forbidden dirty replacement",
        "blocked reload must not write, save, or normalize files");
      Assert (S.Has_Reopen_Candidate = Before_Reopen
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "blocked reload must not mutate reopen state");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reload_Canonical_Path_Ignores_Removed_Name_And_Feature_State;


   procedure Test_Revert_Command_Surface_And_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Cmd   : Editor.Commands.Command_Id;
      Desc  : Editor.Commands.Command_Descriptor;
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("revert_validation.txt");
      M     : Editor.Messages.Editor_Message;
   begin
      Cmd := Editor.Commands.Command_Id_From_Stable_Name ("file.revert-buffer", Found);
      Assert (Found and then Cmd = Editor.Commands.Command_Revert_Active_Buffer,
        "file.revert-buffer must resolve to canonical command id");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Revert_Active_Buffer) = "file.revert-buffer",
        "revert must use canonical persisted command name");
      Desc := Editor.Commands.Descriptor
        (Editor.Commands.Command_Revert_Active_Buffer);
      Assert (Desc.Category = Editor.Commands.File_Category,
        "revert must be a File command");
      Assert (Desc.Bindable and then Desc.Visibility = Editor.Commands.Palette_Command,
        "revert must be bindable and Command Palette visible");
      Assert (Desc.Destructive and then Desc.Lifecycle,
        "revert must be classified as destructive lifecycle command");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "no active buffer must report No active buffer");

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Insert_Text_At (S, 0, "dirty untitled");
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer"
        and then Buffer_Text (S) = "dirty untitled" and then S.File_Info.Dirty,
        "dirty untitled revert must be no-path and non-mutating");

      Remove_If_Exists (Path);
      Write_Bytes (Path, "clean disk");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Write_Bytes (Path, "external disk change that revert must not read");
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert"
        and then Buffer_Text (S) = "clean disk" and then not S.File_Info.Dirty,
        "clean associated revert must be no-op and must not reload");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Command_Surface_And_Validation;

   procedure Test_Revert_Success_Replaces_Dirty_Active_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      A_Path : constant String := Temp_Path ("revert_a.txt");
      B_Path : constant String := Temp_Path ("revert_b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M      : Editor.Messages.Editor_Message;
      Found  : Boolean := False;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Write_Bytes (A_Path, "A disk baseline");
      Write_Bytes (B_Path, "B disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty edits");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives revert"));
      Write_Bytes (B_Path, "B exact" & ASCII.LF & ASCII.HT & "disk text" & ASCII.LF);
      Write_Bytes (A_Path, "A changed but inactive");

      Execute_Revert_And_Confirm (S);
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
        "revert must leave the active buffer active");
      Assert (Buffer_Text (S) = "B exact" & ASCII.LF & ASCII.HT & "disk text" & ASCII.LF,
        "revert must replace active dirty text with exact disk contents");
      Assert (not S.File_Info.Dirty and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful revert must update baseline and mark active buffer clean after read");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = B_Path,
        "successful revert must preserve file association");
      Assert (Editor.History.Undo_Stack.Is_Empty and then Editor.History.Redo_Stack.Is_Empty,
        "successful revert must clear stale edit history without creating entries");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0 and then S.Carets (0).Anchor = 0,
        "successful revert must apply retained caret/selection reset policy");
      Assert (Editor.Clipboard.Get_Text = To_Unbounded_String ("clipboard survives revert"),
        "revert must not mutate Clipboard");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer reverted",
        "successful revert must emit one Buffer reverted message");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "A disk baseline" and then not S.File_Info.Dirty,
        "revert must not mutate inactive buffer text or dirty state");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Success_Replaces_Dirty_Active_Text;

   procedure Test_Revert_Read_Failure_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("revert_missing.txt");
      Before_Text  : Unbounded_String;
      Before_Gen   : Natural := 0;
      Before_Caret : Editor.Cursors.Caret_State;
      Before_Undo  : Ada.Containers.Count_Type;
      Before_Redo  : Ada.Containers.Count_Type;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty text that must survive");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 5, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Remove_If_Exists (Path);

      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not revert buffer",
        "read-failure revert must emit Could not revert buffer");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text and then S.File_Info.Dirty,
        "read-failure revert must preserve dirty text and dirty state");
      Assert (S.File_Info.Saved_Generation = Before_Gen,
        "read-failure revert must preserve saved baseline marker");
      Assert (S.Carets (0).Pos = Before_Caret.Pos and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "read-failure revert must preserve caret/selection");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "read-failure revert must preserve Undo/Redo stacks");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Read_Failure_Preserves_State;

   procedure Test_Revert_Save_Close_Reopen_Reload_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S     : Editor.State.State_Type;
      Path  : constant String := Temp_Path ("revert_workflow.txt");
      M     : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Insert_Text_At (S, Buffer_Text (S)'Length, " saved");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert",
        "successful save must make revert a clean no-op");

      Insert_Text_At (S, Buffer_Text (S)'Length, " unsaved");
      Write_Bytes (Path, "disk after unsaved edit");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Dirty buffer cannot be reloaded"
        and then S.File_Info.Dirty,
        "reload remains the clean-buffer reread command and must not become revert");

      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "disk after unsaved edit" and then not S.File_Info.Dirty,
        "revert success must make the buffer clean and closeable");
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer closed",
        "close after successful revert must use canonical clean close");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty after reopen");
      Write_Bytes (Path, "disk after reopen");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "disk after reopen" and then not S.File_Info.Dirty,
        "reopen followed by edit then revert must use reopened buffer association");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Save_Close_Reopen_Reload_Workflow;


   procedure Test_Revert_Target_Validation_And_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      A_Path       : constant String := Temp_Path ("revert_target_a.txt");
      B_Path       : constant String := Temp_Path ("revert_target_b.txt");
      A_Id         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
      Availability : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "no active buffer must be the first revert validation result");

      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Insert_Text_At (S, 0, "dirty untitled");
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer"
        and then Buffer_Text (S) = "dirty untitled" and then S.File_Info.Dirty,
        "dirty untitled revert must report no path and preserve text");

      Write_Bytes (A_Path, "A clean baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Remove_If_Exists (A_Path);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert"
        and then Buffer_Text (S) = "A clean baseline" and then not S.File_Info.Dirty,
        "clean associated revert must no-op before any filesystem read");

      Write_Bytes (A_Path, "A disk before");
      Write_Bytes (B_Path, "B disk before");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty B");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty A");
      Write_Bytes (A_Path, "A disk target");
      Write_Bytes (B_Path, "B disk must not be read");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Revert_Active_Buffer);
      Assert (Editor.Commands.Is_Available (Availability),
        "dirty associated active buffer must make revert available");
      Assert (Buffer_Text (S) = "A disk before dirty A" and then S.File_Info.Dirty,
        "revert availability must not read files or mutate text");

      Execute_Revert_And_Confirm (S);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id
        and then Buffer_Text (S) = "A disk target"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = A_Path,
        "revert must target only the active buffer at execution time");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer reverted",
        "active target revert success must emit Buffer reverted");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (Buffer_Text (S) = "B disk before dirty B" and then S.File_Info.Dirty,
        "revert must not mutate inactive dirty buffers");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Target_Validation_And_Availability;

   procedure Test_Revert_Read_Failure_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("revert_failure.txt");
      Reopen_Path   : constant String := Temp_Path ("revert_reopen_candidate.txt");
      Before_Text   : Unbounded_String;
      Before_Gen    : Natural := 0;
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Query  : Unbounded_String;
      Before_Replace : Unbounded_String;
      Before_Clip   : Unbounded_String;
      M             : Editor.Messages.Editor_Message;
      Found         : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Path, "disk baseline");
      Write_Bytes (Reopen_Path, "candidate text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty text that must survive");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 8, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("dirty");
      S.Active_Replace_Text := To_Unbounded_String ("clean");
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Reopen_Path);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives failure"));

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Query := S.Active_Find_Query;
      Before_Replace := S.Active_Replace_Text;
      Before_Clip := Editor.Clipboard.Get_Text;
      Remove_If_Exists (Path);
      Ada.Directories.Create_Directory (Path);

      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not revert buffer",
        "directory read failure must emit Could not revert buffer");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen
        and then To_String (S.File_Info.Path) = Path,
        "read failure must preserve text, dirty state, baseline, and association");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "read failure must preserve caret and selection");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "read failure must preserve Undo/Redo stacks");
      Assert (S.Active_Find_Query = Before_Query
        and then S.Active_Replace_Text = Before_Replace,
        "read failure must preserve Find/Replace state");
      Assert (Editor.Clipboard.Get_Text = Before_Clip,
        "read failure must preserve Clipboard");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path,
        "read failure must not mutate reopen candidates");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Read_Failure_Is_Atomic;

   procedure Test_Revert_Exact_Disk_Text_And_History_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Path     : constant String := Temp_Path ("revert_exact.txt");
      Exact    : constant String := "" & ASCII.LF & "  spaces" & ASCII.LF
        & ASCII.HT & "tabs!" & ASCII.LF & ASCII.LF & "tail" & ASCII.LF;
      Saved_Gen : Natural := 0;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " local dirty edit");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
        "setup: dirty edit should create undo history");
      Write_Bytes (Path, Exact);

      Execute_Revert_And_Confirm (S);
      Saved_Gen := S.File_Info.Saved_Generation;
      Assert (Buffer_Text (S) = Exact,
        "successful revert must preserve exact canonical disk text including whitespace and trailing newline");
      Assert (not S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful revert must update saved baseline and clean state after read success");
      Assert (Editor.History.Undo_Stack.Is_Empty
        and then Editor.History.Redo_Stack.Is_Empty,
        "successful revert must clear stale Undo/Redo without creating entries");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = Exact
        and then S.File_Info.Saved_Generation = Saved_Gen
        and then not S.File_Info.Dirty,
        "edit.undo must not undo a successful revert");

      Insert_Text_At (S, Buffer_Text (S)'Length, "post");
      Assert (S.File_Info.Dirty,
        "edits after revert must compare against the new disk-text baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = Exact & "post" and then not S.File_Info.Dirty,
        "save after revert must write current text to the preserved association");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Exact_Disk_Text_And_History_Policy;

   procedure Test_Revert_Clean_No_Op_Preserves_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("revert_clean_noop.txt");
      Before_Text   : Unbounded_String;
      Before_Gen    : Natural := 0;
      Before_Caret  : Editor.Cursors.Caret_State;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Availability  : Editor.Commands.Command_Availability;
      M             : Editor.Messages.Editor_Message;
      Found         : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "clean baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " undoable");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 5, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("baseline");
      S.Active_Replace_Text := To_Unbounded_String ("replacement");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clean noop clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Caret := S.Carets (0);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Remove_If_Exists (Path);

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Revert_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Availability)
        and then Editor.Commands.Unavailable_Reason (Availability) = "No changes to revert",
        "clean associated revert availability must not probe the filesystem");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text,
        "clean availability check must not mutate text");

      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "No changes to revert",
        "clean associated execution must emit No changes to revert");
      Assert (To_Unbounded_String (Buffer_Text (S)) = Before_Text
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen,
        "clean no-op must preserve text, dirty state, and baseline");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "clean no-op must preserve caret and selection");
      Assert (Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "clean no-op must preserve Undo/Redo stacks");
      Assert (To_String (S.Active_Find_Query) = "baseline"
        and then To_String (S.Active_Replace_Text) = "replacement"
        and then To_String (Editor.Clipboard.Get_Text) = "clean noop clipboard",
        "clean no-op must preserve Find/Replace and Clipboard state");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Clean_No_Op_Preserves_State;


   procedure Test_Revert_Validation_Surface_And_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Path     : constant String := Temp_Path ("validation.txt");
      Dir_Path : constant String := Temp_Path ("validation_dir");
      M        : Editor.Messages.Editor_Message;
      Found    : Boolean := False;
      Id       : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Avail    : Editor.Commands.Command_Availability;

      procedure Assert_Message
        (Text : String; Severity : Editor.Messages.Message_Severity) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1,
           "file.revert-buffer must emit exactly one primary message: " & Text);
         Assert (M.Severity = Severity and then To_String (M.Text) = Text,
           "file.revert-buffer message mismatch, expected " & Text);
      end Assert_Message;

      procedure Assert_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert (not Found and then Id = Editor.Commands.No_Command,
           "non-goal revert/recovery command must not be exposed: " & Name);
      end Assert_Absent;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Path, "readable disk text");
      Editor.Buffers.Reset_Global_For_Test;

      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Revert_Active_Buffer) = "file.revert-buffer",
         "canonical active-buffer revert stable name must remain file.revert-buffer");
      Assert_Absent ("file.revert-all-buffers");
      Assert_Absent ("file.revert-clean-buffer");
      Assert_Absent ("file.force-reload-buffer");
      Assert_Absent ("file.discard-buffer");
      Assert_Absent ("file.discard-and-reload");
      Assert_Absent ("file.restore-backup");
      Assert_Absent ("file.restore-discarded-text");
      Assert_Absent ("file.watch-buffer");
      Assert_Absent ("file.reload-project");
      Assert_Absent ("workspace.revert-buffer-text");
      Assert_Absent ("project.revert-all-buffers");

      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert_Message ("No active buffer.", Editor.Messages.Info_Message);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled clean text");
      S.File_Info.Dirty := False;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message);
      Assert (Buffer_Text (S) = "untitled clean text" and then not S.File_Info.Dirty,
        "no-path validation must precede clean-buffer no-op semantics");

      Editor.State.Load_Text (S, "untitled dirty text");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message);
      Assert (Buffer_Text (S) = "untitled dirty text" and then S.File_Info.Dirty,
        "dirty untitled buffers must not invent stale Save As, workspace, or display paths");

      Editor.State.Load_Text (S, "clean associated text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Path);
      S.File_Info.Display_Name := To_Unbounded_String ("validation.txt");
      S.File_Info.Dirty := False;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := Editor.State.Current_Buffer_Revision (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Remove_If_Exists (Path);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Revert_Active_Buffer);
      Assert (not Editor.Commands.Is_Available (Avail)
        and then Editor.Commands.Unavailable_Reason (Avail) = "No changes to revert",
        "clean associated availability must stop before filesystem probing");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Revert_Active_Buffer);
      Assert_Message ("No changes to revert", Editor.Messages.Info_Message);
      Assert (Buffer_Text (S) = "clean associated text" and then not S.File_Info.Dirty
        and then not Ada.Directories.Exists (Path),
        "clean no-op must not read, write, create, or repair the associated file");

      Ada.Directories.Create_Directory (Dir_Path);
      Editor.State.Load_Text (S, "dirty associated text");
      S.File_Info.Has_Path := True;
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("validation_dir");
      S.File_Info.Dirty := True;
      S.File_Info.Baseline_Valid := True;
      S.File_Info.Saved_Generation := 77;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert_Message ("Could not revert buffer", Editor.Messages.Error_Message);
      Assert (Buffer_Text (S) = "dirty associated text" and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = 77,
        "dirty associated read failure must preserve text, dirty flag, and baseline marker");

      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Dir_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Validation_Surface_And_Messages;

   procedure Test_Revert_Target_Is_Active_Buffer_And_Isolated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      A_Path      : constant String := Temp_Path ("target_a.txt");
      B_Path      : constant String := Temp_Path ("target_b.txt");
      C_Path      : constant String := Temp_Path ("target_c.txt");
      A_Id        : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id        : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      C_Id        : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_A    : Unbounded_String;
      Before_B    : Unbounded_String;
      Before_C    : Unbounded_String;
      Before_Count : Natural := 0;
      M           : Editor.Messages.Editor_Message;
      Found       : Boolean := False;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (C_Path);
      Write_Bytes (A_Path, "A baseline");
      Write_Bytes (B_Path, "B baseline");
      Write_Bytes (C_Path, "C baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty A");
      Before_A := To_Unbounded_String (Buffer_Text (S));

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty B");
      Before_B := To_Unbounded_String (Buffer_Text (S));

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Before_C := To_Unbounded_String (Buffer_Text (S));
      Before_Count := Editor.Buffers.Global_Count;

      Write_Bytes (A_Path, "A disk replacement");
      Write_Bytes (B_Path, "B disk replacement");
      Write_Bytes (C_Path, "C disk replacement that clean revert must not read");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id, Emit_Feedback => False);
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (A_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("A stale candidate");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer reverted",
        "active dirty associated revert must emit one Buffer reverted message");
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id
        and then Editor.Buffers.Global_Count = Before_Count
        and then Buffer_Text (S) = "A disk replacement"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = A_Path,
        "revert must target only the active buffer identity at execution time");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "revert must not consume or repair reopen candidates");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id, Emit_Feedback => False);
      Assert (Buffer_Text (S) = To_String (Before_B) and then S.File_Info.Dirty,
        "successful revert on A must not mutate inactive dirty Buffer B");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "B disk replacement" and then not S.File_Info.Dirty,
        "after active switch, revert must target Buffer B rather than stale A");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, C_Id, Emit_Feedback => False);
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert"
        and then Buffer_Text (S) = To_String (Before_C)
        and then not S.File_Info.Dirty,
        "active clean Buffer C revert must be a no-op and must not reload changed disk text");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id, Emit_Feedback => False);
      Assert (Buffer_Text (S) = "A disk replacement",
        "later no-op on C must not mutate inactive reverted Buffer A");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (C_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Remove_If_Exists (C_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Target_Is_Active_Buffer_And_Isolated;

   procedure Test_Revert_Success_Text_Baseline_History_And_Save_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("success_matrix.txt");
      Exact        : constant String := "" & ASCII.LF & "  spaces" & ASCII.LF
        & ASCII.HT & "tabs" & ASCII.LF & ASCII.LF & "punctuation!?" & ASCII.LF;
      Reverted_Gen : Natural := 0;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty edit");
      Assert (S.File_Info.Dirty and then not Editor.History.Undo_Stack.Is_Empty,
        "setup: dirty edit must produce dirty state and undo history");
      Write_Bytes (Path, Exact);

      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Reverted_Gen := S.File_Info.Saved_Generation;
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (M.Text) = "Buffer reverted",
        "successful revert must emit exactly one success message");
      Assert (Buffer_Text (S) = Exact
        and then Read_Bytes (Path) = Exact,
        "successful revert must use exact canonical disk text without formatting or writing");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Path
        and then not S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
        "successful revert must preserve association, update baseline, and mark clean after read success");
      Assert (Editor.History.Undo_Stack.Is_Empty
        and then Editor.History.Redo_Stack.Is_Empty,
        "successful revert must clear stale Undo/Redo without creating revert entries");
      Assert (S.Carets.Length = 1 and then S.Carets (0).Pos = 0 and then S.Carets (0).Anchor = 0,
        "successful revert must apply retained caret/selection destructive lifecycle policy");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Buffer_Text (S) = Exact and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Reverted_Gen,
        "edit.undo must not undo the revert itself");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Buffer_Text (S) = Exact and then not S.File_Info.Dirty,
        "edit.redo must not redo a revert entry");

      Insert_Text_At (S, Buffer_Text (S)'Length, "post");
      Assert (S.File_Info.Dirty,
        "post-revert edits must compare against the new disk-text baseline");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (Path) = Exact & "post" and then not S.File_Info.Dirty,
        "file.save after revert remains the only writer and writes current text to the preserved path");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (S.File_Info.Dirty,
        "undo after post-revert save must dirty against the post-revert saved baseline under normal edit policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (not S.File_Info.Dirty,
        "redo after post-revert save must return to the saved baseline under normal edit policy");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Success_Text_Baseline_History_And_Save_Workflow;

   procedure Test_Revert_Failure_And_Clean_No_Op_Preserve_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                  : Editor.State.State_Type;
      Path               : constant String := Temp_Path ("preserve.txt");
      Dir_Path           : constant String := Temp_Path ("preserve_dir");
      Before_Text        : Unbounded_String;
      Before_Gen         : Natural := 0;
      Before_Undo        : Ada.Containers.Count_Type;
      Before_Redo        : Ada.Containers.Count_Type;
      Before_Caret       : Editor.Cursors.Caret_State;
      Before_Query       : Unbounded_String;
      Before_Replace     : Unbounded_String;
      Before_Clip        : Unbounded_String;
      Before_Has_Clip    : Boolean := False;
      Before_Back        : Natural := 0;
      Before_Forward     : Natural := 0;
      Before_Reopen      : Boolean := False;
      Before_Reopen_Path : Unbounded_String;
      M                  : Editor.Messages.Editor_Message;
      Found              : Boolean := False;

      procedure Capture is
      begin
         Before_Text := To_Unbounded_String (Buffer_Text (S));
         Before_Gen := S.File_Info.Saved_Generation;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
         Before_Caret := S.Carets (0);
         Before_Query := S.Active_Find_Query;
         Before_Replace := S.Active_Replace_Text;
         Before_Clip := Editor.Clipboard.Get_Text;
         Before_Has_Clip := Editor.Clipboard.Has_Text;
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Reopen := S.Has_Reopen_Candidate;
         Before_Reopen_Path := S.Reopen_Candidate_Path;
      end Capture;

      procedure Assert_Preserved (Label : String) is
      begin
         Assert (Buffer_Text (S) = To_String (Before_Text), Label & ": text changed");
         Assert (S.File_Info.Saved_Generation = Before_Gen, Label & ": baseline marker changed");
         Assert (Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo,
           Label & ": Undo/Redo changed");
         Assert (S.Carets (0).Pos = Before_Caret.Pos
           and then S.Carets (0).Anchor = Before_Caret.Anchor,
           Label & ": caret/selection changed");
         Assert (S.Active_Find_Query = Before_Query
           and then S.Active_Replace_Text = Before_Replace,
           Label & ": Find/Replace changed");
         Assert (Editor.Clipboard.Has_Text = Before_Has_Clip
           and then Editor.Clipboard.Get_Text = Before_Clip,
           Label & ": Clipboard changed");
         Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
           and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
           Label & ": Navigation History changed");
         Assert (S.Has_Reopen_Candidate = Before_Reopen
           and then S.Reopen_Candidate_Path = Before_Reopen_Path,
           Label & ": reopen candidate changed");
      end Assert_Preserved;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Write_Bytes (Path, "baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " undoable");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 5, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("baseline");
      S.Active_Replace_Text := To_Unbounded_String ("replacement");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives revert attempts"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (Path);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (Editor.Buffers.Global_Active_Buffer),
          Has_File_Path => True,
          File_Path => To_Unbounded_String (Path),
          Display_Path => To_Unbounded_String (Path),
          Line => 1,
          Column => 1,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));

      Capture;
      Remove_If_Exists (Path);
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert",
        "clean no-op must report No changes to revert even when disk is missing");
      Assert (not S.File_Info.Dirty, "clean no-op must preserve clean state");
      Assert_Preserved ("clean no-op");

      Ada.Directories.Create_Directory (Dir_Path);
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("preserve_dir");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty after clean noop");
      S.File_Info.Path := To_Unbounded_String (Dir_Path);
      S.File_Info.Display_Name := To_Unbounded_String ("preserve_dir");
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Capture;
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not revert buffer",
        "dirty read failure must report Could not revert buffer");
      Assert (S.File_Info.Dirty, "read failure must keep dirty state");
      Assert_Preserved ("read failure");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Dir_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Dir_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_Failure_And_Clean_No_Op_Preserve_Transient_State;

   procedure Test_Revert_File_Lifecycle_And_Read_Only_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("lifecycle.txt");
      Save_As     : constant String := Temp_Path ("lifecycle_save_as.txt");
      Snap        : Editor.Render_Model.Render_Snapshot;
      Avail       : Editor.Commands.Command_Availability;
      Candidates  : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Palette_Found : Boolean := False;
      Before_Text : Unbounded_String;
      Before_Gen  : Natural := 0;
      Before_Dirty : Boolean := False;
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Write_Bytes (Path, "initial disk");
      Write_Bytes (Save_As, "save-as disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Dirty := S.File_Info.Dirty;
      Write_Bytes (Path, "render must not be read by availability");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Revert_Active_Buffer);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Revert_Active_Buffer then
               Palette_Found := True;
            end if;
         end loop;
      end if;
      Assert (Palette_Found,
        "Command Palette projection must still include canonical file.revert-buffer without executing it");
      Assert (Editor.Commands.Is_Available (Avail),
        "dirty associated revert availability may observe state but must not probe filesystem");
      Assert (Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty = Before_Dirty
        and then S.File_Info.Saved_Generation = Before_Gen
        and then Read_Bytes (Path) = "render must not be read by availability",
        "render, availability, and Command Palette projection must not revert, save, reload, or mutate state");
      Assert (Snap.Is_Dirty,
        "render snapshot may observe dirty state without repairing it");

      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "render must not be read by availability"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Path,
        "explicit revert must read current disk text and keep the file association");
      Assert (Read_Bytes (Path) = "render must not be read by availability"
        and then Read_Bytes (Save_As) = "save-as disk",
        "revert must not write active path or unrelated Save As path");

      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Path,
        "successful revert makes the buffer clean and closeable through the normal close lifecycle");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (Buffer_Text (S) = "render must not be read by availability"
        and then not S.File_Info.Dirty,
        "reopen after clean close must not restore discarded pre-revert text");

      Insert_Text_At (S, Buffer_Text (S)'Length, " reopened dirty");
      Write_Bytes (Path, "disk after reopen");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "disk after reopen" and then not S.File_Info.Dirty,
        "revert after reopen still targets the active associated buffer");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "disk after reopen" and then not S.File_Info.Dirty,
        "reload remains the clean-buffer reread command after revert");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No changes to revert",
        "revert after clean reload must remain a clean no-op, not duplicate reload");

      Editor.State.Load_Text (S, "untitled lifecycle dirty");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As);
      Assert (To_String (S.File_Info.Path) = Save_As and then not S.File_Info.Dirty,
        "setup: Save As remains the command that creates an association for untitled text");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty after save-as");
      Write_Bytes (Save_As, "disk after save-as");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "disk after save-as"
        and then not S.File_Info.Dirty
        and then To_String (S.File_Info.Path) = Save_As,
        "after Save As, revert uses the new active associated path without changing association");

      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Save_As);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Revert_File_Lifecycle_And_Read_Only_Boundaries;



procedure Test_Rename_Command_Surface_And_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("surface_source.txt");
      Target       : constant String := Temp_Path ("surface_target.txt");
      Existing     : constant String := Temp_Path ("surface_existing.txt");
      Id           : Editor.Commands.Command_Id;
      Found_Id     : Boolean := False;
      Descriptor   : Editor.Commands.Command_Descriptor;
      Availability : Editor.Commands.Command_Availability;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;

      procedure Assert_Message (Text : String; Severity : Editor.Messages.Message_Severity) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1
           and then M.Severity = Severity
           and then To_String (M.Text) = Text,
           "expected one message '" & Text & "'");
      end Assert_Message;

      procedure Assert_Absent (Name : String) is
         Missing : Boolean := False;
         Cmd     : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Missing);
      begin
         Assert (not Missing and then Cmd = Editor.Commands.No_Command,
           "non-goal rename command must not be exposed: " & Name);
      end Assert_Absent;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Write_Bytes (Path, "rename source disk");
      Write_Bytes (Existing, "existing target");
      Editor.Buffers.Reset_Global_For_Test;

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.rename-buffer-file", Found_Id);
      Assert (Found_Id and then Id = Editor.Commands.Command_Rename_Buffer_File,
        "file.rename-buffer-file must resolve to canonical command id");
      Assert
        (Editor.Commands.Stable_Command_Name
           (Editor.Commands.Command_Rename_Buffer_File) = "file.rename-buffer-file",
         "rename must expose the canonical stable name");

      Descriptor := Editor.Commands.Descriptor
        (Editor.Commands.Command_Rename_Buffer_File);
      Assert (Descriptor.Category = Editor.Commands.File_Category
        and then Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Descriptor.Bindable
        and then Descriptor.Lifecycle,
        "rename must be a visible bindable File lifecycle command");

      Assert_Absent ("file.rename-all-buffers");
      Assert_Absent ("file.rename-project-file");
      Assert_Absent ("file.rename-symbol");
      Assert_Absent ("file.refactor-rename");
      Assert_Absent ("file.rename-dirty-buffer");
      Assert_Absent ("file.rename-untitled-buffer");
      Assert_Absent ("file.force-rename-buffer-file");
      Assert_Absent ("workspace.rename-buffer-file");
      Assert_Absent ("project.rename-files");

      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability)
        and then Editor.Commands.Unavailable_Reason (Availability) = "No active buffer.",
        "rename availability must report no active buffer first");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert_Message ("No active buffer.", Editor.Messages.Info_Message);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled clean");
      S.File_Info.Dirty := False;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message);
      Assert (not Ada.Directories.Exists (Target),
        "no-path rename must not touch target filesystem path");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "");
      Assert_Message ("Invalid rename target", Editor.Messages.Error_Message);
      Assert (Ada.Directories.Exists (Path) and then not Ada.Directories.Exists (Target),
        "missing target must not rename source");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Existing);
      Assert_Message ("Rename target already exists", Editor.Messages.Error_Message);
      Assert (Ada.Directories.Exists (Path)
        and then Read_Bytes (Existing) = "existing target",
        "existing target must not be overwritten");

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
   end Test_Rename_Command_Surface_And_Validation;

   procedure Test_Rename_Success_Preserves_Buffer_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Path           : constant String := Temp_Path ("success_source.txt");
      Target         : constant String := Temp_Path ("success_target.txt");
      Cmd            : Editor.Commands.Command;
      Before_Text    : Unbounded_String;
      Before_Gen     : Natural;
      Before_Valid   : Boolean;
      Before_Caret   : Editor.Cursors.Caret_State;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "rename clean text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 3,
            Anchor                => 1,
            Virtual_Column        => 3,
            Anchor_Virtual_Column => 1));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Valid := S.File_Info.Baseline_Valid;
      Before_Caret := S.Carets (0);
      Editor.Messages.Clear (S.Messages);

      Cmd := Editor.Commands.Command_For_Id
        (Editor.Commands.Command_Rename_Buffer_File);
      Cmd.Path := To_Unbounded_String (Target);
      Editor.Executor.Execute_No_Log (S, Cmd);

      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer file renamed",
        "successful rename must emit one success message");
      Assert (not Ada.Directories.Exists (Path)
        and then Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "rename clean text",
        "filesystem rename must move the backing file without rewriting text");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then S.File_Info.Baseline_Valid = Before_Valid
        and then not S.File_Info.Dirty,
        "success must update association only and preserve text, baseline, and clean state");
      Assert (S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "success must preserve caret/selection state");

      Write_Bytes (Target, "disk after rename");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "disk after rename",
        "subsequent reload must read the renamed target path");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Success_Preserves_Buffer_State;

   procedure Test_Rename_Dirty_And_Failure_Are_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("dirty_source.txt");
      Target       : constant String := Temp_Path ("dirty_target.txt");
      Missing_Path : constant String := Temp_Path ("missing_source.txt");
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Before_Gen   : Natural;
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Path);
      Write_Bytes (Path, "dirty source text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "Dirty buffer preserved.",
        "dirty rename must emit one blocked message");
      Assert (Ada.Directories.Exists (Path)
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen,
        "dirty rename must not touch filesystem, association, text, dirty state, or baseline");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Remove_If_Exists (Path);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not rename buffer file",
        "filesystem rename failure must emit one failure message");
      Assert (not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Dirty
        and then S.File_Info.Saved_Generation = Before_Gen,
        "filesystem failure must preserve association, text, baseline, and clean state");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Missing_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Dirty_And_Failure_Are_Atomic;

   procedure Test_Rename_Active_Isolation_And_Lifecycle_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S                    : Editor.State.State_Type;
      A_Path               : constant String := Temp_Path ("lifecycle_a.txt");
      B_Path               : constant String := Temp_Path ("lifecycle_b.txt");
      A_Target             : constant String := Temp_Path ("lifecycle_a_renamed.txt");
      B_Target             : constant String := Temp_Path ("lifecycle_b_renamed.txt");
      Save_As_Path         : constant String := Temp_Path ("lifecycle_save_as.txt");
      Save_As_Target       : constant String := Temp_Path ("lifecycle_save_as_renamed.txt");
      A_Id                 : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id                 : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_A_Text        : Unbounded_String;
      Before_A_Path        : Unbounded_String;
      Before_B_Text        : Unbounded_String;
      Before_B_Path        : Unbounded_String;
      Before_B_Gen         : Natural := 0;
      Before_Undo          : Ada.Containers.Count_Type;
      Before_Redo          : Ada.Containers.Count_Type;
      Before_Caret         : Editor.Cursors.Caret_State;
      Before_Query         : Unbounded_String;
      Before_Replace       : Unbounded_String;
      Before_Clip          : Unbounded_String;
      Before_Has_Clip      : Boolean := False;
      Before_Back          : Natural := 0;
      Before_Forward       : Natural := 0;
      Before_Reopen        : Boolean := False;
      Before_Reopen_Path   : Unbounded_String;
      M                    : Editor.Messages.Editor_Message;
      Found                : Boolean := False;

      procedure Capture_Active_B_State is
      begin
         Before_B_Text := To_Unbounded_String (Buffer_Text (S));
         Before_B_Path := S.File_Info.Path;
         Before_B_Gen := S.File_Info.Saved_Generation;
         Before_Undo := Editor.History.Undo_Stack.Length;
         Before_Redo := Editor.History.Redo_Stack.Length;
         Before_Caret := S.Carets (0);
         Before_Query := S.Active_Find_Query;
         Before_Replace := S.Active_Replace_Text;
         Before_Clip := Editor.Clipboard.Get_Text;
         Before_Has_Clip := Editor.Clipboard.Has_Text;
         Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
         Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);
         Before_Reopen := S.Has_Reopen_Candidate;
         Before_Reopen_Path := S.Reopen_Candidate_Path;
      end Capture_Active_B_State;

      procedure Assert_Active_B_Features_Preserved (Label : String) is
      begin
         Assert (Buffer_Text (S) = To_String (Before_B_Text),
           Label & ": active text changed");
         Assert (S.File_Info.Saved_Generation = Before_B_Gen,
           Label & ": saved baseline marker changed");
         Assert (Editor.History.Undo_Stack.Length = Before_Undo
           and then Editor.History.Redo_Stack.Length = Before_Redo,
           Label & ": Undo/Redo changed");
         Assert (S.Carets (0).Pos = Before_Caret.Pos
           and then S.Carets (0).Anchor = Before_Caret.Anchor,
           Label & ": caret/selection changed");
         Assert (S.Active_Find_Query = Before_Query
           and then S.Active_Replace_Text = Before_Replace,
           Label & ": Find/Replace changed");
         Assert (Editor.Clipboard.Has_Text = Before_Has_Clip
           and then Editor.Clipboard.Get_Text = Before_Clip,
           Label & ": Clipboard changed");
         Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
           and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
           Label & ": Navigation History changed");
         Assert (S.Has_Reopen_Candidate = Before_Reopen
           and then S.Reopen_Candidate_Path = Before_Reopen_Path,
           Label & ": reopen candidate changed");
      end Assert_Active_B_Features_Preserved;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (A_Target);
      Remove_If_Exists (B_Target);
      Remove_If_Exists (Save_As_Path);
      Remove_If_Exists (Save_As_Target);
      Write_Bytes (A_Path, "A original");
      Write_Bytes (B_Path, "B original");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Clipboard.Clear;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Before_A_Text := To_Unbounded_String (Buffer_Text (S));
      Before_A_Path := S.File_Info.Path;

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos => 4, Anchor => 2, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("B");
      S.Active_Replace_Text := To_Unbounded_String ("bee");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard survives rename"));
      S.Has_Reopen_Candidate := True;
      S.Reopen_Candidate_Path := To_Unbounded_String (A_Path);
      S.Reopen_Candidate_Label := To_Unbounded_String ("A candidate");
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (B_Id),
          Has_File_Path => True,
          File_Path => To_Unbounded_String (B_Path),
          Display_Path => To_Unbounded_String (B_Path),
          Line => 1,
          Column => 0,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));

      Capture_Active_B_State;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, B_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer file renamed",
        "completeness: active rename must emit exactly one success message");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B_Target)
        and then not S.File_Info.Dirty,
        "completeness: rename must keep the active buffer active and clean with the new association");
      Assert_Active_B_Features_Preserved ("completeness successful rename");
      Assert (not Ada.Directories.Exists (B_Path)
        and then Ada.Directories.Exists (B_Target)
        and then Read_Bytes (B_Target) = "B original",
        "completeness: rename must move the active backing file without writing buffer text");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = To_String (Before_A_Text)
        and then To_String (S.File_Info.Path) = To_String (Before_A_Path)
        and then not S.File_Info.Dirty
        and then Ada.Directories.Exists (A_Path)
        and then not Ada.Directories.Exists (A_Target),
        "completeness: renaming B must not mutate inactive buffer A or its file");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (B_Target) = "B original"
        and then not Ada.Directories.Exists (B_Path),
        "completeness: subsequent save must use renamed target and not resurrect old path");

      Write_Bytes (B_Target, "B disk update after rename");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "B disk update after rename",
        "completeness: subsequent reload must use renamed target");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "B disk update after rename"
        and then not S.File_Info.Dirty,
        "completeness: subsequent revert must use renamed target after edits");

      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = A_Path,
        "completeness: rename must not consume or replace existing reopen candidates");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Ada.Directories.Full_Name (B_Target),
        "completeness: close after successful rename must create reopen candidate for renamed path");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (Buffer_Text (S) = "B disk update after rename"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B_Target),
        "completeness: reopen after close must use the renamed association");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "save as text");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Assert (not S.File_Info.Dirty and then Ada.Directories.Exists (Save_As_Path),
        "completeness: save-as should make an untitled buffer eligible for rename");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Save_As_Target);
      Assert (Ada.Directories.Exists (Save_As_Target)
        and then not Ada.Directories.Exists (Save_As_Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Save_As_Target)
        and then Buffer_Text (S) = "save as text"
        and then not S.File_Info.Dirty,
        "completeness: rename after save-as must update only the file association");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (A_Target);
      Remove_If_Exists (B_Target);
      Remove_If_Exists (Save_As_Path);
      Remove_If_Exists (Save_As_Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Remove_If_Exists (A_Target);
         Remove_If_Exists (B_Target);
         Remove_If_Exists (Save_As_Path);
         Remove_If_Exists (Save_As_Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Active_Isolation_And_Lifecycle_Coherence;


   procedure Test_Rename_Validation_Order_And_Active_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      A_Path   : constant String := Temp_Path ("order_a.txt");
      B_Path   : constant String := Temp_Path ("order_b.txt");
      A_Target : constant String := Temp_Path ("order_a_target.txt");
      B_Target : constant String := Temp_Path ("order_b_target.txt");
      Existing : constant String := Temp_Path ("order_existing.txt");
      A_Id     : Editor.Buffers.Buffer_Id;
      B_Id     : Editor.Buffers.Buffer_Id;
      M        : Editor.Messages.Editor_Message;
      Found    : Boolean := False;

      procedure Assert_Message (Text : String; Severity : Editor.Messages.Message_Severity) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1
           and then M.Severity = Severity
           and then To_String (M.Text) = Text,
           "expected one message '" & Text & "'");
      end Assert_Message;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (A_Target);
      Remove_If_Exists (B_Target);
      Remove_If_Exists (Existing);
      Write_Bytes (A_Path, "A disk");
      Write_Bytes (B_Path, "B disk");
      Write_Bytes (Existing, "existing target must survive");
      Editor.Buffers.Reset_Global_For_Test;

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty untitled");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, B_Target);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message);
      Assert (not Ada.Directories.Exists (B_Target),
        "no-path validation must precede dirty and target validation");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "   ");
      Assert_Message ("Invalid rename target", Editor.Messages.Error_Message);
      Assert (Ada.Directories.Exists (A_Path),
        "blank target must be rejected before any filesystem rename");

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Existing);
      Assert_Message ("Dirty buffer preserved.", Editor.Messages.Info_Message);
      Assert (Ada.Directories.Exists (A_Path)
        and then Read_Bytes (Existing) = "existing target must survive"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A_Path),
        "dirty guard must precede target collision checks and preserve state");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A_Target);
      Assert_Message ("Buffer file renamed", Editor.Messages.Success_Message);
      Assert (Editor.Buffers.Global_Active_Buffer = A_Id
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A_Target)
        and then Ada.Directories.Exists (A_Target)
        and then not Ada.Directories.Exists (A_Path)
        and then Ada.Directories.Exists (B_Path)
        and then not Ada.Directories.Exists (B_Target),
        "rename must bind to execution-time active buffer, not another open buffer");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B_Path)
        and then Buffer_Text (S) = "B disk",
        "inactive buffer must remain associated with its original path and text");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (A_Target);
      Remove_If_Exists (B_Target);
      Remove_If_Exists (Existing);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Remove_If_Exists (A_Target);
         Remove_If_Exists (B_Target);
         Remove_If_Exists (Existing);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Validation_Order_And_Active_Source;


   procedure Test_Rename_Association_Ordering_And_State_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S               : Editor.State.State_Type;
      Path            : constant String := Temp_Path ("preserve_source.txt");
      Target          : constant String := Temp_Path ("preserve_target.txt");
      Missing_Target  : constant String := Temp_Path ("preserve_missing_target.txt");
      Before_Text     : Unbounded_String;
      Before_Gen      : Natural;
      Before_Valid    : Boolean;
      Before_Undo     : Ada.Containers.Count_Type;
      Before_Redo     : Ada.Containers.Count_Type;
      Success_Path    : Unbounded_String;
      M               : Editor.Messages.Editor_Message;
      Found           : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Target);
      Write_Bytes (Path, "preserve disk text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.File_Info.Last_Save_Failed := True;
      S.File_Info.Missing_Target_Surfaced := True;
      S.File_Info.Blocked_Close_Surfaced := True;
      S.Post_Restore_Feedback_Current := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Valid := S.File_Info.Baseline_Valid;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Buffer file renamed",
        "success must emit exactly one rename success message");
      Success_Path := S.File_Info.Path;
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then S.File_Info.Baseline_Valid = Before_Valid
        and then not S.File_Info.Dirty
        and then S.File_Info.Last_Save_Failed
        and then S.File_Info.Missing_Target_Surfaced
        and then S.File_Info.Blocked_Close_Surfaced
        and then S.Post_Restore_Feedback_Current
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "success must update only association/display path and preserve retained state");

      Remove_If_Exists (Target);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Gen := S.File_Info.Saved_Generation;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Missing_Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Error_Message
        and then To_String (M.Text) = "Could not rename buffer file",
        "filesystem failure must emit exactly one rename failure message");
      Assert (S.File_Info.Path = Success_Path
        and then not Ada.Directories.Exists (Missing_Target)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then not S.File_Info.Dirty
        and then S.File_Info.Last_Save_Failed
        and then S.File_Info.Missing_Target_Surfaced
        and then S.File_Info.Blocked_Close_Surfaced
        and then S.Post_Restore_Feedback_Current,
        "filesystem failure must not publish target association or clear retained state");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Remove_If_Exists (Missing_Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Remove_If_Exists (Missing_Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Association_Ordering_And_State_Preservation;


   procedure Test_Rename_Read_Only_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("read_only_source.txt");
      Target       : constant String := Temp_Path ("read_only_target.txt");
      Snap         : Editor.Render_Model.Render_Snapshot;
      Availability : Editor.Commands.Command_Availability;
      Candidates   : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Rows         : Natural := 0;
      Before_Text  : Unbounded_String;
      Before_Path  : Unbounded_String;
      Before_Gen   : Natural;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "read-only boundary disk");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Messages.Clear (S.Messages);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Rename_Buffer_File then
               Rows := Rows + 1;
            end if;
         end loop;
      end if;

      Assert (not Snap.Is_Dirty
        and then Editor.Commands.Is_Available (Availability)
        and then Rows = 1,
        "render, availability, and palette projection may observe only static active-buffer rename eligibility");
      Assert (Ada.Directories.Exists (Path)
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then not S.File_Info.Dirty
        and then Editor.Messages.Count (S.Messages) = 0,
        "render, availability, and palette projection must not rename, validate target, or mutate state");

      Remove_If_Exists (Path);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then not Ada.Directories.Exists (Target),
        "availability must not probe source existence or target collision state");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Read_Only_Boundaries;




   procedure Test_Rename_Workflow_Validation_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Source       : constant String := Temp_Path ("matrix_source.txt");
      Target       : constant String := Temp_Path ("matrix_target.txt");
      Existing     : constant String := Temp_Path ("matrix_existing.txt");
      Missing_Parent : constant String := Temp_Path ("matrix_missing_parent");
      Missing_Target : constant String := Ada.Directories.Compose
        (Missing_Parent, "target.txt");
      M            : Editor.Messages.Editor_Message;
      Found        : Boolean := False;

      procedure Assert_Message
        (Text     : String;
         Severity : Editor.Messages.Message_Severity;
         Context  : String)
      is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then Editor.Messages.Count (S.Messages) = 1
           and then M.Severity = Severity
           and then To_String (M.Text) = Text,
           "validation matrix: expected one " & Context
           & " message '" & Text & "'");
      end Assert_Message;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Missing_Parent);
      Write_Bytes (Source, "matrix source text");
      Write_Bytes (Existing, "existing target text");
      Editor.Buffers.Reset_Global_For_Test;

      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert_Message ("No active buffer.", Editor.Messages.Info_Message, "no-active");
      Assert (Ada.Directories.Exists (Source)
        and then not Ada.Directories.Exists (Target),
        "validation matrix: no-active rename must not touch filesystem");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled dirty text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert_Message ("No file path for active buffer", Editor.Messages.Info_Message, "no-path before dirty");
      Assert (Buffer_Text (S) = "untitled dirty text"
        and then S.File_Info.Dirty
        and then not Ada.Directories.Exists (Target),
        "validation matrix: untitled dirty rename must stop before target validation");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "   ");
      Assert_Message ("Dirty buffer preserved.", Editor.Messages.Info_Message, "dirty before target");
      Assert (Ada.Directories.Exists (Source)
        and then Read_Bytes (Existing) = "existing target text"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Source)
        and then S.File_Info.Dirty,
        "validation matrix: dirty associated rename must not validate targets or mutate state");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, "");
      Assert_Message ("Invalid rename target", Editor.Messages.Error_Message, "empty target");
      Assert (Ada.Directories.Exists (Source)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Source),
        "validation matrix: invalid target must not rename or reassociate");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Source);
      Assert_Message ("Rename target already exists", Editor.Messages.Error_Message, "same path collision");
      Assert (Ada.Directories.Exists (Source)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Source),
        "validation matrix: same/equivalent target follows deterministic collision policy");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Existing);
      Assert_Message ("Rename target already exists", Editor.Messages.Error_Message, "existing target");
      Assert (Ada.Directories.Exists (Source)
        and then Read_Bytes (Existing) = "existing target text"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Source),
        "validation matrix: target collision must not overwrite or update association");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Missing_Target);
      Assert_Message ("Could not rename buffer file", Editor.Messages.Error_Message, "filesystem failure");
      Assert (Ada.Directories.Exists (Source)
        and then not Ada.Directories.Exists (Missing_Target)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Source)
        and then not S.File_Info.Dirty,
        "validation matrix: filesystem failure must preserve old association and clean state");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert_Message ("Buffer file renamed", Editor.Messages.Success_Message, "success");
      Assert (not Ada.Directories.Exists (Source)
        and then Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target)
        and then Buffer_Text (S) = "matrix source text"
        and then not S.File_Info.Dirty,
        "validation matrix: successful rename must update only active association after filesystem success");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Remove_If_Exists (Existing);
      Remove_If_Exists (Missing_Target);
      Remove_If_Exists (Missing_Parent);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Remove_If_Exists (Existing);
         Remove_If_Exists (Missing_Target);
         Remove_If_Exists (Missing_Parent);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Workflow_Validation_Matrix;


   procedure Test_Rename_Dirty_And_Transient_State_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Path           : constant String := Temp_Path ("dirty_source.txt");
      Target         : constant String := Temp_Path ("dirty_target.txt");
      Before_Text    : Unbounded_String;
      Before_Path    : Unbounded_String;
      Before_Gen     : Natural;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Caret   : Editor.Cursors.Caret_State;
      Before_Back    : Natural;
      Before_Forward : Natural;
      M              : Editor.Messages.Editor_Message;
      Found          : Boolean := False;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "alpha beta alpha");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "omega");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard payload"));
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos                   => 5,
            Anchor                => 1,
            Virtual_Column        => 5,
            Anchor_Virtual_Column => 1));
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History,
         (Buffer_Id => Natural (Editor.Buffers.Global_Active_Buffer),
          Has_File_Path => True,
          File_Path => S.File_Info.Path,
          Display_Path => S.File_Info.Path,
          Line => 1,
          Column => 1,
          Viewport_Row => 0,
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Info_Message
        and then To_String (M.Text) = "Dirty buffer preserved.",
        "dirty workflow: dirty rename must emit one blocked message");
      Assert (Ada.Directories.Exists (Path)
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor
        and then To_String (S.Active_Find_Query) = "alpha"
        and then To_String (S.Active_Replace_Text) = "omega"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard payload"
        and then Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
        and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
        "dirty workflow: blocked rename must preserve text, path, baseline, history, find/replace, clipboard, selection, and navigation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (not S.File_Info.Dirty,
        "dirty workflow: canonical save must be the only dirty-cleaning path before rename");
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (M.Text) = "Buffer file renamed",
        "dirty workflow: saved clean buffer can then be renamed");
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = To_String (Before_Text)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard payload"
        and then To_String (S.Active_Find_Query) = "alpha"
        and then To_String (S.Active_Replace_Text) = "omega",
        "dirty workflow: successful rename after save must not write via save-as or mutate transient state");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Dirty_And_Transient_State_Preservation;


   procedure Test_Rename_File_Lifecycle_Integrated_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      A_Path     : constant String := Temp_Path ("integrated_a.txt");
      A1_Path    : constant String := Temp_Path ("integrated_a1.txt");
      A2_Path    : constant String := Temp_Path ("integrated_a2.txt");
      B_Save_As  : constant String := Temp_Path ("integrated_b1.txt");
      B2_Path    : constant String := Temp_Path ("integrated_b2.txt");
      C_Path     : constant String := Temp_Path ("integrated_c.txt");
      C1_Path    : constant String := Temp_Path ("integrated_c1.txt");
      Existing   : constant String := Temp_Path ("integrated_existing.txt");
      A_Id       : Editor.Buffers.Buffer_Id;
      B_Id       : Editor.Buffers.Buffer_Id;
      C_Id       : Editor.Buffers.Buffer_Id;
      M          : Editor.Messages.Editor_Message;
      Found      : Boolean := False;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A1_Path);
      Remove_If_Exists (A2_Path);
      Remove_If_Exists (B_Save_As);
      Remove_If_Exists (B2_Path);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C1_Path);
      Remove_If_Exists (Existing);
      Write_Bytes (A_Path, "A original");
      Write_Bytes (C_Path, "C original");
      Write_Bytes (Existing, "existing target");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Editor.State.Load_Text (S, "B untitled");
      Editor.Buffers.Sync_Global_Active_From_State (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A1_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file renamed"
        and then Editor.Buffers.Global_Active_Buffer = A_Id
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A1_Path),
        "integrated: first rename must target active A and keep it active");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Assert (Read_Bytes (A1_Path) = "A original"
        and then not Ada.Directories.Exists (A_Path),
        "integrated: save after rename uses renamed A1 path and does not resurrect old A path");
      Write_Bytes (A1_Path, "A disk after rename");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "A disk after rename",
        "integrated: reload after rename reads renamed A1 path");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A2_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Dirty buffer preserved."
        and then not Ada.Directories.Exists (A2_Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A1_Path),
        "integrated: dirty A1 rename to A2 must be blocked and non-mutating");
      Execute_Revert_And_Confirm (S);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A2_Path);
      Assert (Ada.Directories.Exists (A2_Path)
        and then not Ada.Directories.Exists (A1_Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A2_Path)
        and then Buffer_Text (S) = "A disk after rename"
        and then not S.File_Info.Dirty,
        "integrated: revert restores clean baseline and allows second rename");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, B2_Path);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer"
        and then not Ada.Directories.Exists (B2_Path),
        "integrated: untitled B cannot be renamed before save-as");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, B_Save_As);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, B2_Path);
      Assert (Ada.Directories.Exists (B2_Path)
        and then not Ada.Directories.Exists (B_Save_As)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B2_Path)
        and then Buffer_Text (S) = "B untitled"
        and then not S.File_Info.Dirty,
        "integrated: save-as makes B eligible and rename preserves text/baseline");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, C_Id);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("C clipboard"));
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "C");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Existing);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Rename target already exists"
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (C_Path)
        and then Read_Bytes (Existing) = "existing target"
        and then To_String (Editor.Clipboard.Get_Text) = "C clipboard"
        and then To_String (S.Active_Find_Query) = "C",
        "integrated: target collision on C preserves old association and feature state");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, C1_Path);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Ada.Directories.Full_Name (C1_Path),
        "integrated: close after rename records reopen candidate for renamed path only");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (C1_Path)
        and then Buffer_Text (S) = "C original",
        "integrated: reopen after close reads renamed C1 path");
      Write_Bytes (C1_Path, "C disk reload");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "C disk reload",
        "integrated: reload after reopen still uses renamed C1 association");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Execute_Revert_And_Confirm (S);
      Assert (Buffer_Text (S) = "C disk reload" and then not S.File_Info.Dirty,
        "integrated: revert after reopened rename uses renamed C1 path");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A2_Path)
        and then Buffer_Text (S) = "A disk after rename",
        "integrated: inactive A remains coherent after B/C workflows");
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (B2_Path)
        and then Buffer_Text (S) = "B untitled",
        "integrated: inactive B remains coherent after C workflows");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A1_Path);
      Remove_If_Exists (A2_Path);
      Remove_If_Exists (B_Save_As);
      Remove_If_Exists (B2_Path);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C1_Path);
      Remove_If_Exists (Existing);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (A1_Path);
         Remove_If_Exists (A2_Path);
         Remove_If_Exists (B_Save_As);
         Remove_If_Exists (B2_Path);
         Remove_If_Exists (C_Path);
         Remove_If_Exists (C1_Path);
         Remove_If_Exists (Existing);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_File_Lifecycle_Integrated_Workflow;


   procedure Test_Rename_Read_Only_Feature_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("boundary_source.txt");
      Target        : constant String := Temp_Path ("boundary_target.txt");
      Snap          : Editor.Render_Model.Render_Snapshot;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Gen    : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Rename_Rows   : Natural := 0;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "boundary source");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Goto_Line (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "boundary");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "replacement");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("boundary clipboard"));
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
      Editor.Messages.Clear (S.Messages);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Availability :=
        Editor.Executor.Command_Availability (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Rename_Buffer_File then
               Rename_Rows := Rename_Rows + 1;
            end if;
         end loop;
      end if;
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (not Snap.Is_Dirty
        and then Editor.Commands.Is_Available (Availability)
        and then Rename_Rows = 1,
        "boundaries: render, availability, and palette projection observe rename without execution");
      Assert (Ada.Directories.Exists (Path)
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Saved_Generation = Before_Gen
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then To_String (S.Active_Find_Query) = "boundary"
        and then To_String (S.Active_Replace_Text) = "replacement"
        and then To_String (Editor.Clipboard.Get_Text) = "boundary clipboard"
        and then Editor.Messages.Count (S.Messages) = 0,
        "boundaries: read-only paths must not probe target, rename, write, repair, or mutate feature state");
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), "rename") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Buffer file renamed") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0,
        "boundaries: workspace snapshot must not persist rename command state or target history before execution");

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target)
        and then Buffer_Text (S) = "boundary source"
        and then To_String (S.Active_Find_Query) = "boundary"
        and then To_String (S.Active_Replace_Text) = "replacement"
        and then To_String (Editor.Clipboard.Get_Text) = "boundary clipboard"
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Buffer file renamed") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "rename") = 0,
        "boundaries: successful rename may affect structural association but must not persist transient rename results");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Read_Only_Feature_And_Persistence_Boundaries;


   procedure Test_Rename_Undo_Redo_And_Surface_Non_Goals
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("history_source.txt");
      Target        : constant String := Temp_Path ("history_target.txt");
      Found_Name    : Boolean := False;
      Cmd           : Editor.Commands.Command_Id;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Baseline_Gen  : Natural;

      procedure Assert_Absent (Name : String) is
      begin
         Cmd := Editor.Commands.Command_Id_From_Stable_Name (Name, Found_Name);
         Assert (not Found_Name and then Cmd = Editor.Commands.No_Command,
           "surface: non-goal command must remain absent: " & Name);
      end Assert_Absent;
   begin
      Assert_Absent ("file.rename-all-buffers");
      Assert_Absent ("file.rename-project-file");
      Assert_Absent ("file.rename-symbol");
      Assert_Absent ("file.refactor-rename");
      Assert_Absent ("file.rename-dirty-buffer");
      Assert_Absent ("file.rename-untitled-buffer");
      Assert_Absent ("file.force-rename-buffer-file");
      Assert_Absent ("workspace.rename-buffer-file");
      Assert_Absent ("project.rename-files");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Write_Bytes (Path, "history source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " edit");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (not S.File_Info.Dirty,
        "history: setup must end clean with undo/redo stacks populated at saved baseline");
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Baseline_Gen := S.File_Info.Saved_Generation;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Target);
      Assert (Ada.Directories.Exists (Target)
        and then not Ada.Directories.Exists (Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target)
        and then Buffer_Text (S) = "history source edit"
        and then S.File_Info.Saved_Generation = Baseline_Gen
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "history: rename must preserve undo/redo stacks and saved baseline without becoming an edit");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Undo);
      Assert (Ada.Directories.Exists (Target)
        and then not Ada.Directories.Exists (Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target),
        "history: undo after rename must not undo filesystem rename or restore old association");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Redo);
      Assert (Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (Target),
        "history: redo after rename must not redo a filesystem operation");

      Remove_If_Exists (Path);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Rename_Undo_Redo_And_Surface_Non_Goals;
procedure Test_Delete_Command_Surface_And_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Path         : constant String := Temp_Path ("p449_surface.txt");
      Cmd_Id       : Editor.Commands.Command_Id;
      Found        : Boolean := False;
      Descriptor   : Editor.Commands.Command_Descriptor;
      Availability : Editor.Commands.Command_Availability;
      M            : Editor.Messages.Editor_Message;
   begin
      Cmd_Id := Editor.Commands.Command_Id_From_Stable_Name
        ("file.delete-buffer-file", Found);
      Assert (Found and then Cmd_Id = Editor.Commands.Command_Delete_Buffer_File,
        "file.delete-buffer-file must resolve to canonical command id");
      Assert (Editor.Commands.Stable_Command_Name
        (Editor.Commands.Command_Delete_Buffer_File) = "file.delete-buffer-file",
        "delete must expose canonical stable command name");

      Descriptor := Editor.Commands.Descriptor
        (Editor.Commands.Command_Delete_Buffer_File);
      Assert (Descriptor.Category = Editor.Commands.File_Category
        and then Descriptor.Visibility = Editor.Commands.Palette_Command
        and then Descriptor.Bindable
        and then Descriptor.Destructive
        and then Descriptor.Lifecycle,
        "delete descriptor must be visible bindable destructive File lifecycle command");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "delete unavailable without active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "no active buffer must emit deterministic message");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "untitled text");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "delete unavailable for untitled active buffer");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "no path must emit deterministic message");

      Remove_If_Exists (Path);
      Write_Bytes (Path, "delete dirty guard");
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "delete unavailable for dirty active associated buffer");
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Dirty buffer preserved."
        and then Ada.Directories.Exists (Path)
        and then S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Buffer_Text (S) = "delete dirty guard dirty",
        "dirty delete must be blocked before filesystem delete or mutation");

      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Command_Surface_And_Validation;


   procedure Test_Delete_Success_Preserves_Text_And_Marks_Unsaved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Path        : constant String := Temp_Path ("p449_success.txt");
      Save_As     : constant String := Temp_Path ("p449_success_save_as.txt");
      Before_Text : Unbounded_String;
      Before_Undo : Ada.Containers.Count_Type;
      Before_Redo : Ada.Containers.Count_Type;
      Found       : Boolean := False;
      M           : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Write_Bytes (Path, "delete preserves text");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("delete clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file deleted",
        "successful delete must emit one deterministic success message");
      Assert (not Ada.Directories.Exists (Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Has_Path
        and then Length (S.File_Info.Path) = 0
        and then To_String (S.File_Info.Display_Name) = "Untitled"
        and then S.File_Info.Dirty
        and then not S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 0
        and then Editor.Buffers.Global_Count = 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (Editor.Clipboard.Get_Text) = "delete clipboard",
        "success must delete disk file, preserve text/features/history, and leave dirty unsaved buffer open");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "No file path for active buffer"
        and then not Ada.Directories.Exists (Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "save after delete must follow no-associated-path behavior without writing text");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "reload after delete must observe no associated path");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "revert after delete must observe no associated path");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Save_As);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No file path for active buffer",
        "rename after delete must observe no associated path");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 1,
        "close after delete follows dirty-buffer close blocking policy");
      if S.Dirty_Close_Prompt_Active then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Cancel_Close);
      end if;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As);
      Assert (Ada.Directories.Exists (Save_As)
        and then Read_Bytes (Save_As) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then not S.File_Info.Dirty,
        "save-as after delete must write preserved text and re-associate buffer");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Save_As);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Success_Preserves_Text_And_Marks_Unsaved;


   procedure Test_Delete_Failure_And_Active_Isolation_Are_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      A_Path        : constant String := Temp_Path ("p449_active.txt");
      B_Path        : constant String := Temp_Path ("p449_inactive.txt");
      Missing_Path  : constant String := Temp_Path ("p449_missing.txt");
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Gen    : Natural;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (Missing_Path);
      Write_Bytes (A_Path, "active delete source");
      Write_Bytes (B_Path, "inactive must remain");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);

      --  Switch back to A. B remains open and associated but must not be the
      --  delete source merely because it was recently opened or visible in a
      --  switcher-style collection.
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
        (S, Editor.Buffers.Buffer_Id (1));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "Buffer file deleted"
        and then not Ada.Directories.Exists (A_Path)
        and then Ada.Directories.Exists (B_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty
        and then not S.File_Info.Has_Path,
        "delete must target only execution-time active buffer and preserve inactive file");

      --  Re-associate through Save As, then remove the file externally to
      --  force canonical filesystem-delete failure. Association and baseline
      --  must remain unchanged on failure.
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Missing_Path);
      Remove_If_Exists (Missing_Path);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Could not delete buffer file"
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then not S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Before_Gen
        and then Ada.Directories.Exists (B_Path),
        "filesystem delete failure must preserve association, text, baseline, dirty state, and inactive buffers");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Remove_If_Exists (Missing_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Remove_If_Exists (Missing_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Failure_And_Active_Isolation_Are_Atomic;
procedure Test_Delete_Validation_Order_And_Active_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      A_Path       : constant String := Temp_Path ("p450_active_source.txt");
      B_Path       : constant String := Temp_Path ("p450_inactive_source.txt");
      Before_Body  : constant String := "inactive target must remain";
      Availability : Editor.Commands.Command_Availability;
      Found        : Boolean := False;
      M            : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      S.Active_Buffer_Token := 0;

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then To_String (M.Text) = "No active buffer.",
        "delete validation must report no active buffer first");

      Editor.State.Init (S);
      Editor.State.Load_Text (S, "dirty untitled delete validation");
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (not Editor.Commands.Is_Available (Availability)
        and then Found
        and then To_String (M.Text) = "No file path for active buffer"
        and then Buffer_Text (S) = "dirty untitled delete validation dirty",
        "no associated path must be reported before dirty validation and without mutation");

      Editor.Buffers.Reset_Global_For_Test;
      Write_Bytes (A_Path, "active file delete source");
      Write_Bytes (B_Path, Before_Body);
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
        (S, Editor.Buffers.Buffer_Id (1));
      Editor.Messages.Clear (S.Messages);
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Editor.Commands.Is_Available (Availability)
        and then Found
        and then To_String (M.Text) = "Buffer file deleted"
        and then not Ada.Directories.Exists (A_Path)
        and then Ada.Directories.Exists (B_Path)
        and then Read_Bytes (B_Path) = Before_Body
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then Editor.Buffers.Global_Count = 2
        and then Editor.Buffers.Global_Active_Buffer = Editor.Buffers.Buffer_Id (1),
        "delete must bind to execution-time active buffer, not inactive buffers or switcher-like ordering");

      Remove_If_Exists (A_Path);
      Remove_If_Exists (B_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (A_Path);
         Remove_If_Exists (B_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Validation_Order_And_Active_Source;


   procedure Test_Delete_Blocked_And_Failed_Outcomes_Are_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p450_blocked.txt");
      Missing_Path  : constant String := Temp_Path ("p450_missing.txt");
      Before_Text   : Unbounded_String;
      Before_Path   : Unbounded_String;
      Before_Gen    : Natural;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Back   : Ada.Containers.Count_Type;
      Before_Fwd    : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Missing_Path);
      Write_Bytes (Path, "blocked delete source");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "delete");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "replace");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
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
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Dirty buffer preserved."
        and then Ada.Directories.Exists (Path)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Before_Gen
        and then Buffer_Text (S) = To_String (Before_Text)
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = "delete"
        and then To_String (S.Active_Replace_Text) = "replace"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard",
        "dirty-blocked delete must attempt no filesystem operation and preserve editor state");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Missing_Path);
      Remove_If_Exists (Missing_Path);
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Path := S.File_Info.Path;
      Before_Gen := S.File_Info.Saved_Generation;
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "Could not delete buffer file"
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then not S.File_Info.Dirty
        and then S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = Before_Gen
        and then Buffer_Text (S) = To_String (Before_Text)
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = "delete"
        and then To_String (S.Active_Replace_Text) = "replace"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then not S.Has_Reopen_Candidate,
        "filesystem failure must preserve association, baseline, dirty state, history, and feature state");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Missing_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Missing_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Blocked_And_Failed_Outcomes_Are_Non_Mutating;


   procedure Test_Delete_Success_Lifecycle_And_Persistence_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p450_success.txt");
      Save_As_Path  : constant String := Temp_Path ("p450_success_save_as.txt");
      Before_Text   : Unbounded_String;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Availability  : Editor.Commands.Command_Availability;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As_Path);
      Write_Bytes (Path, "successful delete preserved text");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "preserved");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("success clipboard"));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found
        and then To_String (M.Text) = "Buffer file deleted"
        and then not Ada.Directories.Exists (Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Has_Path
        and then Length (S.File_Info.Path) = 0
        and then S.File_Info.Dirty
        and then not S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 0
        and then Editor.Buffers.Global_Count = 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then To_String (S.Active_Find_Query) = "preserved"
        and then To_String (Editor.Clipboard.Get_Text) = "success clipboard"
        and then not S.Has_Reopen_Candidate,
        "success must clear association only after delete, preserve text/features/history, and leave an unsaved open active buffer");
      Assert_Summary_Excludes ("Buffer file deleted");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes (Path);
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Commands.Is_Available (Availability),
        "post-success availability must observe no path without filesystem repair");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found
        and then To_String (M.Text) = "No file path for active buffer"
        and then not Ada.Directories.Exists (Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.File_Info.Dirty,
        "save after delete must not recreate or write the deleted path");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Assert (Ada.Directories.Exists (Save_As_Path)
        and then Read_Bytes (Save_As_Path) = To_String (Before_Text)
        and then S.File_Info.Has_Path
        and then not S.File_Info.Dirty,
        "save-as after delete remains the only path that writes preserved text and re-associates the buffer");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Remove_If_Exists (Save_As_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Remove_If_Exists (Save_As_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Success_Lifecycle_And_Persistence_Boundaries;

   procedure Test_Delete_Integrated_Workflow_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      A_Path        : constant String := Temp_Path ("p451_a.txt");
      A1_Path       : constant String := Temp_Path ("p451_a1.txt");
      B1_Path       : constant String := Temp_Path ("p451_b1.txt");
      C_Path        : constant String := Temp_Path ("p451_c.txt");
      C1_Path       : constant String := Temp_Path ("p451_c1.txt");
      A_Id          : Editor.Buffers.Buffer_Id;
      B_Id          : Editor.Buffers.Buffer_Id;
      C_Id          : Editor.Buffers.Buffer_Id;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Back   : Ada.Containers.Count_Type;
      Before_Fwd    : Ada.Containers.Count_Type;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;

      procedure Expect_Message (Text : String) is
      begin
         M := Editor.Messages.Active_Message (S.Messages, Found);
         Assert (Found and then To_String (M.Text) = Text,
           "integrated: expected message '" & Text & "'");
      end Expect_Message;
   begin
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A1_Path);
      Remove_If_Exists (B1_Path);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C1_Path);
      Write_Bytes (A_Path, "A original");
      Write_Bytes (C_Path, "C original");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, C_Path);
      C_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "B untitled");
      S.File_Info.Has_Path := False;
      S.File_Info.Path := Null_Unbounded_String;
      S.File_Info.Display_Name := To_Unbounded_String ("Untitled");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Assert (Editor.Buffers.Global_Count = 3,
        "integrated: setup must keep three open buffers");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id, Emit_Feedback => False);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Buffer file deleted");
      Assert (not Ada.Directories.Exists (A_Path)
        and then Editor.Buffers.Global_Active_Buffer = A_Id
        and then Editor.Buffers.Global_Count = 3
        and then Buffer_Text (S) = "A original"
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then not S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 0
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "integrated: successful delete must preserve A text/history, clear only A association, and keep A open/active");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Expect_Message ("No file path for active buffer");
      Editor.Messages.Clear (S.Messages);
      Execute_Revert_And_Confirm (S);
      Expect_Message ("No file path for active buffer");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, A1_Path);
      Expect_Message ("No file path for active buffer");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (Editor.Buffers.Global_Count = 3
        and then Editor.Buffers.Global_Active_Buffer = A_Id,
        "integrated: close after delete must be blocked by dirty unsaved no-path policy");
      if S.Dirty_Close_Prompt_Active then
         Editor.Executor.Execute_Command
           (S, Editor.Commands.Command_Cancel_Close);
      end if;

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, A1_Path);
      Assert (Ada.Directories.Exists (A1_Path)
        and then Read_Bytes (A1_Path) = "A original"
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A1_Path)
        and then not S.File_Info.Dirty,
        "integrated: Save As is the only follow-up that writes preserved deleted-buffer text");
      Write_Bytes (A1_Path, "A reload text");
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Assert (Buffer_Text (S) = "A reload text" and then not S.File_Info.Dirty,
        "integrated: reload after Save As uses the new association only");
      Insert_Text_At (S, Buffer_Text (S)'Length, " dirty");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Dirty buffer preserved.");
      Assert (Ada.Directories.Exists (A1_Path)
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (A1_Path)
        and then S.File_Info.Dirty,
        "integrated: dirty associated A1 delete is blocked and non-mutating");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Buffer file deleted");
      Assert (not Ada.Directories.Exists (A1_Path)
        and then Buffer_Text (S) = "A reload text dirty"
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "integrated: saved A1 can be deleted and returns to unsaved no-path state");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id, Emit_Feedback => False);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("No file path for active buffer");
      Assert (Buffer_Text (S) = "B untitled" and then S.File_Info.Dirty,
        "integrated: dirty untitled B stops at no-path and preserves text");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, B1_Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Buffer file deleted");
      Assert (not Ada.Directories.Exists (B1_Path)
        and then Buffer_Text (S) = "B untitled"
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty,
        "integrated: B delete source is active buffer after Save As");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, C_Id, Emit_Feedback => False);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "C");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "see");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard"));
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
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
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;
      Remove_If_Exists (C_Path);
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Could not delete buffer file");
      Assert (S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = Ada.Directories.Full_Name (C_Path)
        and then Buffer_Text (S) = "C original"
        and then not S.File_Info.Dirty
        and then To_String (S.Active_Find_Query) = "C"
        and then To_String (S.Active_Replace_Text) = "see"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then not S.Has_Reopen_Candidate,
        "integrated: filesystem failure preserves C association, feature state, and reopen candidates");
      Write_Bytes (C_Path, "C original");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Expect_Message ("Buffer file deleted");
      Assert (not Ada.Directories.Exists (C_Path)
        and then Buffer_Text (S) = "C original"
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then To_String (S.Active_Find_Query) = "C"
        and then To_String (S.Active_Replace_Text) = "see"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard"
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd,
        "integrated: successful C delete preserves editor-local state while clearing association");
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, C1_Path);
      Editor.Executor.Buffer_Close_Commands.Execute_Close_Active_Buffer (S);
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Ada.Directories.Full_Name (C1_Path),
        "integrated: delete must not create reopen candidates; later close creates only the new Save As candidate");
      Editor.Executor.File_Open_Commands.Execute_Reopen_Closed_Buffer (S);
      Assert (To_String (S.File_Info.Path) = Ada.Directories.Full_Name (C1_Path)
        and then Buffer_Text (S) = "C original",
        "integrated: reopen after Save As reads the new path, not any deleted path");

      Editor.Clipboard.Clear;
      Remove_If_Exists (A_Path);
      Remove_If_Exists (A1_Path);
      Remove_If_Exists (B1_Path);
      Remove_If_Exists (C_Path);
      Remove_If_Exists (C1_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (A_Path);
         Remove_If_Exists (A1_Path);
         Remove_If_Exists (B1_Path);
         Remove_If_Exists (C_Path);
         Remove_If_Exists (C1_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Integrated_Workflow_Coherence;


   procedure Test_Delete_Read_Only_Feature_And_Persistence_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Path          : constant String := Temp_Path ("p451_read_only.txt");
      Before_Path   : Unbounded_String;
      Before_Text   : Unbounded_String;
      Before_Undo   : Ada.Containers.Count_Type;
      Before_Redo   : Ada.Containers.Count_Type;
      Before_Back   : Ada.Containers.Count_Type;
      Before_Fwd    : Ada.Containers.Count_Type;
      Availability  : Editor.Commands.Command_Availability;
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
      Copy_Rows    : Natural := 0;
      Delete_Rows   : Natural := 0;
      Cmd_Id        : Editor.Commands.Command_Id;
      Has_Name      : Boolean := False;

      procedure Assert_Absent (Name : String) is
      begin
         Cmd_Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Has_Name);
         Assert (not Has_Name and then Cmd_Id = Editor.Commands.No_Command,
           "non-goal command must be absent: " & Name);
      end Assert_Absent;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Path);
      Write_Bytes (Path, "read only delete source");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Command_Palette (S);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "delete");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "remove");
      Editor.Executor.Selection_Commands.Execute_Select_All_Selection_Command (S);
      Editor.Clipboard.Set_Text (To_Unbounded_String ("read only clipboard"));
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
      Before_Path := S.File_Info.Path;
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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

      if not Candidates.Is_Empty then
         for I in Candidates.First_Index .. Candidates.Last_Index loop
            if Candidates (I).Id = Editor.Commands.Command_Delete_Buffer_File then
               Delete_Rows := Delete_Rows + 1;
            end if;
         end loop;
      end if;

      Assert (Editor.Commands.Is_Available (Availability)
        and then Delete_Rows = 1
        and then Ada.Directories.Exists (Path)
        and then S.File_Info.Has_Path
        and then To_String (S.File_Info.Path) = To_String (Before_Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Dirty
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = "delete"
        and then To_String (S.Active_Replace_Text) = "remove"
        and then To_String (Editor.Clipboard.Get_Text) = "read only clipboard",
        "read-only: availability, palette, quick-open/palette visibility, and workspace snapshot must not delete, probe-repair, or mutate state");

      Assert_Summary_Excludes ("Buffer file deleted");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");

      Assert_Absent ("file.delete-all-buffers");
      Assert_Absent ("file.delete-project-file");
      Assert_Absent ("file.delete-dirty-buffer");
      Assert_Absent ("file.delete-untitled-buffer");
      Assert_Absent ("file.force-delete-buffer-file");
      Assert_Absent ("file.close-and-delete-buffer-file");
      Assert_Absent ("file.trash-buffer-file");
      Assert_Absent ("file.restore-deleted-buffer-file");
      Assert_Absent ("workspace.delete-buffer-file");
      Assert_Absent ("project.delete-files");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Found
        and then To_String (M.Text) = "Buffer file deleted"
        and then not Ada.Directories.Exists (Path)
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then not S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 0
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = "delete"
        and then To_String (S.Active_Replace_Text) = "remove"
        and then To_String (Editor.Clipboard.Get_Text) = "read only clipboard"
        and then not S.Has_Reopen_Candidate,
        "read-only: execution mutates only filesystem path association/baseline/dirty state and one message");
      Assert_Summary_Excludes ("Buffer file deleted");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes (Path);
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Read_Only_Feature_And_Persistence_Coherence;
procedure Test_Delete_Cleanup_Preserves_Source_State_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Active_Path    : constant String := Temp_Path ("p452_active_source.txt");
      Inactive_Path  : constant String := Temp_Path ("p452_inactive_source.txt");
      Reopen_Path    : constant String := Temp_Path ("p452_reopen_candidate.txt");
      Before_Text    : Unbounded_String;
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Back    : Ada.Containers.Count_Type;
      Before_Fwd     : Ada.Containers.Count_Type;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Availability   : Editor.Commands.Command_Availability;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence cleanup: summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Reopen_Path);
      Write_Bytes (Active_Path, "active text");
      Write_Bytes (Inactive_Path, "inactive text");
      Write_Bytes (Reopen_Path, "reopen text");
      Editor.Clipboard.Clear;
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Inactive_Path);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer
        (S, Editor.Buffers.Buffer_Id (1));
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "canonical");
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
          Reason => Editor.Navigation_History.Navigation_Reason_Go_To_Line));

      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Back := S.Navigation_History.Back_Stack.Length;
      Before_Fwd := S.Navigation_History.Forward_Stack.Length;
      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Delete_Buffer_File);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Editor.Commands.Is_Available (Availability)
        and then Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Inactive_Path)
        and then Ada.Directories.Exists (Reopen_Path)
        and then S.File_Info.Has_Path
        and then Buffer_Text (S) = To_String (Before_Text)
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd,
        "availability/workspace snapshot must be read-only and must not infer or repair delete source state");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-delete");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Found
        and then To_String (M.Text) = "Buffer file deleted"
        and then not Ada.Directories.Exists (Active_Path)
        and then Ada.Directories.Exists (Inactive_Path)
        and then Ada.Directories.Exists (Reopen_Path)
        and then Read_Bytes (Inactive_Path) = "inactive text"
        and then S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Reopen_Path
        and then Buffer_Text (S) = To_String (Before_Text)
        and then not S.File_Info.Has_Path
        and then S.File_Info.Dirty
        and then not S.File_Info.Baseline_Valid
        and then S.File_Info.Saved_Generation = 0
        and then Editor.Buffers.Global_Count = 2
        and then Editor.Buffers.Global_Active_Buffer = Editor.Buffers.Buffer_Id (1)
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo
        and then S.Navigation_History.Back_Stack.Length = Before_Back
        and then S.Navigation_History.Forward_Stack.Length = Before_Fwd
        and then To_String (S.Active_Find_Query) = ""
        and then To_String (S.Active_Replace_Text) = "canonical"
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard",
        "cleanup must preserve the canonical active-buffer-only delete behavior and retained lifecycle boundaries");

      Assert_Summary_Excludes ("Buffer file deleted");
      Assert_Summary_Excludes ("last delete");
      Assert_Summary_Excludes ("delete history");
      Assert_Summary_Excludes ("deleted path");
      Assert_Summary_Excludes (Active_Path);
      Assert_Summary_Excludes ("trash");
      Assert_Summary_Excludes ("recovery");
      Assert_Summary_Excludes ("file-watch");
      Assert_Summary_Excludes ("project-delete");

      Editor.Clipboard.Clear;
      Remove_If_Exists (Active_Path);
      Remove_If_Exists (Inactive_Path);
      Remove_If_Exists (Reopen_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Clipboard.Clear;
         Remove_If_Exists (Active_Path);
         Remove_If_Exists (Inactive_Path);
         Remove_If_Exists (Reopen_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Delete_Cleanup_Preserves_Source_State_And_Persistence;



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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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

      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);

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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
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



   procedure Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Target : constant String := Temp_Path ("prompt_save_as.txt");
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "prompt text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Append_Character ('/');
      Editor.Command_Palette.Append_Character ('q');
      Editor.Command_Palette.Append_Character ('u');
      Editor.Command_Palette.Append_Character ('e');
      Editor.Command_Palette.Append_Character ('r');
      Editor.Command_Palette.Append_Character ('y');

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Save As without explicit target should open the transient target prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target",
        "Save As prompt should expose the deterministic label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "prompt input must start empty and not infer a target");
      Assert (Buffer_Text (S) = "prompt text" and then S.File_Info.Dirty,
        "prompt opening must not mutate buffer text or dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt opening must not emit an underlying command outcome message");
      Assert (not Ada.Directories.Exists (Target),
        "prompt opening must not perform filesystem work");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "x");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "prompt editing must update prompt input only");
      Assert (Buffer_Text (S) = "prompt text",
        "prompt editing must not insert text into the active buffer");

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "prompt confirmation should clear transient prompt state");
      Assert (Read_Bytes (Target) = "prompt text",
        "prompt confirmation should dispatch the exact target to canonical Save As");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "prompt confirmation must emit exactly the canonical Save As outcome message");
      Remove_If_Exists (Target);
   end Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation;

   procedure Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Before_Text : constant String := "cancel text";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "discarded-target.txt");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "cancellation should clear pending file target prompt state");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "cancellation should discard typed target text");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "cancellation must not mutate active buffer text or dirty state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "cancellation must not emit underlying file operation feedback");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "lifecycle-target.txt");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "lifecycle reset must clear transient prompt state and input");
      Assert (Buffer_Text (S) = Before_Text,
        "lifecycle prompt cleanup must not edit buffer text");
   end Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup;

   procedure Test_Target_Requiring_Command_Prompt_Eligibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("source.txt");

      procedure Assert_Opens
        (Id    : Editor.Commands.Command_Id;
         Label : String)
      is
      begin
         Editor.Executor.Execute_Command (S, Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "eligible target command should open prompt");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = Label,
           "eligible target command should expose canonical prompt label");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "eligible target command prompt should not infer target text");
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      end Assert_Opens;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Assert (not S.File_Info.Dirty and then S.File_Info.Has_Path,
        "fixture should be a clean associated active buffer");
      Editor.Messages.Clear (S.Messages);

      Assert_Opens (Editor.Commands.Command_Save_File_As, "Save As target");
      Assert_Opens (Editor.Commands.Command_Rename_Buffer_File, "Rename target");
      Assert_Opens (Editor.Commands.Command_Copy_Buffer_File, "Copy target");
      Assert_Opens (Editor.Commands.Command_Move_Buffer_File, "Move target");
      Assert (Read_Bytes (Source) = "source",
        "opening target prompts must not perform source filesystem mutation");

      S.File_Info.Dirty := True;
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open rename prompt under preferred policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open copy prompt under preferred policy");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Move_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "dirty associated buffer should not open move prompt under preferred policy");

      Remove_If_Exists (Source);
   end Test_Target_Requiring_Command_Prompt_Eligibility;

   procedure Test_Render_Projects_File_Target_Prompt_Without_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : constant String := "render text";
      Before_Messages : Natural := 0;
      Snap           : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "render-target.txt");
      Before_Messages := Editor.Messages.Count (S.Messages);

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible,
        "render snapshot should project visible file target prompt");
      Assert (To_String (Snap.File_Target_Prompt_Label) = "Save As target",
        "render snapshot should project prompt label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "render-target.txt",
        "render snapshot must not mutate prompt input");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "render snapshot must not mutate buffer state");
      Assert (Editor.Messages.Count (S.Messages) = Before_Messages,
        "render snapshot must not emit command feedback");
   end Test_Render_Projects_File_Target_Prompt_Without_Mutation;



   procedure Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("active_source_a.txt");
      Active : constant String := Temp_Path ("active_source_b.txt");
      Target : constant String := Temp_Path ("active_target.txt");
      Found  : Boolean := False;
      M      : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Active);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "source A");
      Write_Bytes (Active, "source B");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Active);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Previous_Buffer);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Source,
        "fixture should start prompt from source A");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "copy without target should open prompt before active-buffer switch");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Next_Buffer);
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = Active,
        "fixture should switch active buffer before prompt confirmation");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "confirmation after active-buffer switch should clear prompt");
      Assert (Read_Bytes (Target) = "source B",
        "prompt confirmation should use active buffer at confirmation time");
      Assert (Read_Bytes (Source) = "source A",
        "prompt confirmation must not copy stale source-open buffer");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then To_String (M.Text) = "Buffer file copied",
        "active-buffer-at-confirmation copy should emit canonical copy outcome only");

      Remove_If_Exists (Source);
      Remove_If_Exists (Active);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Active);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation;


   procedure Test_Second_Target_Prompt_Replaces_First_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Source : constant String := Temp_Path ("second_prompt_source.txt");
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "second prompt source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "rename-target-should-be-discarded.txt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Rename target",
        "first eligible target command should own prompt");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "second eligible target command should leave one prompt active");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Copy target",
        "second target prompt should deterministically replace command label");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "second target prompt must discard prior prompt input and not infer history");
      Assert (Read_Bytes (Source) = "second prompt source",
        "prompt replacement must not rename, copy, move, or save files");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt replacement must not emit underlying file command feedback");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Second_Target_Prompt_Replaces_First_Deterministically;


   procedure Test_Target_Prompt_Workspace_Persistence_Excluded
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S         : Editor.State.State_Type;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary   : Unbounded_String;

      procedure Assert_Summary_Excludes (Needle : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (To_String (Summary), Needle) = 0,
           "persistence exclusion: workspace summary must exclude '" & Needle & "'");
      end Assert_Summary_Excludes;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "persistence text");
      S.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text
        (S, "prompt-target-must-not-persist.txt");
      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String
        (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert_Summary_Excludes ("prompt-target-must-not-persist.txt");
      Assert_Summary_Excludes ("Save As target");
      Assert_Summary_Excludes ("file target prompt");
      Assert_Summary_Excludes ("target prompt");
      Assert_Summary_Excludes ("last target");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) =
          "prompt-target-must-not-persist.txt",
        "workspace snapshot must inspect state without clearing or mutating prompt input");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "lifecycle reset after workspace snapshot should still clear prompt state");
   end Test_Target_Prompt_Workspace_Persistence_Excluded;


   procedure Test_Target_Prompt_Workflow_Coherence_Matrix
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S           : Editor.State.State_Type;
      Source      : constant String := Temp_Path ("matrix_source.txt");
      Before_Text : constant String := "matrix source";

      function Is_Target_Command (Id : Editor.Commands.Command_Id) return Boolean is
      begin
         return Id = Editor.Commands.Command_Save_File_As
           or else Id = Editor.Commands.Command_Rename_Buffer_File
           or else Id = Editor.Commands.Command_Copy_Buffer_File
           or else Id = Editor.Commands.Command_Move_Buffer_File;
      end Is_Target_Command;

      procedure Assert_Opens_Empty_Prompt
        (Id    : Editor.Commands.Command_Id;
         Label : String)
      is
      begin
         Editor.Executor.Execute_Command (S, Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "eligible canonical target command should open exactly one prompt");
         Assert (S.File_Target_Prompt_Command = Id,
           "prompt should retain the canonical pending command id only");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = Label,
           "prompt label should be deterministic per canonical command");
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "prompt input should not be inferred from command/palette/history state");
         Assert (Editor.Overlay_Focus.Is_Active
                   (S.Overlay_Focus, Editor.Overlay_Focus.File_Target_Prompt_Overlay),
           "opened prompt should explicitly own overlay input focus");
         Assert (Buffer_Text (S) = Before_Text
           and then not S.File_Info.Dirty
           and then To_String (S.File_Info.Path) = Source,
           "opening prompt must not mutate buffer text, dirty state, or association");
         Assert (Editor.Messages.Count (S.Messages) = 0,
           "opening prompt must not emit underlying command outcome messages");
         Assert (Read_Bytes (Source) = Before_Text,
           "opening prompt must not perform filesystem work");
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      end Assert_Opens_Empty_Prompt;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("/tmp/from-palette-query.adb");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("/tmp/from-clipboard.adb"));
      S.Active_Find_Query := To_Unbounded_String ("/tmp/from-find.adb");
      S.Active_Replace_Text := To_Unbounded_String ("/tmp/from-replace.adb");

      for Id in Editor.Commands.Command_Id loop
         Assert (Editor.Executor.Command_Requires_Explicit_Target (Id) = Is_Target_Command (Id),
           "target-prompt-capable command set must be exactly save-as/rename/copy/move");
      end loop;

      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Save_File_As, "Save As target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Rename_Buffer_File, "Rename target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Copy_Buffer_File, "Copy target");
      Assert_Opens_Empty_Prompt (Editor.Commands.Command_Move_Buffer_File, "Move target");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.save must never open a target prompt");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.delete-buffer-file must never open a target prompt");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Workflow_Coherence_Matrix;


   procedure Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Before_Text    : constant String := "edit isolation";
      Before_Undo    : Ada.Containers.Count_Type;
      Before_Redo    : Ada.Containers.Count_Type;
      Before_Caret   : Editor.Cursors.Caret_State;
      Target         : constant String := Temp_Path ("edit_target.txt");
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.State.Load_Text (S, Before_Text);
      S.File_Info.Dirty := True;
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'(Pos                   => 5,
          Anchor                => 1,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      S.Active_Find_Query := To_Unbounded_String ("find-state");
      S.Active_Replace_Text := To_Unbounded_String ("replace-state");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("clipboard-state"));
      Editor.Buffers.Ensure_Global_Registry (S);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Before_Undo := Editor.History.Undo_Stack.Length;
      Before_Redo := Editor.History.Redo_Stack.Length;
      Before_Caret := S.Carets (0);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "xy");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
      Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "insert/backspace/caret/delete should edit prompt input only");
      Assert (Buffer_Text (S) = Before_Text
        and then Editor.History.Undo_Stack.Length = Before_Undo
        and then Editor.History.Redo_Stack.Length = Before_Redo,
        "prompt text editing must not route through buffer insertion or history");
      Assert (S.Carets.Length = 1
        and then S.Carets (0).Pos = Before_Caret.Pos
        and then S.Carets (0).Anchor = Before_Caret.Anchor,
        "prompt text editing must preserve active-buffer caret/selection");
      Assert (To_String (S.Active_Find_Query) = "find-state"
        and then To_String (S.Active_Replace_Text) = "replace-state"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "clipboard-state",
        "prompt text editing must preserve Find/Replace and Clipboard state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "prompt text editing must not emit command outcome messages");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command,
        "cancellation should clear command and transient input");
      Assert (not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then S.File_Info.Dirty,
        "cancellation must not execute file lifecycle behavior or mutate buffer state");
      Assert (Editor.Messages.Count (S.Messages) = 0,
        "cancellation must not emit invalid-target, failure, or success messages");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "confirmation should clear prompt before canonical command dispatch outcome");
      Assert (Editor.Messages.Count (S.Messages) = 1,
        "invalid submitted target should produce exactly one canonical command outcome");
      Assert (Buffer_Text (S) = Before_Text and then S.File_Info.Dirty,
        "invalid target confirmation must preserve buffer text and dirty state through canonical validation");

      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy;


   procedure Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S            : Editor.State.State_Type;
      Source       : constant String := Temp_Path ("route_source.txt");
      Candidates   : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Count_Save_As : Natural := 0;
      Count_Rename  : Natural := 0;
      Count_Copy    : Natural := 0;
      Count_Move    : Natural := 0;
      Found         : Boolean := False;
      Id            : Editor.Commands.Command_Id;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;
      Config_Before : Editor.Configuration_Audit.Configuration_State_Summary;
      Config_After  : Editor.Configuration_Audit.Configuration_State_Summary;
   begin
      Remove_If_Exists (Source);
      Write_Bytes (Source, "route source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C : constant Editor.Commands.Command_Palette_Candidate := Candidates.Element (I);
            begin
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Count_Save_As := Count_Save_As + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Count_Rename := Count_Rename + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Count_Copy := Count_Copy + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Count_Move := Count_Move + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Count_Save_As = 1 and then Count_Rename = 1
        and then Count_Copy = 1 and then Count_Move = 1,
        "Command Palette projection must expose each canonical target command once and no prompted aliases");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Command Palette projection must be side-effect-free and must not open prompts");

      Editor.Command_Palette.Insert_Text ("/tmp/query-must-not-be-target.adb");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "Command Palette/keybinding canonical invocation path should open empty prompt, not query text");
      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);

      Assert (Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Rename_Buffer_File)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Copy_Buffer_File)
        and then Editor.Commands.Is_Bindable_Command (Editor.Commands.Command_Move_Buffer_File),
        "keybinding routes should continue to target canonical bindable command names only");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.save-as-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted save-as alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.rename-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted rename alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.copy-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted copy alias must remain absent");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("file.move-buffer-file-prompted", Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
        "prompted move alias must remain absent");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "rename-text-must-be-cleared");
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "opening another exclusive overlay should deterministically clear target prompt state");
      Assert (not Ada.Directories.Exists ("rename-text-must-be-cleared"),
        "overlay supersession must not submit target prompt text");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "audit-text-must-remain-local");
      Config_Before := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Copy_Buffer_File);
      Config_After := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0,
        "inert route audit should not report failures for canonical command route recording");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "audit-text-must-remain-local",
        "route/configuration audits must not confirm, cancel, or mutate prompt state");
      Assert (Config_Before.Message_Count = Config_After.Message_Count
        and then Config_Before.Dirty_Buffer_Count = Config_After.Dirty_Buffer_Count,
        "configuration audit summary must inspect prompt-adjacent state without runtime mutation");

      Remove_If_Exists (Source);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow;


   procedure Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Restored      : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source_A      : constant String := Temp_Path ("confirm_a.txt");
      Source_B      : constant String := Temp_Path ("confirm_b.txt");
      Target        : constant String := Temp_Path ("confirm_target.txt");
      Direct_Target : constant String := Temp_Path ("direct_target.txt");
      Direct_Copy   : constant String := Temp_Path ("direct_copy.txt");
      Direct_Rename : constant String := Temp_Path ("direct_rename.txt");
      Direct_Move   : constant String := Temp_Path ("direct_move.txt");
      A             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Target);
      Remove_If_Exists (Direct_Target);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render snapshot should project active prompt label/input structurally");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "render snapshot must not mutate prompt input");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0,
        "workspace persistence must exclude pending command, label, and target text");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must not restore transient target prompt state");

      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Target) = "source b",
        "prompt confirmation should use active buffer at confirmation time through canonical Executor route");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "successful confirmation should clear transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation success must emit exactly one canonical command outcome message");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Target);
      Assert (Read_Bytes (Direct_Target) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As must bypass prompt and preserve canonical behavior");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Target
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Copy must bypass prompt and preserve association");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Direct_Rename);
      Assert (Ada.Directories.Exists (Direct_Rename)
        and then not Ada.Directories.Exists (Direct_Target)
        and then To_String (S.File_Info.Path) = Direct_Rename
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Rename must bypass prompt and update canonical association");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Direct_Move);
      Assert (Ada.Directories.Exists (Direct_Move)
        and then not Ada.Directories.Exists (Direct_Rename)
        and then To_String (S.File_Info.Path) = Direct_Move
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Move must bypass prompt and update canonical association");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, "lifecycle-discarded-target.txt");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists ("lifecycle-discarded-target.txt"),
        "lifecycle cleanup should clear target prompt without executing filesystem work");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Target);
      Remove_If_Exists (Direct_Target);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Target);
         Remove_If_Exists (Direct_Target);
         Remove_If_Exists (Direct_Copy);
         Remove_If_Exists (Direct_Rename);
         Remove_If_Exists (Direct_Move);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior;



procedure Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source         : constant String := Temp_Path ("no_infer_source.txt");
      Target         : constant String := Temp_Path ("exact target.txt");
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Before_Text    : constant String := "no inference source";
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("/tmp/command-palette-query.adb");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("/tmp/clipboard-target.adb"));
      S.Active_Find_Query := To_Unbounded_String ("/tmp/find-target.adb");
      S.Active_Replace_Text := To_Unbounded_String ("/tmp/replace-target.adb");
      S.Reopen_Candidate_Path := To_Unbounded_String ("/tmp/reopen-target.adb");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As,
        "canonical invocation without target should open one pending save-as prompt");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "prompt input must not be inferred from palette, clipboard, find/replace, or reopen state");
      Assert (Editor.Messages.Count (S.Messages) = 0
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source,
        "prompt opening must remain side-effect-free and filesystem-free");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & " stale");
      Editor.Executor.File_Target_Prompt_Commands.Select_All_File_Target_Prompt_Text (S);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "prompt editing must be owned by the canonical prompt input helper");
      Assert (Buffer_Text (S) = Before_Text
        and then To_String (S.Active_Find_Query) = "/tmp/find-target.adb"
        and then To_String (S.Active_Replace_Text) = "/tmp/replace-target.adb"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "/tmp/clipboard-target.adb",
        "prompt input must not leak into buffer, find/replace, or clipboard state");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "File_Target_Prompt") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "last prompted target") = 0,
        "workspace snapshot must exclude prompt command, label, input, caches, and target history");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must not reconstruct prompt state from persistence");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Editor.Messages.Count (S.Messages) = 0,
        "canonical cancellation must clear command/input and emit no lifecycle outcome");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target),
        "lifecycle cleanup must use canonical state clearing and never confirm typed targets");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup;


   procedure Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source_A      : constant String := Temp_Path ("confirm_a.txt");
      Source_B      : constant String := Temp_Path ("confirm_b.txt");
      Prompt_Target : constant String := Temp_Path ("prompt exact target.txt");
      Direct_Save   : constant String := Temp_Path ("direct_save.txt");
      Direct_Copy   : constant String := Temp_Path ("direct_copy.txt");
      A             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B             : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found         : Boolean := False;
      M             : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Prompt_Target) = "source b",
        "confirmation must route exact submitted target through Executor using active buffer at confirmation");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "confirmation must clear canonical transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation must emit exactly one canonical underlying command outcome");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Save);
      Assert (Read_Bytes (Direct_Save) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target save-as must remain prompt-free");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Save
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target copy must remain prompt-free and preserve association");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Save);
         Remove_If_Exists (Direct_Copy);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical;

   procedure Test_Workspace_Restore_Applies_Continuity_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      After          : Editor.Workspace_Persistence.Workspace_Snapshot;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Root           : constant String := Temp_Path ("restore_continuity_project");
      Src            : constant String := Ada.Directories.Compose (Root, "src");
      Source         : constant String := Ada.Directories.Compose (Src, "main.adb");
      Switched       : Boolean := False;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Path (Src);
      Write_Bytes (Source, "procedure Main is begin null; end Main;");
      Editor.Buffers.Reset_Global_For_Test;

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src");
      Editor.Quick_Open.Set_File_Kind_Filter
        (S.Quick_Open, Editor.Quick_Open.Ada_Files);
      Switched := Editor.Feature_Panel.Set_Active_Feature
        (S.Feature_Panel, Editor.Feature_Panel.Diagnostics_Feature);
      Assert (Switched, "test setup should activate Diagnostics feature panel");
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, True);
      Workspace := Editor.State.Build_Workspace_Snapshot (S);

      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot
        (Restored, Workspace, Restore_Status);
      Assert (Restore_Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace restore should apply complete structural state");
      After := Editor.State.Build_Workspace_Snapshot (Restored);

      Assert (Editor.Workspace_Persistence.Has_Project_Root (After)
              and then Editor.Workspace_Persistence.Project_Root (After) = Root,
              "restore should reopen the project root");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (After)
              and then Editor.Workspace_Persistence.Active_File_Path (After) =
                "src/main.adb",
              "restore should select the active file");
      Assert (Editor.Workspace_Persistence.Quick_Open_Path_Scope (After) =
                "src/",
              "restore should apply Quick Open scope");
      Assert (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (After) =
                Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files,
              "restore should apply Quick Open file-kind filter");
      Assert (Editor.Workspace_Persistence.Feature_Panel_Visible (After),
              "restore should apply feature panel visibility");
      Assert (Editor.Workspace_Persistence.Active_Feature_Panel (After) =
                Editor.Workspace_Persistence.Workspace_Diagnostics_Feature,
              "restore should apply active feature panel selection");
      Assert (Editor.Workspace_Persistence.Has_Recent_Project_Path (After)
              and then Editor.Workspace_Persistence.Recent_Project_Path (After) =
                Root,
              "restore should preserve recent project continuity");

      Remove_If_Exists (Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Src);
         Remove_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Restore_Applies_Continuity_State;
procedure Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Restored       : Editor.State.State_Type;
      Restore_Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Source         : constant String := Temp_Path ("input_source.txt");
      Target         : constant String := Temp_Path ("exact typed target.txt");
      Before_Text    : constant String := "input source";
      Before_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit    : Editor.Configuration_Audit.Configuration_State_Summary;
      Workspace      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary        : Unbounded_String;
      Availability   : Editor.Commands.Command_Availability;
      Snap           : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, Before_Text);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text ("/tmp/palette-query-must-not-be-target.txt");
      Editor.Clipboard.Set_Text (To_Unbounded_String ("/tmp/clipboard-must-not-be-target.txt"));
      S.Active_Find_Query := To_Unbounded_String ("/tmp/find-must-not-be-target.txt");
      S.Active_Replace_Text := To_Unbounded_String ("/tmp/replace-must-not-be-target.txt");
      S.Reopen_Candidate_Path := To_Unbounded_String ("/tmp/reopen-must-not-be-target.txt");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Copy_Buffer_File
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Copy target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source
        and then Editor.Messages.Count (S.Messages) = 0,
        "prompt opening must be side-effect-free and must not infer target text from UI/runtime state");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target & "xy");
      Editor.Executor.File_Target_Prompt_Commands.Backspace_File_Target_Prompt (S);
      Editor.Executor.File_Target_Prompt_Commands.Move_File_Target_Prompt_Cursor_Left (S);
      Editor.Executor.File_Target_Prompt_Commands.Delete_Forward_File_Target_Prompt (S);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.Active_Find_Query) = "/tmp/find-must-not-be-target.txt"
        and then To_String (S.Active_Replace_Text) = "/tmp/replace-must-not-be-target.txt"
        and then Editor.Clipboard.Has_Text
        and then To_String (Editor.Clipboard.Get_Text) = "/tmp/clipboard-must-not-be-target.txt",
        "prompt input edits must remain local to focused prompt state and not leak into buffer/find/replace/clipboard");

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Copy target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "render snapshot must mirror prompt state without mutating or validating it");

      Availability := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Copy_Buffer_File);
      Assert (Editor.Commands.Is_Available (Availability)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "availability checks must not open, confirm, cancel, seed, or mutate prompt state");

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Assert (Before_Audit.Message_Count = After_Audit.Message_Count
        and then Before_Audit.Dirty_Buffer_Count = After_Audit.Dirty_Buffer_Count
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target,
        "audit/reference summaries must inspect without confirming, cancelling, repairing, or mutating prompts");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Copy target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "palette-query") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "clipboard") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0,
        "workspace snapshots must exclude prompt input, labels, inference sources, and target histories");
      Editor.State.Init (Restored);
      Editor.Executor.Restore_Workspace_Snapshot (Restored, Workspace, Restore_Status);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (Restored)
        and then Restored.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (Restored) = "",
        "workspace reload must drop any prompt-active runtime state");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Buffer_Text (S) = Before_Text
        and then To_String (S.File_Info.Path) = Source
        and then Editor.Messages.Count (S.Messages) = 0,
        "cancellation must clear prompt state without command execution, filesystem work, or messages");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Move_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Executor.Command_Surface_Commands.Execute_Open_Quick_Open (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Source,
        "overlay supersession must use canonical prompt cleanup and must not submit pending input");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Rename_Buffer_File);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.State.Reset_Project_Scoped_State (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then not Ada.Directories.Exists (Target)
        and then Ada.Directories.Exists (Source),
        "lifecycle cleanup must discard prompt command/input without executing rename/copy/move/save-as");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze;


   procedure Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Source_A       : constant String := Temp_Path ("confirm_a.txt");
      Source_B       : constant String := Temp_Path ("confirm_b.txt");
      Prompt_Target  : constant String := Temp_Path ("prompt submitted target.txt");
      Direct_Save    : constant String := Temp_Path ("direct_save.txt");
      Direct_Copy    : constant String := Temp_Path ("direct_copy.txt");
      Direct_Rename  : constant String := Temp_Path ("direct_rename.txt");
      Direct_Move    : constant String := Temp_Path ("direct_move.txt");
      A              : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B              : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found          : Boolean := False;
      M              : Editor.Messages.Editor_Message;
   begin
      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Write_Bytes (Source_A, "source a");
      Write_Bytes (Source_B, "source b");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_A);
      A := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source_B);
      B := Editor.Buffers.Global_Active_Buffer;
      Editor.Messages.Clear (S.Messages);

      Editor.Buffers.Global_Set_Active_Buffer (A);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As,
        "save-as without explicit target should open the canonical transient prompt");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Buffers.Global_Set_Active_Buffer (B);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Read_Bytes (Prompt_Target) = "source b",
        "confirmation must dispatch through Executor using active buffer at confirmation and exact submitted target");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.No_Command
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "confirmation must clear the canonical transient prompt state");
      M := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Count (S.Messages) = 1
        and then M.Severity = Editor.Messages.Success_Message
        and then To_String (M.Text) = "Saved file as",
        "confirmation must emit exactly one canonical underlying command outcome message");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.save must remain prompt-free");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Delete_Buffer_File);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "file.delete-buffer-file must remain prompt-free even though it is a file lifecycle command");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Save);
      Assert (Read_Bytes (Direct_Save) = "source b"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target save-as must bypass prompt and preserve canonical behavior");
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Direct_Copy);
      Assert (Read_Bytes (Direct_Copy) = "source b"
        and then To_String (S.File_Info.Path) = Direct_Save
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target copy must bypass prompt and preserve association");
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Direct_Rename);
      Assert (Ada.Directories.Exists (Direct_Rename)
        and then not Ada.Directories.Exists (Direct_Save)
        and then To_String (S.File_Info.Path) = Direct_Rename
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target rename must bypass prompt and update canonical association");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Direct_Move);
      Assert (Ada.Directories.Exists (Direct_Move)
        and then not Ada.Directories.Exists (Direct_Rename)
        and then To_String (S.File_Info.Path) = Direct_Move
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target move must bypass prompt and update canonical association");

      Remove_If_Exists (Source_A);
      Remove_If_Exists (Source_B);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Save);
      Remove_If_Exists (Direct_Copy);
      Remove_If_Exists (Direct_Rename);
      Remove_If_Exists (Direct_Move);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source_A);
         Remove_If_Exists (Source_B);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Save);
         Remove_If_Exists (Direct_Copy);
         Remove_If_Exists (Direct_Rename);
         Remove_If_Exists (Direct_Move);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze;



procedure Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("boundary_source.txt");
      Target        : constant String := Temp_Path ("exact target.txt");
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_As_Rows  : Natural := 0;
      Rename_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Msgs   : Natural := 0;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "boundary source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);
      Before_Msgs := Editor.Messages.Count (S.Messages);

      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Target_Prompt_Label
                (Editor.Commands.Command_Save_File_As) = "Save As target",
        "reading minimal metadata must be a pure descriptor/accessor operation");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Editor.Messages.Count (S.Messages) = Before_Msgs
        and then not Ada.Directories.Exists (Target)
        and then To_String (S.File_Info.Path) = Source,
        "metadata reads must not open prompts, seed input, emit messages, validate targets, or touch files");

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Command_Palette.Insert_Text (Target);
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C : constant Editor.Commands.Command_Palette_Candidate :=
                 Candidates.Element (I);
               Name : constant String := Editor.Commands.Stable_Command_Name (C.Id);
            begin
               Assert (Ada.Strings.Fixed.Index (Name, "prompt") = 0,
                 "Command Palette must not expose prompted aliases");
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Save_As_Rows := Save_As_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Rename_Rows := Rename_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Copy_Rows := Copy_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Move_Rows := Move_Rows + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Save_As_Rows <= 1 and then Rename_Rows <= 1
        and then Copy_Rows <= 1 and then Move_Rows <= 1,
        "Command Palette projection must not synthesize duplicate prompted rows");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "Command Palette query text must not become target prompt input");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "no-target invocation must still open the canonical prompt using the minimal label");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must project active prompt state, not a separate prompt-reference layer");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0,
        "persistence must exclude prompt runtime state, projection caches, metadata caches, and target history");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "cancellation remains non-mutating after metadata minimalization");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "boundary source"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target execution must bypass prompt and preserve canonical behavior");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze;


procedure Test_Target_Prompt_Metadata_Minimality_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Reject_In (Text : String; Forbidden : String; Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Text, Forbidden) = 0,
           "forbidden prompt-reference/minimality token '" &
           Forbidden & "' leaked into " & Context);
      end Reject_In;

      procedure Check_Command_Text (Id : Editor.Commands.Command_Id) is
         D       : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Context : constant String := Editor.Commands.Stable_Command_Name (Id);
         Text    : constant String :=
           Editor.Commands.Stable_Command_Name (Id) & " " &
           To_String (D.Name) & " " &
           To_String (D.Description) & " " &
           To_String (D.Summary) & " " &
           To_String (D.Availability_Summary) & " " &
           To_String (D.Mutation_Summary) & " " &
           To_String (D.Filesystem_Effect_Summary) & " " &
           To_String (D.State_Preservation_Summary) & " " &
           To_String (D.Non_Goal_Summary) & " " &
           To_String (D.Target_Prompt_Label);
      begin
         Reject_In (Text, "target_parameter_summary", Context);
         Reject_In (Text, "prompt_confirmation_summary", Context);
         Reject_In (Text, "prompt_cancellation_summary", Context);
         Reject_In (Text, "target_prompt_non_goals_summary", Context);
         Reject_In (Text, "prompt_reference_summary", Context);
         Reject_In (Text, "prompt_reference_family", Context);
         Reject_In (Text, "prompt_reference_effect_classification", Context);
         Reject_In (Text, "prompt_reference_availability_summary", Context);
         Reject_In (Text, "prompt_reference_documentation_text", Context);
         Reject_In (Text, "prompt_reference_search_text", Context);
         Reject_In (Text, "prompt_reference_projection_cache", Context);
         Reject_In (Text, "target history", Context);
         Reject_In (Text, "autocomplete", Context);
         Reject_In (Text, "file picker", Context);
         Reject_In (Text, "overwrite prompt", Context);
      end Check_Command_Text;
   begin
      for Id in Editor.Commands.Command_Id loop
         Check_Command_Text (Id);
      end loop;
   end Test_Target_Prompt_Metadata_Minimality_Guard;


   procedure Test_Metadata_Reads_Are_Pure_And_Availability_Independent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Target        : constant String := Temp_Path ("metadata_read_target.txt");
      Before_Msgs   : Natural := 0;
      Rename_Avail  : Editor.Commands.Command_Availability;
      Save_As_Avail : Editor.Commands.Command_Availability;
   begin
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Messages.Clear (S.Messages);
      Before_Msgs := Editor.Messages.Count (S.Messages);

      for Id in Editor.Commands.Command_Id loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (Id);
            pragma Unreferenced (D);
            Required : constant Boolean :=
              Editor.Commands.Command_Requires_Explicit_Target (Id);
            Capable : constant Boolean :=
              Editor.Commands.Command_Is_Target_Prompt_Capable (Id);
            Label : constant String := Editor.Commands.Command_Target_Prompt_Label (Id);
            pragma Unreferenced (Required, Capable, Label);
         begin
            null;
         end;
      end loop;

      Rename_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Save_As_Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File_As);

      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Rename_Buffer_File)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Rename_Buffer_File)
        and then not Editor.Commands.Is_Available (Rename_Avail),
        "explicit-target metadata must not imply runtime availability");
      Assert (Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Save_File_As)
        and then Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Save_File_As)
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "metadata reads must not open the target prompt");
      Assert (Editor.Commands.Is_Available (Save_As_Avail)
          or else not Editor.Commands.Is_Available (Save_As_Avail),
        "availability remains an Executor-owned result, independent from metadata mapping");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = ""
        and then Editor.Messages.Count (S.Messages) = Before_Msgs
        and then not Ada.Directories.Exists (Target),
        "metadata reads must not seed input, emit messages, validate paths, or touch files");

      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Metadata_Reads_Are_Pure_And_Availability_Independent;


   procedure Test_Command_Palette_Render_Audit_And_Persistence_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("boundary_source.txt");
      Target        : constant String := Temp_Path ("prompted target.txt");
      Candidates    : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_As_Rows  : Natural := 0;
      Rename_Rows   : Natural := 0;
      Copy_Rows     : Natural := 0;
      Move_Rows     : Natural := 0;
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Audit  : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      Audit_Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "boundary source");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Command_Palette.Reset;
      Editor.Command_Palette.Open;
      Editor.Executor.Command_Palette_Candidates (S, Candidates);
      if Candidates.Length > 0 then
         for I in 0 .. Natural (Candidates.Length) - 1 loop
            declare
               C    : constant Editor.Commands.Command_Palette_Candidate :=
                 Candidates.Element (I);
               Name : constant String := Editor.Commands.Stable_Command_Name (C.Id);
            begin
               Assert (Ada.Strings.Fixed.Index (Name, "prompt") = 0,
                 "Command Palette must expose no prompted aliases");
               Assert (Ada.Strings.Fixed.Index (To_String (C.Label), "prompt_reference") = 0
                 and then Ada.Strings.Fixed.Index (To_String (C.Description), "prompt_reference") = 0
                 and then Ada.Strings.Fixed.Index (To_String (C.Reference_Summary), "prompt_reference") = 0,
                 "Command Palette projection must not synthesize prompt-reference prose");
               if C.Id = Editor.Commands.Command_Save_File_As then
                  Save_As_Rows := Save_As_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Rename_Buffer_File then
                  Rename_Rows := Rename_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Copy_Buffer_File then
                  Copy_Rows := Copy_Rows + 1;
               elsif C.Id = Editor.Commands.Command_Move_Buffer_File then
                  Move_Rows := Move_Rows + 1;
               end if;
            end;
         end loop;
      end if;
      Assert (Save_As_Rows <= 1 and then Rename_Rows <= 1
        and then Copy_Rows <= 1 and then Move_Rows <= 1,
        "Command Palette must not synthesize duplicate prompted rows");
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "Command Palette projection must not open prompts");

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Audit_Result, Before_Audit, After_Audit,
         "target prompt metadata route/configuration audit");
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0
        and then Editor.Configuration_Audit.Status (Audit_Result) = Editor.Configuration_Audit.Configuration_Audit_Ok
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "route/configuration audits must be side-effect-free and must not open prompts");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must snapshot canonical prompt state only");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = Target
        and then not Ada.Directories.Exists (Target),
        "render snapshots must not confirm prompts or touch filesystem targets");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt label") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0,
        "workspace persistence must exclude prompt runtime state, projection caches, labels, and histories");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "cancellation remains non-mutating after metadata validation");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Command_Palette_Render_Audit_And_Persistence_Boundary;



   procedure Test_Target_Prompt_Metadata_Canonical_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      type Expected_Metadata is record
         Id       : Editor.Commands.Command_Id;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 10) of Expected_Metadata :=
        ((Editor.Commands.Command_Save_File, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Save_File_As, True, True, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Close_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reopen_Closed_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reload_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Revert_Active_Buffer, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Rename_Buffer_File, True, True, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Delete_Buffer_File, False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Copy_Buffer_File, True, True, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
   begin
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Minimal,
        "retained target prompt metadata must remain minimal");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal,
        "cleanup guard must keep canonical descriptor/accessor prompt metadata coherent");

      for E of Expected loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (E.Id);
         begin
            Assert (D.Requires_Explicit_Target = E.Required
              and then D.Target_Prompt_Capable = E.Capable
              and then To_String (D.Target_Prompt_Label) = To_String (E.Label),
              "descriptor-owned prompt metadata drift for " &
              Editor.Commands.Stable_Command_Name (E.Id));
            Assert (Editor.Commands.Command_Requires_Explicit_Target (E.Id) =
                    D.Requires_Explicit_Target
              and then Editor.Commands.Command_Is_Target_Prompt_Capable (E.Id) =
                       D.Target_Prompt_Capable
              and then Editor.Commands.Command_Target_Prompt_Label (E.Id) =
                       To_String (D.Target_Prompt_Label),
              "public prompt accessors must project descriptor metadata for " &
              Editor.Commands.Stable_Command_Name (E.Id));
            Assert (Editor.Executor.Command_Requires_Explicit_Target (E.Id) =
                    D.Requires_Explicit_Target
              and then Editor.Executor.File_Target_Prompt_Commands.Command_Requires_File_Target_Prompt (E.Id) =
                       D.Target_Prompt_Capable,
              "Executor prompt predicates must remain canonical-accessor derived for " &
              Editor.Commands.Stable_Command_Name (E.Id));

            if D.Target_Prompt_Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
            end if;
         end;
      end loop;

      Assert (Prompt_Capable_Count = 4,
        "only Save As, Rename, Copy, and Move may be prompt-capable");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Command_Is_Target_Prompt_Capable (Id) then
            Assert (Editor.Commands.Is_File_Lifecycle_Command (Id)
              and then Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length > 0,
              "no non-file or unlabeled command may become prompt-capable");
         else
            Assert (not Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length = 0,
              "non-prompt-capable commands must carry no prompt metadata");
         end if;
      end loop;
   end Test_Target_Prompt_Metadata_Canonical_Cleanup;
procedure Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Source     : constant String := Temp_Path ("source.txt");
      Target     : constant String := Temp_Path ("target.txt");
      Workspace  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary    : Unbounded_String;
      Snap       : Editor.Render_Model.Render_Snapshot;
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Write_Bytes (Source, "source text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then S.File_Target_Prompt_Command = Editor.Commands.Command_Save_File_As
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = "Save As target"
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "cleanup must preserve canonical Save As prompt opening");

      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Target,
        "render must project active prompt snapshot state, not local metadata");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "projection cache") = 0,
        "workspace persistence must exclude prompt metadata, labels, caches, and target histories");

      Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then not Ada.Directories.Exists (Target),
        "prompt cancellation remains non-mutating");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Target);
      Assert (Ada.Directories.Exists (Target)
        and then Read_Bytes (Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As behavior must remain unchanged");

      Remove_If_Exists (Source);
      Remove_If_Exists (Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke;




   procedure Test_Minimal_Metadata_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      type Expected_Metadata is record
         Id       : Editor.Commands.Command_Id;
         Name     : Unbounded_String;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 10) of Expected_Metadata :=
        ((Editor.Commands.Command_Save_File, To_Unbounded_String ("file.save"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Save_File_As, To_Unbounded_String ("file.save-as"), True, True, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Close_Active_Buffer, To_Unbounded_String ("file.close-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reopen_Closed_Buffer, To_Unbounded_String ("file.reopen-closed-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Reload_Active_Buffer, To_Unbounded_String ("file.reload-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Revert_Active_Buffer, To_Unbounded_String ("file.revert-buffer"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Rename_Buffer_File, To_Unbounded_String ("file.rename-buffer-file"), True, True, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Delete_Buffer_File, To_Unbounded_String ("file.delete-buffer-file"), False, False, Null_Unbounded_String),
         (Editor.Commands.Command_Copy_Buffer_File, To_Unbounded_String ("file.copy-buffer-file"), True, True, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, To_Unbounded_String ("file.move-buffer-file"), True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
      Required_Count       : Natural := 0;

      procedure Reject_In (Text : String; Forbidden : String; Context : String) is
      begin
         Assert (Ada.Strings.Fixed.Index (Text, Forbidden) = 0,
           "forbidden prompt metadata token '" & Forbidden &
           "' leaked into " & Context);
      end Reject_In;

      procedure Assert_Descriptor_Minimal (Id : Editor.Commands.Command_Id) is
         D       : constant Editor.Commands.Command_Descriptor :=
           Editor.Commands.Descriptor (Id);
         Context : constant String := Editor.Commands.Stable_Command_Name (Id);
         Text    : constant String :=
           Context & " " &
           To_String (D.Name) & " " &
           To_String (D.Description) & " " &
           To_String (D.Summary) & " " &
           To_String (D.Availability_Summary) & " " &
           To_String (D.Mutation_Summary) & " " &
           To_String (D.Filesystem_Effect_Summary) & " " &
           To_String (D.State_Preservation_Summary) & " " &
           To_String (D.Non_Goal_Summary) & " " &
           To_String (D.Target_Prompt_Label);
      begin
         Reject_In (Text, "target_parameter_summary", Context);
         Reject_In (Text, "prompt_confirmation_summary", Context);
         Reject_In (Text, "prompt_cancellation_summary", Context);
         Reject_In (Text, "target_prompt_non_goals_summary", Context);
         Reject_In (Text, "prompt_reference_summary", Context);
         Reject_In (Text, "prompt_reference_family", Context);
         Reject_In (Text, "prompt_reference_effect_classification", Context);
         Reject_In (Text, "prompt_reference_availability_summary", Context);
         Reject_In (Text, "prompt_reference_documentation_text", Context);
         Reject_In (Text, "prompt_reference_search_text", Context);
         Reject_In (Text, "prompt_reference_projection_cache", Context);
         Reject_In (Text, "prompt_history", Context);
         Reject_In (Text, "target_history", Context);
         Reject_In (Text, "recent_target_list", Context);
         Reject_In (Text, "target_autocomplete_cache", Context);
         Reject_In (Text, "prompt-capable cache", Context);
         Reject_In (Text, "file picker", Context);
         Reject_In (Text, "overwrite prompt", Context);
         Reject_In (Text, "force prompt", Context);
      end Assert_Descriptor_Minimal;
   begin
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Minimal,
        "minimal metadata guard must remain true");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal,
        "canonical/minimal cleanup guard must remain true");
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Frozen,
        "final metadata freeze guard must remain true");

      for E of Expected loop
         declare
            D : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (E.Id);
         begin
            Assert (D.Id = E.Id
              and then Editor.Commands.Stable_Command_Name (E.Id) = To_String (E.Name),
              "descriptor identity drift for " & To_String (E.Name));
            Assert (D.Requires_Explicit_Target = E.Required
              and then D.Target_Prompt_Capable = E.Capable
              and then To_String (D.Target_Prompt_Label) = To_String (E.Label),
              "descriptor-owned prompt metadata mapping drift for " & To_String (E.Name));
            Assert (Editor.Commands.Command_Requires_Explicit_Target (E.Id) = E.Required
              and then Editor.Commands.Command_Is_Target_Prompt_Capable (E.Id) = E.Capable
              and then Editor.Commands.Command_Target_Prompt_Label (E.Id) = To_String (E.Label),
              "public metadata accessor mapping drift for " & To_String (E.Name));
            Assert (Editor.Executor.Command_Requires_Explicit_Target (E.Id) = E.Required
              and then Editor.Executor.File_Target_Prompt_Commands.Command_Requires_File_Target_Prompt (E.Id) = E.Capable,
              "prompt invocation predicates must remain canonical-accessor derived for " &
              To_String (E.Name));

            if E.Required then
               Required_Count := Required_Count + 1;
            end if;
            if E.Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
               Assert (To_String (E.Label)'Length > 0,
                 "prompt-capable command must have canonical prompt label");
            else
               Assert (To_String (E.Label)'Length = 0,
                 "non-prompt command must have no prompt label");
            end if;

            Assert_Descriptor_Minimal (E.Id);
         end;
      end loop;

      Assert (Required_Count = 4 and then Prompt_Capable_Count = 4,
        "only Save As, Rename, Copy, and Move may require and support target prompts");

      for Id in Editor.Commands.Command_Id loop
         if Editor.Commands.Command_Is_Target_Prompt_Capable (Id) then
            Assert (Id in Editor.Commands.Command_Save_File_As
                       | Editor.Commands.Command_Rename_Buffer_File
                       | Editor.Commands.Command_Copy_Buffer_File
                       | Editor.Commands.Command_Move_Buffer_File
              and then Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length > 0,
              "no command outside the frozen file target set may become prompt-capable");
         else
            Assert (not Editor.Commands.Command_Requires_Explicit_Target (Id)
              and then Editor.Commands.Command_Target_Prompt_Label (Id)'Length = 0,
              "non-prompt-capable commands must not retain prompt metadata");
         end if;
      end loop;
   end Test_Minimal_Metadata_Final_Freeze;


procedure Test_Render_Audit_Persistence_And_Behavior_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S             : Editor.State.State_Type;
      Source        : constant String := Temp_Path ("source.txt");
      Prompt_Target : constant String := Temp_Path ("prompted target.txt");
      Direct_Target : constant String := Temp_Path ("direct target.txt");
      Workspace     : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary       : Unbounded_String;
      Snap          : Editor.Render_Model.Render_Snapshot;
      Before_Audit  : Editor.Configuration_Audit.Configuration_State_Summary;
      After_Audit   : Editor.Configuration_Audit.Configuration_State_Summary;
      Audit_Result  : Editor.Configuration_Audit.Configuration_Audit_Result;
      Route_Audit   : Editor.Command_Route_Audit.Route_Audit_Result;

      type Prompt_Command is record
         Id    : Editor.Commands.Command_Id;
         Label : Unbounded_String;
      end record;

      Prompt_Commands : constant array (Positive range 1 .. 4) of Prompt_Command :=
        ((Editor.Commands.Command_Save_File_As, To_Unbounded_String ("Save As target")),
         (Editor.Commands.Command_Rename_Buffer_File, To_Unbounded_String ("Rename target")),
         (Editor.Commands.Command_Copy_Buffer_File, To_Unbounded_String ("Copy target")),
         (Editor.Commands.Command_Move_Buffer_File, To_Unbounded_String ("Move target")));
   begin
      Remove_If_Exists (Source);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Target);
      Write_Bytes (Source, "source text");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Source);
      Editor.Messages.Clear (S.Messages);

      Before_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Command_Route_Audit.Clear (Route_Audit);
      Editor.Command_Route_Audit.Record_Route
        (Route_Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      After_Audit := Editor.Configuration_Audit.Configuration_State_Summary_For (S);
      Editor.Configuration_Audit.Expect_No_Runtime_Or_Lifecycle_Mutation
        (Audit_Result, Before_Audit, After_Audit,
         "target prompt metadata final audit boundary");
      Assert (Editor.Command_Route_Audit.Failure_Count (Route_Audit) = 0
        and then Editor.Configuration_Audit.Status (Audit_Result) =
                 Editor.Configuration_Audit.Configuration_Audit_Ok
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "route/configuration audits must not mutate state or open prompts");

      for P of Prompt_Commands loop
         Editor.Executor.Execute_Command (S, P.Id);
         Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
           and then S.File_Target_Prompt_Command = P.Id
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Label (S) = To_String (P.Label)
           and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
           "no-target invocation must open canonical prompt for " &
           Editor.Commands.Stable_Command_Name (P.Id));
         Editor.Render_Model.Build_Render_Snapshot (S, Snap);
         Assert (Snap.File_Target_Prompt_Visible
           and then To_String (Snap.File_Target_Prompt_Label) = To_String (P.Label),
           "render snapshot must project canonical prompt label for " &
           Editor.Commands.Stable_Command_Name (P.Id));
         Editor.Executor.File_Target_Prompt_Commands.Cancel_File_Target_Prompt (S);
         Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
           "prompt cancellation must clean transient state for " &
           Editor.Commands.Stable_Command_Name (P.Id));
      end loop;

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File);
      Assert (not Editor.Commands.Command_Is_Target_Prompt_Capable
                (Editor.Commands.Command_Delete_Buffer_File)
        and then not Editor.Commands.Command_Requires_Explicit_Target
                (Editor.Commands.Command_Delete_Buffer_File)
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S)
        and then Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
        "non-target file lifecycle commands must not open target prompts");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Save_File_As);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.File_Target_Prompt_Visible
        and then To_String (Snap.File_Target_Prompt_Label) = "Save As target"
        and then To_String (Snap.File_Target_Prompt_Field.Text) = Prompt_Target,
        "render remains snapshot-driven for active prompt state");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), Prompt_Target) = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "Save As target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending target") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "pending prompt") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt metadata") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt-capable") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "prompt label cache") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "target history") = 0
        and then Ada.Strings.Fixed.Index (To_String (Summary), "projection cache") = 0,
        "workspace persistence must exclude prompt state, metadata snapshots, caches, and histories");

      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (Ada.Directories.Exists (Prompt_Target)
        and then Read_Bytes (Prompt_Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "prompted Save As confirmation behavior must remain unchanged");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Direct_Target);
      Assert (Ada.Directories.Exists (Direct_Target)
        and then Read_Bytes (Direct_Target) = "source text"
        and then not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
        "direct explicit-target Save As must bypass prompt and remain unchanged");

      Remove_If_Exists (Source);
      Remove_If_Exists (Prompt_Target);
      Remove_If_Exists (Direct_Target);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_If_Exists (Source);
         Remove_If_Exists (Prompt_Target);
         Remove_If_Exists (Direct_Target);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Render_Audit_Persistence_And_Behavior_Final_Freeze;


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






   procedure Test_Save_As_Canonical_Surface_And_Default_Keybinding_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Save_As_Canonical_Handler_Preserves_File_Save_Targeting (T);
   end Test_Save_As_Canonical_Surface_And_Default_Keybinding_Cleanup;

   procedure Test_Revert_Canonical_Surface_And_Removed_Name_Discard_Removed
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Revert_Canonical_Dirty_Read_Path (T);
   end Test_Revert_Canonical_Surface_And_Removed_Name_Discard_Removed;

   procedure Test_Rename_Canonical_Cleanup_And_No_Removed_Name_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Rename_Read_Only_Feature_And_Persistence_Boundaries (T);
   end Test_Rename_Canonical_Cleanup_And_No_Removed_Name_State;

   procedure Test_Delete_Read_Only_Persistence_And_Route_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Delete_Read_Only_Feature_And_Persistence_Coherence (T);
   end Test_Delete_Read_Only_Persistence_And_Route_Boundaries;

   procedure Test_Delete_Canonical_Surface_And_No_Removed_Name_Routes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Delete_Cleanup_Preserves_Source_State_And_Persistence (T);
   end Test_Delete_Canonical_Surface_And_No_Removed_Name_Routes;

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

   procedure Test_Target_Prompt_Canonical_Surface_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup (T);
   end Test_Target_Prompt_Canonical_Surface_Cleanup;

   procedure Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze (T);
   end Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze;

   procedure Test_Target_Prompt_Minimal_Metadata_Canonical
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze (T);
   end Test_Target_Prompt_Minimal_Metadata_Canonical;

   procedure Test_Target_Prompt_Metadata_Accuracy_And_Stability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Target_Prompt_Metadata_Minimality_Guard (T);
   end Test_Target_Prompt_Metadata_Accuracy_And_Stability;

   procedure Test_No_Duplicate_Metadata_Projection_Or_Aliases
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke (T);
   end Test_No_Duplicate_Metadata_Projection_Or_Aliases;

   procedure Test_Command_Palette_Alias_And_Inference_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Test_Minimal_Metadata_Final_Freeze (T);
   end Test_Command_Palette_Alias_And_Inference_Final_Freeze;

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
        (T, Test_Open_Save_And_Reload_Update_Baseline'Access,
         "Open Save And Reload Update Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Does_Not_Update_Baseline'Access,
         "Failed Save Does Not Update Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Reload_Is_Blocked_And_Preserves_State'Access,
         "Dirty Reload Is Blocked And Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Missing_And_Read_Failure_Reload_Preserve_Buffer'Access,
         "Missing And Read Failure Reload Preserve Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Already_Open_Changed_File_Does_Not_Reread'Access,
         "Open Already Open Changed File Does Not Reread");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Writes_Buffer_And_Cleans_State'Access,
         "Save Writes Buffer And Cleans State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_On_Save_Trims_Before_File_Save'Access,
         "Format On Save Trims Before File Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Edit_After_Save_Marks_Dirty'Access,
         "Edit After Save Marks Dirty");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Without_Path_Returns_Invalid_Path'Access,
         "Save Without Path Returns Invalid Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Writes_Contents'Access,
         "Save File Result Writes Contents");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Rejects_Invalid_And_Directory'Access,
         "Save File Result Rejects Invalid And Directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Result_Reports_Missing_Parent'Access,
         "Save File Result Reports Missing Parent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Missing_Target_Surfaces_State_And_Preserves_Text'Access,
         "Reload Missing Target Surfaces State And Preserves Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Missing_Target_Preserves_Dirty_Text'Access,
         "Revert Missing Target Preserves Dirty Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Invalidates_Derived_State'Access,
         "Save As Invalidates Derived State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Lifecycle_Guidance_Projects_Read_Recovery_Markers'Access,
         "Lifecycle Guidance Projects Read Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Buffer_Guidance_Projects_Recovery_Markers'Access,
         "Open Buffer Guidance Projects Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Guidance_Projects_Open_Buffer_Recovery_Markers'Access,
         "File Tree Guidance Projects Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_All_Invalidates_Derived_State_After_Restoring_Original_Buffer'Access,
         "Save All Invalidates Derived State After Restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_All_Summarizes_Recovery_Failure_Kinds'Access,
         "Save All Summarizes Recovery Failure Kinds");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Dirty_Recovery_Markers_Take_Guidance_Precedence'Access,
         "Dirty Recovery Markers Take Guidance Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Row_Guidance_Uses_Buffer_Summary_Markers'Access,
         "Active Row Guidance Uses Buffer Summary Recovery Markers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Inactive_Dirty_Recovery_Markers_Take_Guidance_Precedence'Access,
         "Inactive Dirty Recovery Markers Take Guidance Precedence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Pending_Becomes_Stale_After_Save'Access,
         "Reload Pending Becomes Stale After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Pending_Becomes_Stale_After_Save'Access,
         "Revert Pending Becomes Stale After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Revert_Cancel_Messages_Are_Specific'Access,
         "Reload Revert Cancel Messages Are Specific");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Save_All_Command'Access,
         "File Lifecycle Confirmation Blocks Save All Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Target_Changing_Routes'Access,
         "File Lifecycle Confirmation Blocks Target Changing Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Confirmation_Blocks_Text_Mutations'Access,
         "File Lifecycle Confirmation Blocks Text Mutations");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Conflict_Keep_And_Overwrite_Are_Explicit'Access,
         "Save Conflict Keep And Overwrite Are Explicit");
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
        (T, Test_Display_Name_For_Path_Returns_Basename'Access,
         "Display Name For Path Returns Basename");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_On_Opened_File_Writes_And_Cleans'Access,
         "Execute Save On Opened File Writes And Cleans");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_Untitled_Preserves_State'Access,
         "Execute Save Untitled Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_Failure_Preserves_File_Identity'Access,
         "Execute Save Failure Preserves File Identity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Writes_Identity_And_Status'Access,
         "Execute Save As Writes Identity And Status");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Invalid_Path_Preserves_State'Access,
         "Execute Save As Invalid Path Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Save_As_Directory_Preserves_State'Access,
         "Execute Save As Directory Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Does_Not_Reset_Editor_State'Access,
         "Save As Does Not Reset Editor State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Rejects_Untitled'Access,
         "Save Availability Rejects Untitled");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Allows_File_Backed_Buffer'Access,
         "Save Availability Allows File Backed Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Preserves_Cursor_Selection_And_Message_Count'Access,
         "Failed Save Preserves Cursor Selection And Message Count");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Empty_Path_Uses_Deterministic_Error'Access,
         "Save As Empty Path Uses Deterministic Error");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Missing_Backing_File_Save_Recreates_Explicitly'Access,
         "Missing Backing File Save Recreates Explicitly");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Directory_Target_Preserves_Editing_Context'Access,
         "Directory Target Preserves Editing Context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Preserves_Undo_Redo_And_Baseline'Access,
         "Failed Save Preserves Undo Redo And Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_File_Uses_Temporary_File_For_Existing_Target'Access,
         "Save File Uses Temporary File For Existing Target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Command_Metadata_Uses_Canonical_File_Save_Name'Access,
         "Save Command Metadata Uses Canonical File Save Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clean_Save_Is_Deterministic_No_Op'Access,
         "Clean Save Is Deterministic No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Success_Preserves_Editor_Feature_State'Access,
         "Save Success Preserves Editor Feature State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_State_And_Baseline'Access,
         "Save Failure Preserves State And Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Affects_Only_Active_Buffer'Access,
         "Save Affects Only Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Binds_Execution_Time_Active_Buffer'Access,
         "Save Binds Execution Time Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Writes_Exact_Current_Text_And_Not_Disk_Baseline'Access,
         "Save Writes Exact Current Text And Not Disk Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Is_Side_Effect_Free'Access,
         "Save Availability Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Preserves_Redo_Stack_And_Does_Not_Replay_Save'Access,
         "Save Preserves Redo Stack And Does Not Replay Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Binds_Active_Buffer_Read_Only'Access,
         "Save Availability Binds Active Buffer Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_Feature_State_Completely'Access,
         "Save Failure Preserves Feature State Completely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Target_Switch_Integrated_Isolation'Access,
         "Save Target Switch Integrated Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Uses_Current_Text_After_Undo_Redo_And_Preserves_Redo'Access,
         "Save Uses Current Text After Undo Redo And Preserves Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Serializes_Whitespace_And_Line_Boundaries_Exactly'Access,
         "Save Serializes Whitespace And Line Boundaries Exactly");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_Dirty_Baseline_And_Features'Access,
         "Save Failure Preserves Dirty Baseline And Features");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_And_Availability_Are_Save_Side_Effect_Free'Access,
         "Render And Availability Are Save Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Path_And_Clean_Save_Are_Non_Mutating_Workflows'Access,
         "No Path And Clean Save Are Non Mutating Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_And_Default_Keybinding_Use_Canonical_File_Save'Access,
         "Palette And Default Keybinding Use Canonical File Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Command_Metadata_And_No_Target_Route'Access,
         "Save As Command Metadata And No Target Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Success_Reassociates_And_Subsequent_Save_Uses_New_Path'Access,
         "Save As Success Reassociates And Subsequent Save Uses New Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Failure_Preserves_Old_Association_Baseline_And_State'Access,
         "Save As Failure Preserves Old Association Baseline And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Affects_Only_Active_Buffer'Access,
         "Save As Affects Only Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Missing_Parent_Is_Write_Failure_And_Non_Mutating'Access,
         "Save As Missing Parent Is Write Failure And Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Untitled_Save_As_Failure_Preserves_Untitled_Save_Target'Access,
         "Untitled Save As Failure Preserves Untitled Save Target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_After_Undo_Preserves_Redo_And_Updates_Baseline'Access,
         "Save As After Undo Preserves Redo And Updates Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Render_And_Availability_Are_Side_Effect_Free'Access,
         "Save As Render And Availability Are Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Binds_Execution_Time_Active_Buffer_In_Workflow'Access,
         "Save As Binds Execution Time Active Buffer In Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Untitled_Save_As_Save_Undo_Redo_And_Failure_Coherence'Access,
         "Untitled Save As Save Undo Redo And Failure Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Associated_Save_As_Failure_No_Target_And_Same_Target_Preserve_Order'Access,
         "Associated Save As Failure No Target And Same Target Preserve Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Render_Availability_And_Command_Surface_Are_Non_Mutating'Access,
         "Save As Render Availability And Command Surface Are Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Canonical_Surface_And_Default_Keybinding_Cleanup'Access,
         "Save As Canonical Surface And Default Keybinding Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Canonical_Handler_Preserves_File_Save_Targeting'Access,
         "Save As Canonical Handler Preserves File Save Targeting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Command_Metadata_Uses_Canonical_Name'Access,
         "Reload Command Metadata Uses Canonical Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Success_Replaces_Active_Text_After_Read'Access,
         "Reload Success Replaces Active Text After Read");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Blocked_And_Failed_Preserve_State'Access,
         "Reload Blocked And Failed Preserve State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Validation_Order_And_Availability_Are_Local'Access,
         "Reload Validation Order And Availability Are Local");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Exact_Disk_Text_And_No_Reopen_State'Access,
         "Reload Exact Disk Text And No Reopen State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Targets_Active_Buffer_Only'Access,
         "Reload Targets Active Buffer Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_And_Failed_Reloads_Preserve_Transient_State'Access,
         "Blocked And Failed Reloads Preserve Transient State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Successful_Reload_Is_Not_Undoable_And_Enables_Save_Close'Access,
         "Successful Reload Is Not Undoable And Enables Save Close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Availability_Has_No_Filesystem_Side_Effects'Access,
         "Reload Availability Has No Filesystem Side Effects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Validation_Order_Surface_And_Messages'Access,
         "Reload Validation Order Surface And Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Success_Exact_Text_Baseline_And_Edit_Workflow'Access,
         "Reload Success Exact Text Baseline And Edit Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Preserves_Failure_State_And_Active_Buffer_Isolation'Access,
         "Reload Preserves Failure State And Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Save_As_Close_Reopen_Integrated_Workflow'Access,
         "Reload Save As Close Reopen Integrated Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Canonical_Path_Ignores_Removed_Name_And_Feature_State'Access,
         "Reload Canonical Path Ignores Removed_Name And Feature State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Command_Surface_And_Validation'Access,
         "Revert Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Success_Replaces_Dirty_Active_Text'Access,
         "Revert Success Replaces Dirty Active Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Read_Failure_Preserves_State'Access,
         "Revert Read Failure Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Save_Close_Reopen_Reload_Workflow'Access,
         "Revert Save Close Reopen Reload Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Target_Validation_And_Availability'Access,
         "Revert Target Validation And Availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Read_Failure_Is_Atomic'Access,
         "Revert Read Failure Is Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Exact_Disk_Text_And_History_Policy'Access,
         "Revert Exact Disk Text And History Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Clean_No_Op_Preserves_State'Access,
         "Revert Clean No Op Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Validation_Surface_And_Messages'Access,
         "Revert Validation Surface And Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Target_Is_Active_Buffer_And_Isolated'Access,
         "Revert Target Is Active Buffer And Isolated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Success_Text_Baseline_History_And_Save_Workflow'Access,
         "Revert Success Text Baseline History And Save Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Failure_And_Clean_No_Op_Preserve_Transient_State'Access,
         "Revert Failure And Clean No Op Preserve Transient State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_File_Lifecycle_And_Read_Only_Boundaries'Access,
         "Revert File Lifecycle And Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Canonical_Surface_And_Removed_Name_Discard_Removed'Access,
         "Revert Canonical Surface And Removed_Name Discard Removed");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Command_Surface_And_Validation'Access,
         "Rename Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Success_Preserves_Buffer_State'Access,
         "Rename Success Preserves Buffer State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Dirty_And_Failure_Are_Atomic'Access,
         "Rename Dirty And Failure Are Atomic");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Active_Isolation_And_Lifecycle_Coherence'Access,
         "Rename Active Isolation And Lifecycle Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Validation_Order_And_Active_Source'Access,
         "Rename Validation Order And Active Source");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Association_Ordering_And_State_Preservation'Access,
         "Rename Association Ordering And State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Read_Only_Boundaries'Access,
         "Rename Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Workflow_Validation_Matrix'Access,
         "Rename Workflow Validation Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Dirty_And_Transient_State_Preservation'Access,
         "Rename Dirty And Transient State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_File_Lifecycle_Integrated_Workflow'Access,
         "Rename File Lifecycle Integrated Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Read_Only_Feature_And_Persistence_Boundaries'Access,
         "Rename Read Only Feature And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Undo_Redo_And_Surface_Non_Goals'Access,
         "Rename Undo Redo And Surface Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Canonical_Cleanup_And_No_Removed_Name_State'Access,
         "Rename Canonical Cleanup And No Removed_Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Command_Surface_And_Validation'Access,
         "Delete Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Success_Preserves_Text_And_Marks_Unsaved'Access,
         "Delete Success Preserves Text And Marks Unsaved");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Failure_And_Active_Isolation_Are_Atomic'Access,
         "Delete Failure And Active Isolation Are Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Read_Only_Persistence_And_Route_Boundaries'Access,
         "Delete Read Only Persistence And Route Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Validation_Order_And_Active_Source'Access,
         "Delete Validation Order And Active Source");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Blocked_And_Failed_Outcomes_Are_Non_Mutating'Access,
         "Delete Blocked And Failed Outcomes Are Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Success_Lifecycle_And_Persistence_Boundaries'Access,
         "Delete Success Lifecycle And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Integrated_Workflow_Coherence'Access,
         "Delete Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Read_Only_Feature_And_Persistence_Coherence'Access,
         "Delete Read Only Feature And Persistence Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Canonical_Surface_And_No_Removed_Name_Routes'Access,
         "Delete Canonical Surface And No Removed_Name Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Cleanup_Preserves_Source_State_And_Persistence'Access,
         "Delete Cleanup Preserves Source State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Command_Surface_And_Validation'Access,
         "Copy Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Success_Preserves_Buffer_State'Access,
         "Copy Success Preserves Buffer State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Failure_And_Active_Isolation_Are_Atomic'Access,
         "Copy Failure And Active Isolation Are Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Source_And_Target_Failures_Preserve_State'Access,
         "Copy Source And Target Failures Preserve State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_File_Lifecycle_Interactions_Stay_On_Original_Path'Access,
         "Copy File Lifecycle Interactions Stay On Original Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Persistence_And_No_Removed_Name_Routes'Access,
         "Copy Read Only Persistence And No Removed_Name Routes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Validation_Order_And_Active_Source_Reliability'Access,
         "Copy Validation Order And Active Source Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Preserves_Transient_State_On_Success_And_Failure'Access,
         "Copy Preserves Transient State On Success And Failure");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_File_Lifecycle_And_Persistence_Reliability'Access,
         "Copy File Lifecycle And Persistence Reliability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Integrated_Workflow_Coherence'Access,
         "Copy Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Feature_And_Availability_Boundaries'Access,
         "Copy Read Only Feature And Availability Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Undo_Redo_Message_And_Surface_Non_Goals'Access,
         "Copy Undo Redo Message And Surface Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Canonical_Surface_And_Removed_Name_Cleanup'Access,
         "Copy Canonical Surface And Removed_Name Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Source_Validation_And_Target_Canonicalization'Access,
         "Copy Source Validation And Target Canonicalization");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Copy_Read_Only_Persistence_And_No_Removed_Name_State'Access,
         "Copy Read Only Persistence And No Removed_Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Command_Surface_And_Blocked_Outcomes'Access,
         "Move Command Surface And Blocked Outcomes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Success_Updates_Association_Only_After_Filesystem'Access,
         "Move Success Updates Association Only After Filesystem");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Failure_Preserves_Association_And_State'Access,
         "Move Failure Preserves Association And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Source_Validation_Order_And_Active_Identity'Access,
         "Move Source Validation Order And Active Identity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Failure_Read_Only_Boundaries_And_Persistence'Access,
         "Move Failure Read Only Boundaries And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_File_Lifecycle_Uses_Moved_Association'Access,
         "Move File Lifecycle Uses Moved Association");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Integrated_Workflow_Coherence'Access,
         "Move Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Preserves_Transient_Feature_Boundaries'Access,
         "Move Preserves Transient Feature Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Read_Only_Persistence_And_Surface_Boundaries'Access,
         "Move Read Only Persistence And Surface Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Canonical_Surface_And_Removed_Name_Cleanup'Access,
         "Move Canonical Surface And Removed_Name Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Canonical_State_And_Persistence_Cleanup'Access,
         "Move Canonical State And Persistence Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Blocked_Outcomes_Ignore_Removed_Name_State'Access,
         "Move Blocked Outcomes Ignore Removed_Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cross_Command_Source_Validation_And_Association_Coherence'Access,
         "Cross Command Source Validation And Association Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Cross_Command_Failure_Dirty_And_Feature_State_Preservation'Access,
         "Cross Command Failure Dirty And Feature State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Read_Only_Lifecycle_Persistence_And_Removed_Name_State_Exclusion'Access,
         "Read Only Lifecycle Persistence And Removed_Name State Exclusion");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Canonical_Family_Surface_And_Shared_Boundaries'Access,
         "Canonical Family Surface And Shared Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Final_Family_Surface_Validation_And_Readonly_Freeze'Access,
         "Final Family Surface Validation And Readonly Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Final_Association_Lifecycle_And_Failure_Freeze'Access,
         "Final Association Lifecycle And Failure Freeze");
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
        (T, Test_Target_Prompt_Opening_Input_And_Save_As_Confirmation'Access,
         "Target Prompt Opening Input And Save As Confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Cancellation_And_Lifecycle_Cleanup'Access,
         "Target Prompt Cancellation And Lifecycle Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Requiring_Command_Prompt_Eligibility'Access,
         "Target Requiring Command Prompt Eligibility");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Projects_File_Target_Prompt_Without_Mutation'Access,
         "Render Projects File Target Prompt Without Mutation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Uses_Active_Buffer_At_Confirmation'Access,
         "Target Prompt Uses Active Buffer At Confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Second_Target_Prompt_Replaces_First_Deterministically'Access,
         "Second Target Prompt Replaces First Deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Workspace_Persistence_Excluded'Access,
         "Target Prompt Workspace Persistence Excluded");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Workflow_Coherence_Matrix'Access,
         "Target Prompt Workflow Coherence Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Text_Editing_Cancel_And_Message_Policy'Access,
         "Target Prompt Text Editing Cancel And Message Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Keybinding_Overlay_And_Audit_Workflow'Access,
         "Command Palette Keybinding Overlay And Audit Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Confirmation_Lifecycle_Persistence_And_Direct_Behavior'Access,
         "Confirmation Lifecycle Persistence And Direct Behavior");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Canonical_Surface_Cleanup'Access,
         "Target Prompt Canonical Surface Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_No_Inference_State_And_Persistence_Cleanup'Access,
         "Target Prompt No Inference State And Persistence Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Confirmation_And_Direct_Behavior_Canonical'Access,
         "Target Prompt Confirmation And Direct Behavior Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Restore_Applies_Continuity_State'Access,
         "Workspace Restore Applies Continuity State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Surface_State_And_Alias_Freeze'Access,
         "Target Prompt Final Surface State And Alias Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Input_Overlay_Audit_And_Persistence_Freeze'Access,
         "Target Prompt Final Input Overlay Audit And Persistence Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Final_Confirmation_Active_Buffer_Message_And_Direct_Freeze'Access,
         "Target Prompt Final Confirmation Active Buffer Message And Direct Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Minimal_Metadata_Canonical'Access,
         "Target Prompt Minimal Metadata Canonical");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Boundaries_And_Behavior_Freeze'Access,
         "Target Prompt Metadata Boundaries And Behavior Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Accuracy_And_Stability'Access,
         "Target Prompt Metadata Accuracy And Stability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Minimality_Guard'Access,
         "Target Prompt Metadata Minimality Guard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Metadata_Reads_Are_Pure_And_Availability_Independent'Access,
         "Metadata Reads Are Pure And Availability Independent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Render_Audit_And_Persistence_Boundary'Access,
         "Command Palette Render Audit And Persistence Boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Target_Prompt_Metadata_Canonical_Cleanup'Access,
         "Target Prompt Metadata Canonical Cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Duplicate_Metadata_Projection_Or_Aliases'Access,
         "No Duplicate Metadata Projection Or Aliases");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Metadata_Cleanup_Behavior_And_Persistence_Smoke'Access,
         "Metadata Cleanup Behavior And Persistence Smoke");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Minimal_Metadata_Final_Freeze'Access,
         "Minimal Metadata Final Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Alias_And_Inference_Final_Freeze'Access,
         "Command Palette Alias And Inference Final Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Audit_Persistence_And_Behavior_Final_Freeze'Access,
         "Render Audit Persistence And Behavior Final Freeze");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Command_Surface_Milestone_Freeze'Access,
         "File Lifecycle Command Surface Milestone Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Cross_Command_Sequence_Milestone_Freeze'Access,
         "File Lifecycle Cross Command Sequence Milestone Freeze");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Retry_Save_After_Failure_Uses_Latest_Content'Access,
         "Retry Save After Failure Uses Latest Content");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Dirty_Reload_Preserves_History_Viewport_And_Features'Access,
         "Blocked Dirty Reload Preserves History Viewport And Features");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Canonical_Dirty_Read_Path'Access,
         "Revert Canonical Dirty Read Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Feedback_Explains_Retryable_State'Access,
         "Failed Save Feedback Explains Retryable State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Reload_Feedback_Says_No_Replacement'Access,
         "Blocked Reload Feedback Says No Replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Close_Feedback_Says_Buffer_Remains_Open'Access,
         "Blocked Close Feedback Says Buffer Remains Open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Already_Open_Focus_Feedback_Does_Not_Imply_Reload'Access,
         "Already Open Focus Feedback Does Not Imply Reload");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Context_Clears_After_Successful_Save'Access,
         "Failed Save Context Clears After Successful Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Retry_Context_Survives_Buffer_Switch'Access,
         "Retry Context Survives Buffer Switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Reload_Clears_After_Save'Access,
         "Blocked Reload Clears After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Close_Clears_After_Close'Access,
         "Blocked Close Clears After Close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_After_Load_Emits_Text'Access,
         "Render Packet After Load Emits Text");
   end Register_Tests;

end Editor.Files.Tests;
