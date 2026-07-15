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

package body Editor.Files.Reload_Revert_Operation_Tests is

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
      S.Reopen_Candidate_Path := To_Unbounded_String (Editor.Test_Temp.Base & "/unrelated-reopen.txt");
      S.Reopen_Candidate_Label := To_Unbounded_String ("unrelated");
      Write_Bytes (Path, Exact);
      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);

      Assert (Buffer_Text (S) = Exact,
        "reload must preserve empty lines, spaces, tabs, punctuation, and trailing newlines exactly");
      Assert (S.Has_Reopen_Candidate
        and then To_String (S.Reopen_Candidate_Path) = Editor.Test_Temp.Base & "/unrelated-reopen.txt",
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
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
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





   overriding function Name (T : Reload_Revert_Operation_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Reload_Revert_Operation.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Reload_Revert_Operation_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Command_Metadata_Uses_Canonical_Name'Access, "Reload Command Metadata Uses Canonical Name");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Success_Replaces_Active_Text_After_Read'Access, "Reload Success Replaces Active Text After Read");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Blocked_And_Failed_Preserve_State'Access, "Reload Blocked And Failed Preserve State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Validation_Order_And_Availability_Are_Local'Access, "Reload Validation Order And Availability Are Local");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Exact_Disk_Text_And_No_Reopen_State'Access, "Reload Exact Disk Text And No Reopen State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Targets_Active_Buffer_Only'Access, "Reload Targets Active Buffer Only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_And_Failed_Reloads_Preserve_Transient_State'Access, "Blocked And Failed Reloads Preserve Transient State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Successful_Reload_Is_Not_Undoable_And_Enables_Save_Close'Access, "Successful Reload Is Not Undoable And Enables Save Close");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Availability_Has_No_Filesystem_Side_Effects'Access, "Reload Availability Has No Filesystem Side Effects");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Validation_Order_Surface_And_Messages'Access, "Reload Validation Order Surface And Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Success_Exact_Text_Baseline_And_Edit_Workflow'Access, "Reload Success Exact Text Baseline And Edit Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Preserves_Failure_State_And_Active_Buffer_Isolation'Access, "Reload Preserves Failure State And Active Buffer Isolation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Save_As_Close_Reopen_Integrated_Workflow'Access, "Reload Save As Close Reopen Integrated Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reload_Canonical_Path_Ignores_Removed_Name_And_Feature_State'Access, "Reload Canonical Path Ignores Removed Name And Feature State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Command_Surface_And_Validation'Access, "Revert Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Success_Replaces_Dirty_Active_Text'Access, "Revert Success Replaces Dirty Active Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Read_Failure_Preserves_State'Access, "Revert Read Failure Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Save_Close_Reopen_Reload_Workflow'Access, "Revert Save Close Reopen Reload Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Target_Validation_And_Availability'Access, "Revert Target Validation And Availability");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Read_Failure_Is_Atomic'Access, "Revert Read Failure Is Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Exact_Disk_Text_And_History_Policy'Access, "Revert Exact Disk Text And History Policy");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Clean_No_Op_Preserves_State'Access, "Revert Clean No Op Preserves State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Validation_Surface_And_Messages'Access, "Revert Validation Surface And Messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Target_Is_Active_Buffer_And_Isolated'Access, "Revert Target Is Active Buffer And Isolated");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Success_Text_Baseline_History_And_Save_Workflow'Access, "Revert Success Text Baseline History And Save Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Failure_And_Clean_No_Op_Preserve_Transient_State'Access, "Revert Failure And Clean No Op Preserve Transient State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_File_Lifecycle_And_Read_Only_Boundaries'Access, "Revert File Lifecycle And Read Only Boundaries");
   end Register_Tests;

end Editor.Files.Reload_Revert_Operation_Tests;
