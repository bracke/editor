with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.File_Tree;
with Editor.Files;
with Editor.Layout;
with Editor.Project;
with Editor.Project_Search;
with Editor.Search_Results;
with Editor.Buffers;
with Editor.State;

package body Editor.Search_Results.Tests is

   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Search_Results.Search_Results_Row_Kind;
   use type Editor.Search_Results.Search_Results_Zone;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Current_Directory, "phase73_search_results_" & Name);
   end Temp_Path;

   procedure Remove_File_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Remove_File_If_Exists;

   procedure Remove_Dir_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Directory (Path);
      end if;
   end Remove_Dir_If_Exists;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Bytes'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
      end loop;
      if Bytes'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   procedure Cleanup_Fixture (Root : String) is
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   procedure Build_Fixture (Root : String) is
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "a.txt"),
         "Alpha needle" & ASCII.LF & "needle again needle");
      Write_Bytes
        (Ada.Directories.Compose (Root, "b.txt"),
         "plain needle");
   end Build_Fixture;

   function Read_Text
     (Path : String;
      Text : out Unbounded_String) return Boolean
   is
      Result : constant Editor.Files.File_Open_Result := Editor.Files.Open_File (Path);
   begin
      if Editor.Files.Is_Success (Result) then
         Text := Result.Contents;
         return True;
      else
         Text := Null_Unbounded_String;
         return False;
      end if;
   end Read_Text;

   function Build_Search (Root : String) return Editor.Project_Search.Project_Search_State is
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      return Search;
   end Build_Search;

   overriding function Name
     (T : Search_Results_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Search_Results.Tests");
   end Name;

   procedure Test_Empty_Snapshot_And_Formatting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search : Editor.Project_Search.Project_Search_State;
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Header   : Editor.Search_Results.Search_Results_Row;
      Empty    : Editor.Search_Results.Search_Results_Row;
   begin
      Editor.Project_Search.Set_Status
        (Search, Editor.Project_Search.Project_Search_No_Project);
      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);
      Assert (Editor.Search_Results.Row_Count (Snapshot) = 2,
              "empty Search Results snapshot should include a header and empty-state row");
      Header := Editor.Search_Results.Row (Snapshot, 1);
      Empty := Editor.Search_Results.Row (Snapshot, 2);
      Assert (Header.Kind = Editor.Search_Results.Search_Results_Header_Row,
              "first Search Results snapshot row should be the header");
      Assert (Empty.Kind = Editor.Search_Results.Search_Results_Empty_Row,
              "empty project search should produce an empty-state row");
      Assert (To_String (Header.Text) = "Search Project - No project open",
              "header should format no-project status deterministically");
      Assert (Editor.Search_Results.Truncate_Text ("abcdef", 5) = "ab...",
              "Search Results truncation should use deterministic ASCII ellipsis");
   end Test_Empty_Snapshot_And_Formatting;

   procedure Test_Grouped_Snapshot_And_Selected_Row
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("grouped_root");
      Search : Editor.Project_Search.Project_Search_State := Build_Search (Root);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Row_1 : Editor.Search_Results.Search_Results_Row;
      Row_2 : Editor.Search_Results.Search_Results_Row;
      Row_3 : Editor.Search_Results.Search_Results_Row;
   begin
      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);
      Assert (Editor.Project_Search.Result_Count (Search) = 3,
              "fixture should produce three line-based search results");
      Assert (Editor.Search_Results.Row_Count (Snapshot) = 6,
              "snapshot should contain header, two file groups, and three match rows");

      Row_1 := Editor.Search_Results.Row (Snapshot, 1);
      Row_2 := Editor.Search_Results.Row (Snapshot, 2);
      Row_3 := Editor.Search_Results.Row (Snapshot, 3);
      Assert (Row_1.Kind = Editor.Search_Results.Search_Results_Header_Row
              and then To_String (Row_1.Text) =
                "Search Project: ""needle"" - 3 matches in 2 files; searched 2 files - Scope: all | Kind: all | Case: insensitive | Whole word: off | Regex: off",
              "header should include result count, file count, and query");
      Assert (Row_2.Kind = Editor.Search_Results.Search_Results_File_Row
              and then To_String (Row_2.Text) = "a.txt (2)",
              "file group row should show relative path and match count");
      Assert (Row_3.Kind = Editor.Search_Results.Search_Results_Match_Row
              and then Row_3.Result_Index = 1
              and then Row_3.Is_Selected,
              "first match row should map to selected result index one");
      Assert (To_String (Row_3.Text) = "  a.txt:1:7: Alpha needle"
              and then To_String (Row_3.Line_Preview) = "Alpha needle"
              and then Row_3.Match_Column = 7
              and then Row_3.Preview_Match_Start = 7
              and then Row_3.Preview_Match_Length = 6
              and then To_String (Row_3.Display_Text) = To_String (Row_3.Text),
              "Phase 338 match row should render stored preview, one-based column, and structured match range");

      Cleanup_Fixture (Root);
   end Test_Grouped_Snapshot_And_Selected_Row;

   procedure Test_Phase547_Header_Shows_Skip_And_Limit_Details
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase547_skip_header_root");
      Project : Editor.Project.Project_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened : Editor.Project.Project_Open_Result;
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Header : Editor.Search_Results.Search_Results_Row;
      Header_Text : Unbounded_String;
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "large.txt"));
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "ok.txt"), "needle needle");
      Write_Bytes (Ada.Directories.Compose (Root, "large.txt"), "needle too large");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "ok.txt", Ada.Directories.Compose (Root, "ok.txt"));
      Editor.Project.Add_Known_File
        (Project, "large.txt", Ada.Directories.Compose (Root, "large.txt"));
      Editor.Project.Add_Known_File
        (Project, "missing.txt", Ada.Directories.Compose (Root, "missing.txt"));

      Options.Max_File_Size_Bytes := 8;
      Options.Max_Result_Count := 1;
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);
      Header := Editor.Search_Results.Row (Snapshot, 1);
      Header_Text := Header.Text;

      Assert (Ada.Strings.Fixed.Index (To_String (Header_Text), "skipped 2") > 0
              and then Ada.Strings.Fixed.Index (To_String (Header_Text), "missing=1") > 0
              and then Ada.Strings.Fixed.Index (To_String (Header_Text), "large=1") > 0
              and then Ada.Strings.Fixed.Index (To_String (Header_Text), "result limit reached") > 0,
              "Phase 547 header should expose skipped-file categories and result-limit state clearly");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "large.txt"));
      Remove_Dir_If_Exists (Root);
   end Test_Phase547_Header_Shows_Skip_And_Limit_Details;


   procedure Test_Phase547_Invalid_Regex_Header
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase547_invalid_regex_header_root");
      Tree : Editor.File_Tree.File_Tree_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Header : Editor.Search_Results.Search_Results_Row;
      Empty  : Editor.Search_Results.Search_Results_Row;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "[");
      Editor.Project_Search.Set_Regex_Enabled (Search, True);
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);
      Header := Editor.Search_Results.Row (Snapshot, 1);
      Empty := Editor.Search_Results.Row (Snapshot, 2);

      Assert (Header.Kind = Editor.Search_Results.Search_Results_Header_Row
              and then Ada.Strings.Fixed.Index
                (To_String (Header.Text), "Invalid regex") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Header.Text), "Regex: on") > 0,
              "Phase 547 invalid regex status should render a deterministic header instead of falling through the status case");
      Assert (Empty.Kind = Editor.Search_Results.Search_Results_Empty_Row,
              "invalid regex snapshots should contain no stale match rows");

      Cleanup_Fixture (Root);
   end Test_Phase547_Invalid_Regex_Header;

   procedure Test_Hit_Test
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("hit_root");
      Search : Editor.Project_Search.Project_Search_State := Build_Search (Root);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : constant Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot (Search, Config);
      Panel : constant Editor.Layout.Rect :=
        (X => 10, Y => 20, Width => 300, Height => 80);
      Hit : Editor.Search_Results.Search_Results_Hit_Result;
   begin
      Hit := Editor.Search_Results.Hit_Test (Panel, Config, Snapshot, 10, 0, 0);
      Assert (Hit.Zone = Editor.Search_Results.Outside_Search_Results,
              "point outside Search Results panel should be outside");

      Hit := Editor.Search_Results.Hit_Test (Panel, Config, Snapshot, 10, 15, 25);
      Assert (Hit.Zone = Editor.Search_Results.Search_Results_Header_Zone,
              "first rendered Search Results row should hit the header");

      Hit := Editor.Search_Results.Hit_Test (Panel, Config, Snapshot, 10, 15, 35);
      Assert (Hit.Zone = Editor.Search_Results.Search_Results_File_Row_Zone,
              "second rendered Search Results row should hit a file row");

      Hit := Editor.Search_Results.Hit_Test (Panel, Config, Snapshot, 10, 15, 45);
      Assert (Hit.Zone = Editor.Search_Results.Search_Results_Match_Row_Zone
              and then Hit.Result_Index = 1,
              "third rendered Search Results row should hit the first match result");

      Hit := Editor.Search_Results.Hit_Test (Panel, Config, Snapshot, 10, 15, 95);
      Assert (Hit.Zone = Editor.Search_Results.Search_Results_Background_Zone,
              "point below rendered Search Results rows should hit background");

      Cleanup_Fixture (Root);
   end Test_Hit_Test;



   procedure Test_Row_Mapping_And_Windowing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("mapping_root");
      Search : Editor.Project_Search.Project_Search_State := Build_Search (Root);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Visible  : Editor.Search_Results.Search_Results_Snapshot;
      View     : Editor.Search_Results.Search_Results_View_State;
      Found    : Boolean := False;
      Row_Num  : Natural := 0;
      Result_Index : Natural := 0;
   begin
      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);

      Row_Num := Editor.Search_Results.Row_For_Result (Snapshot, 2, Found);
      Assert (Found and then Row_Num = 4,
              "second result should map to the fourth snapshot row");

      Result_Index := Editor.Search_Results.Result_For_Row (Snapshot, 4, Found);
      Assert (Found and then Result_Index = 2,
              "fourth snapshot row should map back to second result");

      Result_Index := Editor.Search_Results.Result_For_Row (Snapshot, 2, Found);
      Assert ((not Found) and then Result_Index = 0,
              "file rows should not directly map to concrete results");

      Result_Index := Editor.Search_Results.First_Result_In_File_Group (Snapshot, 2, Found);
      Assert (Found and then Result_Index = 1,
              "file group helper should return the first result in that group");

      Editor.Project_Search.Set_Selected_Result_Index (Search, 3);
      Editor.Search_Results.Ensure_Selected_Row_Visible
        (View, Snapshot, Editor.Project_Search.Selected_Result_Index (Search), 3);
      Assert (View.Top_Row = 5,
              "visible window should scroll down to keep selected result visible");

      Visible := Editor.Search_Results.Visible_Snapshot (Snapshot, View, 3);
      Assert (Editor.Search_Results.Row_Count (Visible) = 3,
              "visible Search Results snapshot should be clipped to panel capacity");

      Cleanup_Fixture (Root);
   end Test_Row_Mapping_And_Windowing;

   procedure Test_Row_Selection_Does_Not_Wrap
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("keyboard_nowrap_root");
      Search : Editor.Project_Search.Project_Search_State := Build_Search (Root);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Snapshot : Editor.Search_Results.Search_Results_Snapshot :=
        Editor.Search_Results.Build_Snapshot (Search, Config);
      View : Editor.Search_Results.Search_Results_View_State;
   begin
      Editor.Search_Results.Move_Row_Selection
        (View, Search, Snapshot, Editor.Search_Results.Previous_Row);
      Assert
        (Editor.Project_Search.Selected_Result_Index (Search) = 1,
         "Phase 76 focused Search Results Up should not wrap before the first result");

      Editor.Project_Search.Set_Selected_Result_Index
        (Search, Editor.Project_Search.Result_Count (Search));
      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config);
      Editor.Search_Results.Move_Row_Selection
        (View, Search, Snapshot, Editor.Search_Results.Next_Row);
      Assert
        (Editor.Project_Search.Selected_Result_Index (Search) =
           Editor.Project_Search.Result_Count (Search),
         "Phase 76 focused Search Results Down should not wrap after the last result");

      Cleanup_Fixture (Root);
   end Test_Row_Selection_Does_Not_Wrap;


   procedure Test_Phase334_Marker_Snapshot_Uses_Buffer_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase334_marker_root");
      Search : Editor.Project_Search.Project_Search_State := Build_Search (Root);
      Config : constant Editor.Search_Results.Search_Results_View_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Row_3 : Editor.Search_Results.Search_Results_Row;
   begin
      Id := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         Ada.Directories.Compose (Root, "a.txt"),
         "a.txt",
         "Alpha needle" & ASCII.LF & "needle again needle");
      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Id).all, True);

      Snapshot := Editor.Search_Results.Build_Snapshot (Search, Config, Registry);
      Row_3 := Editor.Search_Results.Row (Snapshot, 3);
      Assert (Row_3.Is_Open and then Row_3.Is_Active and then Row_3.Is_Dirty,
              "Phase 334 Search Results snapshot should derive open/active/dirty markers from buffer state");
      Assert (To_String (Row_3.Project_Relative_Path) = "a.txt"
              and then Row_3.Line_Number = 1
              and then Row_3.Match_Column = 6,
              "Phase 334 Search Results row should expose structured result location fields");
      Assert (To_String (Row_3.Display_Text) = To_String (Row_3.Text)
              and then Ada.Strings.Fixed.Index (To_String (Row_3.Text), "[open]") > 0
              and then Ada.Strings.Fixed.Index (To_String (Row_3.Text), "a.txt:1:6:") > 0,
              "Phase 338 marker-prefixed rows should keep Display_Text and Text consistent while preserving path:line:column display");

      Cleanup_Fixture (Root);
   end Test_Phase334_Marker_Snapshot_Uses_Buffer_State;

   overriding procedure Register_Tests
     (T : in out Search_Results_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Empty_Snapshot_And_Formatting'Access,
         "Phase 73 Search Results snapshot formats empty states and truncation");
      Register_Routine
        (T, Test_Grouped_Snapshot_And_Selected_Row'Access,
         "Phase 73 Search Results snapshot groups matches and maps selected row");
      Register_Routine
        (T, Test_Phase547_Header_Shows_Skip_And_Limit_Details'Access,
         "Phase 547 Search Results header shows skip and limit details");
      Register_Routine
        (T, Test_Phase547_Invalid_Regex_Header'Access,
         "Phase 547 Search Results header renders invalid regex status");
      Register_Routine
        (T, Test_Hit_Test'Access,
         "Phase 73 Search Results hit-testing maps rows to result indexes");
      Register_Routine
        (T, Test_Row_Mapping_And_Windowing'Access,
         "Phase 75 Search Results maps rows and keeps selected results visible");
      Register_Routine
        (T, Test_Row_Selection_Does_Not_Wrap'Access,
         "Phase 76 Search Results focused row movement does not wrap");
      Register_Routine
        (T, Test_Phase334_Marker_Snapshot_Uses_Buffer_State'Access,
         "Phase 334 Search Results snapshots include structured location and buffer markers");
   end Register_Tests;

end Editor.Search_Results.Tests;
