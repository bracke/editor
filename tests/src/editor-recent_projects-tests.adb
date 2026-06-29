with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Editor.Recent_Projects;
with Editor.Buffer_Switcher;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Project;
with Editor.State;

package body Editor.Recent_Projects.Tests is

   use type Editor.Recent_Projects.Recent_Project_Status;
   use type Ada.Directories.File_Kind;

   function Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Code,
         Modifiers => (Ctrl => False, Shift => False,
                       Alt => False, Meta => False));
   end Key;

   function Name
     (T : Recent_Projects_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Recent_Projects.Tests");
   end Name;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "phase92_" & Name);
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
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
   end Remove_If_Exists;

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

   procedure Test_Empty_And_Add_Promote
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      List : Editor.Recent_Projects.Recent_Project_List;
      Item : Editor.Recent_Projects.Recent_Project_Entry;
   begin
      Assert (Editor.Recent_Projects.Count (List) = 0,
              "new recent-project list must be empty");

      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/editor", "editor", 10);
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "Add_Or_Promote must add an entry");
      Item := Editor.Recent_Projects.Item (List, 1);
      Assert (To_String (Item.Display_Name) = "editor",
              "Add_Or_Promote must store the display name");

      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/database", "database", 20);
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/editor", "editor2", 30);
      Assert (Editor.Recent_Projects.Count (List) = 2,
              "promoting an existing project must not duplicate it");
      Item := Editor.Recent_Projects.Item (List, 1);
      Assert (To_String (Item.Display_Name) = "editor2" and then Item.Last_Opened_Ms = 30,
              "promoting an existing project must move it to top and update metadata");
   end Test_Empty_And_Add_Promote;

   procedure Test_Max_Remove_And_Normalize
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      List : Editor.Recent_Projects.Recent_Project_List;
      Config : constant Editor.Recent_Projects.Recent_Project_Config :=
        (Max_Entries => 2);
   begin
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/a", "a", 1, Config);
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/b", "b", 2, Config);
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/c", "c", 3, Config);
      Assert (Editor.Recent_Projects.Count (List) = 2,
              "Max_Entries must cap the recent-project list");
      Assert (To_String (Editor.Recent_Projects.Item (List, 1).Display_Name) = "c",
              "newest entry must be first after cap normalization");

      Editor.Recent_Projects.Remove (List, "/tmp/c/");
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "Remove must delete a matching normalized path");
      Editor.Recent_Projects.Remove (List, "/tmp/missing");
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "Remove of a missing path must be a no-op");
   end Test_Max_Remove_And_Normalize;

   procedure Test_Save_Load_Roundtrip
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := Temp_Path ("recent-projects.txt");
      List : Editor.Recent_Projects.Recent_Project_List;
      Loaded : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
      Text : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/editor", "editor", 123);
      Editor.Recent_Projects.Add_Or_Promote (List, "/tmp/database", "database", 124);
      Editor.Recent_Projects.Save_To_File (List, Path, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "Save_To_File must succeed for a writable path");

      Text := To_Unbounded_String (Read_Text (Path));
      Assert (To_String (Text)'Length > 0,
              "Save_To_File must write non-empty deterministic text");
      Assert (To_String (Text) (To_String (Text)'First .. To_String (Text)'First + 31) =
                "editor-recent-projects-version=1",
              "Save_To_File must write the version header first");

      Editor.Recent_Projects.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "Load_From_File must load saved recent projects");
      Assert (Editor.Recent_Projects.Count (Loaded) = 2,
              "roundtrip must preserve entry count");
      Assert (To_String (Editor.Recent_Projects.Item (Loaded, 1).Display_Name) = "database",
              "serialization order must remain most-recent first");
      Remove_If_Exists (Path);
   end Test_Save_Load_Roundtrip;

   procedure Test_Load_Error_Statuses_And_Skip_Malformed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant String := Temp_Path ("missing-recent-projects.txt");
      Invalid : constant String := Temp_Path ("invalid-recent-projects.txt");
      Malformed : constant String := Temp_Path ("malformed-recent-projects.txt");
      List : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Remove_If_Exists (Missing);
      Editor.Recent_Projects.Load_From_File (Missing, List, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Not_Found,
              "missing recent-projects file must return Not_Found");

      Write_Text (Invalid, "editor-recent-projects-version=99" & ASCII.LF);
      Editor.Recent_Projects.Load_From_File (Invalid, List, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Invalid_Format,
              "unsupported recent-projects version must return Invalid_Format");

      Write_Text
        (Malformed,
         "editor-recent-projects-version=1" & ASCII.LF &
         "[projects]" & ASCII.LF &
         "not a valid entry" & ASCII.LF &
         "/tmp/editor|name=editor|opened=44" & ASCII.LF);
      Editor.Recent_Projects.Load_From_File (Malformed, List, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Partial_Load,
              "malformed project entries must be skipped and reported as partial recovery");
      Assert (Editor.Recent_Projects.Last_Load_Ignored_Count = 1,
              "malformed project entries must be counted for recovery summaries");
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "load must retain valid entries around malformed entries");
      Remove_If_Exists (Invalid);
      Remove_If_Exists (Malformed);
   end Test_Load_Error_Statuses_And_Skip_Malformed;


   procedure Test_Phase213_Recent_Projects_Persistence_Domain
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("phase213-recent-projects.txt");
      List   : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
      Text   : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.Recent_Projects.Add_Or_Promote
        (List, "/tmp/editor", "editor", 213);
      Editor.Recent_Projects.Save_To_File (List, Path, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "recent projects save should succeed for writable path");

      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "[open-files]") = 0,
              "recent projects persistence must exclude workspace open files");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "project-root=") = 0,
              "recent projects persistence must exclude workspace project root field");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "theme=") = 0,
              "recent projects persistence must exclude settings fields");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "key=") = 0,
              "recent projects persistence must exclude keybinding fields");

      Remove_If_Exists (Path);
   end Test_Phase213_Recent_Projects_Persistence_Domain;


   procedure Test_Phase576_Recent_Projects_Save_Excludes_Buffer_List_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("phase576-recent-projects-exclude-buffer-list.txt");
      S      : Editor.State.State_Type;
      Status : Editor.Recent_Projects.Recent_Project_Status;
      Text   : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.State.Init (S);

      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/editor-phase576-project", "editor-phase576", 576);

      --  Phase 576: Recent Projects persistence owns only project recency
      --  entries.  It must not serialize any transient Buffer List state even
      --  when that UI state is live in the editor state at save time.
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text
        (S.Buffer_Switcher, "phase576-recent-buffer-list-query-must-not-persist");
      Editor.Buffer_Switcher.Set_Outside_Project_Filter (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Sort_Mode
        (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);

      Editor.Recent_Projects.Save_To_File (S.Recent_Projects, Path, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "recent projects save should succeed with Buffer List runtime state present");

      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text),
                "editor-recent-projects-version=1") > 0,
              "recent projects save must still write the recent-projects header");
      Assert (Ada.Strings.Fixed.Index (To_String (Text),
                "phase576-recent-buffer-list-query-must-not-persist") = 0,
              "recent projects save must exclude Buffer List query/filter text");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "buffer-list") = 0,
              "recent projects save must exclude Buffer List runtime fields");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "buffer-switcher") = 0,
              "recent projects save must exclude removed Buffer Switcher runtime fields");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "selected-row") = 0,
              "recent projects save must exclude Buffer List selection state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "runtime-buffer") = 0,
              "recent projects save must exclude runtime buffer identifiers");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "outside-project-filter") = 0,
              "recent projects save must exclude Buffer List state-filter selection");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "name-sort") = 0,
              "recent projects save must exclude Buffer List sort mode");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "marked-review") = 0,
              "recent projects save must exclude Buffer List review/mark state");

      Remove_If_Exists (Path);
   end Test_Phase576_Recent_Projects_Save_Excludes_Buffer_List_Runtime_State;

   procedure Test_Phase559_Missing_Availability_And_Remove_Missing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Existing : constant String := Temp_Path ("phase559-existing-project");
      Missing  : constant String := Temp_Path ("phase559-missing-project");
      List     : Editor.Recent_Projects.Recent_Project_List;
      Removed  : Natural := 0;
   begin
      Remove_If_Exists (Existing);
      Remove_If_Exists (Missing);
      Ada.Directories.Create_Path (Existing);

      Editor.Recent_Projects.Add_Or_Promote (List, Existing, "existing", 559);
      Editor.Recent_Projects.Add_Or_Promote (List, Missing, "missing", 560);
      Editor.Recent_Projects.Refresh_Availability (List);

      Assert (not Editor.Recent_Projects.Is_Available
                (Editor.Recent_Projects.Item (List, 1)),
              "missing recent project must be marked unavailable after safe check");
      Assert (Editor.Recent_Projects.Unavailable_Label
                (Editor.Recent_Projects.Item (List, 1)) =
              "project path no longer exists",
              "missing recent project must expose a display-only unavailable label");
      Assert (Editor.Recent_Projects.Is_Available
                (Editor.Recent_Projects.Item (List, 2)),
              "existing recent project must remain available");
      Assert (Editor.Recent_Projects.Available_Count (List) = 1
              and then Editor.Recent_Projects.Unavailable_Count (List) = 1,
              "Recent Projects snapshot must expose display-only available and unavailable counts");

      Removed := Editor.Recent_Projects.Remove_Missing (List);
      Assert (Removed = 1,
              "Remove_Missing must remove only known unavailable recent entries");
      Assert (Editor.Recent_Projects.Count (List) = 1
              and then To_String
                (Editor.Recent_Projects.Item (List, 1).Display_Name) = "existing",
              "Remove_Missing must preserve available entries");

      Remove_If_Exists (Existing);
   end Test_Phase559_Missing_Availability_And_Remove_Missing;

   procedure Test_Phase559_Recent_Entry_Remains_Lightweight
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("phase559-lightweight-recent.txt");
      List   : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
      Text   : Unbounded_String;
   begin
      Remove_If_Exists (Path);
      Editor.Recent_Projects.Add_Or_Promote
        (List, "/tmp/editor-phase559", "editor-phase559", 559);
      Editor.Recent_Projects.Save_To_File (List, Path, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "recent projects save must succeed for lightweight entries");

      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "open-file") = 0,
              "recent project entries must not persist open files");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "workspace") = 0,
              "recent project entries must not persist workspace session state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "build") = 0,
              "recent project entries must not persist Build state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "diagnostic") = 0,
              "recent project entries must not persist Diagnostics state");
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "dirty") = 0,
              "recent project entries must not persist dirty buffer state");

      Remove_If_Exists (Path);
   end Test_Phase559_Recent_Entry_Remains_Lightweight;


   procedure Test_Phase559_Deduplicate_Load_Keeps_Newest
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("phase559-duplicate-recent.txt");
      Root   : constant String := Temp_Path ("phase559-duplicate-root");
      List   : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
   begin
      Remove_If_Exists (Path);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Path (Root);
      Write_Text
        (Path,
         "editor-recent-projects-version=1" & ASCII.LF &
         "[projects]" & ASCII.LF &
         Root & "|name=old|opened=10" & ASCII.LF &
         Root & "|name=new|opened=99" & ASCII.LF);

      Editor.Recent_Projects.Load_From_File (Path, List, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "duplicate recent roots must not make the file invalid");
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "canonical duplicate recent roots must collapse to one entry");
      Assert (To_String (Editor.Recent_Projects.Item (List, 1).Display_Name) = "new"
              and then Editor.Recent_Projects.Item (List, 1).Last_Opened_Ms = 99,
              "duplicate recent roots must keep the newest ordering marker");

      Remove_If_Exists (Path);
      Remove_If_Exists (Root);
   end Test_Phase559_Deduplicate_Load_Keeps_Newest;

   procedure Test_Phase559_File_Path_Is_Unavailable_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      File_Path : constant String := Temp_Path ("phase559-not-a-directory.gpr");
      List      : Editor.Recent_Projects.Recent_Project_List;
   begin
      Remove_If_Exists (File_Path);
      Write_Text (File_Path, "project marker" & ASCII.LF);

      Editor.Recent_Projects.Add_Or_Promote (List, File_Path, "not-a-project-root", 559);
      Editor.Recent_Projects.Refresh_Availability (List);
      Assert (Editor.Recent_Projects.Count (List) = 1,
              "file-backed recent reference may be retained as an unavailable row");
      Assert (not Editor.Recent_Projects.Is_Available
                (Editor.Recent_Projects.Item (List, 1)),
              "recent project availability must require a directory project root");

      Remove_If_Exists (File_Path);
   end Test_Phase559_File_Path_Is_Unavailable_Project;


   procedure Test_Phase559_Unsupported_Project_Reference_Is_Dropped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path   : constant String := Temp_Path ("phase559-unsupported-reference.txt");
      List   : Editor.Recent_Projects.Recent_Project_List;
      Loaded : Editor.Recent_Projects.Recent_Project_List;
      Status : Editor.Recent_Projects.Recent_Project_Status;
      Text   : Unbounded_String;
   begin
      Remove_If_Exists (Path);

      Editor.Recent_Projects.Add_Or_Promote
        (List, "/tmp/phase559|bad", "bad", 1);
      Assert (Editor.Recent_Projects.Count (List) = 0,
              "unsupported pipe-delimited recent project references must be ignored before save");

      Write_Text
        (Path,
         "editor-recent-projects-version=1" & ASCII.LF &
         "[projects]" & ASCII.LF &
         "/tmp/phase559-ok|name=ok|opened=2" & ASCII.LF &
         "/tmp/phase559|bad|name=bad|opened=3" & ASCII.LF);
      Editor.Recent_Projects.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Partial_Load,
              "unsupported recent project references must not invalidate the whole file and must be reported");
      Assert (Editor.Recent_Projects.Last_Load_Ignored_Count = 1,
              "unsupported recent project references must be counted for recovery summaries");
      Assert (Editor.Recent_Projects.Count (Loaded) = 1,
              "load must retain only representable lightweight project references");

      Editor.Recent_Projects.Save_To_File (Loaded, Path, Status);
      Assert (Status = Editor.Recent_Projects.Recent_Project_Ok,
              "saving after load cleanup must still succeed");
      Text := To_Unbounded_String (Read_Text (Path));
      Assert (Ada.Strings.Fixed.Index (To_String (Text), "phase559|bad") = 0,
              "save must not re-emit unsupported recent project references");

      Remove_If_Exists (Path);
   end Test_Phase559_Unsupported_Project_Reference_Is_Dropped;

   procedure Test_Phase559_Row_Label_Is_Lightweight_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      List  : Editor.Recent_Projects.Recent_Project_List;
      Label : Unbounded_String;
   begin
      Editor.Recent_Projects.Add_Or_Promote
        (List, "/tmp/phase559-row", "phase559-row", 559);
      Label := To_Unbounded_String
        (Editor.Recent_Projects.Row_Label
           (Editor.Recent_Projects.Item (List, 1), Is_Selected => True));

      Assert (Ada.Strings.Fixed.Index (To_String (Label), "> phase559-row") = 1,
              "row label must carry a selected marker for the projected row");
      Assert (Ada.Strings.Fixed.Index (To_String (Label), "/tmp/phase559-row") > 0,
              "row label must include the project path label");
      Assert (Ada.Strings.Fixed.Index (To_String (Label), "workspace") = 0,
              "row label must not project workspace state");
      Assert (Ada.Strings.Fixed.Index (To_String (Label), "Build") = 0,
              "row label must not project Build state");
      Assert (Ada.Strings.Fixed.Index (To_String (Label), "Outline") = 0,
              "row label must not project Outline state");
   end Test_Phase559_Row_Label_Is_Lightweight_Projection;

   procedure Test_Focused_Recent_Projects_Keyboard_Routes_Through_Input_Bridge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_A : constant String := Temp_Path ("recent_keyboard_a");
      Root_B : constant String := Temp_Path ("recent_keyboard_b");
      S      : Editor.State.State_Type;
      After  : Editor.State.State_Type;
   begin
      Remove_If_Exists (Root_A);
      Remove_If_Exists (Root_B);
      Ada.Directories.Create_Path (Root_A);
      Ada.Directories.Create_Path (Root_B);

      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Root_A, "recent-a", 1);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Root_B, "recent-b", 2);
      S.Recent_Projects_Focused := True;
      S.Recent_Project_Selected_Index := 1;
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Recent_Project_Selected_Index = 2,
              "Down selects next focused recent project through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Up));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (After.Recent_Project_Selected_Index = 1,
              "Up selects previous focused recent project through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Project.Has_Project (After.Project),
              "Enter opens the selected recent project through Input_Bridge");

      After.Recent_Projects_Focused := True;
      After.Recent_Project_Selected_Index := 1;
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (Editor.Recent_Projects.Count (After.Recent_Projects) = 1,
              "Delete removes the selected focused recent project");

      After.Recent_Projects_Focused := True;
      Editor.Input_Bridge.Set_State_For_Test (After);
      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Assert (not After.Recent_Projects_Focused,
              "Escape returns focused recent projects to editor text");

      Remove_If_Exists (Root_A);
      Remove_If_Exists (Root_B);
   exception
      when others =>
         Remove_If_Exists (Root_A);
         Remove_If_Exists (Root_B);
         raise;
   end Test_Focused_Recent_Projects_Keyboard_Routes_Through_Input_Bridge;

   procedure Register_Tests
     (T : in out Recent_Projects_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Empty_And_Add_Promote'Access,
                        "Empty And Add Promote");
      Register_Routine (T, Test_Max_Remove_And_Normalize'Access,
                        "Max Remove And Normalize");
      Register_Routine (T, Test_Save_Load_Roundtrip'Access,
                        "Save Load Roundtrip");
      Register_Routine (T, Test_Load_Error_Statuses_And_Skip_Malformed'Access,
                        "Load Error Statuses And Skip Malformed");
      Register_Routine (T, Test_Phase213_Recent_Projects_Persistence_Domain'Access,
                        "Phase 213 recent projects persistence domain separation");
      Register_Routine (T, Test_Phase576_Recent_Projects_Save_Excludes_Buffer_List_Runtime_State'Access,
                        "Phase576 Recent Projects Save Excludes Buffer List Runtime State");
      Register_Routine (T, Test_Phase559_Missing_Availability_And_Remove_Missing'Access,
                        "Phase 559 missing availability and remove missing");
      Register_Routine (T, Test_Phase559_Recent_Entry_Remains_Lightweight'Access,
                        "Phase 559 recent entry remains lightweight");
      Register_Routine (T, Test_Phase559_Deduplicate_Load_Keeps_Newest'Access,
                        "Phase 559 deduplicate loaded recent projects keeps newest");
      Register_Routine (T, Test_Phase559_File_Path_Is_Unavailable_Project'Access,
                        "Phase 559 file path is unavailable project root");
      Register_Routine (T, Test_Phase559_Unsupported_Project_Reference_Is_Dropped'Access,
                        "Phase 559 unsupported project reference is dropped");
      Register_Routine (T, Test_Phase559_Row_Label_Is_Lightweight_Projection'Access,
                        "Phase 559 row label is lightweight projection");
      Register_Routine
        (T, Test_Focused_Recent_Projects_Keyboard_Routes_Through_Input_Bridge'Access,
         "focused recent projects keyboard routes through Input_Bridge");
   end Register_Tests;

end Editor.Recent_Projects.Tests;
