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
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.Navigation_Commands;
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

package body Editor.Files.Rename_Delete_Operation_Tests is

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
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Navigation_Commands.Execute_Open_Goto_Line (S);
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
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
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
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
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

   overriding function Name (T : Rename_Delete_Operation_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Rename_Delete_Operation.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Rename_Delete_Operation_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Command_Surface_And_Validation'Access, "Rename Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Success_Preserves_Buffer_State'Access, "Rename Success Preserves Buffer State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Dirty_And_Failure_Are_Atomic'Access, "Rename Dirty And Failure Are Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Active_Isolation_And_Lifecycle_Coherence'Access, "Rename Active Isolation And Lifecycle Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Validation_Order_And_Active_Source'Access, "Rename Validation Order And Active Source");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Association_Ordering_And_State_Preservation'Access, "Rename Association Ordering And State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Read_Only_Boundaries'Access, "Rename Read Only Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Workflow_Validation_Matrix'Access, "Rename Workflow Validation Matrix");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Dirty_And_Transient_State_Preservation'Access, "Rename Dirty And Transient State Preservation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_File_Lifecycle_Integrated_Workflow'Access, "Rename File Lifecycle Integrated Workflow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Read_Only_Feature_And_Persistence_Boundaries'Access, "Rename Read Only Feature And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Undo_Redo_And_Surface_Non_Goals'Access, "Rename Undo Redo And Surface Non Goals");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Command_Surface_And_Validation'Access, "Delete Command Surface And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Success_Preserves_Text_And_Marks_Unsaved'Access, "Delete Success Preserves Text And Marks Unsaved");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Failure_And_Active_Isolation_Are_Atomic'Access, "Delete Failure And Active Isolation Are Atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Validation_Order_And_Active_Source'Access, "Delete Validation Order And Active Source");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Blocked_And_Failed_Outcomes_Are_Non_Mutating'Access, "Delete Blocked And Failed Outcomes Are Non Mutating");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Success_Lifecycle_And_Persistence_Boundaries'Access, "Delete Success Lifecycle And Persistence Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Integrated_Workflow_Coherence'Access, "Delete Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Read_Only_Feature_And_Persistence_Coherence'Access, "Delete Read Only Feature And Persistence Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Cleanup_Preserves_Source_State_And_Persistence'Access, "Delete Cleanup Preserves Source State And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Rename_Canonical_Cleanup_And_No_Removed_Name_State'Access, "Rename Canonical Cleanup And No Removed Name State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Read_Only_Persistence_And_Route_Boundaries'Access, "Delete Read Only Persistence And Route Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Delete_Canonical_Surface_And_No_Removed_Name_Routes'Access, "Delete Canonical Surface And No Removed Name Routes");
   end Register_Tests;

end Editor.Files.Rename_Delete_Operation_Tests;
