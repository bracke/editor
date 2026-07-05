with Editor.Executor.Command_Palette_Projection;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.File_Tree_Navigation_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Workspace_Commands;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Files;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.History;
with Editor.Messages;
with Editor.Pending_Transitions;
with Editor.Project;
with Editor.Recent_Buffers;
with Editor.State;
with Editor.Test_Helper;
with Editor.View;
with Editor.Workspace_Persistence;

package body Editor.Executor.Project_Workspace_Session_Tests is

   use type Editor.Buffers.Buffer_Id;
   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Files.File_Open_Status;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

   overriding function Name
     (T : Project_Workspace_Session_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Project_Workspace_Session_Tests");
   end Name;


   procedure Test_Workspace_Reopen_Missing_Active_Falls_Back
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("missing_active_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "missing.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "missing active restore should be a partial restore");
      Assert (Summary.Files_Restored = 1, "valid sibling file should restore");
      Assert (Summary.Files_Skipped = 0, "missing active is not double-counted when files were requested");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "missing active file should fall back to first restored file");
      Assert (not S.File_Info.Dirty,
              "restored file-backed buffer should start clean");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Reopen_Missing_Active_Falls_Back;

   procedure Test_Workspace_Active_Outside_Open_Set_Does_Not_Open
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("active_outside_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Nested   : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "a_dir"), "nested.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := True;
      Id       : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "a_dir/nested.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (Nested, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "active path outside restored set should be partial, not an implicit open");
      Assert (Summary.Files_Restored = 1,
              "valid open-file entry should still restore");
      Assert (Summary.Files_Skipped = 0,
              "active outside open set must not be counted as an open-file skip");
      Assert (not Found,
              "active path outside open-files must not open an extra buffer");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "active outside open set should fall back to first restored file");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Active_Outside_Open_Set_Does_Not_Open;


   procedure Test_Workspace_Reopen_Directory_Creates_No_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("directory_restore_root");
      Dir_Path : constant String := Ada.Directories.Compose (Root, "a_dir");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := True;
      Id       : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Id);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a_dir"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (Dir_Path, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
         "directory restore should be partial, not successful");
      Assert (Summary.Files_Restored = 0, "directory path must not restore a file buffer");
      Assert (Summary.Files_Skipped = 1, "directory path should be skipped once");
      Assert (not Found, "directory path must not create a partial file buffer");
      Assert (not S.File_Info.Dirty, "failed restore must not create a dirty buffer");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Reopen_Directory_Creates_No_Buffer;

   procedure Test_Workspace_Reopen_Already_Open_Dirty_No_Duplicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Path ("dirty_duplicate_root");
      File_A        : constant String := Ada.Directories.Compose (Root, "a.txt");
      S             : Editor.State.State_Type;
      Snapshot      : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status        : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary       : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Before_Count  : Natural;
      After_Count   : Natural;
      Found         : Boolean := False;
      Id            : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, File_A);
      Before_Count := Editor.Buffers.Global_Count;
      Set_Buffer_Text (S, "dirty in memory");
      S.File_Info.Dirty := True;
      S.File_Info.Last_Save_Failed := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Write_Text_File (File_A, "changed on disk");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      After_Count := Editor.Buffers.Global_Count;
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert
        (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
         "already-open dirty restore should succeed without reread");
      Assert (Summary.Files_Restored = 1, "already-open dirty file counts as restored");
      Assert (After_Count = Before_Count, "already-open restore must not duplicate buffers");
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "already-open file should still be tracked");
      Assert (Buffer_Text (S) = "dirty in memory",
              "already-open dirty restore must preserve unsaved content");
      Assert (Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "already-open dirty restore must preserve dirty marker");
      Assert (Editor.Buffers.Global_Summary_For (Id).Last_Save_Failed,
              "already-open dirty restore must preserve retry context");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Workspace_Reopen_Already_Open_Dirty_No_Duplicate;



   procedure Test_Restore_Order_And_Active_Buffer_Agree
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("order_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      File_B   : constant String := Ada.Directories.Compose (Root, "b.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Before_Count : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (File_B, "b");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("b.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "restore order should be a complete restore");
      Assert (Editor.Buffers.Global_Count = Before_Count + 2,
              "restore should append exactly the requested unique buffers");
      Assert (To_String (Editor.Buffers.Global_Summary_At (Before_Count + 1).Display_Name) = "b.txt",
              "first newly restored row should follow workspace order");
      Assert (To_String (Editor.Buffers.Global_Summary_At (Before_Count + 2).Display_Name) = "a.txt",
              "second newly restored row should follow workspace order");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "restored active buffer should match the active workspace reference");
      Assert (Editor.Buffers.Global_Summary_At (Before_Count + 2).Is_Active,
              "open-buffer active marker should match restored active buffer");
      Assert (Summary.Files_Restored = 2 and then Summary.Files_Skipped = 0,
              "restore summary should report two restored files");

      Remove_File_If_Exists (File_B);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (File_B);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restore_Order_And_Active_Buffer_Agree;

   procedure Test_Duplicate_Restored_File_Collapses_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("duplicate_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := False;
      Id       : Editor.Buffers.Buffer_Id;
      Before_Count : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before_Count := Editor.Buffers.Global_Count;

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      for I in 1 .. 2 loop
         Editor.Workspace_Persistence.Add_Open_File
           (Snapshot,
            (Path                => To_Unbounded_String ("a.txt"),
             Is_Project_Relative => True,
             Cursor_Row          => I - 1,
             Cursor_Column       => 0,
             View_First_Row      => 0));
      end loop;
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "duplicate restore references should collapse without making restore partial");
      Assert (Summary.Files_Requested = 2,
              "duplicate restore should keep requested count for deterministic feedback");
      Assert (Summary.Files_Restored = 1 and then Summary.Files_Skipped = 0,
              "duplicate restore should count only the unique restored file");
      Assert (Editor.Buffers.Global_Count = Before_Count + 1,
              "duplicate restore should append one open-buffer row");
      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "duplicate restore should leave the unique file-backed buffer tracked");
      Assert (S.File_Info.Has_Path and then To_String (S.File_Info.Path) = File_A,
              "duplicate active reference should focus the unique restored buffer");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Duplicate_Restored_File_Collapses_Deterministically;

   procedure Test_Restored_Cursor_And_Viewport_Clamp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("cursor_view_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (File_A, "one" & ASCII.LF & "last");
      Init_Executor_Test_State (S);
      Editor.View.Reset;
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 99,
          Cursor_Column       => 99,
          View_First_Row      => 99));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "cursor/viewport clamp restore should succeed");
      Assert (S.Carets.Length = 1,
              "restored cursor should leave exactly one caret");
      Assert (S.Carets (S.Carets.First_Index).Pos <= Text_Buffer.Length (S.Buffer),
              "restored cursor should clamp inside restored content");
      Assert (Editor.View.Scroll_Y = 1,
              "restored viewport should clamp to the last restored content row");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restored_Cursor_And_Viewport_Clamp;

   procedure Test_Clean_Restore_Clears_Transient_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("clean_lifecycle_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Found    : Boolean := False;
      Id       : Editor.Buffers.Buffer_Id;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Id := Editor.Buffers.Global_Find_By_Path (File_A, Found);

      Assert (Found and then Id /= Editor.Buffers.No_Buffer,
              "clean restore should track restored file");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Is_Dirty,
              "successful file-backed restore should start clean");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Last_Save_Failed,
              "successful restore must not revive failed-save context");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Missing_Target_Surfaced,
              "successful restore must not revive missing-target context");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Editor.Buffers.Global_Summary_For (Id).Display_Name),
                 "reload blocked") = 0,
              "restore summaries must not expose reload context");
      Assert (not Editor.Buffers.Global_Summary_For (Id).Blocked_Close_Surfaced,
              "successful restore must not revive blocked-close context");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clean_Restore_Clears_Transient_Lifecycle;



   procedure Test_Post_Restore_Command_Readiness
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("readiness_root");
      S          : Editor.State.State_Type;
      Snapshot   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status     : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary    : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Save_A     : Editor.Commands.Command_Availability;
      Reload_A   : Editor.Commands.Command_Availability;
      Close_A    : Editor.Commands.Command_Availability;
      Feature_A  : Editor.Commands.Command_Availability;
      Saw_Save    : Boolean := False;
      Saw_Reload  : Boolean := False;
      Saw_Close   : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);

      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);
      Save_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Save_File);
      Reload_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Reload_Active_Buffer);
      Close_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Close_Active_Buffer);
      Feature_A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Feature_Panel_Open_Selected);
      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);

      for C of Candidates loop
         if C.Id = Editor.Commands.Command_Save_File then
            Saw_Save := C.Available;
         elsif C.Id = Editor.Commands.Command_Reload_Active_Buffer then
            Saw_Reload := C.Available;
         elsif C.Id = Editor.Commands.Command_Close_Active_Buffer then
            Saw_Close := C.Available;
         end if;
      end loop;

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "restore fixture should succeed");
      Assert (Editor.Commands.Is_Available (Save_A),
              "post-restore save availability should match restored file-backed active buffer");
      Assert (Editor.Commands.Is_Available (Reload_A),
              "post-restore reload availability should match clean file-backed active buffer");
      Assert (Editor.Commands.Is_Available (Close_A),
              "post-restore close availability should match restored open buffer");
      Assert (not Editor.Commands.Is_Available (Feature_A),
              "post-restore Feature Panel activation should not revive stale rows");
      Assert (Saw_Save and then Saw_Reload and then Saw_Close,
              "Command Palette candidates should use restored availability without an extra refresh command");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Post_Restore_Command_Readiness;

   procedure Test_First_Save_After_Restore_Uses_Normal_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("save_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Cmd      : Editor.Commands.Command;
      Result   : Editor.Executor.Command_Execution_Result;
      Reloaded : Editor.Files.File_Open_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 1,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.File_Info.Dirty,
              "first edit after restore should dirty the restored active buffer");
      Assert (Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer).Is_Dirty,
              "first edit after restore should update open-buffer dirty marker");

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Save_File);
      Reloaded := Editor.Files.Open_File (File_A);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first save after restore should execute through normal save path");
      Assert (Editor.Files.Is_Success (Reloaded)
                and then To_String (Reloaded.Contents) = Editor.State.Current_Text (S),
              "first save after restore should write latest restored-buffer content");
      Assert (not S.File_Info.Dirty,
              "successful save after restore should clear active dirty marker");
      Assert (not Editor.Buffers.Global_Summary_For (Editor.Buffers.Global_Active_Buffer).Is_Dirty,
              "successful save after restore should clear open-buffer dirty marker");
      Assert (S.File_Info.Baseline_Valid
                and then S.File_Info.Saved_Generation = Editor.State.Current_Buffer_Revision (S),
              "successful save after restore should update saved baseline");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_First_Save_After_Restore_Uses_Normal_Path;

   procedure Test_First_Reload_After_Restore_Uses_Normal_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("reload_root");
      File_A   : constant String := Ada.Directories.Compose (Root, "a.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Cmd      : Editor.Commands.Command;
      Result   : Editor.Executor.Command_Execution_Result;
      Before   : Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Write_Text_File (File_A, "changed");
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first reload after clean restore should execute");
      Assert (Editor.State.Current_Text (S) = "changed",
              "first reload after restore should read replacement content");
      Assert (not S.File_Info.Dirty,
              "successful reload after restore should leave buffer clean");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'X';
      Cmd.Text := To_Unbounded_String (String'(1 => 'X'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Before := To_Unbounded_String (Editor.State.Current_Text (S));
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Reload_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Unavailable,
              "dirty restored buffer reload should be blocked before replacement");
      Assert (To_String (Before) = Editor.State.Current_Text (S),
              "blocked reload after restore should preserve dirty content");
      Assert (S.File_Info.Dirty,
              "blocked reload after restore should preserve dirty marker");

      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_First_Reload_After_Restore_Uses_Normal_Guards;

   procedure Test_First_Close_And_Navigation_After_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("close_nav_root");
      File_B   : constant String := Ada.Directories.Compose (Root, "b.txt");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Summary  : Editor.Workspace_Persistence.Workspace_Restore_Summary;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Write_Text_File (File_B, "b");
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("b.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Executor.Restore_Workspace_Snapshot (S, Snapshot, Status, Summary);

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Next_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then To_String (S.File_Info.Display_Name) = "b.txt",
              "next buffer after restore should follow restored order");
      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Previous_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then To_String (S.File_Info.Display_Name) = "a.txt",
              "previous buffer after restore should follow restored order");

      Result := Editor.Executor.Execute_Command_With_Result (S, Editor.Commands.Command_Close_Active_Buffer);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "first close after clean restore should execute");
      Assert (To_String (S.File_Info.Display_Name) = "b.txt",
              "closing restored active buffer should choose deterministic next active buffer");

      Remove_File_If_Exists (File_B);
      Cleanup_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (File_B);
         Cleanup_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_First_Close_And_Navigation_After_Restore;

   procedure Test_Restore_Feedback_Becomes_Historical_After_Edit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("feedback_edit_root");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
      Cmd      : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "restore feedback fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "explicit restore should execute");
      Assert (S.Post_Restore_Feedback_Current,
              "restore feedback should be current immediately after restore");
      Assert (S.Last_Restore_Summary_Available
                and then S.Last_Restore_Summary.Files_Requested = 1
                and then S.Last_Restore_Summary.Files_Restored = 1,
              "restore should retain structured restore details while feedback is current");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "restore Message should remain historical");

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not S.Post_Restore_Feedback_Current,
              "first edit should stop restore feedback being current");
      Assert (not S.Last_Restore_Summary_Available,
              "first edit should clear transient restore details");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "first edit should not erase historical restore Message");
      Assert (S.File_Info.Dirty,
              "restore feedback cleanup must preserve dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restore_Feedback_Becomes_Historical_After_Edit;

   procedure Test_Restore_Feedback_Replaced_By_Command_Outcome
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("feedback_command_root");
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "restore feedback command fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed
                and then S.Post_Restore_Feedback_Current,
              "restore feedback should start as current command feedback");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "save after restore should execute normally");
      Assert (not S.Post_Restore_Feedback_Current,
              "first command should replace restore-only current feedback");
      Assert (not S.File_Info.Dirty,
              "restore feedback replacement must not dirty clean buffer");
      Assert (Editor.Messages.Count (S.Messages) > 0,
              "command replacement keeps Messages as bounded history");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Restore_Feedback_Replaced_By_Command_Outcome;

   procedure Save_Minimal_Workspace_Session
     (Root : String)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace session fixture should save");
   end Save_Minimal_Workspace_Session;

   procedure Test_Clear_Workspace_State_Requires_Confirmation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("clear_workspace_confirm");
      Path : constant String := Editor.Workspace_Persistence.Session_File_Path (Root);
      S    : Editor.State.State_Type;
   begin
      Build_Fixture (Root);
      Save_Minimal_Workspace_Session (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
      Assert (Ada.Directories.Exists (Path),
              "first clear workspace command must preserve session file");
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "first clear workspace command should create pending confirmation");
      Assert
        (Editor.Pending_Transitions.Target_Kind (S.Pending_Transitions) =
         Editor.Pending_Transitions.Pending_Clear_Workspace_State,
         "clear workspace confirmation should use dedicated pending kind");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clear_Workspace_State_Requires_Confirmation;

   procedure Test_Clear_Workspace_State_Cancel_Preserves_Session
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("clear_workspace_cancel");
      Path : constant String := Editor.Workspace_Persistence.Session_File_Path (Root);
      S    : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Build_Fixture (Root);
      Save_Minimal_Workspace_Session (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "clear workspace should open confirmation before cancel");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Cancel_Pending_Transition);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "cancel pending transition should execute");
      Assert (Ada.Directories.Exists (Path),
              "cancel should preserve workspace session file");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "cancel should clear workspace confirmation");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clear_Workspace_State_Cancel_Preserves_Session;

   procedure Test_Clear_Workspace_State_Retry_Deletes_Session
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("clear_workspace_retry");
      Path : constant String := Editor.Workspace_Persistence.Session_File_Path (Root);
      S    : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Build_Fixture (Root);
      Save_Minimal_Workspace_Session (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
      Assert (Ada.Directories.Exists (Path)
                and then Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "clear workspace should stage confirmation before retry");

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "retry should confirm clear workspace");
      Assert (not Ada.Directories.Exists (Path),
              "retry should delete workspace session file");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "retry should clear workspace confirmation");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clear_Workspace_State_Retry_Deletes_Session;

   procedure Test_Clear_Workspace_State_Stale_Session_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("clear_workspace_stale");
      Path : constant String := Editor.Workspace_Persistence.Session_File_Path (Root);
      S    : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
   begin
      Build_Fixture (Root);
      Save_Minimal_Workspace_Session (Root);
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Workspace_Commands.Execute_Clear_Workspace_State (S);
      Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "clear workspace should stage confirmation before stale session removal");

      Ada.Directories.Delete_File (Path);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Retry_Pending_Transition);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "retry stale clear workspace should return a command outcome");
      Assert (not Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
              "stale clear workspace retry should clear pending confirmation");
      Assert (not Ada.Directories.Exists (Path),
              "stale clear workspace retry should not recreate session file");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Clear_Workspace_State_Stale_Session_Is_Rejected;



   procedure Prepare_Restored_File
     (Root : String;
      S    : in out Editor.State.State_Type)
   is
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Result   : Editor.Executor.Command_Execution_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Build_Fixture (Root);
      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("a.txt"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path (Snapshot, "a.txt", True);
      Editor.Workspace_Persistence.Save_To_File
        (Snapshot, Editor.Workspace_Persistence.Session_File_Path (Root), Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "restored-file fixture should save session");

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Restore_Workspace_State);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "restored-file fixture should restore session");
      Assert (S.Post_Restore_Feedback_Current,
              "restored-file fixture should start with current restore feedback");
   end Prepare_Restored_File;

   procedure Test_Ordinary_Commands_Clear_Restore_Transient_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Command_Clears
        (Suffix  : String;
         Command : Editor.Commands.Command_Id)
      is
         Root   : constant String := Temp_Path ("restore_clear_" & Suffix);
         S      : Editor.State.State_Type;
         Result : Editor.Executor.Command_Execution_Result;
      begin
         Prepare_Restored_File (Root, S);
         Result := Editor.Executor.Execute_Command_With_Result (S, Command);
         Assert (Result.Status = Editor.Executor.Command_Executed
                   or else Result.Status = Editor.Executor.Command_Unavailable,
                 "ordinary command should return a bounded command outcome");
         Assert (not S.Post_Restore_Feedback_Current,
                 "ordinary command should clear current restore feedback");
         Assert (not S.Last_Restore_Summary_Available,
                 "ordinary command should clear transient restore details");
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
      exception
         when others =>
            Remove_Tree_If_Exists (Root);
            Editor.Buffers.Reset_Global_For_Test;
            raise;
      end Expect_Command_Clears;

      Project_Root : constant String := Temp_Path ("restore_clear_project_switch");
      Next_Root    : constant String := Temp_Path ("restore_clear_project_next");
      S            : Editor.State.State_Type;
   begin
      Expect_Command_Clears
        ("quick_open",
         Editor.Commands.Command_Open_Quick_Open);
      Expect_Command_Clears
        ("command_palette",
         Editor.Commands.Command_Open_Command_Palette);
      Expect_Command_Clears
        ("diagnostics",
         Editor.Commands.Command_Diagnostics_Show);
      Expect_Command_Clears
        ("build_ui",
         Editor.Commands.Command_Build_UI_Show);

      Prepare_Restored_File (Project_Root, S);
      Build_Fixture (Next_Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Next_Root);
      Assert (not S.Post_Restore_Feedback_Current,
              "project switch should clear current restore feedback");
      Assert (not S.Last_Restore_Summary_Available,
              "project switch should clear transient restore details");
      Remove_Tree_If_Exists (Project_Root);
      Remove_Tree_If_Exists (Next_Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Project_Root);
         Remove_Tree_If_Exists (Next_Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Ordinary_Commands_Clear_Restore_Transient_State;

   procedure Test_Save_After_Cleanup_Uses_Ordinary_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("save_after_cleanup_root");
      S      : Editor.State.State_Type;
      Cmd    : Editor.Commands.Command;
      Result : Editor.Executor.Command_Execution_Result;
      Before : Natural := 0;
      Latest : Unbounded_String;
   begin
      Prepare_Restored_File (Root, S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not S.Post_Restore_Feedback_Current,
              "edit cleanup should make restore feedback historical");
      Assert (S.File_Info.Dirty,
              "edit after cleanup should expose ordinary dirty state");

      Before := Editor.Messages.Count (S.Messages);
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Save_File);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Result.Status = Editor.Executor.Command_Executed,
              "save after cleanup should execute through normal save path");
      Assert (Editor.Messages.Count (S.Messages) = Before + 1,
              "save after cleanup should post exactly one primary save message");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Saved a.txt") > 0,
              "save after cleanup should make the current feedback the save result");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state restored") = 0,
              "save after cleanup must not repost restore success as current feedback");
      Assert (not S.File_Info.Dirty,
              "successful save after cleanup should clear dirty state normally");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Save_After_Cleanup_Uses_Ordinary_Feedback;

   procedure Test_Direct_Open_Clears_Restore_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("direct_open_root");
      S         : Editor.State.State_Type;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Before    : Natural := 0;
      Latest    : Unbounded_String;
   begin
      Prepare_Restored_File (Root, S);
      Before := Editor.Messages.Count (S.Messages);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, File_Path);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (not S.Post_Restore_Feedback_Current,
              "direct open/focus should clear current restore feedback");
      Assert (Editor.Messages.Count (S.Messages) = Before + 1,
              "direct open/focus should post only its own normal feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Focused existing buffer a.txt") > 0,
              "direct open/focus should use ordinary already-open feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state restored") = 0,
              "direct open/focus must not revive restore feedback");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Direct_Open_Clears_Restore_Feedback;

   procedure Test_File_Tree_Row_Action_Is_Ordinary_After_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("file_tree_action_root");
      S         : Editor.State.State_Type;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found     : Boolean := False;
      Latest    : Unbounded_String;
   begin
      Prepare_Restored_File (Root, S);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found,
              "File Tree fixture should contain restored file row");

      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (not S.Post_Restore_Feedback_Current,
              "direct File Tree row action should clear current restore feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Focused existing buffer a.txt") > 0,
              "File Tree activation after cleanup should use normal focus feedback");
      Assert (Ada.Strings.Fixed.Index (To_String (Latest), "Workspace state") = 0,
              "File Tree activation must not repost restore details");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Tree_Row_Action_Is_Ordinary_After_Restore;

   procedure Test_Already_Open_Dirty_File_Tree_Focus_Preserves_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("dirty_focus_root");
      S         : Editor.State.State_Type;
      Cmd       : Editor.Commands.Command;
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node      : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found     : Boolean := False;
      Before    : Unbounded_String;
   begin
      Prepare_Restored_File (Root, S);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'Z';
      Cmd.Text := To_Unbounded_String (String'(1 => 'Z'));
      Cmd.Code := Wide_Wide_Character'Val (0);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Before := To_Unbounded_String (Editor.State.Current_Text (S));
      Assert (S.File_Info.Dirty,
              "dirty focus fixture should be dirty after edit");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, File_Path, Found);
      Assert (Found,
              "dirty File Tree fixture should contain file row");
      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (S.File_Info.Dirty,
              "already-open File Tree activation should preserve dirty state");
      Assert (To_String (Before) = Editor.State.Current_Text (S),
              "already-open File Tree activation must not reread and replace dirty text");
      Assert (not S.Post_Restore_Feedback_Current,
              "dirty File Tree activation should leave restore feedback historical");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Already_Open_Dirty_File_Tree_Focus_Preserves_Text;



   procedure Test_Open_Edit_Syncs_Ordinary_Dirty_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("open_edit_dirty_root");
      S      : Editor.State.State_Type;
      Path   : constant String := Ada.Directories.Compose (Root, "a.txt");
      Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Row    : Editor.Buffers.Buffer_Summary;
      Avail  : Editor.Commands.Command_Availability;
      Recent_Before : Natural := 0;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;
      Row := Editor.Buffers.Global_Summary_For (Id);
      Assert (Id /= Editor.Buffers.No_Buffer and then Row.Has_Path,
              "open should create a file-backed active buffer row");
      Assert (not Row.Is_Dirty and then not S.File_Info.Dirty,
              "newly opened file-backed buffer should start clean");

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, 'Z'));
      Row := Editor.Buffers.Global_Summary_For (Id);
      Avail := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Save_File);

      Assert (Buffer_Text (S) = "aZ",
              "typing after open should edit the active buffer only");
      Assert (S.File_Info.Dirty,
              "typing after open should dirty the active buffer");
      Assert (Row.Is_Dirty,
              "open-buffer row should become dirty immediately after typing");
      Assert (Editor.Commands.Is_Available (Avail),
              "save availability should follow the dirty active buffer");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save (S);
      Row := Editor.Buffers.Global_Summary_For (Id);
      Assert (not S.File_Info.Dirty and then not Row.Is_Dirty,
              "successful ordinary save should clear buffer and row dirty state");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Open_Edit_Syncs_Ordinary_Dirty_Row;

   procedure Test_Repeated_Switching_Preserves_Ordinary_Edit_Context
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("switch_context_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      A_Row  : Editor.Buffers.Buffer_Summary;
      B_Row  : Editor.Buffers.Buffer_Summary;
   begin
      Build_Fixture (Root);
      Write_Text_File (B_Path, "b");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Assert (Buffer_Text (S) = "b!",
              "setup should edit the second active buffer");
      B_Row := Editor.Buffers.Global_Summary_For (B_Id);
      Assert (B_Row.Is_Dirty,
              "dirty row should be visible before switching away");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "a",
              "switching to first buffer should restore first content");
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '?'));
      A_Row := Editor.Buffers.Global_Summary_For (A_Id);
      Assert (Buffer_Text (S) = "a?" and then A_Row.Is_Dirty,
              "editing after switch should dirty only the selected first buffer");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      A_Row := Editor.Buffers.Global_Summary_For (A_Id);
      B_Row := Editor.Buffers.Global_Summary_For (B_Id);
      Assert (Buffer_Text (S) = "b!",
              "switching back should restore second buffer content");
      Assert (A_Row.Is_Dirty and then B_Row.Is_Dirty,
              "repeated switching should preserve each buffer dirty marker");
      Assert (Editor.Buffers.Global_Active_Buffer = B_Id,
              "active open-buffer marker should follow the final switch");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Repeated_Switching_Preserves_Ordinary_Edit_Context;

   procedure Test_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("dirty_reload_root");
      S           : Editor.State.State_Type;
      Path        : constant String := Ada.Directories.Compose (Root, "a.txt");
      Id          : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Text : Unbounded_String;
      Row         : Editor.Buffers.Buffer_Summary;
      Latest      : Unbounded_String;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Before_Text := To_Unbounded_String (Buffer_Text (S));
      Write_Text_File (Path, "disk replacement");

      Editor.Executor.File_Save_Basic_Commands.Execute_Reload_Active_Buffer (S);
      Row := Editor.Buffers.Global_Summary_For (Id);
      Latest := To_Unbounded_String (Latest_Message_Text (S));

      Assert (Buffer_Text (S) = To_String (Before_Text),
              "dirty reload should block before content replacement");
      Assert (S.File_Info.Dirty and then Row.Is_Dirty,
              "blocked reload should preserve buffer and row dirty state");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Row.Display_Name), "reload blocked") = 0,
              "dirty reload must not record reload lifecycle context on the current buffer");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Latest), "Dirty buffer cannot be reloaded") > 0,
              "blocked reload feedback should describe the current ordinary action");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift;

   procedure Test_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Path ("file_tree_focus_root");
      S            : Editor.State.State_Type;
      Path         : constant String := Ada.Directories.Compose (Root, "a.txt");
      Node         : Editor.File_Tree.File_Tree_Node_Id := Editor.File_Tree.No_File_Tree_Node;
      Found        : Boolean := False;
      Before_Count : Natural := 0;
      Before_Text  : Unbounded_String;
   begin
      Build_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (Buffer_Text (S)'Length, '!'));
      Before_Count := Editor.Buffers.Global_Count;
      Before_Text := To_Unbounded_String (Buffer_Text (S));

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, Path, Found);
      Assert (Found,
              "file tree fixture should contain the ordinary file row");
      Editor.Executor.File_Tree_Navigation_Commands.Execute_File_Tree_Node_Action
        (S, Node, Editor.File_Tree_View.Open_File_Action);

      Assert (Editor.Buffers.Global_Count = Before_Count,
              "File Tree focus should not duplicate already-open rows");
      Assert (S.File_Info.Dirty,
              "File Tree focus should preserve already-open dirty state");
      Assert (Buffer_Text (S) = To_String (Before_Text),
              "File Tree focus should not reload over dirty text");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily;


   overriding procedure Register_Tests (T : in out Project_Workspace_Session_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Reopen_Missing_Active_Falls_Back'Access,
         "workspace reopen missing active falls back");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Active_Outside_Open_Set_Does_Not_Open'Access,
         "workspace active outside open set does not open");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Reopen_Directory_Creates_No_Buffer'Access,
         "workspace reopen directory creates no buffer");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Workspace_Reopen_Already_Open_Dirty_No_Duplicate'Access,
         "workspace reopen already-open dirty no duplicate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restore_Order_And_Active_Buffer_Agree'Access,
         "restore order and active buffer agree");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Duplicate_Restored_File_Collapses_Deterministically'Access,
         "duplicate restored file collapses deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restored_Cursor_And_Viewport_Clamp'Access,
         "restored cursor and viewport clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clean_Restore_Clears_Transient_Lifecycle'Access,
         "clean restore clears transient lifecycle");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Post_Restore_Command_Readiness'Access,
         "post-restore command readiness");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_First_Save_After_Restore_Uses_Normal_Path'Access,
         "first save after restore uses normal path");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_First_Reload_After_Restore_Uses_Normal_Guards'Access,
         "first reload after restore uses normal guards");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_First_Close_And_Navigation_After_Restore'Access,
         "first close and navigation after restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restore_Feedback_Becomes_Historical_After_Edit'Access,
         "restore feedback becomes historical after edit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Restore_Feedback_Replaced_By_Command_Outcome'Access,
         "restore feedback replaced by command outcome");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Workspace_State_Requires_Confirmation'Access,
         "clear workspace state requires confirmation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Workspace_State_Cancel_Preserves_Session'Access,
         "clear workspace state cancel preserves session");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Workspace_State_Retry_Deletes_Session'Access,
         "clear workspace state retry deletes session");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Workspace_State_Stale_Session_Is_Rejected'Access,
         "clear workspace state stale session is rejected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Ordinary_Commands_Clear_Restore_Transient_State'Access,
         "ordinary commands clear restore transient state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Save_After_Cleanup_Uses_Ordinary_Feedback'Access,
         "save after cleanup uses ordinary feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Direct_Open_Clears_Restore_Feedback'Access,
         "direct open clears restore feedback");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Row_Action_Is_Ordinary_After_Restore'Access,
         "file tree row action is ordinary after restore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Already_Open_Dirty_File_Tree_Focus_Preserves_Text'Access,
         "already open dirty file tree focus preserves text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Edit_Syncs_Ordinary_Dirty_Row'Access,
         "open edit syncs ordinary dirty row");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Repeated_Switching_Preserves_Ordinary_Edit_Context'Access,
         "repeated switching preserves ordinary edit context");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Ordinary_Dirty_Reload_Blocks_Without_Row_Drift'Access,
         "ordinary dirty reload blocks without row drift");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Tree_Focuses_Already_Open_Dirty_File_Ordinarily'Access,
         "file tree focuses already open dirty file ordinarily");
   end Register_Tests;

end Editor.Executor.Project_Workspace_Session_Tests;
