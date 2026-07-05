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

package body Editor.Files.Save_Operation_Tests is

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
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

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





   overriding function Name (T : Save_Operation_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Save_Operation.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Save_Operation_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Command_Metadata_And_No_Target_Route'Access, "Save As Command Metadata And No Target Route");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Success_Reassociates_And_Subsequent_Save_Uses_New_Path'Access, "Save As Success Reassociates And Subsequent Save Uses New Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Failure_Preserves_Old_Association_Baseline_And_State'Access, "Save As Failure Preserves Old Association Baseline And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Affects_Only_Active_Buffer'Access, "Save As Affects Only Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Missing_Parent_Is_Write_Failure_And_Non_Mutating'Access, "Save As Missing Parent Is Write Failure And Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Untitled_Save_As_Failure_Preserves_Untitled_Save_Target'Access, "Untitled Save As Failure Preserves Untitled Save Target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_After_Undo_Preserves_Redo_And_Updates_Baseline'Access, "Save As After Undo Preserves Redo And Updates Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Render_And_Availability_Are_Side_Effect_Free'Access, "Save As Render And Availability Are Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Binds_Execution_Time_Active_Buffer_In_Workflow'Access, "Save As Binds Execution Time Active Buffer In Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Untitled_Save_As_Save_Undo_Redo_And_Failure_Coherence'Access, "Untitled Save As Save Undo Redo And Failure Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Associated_Save_As_Failure_No_Target_And_Same_Target_Preserve_Order'Access, "Associated Save As Failure No Target And Same Target Preserve Order");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Render_Availability_And_Command_Surface_Are_Non_Mutating'Access, "Save As Render Availability And Command Surface Are Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_As_Canonical_Handler_Preserves_File_Save_Targeting'Access, "Save As Canonical Handler Preserves File Save Targeting");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Command_Metadata_Uses_Canonical_File_Save_Name'Access, "Save Command Metadata Uses Canonical File Save Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clean_Save_Is_Deterministic_No_Op'Access, "Clean Save Is Deterministic No Op");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Success_Preserves_Editor_Feature_State'Access, "Save Success Preserves Editor Feature State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Affects_Only_Active_Buffer'Access, "Save Affects Only Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_State_And_Baseline'Access, "Save Failure Preserves State And Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Binds_Execution_Time_Active_Buffer'Access, "Save Binds Execution Time Active Buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Writes_Exact_Current_Text_And_Not_Disk_Baseline'Access, "Save Writes Exact Current Text And Not Disk Baseline");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Is_Side_Effect_Free'Access, "Save Availability Is Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Preserves_Redo_Stack_And_Does_Not_Replay_Save'Access, "Save Preserves Redo Stack And Does Not Replay Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Availability_Binds_Active_Buffer_Read_Only'Access, "Save Availability Binds Active Buffer Read Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_Feature_State_Completely'Access, "Save Failure Preserves Feature State Completely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Target_Switch_Integrated_Isolation'Access, "Save Target Switch Integrated Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Uses_Current_Text_After_Undo_Redo_And_Preserves_Redo'Access, "Save Uses Current Text After Undo Redo And Preserves Redo");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Serializes_Whitespace_And_Line_Boundaries_Exactly'Access, "Save Serializes Whitespace And Line Boundaries Exactly");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_Failure_Preserves_Dirty_Baseline_And_Features'Access, "Save Failure Preserves Dirty Baseline And Features");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_And_Availability_Are_Save_Side_Effect_Free'Access, "Render And Availability Are Save Side Effect Free");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_No_Path_And_Clean_Save_Are_Non_Mutating_Workflows'Access, "No Path And Clean Save Are Non Mutating Workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Palette_And_Default_Keybinding_Use_Canonical_File_Save'Access, "Palette And Default Keybinding Use Canonical File Save");
   end Register_Tests;

end Editor.Files.Save_Operation_Tests;
