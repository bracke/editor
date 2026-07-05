with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Workspace_Persistence;

package body Editor.Workspace_Persistence.Tests is

   use type Ada.Directories.File_Kind;

   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Workspace_Persistence.Bottom_Content_Id;
   use type Editor.Workspace_Persistence.Workspace_Diagnostic_Kind;
   use type Editor.Workspace_Persistence.Workspace_Session_File_Status;

   function Name
     (T : Workspace_Persistence_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Workspace_Persistence.Tests");
   end Name;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "" & Name);
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Directory (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Tree (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Write_Text (Path : String; Text : String) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Text);
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Write_Text;

   function Read_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            Append (Result, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Read_Text;

   procedure Test_Snapshot_Defaults_And_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
   begin
      Assert (Editor.Workspace_Persistence.Version (Snapshot) = 1,
              "workspace snapshot should default to version 1");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Snapshot),
              "new workspace snapshot should have no project root");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 0,
              "new workspace snapshot should have no open files");

      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 12,
          Cursor_Column       => 4,
          View_First_Row      => 2));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/editor.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Snapshot, "src");

      Assert (Editor.Workspace_Persistence.Has_Project_Root (Snapshot),
              "Set_Project_Root should mark project root present");
      Assert (Editor.Workspace_Persistence.Project_Root (Snapshot) = "/tmp/project",
              "Set_Project_Root should store root path");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "Add_Open_File should append a file entry");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "Set_Active_File_Path should mark active file present");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Snapshot) = 1,
              "Add_Expanded_File_Tree_Path should append expansion path");
      Editor.Workspace_Persistence.Set_Recent_Project_Path
        (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Set_Quick_Open_Path_Scope
        (Snapshot, "src");
      Editor.Workspace_Persistence.Set_Quick_Open_File_Kind_Filter
        (Snapshot,
         Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files);
      Editor.Workspace_Persistence.Set_Feature_Panel
        (Snapshot, True,
         Editor.Workspace_Persistence.Workspace_Diagnostics_Feature);
      Assert (Editor.Workspace_Persistence.Has_Recent_Project_Path (Snapshot),
              "Set_Recent_Project_Path should mark recent project present");
      Assert (Editor.Workspace_Persistence.Quick_Open_Path_Scope (Snapshot) = "src/",
              "Set_Quick_Open_Path_Scope should store canonical directory scope");
      Assert (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (Snapshot) =
                Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files,
              "Set_Quick_Open_File_Kind_Filter should store the stable filter");
      Assert (Editor.Workspace_Persistence.Feature_Panel_Visible (Snapshot),
              "Set_Feature_Panel should preserve feature panel visibility");
      Assert (Editor.Workspace_Persistence.Active_Feature_Panel (Snapshot) =
                Editor.Workspace_Persistence.Workspace_Diagnostics_Feature,
              "Set_Feature_Panel should preserve active feature panel");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Snapshot),
              "Clear should remove project root");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 0,
              "Clear should remove open files");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "Clear should remove active file path");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Snapshot) = 0,
              "Clear should remove file-tree expansion paths");
      Assert (not Editor.Workspace_Persistence.Has_Recent_Project_Path (Snapshot),
              "Clear should remove recent project path");
      Assert (Editor.Workspace_Persistence.Quick_Open_Path_Scope (Snapshot) = "",
              "Clear should remove Quick Open scope");
      Assert (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (Snapshot) =
                Editor.Workspace_Persistence.Workspace_Quick_Open_All_Files,
              "Clear should restore the default Quick Open filter");
      Assert (not Editor.Workspace_Persistence.Feature_Panel_Visible (Snapshot),
              "Clear should hide feature panel");
      Assert (Editor.Workspace_Persistence.Active_Feature_Panel (Snapshot) =
                Editor.Workspace_Persistence.Workspace_Outline_Feature,
              "Clear should restore default active feature panel");
   end Test_Snapshot_Defaults_And_Clear;

   procedure Test_Save_Load_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := Temp_Path ("workspace_session.txt");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Item    : Editor.Workspace_Persistence.Workspace_File_Entry;
   begin
      Remove_If_Exists (Path);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 12,
          Cursor_Column       => 4,
          View_First_Row      => 2));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/editor-state.ads"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/editor.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Snapshot, "src");
      Editor.Workspace_Persistence.Set_File_Tree_Panel (Snapshot, True, 32);
      Editor.Workspace_Persistence.Set_Bottom_Panel
        (Snapshot, True, 12,
         Editor.Workspace_Persistence.Workspace_Search_Results_Content);
      Editor.Workspace_Persistence.Set_Recent_Project_Path
        (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Set_Quick_Open_Path_Scope
        (Snapshot, "src/editor");
      Editor.Workspace_Persistence.Set_Quick_Open_File_Kind_Filter
        (Snapshot,
         Editor.Workspace_Persistence.Workspace_Quick_Open_Test_Files);
      Editor.Workspace_Persistence.Set_Feature_Panel
        (Snapshot, True,
         Editor.Workspace_Persistence.Workspace_Diagnostics_Feature);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Save_To_File should write deterministic workspace file");

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Load_From_File should load saved workspace file");
      Assert (Editor.Workspace_Persistence.Project_Root (Loaded) = "/tmp/project",
              "roundtrip should preserve project root");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 2,
              "roundtrip should preserve open file count");
      Item := Editor.Workspace_Persistence.Open_File (Loaded, 1);
      Assert (To_String (Item.Path) = "src/editor.adb",
              "roundtrip should preserve open file order");
      Assert (Item.Cursor_Row = 12 and then Item.Cursor_Column = 4,
              "roundtrip should preserve caret row and column");
      Assert (Editor.Workspace_Persistence.Active_File_Path (Loaded) = "src/editor.adb",
              "roundtrip should preserve active file path");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path (Loaded, 1) = "src",
              "roundtrip should preserve file tree expansion path");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Width (Loaded) = 32,
              "roundtrip should preserve file tree panel width");
      Assert (Editor.Workspace_Persistence.Bottom_Panel_Height (Loaded) = 12,
              "roundtrip should preserve bottom panel height");
      Assert (Editor.Workspace_Persistence.Active_Bottom_Content (Loaded) =
                Editor.Workspace_Persistence.Workspace_Search_Results_Content,
              "roundtrip should preserve active bottom panel content");
      Assert (Editor.Workspace_Persistence.Has_Recent_Project_Path (Loaded)
              and then Editor.Workspace_Persistence.Recent_Project_Path (Loaded) =
                "/tmp/project",
              "roundtrip should preserve recent project path");
      Assert (Editor.Workspace_Persistence.Quick_Open_Path_Scope (Loaded) =
                "src/editor/",
              "roundtrip should preserve Quick Open path scope");
      Assert (Editor.Workspace_Persistence.Quick_Open_File_Kind_Filter (Loaded) =
                Editor.Workspace_Persistence.Workspace_Quick_Open_Test_Files,
              "roundtrip should preserve Quick Open file-kind filter");
      Assert (Editor.Workspace_Persistence.Feature_Panel_Visible (Loaded)
              and then Editor.Workspace_Persistence.Active_Feature_Panel (Loaded) =
                Editor.Workspace_Persistence.Workspace_Diagnostics_Feature,
              "roundtrip should preserve feature panel visibility and selection");
      Assert (Ada.Strings.Fixed.Index (Read_Text (Path), "[theme]") = 0,
              "workspace save must exclude settings-owned theme section");
      Assert (Ada.Strings.Fixed.Index (Read_Text (Path), "active=dark") = 0,
              "workspace save must exclude settings-owned theme value");

      Remove_If_Exists (Path);
   end Test_Save_Load_Roundtrip;

   procedure Test_Load_Error_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant String := Temp_Path ("missing_session.txt");
      Invalid : constant String := Temp_Path ("invalid_session.txt");
      Future  : constant String := Temp_Path ("future_session.txt");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_If_Exists (Missing);
      Editor.Workspace_Persistence.Load_From_File (Missing, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Not_Found,
              "missing workspace file should return Not_Found");

      Write_Text (Invalid, "not-a-workspace" & ASCII.LF);
      Editor.Workspace_Persistence.Load_From_File (Invalid, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "malformed header should return Invalid_Format");

      Write_Text (Future, "editor-workspace-version=999" & ASCII.LF);
      Editor.Workspace_Persistence.Load_From_File (Future, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Unsupported_Version,
              "future workspace version should return Unsupported_Version");

      Remove_If_Exists (Invalid);
      Remove_If_Exists (Future);
   end Test_Load_Error_Statuses;

   procedure Test_Malformed_Optional_Entry_Is_Partial
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := Temp_Path ("partial_session.txt");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/editor.adb|relative=true|row=not-a-number|col=4|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/editor.adb|relative=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "malformed optional field should mark load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 0,
              "malformed canonical metadata should reject the file entry");
      Remove_If_Exists (Path);
   end Test_Malformed_Optional_Entry_Is_Partial;



   procedure Test_Path_Safety_And_Normalization
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Valid : Boolean;
      Clean : constant String := Editor.Workspace_Persistence.Normalize_Project_Relative_Path
        ("src\\core//editor.adb", Valid);
   begin
      Assert ((not Valid) and then Clean = "",
              "strict normalization should reject noncanonical separators");
      Assert (not Editor.Workspace_Persistence.Is_Safe_Project_Relative_Path ("../outside.adb"),
              "workspace persistence should reject parent-directory escapes");
      Assert (not Editor.Workspace_Persistence.Is_Safe_Project_Relative_Path ("/tmp/outside.adb"),
              "workspace persistence should reject absolute file paths");
      Assert (not Editor.Workspace_Persistence.Is_Safe_Project_Relative_Path ("src/./editor.adb"),
              "workspace persistence should reject explicit dot path segments");
   end Test_Path_Safety_And_Normalization;

   procedure Test_Normalize_Equivalent_And_Deterministic_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path_A : constant String := Temp_Path ("a.session");
      Path_B : constant String := Temp_Path ("b.session");
      Left   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Right  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);

      Editor.Workspace_Persistence.Set_Project_Root (Left, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Left,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 3,
          Cursor_Column       => 2,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Open_File
        (Left,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 9,
          Cursor_Column       => 9,
          View_First_Row      => 9));
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Left, "zeta");
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Left, "src");
      Editor.Workspace_Persistence.Set_Active_File_Path (Left, "src/editor.adb", True);

      Editor.Workspace_Persistence.Set_Project_Root (Right, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Right,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 3,
          Cursor_Column       => 2,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Right, "src");
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Right, "zeta");
      Editor.Workspace_Persistence.Set_Active_File_Path (Right, "src/editor.adb", True);

      Assert (Editor.Workspace_Persistence.Equivalent (Left, Right),
              "Equivalent should compare normalized semantic snapshot content: " &
              Editor.Workspace_Persistence.Debug_Summary (Left));

      Editor.Workspace_Persistence.Save_To_File (Left, Path_A, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "normalized save should succeed");
      Editor.Workspace_Persistence.Save_To_File (Right, Path_B, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "second normalized save should succeed");
      Assert (Read_Text (Path_A) = Read_Text (Path_B),
              "equivalent snapshots should serialize to identical bytes");

      Remove_If_Exists (Path_A);
      Remove_If_Exists (Path_B);
   end Test_Normalize_Equivalent_And_Deterministic_Save;

   procedure Test_Atomic_Save_Overwrites_And_Cleans_Temp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("atomic.session");
      Temp   : constant String := Ada.Directories.Compose
        (Ada.Directories.Containing_Directory (Path),
         "." & Ada.Directories.Simple_Name (Path) & ".tmp");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Temp);
      Write_Text (Path, "previous-good-session");

      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/editor.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 0,
          Cursor_Column       => 0,
          View_First_Row      => 0));

      Editor.Workspace_Persistence.Save_To_File_Atomically (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "atomic workspace save should succeed");
      Assert (Read_Text (Path)'Length > 0 and then Read_Text (Path) /= "previous-good-session",
              "atomic save should replace the target with serialized content");
      Assert (not Ada.Directories.Exists (Temp),
              "atomic save should remove the temporary file after success");

      Remove_If_Exists (Path);
   end Test_Atomic_Save_Overwrites_And_Cleans_Temp;

   procedure Test_Corrupt_And_Unsafe_Input_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("corrupt.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "../outside.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "src/ok.adb|relative=true|row=bad|col=0|view=0" & ASCII.LF &
         "src/ok.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[unknown-section]" & ASCII.LF &
         "ignored=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "unsafe or malformed optional entries should produce partial status");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "unsafe open-file path should be skipped while safe entries remain");
      Assert (Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) >= 3,
              "loader should retain diagnostics for corrupt optional entries");

      Remove_If_Exists (Path);
   end Test_Corrupt_And_Unsafe_Input_Diagnostics;


   procedure Test_Save_To_File_Uses_Safe_Session_Path
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("project_root");
      Path     : constant String :=
        Editor.Workspace_Persistence.Session_File_Path_For_Project (Root);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Path (Root);

      Assert
        (Editor.Workspace_Persistence.Is_Session_File_Path_For_Project
           (Root, Path),
         "session path helper should identify the per-project session file");
      Assert
        (not Editor.Workspace_Persistence.Is_Session_File_Path_For_Project
           (Root, Ada.Directories.Compose (Root, "not-session")),
         "session path helper should reject arbitrary project paths");

      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Save_To_File should use the atomic save policy");
      Assert (Ada.Directories.Exists (Path),
              "Save_To_File should create the configured .editor/session file");

      Remove_Tree_If_Exists (Root);
   end Test_Save_To_File_Uses_Safe_Session_Path;

   procedure Test_Duplicate_And_Sorted_Path_Load_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("duplicates.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/a.adb|relative=true|row=1|col=2|view=3" & ASCII.LF &
         "src/a.adb|relative=true|row=9|col=9|view=9" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "a" & ASCII.LF &
         "z" & ASCII.LF &
         "z" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "duplicate paths should be diagnosed as a partial load");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "duplicate open-file paths should be ignored after the first entry");

      Editor.Workspace_Persistence.Normalize (Snapshot);
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path (Snapshot, 1) = "a",
              "expanded paths should sort lexicographically during normalization");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path (Snapshot, 2) = "z",
              "duplicate expanded paths should be removed during normalization");

      Remove_If_Exists (Path);
   end Test_Duplicate_And_Sorted_Path_Load_Save;

   procedure Test_Empty_File_Invalid_With_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("empty.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Write_Text (Path, "");
      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "empty workspace file should be invalid");
      Assert (Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) >= 1,
              "empty workspace file should retain a parse diagnostic");
      Remove_If_Exists (Path);
   end Test_Empty_File_Invalid_With_Diagnostic;




   procedure Test_Status_State_Is_Not_Persisted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("status_exclusion.ws");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Output   : Unbounded_String;
   begin
      Remove_If_Exists (Path);

      Editor.Workspace_Persistence.Set_Project_Root
        (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 4,
          Cursor_Column       => 2,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", True);
      Editor.Workspace_Persistence.Set_File_Tree_Panel
        (Snapshot, Visible => True, Width => 30);
      Editor.Workspace_Persistence.Set_Bottom_Panel
        (Snapshot, Visible => True, Height => 8,
         Content => Editor.Workspace_Persistence.Workspace_Problems_Content);

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "setup should save a workspace snapshot");

      Output := To_Unbounded_String (Read_Text (Path));

      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Saved main.adb") = 0,
              "workspace save must exclude latest command message text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Confirmation required") = 0,
              "workspace save must exclude pending confirmation status text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "No selection") = 0,
              "workspace save must exclude selection summary text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Outline:") = 0,
              "workspace save must exclude outline status summary text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Current:") = 0,
              "workspace save must exclude current-symbol status text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "current-symbol") = 0,
              "workspace save must exclude current-symbol state fields");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "outline-filter") = 0,
              "workspace save must exclude Outline filter state fields");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "filtered-outline") = 0,
              "workspace save must exclude filtered Outline projections");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "last-navigated-symbol") = 0,
              "workspace save must exclude symbol navigation history");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Diagnostics:") = 0,
              "workspace save must exclude diagnostics status summary text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Build:") = 0,
              "workspace save must exclude build status summary text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Search:") = 0,
              "workspace save must exclude search status summary text");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "Project switch pending") = 0,
              "workspace save must exclude project pending status text");

      Remove_If_Exists (Path);
   end Test_Status_State_Is_Not_Persisted;


   procedure Test_Active_File_Must_Belong_To_Open_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("active_membership.session");
      Saved    : constant String := Temp_Path ("active_membership_saved.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Output   : Unbounded_String;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/hidden.adb|relative=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "active file outside open-files should make workspace load partial");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "active file outside open-files must not survive load as structural state");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "valid open files should still load when active file is stale");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Saved, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saving normalized active membership snapshot should succeed");
      Output := To_Unbounded_String (Read_Text (Saved));
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "src/hidden.adb") = 0,
              "save must drop active-file references that are not in open-files");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "src/main.adb") > 0,
              "save must retain structural open file references");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/active-only.adb", True);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Saved, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saving active-only snapshot should succeed by dropping non-structural active reference");
      Output := To_Unbounded_String (Read_Text (Saved));
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "src/active-only.adb") = 0,
              "normalization must not persist active-file references outside open-files");

      Remove_If_Exists (Path);
      Remove_If_Exists (Saved);
   end Test_Active_File_Must_Belong_To_Open_Files;


   procedure Test_Invalid_Project_Root_Is_Diagnostic_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("invalid_project_root.session");
      Saved    : constant String := Temp_Path ("invalid_project_root_saved.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Output   : Unbounded_String;
      Saw_Invalid_Project : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "invalid project-root should make workspace load partial, not fatal");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Snapshot),
              "empty project-root must not fabricate project context");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "valid structural open files should remain available after invalid project root");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Invalid_Path
         then
            Saw_Invalid_Project := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Project,
              "invalid project-root should produce an explicit invalid path diagnostic");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Saved, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saving after invalid project-root load should drop the bad root");
      Output := To_Unbounded_String (Read_Text (Saved));
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "project-root=") = 0,
              "normalized save must not re-emit invalid project-root");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "src/main.adb") > 0,
              "normalized save must retain valid structural open files");

      Remove_If_Exists (Path);
      Remove_If_Exists (Saved);
   end Test_Invalid_Project_Root_Is_Diagnostic_Only;


   procedure Test_Zero_Panel_Dimensions_Are_Diagnostic_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("zero_panel_dimensions.session");
      Saved    : constant String := Temp_Path ("zero_panel_dimensions_saved.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Output   : Unbounded_String;
      Saw_Invalid_Panel : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=0" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=0" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "zero panel dimensions should make workspace load partial, not fatal");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Width (Snapshot) = 28,
              "invalid file tree width should leave the structural default in effect");
      Assert (Editor.Workspace_Persistence.Bottom_Panel_Height (Snapshot) = 8,
              "invalid bottom panel height should leave the structural default in effect");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Invalid_Panel_Value
         then
            Saw_Invalid_Panel := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Panel,
              "zero panel dimensions should produce explicit panel diagnostics");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Saved, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saving after invalid panel values should succeed");
      Output := To_Unbounded_String (Read_Text (Saved));
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "file-tree-width=0") = 0,
              "normalized save must not re-emit zero file tree panel width");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "bottom-height=0") = 0,
              "normalized save must not re-emit zero bottom panel height");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "file-tree-width=28") > 0,
              "normalized save should retain the file tree structural default width");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "bottom-height=8") > 0,
              "normalized save should retain the bottom panel structural default height");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Set_File_Tree_Panel (Snapshot, True, 0);
      Editor.Workspace_Persistence.Set_Bottom_Panel
        (Snapshot, False, 0,
         Editor.Workspace_Persistence.Workspace_Problems_Content);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Saved, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saving an in-memory snapshot with zero panel dimensions should normalize it");
      Output := To_Unbounded_String (Read_Text (Saved));
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "file-tree-width=0") = 0,
              "programmatic zero file tree width must not persist");
      Assert (Ada.Strings.Fixed.Index (To_String (Output), "bottom-height=0") = 0,
              "programmatic zero bottom height must not persist");

      Remove_If_Exists (Path);
      Remove_If_Exists (Saved);
   end Test_Zero_Panel_Dimensions_Are_Diagnostic_Only;



   procedure Test_Path_Only_File_Rows_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("path_only_file_rows.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/path_only_open.adb" & ASCII.LF &
         "src/canonical.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/path_only_active.adb" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "path-only file rows should make workspace load partial under the canonical schema");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "canonical open-file row should still load after rejecting path-only row");
      Assert (Editor.Workspace_Persistence.Open_File (Snapshot, 1).Path =
                To_Unbounded_String ("src/canonical.adb"),
              "path-only open-file row must not be retained as structural state");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "path-only active-file row must not be retained as structural state");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "path-only open/active file rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Path_Only_File_Rows_Are_Rejected;

   procedure Test_File_Rows_Require_Full_Canonical_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("full_metadata_required.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
      Saw_Unsupported : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/missing_view.adb|relative=true|row=1|col=2" & ASCII.LF &
         "src/noncanonical_extra.adb|relative=true|row=1|col=2|view=3|extra=4" & ASCII.LF &
         "src/canonical.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/canonical.adb|row=0" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "noncanonical metadata-bearing file rows should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "only fully canonical open-file rows should load");
      Assert (Editor.Workspace_Persistence.Open_File (Snapshot, 1).Path =
                To_Unbounded_String ("src/canonical.adb"),
              "canonical row should still load after rejecting noncanonical metadata rows");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "active-file rows without canonical relative metadata must not restore active state");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         elsif Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Unsupported_Key
         then
            Saw_Unsupported := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "missing required canonical metadata should produce malformed-line diagnostics");
      Assert (Saw_Unsupported,
              "extra noncanonical metadata keys should produce unsupported-key diagnostics");

      Remove_If_Exists (Path);
   end Test_File_Rows_Require_Full_Canonical_Metadata;





   procedure Test_Duplicate_Canonical_Metadata_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("duplicate_metadata.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/dup_row.adb|relative=true|row=1|row=2|col=0|view=0" & ASCII.LF &
         "src/dup_relative.adb|relative=true|relative=false|row=1|col=0|view=0" & ASCII.LF &
         "src/wrong_order.adb|row=1|relative=true|col=0|view=0" & ASCII.LF &
         "src/canonical.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/canonical.adb|relative=true|relative=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "duplicate canonical metadata should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "open-file rows with duplicate or out-of-order canonical metadata must be rejected");
      Assert (Editor.Workspace_Persistence.Open_File (Snapshot, 1).Path =
                To_Unbounded_String ("src/canonical.adb"),
              "valid canonical open-file row should remain after duplicate rows are rejected");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "active-file row with duplicate relative metadata must not restore active state");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "duplicate or out-of-order canonical metadata should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Duplicate_Canonical_Metadata_Is_Rejected;



   procedure Test_Trailing_And_Empty_Metadata_Fields_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("empty_metadata_fields.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/trailing.adb|relative=true|row=1|col=1|view=1|" & ASCII.LF &
         "src/empty.adb||relative=true|row=1|col=1|view=1" & ASCII.LF &
         "src/canonical.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/canonical.adb|relative=true|" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "empty/trailing metadata fields should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "only canonical file rows without empty metadata separators should load");
      Assert (Editor.Workspace_Persistence.Open_File (Snapshot, 1).Path =
                To_Unbounded_String ("src/canonical.adb"),
              "canonical row should survive rejected empty metadata rows");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "active-file row with trailing metadata separator must be rejected");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "empty metadata fields should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Trailing_And_Empty_Metadata_Fields_Are_Rejected;

   procedure Test_Panel_Section_Requires_Canonical_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("panel_order.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/canonical.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-width=40" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=9" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "out-of-order panel rows should make load partial under the strict schema");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "valid structural open-file state should survive panel-row rejection");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "out-of-order panel rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Panel_Section_Requires_Canonical_Order;



   procedure Test_Sections_Require_Canonical_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("section_order.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "out-of-order workspace sections should make load partial under the strict schema");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 0,
              "out-of-order open-files section should not be accepted as structural state");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "active file should not survive when canonical section order is violated");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "out-of-order sections should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Sections_Require_Canonical_Order;


   procedure Test_Active_File_Section_Allows_At_Most_One_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("duplicate_active_file_rows.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/first.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "src/second.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/first.adb|relative=true" & ASCII.LF &
         "src/second.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "duplicate active-file rows should make load partial under the strict schema");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "the first canonical active-file row should remain usable");
      Assert (Editor.Workspace_Persistence.Active_File_Path (Snapshot) = "src/first.adb",
              "duplicate active-file rows must not overwrite the first canonical active file");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "duplicate active-file rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Active_File_Section_Allows_At_Most_One_Row;


   procedure Test_Invalid_Panel_Section_Does_Not_Partially_Restore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("invalid_panel_no_partial.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=false" & ASCII.LF &
         "file-tree-width=41" & ASCII.LF &
         "bottom-visible=true" & ASCII.LF &
         "bottom-height=13" & ASCII.LF &
         "unexpected-panel-payload=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "invalid panel section should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "valid structural file state should survive invalid panel section");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Visible (Snapshot),
              "invalid panel section must not partially restore file-tree visibility");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Width (Snapshot) = 28,
              "invalid panel section must not partially restore file-tree width");
      Assert (not Editor.Workspace_Persistence.Bottom_Panel_Visible (Snapshot),
              "invalid panel section must not partially restore bottom visibility");
      Assert (Editor.Workspace_Persistence.Bottom_Panel_Height (Snapshot) = 8,
              "invalid panel section must not partially restore bottom height");
      Assert (Editor.Workspace_Persistence.Active_Bottom_Content (Snapshot) =
                Editor.Workspace_Persistence.Workspace_Problems_Content,
              "invalid panel section must not partially restore bottom content");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "invalid panel section should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Invalid_Panel_Section_Does_Not_Partially_Restore;



   procedure Test_Canonical_Section_Set_Is_Required
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("missing_canonical_sections.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=0|col=0|view=0" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Snapshot, Status);

      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "missing canonical sections should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Snapshot) = 1,
              "valid structural rows before the truncated schema should remain available");
      Assert (Editor.Workspace_Persistence.Has_Active_File_Path (Snapshot),
              "valid active-file row should remain available when its open file exists");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Snapshot) loop
         if Editor.Workspace_Persistence.Diagnostic (Snapshot, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "missing canonical sections should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Canonical_Section_Set_Is_Required;


   procedure Test_Workspace_Path_Metacharacters_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("path_meta.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Invalid_Path : Boolean := False;
      Saved_Text : Unbounded_String;
   begin
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/main|bad.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 1,
          Cursor_Column       => 1,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/good.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 1,
          Cursor_Column       => 1,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main=bad.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path
        (Snapshot, "src/[generated]");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "save should normalize away paths that cannot round-trip through the strict schema");
      Saved_Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Saved_Text), "main|bad") = 0,
              "open-file path containing metadata separator should not be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Saved_Text), "main=bad") = 0,
              "active-file path containing key separator should not be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Saved_Text), "[generated]") = 0,
              "expanded path containing section delimiters should not be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Saved_Text), "src/good.adb") > 0,
              "valid structural path should still be saved");

      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main|bad.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "src/good.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/good.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src/[generated]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "metacharacter paths in persisted workspace rows should make load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "invalid metacharacter open-file path should be skipped while valid rows remain");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 0,
              "invalid metacharacter expanded path should be skipped");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Invalid_Path
         then
            Saw_Invalid_Path := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Path,
              "metacharacter paths should produce invalid-path diagnostics");

      Remove_If_Exists (Path);
   end Test_Workspace_Path_Metacharacters_Are_Rejected;



   procedure Test_Padded_Canonical_Lines_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("padded_lines.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         " src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "padded nonblank canonical rows should make strict-schema load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 0,
              "padded open-file row must not be trimmed into structural state");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "active file should be cleared because the padded open-file row was rejected");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "padded rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Padded_Canonical_Lines_Are_Rejected;






   procedure Test_Internal_Whitespace_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("internal_whitespace.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root= /tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb |relative=true|row=1|col=1|view=1" & ASCII.LF &
         "src/other.adb|relative= true|row=1|col=1|view=1" & ASCII.LF &
         "src/good.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/good.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width= 28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "internally padded canonical fields should make strict-schema load partial");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Loaded),
              "project-root value with internal schema padding should not be retained");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "only the exact canonical open-file row should be retained");
      Assert (Editor.Workspace_Persistence.Open_File (Loaded, 1).Path =
                To_Unbounded_String ("src/good.adb"),
              "internally padded open-file rows should be skipped");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Width (Loaded) = 28,
              "invalid padded panel section should fall back to default width");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "internally padded rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Internal_Whitespace_Is_Rejected;


   procedure Test_Blank_Lines_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("blank_lines.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         ASCII.LF &
         "src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "blank lines should make strict-schema load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "valid canonical open-file rows should still be retained");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 1,
              "valid canonical file-tree rows should still be retained");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "blank rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Blank_Lines_Are_Rejected;


   procedure Test_Header_Must_Be_First_Physical_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("header_first.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Write_Text
        (Path,
         ASCII.LF &
         "editor-workspace-version=1" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "blank row before header must invalidate strict workspace file");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 0,
              "pre-header malformed input must not retain later open-file state");

      Write_Text
        (Path,
         "[open-files]" & ASCII.LF &
         "editor-workspace-version=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "section before header must invalidate strict workspace file");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 0,
              "pre-header section must not retain later structural state");

      Remove_If_Exists (Path);
   end Test_Header_Must_Be_First_Physical_Line;


   procedure Test_Duplicate_Project_Root_Rows_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("duplicate_project_root.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=" & ASCII.LF &
         "project-root=/tmp/should-not-be-restored" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "duplicate project-root rows should make strict-schema load partial");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Loaded),
              "a later project-root row must not repair an earlier invalid duplicate");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "valid structural file state should still be retained");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "duplicate project-root rows should produce malformed-line diagnostics");

      Remove_If_Exists (Path);
   end Test_Duplicate_Project_Root_Rows_Are_Rejected;

   procedure Test_Unsupported_Root_Row_Blocks_Project_Root_Repair
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("root_row_repair.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
      Saw_Unsupported : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "workspace-name=old-session" & ASCII.LF &
         "project-root=/tmp/should-not-be-restored" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "unsupported root row plus later project-root should make load partial");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Loaded),
              "later project-root must not repair a noncanonical first root row");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "valid canonical file state after the root error should still be retained");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         elsif Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Unsupported_Key
         then
            Saw_Unsupported := True;
         end if;
      end loop;
      Assert (Saw_Unsupported,
              "the first noncanonical root row should be reported as unsupported");
      Assert (Saw_Malformed,
              "the later project-root row should be reported as malformed duplicate root state");

      Remove_If_Exists (Path);
   end Test_Unsupported_Root_Row_Blocks_Project_Root_Repair;


   procedure Test_Relative_False_File_Rows_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("relative_false.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=false|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=false" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "relative=false file rows should make strict workspace load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 0,
              "open-file row with relative=false must not be retained");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "active-file row with relative=false must not be retained");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "relative=false should be reported as malformed strict-schema file metadata");

      Remove_If_Exists (Path);
   end Test_Relative_False_File_Rows_Are_Rejected;


   procedure Test_Programmatic_Padded_Structural_Paths_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("programmatic_padded_paths.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Text     : Unbounded_String;
   begin
      Remove_If_Exists (Path);

      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, " /tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String (" src/main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 1,
          Cursor_Column       => 1,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/ok.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 2,
          Cursor_Column       => 3,
          View_First_Row      => 4));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/ok.adb ", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Snapshot, " src");
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Snapshot, "src");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "save should normalize invalid programmatic structural paths away");

      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "project-root=") = 0,
              "padded project root must not be trimmed into retained workspace state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src/ok.adb|relative=true|row=2|col=3|view=4") > 0,
              "valid open file should still be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), " src/main.adb") = 0,
              "padded open-file path must not be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "[active-file]" & ASCII.LF & "src/ok.adb") = 0,
              "padded active-file path must not be trimmed and saved");

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "saved normalized strict-schema file should reload cleanly");
      Assert (not Editor.Workspace_Persistence.Has_Project_Root (Loaded),
              "invalid padded project root should stay absent after reload");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "only the valid open file should survive save/load");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "padded active path should not be retained or repaired");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 1,
              "only the valid expanded path should survive save/load");

      Remove_If_Exists (Path);
   end Test_Programmatic_Padded_Structural_Paths_Are_Rejected;


   procedure Test_Leading_Zero_Numbers_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("leading_zero_numbers.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Invalid_Number : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=01|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=028" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=08" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "leading-zero numeric fields should make strict workspace load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 0,
              "open-file row with noncanonical row number must not be retained");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "active file should be dropped when its open-file row is rejected");
      Assert (Editor.Workspace_Persistence.File_Tree_Panel_Width (Loaded) = 28,
              "invalid panel width should fall back to the structural default");
      Assert (Editor.Workspace_Persistence.Bottom_Panel_Height (Loaded) = 8,
              "invalid panel height should fall back to the structural default");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Invalid_Number
         then
            Saw_Invalid_Number := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Number,
              "leading-zero numeric fields should be reported as invalid numbers");

      Write_Text
        (Path,
         "editor-workspace-version=01" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Invalid_Format,
              "leading-zero workspace version must not be accepted as canonical version 1");

      Remove_If_Exists (Path);
   end Test_Leading_Zero_Numbers_Are_Rejected;


   procedure Test_File_Tree_Expanded_Paths_Require_Canonical_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("expanded_order.session");
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Saw_Malformed : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src/main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src/main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src/z" & ASCII.LF &
         "src/a" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "out-of-order expanded paths should make strict workspace load partial");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 1,
              "descending expanded path row must not be retained");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path (Loaded, 1) = "src/z",
              "valid first expanded path should remain available");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Malformed_Line
         then
            Saw_Malformed := True;
         end if;
      end loop;
      Assert (Saw_Malformed,
              "descending expanded path rows should be reported as malformed strict-schema input");

      Remove_If_Exists (Path);
   end Test_File_Tree_Expanded_Paths_Require_Canonical_Order;


   procedure Test_Backslash_Paths_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("backslash_paths.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Text     : Unbounded_String;
      Saw_Invalid_Path : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src\main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "src/ok.adb|relative=true|row=2|col=3|view=4" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src\main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src\tree" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "backslash project-relative paths should make strict workspace load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "backslash open-file row must not be retained");
      Assert (Editor.Workspace_Persistence.Open_File (Loaded, 1).Path = To_Unbounded_String ("src/ok.adb"),
              "valid slash-separated open-file row should remain available");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "backslash active file should not be normalized into a retained active path");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 0,
              "backslash expanded path should not be normalized into retained file-tree state");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Invalid_Path
         then
            Saw_Invalid_Path := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Path,
              "backslash path rows should be reported as invalid strict-schema paths");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src\main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 1,
          Cursor_Column       => 1,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/ok.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 2,
          Cursor_Column       => 3,
          View_First_Row      => 4));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src\main.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path
        (Snapshot, "src\tree");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "save should drop noncanonical backslash structural paths");
      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src\main.adb") = 0,
              "backslash open/active paths must not be normalized or saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src/ok.adb|relative=true|row=2|col=3|view=4") > 0,
              "valid slash-separated open path should still be saved");

      Remove_If_Exists (Path);
   end Test_Backslash_Paths_Are_Rejected;


   procedure Test_Redundant_Slash_Paths_Are_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("redundant_slash_paths.session");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded   : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Text     : Unbounded_String;
      Saw_Invalid_Path : Boolean := False;
   begin
      Write_Text
        (Path,
         "editor-workspace-version=1" & ASCII.LF &
         "project-root=/tmp/project" & ASCII.LF &
         "[open-files]" & ASCII.LF &
         "src//main.adb|relative=true|row=1|col=1|view=1" & ASCII.LF &
         "src/ok.adb|relative=true|row=2|col=3|view=4" & ASCII.LF &
         "[active-file]" & ASCII.LF &
         "src//main.adb|relative=true" & ASCII.LF &
         "[file-tree-expanded]" & ASCII.LF &
         "src/" & ASCII.LF &
         "[panels]" & ASCII.LF &
         "file-tree-visible=true" & ASCII.LF &
         "file-tree-width=28" & ASCII.LF &
         "bottom-visible=false" & ASCII.LF &
         "bottom-height=8" & ASCII.LF &
         "bottom-content=problems" & ASCII.LF);

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Partial_Restore,
              "redundant slash paths should make strict workspace load partial");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "redundant-slash open-file row must not be retained");
      Assert (Editor.Workspace_Persistence.Open_File (Loaded, 1).Path = To_Unbounded_String ("src/ok.adb"),
              "valid slash-separated open-file row should remain available");
      Assert (not Editor.Workspace_Persistence.Has_Active_File_Path (Loaded),
              "redundant-slash active file should not be normalized into retained active state");
      Assert (Editor.Workspace_Persistence.Expanded_File_Tree_Path_Count (Loaded) = 0,
              "trailing-slash expanded path should not be normalized into retained file-tree state");

      for I in 1 .. Editor.Workspace_Persistence.Diagnostic_Count (Loaded) loop
         if Editor.Workspace_Persistence.Diagnostic (Loaded, I).Kind =
              Editor.Workspace_Persistence.Invalid_Path
         then
            Saw_Invalid_Path := True;
         end if;
      end loop;
      Assert (Saw_Invalid_Path,
              "redundant slash path rows should be reported as invalid strict-schema paths");

      Editor.Workspace_Persistence.Clear (Snapshot);
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src//main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 1,
          Cursor_Column       => 1,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/ok.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 2,
          Cursor_Column       => 3,
          View_First_Row      => 4));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src//main.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path
        (Snapshot, "src/");

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "save should drop redundant-slash structural paths");
      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src//main.adb") = 0,
              "redundant-slash open/active paths must not be normalized or saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src/ok.adb|relative=true|row=2|col=3|view=4") > 0,
              "valid canonical open path should still be saved");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "src/" & ASCII.LF & "[panels]") = 0,
              "trailing-slash expanded path must not be normalized or saved");

      Remove_If_Exists (Path);
   end Test_Redundant_Slash_Paths_Are_Rejected;



   procedure Test_Lifecycle_Config_Defaults
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Editor.Workspace_Persistence.Workspace_Lifecycle_Config :=
        Editor.Workspace_Persistence.Default_Workspace_Lifecycle_Config;
   begin
      Assert (not Config.Auto_Restore_On_Project_Open,
              "default policy must keep project-open restore explicit");
      Assert (Config.Report_Available_Session_On_Project_Open,
              "default policy should report available workspace state");
      Assert (not Config.Save_On_Project_Close,
              "default policy must not save workspace state on close");
   end Test_Lifecycle_Config_Defaults;

   procedure Test_Session_File_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("status_root");
      Session  : constant String :=
        Editor.Workspace_Persistence.Session_File_Path (Root);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_Tree_If_Exists (Root);
      Assert
        (Editor.Workspace_Persistence.Session_File_Status (Root) =
           Editor.Workspace_Persistence.Session_File_Missing,
         "missing project session should report Session_File_Missing");
      Assert
        (not Editor.Workspace_Persistence.Workspace_State_Exists (Root),
         "missing project session should not be offered as available");

      Ada.Directories.Create_Path (Root);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, Root);
      Editor.Workspace_Persistence.Save_To_File (Snapshot, Session, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "test setup should create a workspace session file");
      Assert
        (Editor.Workspace_Persistence.Session_File_Status (Root) =
           Editor.Workspace_Persistence.Session_File_Present,
         "saved project session should report Session_File_Present");
      Assert
        (Editor.Workspace_Persistence.Workspace_State_Exists (Root),
         "saved project session should be cheaply available");

      Remove_Tree_If_Exists (Root);
   end Test_Session_File_Status;


   procedure Test_Workspace_Serializer_Audit_Is_Safe
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Audit    : Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit;
      Text     : Unbounded_String;
   begin
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 4,
          Cursor_Column       => 2,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", True);

      Text := To_Unbounded_String
        (Editor.Workspace_Persistence.Serialized_Text (Snapshot));
      Audit := Editor.Workspace_Persistence.Audit_Buffer_Persistence (Snapshot);

      Assert (Audit.Safe,
              "canonical serialized workspace should pass buffer persistence audit");
      Assert (not Audit.Runtime_Buffer_Id_Persisted,
              "serialized workspace must not contain runtime buffer ids");
      Assert (not Audit.Active_Buffer_Id_Persisted,
              "serialized workspace must not contain active runtime buffer ids");
      Assert (not Audit.Selected_Buffer_Id_Persisted,
              "serialized workspace must not contain selected runtime buffer ids");
      Assert (not Audit.Buffer_List_State_Persisted,
              "serialized workspace must not contain Buffer List selection/filter state");
      Assert (not Audit.Dirty_Text_Persisted,
              "serialized workspace must not contain dirty buffer text");
      Assert (not Audit.Scratch_Text_Persisted,
              "serialized workspace must not contain scratch buffer text");
      Assert (not Audit.Conflict_Token_Persisted,
              "serialized workspace must not contain file conflict tokens");
      Assert (not Audit.Close_Prompt_State_Persisted,
              "serialized workspace must not contain close/conflict prompt state");
      Assert (not Audit.Undo_Redo_Clipboard_Persisted,
              "serialized workspace must not contain undo/redo/clipboard state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "[open-files]") > 0,
              "serialized workspace audit should inspect actual workspace text");
   end Test_Workspace_Serializer_Audit_Is_Safe;


   procedure Test_Workspace_Serializer_Audit_Detects_Leaks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Text  : constant String :=
        "editor-workspace-version=1" & ASCII.LF
        & "[open-files]" & ASCII.LF
        & "src/main.adb|relative=true|row=0|col=0|view=0|runtime-buffer-id=42" & ASCII.LF
        & "[active-file]" & ASCII.LF
        & "src/main.adb|relative=true|active-buffer-id=42" & ASCII.LF
        & "[file-tree-expanded]" & ASCII.LF
        & "[panels]" & ASCII.LF
        & "buffer-list-selection=42" & ASCII.LF
        & "dirty-text=unsaved" & ASCII.LF
        & "scratch-text=temporary" & ASCII.LF
        & "file-conflict-token=abc" & ASCII.LF
        & "close-prompt=pending" & ASCII.LF
        & "undo-stack=opaque" & ASCII.LF;
      Audit : constant Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit :=
        Editor.Workspace_Persistence.Audit_Serialized_Buffer_Persistence (Text);
   begin
      Assert (not Audit.Safe,
              "serializer audit should reject forbidden buffer persistence fields");
      Assert (Audit.Runtime_Buffer_Id_Persisted,
              "serializer audit should detect runtime buffer ids");
      Assert (Audit.Active_Buffer_Id_Persisted,
              "serializer audit should detect active runtime buffer ids");
      Assert (Audit.Buffer_List_State_Persisted,
              "serializer audit should detect Buffer List state");
      Assert (Audit.Dirty_Text_Persisted,
              "serializer audit should detect dirty text");
      Assert (Audit.Scratch_Text_Persisted,
              "serializer audit should detect scratch text");
      Assert (Audit.Conflict_Token_Persisted,
              "serializer audit should detect conflict tokens");
      Assert (Audit.Close_Prompt_State_Persisted,
              "serializer audit should detect close prompt state");
      Assert (Audit.Undo_Redo_Clipboard_Persisted,
              "serializer audit should detect undo/redo/clipboard state");
   end Test_Workspace_Serializer_Audit_Detects_Leaks;



   procedure Test_Workspace_Serializer_Audit_Is_Structural
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Safe_Text : constant String :=
        "editor-workspace-version=1" & ASCII.LF
        & "project-root=/tmp/project" & ASCII.LF
        & "[open-files]" & ASCII.LF
        & "src/runtime_buffer_id_notes.adb|relative=true|row=0|col=0|view=0" & ASCII.LF
        & "[active-file]" & ASCII.LF
        & "src/runtime_buffer_id_notes.adb|relative=true" & ASCII.LF
        & "[file-tree-expanded]" & ASCII.LF
        & "docs/selected_buffer_id_notes" & ASCII.LF
        & "[panels]" & ASCII.LF
        & "file-tree-visible=true" & ASCII.LF
        & "file-tree-width=28" & ASCII.LF
        & "bottom-visible=false" & ASCII.LF
        & "bottom-height=8" & ASCII.LF
        & "bottom-content=problems" & ASCII.LF;
      Unsafe_Text : constant String :=
        "editor-workspace-version=1" & ASCII.LF
        & "[open-files]" & ASCII.LF
        & "src/main.adb|relative=true|row=0|col=0|view=0|selected_buffer_id=42" & ASCII.LF
        & "[active-file]" & ASCII.LF
        & "src/main.adb|relative=true|observed_file_token=abc" & ASCII.LF
        & "[file-tree-expanded]" & ASCII.LF
        & "docs/readme.md|runtime_buffer_id=9" & ASCII.LF
        & "[panels]" & ASCII.LF
        & "selected-row=1" & ASCII.LF
        & "clipboard=text" & ASCII.LF;
      Safe_Audit : constant Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit :=
        Editor.Workspace_Persistence.Audit_Serialized_Buffer_Persistence (Safe_Text);
      Unsafe_Audit : constant Editor.Workspace_Persistence.Workspace_Buffer_Persistence_Audit :=
        Editor.Workspace_Persistence.Audit_Serialized_Buffer_Persistence (Unsafe_Text);
   begin
      Assert (Safe_Audit.Safe,
              "structural audit must not reject forbidden words inside path values");
      Assert (not Safe_Audit.Runtime_Buffer_Id_Persisted,
              "path value containing runtime_buffer_id must not be treated as persisted field");
      Assert (not Safe_Audit.Selected_Buffer_Id_Persisted,
              "path value containing selected_buffer_id must not be treated as persisted field");

      Assert (not Unsafe_Audit.Safe,
              "structural audit must reject forbidden field names in serialized workspace metadata");
      Assert (Unsafe_Audit.Selected_Buffer_Id_Persisted,
              "structural audit should detect selected buffer id metadata field");
      Assert (Unsafe_Audit.Conflict_Token_Persisted,
              "structural audit should detect observed file token metadata field");
      Assert (Unsafe_Audit.Runtime_Buffer_Id_Persisted,
              "structural audit should detect runtime buffer id metadata field");
      Assert (Unsafe_Audit.Buffer_List_State_Persisted,
              "structural audit should detect Buffer List selected-row state");
      Assert (Unsafe_Audit.Undo_Redo_Clipboard_Persisted,
              "structural audit should detect clipboard state field");
   end Test_Workspace_Serializer_Audit_Is_Structural;


   procedure Test_Serialized_Text_Matches_File_Save
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path     : constant String := Temp_Path ("serializer_audit.txt");
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status   : Editor.Workspace_Persistence.Workspace_Persistence_Status;
   begin
      Remove_If_Exists (Path);
      Editor.Workspace_Persistence.Set_Project_Root (Snapshot, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Snapshot,
         (Path                => To_Unbounded_String ("src/main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 7,
          Cursor_Column       => 3,
          View_First_Row      => 2));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Snapshot, "src/main.adb", True);
      Editor.Workspace_Persistence.Set_File_Tree_Panel
        (Snapshot, True, 31);

      Editor.Workspace_Persistence.Save_To_File (Snapshot, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "workspace save should succeed for serializer audit fixture");
      Assert (Read_Text (Path) & ASCII.LF =
                Editor.Workspace_Persistence.Serialized_Text (Snapshot),
              "serializer audit must inspect the same canonical text emitted by save");
      Remove_If_Exists (Path);
   end Test_Serialized_Text_Matches_File_Save;

   procedure Test_Restore_Audit_And_Details_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Before : Editor.Workspace_Persistence.Workspace_Snapshot;
      After  : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : constant Editor.Workspace_Persistence.Workspace_Restore_Summary :=
        (Files_Requested      => 1,
         Files_Restored       => 1,
         Files_Skipped        => 0,
         Expansions_Requested => 1,
         Expansions_Restored  => 1,
         Expansions_Skipped   => 0,
         Panel_Values_Clamped => 0);
      Audit : Editor.Workspace_Persistence.Workspace_Restore_Audit;
   begin
      Editor.Workspace_Persistence.Set_Project_Root (Before, "/tmp/project");
      Editor.Workspace_Persistence.Add_Open_File
        (Before,
         (Path                => To_Unbounded_String ("src/main.adb"),
          Is_Project_Relative => True,
          Cursor_Row          => 4,
          Cursor_Column       => 2,
          View_First_Row      => 1));
      Editor.Workspace_Persistence.Set_Active_File_Path
        (Before, "src/main.adb", True);
      Editor.Workspace_Persistence.Add_Expanded_File_Tree_Path (Before, "src");
      Editor.Workspace_Persistence.Set_Recent_Project_Path
        (Before, "/tmp/project");
      Editor.Workspace_Persistence.Set_Quick_Open_Path_Scope (Before, "src");
      Editor.Workspace_Persistence.Set_Quick_Open_File_Kind_Filter
        (Before,
         Editor.Workspace_Persistence.Workspace_Quick_Open_Ada_Files);
      Editor.Workspace_Persistence.Set_Feature_Panel
        (Before, True,
         Editor.Workspace_Persistence.Workspace_Diagnostics_Feature);

      After := Before;
      Audit := Editor.Workspace_Persistence.Audit_Restore_Roundtrip
        (Before, After, Summary);

      Assert (Audit.Snapshots_Equivalent,
              "restore audit should compare normalized structural snapshots");
      Assert (Audit.Runtime_State_Excluded,
              "restore audit should reuse the runtime-leak persistence audit");
      Assert (Audit.Restore_Counts_Coherent,
              "restore audit should validate restored/skipped counts");
      Assert (Audit.Continuity_State_Restored,
              "restore audit should include Quick Open and feature-panel continuity");
      Assert (Audit.Safe,
              "restore audit should summarize all restore safety checks");
      Assert
        (Editor.Workspace_Persistence.Restore_Details_Label (Summary) =
         "restore details: files 1/1, skipped files 0, expanded paths 1/1, skipped expanded paths 0, clamped panels 0",
         "restore details should expose restored and skipped counts");
   end Test_Restore_Audit_And_Details_Label;


   procedure Register_Tests
     (T : in out Workspace_Persistence_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Snapshot_Defaults_And_Clear'Access,
         "workspace snapshot defaults and clear semantics");
      Register_Routine
        (T, Test_Save_Load_Roundtrip'Access,
         "workspace persistence save/load roundtrip");
      Register_Routine
        (T, Test_Load_Error_Statuses'Access,
         "workspace persistence load error statuses");
      Register_Routine
        (T, Test_Malformed_Optional_Entry_Is_Partial'Access,
         "malformed optional entries produce partial restore status");
      Register_Routine
        (T, Test_Path_Safety_And_Normalization'Access,
         "workspace path safety and normalization");
      Register_Routine
        (T, Test_Normalize_Equivalent_And_Deterministic_Save'Access,
         "normalized equivalence and deterministic serialization");
      Register_Routine
        (T, Test_Atomic_Save_Overwrites_And_Cleans_Temp'Access,
         "atomic save overwrite and temp cleanup");
      Register_Routine
        (T, Test_Corrupt_And_Unsafe_Input_Diagnostics'Access,
         "corrupt and unsafe input diagnostics");
      Register_Routine
        (T, Test_Save_To_File_Uses_Safe_Session_Path'Access,
         "session path policy and atomic save");
      Register_Routine
        (T, Test_Duplicate_And_Sorted_Path_Load_Save'Access,
         "duplicate path diagnostics and sorted expansions");
      Register_Routine
        (T, Test_Empty_File_Invalid_With_Diagnostic'Access,
         "empty workspace file diagnostic");
      Register_Routine
        (T, Test_Status_State_Is_Not_Persisted'Access,
         "status state is not persisted");
      Register_Routine
        (T, Test_Active_File_Must_Belong_To_Open_Files'Access,
         "active file must belong to open files");
      Register_Routine
        (T, Test_Invalid_Project_Root_Is_Diagnostic_Only'Access,
         "invalid project root is diagnostic-only");
      Register_Routine
        (T, Test_Zero_Panel_Dimensions_Are_Diagnostic_Only'Access,
         "zero panel dimensions are diagnostic-only");
      Register_Routine
        (T, Test_Path_Only_File_Rows_Are_Rejected'Access,
         "rejects path-only file rows under strict schema");
      Register_Routine
        (T, Test_File_Rows_Require_Full_Canonical_Metadata'Access,
         "requires full canonical file row metadata");
      Register_Routine
        (T, Test_Duplicate_Canonical_Metadata_Is_Rejected'Access,
         "rejects duplicate or out-of-order canonical metadata");
      Register_Routine
        (T, Test_Trailing_And_Empty_Metadata_Fields_Are_Rejected'Access,
         "rejects empty metadata fields in canonical rows");
      Register_Routine
        (T, Test_Panel_Section_Requires_Canonical_Order'Access,
         "requires canonical panel row order");
      Register_Routine
        (T, Test_Sections_Require_Canonical_Order'Access,
         "requires canonical section order");
      Register_Routine
        (T, Test_Active_File_Section_Allows_At_Most_One_Row'Access,
         "active-file section allows at most one row");
      Register_Routine
        (T, Test_Invalid_Panel_Section_Does_Not_Partially_Restore'Access,
         "invalid panel section does not partially restore layout");
      Register_Routine
        (T, Test_Canonical_Section_Set_Is_Required'Access,
         "requires complete canonical section set");
      Register_Routine
        (T, Test_Workspace_Path_Metacharacters_Are_Rejected'Access,
         "rejects paths that cannot round-trip through strict schema");
      Register_Routine
        (T, Test_Padded_Canonical_Lines_Are_Rejected'Access,
         "rejects padded canonical rows under strict schema");
      Register_Routine
        (T, Test_Internal_Whitespace_Is_Rejected'Access,
         "rejects internally padded canonical fields");
      Register_Routine
        (T, Test_Blank_Lines_Are_Rejected'Access,
         "rejects blank lines under strict schema");
      Register_Routine
        (T, Test_Header_Must_Be_First_Physical_Line'Access,
         "requires version header as first physical line");
      Register_Routine
        (T, Test_Duplicate_Project_Root_Rows_Are_Rejected'Access,
         "rejects duplicate project-root rows under strict schema");
      Register_Routine
        (T, Test_Unsupported_Root_Row_Blocks_Project_Root_Repair'Access,
         "rejects root-row repair after unsupported root state");
      Register_Routine
        (T, Test_Relative_False_File_Rows_Are_Rejected'Access,
         "rejects relative=false file rows under strict schema");
      Register_Routine
        (T, Test_Programmatic_Padded_Structural_Paths_Are_Rejected'Access,
         "rejects padded programmatic structural paths");
      Register_Routine
        (T, Test_Leading_Zero_Numbers_Are_Rejected'Access,
         "rejects leading-zero numeric fields");
      Register_Routine
        (T, Test_File_Tree_Expanded_Paths_Require_Canonical_Order'Access,
         "requires canonical ordering for file-tree expanded paths");
      Register_Routine
        (T, Test_Backslash_Paths_Are_Rejected'Access,
         "rejects backslash paths under strict schema");
      Register_Routine
        (T, Test_Redundant_Slash_Paths_Are_Rejected'Access,
         "rejects redundant slash paths under strict schema");
      Register_Routine
        (T, Test_Lifecycle_Config_Defaults'Access,
         "workspace lifecycle config defaults");
      Register_Routine
        (T, Test_Session_File_Status'Access,
         "cheap session file status detection");
      Register_Routine
        (T, Test_Workspace_Serializer_Audit_Is_Safe'Access,
         "workspace serializer audit accepts canonical structural persistence");
      Register_Routine
        (T, Test_Workspace_Serializer_Audit_Detects_Leaks'Access,
         "workspace serializer audit detects forbidden buffer persistence fields");
      Register_Routine
        (T, Test_Workspace_Serializer_Audit_Is_Structural'Access,
         "workspace serializer audit is structural and field-name based");
      Register_Routine
        (T, Test_Serialized_Text_Matches_File_Save'Access,
         "serialized text matches actual workspace save output");
      Register_Routine
        (T, Test_Restore_Audit_And_Details_Label'Access,
         "restore audit and details label");
   end Register_Tests;

end Editor.Workspace_Persistence.Tests;
