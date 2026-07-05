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

package body Editor.Files.Operations_Tests is

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


   overriding function Name (T : Operations_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Files.Operations.Tests");
   end Name;

   overriding procedure Register_Tests (T : in out Operations_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Command_Surface_And_Blocked_Outcomes'Access, "Move Command Surface And Blocked Outcomes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Success_Updates_Association_Only_After_Filesystem'Access, "Move Success Updates Association Only After Filesystem");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Failure_Preserves_Association_And_State'Access, "Move Failure Preserves Association And State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Source_Validation_Order_And_Active_Identity'Access, "Move Source Validation Order And Active Identity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Failure_Read_Only_Boundaries_And_Persistence'Access, "Move Failure Read Only Boundaries And Persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_File_Lifecycle_Uses_Moved_Association'Access, "Move File Lifecycle Uses Moved Association");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Integrated_Workflow_Coherence'Access, "Move Integrated Workflow Coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Preserves_Transient_Feature_Boundaries'Access, "Move Preserves Transient Feature Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Move_Read_Only_Persistence_And_Surface_Boundaries'Access, "Move Read Only Persistence And Surface Boundaries");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Retry_Save_After_Failure_Uses_Latest_Content'Access, "Retry Save After Failure Uses Latest Content");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Dirty_Reload_Preserves_History_Viewport_And_Features'Access, "Blocked Dirty Reload Preserves History Viewport And Features");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Revert_Canonical_Dirty_Read_Path'Access, "Revert Canonical Dirty Read Path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Render_Packet_After_Load_Emits_Text'Access, "Render Packet After Load Emits Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Feedback_Explains_Retryable_State'Access, "Failed Save Feedback Explains Retryable State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Reload_Feedback_Says_No_Replacement'Access, "Blocked Reload Feedback Says No Replacement");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Close_Feedback_Says_Buffer_Remains_Open'Access, "Blocked Close Feedback Says Buffer Remains Open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Already_Open_Focus_Feedback_Does_Not_Imply_Reload'Access, "Already Open Focus Feedback Does Not Imply Reload");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Save_Context_Clears_After_Successful_Save'Access, "Failed Save Context Clears After Successful Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Retry_Context_Survives_Buffer_Switch'Access, "Retry Context Survives Buffer Switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Reload_Clears_After_Save'Access, "Blocked Reload Clears After Save");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Blocked_Close_Clears_After_Close'Access, "Blocked Close Clears After Close");
   end Register_Tests;

end Editor.Files.Operations_Tests;
