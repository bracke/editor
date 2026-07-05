with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.File_Tree;
with Editor.Files;
with Editor.Project_Search;
with Editor.Project;
with Editor.Commands;
with Editor.Buffers;
with Editor.Command_Route_Audit;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Target_Prompt_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.State;
with Editor.Search_Results;

package body Editor.Project_Search.Tests is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Project_Search.Project_Search_Result_Id;
   use type Editor.Project_Search.Project_Search_File_Kind_Filter;
   use type Editor.Project_Search.Project_Replace_Preview_Status;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Search_Results.Search_Results_Row_Kind;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Visibility;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "project_search_" & Name);
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
         Ada.Directories.Delete_Tree (Path);
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


   procedure Remove_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_Tree_If_Exists;

   procedure Build_Fixture (Root : String) is
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "a.txt"),
         "Alpha needle" & ASCII.LF & "needle again needle");
      Write_Bytes
        (Ada.Directories.Compose (Root, "b.txt"),
         "Needle upper" & ASCII.LF & "plain needle");
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


   procedure Assert_Project_Search_Coherent
     (Search : Editor.Project_Search.Project_Search_State;
      Label  : String)
   is
      Count        : constant Natural := Editor.Project_Search.Result_Count (Search);
      Selected     : constant Natural := Editor.Project_Search.Selected_Result_Index (Search);
      Unique_Files : Natural := 0;
      Seen         : Boolean := False;
      Result       : Editor.Project_Search.Project_Search_Result;
      Candidate    : Editor.Project_Search.Project_Search_Result;
   begin
      if Count = 0 then
         Assert (Selected = 0,
                 Label & ": empty results should have empty selection");
         Assert (Editor.Project_Search.File_Group_Count (Search) = 0,
                 Label & ": empty results should have no file groups");
      else
         Assert (Selected in 1 .. Count,
                 Label & ": selected result should exist in current results");
      end if;

      for I in 1 .. Count loop
         Result := Editor.Project_Search.Result_At (Search, I);
         Assert (Result.Id /= Editor.Project_Search.No_Project_Search_Result,
                 Label & ": every visible result should have a structured id");
         Assert (Result.Row > 0,
                 Label & ": every result should carry a one-based row");
         Assert (Result.Match_Column = Result.Start_Column + 1,
                 Label & ": match column should stay consistent with stored range");
         Assert (Length (Result.Line_Preview) <=
                   Editor.Project_Search.Max_Search_Result_Preview_Length,
                 Label & ": preview should remain bounded");
         if Length (Result.Line_Preview) > 0 then
            Assert (Result.Preview_Match_Start = 0
                    or else Result.Preview_Match_Start <= Length (Result.Line_Preview),
                    Label & ": preview match start should point inside the preview");
            Assert (Result.Preview_Match_Length = 0
                    or else Result.Preview_Match_Start + Result.Preview_Match_Length - 1
                      <= Length (Result.Line_Preview),
                    Label & ": preview match range should point inside the preview");
         end if;

         Seen := False;
         for J in 1 .. I - 1 loop
            Candidate := Editor.Project_Search.Result_At (Search, J);
            if To_String (Candidate.Relative_Path) = To_String (Result.Relative_Path) then
               Seen := True;
            end if;
         end loop;
         if not Seen then
            Unique_Files := Unique_Files + 1;
         end if;
      end loop;

      Assert (Editor.Project_Search.Files_With_Matches (Search) = Unique_Files,
              Label & ": matched-file count should equal unique result paths");
      Assert (Editor.Project_Search.File_Group_Count (Search) = Unique_Files,
              Label & ": file-group count should equal unique result paths for grouped results");
      Assert (Editor.Project_Search.Skipped_File_Count (Search) =
                Editor.Project_Search.Skipped_Missing_Count (Search)
              + Editor.Project_Search.Skipped_Large_Count (Search)
              + Editor.Project_Search.Skipped_Binary_Count (Search)
              + Editor.Project_Search.Read_Error_Count (Search),
              Label & ": aggregate skipped count should match individual categories");
   end Assert_Project_Search_Coherent;


   procedure Assert_Project_Search_File_Lifecycle_Observation_Canonical
     (Search : Editor.Project_Search.Project_Search_State;
      Label  : String)
   is
   begin
      Assert_Project_Search_Coherent (Search, Label);
      Assert
        (Editor.Project_Search.Project_Search_No_Duplicate_Lifecycle_State (Search),
         Label & ": duplicate lifecycle observation state must be absent");
      Assert
        (Editor.Project_Search.Project_Search_No_Prompt_State (Search),
         Label & ": prompt ownership must remain outside Project Search");
      Assert
        (Editor.Project_Search.Project_Search_Query_Selection_Source_Target_Boundary
           (Search),
         Label & ": query and selection must remain UI state only");
      Assert
        (Editor.Project_Search.Project_Search_Project_Source_Boundary_Canonical
           (Search),
         Label & ": retained project/searchable-file source boundary must be canonical");
      Assert
        (Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Canonical
           (Search),
         Label & ": canonical lifecycle observation predicate must hold");
   end Assert_Project_Search_File_Lifecycle_Observation_Canonical;

   procedure Assert_Project_Search_File_Lifecycle_Observation_Frozen
     (Search : Editor.Project_Search.Project_Search_State;
      Label  : String)
   is
   begin
      Assert_Project_Search_File_Lifecycle_Observation_Canonical (Search, Label);
      Assert
        (Editor.Project_Search.Project_Search_File_Lifecycle_Observation_Frozen
           (Search),
         Label & ": final frozen lifecycle observation predicate must hold");
   end Assert_Project_Search_File_Lifecycle_Observation_Frozen;

   procedure Add_Known
     (Project : in out Editor.Project.Project_State;
      Rel     : String;
      Abs_Path     : String)
   is
   begin
      Editor.Project.Add_Known_File (Project, Rel, Abs_Path);
   end Add_Known;

   procedure Assert_Absent_Command_Not_Exposed (Stable_Name : String) is
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Stable_Name, Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              Stable_Name & " must not resolve to a registered command");
   end Assert_Absent_Command_Not_Exposed;

   function Project_Search_Has_Result_Path
     (Search : Editor.Project_Search.Project_Search_State;
      Path   : String) return Boolean
   is
      Result : Editor.Project_Search.Project_Search_Result;
   begin
      for I in 1 .. Editor.Project_Search.Result_Count (Search) loop
         Result := Editor.Project_Search.Result_At (Search, I);
         if To_String (Result.Relative_Path) = Path then
            return True;
         end if;
      end loop;
      return False;
   end Project_Search_Has_Result_Path;



   procedure Assert_Project_Search_Result_Set_Unchanged
     (Search        : Editor.Project_Search.Project_Search_State;
      Expected_One  : String;
      Expected_Two  : String;
      Forbidden_One : String;
      Forbidden_Two : String;
      Label         : String)
   is
   begin
      Assert_Project_Search_Coherent (Search, Label);
      if Expected_One'Length > 0 then
         Assert (Project_Search_Has_Result_Path (Search, Expected_One),
                 Label & ": expected retained source missing: " & Expected_One);
      end if;
      if Expected_Two'Length > 0 then
         Assert (Project_Search_Has_Result_Path (Search, Expected_Two),
                 Label & ": expected retained source missing: " & Expected_Two);
      end if;
      if Forbidden_One'Length > 0 then
         Assert (not Project_Search_Has_Result_Path (Search, Forbidden_One),
                 Label & ": forbidden lifecycle-derived result present: " & Forbidden_One);
      end if;
      if Forbidden_Two'Length > 0 then
         Assert (not Project_Search_Has_Result_Path (Search, Forbidden_Two),
                 Label & ": forbidden lifecycle-derived result present: " & Forbidden_Two);
      end if;
   end Assert_Project_Search_Result_Set_Unchanged;

   procedure Rerun_Project_Search
     (S       : in out Editor.State.State_Type;
      Options : Editor.Project_Search.Project_Search_Options)
   is
   begin
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
   end Rerun_Project_Search;

   procedure Assert_Project_Search_File_Lifecycle_Observation_Coherent
     (Search       : Editor.Project_Search.Project_Search_State;
      Expected_Path : String;
      Forbidden_Path : String;
      Label        : String)
   is
   begin
      Assert_Project_Search_Coherent (Search, Label);
      if Expected_Path'Length > 0 then
         Assert (Project_Search_Has_Result_Path (Search, Expected_Path),
                 Label & ": retained project/searchable source should remain visible");
      end if;
      if Forbidden_Path'Length > 0 then
         Assert (not Project_Search_Has_Result_Path (Search, Forbidden_Path),
                 Label & ": lifecycle target history must not create a search result");
      end if;
      Assert (Editor.Project_Search.Query (Search)'Length = 0
              or else Editor.Project_Search.Last_Run_Query (Search) =
                Editor.Project_Search.Query (Search),
              Label & ": Project Search query remains search text only");
   end Assert_Project_Search_File_Lifecycle_Observation_Coherent;

   overriding function Name
     (T : Project_Search_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Project_Search.Tests");
   end Name;

   procedure Test_Initial_Clear_And_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search : Editor.Project_Search.Project_Search_State;
   begin
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Idle,
              "new project search state should be idle");
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "new project search state should have no results");

      Editor.Project_Search.Set_Query (Search, "needle");
      Assert (Editor.Project_Search.Query (Search) = "needle",
              "Set_Query should store the project search query");
      Assert (Editor.Project_Search.Has_Query (Search),
              "Has_Query should be true after Set_Query with text");

      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = "",
              "Clear should clear the project search query");
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Idle,
              "Clear should return project search to idle");
   end Test_Initial_Clear_And_Query;

   procedure Test_Empty_Query_And_No_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("empty_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Project_Search.Set_Query (Search, "");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Empty_Query,
              "empty project search query should produce Empty_Query status");

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_No_Files,
              "project search over a tree with no file nodes should produce No_Files status");

      Cleanup_Fixture (Root);
   end Test_Empty_Query_And_No_Files;

   procedure Test_Literal_Search_Grouping_And_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("literal_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Result_1 : Editor.Project_Search.Project_Search_Result;
      Result_2 : Editor.Project_Search.Project_Search_Result;
      Group_1  : Editor.Project_Search.Project_Search_File_Group;
      Found    : Boolean := False;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Ok,
              "literal project search should complete with Ok status");
      Assert (Editor.Project_Search.Result_Count (Search) = 5,
              "case-insensitive project search should find every non-overlapping match occurrence");
      Assert (Editor.Project_Search.File_Group_Count (Search) = 2,
              "matches should be grouped by matching file");
      Assert (Editor.Project_Search.Files_Searched (Search) = 2,
              "project search should track the deterministic number of searched files");
      Assert (Editor.Project_Search.Files_With_Matches (Search) = 2,
              "project search should track the number of files with matches");
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "search with matches should select the first result");

      Result_1 := Editor.Project_Search.Result_At (Search, 1);
      Result_2 := Editor.Project_Search.Result_At (Search, 2);
      Assert (To_String (Result_1.Relative_Path) = "a.txt",
              "first result should be in the first deterministic file");
      Assert (Result_1.Row = 1
              and then Result_1.Start_Column = 6
              and then Result_1.Match_Column = 7,
              "first result should carry one-based line number, zero-based internal range, and one-based match column");
      Assert (To_String (Result_1.Line_Preview) = "Alpha needle"
              and then Result_1.Preview_Match_Start = 7
              and then Result_1.Preview_Match_Length = 6,
              "short preview should be stored with a valid preview match range");
      Assert (Result_2.Row = 2 and then Result_2.Start_Column = 0,
              "second result should be ordered by line number and column within the file");

      Group_1 := Editor.Project_Search.File_Group_At (Search, 1);
      Assert (To_String (Group_1.Relative_Path) = "a.txt"
              and then Group_1.First_Result_Index = 1
              and then Group_1.Result_Count = 3,
              "first file group should point at its first result and occurrence count");

      declare
         Selected : constant Editor.Project_Search.Project_Search_Result :=
           Editor.Project_Search.Selected_Result (Search, Found);
      begin
         Assert (Found and then Selected.Id = Result_1.Id,
                 "Selected_Result should return the selected project search result");
      end;

      Cleanup_Fixture (Root);
   end Test_Literal_Search_Grouping_And_Order;

   procedure Test_Selection_Case_And_Limits
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("limits_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Options.Case_Sensitive := False;
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 5,
              "case-insensitive project search should include one row per match occurrence");

      Editor.Project_Search.Move_Selection_Down (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 2,
              "Move_Selection_Down should advance to the next result");
      Editor.Project_Search.Move_Selection_Up (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "Move_Selection_Up should return to the previous result");

      Options := (Case_Sensitive => False,
                  Max_File_Count => 5_000,
                  Max_Result_Count => 2,
                  Max_Matches_Per_File => 200,
                  Max_Line_Length => 500,
                  Max_File_Size_Bytes => 2 * 1024 * 1024,
                  others => <>);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "Max_Result_Count should truncate collected results deterministically");
      Assert (Editor.Project_Search.Was_Truncated (Search),
              "truncated project search should expose Was_Truncated");
      Assert (Editor.Project_Search.Matches_Truncated_Count (Search) > 0,
              "truncated project search should expose a deterministic truncation count");

      Editor.Project_Search.Move_Selected_Result
        (Search, Editor.Project_Search.Next_Result, True);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 2,
              "Move_Selected_Result Next should advance selection");
      Editor.Project_Search.Move_Selected_Result
        (Search, Editor.Project_Search.Next_Result, True);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "Move_Selected_Result should wrap by default");
      Editor.Project_Search.Mark_Stale (Search);
      Assert (Editor.Project_Search.Is_Stale (Search),
              "Mark_Stale should mark existing project search results stale");
      Editor.Project_Search.Clear_Stale (Search);
      Assert (not Editor.Project_Search.Is_Stale (Search),
              "Clear_Stale should clear stale project search state");

      Cleanup_Fixture (Root);
   end Test_Selection_Case_And_Limits;


   procedure Test_Zero_Result_Query_Marks_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("zero_result_stale");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Project_Search.Set_Query (Search, "newly-created-token");
      Editor.Project_Search.Search_Project
        (Search, Tree, Read_Text'Access, Options);

      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "setup should retain a zero-result project search");
      Assert (not Editor.Project_Search.Is_Stale (Search),
              "setup should start with a fresh zero-result search");

      Editor.Project_Search.Mark_Stale (Search);

      Assert (Editor.Project_Search.Is_Stale (Search),
              "File Tree mutation invalidation must stale retained zero-result searches");

      Cleanup_Fixture (Root);
   end Test_Zero_Result_Query_Marks_Stale;


   procedure Test_Zero_Result_Replace_Preview_Marks_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("zero_replace_stale");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Status  : Editor.Project_Search.Project_Replace_Preview_Status;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Project_Search.Set_Query (Search, "future-replace-token");
      Editor.Project_Search.Search_Project
        (Search, Tree, Read_Text'Access, Options);
      Editor.Project_Search.Set_Replace_Text (Search, "replacement");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);

      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "setup should retain a zero-result replace search");
      Assert (Status = Editor.Project_Search.Project_Replace_No_Search_Results,
              "setup should expose a no-results replace preview status");
      Assert (not Editor.Project_Search.Replace_Preview_Is_Stale (Search),
              "setup should start with a fresh zero-row replace preview");

      Editor.Project_Search.Mark_Stale (Search);

      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (Search),
              "File Tree mutation invalidation must stale retained zero-row replace previews");
      Assert (Editor.Project_Search.Replace_Preview_Status (Search) =
                Editor.Project_Search.Project_Replace_Search_Stale,
              "zero-row replace preview should report stale search status after mutation invalidation");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Zero_Result_Replace_Preview_Marks_Stale;


   procedure Test_Result_Navigation_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("nav_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      Search : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Found  : Boolean := False;
      Dir    : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 5,
              "fixture should expose navigable project-search result occurrences");

      Editor.Project_Search.Select_Last_Result (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 5,
              "last navigation should select the final stored result");
      Editor.Project_Search.Select_First_Result (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "first navigation should select the first stored result");

      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "b.txt");
      Assert (Found and then Editor.Project_Search.Selected_Result_Index (Search) = 4,
              "reveal-active helper should select the first result for a path");
      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "b.txt");
      Assert (Found and then Editor.Project_Search.Selected_Result_Index (Search) = 4,
              "reveal-active helper should preserve a selection already in the active file");
      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "missing.txt");
      Assert ((not Found) and then Editor.Project_Search.Selected_Result_Index (Search) = 4,
              "reveal-active helper should not disturb selection when no result matches");

      Dir := To_Unbounded_String
        (Editor.Project_Search.Selected_Result_Directory (Search, Found));
      Assert (Found and then To_String (Dir) = "",
              "selected-directory helper should clear scope for root-level files");
      Assert (Editor.Project_Search.Directory_Scope_Of_Path ("src/editor/executor.adb") = "src/editor/",
              "directory scope helper should derive the selected result directory");

      Cleanup_Fixture (Root);
   end Test_Result_Navigation_Helpers;


   procedure Test_Command_Surface_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Open_Project_Search_Bar) = "project.search.show",
              "project search show command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Toggle_Project_Search_Bar) = "project.search.toggle",
              "project search toggle command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Close_Project_Search_Bar) = "project.search.hide",
              "project search hide command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Run_Project_Search) = "project.search.run",
              "project search run command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Run_Project_Search_From_Bar) = "project.search.query.set",
              "project search query.set route must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_From_Selection) = "project.search.from-selection",
              "from-selection command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_From_Active_Word) = "project.search.from-active-word",
              "from-active-word command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Active_Directory) = "project.search.active-directory",
              "active-directory command must have stable persisted name");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_From_Selection).Bindable,
              "from-selection command should be bindable");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_From_Active_Word).Bindable,
              "from-active-word command should be bindable");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_Active_Directory).Bindable,
              "active-directory command should be bindable");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_From_Selection).Visibility = Editor.Commands.Palette_Command,
              "from-selection command should be Command Palette visible");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_From_Active_Word).Visibility = Editor.Commands.Palette_Command,
              "from-active-word command should be Command Palette visible");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_Active_Directory).Visibility = Editor.Commands.Palette_Command,
              "active-directory command should be Command Palette visible");
      Assert (not Editor.Commands.Descriptor
                    (Editor.Commands.Command_Project_Search_From_Selection).Destructive
              and then not Editor.Commands.Descriptor
                    (Editor.Commands.Command_Project_Search_From_Active_Word).Destructive
              and then not Editor.Commands.Descriptor
                    (Editor.Commands.Command_Project_Search_Active_Directory).Destructive,
              "context search commands should be non-destructive");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Clear_Project_Search) = "project.search.query.clear",
              "project search query.clear route must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Next_Project_Search_Result) = "project.search.next",
              "project search next command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Previous_Project_Search_Result) = "project.search.previous",
              "project search previous command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_First_Project_Search_Result) = "project.search.first",
              "project search first command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Last_Project_Search_Result) = "project.search.last",
              "project search last command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Reveal_Active_Project_Search_Result) = "project.search.reveal-active-result",
              "project search reveal-active-result command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Scope_Selected_Directory) = "project.search.scope.selected-directory",
              "project search selected-directory scope command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Open_Selected_Project_Search_Result) = "project.search.open-selected",
              "project search open-selected command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Kind_Next) = "project.search.kind.next",
              "Project Search kind-next command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Kind_Previous) = "project.search.kind.previous",
              "Project Search kind-previous command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Kind_Clear) = "project.search.kind.clear",
              "Project Search kind-clear command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Scope_Set) = "project.search.scope.set",
              "Project Search scope-set command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Scope_Clear) = "project.search.scope.clear",
              "Project Search scope-clear command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Case_Toggle) = "project.search.case.toggle",
              "Project Search case-toggle command must have stable persisted name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Project_Search_Case_Clear) = "project.search.case.clear",
              "Project Search case-clear command must have stable persisted name");
      Assert (not Editor.Commands.Descriptor
                    (Editor.Commands.Command_Project_Search_Scope_Set).Bindable,
              "payload-style Project Search scope.set must not be bindable");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Project_Search_Case_Toggle).Bindable,
              "Project Search case toggle should be bindable like local search commands");

      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.run", Found);
      Assert (Found and then Id = Editor.Commands.Command_Run_Project_Search,
              "project.search.run should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.toggle", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Project_Search_Bar,
              "project.search.toggle should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.scope.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Scope_Clear,
              "project.search.scope.clear should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.from-selection", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_From_Selection,
              "project.search.from-selection should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.from-active-word", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_From_Active_Word,
              "project.search.from-active-word should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.active-directory", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Active_Directory,
              "project.search.active-directory should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.first", Found);
      Assert (Found and then Id = Editor.Commands.Command_First_Project_Search_Result,
              "project.search.first should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.last", Found);
      Assert (Found and then Id = Editor.Commands.Command_Last_Project_Search_Result,
              "project.search.last should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.reveal-active-result", Found);
      Assert (Found and then Id = Editor.Commands.Command_Reveal_Active_Project_Search_Result,
              "project.search.reveal-active-result should roundtrip through stable command lookup");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("project.search.scope.selected-directory", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Scope_Selected_Directory,
              "project.search.scope.selected-directory should roundtrip through stable command lookup");
   end Test_Command_Surface_Stable_Names;

   procedure Test_Known_Project_File_Search
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("known_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
   begin
      Build_Fixture (Root);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "b.txt", Ada.Directories.Compose (Root, "b.txt"));
      Editor.Project.Add_Known_File
        (Project, "a.txt", Ada.Directories.Compose (Root, "a.txt"));
      Editor.Project.Add_Known_File
        (Project, "missing.txt", Ada.Directories.Compose (Root, "missing.txt"));

      Editor.Project_Search.Set_Query (Search, "NEEDLE");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);

      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Ok,
              "known-file project search should complete successfully");
      Assert (Editor.Project_Search.Result_Count (Search) = 5,
              "search should be case-insensitive and one row per match occurrence");
      Assert (To_String (Editor.Project_Search.Result_At (Search, 1).Relative_Path) = "a.txt",
              "search result order should follow sorted known project file order");
      Assert (Editor.Project_Search.Skipped_Missing_Count (Search) = 1,
              "search should count missing stale known files without mutating the known list");
      Assert (Editor.Project.Known_File_Count (Project) = 3,
              "search must not prune or refresh the known project file list");

      Cleanup_Fixture (Root);
   end Test_Known_Project_File_Search;

   procedure Test_Limits_And_Binary_Skips
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("bounds_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "large.txt"), "needle too large");
      Write_Bytes (Ada.Directories.Compose (Root, "binary.bin"), "abc" & ASCII.NUL & "needle");
      Write_Bytes (Ada.Directories.Compose (Root, "ok.txt"), "needle ok");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "large.txt", Ada.Directories.Compose (Root, "large.txt"));
      Editor.Project.Add_Known_File
        (Project, "binary.bin", Ada.Directories.Compose (Root, "binary.bin"));
      Editor.Project.Add_Known_File
        (Project, "ok.txt", Ada.Directories.Compose (Root, "ok.txt"));

      Options.Max_File_Size_Bytes := 4;
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "per-file size bound should skip files above the limit");
      Assert (Editor.Project_Search.Skipped_Large_Count (Search) = 3,
              "should report large-file skips deterministically");

      Options.Max_File_Size_Bytes := 2 * 1024 * 1024;
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "should search readable text files and skip binary-looking files");
      Assert (Editor.Project_Search.Skipped_Binary_Count (Search) = 1,
              "should count binary-looking decode failures separately");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "large.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "binary.bin"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok.txt"));
      Remove_Dir_If_Exists (Root);
   end Test_Limits_And_Binary_Skips;


   procedure Test_Rerun_Preserves_Selection_By_Path_Line
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("preserve_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
   begin
      Build_Fixture (Root);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "a.txt", Ada.Directories.Compose (Root, "a.txt"));
      Editor.Project.Add_Known_File
        (Project, "b.txt", Ada.Directories.Compose (Root, "b.txt"));

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Editor.Project_Search.Set_Selected_Result_Index (Search, 2);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);

      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 2,
              "rerun should preserve the selected path+line when it still exists");

      Write_Bytes
        (Ada.Directories.Compose (Root, "a.txt"),
         "Alpha needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "rerun should select the first result when the previous path+line disappears");

      Cleanup_Fixture (Root);
   end Test_Rerun_Preserves_Selection_By_Path_Line;


   procedure Test_Search_Options_Filter_And_Clear_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("options_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
      Valid   : Boolean := False;
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "src.adb"), "Execute_Command");
      Write_Bytes (Ada.Directories.Compose (Root, "test_executor.adb"), "Execute_Command");
      Write_Bytes (Ada.Directories.Compose (Root, "readme.md"), "Execute_Command");
      Write_Bytes (Ada.Directories.Compose (Root, "data.cfg"), "Execute_Command");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "src/editor-executor.adb", Ada.Directories.Compose (Root, "src.adb"));
      Editor.Project.Add_Known_File
        (Project, "tests/test_executor.adb", Ada.Directories.Compose (Root, "test_executor.adb"));
      Editor.Project.Add_Known_File
        (Project, "README.md", Ada.Directories.Compose (Root, "readme.md"));
      Editor.Project.Add_Known_File
        (Project, "misc/data.cfg", Ada.Directories.Compose (Root, "data.cfg"));

      Editor.Project_Search.Set_Query (Search, "execute_command");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 4,
              "default Project Search should be case-insensitive over all known files");
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 4,
              "default eligible count should include all known files");

      Editor.Project_Search.Set_Path_Scope (Search, "src", Valid);
      Assert (Valid and then Editor.Project_Search.Path_Scope (Search) = "src/",
              "path scope should normalize project-relative directory prefixes");
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0,
              "changing path scope should clear stale results and selection");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then Editor.Project_Search.Eligible_File_Count (Search) = 1,
              "scoped search should read only eligible scoped files");

      Editor.Project_Search.Set_Path_Scope (Search, "..", Valid);
      Assert (not Valid and then Editor.Project_Search.Path_Scope (Search) = "src/",
              "invalid path scope should be rejected without mutating scope");

      Editor.Project_Search.Clear_Path_Scope (Search);
      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Assert (Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_Ada,
              "kind next should move All to Ada deterministically");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 2,
              "Ada kind should include .adb/.ads known project files only");
      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 1,
              "Tests kind should include test paths and test-named files");
      Editor.Project_Search.Clear_File_Kind_Filter (Search);
      Assert (Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_All,
              "kind clear should reset Project Search kind to all");

      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "case-sensitive mode should distinguish query case");
      Editor.Project_Search.Set_Case_Sensitive (Search, False);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 4,
              "clearing case-sensitive mode should restore insensitive matching");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "src.adb"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "test_executor.adb"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "readme.md"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "data.cfg"));
      Remove_Dir_If_Exists (Root);
   end Test_Search_Options_Filter_And_Clear_Results;



   procedure Test_Summary_Counts_And_Skips
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("summary_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "ok.txt"), "needle");
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
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);

      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "match count should equal result rows");
      Assert (Editor.Project_Search.Files_With_Matches (Search) = 1,
              "matched-file count should equal unique result files");
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 3,
              "eligible count should include scoped known files before skips");
      Assert (Editor.Project_Search.Files_Searched (Search) = 1,
              "searched count should exclude skipped missing/large files");
      Assert (Editor.Project_Search.Skipped_File_Count (Search) = 2,
              "skipped count should aggregate skipped categories");
      Assert (Editor.Project_Search.Skipped_Missing_Count (Search) = 1
              and then Editor.Project_Search.Skipped_Large_Count (Search) = 1,
              "skipped categories should remain individually inspectable");
      Assert (Editor.Project_Search.Last_Run_Query (Search) = "needle",
              "summary query should track the last successful active Find query");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "large.txt"));
      Remove_Dir_If_Exists (Root);
   end Test_Summary_Counts_And_Skips;

   procedure Test_Noop_And_Precondition_Preserve_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("atomic_root");
      Project : Editor.Project.Project_State;
      Empty_Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
   begin
      Cleanup_Fixture (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "ok.txt"), "needle");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Editor.Project.Add_Known_File
        (Project, "ok.txt", Ada.Directories.Compose (Root, "ok.txt"));

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "fixture search should produce one result");

      Editor.Project_Search.Clear_Path_Scope (Search);
      Editor.Project_Search.Clear_File_Kind_Filter (Search);
      Editor.Project_Search.Set_Case_Sensitive (Search, False);
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then Editor.Project_Search.Last_Run_Query (Search) = "needle",
              "no-op option clears should preserve current results and summary");

      Editor.Project_Search.Search_Known_Project_Files
        (Search, Empty_Project, Options);
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_No_Project,
              "no-project precondition should report No_Project");
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then Editor.Project_Search.Last_Run_Query (Search) = "needle",
              "same-query precondition failure should not partially replace previous summary/results");

      Editor.Project_Search.Set_Query (Search, "");
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "actual query changes should clear stale summary/results before a later run");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok.txt"));
      Remove_Dir_If_Exists (Root);
   end Test_Noop_And_Precondition_Preserve_Summary;

   procedure Test_Match_Columns_And_Previews
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("preview_root");
      File    : constant String := Ada.Directories.Compose (Root, "long.txt");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Early   : Editor.Project_Search.Project_Search_Result;
      Middle  : Editor.Project_Search.Project_Search_Result;
      Late    : Editor.Project_Search.Project_Search_Result;
      Control : Editor.Project_Search.Project_Search_Result;
      Long_Prefix : constant String (1 .. 80) := (others => 'A');
      Long_Suffix : constant String (1 .. 200) := (others => 'B');
   begin
      Remove_File_If_Exists (File);
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (File,
         "needle" & Long_Suffix & ASCII.LF
         & Long_Prefix & "needle" & Long_Suffix & ASCII.LF
         & Long_Suffix & "needle" & ASCII.LF
         & ASCII.ESC & " needle");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Assert (Editor.Project_Search.Find_Literal_Match_Column
                ("  Execute_Command (Ctx);", "Execute_Command", True) = 3
              and then Editor.Project_Search.Find_Literal_Match_Column
                ("  Execute_Command (Ctx);", "execute_command", False) = 3
              and then Editor.Project_Search.Find_Literal_Match_Column
                ("needle needle", "needle", True) = 1
              and then Editor.Project_Search.Find_Literal_Match_Column
                ("  Execute_Command (Ctx);", "execute_command", True) = 0,
              "literal match helper should return one-based first-match columns with correct case policy");

      declare
         Repeat_Line : constant String := "needle x needle";
         Repeat_Preview : constant String :=
           Editor.Project_Search.Build_Project_Search_Line_Preview
             (Repeat_Line, 10, 6, Editor.Project_Search.Max_Search_Result_Preview_Length);
         Repeat_Start : Natural := 0;
         Repeat_Length : Natural := 0;
      begin
         Editor.Project_Search.Build_Project_Search_Preview_Match_Range
           (Line                 => Repeat_Line,
            Match_Column         => 10,
            Match_Length         => 6,
            Preview              => Repeat_Preview,
            Preview_Match_Start  => Repeat_Start,
            Preview_Match_Length => Repeat_Length);
         Assert (Repeat_Start = 10 and then Repeat_Length = 6,
                 "repeated same-line matches should highlight the selected occurrence, not the first identical text");
      end;

      Assert (Editor.Project_Search.Result_Count (Search) = 4,
              "preview fixture should produce one result per matching line");

      Early := Editor.Project_Search.Result_At (Search, 1);
      Middle := Editor.Project_Search.Result_At (Search, 2);
      Late := Editor.Project_Search.Result_At (Search, 3);
      Control := Editor.Project_Search.Result_At (Search, 4);

      Assert (Early.Match_Column = 1
              and then Early.Start_Column = 0
              and then Early.Preview_Match_Start = 1,
              "early match should store one-based match column and preview start");
      Assert (To_String (Early.Line_Preview)'Length <=
                Editor.Project_Search.Max_Search_Result_Preview_Length
              and then To_String (Early.Line_Preview)
                (To_String (Early.Line_Preview)'Last - 2 .. To_String (Early.Line_Preview)'Last) = "...",
              "early long preview should trim trailing text deterministically");

      Assert (Middle.Match_Column = 81
              and then Ada.Strings.Fixed.Index (To_String (Middle.Line_Preview), "needle") > 0
              and then To_String (Middle.Line_Preview)'Length <=
                Editor.Project_Search.Max_Search_Result_Preview_Length,
              "middle long preview should remain bounded and contain the match");
      Assert (To_String (Middle.Line_Preview)
                (To_String (Middle.Line_Preview)'First .. To_String (Middle.Line_Preview)'First + 2) = "..."
              and then To_String (Middle.Line_Preview)
                (To_String (Middle.Line_Preview)'Last - 2 .. To_String (Middle.Line_Preview)'Last) = "...",
              "middle long preview should mark both omitted sides");

      Assert (Late.Match_Column = 201
              and then To_String (Late.Line_Preview)
                (To_String (Late.Line_Preview)'First .. To_String (Late.Line_Preview)'First + 2) = "..."
              and then Ada.Strings.Fixed.Index (To_String (Late.Line_Preview), "needle") > 0,
              "late long preview should trim leading text and preserve the match");

      Assert (Ada.Strings.Fixed.Index (To_String (Control.Line_Preview), String'(1 => ASCII.ESC)) = 0
              and then Ada.Strings.Fixed.Index (To_String (Control.Line_Preview), "? needle") > 0,
              "preview sanitization should replace non-printable control characters deterministically");

      Editor.Project_Search.Set_Query (Search, "other");
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "query changes should clear result previews and summary metadata together");

      Remove_File_If_Exists (File);
      Remove_Dir_If_Exists (Root);
   end Test_Match_Columns_And_Previews;


   procedure Test_Query_Run_Navigate_And_Cleanup_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("workflow_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
      Valid   : Boolean := False;
      First_Id : Editor.Project_Search.Project_Search_Result_Id;
      Last_Id  : Editor.Project_Search.Project_Search_Result_Id;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "executor_body.adb"),
                   "procedure Executor is" & ASCII.LF & "begin" & ASCII.LF & "   Run_Executor;" & ASCII.LF & "end;");
      Write_Bytes (Ada.Directories.Compose (Root, "executor_spec.ads"),
                   "package Executor is" & ASCII.LF & "end Executor;");
      Write_Bytes (Ada.Directories.Compose (Root, "test_executor.adb"),
                   "procedure Test_Executor is begin null; end Test_Executor;");
      Write_Bytes (Ada.Directories.Compose (Root, "executor.md"),
                   "Executor documentation" & ASCII.LF & "executor usage");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "src/editor/executor.adb", Ada.Directories.Compose (Root, "executor_body.adb"));
      Add_Known (Project, "src/editor/executor.ads", Ada.Directories.Compose (Root, "executor_spec.ads"));
      Add_Known (Project, "tests/test_executor.adb", Ada.Directories.Compose (Root, "test_executor.adb"));
      Add_Known (Project, "docs/executor.md", Ada.Directories.Compose (Root, "executor.md"));

      Editor.Project_Search.Set_Query (Search, "executor");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 8,
              "workflow run should collect all current literal result rows");
      Assert (Editor.Project_Search.Files_With_Matches (Search) = 4,
              "workflow run should count unique matched files");
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "workflow run should select the first result");
      Assert_Project_Search_Coherent (Search, "initial workflow search");

      First_Id := Editor.Project_Search.Result_At (Search, 1).Id;
      Last_Id := Editor.Project_Search.Result_At (Search, 8).Id;
      Editor.Project_Search.Move_Selected_Result (Search, Editor.Project_Search.Previous_Result, True);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 8
              and then Editor.Project_Search.Result_At (Search, 8).Id = Last_Id,
              "previous from first should wrap to the last structured result");
      Editor.Project_Search.Move_Selected_Result (Search, Editor.Project_Search.Next_Result, True);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1
              and then Editor.Project_Search.Result_At (Search, 1).Id = First_Id,
              "next from last should wrap back to the first structured result");
      Editor.Project_Search.Select_Last_Result (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 8,
              "last navigation should select the current boundary result");
      Editor.Project_Search.Select_First_Result (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "first navigation should select the current boundary result");
      Assert_Project_Search_Coherent (Search, "after navigation");

      Editor.Project_Search.Set_Query (Search, "Test_Executor");
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "actual query changes should clear results, selection, and summary");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2
              and then To_String (Editor.Project_Search.Result_At (Search, 1).Relative_Path) = "tests/test_executor.adb",
              "rerun after query change should replace results atomically");
      Assert_Project_Search_Coherent (Search, "after query rerun");

      Editor.Project_Search.Toggle_Case_Sensitive (Search);
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Case_Sensitive (Search),
              "actual case option changes should clear stale results without running search");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "case-sensitive rerun should use current query and options");

      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Assert (Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_Ada
              and then Editor.Project_Search.Result_Count (Search) = 0,
              "kind option changes should clear stale results without running search");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2
              and then Editor.Project_Search.Eligible_File_Count (Search) = 3,
              "Ada-kind rerun should search only Ada eligible files");

      Editor.Project_Search.Set_Path_Scope (Search, "src/editor", Valid);
      Assert (Valid and then Editor.Project_Search.Path_Scope (Search) = "src/editor/"
              and then Editor.Project_Search.Result_Count (Search) = 0,
              "scope option changes should normalize scope and clear stale results");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Eligible_File_Count (Search) = 2,
              "scoped case-sensitive rerun should use combined current options");
      Assert_Project_Search_Coherent (Search, "after scoped option workflow");

      Remove_Tree_If_Exists (Root);
   end Test_Query_Run_Navigate_And_Cleanup_Workflow;

   procedure Test_Scoped_Kind_Case_And_Independence_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("scoped_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
      Valid   : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "executor_body.adb"), "Executor" & ASCII.LF & "executor");
      Write_Bytes (Ada.Directories.Compose (Root, "executor_spec.ads"), "Executor spec");
      Write_Bytes (Ada.Directories.Compose (Root, "test_executor.adb"), "executor test");
      Write_Bytes (Ada.Directories.Compose (Root, "executor.md"), "Executor docs");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "src/editor/executor.adb", Ada.Directories.Compose (Root, "executor_body.adb"));
      Add_Known (Project, "src/editor/executor.ads", Ada.Directories.Compose (Root, "executor_spec.ads"));
      Add_Known (Project, "tests/test_executor.adb", Ada.Directories.Compose (Root, "test_executor.adb"));
      Add_Known (Project, "docs/executor.md", Ada.Directories.Compose (Root, "executor.md"));

      Editor.Project_Search.Set_Query (Search, "executor");
      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Editor.Project_Search.Set_Path_Scope (Search, "src", Valid);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 2
              and then Editor.Project_Search.Files_Searched (Search) = 2
              and then Editor.Project_Search.Result_Count (Search) = 3,
              "Ada+src+insensitive search should search only eligible source files");
      Assert_Project_Search_Coherent (Search, "Ada src scoped search");

      Editor.Project_Search.Clear_Path_Scope (Search);
      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_Tests
              and then Editor.Project_Search.Eligible_File_Count (Search) = 1
              and then Editor.Project_Search.Result_Count (Search) = 1
              and then To_String (Editor.Project_Search.Result_At (Search, 1).Relative_Path) = "tests/test_executor.adb",
              "Tests kind should be independent from earlier source scope state");

      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_Docs
              and then Editor.Project_Search.Eligible_File_Count (Search) = 1
              and then Editor.Project_Search.Result_Count (Search) = 0,
              "Docs + case-sensitive search should distinguish query case");

      Editor.Project_Search.Set_Query (Search, "Executor");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then To_String (Editor.Project_Search.Result_At (Search, 1).Relative_Path) = "docs/executor.md",
              "Docs + case-sensitive rerun should match exact-case docs only");

      Editor.Project_Search.Set_Path_Scope (Search, "tests", Valid);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 0
              and then Editor.Project_Search.Result_Count (Search) = 0,
              "kind and path scope should combine rather than falling back to Quick Open state");
      Assert (Editor.Project.Known_File_Count (Project) = 4,
              "Project Search option workflows must not mutate the known project file list");

      Remove_Tree_If_Exists (Root);
   end Test_Scoped_Kind_Case_And_Independence_Counts;

   procedure Test_Selected_Directory_Scope_And_Refresh_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("scope_refresh_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
      Found   : Boolean := False;
      Valid   : Boolean := False;
      Dir     : Unbounded_String := Null_Unbounded_String;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "executor_body.adb"), "needle");
      Write_Bytes (Ada.Directories.Compose (Root, "other.adb"), "needle");
      Write_Bytes (Ada.Directories.Compose (Root, "readme.md"), "needle");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "src/editor/executor.adb", Ada.Directories.Compose (Root, "executor_body.adb"));
      Add_Known (Project, "src/other/other.adb", Ada.Directories.Compose (Root, "other.adb"));
      Add_Known (Project, "README.md", Ada.Directories.Compose (Root, "readme.md"));

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 3,
              "selected-directory fixture should start with all results");
      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "src/editor/executor.adb");
      Assert (Found, "fixture should select a source result");

      Dir := To_Unbounded_String (Editor.Project_Search.Selected_Result_Directory (Search, Found));
      Editor.Project_Search.Set_Path_Scope (Search, To_String (Dir), Valid);
      Assert (Found and then Valid
              and then Editor.Project_Search.Path_Scope (Search) = "src/editor/"
              and then Editor.Project_Search.Query (Search) = "needle"
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "scope-from-selected-directory should preserve query/options and clear results only");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then To_String (Editor.Project_Search.Result_At (Search, 1).Relative_Path) = "src/editor/executor.adb",
              "rerun after selected-directory scope should search only that directory");

      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "README.md");
      Assert (not Found,
              "scoped result list should not expose root-level stale results");
      Editor.Project_Search.Clear_Path_Scope (Search);
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path (Search, "README.md");
      Dir := To_Unbounded_String (Editor.Project_Search.Selected_Result_Directory (Search, Found));
      Editor.Project_Search.Set_Path_Scope (Search, To_String (Dir), Valid);
      Assert (Found and then Valid
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.Result_Count (Search) = 0,
              "root-level selected result should clear the path scope and stale results");

      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Editor.Project_Search.Clear_Results_Preserve_Query (Search);
      Assert (Editor.Project_Search.Query (Search) = "needle"
              and then Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_All
              and then not Editor.Project_Search.Case_Sensitive (Search)
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "refresh cleanup policy should preserve query/options while clearing stale results and summary");

      Remove_Tree_If_Exists (Root);
   end Test_Selected_Directory_Scope_And_Refresh_Cleanup;

   procedure Test_Stale_Skipped_Truncated_And_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("stale_root");
      Project : Editor.Project.Project_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened  : Editor.Project.Project_Open_Result;
      Stale_Result_Count : Natural := 0;
      Valid              : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "ok1.txt"), "needle one");
      Write_Bytes (Ada.Directories.Compose (Root, "ok2.txt"), "needle two");
      Write_Bytes (Ada.Directories.Compose (Root, "large.txt"), "needle too large");
      Write_Bytes (Ada.Directories.Compose (Root, "binary.bin"), "abc" & ASCII.NUL & "needle");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "ok1.txt", Ada.Directories.Compose (Root, "ok1.txt"));
      Add_Known (Project, "ok2.txt", Ada.Directories.Compose (Root, "ok2.txt"));
      Add_Known (Project, "large.txt", Ada.Directories.Compose (Root, "large.txt"));
      Add_Known (Project, "binary.bin", Ada.Directories.Compose (Root, "binary.bin"));
      Add_Known (Project, "missing.txt", Ada.Directories.Compose (Root, "missing.txt"));

      Options.Max_File_Size_Bytes := 20;
      Options.Max_Result_Count := 1;
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1
              and then Editor.Project_Search.Was_Truncated (Search)
              and then Editor.Project_Search.Matches_Truncated_Count (Search) > 0,
              "match-limit workflow should collect valid rows and report truncation");
      Assert_Project_Search_Coherent (Search, "truncated result state");

      Stale_Result_Count := Editor.Project_Search.Result_Count (Search);
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "ok1.txt"));
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Skipped_Missing_Count (Search) >= 1
              and then Editor.Project.Known_File_Count (Project) = 5,
              "rerun with stale known files should skip, not prune or refresh, known files");
      Assert (Editor.Project_Search.Result_Count (Search) <= Stale_Result_Count,
              "stale rerun should atomically replace results under current limits");

      Options.Max_Result_Count := 10;
      Options.Max_File_Size_Bytes := 4;
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Skipped_Missing_Count (Search) >= 1
              and then Editor.Project_Search.Skipped_Large_Count (Search) >= 3,
              "skipped-file workflow should account for stale and large files without hard failure");
      Assert_Project_Search_Coherent (Search, "skipped result state");

      Editor.Project_Search.Set_Query (Search, "other");
      Assert (Editor.Project_Search.Skipped_File_Count (Search) = 0
              and then not Editor.Project_Search.Was_Truncated (Search)
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "option/query cleanup should clear skipped and truncated summary state");

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Editor.Project_Search.Set_Path_Scope (Search, "src/editor", Valid);
      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Cycle_File_Kind_Filter (Search, True);
      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = ""
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.File_Kind_Filter (Search) =
                Editor.Project_Search.Project_Search_Kind_All
              and then not Editor.Project_Search.Case_Sensitive (Search)
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = "",
              "project lifecycle clear should reset all transient Project Search state");

      Remove_Tree_If_Exists (Root);
   end Test_Stale_Skipped_Truncated_And_Lifecycle_Cleanup;

   procedure Test_Retained_Source_Lifecycle_Observation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Path ("retained_sources");
      Src           : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path    : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path     : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Copy_Target   : constant String := Ada.Directories.Compose (Src, "alpha_copy.adb");
      Rename_Target : constant String := Ada.Directories.Compose (Src, "beta_renamed.adb");
      S             : Editor.State.State_Type;
      Opened        : Editor.Project.Project_Open_Result;
      Options       : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found         : Boolean := False;
      Alpha_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta_Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Alpha_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;
      Assert (Alpha_Id /= Editor.Buffers.No_Buffer
              and then Beta_Id /= Editor.Buffers.No_Buffer
              and then Alpha_Id /= Beta_Id,
              "setup should create distinct canonical open buffers");

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "setup should search retained known project files only");
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/alpha.adb")
              and then Project_Search_Has_Result_Path (S.Project_Search, "src/beta.adb"),
              "setup should expose retained searchable source paths");

      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found,
              "setup should select an inactive Project Search result");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta_Id,
              "selected search result must not replace canonical active buffer");

      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (S, Editor.Commands.Command_Copy_Buffer_File, Copy_Target);
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert_Project_Search_File_Lifecycle_Observation_Coherent
        (S.Project_Search, "src/alpha.adb", "src/alpha_copy.adb",
         "copy observation through retained searchable sources");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta_Id,
              "copy uses active buffer source, not selected search result");

      Editor.Executor.File_Target_Prompt_Commands.Execute_File_Target_Command
        (S, Editor.Commands.Command_Rename_Buffer_File, Rename_Target);
      Assert (Editor.Buffers.Global_Find_By_Path (Rename_Target, Found) = Beta_Id
              and then Found,
              "rename should update canonical active buffer association");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert_Project_Search_File_Lifecycle_Observation_Coherent
        (S.Project_Search, "src/alpha.adb", "src/beta_renamed.adb",
         "rename target must not be promoted to searchable source");
      Assert (Editor.Project_Search.Skipped_Missing_Count (S.Project_Search) >= 1,
              "stale retained known-file source is skipped, not repaired by Project Search");
      Assert (not Project_Search_Has_Result_Path (S.Project_Search, "src/beta.adb"),
              "missing pre-rename source should not be shown as recovery state after rerun");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Retained_Source_Lifecycle_Observation;

   procedure Test_Query_Selection_And_Target_Prompt_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("prompt_boundary");
      Src         : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path  : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path   : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Target_Path : constant String := Ada.Directories.Compose (Src, "beta_prompt_renamed.adb");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Options     : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found       : Boolean := False;
      Beta_Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Project_Search.Set_Query
        (S.Project_Search, "src/query-must-not-seed-target.adb");
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found,
              "setup should select a Project Search result different from active buffer");

      Editor.Executor.File_Target_Prompt_Commands.Open_File_Target_Prompt
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
              "canonical prompt opens through Executor only");
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
              "Project Search query/selection must not seed target prompt input");
      Editor.Project_Search.Move_Selection_Down (S.Project_Search);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
              "Project Search selection changes do not mutate prompt input");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Target_Path);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
              "prompt confirmation leaves no Project Search-owned prompt state");
      Assert (Editor.Buffers.Global_Find_By_Path (Target_Path, Found) = Beta_Id
              and then Found,
              "prompt confirmation uses canonical active buffer, not selected result");
      Assert (Ada.Directories.Exists (Alpha_Path),
              "selected Project Search result remains local UI state and is not renamed");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert (not Project_Search_Has_Result_Path
                (S.Project_Search, "src/query-must-not-seed-target.adb"),
              "query text must not create target history results");
      Assert (not Project_Search_Has_Result_Path
                (S.Project_Search, "src/beta_prompt_renamed.adb"),
              "prompted target must not be promoted to retained searchable source");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Query_Selection_And_Target_Prompt_Boundary;

   procedure Test_Route_Audit_Alias_And_State_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit  : Editor.Command_Route_Audit.Route_Audit_Result;
      Search : Editor.Project_Search.Project_Search_State;
      Valid  : Boolean := False;
   begin
      Assert_Absent_Command_Not_Exposed ("project.search.file.save");
      Assert_Absent_Command_Not_Exposed ("project.search.file.save-as");
      Assert_Absent_Command_Not_Exposed ("project.search.file.rename-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.delete-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.copy-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.move-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.prompt.file.save-as");
      Assert_Absent_Command_Not_Exposed ("project.search.prompt.file.rename-buffer-file");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Rename_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Copy_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "audits observe canonical file lifecycle routes without executing them");
      Assert (Editor.Command_Route_Audit.Summary (Audit)'Length > 0,
              "route audit result remains transient side-effect-free data");

      Editor.Project_Search.Set_Query (Search, "target-like-text.adb");
      Editor.Project_Search.Set_Path_Scope (Search, "src/", Valid);
      Editor.Project_Search.Mark_Stale (Search);
      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = ""
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = ""
              and then not Editor.Project_Search.Is_Stale (Search),
              "Project Search lifecycle observation state does not exist or persist in Search state");
   end Test_Route_Audit_Alias_And_State_Exclusion;



   procedure Test_Direct_Lifecycle_Observation_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root          : constant String := Temp_Path ("direct_reliable");
      Src           : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path    : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path     : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Copy_Target   : constant String := Ada.Directories.Compose (Src, "beta_copy.adb");
      Move_Target   : constant String := Ada.Directories.Compose (Src, "beta_moved.adb");
      Save_As_Path  : constant String := Ada.Directories.Compose (Src, "beta_saved_as.adb");
      S             : Editor.State.State_Type;
      Opened        : Editor.Project.Project_Open_Result;
      Options       : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found         : Boolean := False;
      Beta_Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "", "",
         "initial retained source snapshot");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Target);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/beta_copy.adb", "",
         "copy does not create Project Search lifecycle target result");
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id and then Found,
              "copy preserves canonical active-buffer association");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/beta_saved_as.adb", "src/beta_copy.adb",
         "save-as target is observed only through buffer association, not retained project sources");
      Assert (Editor.Buffers.Global_Find_By_Path (Save_As_Path, Found) = Beta_Id and then Found,
              "save-as updates only canonical buffer association");

      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Target);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/beta_moved.adb", "src/beta_saved_as.adb",
         "move target is not promoted to retained searchable source");
      Assert (Editor.Buffers.Global_Find_By_Path (Move_Target, Found) = Beta_Id and then Found,
              "move updates only canonical active-buffer association");

      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/beta_moved.adb", "src/beta_saved_as.adb",
         "delete creates no recovery, deleted-source, or target-history result");
      declare
         Deleted_Id : constant Editor.Buffers.Buffer_Id :=
           Editor.Buffers.Global_Find_By_Path (Move_Target, Found);
      begin
         pragma Unreferenced (Deleted_Id);
         Assert (not Found,
                 "delete clears canonical active-buffer association before Project Search observes again");
      end;

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Direct_Lifecycle_Observation_Reliability;

   procedure Test_Failure_And_Blocked_Observation_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Path ("failure_preserve");
      Src          : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path   : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path    : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Missing_Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "missing"), "target.adb");
      S            : Editor.State.State_Type;
      Opened       : Editor.Project.Project_Open_Result;
      Options      : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found        : Boolean := False;
      Beta_Id      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);

      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Alpha_Path);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "", "",
         "rename target collision preserves retained Project Search results");
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id and then Found,
              "failed rename preserves canonical association");

      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Missing_Path);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "missing/target.adb", "",
         "failed move target is never displayed or stored");
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id and then Found,
              "failed move preserves canonical association");

      Editor.State.Set_Dirty (S, True);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Ada.Directories.Compose (Src, "dirty_copy.adb"));
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/dirty_copy.adb", "",
         "dirty-blocked copy/delete preserve Project Search observation");
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id and then Found,
              "dirty-blocked operations preserve canonical active-buffer source");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Failure_And_Blocked_Observation_Preservation;

   procedure Test_Query_Selection_And_Prompt_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("prompt_reliable");
      Src         : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path  : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path   : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Alpha_New   : constant String := Ada.Directories.Compose (Src, "alpha_prompt_renamed.adb");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Options     : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found       : Boolean := False;
      Alpha_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta_Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle target-like-text" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Alpha_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Project_Search.Set_Query (S.Project_Search, "target-like-text");
      Rerun_Project_Search (S, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found,
              "setup selects a target-like Project Search result");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta_Id,
              "selected Project Search result does not become active buffer");

      Editor.Executor.File_Target_Prompt_Commands.Open_File_Target_Prompt
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
              "query/result text must not seed prompt input");
      Editor.Project_Search.Move_Selection_Down (S.Project_Search);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Alpha_Id);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Alpha_New);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);

      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
              "prompt confirmation leaves prompt state canonical and transient");
      Assert (Editor.Buffers.Global_Find_By_Path (Alpha_New, Found) = Alpha_Id and then Found,
              "prompt confirmation uses active buffer at confirmation time");
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id and then Found,
              "selected/query Project Search state does not redirect file lifecycle source");
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/beta.adb", "", "src/alpha_prompt_renamed.adb", "target-like-text",
         "prompted target and query text remain outside retained Project Search sources");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Query_Selection_And_Prompt_Reliability;

   procedure Test_Route_Audit_And_Persistence_State_Exclusion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Audit  : Editor.Command_Route_Audit.Route_Audit_Result;
      Search : Editor.Project_Search.Project_Search_State;
      Valid  : Boolean := False;
   begin
      Assert_Absent_Command_Not_Exposed ("project.search.file.reload-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.revert-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.close-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.reopen-closed-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.target-history");
      Assert_Absent_Command_Not_Exposed ("project.search.file.source-override");
      Assert_Absent_Command_Not_Exposed ("project.search.file.repair-source");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Delete_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Close_Active_Buffer);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "route audit observes Executor-routed lifecycle commands without executing them");

      Editor.Project_Search.Set_Query (Search, "last-observed-rename-target.adb");
      Editor.Project_Search.Set_Path_Scope (Search, "src/", Valid);
      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Mark_Stale (Search);
      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = ""
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = ""
              and then not Editor.Project_Search.Case_Sensitive (Search)
              and then not Editor.Project_Search.Is_Stale (Search),
              "Project Search has no lifecycle observation cache, target history, dirty cache, or persistence field to restore");
   end Test_Route_Audit_And_Persistence_State_Exclusion;


   procedure Test_Canonical_Ownership_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("canonical_cleanup");
      Src        : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path  : constant String := Ada.Directories.Compose (Src, "beta.adb");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Options    : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_File_Lifecycle_Observation_Canonical
        (S.Project_Search, "retained-source snapshot");
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb", "src/copy.adb",
         "src/moved.adb",
         "result derivation is retained-source only");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Canonical_Ownership_Cleanup;

   procedure Test_Query_Selection_Prompt_Source_Target_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("prompt_cleanup");
      Src         : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path  : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path   : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Rename_Path : constant String := Ada.Directories.Compose (Src, "renamed_by_prompt.adb");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Options     : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found       : Boolean := False;
      Alpha_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta_Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha target-like-text needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Alpha_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Project_Search.Set_Query (S.Project_Search, "target-like-text");
      Rerun_Project_Search (S, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found, "selects a target-looking Project Search row");
      Assert_Project_Search_File_Lifecycle_Observation_Canonical
        (S.Project_Search, "selected result remains canonical");

      Editor.Executor.File_Target_Prompt_Commands.Open_File_Target_Prompt
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
              "Project Search query/result does not seed target prompt");
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Rename_Path);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);

      Assert (Editor.Buffers.Global_Find_By_Path (Rename_Path, Found) = Beta_Id
              and then Found,
              "prompt confirmation uses canonical active buffer source");
      Assert (Editor.Buffers.Global_Find_By_Path (Alpha_Path, Found) = Alpha_Id
              and then Found,
              "selected Project Search result is not lifecycle source");

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "", "src/renamed_by_prompt.adb",
         "target-like-text",
         "prompted target/query are not retained Project Search sources");
      Assert_Project_Search_File_Lifecycle_Observation_Canonical
        (S.Project_Search, "after prompt confirmation cleanup");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Query_Selection_Prompt_Source_Target_Cleanup;

   procedure Test_Route_Audit_And_Persistence_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search : Editor.Project_Search.Project_Search_State;
      Valid  : Boolean := False;
      Audit  : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Assert_Absent_Command_Not_Exposed ("project.search.file.save");
      Assert_Absent_Command_Not_Exposed ("project.search.file.save-as");
      Assert_Absent_Command_Not_Exposed ("project.search.file.rename-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.delete-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.copy-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.move-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.prompted-rename");
      Assert_Absent_Command_Not_Exposed ("project.search.file.prompted-copy");
      Assert_Absent_Command_Not_Exposed ("project.search.file.prompted-move");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit, Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit, Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "lifecycle commands still route through Executor-facing ids");

      Editor.Project_Search.Set_Query (Search, "rename-target-cache");
      Editor.Project_Search.Set_Path_Scope (Search, "src/", Valid);
      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Mark_Stale (Search);
      Assert_Project_Search_File_Lifecycle_Observation_Canonical
        (Search, "configured transient state has no lifecycle cache");
      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = ""
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = ""
              and then not Editor.Project_Search.Case_Sensitive (Search)
              and then not Editor.Project_Search.Is_Stale (Search),
              "clear drops all transient state and has no persistence-adjacent lifecycle fields");
      Assert_Project_Search_File_Lifecycle_Observation_Canonical
        (Search, "cleared state canonical");
   end Test_Route_Audit_And_Persistence_Cleanup;


   function Snapshot_Match_Row_For_Path
     (Snapshot : Editor.Search_Results.Search_Results_Snapshot;
      Path     : String;
      Found    : out Boolean) return Editor.Search_Results.Search_Results_Row
   is
      Row : Editor.Search_Results.Search_Results_Row;
   begin
      Found := False;
      for I in 1 .. Editor.Search_Results.Row_Count (Snapshot) loop
         Row := Editor.Search_Results.Row (Snapshot, I);
         if Row.Kind = Editor.Search_Results.Search_Results_Match_Row
           and then To_String (Row.Project_Relative_Path) = Path
         then
            Found := True;
            return Row;
         end if;
      end loop;
      return (others => <>);
   end Snapshot_Match_Row_For_Path;

   procedure Test_Canonical_Source_And_Render_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Path ("source_render_freeze");
      Src          : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path   : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path    : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Save_As_Path : constant String := Ada.Directories.Compose (Src, "beta_saved_as.adb");
      S            : Editor.State.State_Type;
      Opened       : Editor.Project.Project_Open_Result;
      Options      : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Snapshot_Before : Editor.Search_Results.Search_Results_Snapshot;
      Snapshot_Dirty  : Editor.Search_Results.Search_Results_Snapshot;
      Snapshot_After  : Editor.Search_Results.Search_Results_Snapshot;
      Row             : Editor.Search_Results.Search_Results_Row;
      Found           : Boolean := False;
      Beta_Id         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found, "setup selects retained alpha result");
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb",
         "src/beta_saved_as.adb", "src/beta_copy.adb",
         "retained source freeze before operation");
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (S.Project_Search, "retained source canonical freeze");

      Snapshot_Before := Editor.Search_Results.Build_Snapshot
        (S.Project_Search, (others => <>), Editor.Buffers.Global_Registry_For_UI);
      Row := Snapshot_Match_Row_For_Path (Snapshot_Before, "src/beta.adb", Found);
      Assert (Found, "render snapshot exposes retained beta match");
      Assert (Row.Is_Open and then Row.Is_Active and then not Row.Is_Dirty,
              "open/active/dirty markers derive from canonical buffer state");
      Assert (not Row.Is_Selected,
              "selection marker derives only from Project Search selection");

      Editor.State.Set_Dirty (S, True);
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Snapshot_Dirty := Editor.Search_Results.Build_Snapshot
        (S.Project_Search, (others => <>), Editor.Buffers.Global_Registry_For_UI);
      Row := Snapshot_Match_Row_For_Path (Snapshot_Dirty, "src/beta.adb", Found);
      Assert (Found and then Row.Is_Dirty,
              "dirty marker derives from current buffer dirty state only");
      Row := Snapshot_Match_Row_For_Path (Snapshot_Before, "src/beta.adb", Found);
      Assert (Found and then not Row.Is_Dirty,
              "stale render snapshot is not repaired by mutation");

      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Path);
      Assert (Editor.Buffers.Global_Find_By_Path (Save_As_Path, Found) = Beta_Id
              and then Found,
              "save-as updates canonical active-buffer association");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "src/beta.adb",
         "src/beta_saved_as.adb", "src/beta_copy.adb",
         "save-as target is not promoted to retained searchable source");
      Snapshot_After := Editor.Search_Results.Build_Snapshot
        (S.Project_Search, (others => <>), Editor.Buffers.Global_Registry_For_UI);
      Row := Snapshot_Match_Row_For_Path (Snapshot_After, "src/beta.adb", Found);
      Assert (Found and then not Row.Is_Open and then not Row.Is_Active and then not Row.Is_Dirty,
              "fresh render markers follow current association, not stale path cache");
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (S.Project_Search, "render/source final freeze after save-as");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Canonical_Source_And_Render_Final_Freeze;

   procedure Test_Operation_Query_Selection_Prompt_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("operation_prompt_freeze");
      Src         : constant String := Ada.Directories.Compose (Root, "src");
      Alpha_Path  : constant String := Ada.Directories.Compose (Src, "alpha.adb");
      Beta_Path   : constant String := Ada.Directories.Compose (Src, "beta.adb");
      Copy_Path   : constant String := Ada.Directories.Compose (Src, "beta_copy.adb");
      Move_Path   : constant String := Ada.Directories.Compose (Src, "beta_moved.adb");
      Rename_Path : constant String := Ada.Directories.Compose (Src, "alpha_prompt_renamed.adb");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Options     : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Found       : Boolean := False;
      Alpha_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta_Id     : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha needle target-like-text" & ASCII.LF);
      Write_Bytes (Beta_Path, "beta needle" & ASCII.LF);

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "src/alpha.adb", Alpha_Path);
      Add_Known (S.Project, "src/beta.adb", Beta_Path);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Alpha_Path);
      Alpha_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Beta_Path);
      Beta_Id := Editor.Buffers.Global_Active_Buffer;

      Editor.Project_Search.Set_Query (S.Project_Search, "target-like-text");
      Rerun_Project_Search (S, Options);
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/alpha.adb");
      Assert (Found, "selects a target-like retained Project Search result");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta_Id,
              "selected Project Search result does not override active buffer");

      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Path);
      Assert (Editor.Buffers.Global_Find_By_Path (Beta_Path, Found) = Beta_Id
              and then Found,
              "direct copy preserves canonical active-buffer association");
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Path);
      Assert (Editor.Buffers.Global_Find_By_Path (Move_Path, Found) = Beta_Id
              and then Found,
              "direct move updates only canonical active-buffer association");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "src/alpha.adb", "", "src/beta_copy.adb",
         "src/beta_moved.adb",
         "direct copy/move targets never become Project Search sources");
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (S.Project_Search, "direct explicit-target observation frozen");

      Editor.Executor.File_Target_Prompt_Commands.Open_File_Target_Prompt
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Input_Text (S) = "",
              "query/result/display text does not seed prompt input");
      Editor.Project_Search.Move_Selection_Down (S.Project_Search);
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Alpha_Id);
      Editor.Executor.File_Target_Prompt_Commands.Insert_File_Target_Prompt_Text (S, Rename_Path);
      Editor.Executor.File_Target_Prompt_Commands.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Commands.File_Target_Prompt_Is_Active (S),
              "prompt state remains canonical and transient");
      Assert (Editor.Buffers.Global_Find_By_Path (Rename_Path, Found) = Alpha_Id
              and then Found,
              "prompted rename uses active buffer at confirmation time");
      Assert (Editor.Buffers.Global_Find_By_Path (Move_Path, Found) = Beta_Id
              and then Found,
              "Project Search selection does not become lifecycle source");

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Rerun_Project_Search (S, Options);
      Assert_Project_Search_Result_Set_Unchanged
        (S.Project_Search, "", "", "src/alpha_prompt_renamed.adb",
         "src/beta_moved.adb",
         "prompted/direct target paths are not retained Project Search sources");
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (S.Project_Search, "prompted observation final freeze");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Operation_Query_Selection_Prompt_Final_Freeze;

   procedure Test_Route_Audit_Lifecycle_Persistence_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search : Editor.Project_Search.Project_Search_State;
      Audit  : Editor.Command_Route_Audit.Route_Audit_Result;
      Valid  : Boolean := False;
   begin
      Assert_Absent_Command_Not_Exposed ("project.search.file.save");
      Assert_Absent_Command_Not_Exposed ("project.search.file.save-as");
      Assert_Absent_Command_Not_Exposed ("project.search.file.rename-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.delete-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.copy-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.move-buffer-file");
      Assert_Absent_Command_Not_Exposed ("project.search.file.reload-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.revert-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.close-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.reopen-closed-buffer");
      Assert_Absent_Command_Not_Exposed ("project.search.file.target-history");
      Assert_Absent_Command_Not_Exposed ("project.search.file.operation-history");
      Assert_Absent_Command_Not_Exposed ("project.search.file.source-override");
      Assert_Absent_Command_Not_Exposed ("project.search.file.repair-source");
      Assert_Absent_Command_Not_Exposed ("project.search.file.import-quick-open");
      Assert_Absent_Command_Not_Exposed ("project.search.file.import-open-buffer-switcher");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit, Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit, Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Move_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit, Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Reopen_Closed_Buffer);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "audits inspect canonical Executor-routed command ids only");

      Editor.Project_Search.Set_Query (Search, "last-save-as-target prompt-cache dirty-cache source-override");
      Editor.Project_Search.Set_Path_Scope (Search, "src/", Valid);
      Editor.Project_Search.Set_Case_Sensitive (Search, True);
      Editor.Project_Search.Mark_Stale (Search);
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (Search, "configured transient Project Search state has no lifecycle ownership");
      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Query (Search) = ""
              and then Editor.Project_Search.Path_Scope (Search) = ""
              and then Editor.Project_Search.Selected_Result_Index (Search) = 0
              and then Editor.Project_Search.Result_Count (Search) = 0
              and then Editor.Project_Search.Last_Run_Query (Search) = ""
              and then not Editor.Project_Search.Case_Sensitive (Search)
              and then not Editor.Project_Search.Is_Stale (Search),
              "lifecycle cleanup/persistence exclusion leaves no Project Search lifecycle fields");
      Assert_Project_Search_File_Lifecycle_Observation_Frozen
        (Search, "cleared state final freeze");
   end Test_Route_Audit_Lifecycle_Persistence_Final_Freeze;

   procedure Test_Invalid_Run_Clears_Project_Search_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("invalid_run_clears");
      Project : Editor.Project.Project_State;
      Opened  : Editor.Project.Project_Open_Result;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Build_Fixture (Root);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "a.txt", Ada.Directories.Compose (Root, "a.txt"));
      Add_Known (Project, "b.txt", Ada.Directories.Compose (Root, "b.txt"));

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Result_Count (Search) > 0,
              "setup should produce real project search rows");

      Editor.Project_Search.Set_Query (Search, "");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Status (Search) =
                Editor.Project_Search.Project_Search_Empty_Query,
              "empty-query search should report the no-query state");
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "empty-query search must clear stale result rows");
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 0,
              "empty-query search must clear stale selection");

      Editor.Project.Clear (Project);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);
      Assert (Editor.Project_Search.Status (Search) =
                Editor.Project_Search.Project_Search_No_Project,
              "no-project search should report unavailable state");
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "no-project search must not retain old rows");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Invalid_Run_Clears_Project_Search_Results;


   procedure Test_Stale_Project_Search_Activation_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("stale_activation");
      S       : Editor.State.State_Type;
      Opened  : Editor.Project.Project_Open_Result;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      A       : Editor.Commands.Command_Availability;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "a.txt", Ada.Directories.Compose (Root, "a.txt"));
      Add_Known (S.Project, "b.txt", Ada.Directories.Compose (Root, "b.txt"));

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) /= 0,
              "setup should select a real result");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Available,
              "fresh selected project search result should be activatable");

      Editor.Project_Search.Mark_Stale (S.Project_Search);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "stale project search results must not activate silently");
      Assert (Editor.Commands.Unavailable_Reason (A) =
                Editor.Commands.Reason_Target_Stale,
              "stale activation should explain the stale result boundary");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_First_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "stale Project Search rows must not be reselection targets");
      Assert (Editor.Commands.Unavailable_Reason (A) =
                Editor.Commands.Reason_Target_Stale,
              "stale reselection should share the stale boundary reason");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Project_Search_Scope_Selected_Directory);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "stale Project Search rows must not seed a scope payload");
      Assert (Editor.Commands.Unavailable_Reason (A) =
                Editor.Commands.Reason_Target_Stale,
              "stale scope derivation should share the stale boundary reason");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Stale_Project_Search_Activation_Is_Unavailable;


   procedure Test_Whole_Word_Search_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("whole_word_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "words.txt"),
         "needle kneede needle_1" & ASCII.LF &
         "needles needle needle-two" & ASCII.LF &
         "pre_needlep post");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 6,
              "literal search should find every bounded non-overlapping occurrence before whole-word mode");

      Editor.Project_Search.Set_Whole_Word (Search, True);
      Assert (Editor.Project_Search.Whole_Word (Search),
              "whole-word toggle should be retained in transient search state");
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "whole-word toggle should clear stale literal rows before rerun");

      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 3,
              "whole-word search should reject substring and underscore-adjacent matches while retaining punctuation-bounded words");
      Assert_Project_Search_Coherent (Search, "whole-word search");

      Editor.Project_Search.Toggle_Whole_Word (Search);
      Assert (not Editor.Project_Search.Whole_Word (Search),
              "whole-word toggle should be reversible");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Whole_Word_Search_Mode;

   procedure Test_Include_Exclude_Path_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("path_filters_root");
      Src     : constant String := Ada.Directories.Compose (Root, "src");
      Tests   : constant String := Ada.Directories.Compose (Root, "tests");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Valid   : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Tests);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "needle in src");
      Write_Bytes (Ada.Directories.Compose (Tests, "main_tests.adb"), "needle in tests");
      Write_Bytes (Ada.Directories.Compose (Root, "README.md"), "needle in docs");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 3,
              "baseline fixture should expose all candidate files");

      Editor.Project_Search.Set_Include_Path_Filter (Search, "src", Valid);
      Assert (Valid and then Editor.Project_Search.Include_Path_Filter (Search) = "src",
              "include path filter should normalize relative substring filters");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "include path filter should narrow candidates by project-relative path");
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 1,
              "include path filter should affect eligible-file count");

      Editor.Project_Search.Clear_Include_Path_Filter (Search);
      Editor.Project_Search.Set_Exclude_Path_Filter (Search, "tests", Valid);
      Assert (Valid and then Editor.Project_Search.Exclude_Path_Filter (Search) = "tests",
              "exclude path filter should normalize relative substring filters");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "exclude path filter should remove matching project-relative paths");

      Editor.Project_Search.Set_Include_Path_Filter (Search, "/absolute", Valid);
      Assert (not Valid and then Editor.Project_Search.Include_Path_Filter (Search) = "",
              "include filter should reject absolute paths without mutating state");
      Editor.Project_Search.Set_Exclude_Path_Filter (Search, "../outside", Valid);
      Assert (not Valid and then Editor.Project_Search.Exclude_Path_Filter (Search) = "tests",
              "exclude filter should reject parent traversal without mutating state");

      Editor.Project_Search.Clear_Exclude_Path_Filter (Search);
      Assert (Editor.Project_Search.Exclude_Path_Filter (Search) = "",
              "exclude filter clear should remove transient filter text");
      Assert_Project_Search_Coherent (Search, "include/exclude path filters");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Include_Exclude_Path_Filters;

   procedure Test_Path_Filter_Wildcards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("wildcard_filters_root");
      Src     : constant String := Ada.Directories.Compose (Root, "src");
      Docs    : constant String := Ada.Directories.Compose (Root, "docs");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Valid   : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "needle in body");
      Write_Bytes (Ada.Directories.Compose (Src, "main.ads"), "needle in spec");
      Write_Bytes (Ada.Directories.Compose (Docs, "main.adb.md"), "needle in docs");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");

      Editor.Project_Search.Set_Include_Path_Filter (Search, "*.adb", Valid);
      Assert (Valid and then Editor.Project_Search.Include_Path_Filter (Search) = "*.adb",
              "wildcard include filter should retain simple '*' patterns");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "wildcard include filter should match project-relative file suffixes");

      Editor.Project_Search.Clear_Include_Path_Filter (Search);
      Editor.Project_Search.Set_Exclude_Path_Filter (Search, "docs/*", Valid);
      Assert (Valid and then Editor.Project_Search.Exclude_Path_Filter (Search) = "docs/*",
              "wildcard exclude filter should retain bounded project-relative patterns");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "wildcard exclude filter should remove matching project-relative paths");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Path_Filter_Wildcards;

   procedure Test_Path_Filter_Lists
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("filter_lists_root");
      Src     : constant String := Ada.Directories.Compose (Root, "src");
      Tests   : constant String := Ada.Directories.Compose (Root, "tests");
      Docs    : constant String := Ada.Directories.Compose (Root, "docs");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Valid   : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Tests);
      Ada.Directories.Create_Directory (Docs);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "needle in src");
      Write_Bytes (Ada.Directories.Compose (Tests, "main_tests.adb"), "needle in tests");
      Write_Bytes (Ada.Directories.Compose (Docs, "guide.md"), "needle in docs");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");

      Editor.Project_Search.Set_Include_Path_Filter
        (Search, "src; docs/*.md", Valid);
      Assert (Valid
              and then Editor.Project_Search.Include_Path_Filter (Search) = "src,docs/*.md",
              "include filter lists should normalize comma/semicolon separated entries");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 2,
              "include filter lists should match any retained project-relative pattern");
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 2,
              "include filter lists should narrow eligible candidate files");

      Editor.Project_Search.Set_Exclude_Path_Filter
        (Search, "tests,docs/*", Valid);
      Assert (Valid
              and then Editor.Project_Search.Exclude_Path_Filter (Search) = "tests,docs/*",
              "exclude filter lists should normalize comma-separated entries");
      Editor.Project_Search.Clear_Include_Path_Filter (Search);
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "exclude filter lists should remove any matching project-relative pattern");

      Editor.Project_Search.Set_Include_Path_Filter
        (Search, "src,../outside", Valid);
      Assert (not Valid and then Editor.Project_Search.Include_Path_Filter (Search) = "",
              "filter lists should reject traversal in any individual token without mutation");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Path_Filter_Lists;



   procedure Test_Tree_Search_Reports_Binary_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("tree_binary_root");
      Text_P  : constant String := Ada.Directories.Compose (Root, "text.txt");
      Bin_P   : constant String := Ada.Directories.Compose (Root, "binary.bin");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Text_P, "needle in text" & ASCII.LF);
      Write_Bytes (Bin_P, "needle" & ASCII.NUL & "hidden");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "File Tree search should keep text matches while skipping binary files");
      Assert (Editor.Project_Search.Skipped_Binary_Count (Search) = 1,
              "File Tree search should report binary/decode failures as binary skips");
      Assert (Editor.Project_Search.Read_Error_Count (Search) = 0,
              "File Tree binary files should not be collapsed into generic read errors");
      Assert (Editor.Project_Search.Files_Searched (Search) = 1,
              "File Tree binary files should not count as searched text files");
      Assert_Project_Search_Coherent (Search, "File Tree binary skip category");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Tree_Search_Reports_Binary_Files;


   procedure Test_Tree_Search_Reports_Missing_And_Large_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("tree_skips_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : Editor.Project_Search.Project_Search_Options := (others => <>);
      Missing : constant String := Ada.Directories.Compose (Root, "missing.txt");
      Large   : constant String := Ada.Directories.Compose (Root, "large.txt");
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Missing, "needle before deletion");
      Write_Bytes (Large, "needle content that exceeds the tiny test limit");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Ada.Directories.Delete_File (Missing);

      Options.Max_File_Size_Bytes := 4;
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "tree skip fixture should retain no results from missing or large files");
      Assert (Editor.Project_Search.Skipped_Missing_Count (Search) = 1,
              "File Tree-backed search should report a stale/deleted candidate as missing, not generic unreadable");
      Assert (Editor.Project_Search.Skipped_Large_Count (Search) = 1,
              "File Tree-backed search should report candidates over the bounded file-size limit as large");
      Assert (Editor.Project_Search.Read_Error_Count (Search) = 0,
              "missing/large candidates should not be collapsed into unreadable errors");
      Assert (Editor.Project_Search.Files_Searched (Search) = 0,
              "missing/large candidates should be counted as skipped, not searched");
      Assert_Project_Search_Coherent (Search, "File Tree skip categories");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Tree_Search_Reports_Missing_And_Large_Files;


   procedure Test_Buffer_Edit_Marks_Project_Search_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("edit_stale_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      S       : Editor.State.State_Type;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "main.adb"), "needle");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Search_Project
        (S.Project_Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1
              and then not Editor.Project_Search.Is_Stale (S.Project_Search),
              "edit-stale fixture should start with one fresh Project Search result");

      Editor.State.Rebuild_After_Buffer_Change (S);
      Assert (Editor.Project_Search.Is_Stale (S.Project_Search),
              "ordinary buffer edits should mark retained Project Search results stale");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Buffer_Edit_Marks_Project_Search_Stale;


   procedure Test_Command_Surface_Extends_Project_Search_Modes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      D     : Editor.Commands.Command_Descriptor;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.whole-word.toggle", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Whole_Word_Toggle,
              "whole-word toggle must have a stable no-payload command name");
      D := Editor.Commands.Descriptor (Id);
      Assert (D.Id = Id and then D.Bindable,
              "whole-word toggle must have command metadata and remain bindable");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "whole-word toggle must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.whole-word.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Whole_Word_Clear,
              "whole-word clear must have a stable no-payload command name");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "whole-word clear must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.regex.toggle", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Regex_Toggle,
              "regex toggle must have a stable no-payload command name");
      D := Editor.Commands.Descriptor (Id);
      Assert (D.Id = Id and then D.Bindable,
              "regex toggle must have command metadata and remain bindable");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "regex toggle must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.regex.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Regex_Clear,
              "regex clear must have a stable no-payload command name");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "regex clear must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.include.set", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Include_Filter_Set,
              "include-filter set must resolve as a non-keybinding explicit-text command");
      D := Editor.Commands.Descriptor (Id);
      Assert (not D.Bindable,
              "include-filter set must not be bindable because it requires explicit text");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "include-filter set must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.exclude.set", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Exclude_Filter_Set,
              "exclude-filter set must resolve as a non-keybinding explicit-text command");
      D := Editor.Commands.Descriptor (Id);
      Assert (not D.Bindable,
              "exclude-filter set must not be bindable because it requires explicit text");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "exclude-filter set must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.include.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Include_Filter_Clear,
              "include-filter clear must have a stable no-payload command name");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "include-filter clear must be classified as a search command");

      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("project.search.exclude.clear", Found);
      Assert (Found and then Id = Editor.Commands.Command_Project_Search_Exclude_Filter_Clear,
              "exclude-filter clear must have a stable no-payload command name");
      Assert (Editor.Commands.Is_Search_Command (Id),
              "exclude-filter clear must be classified as a search command");
   end Test_Command_Surface_Extends_Project_Search_Modes;


   procedure Test_Next_Previous_Available_Without_Selected_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("nav_no_selection");
      S       : Editor.State.State_Type;
      Opened  : Editor.Project.Project_Open_Result;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      A       : Editor.Commands.Command_Availability;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      Add_Known (S.Project, "a.txt", Ada.Directories.Compose (Root, "a.txt"));
      Add_Known (S.Project, "b.txt", Ada.Directories.Compose (Root, "b.txt"));

      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files
        (S.Project_Search, S.Project, Options);
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) > 0,
              "navigation setup should retain project search results");

      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, 0);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0,
              "navigation setup should allow no selected result");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Next_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Available,
              "next-result command should be available when results exist even if none is selected");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Previous_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Available,
              "previous-result command should be available when results exist even if none is selected");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Open_Selected_Project_Search_Result);
      Assert (A.Status = Editor.Commands.Command_Unavailable
              and then Editor.Commands.Unavailable_Reason (A) = "No search result selected.",
              "open-selected result should still require an actual selected result");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Next_Project_Search_Result);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "next-result should select the first retained result when none is selected");

      Editor.Project_Search.Set_Selected_Result_Index (S.Project_Search, 0);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Previous_Project_Search_Result);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) =
                Editor.Project_Search.Result_Count (S.Project_Search),
              "previous-result should wrap to the last retained result when none is selected");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Next_Previous_Available_Without_Selected_Result;




   procedure Test_Known_Project_Search_Preserves_Project_Root_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("root_bounds_root");
      Outside    : constant String := Temp_Path ("root_bounds_outside.txt");
      Inside     : constant String := Ada.Directories.Compose (Root, "inside.txt");
      Project    : Editor.Project.Project_State;
      Search     : Editor.Project_Search.Project_Search_State;
      Options    : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Opened     : Editor.Project.Project_Open_Result;
   begin
      Remove_Tree_If_Exists (Root);
      Remove_File_If_Exists (Outside);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Inside, "needle inside project");
      Write_Bytes (Outside, "needle outside project");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (Project, Opened);
      Add_Known (Project, "inside.txt", Inside);
      Add_Known (Project, "../outside.txt", Outside);
      Add_Known (Project, "external.txt", Outside);

      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Known_Project_Files (Search, Project, Options);

      Assert (Editor.Project_Search.Result_Count (Search) = 1,
              "root-bound search should retain only in-project known-file results");
      Assert (Project_Search_Has_Result_Path (Search, "inside.txt"),
              "root-bound search should keep safe project-relative files");
      Assert (not Project_Search_Has_Result_Path (Search, "../outside.txt"),
              "root-bound search must not retain traversal-relative results");
      Assert (not Project_Search_Has_Result_Path (Search, "external.txt"),
              "root-bound search must not retain absolute targets outside the project root");
      Assert (Editor.Project_Search.Eligible_File_Count (Search) = 1,
              "root-bound search should not count unsafe targets as eligible candidates");
      Assert (Editor.Project_Search.Read_Error_Count (Search) = 2,
              "root-bound search should report unsafe known-file targets as skipped read errors");
      Assert_Project_Search_Coherent (Search, "known-project root bounds");

      Remove_Tree_If_Exists (Root);
      Remove_File_If_Exists (Outside);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Remove_File_If_Exists (Outside);
         raise;
   end Test_Known_Project_Search_Preserves_Project_Root_Bounds;



   procedure Test_Regex_Project_Search_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("regex_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, "rx.txt"),
         "item-1 item-22 item-x" & ASCII.LF & "item-333");

      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "item-[0-9]+");
      Editor.Project_Search.Set_Regex_Enabled (Search, True);
      Assert (Editor.Project_Search.Regex_Enabled (Search),
              "regex mode should be retained as transient Project Search state");

      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Ok,
              "bounded regex search should complete successfully for a valid pattern");
      Assert (Editor.Project_Search.Result_Count (Search) = 3,
              "regex search should retain each non-overlapping regex match occurrence");
      Assert_Project_Search_Coherent (Search, "regex search");

      Editor.Project_Search.Set_Query (Search, "(");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Status (Search) = Editor.Project_Search.Project_Search_Invalid_Regex,
              "invalid regex should report an invalid-regex search status");
      Assert (Editor.Project_Search.Result_Count (Search) = 0,
              "invalid regex should not retain stale result rows");
      Assert (Editor.Project_Search.Regex_Error (Search)'Length > 0,
              "invalid regex should retain a useful transient error label");

      Editor.Project_Search.Clear_Regex (Search);
      Assert (not Editor.Project_Search.Regex_Enabled (Search),
              "regex mode should be clearable without persistence");

      Remove_Tree_If_Exists (Root);
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         raise;
   end Test_Regex_Project_Search_Mode;


   procedure Assert_Project_Replace_Preview_Coherent
     (Search : Editor.Project_Search.Project_Search_State;
      Label  : String)
   is
      Count    : constant Natural := Editor.Project_Search.Replace_Preview_Count (Search);
      Selected : constant Natural := Editor.Project_Search.Selected_Replace_Preview_Index (Search);
      Row      : Editor.Project_Search.Project_Replace_Preview_Row;
   begin
      if Count = 0 then
         Assert (Selected = 0,
                 Label & ": empty replacement preview should have no selected preview row");
      else
         Assert (Selected = 0 or else Selected in 1 .. Count,
                 Label & ": selected replacement preview row should be zero or valid");
      end if;

      for I in 1 .. Count loop
         Row := Editor.Project_Search.Replace_Preview_Row_At (Search, I);
         Assert (Row.Search_Result_Id /= Editor.Project_Search.No_Project_Search_Result,
                 Label & ": preview row should retain source search result id");
         Assert (Row.Row > 0,
                 Label & ": preview row should retain one-based source row");
         Assert (Row.End_Column >= Row.Start_Column,
                 Label & ": preview row should retain a sane end-exclusive range");
         Assert (Length (Row.Before_Excerpt) <=
                   Editor.Project_Search.Max_Search_Result_Preview_Length,
                 Label & ": before excerpt should be bounded");
         Assert (Length (Row.After_Excerpt) <=
                   Editor.Project_Search.Max_Search_Result_Preview_Length,
                 Label & ": after excerpt should be bounded");
         Assert (Length (Row.Replacement_Excerpt) <=
                   Editor.Project_Search.Max_Search_Result_Preview_Length,
                 Label & ": replacement excerpt should be bounded");
      end loop;
   end Assert_Project_Replace_Preview_Coherent;

   procedure Test_Replace_Preview_And_Inclusion_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("replace_preview_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Status  : Editor.Project_Search.Project_Replace_Preview_Status;
      Row     : Editor.Project_Search.Project_Replace_Preview_Row;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Editor.Project_Search.Set_Replace_Text (Search, "pin");
      Assert (Editor.Project_Search.Replace_Mode_Active (Search),
              "explicit replacement text input should activate transient replace mode before preview");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);

      Assert (Status = Editor.Project_Search.Project_Replace_Preview_Ok,
              "preview should be generated from fresh Project Search results");
      Assert (Editor.Project_Search.Replace_Mode_Active (Search),
              "preview generation should activate replace mode");
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) =
                Editor.Project_Search.Result_Count (Search),
              "preview should create one row per retained search result");
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 5,
              "preview should include all rows by default");
      Assert (Editor.Project_Search.Included_Replacement_File_Count (Search) = 2,
              "preview should count included files by unique path");
      Assert_Project_Replace_Preview_Coherent (Search, "preview");
      Row :=
        Editor.Project_Search.Replace_Preview_Row_At
          (Search, Editor.Project_Search.Replace_Preview_Count (Search) + 1);
      Assert ((not Row.Included) and then Row.Invalid
                and then Row.Search_Result_Id =
                  Editor.Project_Search.No_Project_Search_Result,
              "out-of-range preview lookup should fail closed");

      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 1);
      Assert (To_String (Row.Match_Text) = "needle",
              "preview row should retain the original matched text");
      Assert (To_String (Row.Before_Excerpt) = "Alpha needle",
              "preview should show the bounded before excerpt");
      Assert (To_String (Row.After_Excerpt) = "Alpha pin",
              "preview should show the bounded after excerpt");

      Editor.Project_Search.Exclude_Selected_Replacement (Search);
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 4,
              "exclude selected should remove one included row");
      Editor.Project_Search.Include_Selected_Replacement (Search);
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 5,
              "include selected should restore the selected row");

      Editor.Project_Search.Exclude_File_Replacements (Search, "a.txt");
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 2,
              "exclude file should exclude all rows in that file group");
      Editor.Project_Search.Include_All_Replacements (Search);
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 5,
              "include all should restore every preview row");
      Editor.Project_Search.Exclude_All_Replacements (Search);
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 0,
              "exclude all should leave no included replacements");

      Editor.Project_Search.Mark_Replace_Preview_Stale_For_File (Search, "a.txt");
      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (Search),
              "file-specific stale marking should stale the preview");
      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 1);
      Assert ((not Row.Included) and then Row.Stale,
              "stale marking should also exclude affected rows from the preview scope");
      Editor.Project_Search.Include_All_Replacements (Search);
      Assert (Editor.Project_Search.Included_Replacement_Count (Search) = 0,
              "include-all must not make stale rows eligible for apply");
      Assert (Editor.Project_Search.Included_Replacement_File_Count (Search) = 0,
              "stale included rows must not count as target files");
      Editor.Project_Search.Clear_Replace_Preview (Search);
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "explicit clear should remove stale replacement rows");
      Assert (not Editor.Project_Search.Replace_Preview_Is_Stale (Search),
              "explicit clear should remove stale replacement marker");
      Assert (Editor.Project_Search.Replace_Text (Search) = "pin",
              "explicit preview clear should preserve transient replacement text");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Replace_Preview_And_Inclusion_State;

   procedure Test_Replace_Selection_Follows_Result_Movement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("replace_selection_sync_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Status  : Editor.Project_Search.Project_Replace_Preview_Status;
      Row     : Editor.Project_Search.Project_Replace_Preview_Row;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Editor.Project_Search.Set_Replace_Text (Search, "pin");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);

      Assert (Status = Editor.Project_Search.Project_Replace_Preview_Ok,
              "selection-sync setup should generate a replacement preview");
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "setup should select the first search result");
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 1,
              "setup should select the matching replacement preview row");

      Editor.Project_Search.Clear_Replace_Preview (Search);
      Editor.Project_Search.Set_Selected_Result_Index (Search, 0);
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 0,
              "explicit no-selection state should be retained across preview generation");
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 0,
              "preview generation must not select a replacement row when no search result is selected");
      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 1);
      Assert (not Row.Selected,
              "no-selection preview should not mark the first replacement row selected");

      Editor.Project_Search.Clear_Replace_Preview (Search);
      Editor.Project_Search.Set_Selected_Result_Index (Search, 3);
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 3,
              "explicit result selection should be retained across preview generation");
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 3,
              "preview generation should select the matching replacement row, not the first valid row");

      Editor.Project_Search.Set_Selected_Result_Index (Search, 1);
      Editor.Project_Search.Move_Selection_Down (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 2,
              "previous result movement should advance the search selection");
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 2,
              "previous result movement should keep replacement selection synchronized");
      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 2);
      Assert (Row.Selected,
              "replacement row 2 should carry the selected marker after moving down");

      Editor.Project_Search.Move_Selection_Up (Search);
      Assert (Editor.Project_Search.Selected_Result_Index (Search) = 1,
              "previous result movement should move the search selection back up");
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 1,
              "previous result movement should keep replacement selection synchronized when moving up");
      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 1);
      Assert (Row.Selected,
              "replacement row 1 should carry the selected marker after moving up");

      Editor.Project_Search.Set_Selected_Replace_Preview_Index (Search, 999);
      Assert (Editor.Project_Search.Selected_Replace_Preview_Index (Search) = 0,
              "out-of-range replacement selection should fail closed instead of clamping");
      Row := Editor.Project_Search.Replace_Preview_Row_At (Search, 3);
      Assert (not Row.Selected,
              "out-of-range replacement selection should not leave the last row selected");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Replace_Selection_Follows_Result_Movement;

   procedure Test_Apply_Included_Replacements_To_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root              : constant String := Temp_Path ("replace_apply_root");
      Tree              : Editor.File_Tree.File_Tree_State;
      Search            : Editor.Project_Search.Project_Search_State;
      Options           : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Status            : Editor.Project_Search.Project_Replace_Preview_Status;
      Changed           : Boolean := False;
      Replacement_Count : Natural := 0;
      Source_Text       : constant String := "Alpha needle" & ASCII.LF & "needle again needle";
      Replaced_Text     : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Editor.Project_Search.Set_Replace_Text (Search, "pin");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);

      Replaced_Text := To_Unbounded_String
        (Editor.Project_Search.Apply_Included_Replacements_To_Text
           (State             => Search,
            Relative_Path     => "a.txt",
            Text              => Source_Text,
            Changed           => Changed,
            Replacement_Count => Replacement_Count));

      Assert (Changed,
              "text helper should report changed text for included replacements");
      Assert (Replacement_Count = 3,
              "text helper should replace every included match in the file");
      Assert (To_String (Replaced_Text) = "Alpha pin" & ASCII.LF & "pin again pin",
              "text helper should handle column-zero and later same-line matches safely");

      Editor.Project_Search.Set_Replace_Text (Search, "needle");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);
      Replaced_Text := To_Unbounded_String
        (Editor.Project_Search.Apply_Included_Replacements_To_Text
           (State             => Search,
            Relative_Path     => "a.txt",
            Text              => Source_Text,
            Changed           => Changed,
            Replacement_Count => Replacement_Count));
      Assert (not Changed,
              "no-op replacement should not report a dirtying change");
      Assert (Replacement_Count = 3,
              "no-op replacement should still count included candidate rows");
      Assert (To_String (Replaced_Text) = Source_Text,
              "no-op replacement should preserve text exactly");

      --  A retained preview must not be usable as an offset-only edit plan
      --  after the candidate text has drifted.  The helper validates the
      --  retained match text before replacing, matching the executor's
      --  per-file transaction guard.
      Replaced_Text := To_Unbounded_String
        (Editor.Project_Search.Apply_Included_Replacements_To_Text
           (State             => Search,
            Relative_Path     => "a.txt",
            Text              => "Alpha thread" & ASCII.LF & "thread again thread",
            Changed           => Changed,
            Replacement_Count => Replacement_Count));
      Assert (not Changed,
              "stale helper input should not report a dirtying change");
      Assert (Replacement_Count = 0,
              "stale helper input should reject the retained replacement plan");
      Assert (To_String (Replaced_Text) =
                "Alpha thread" & ASCII.LF & "thread again thread",
              "stale helper input should preserve text exactly");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Apply_Included_Replacements_To_Text;



   procedure Test_Multiline_Replacement_Text_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root              : constant String := Temp_Path ("replace_multiline_root");
      Tree              : Editor.File_Tree.File_Tree_State;
      Search            : Editor.Project_Search.Project_Search_State;
      Options           : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Status            : Editor.Project_Search.Project_Replace_Preview_Status;
      Changed           : Boolean := True;
      Replacement_Count : Natural := 99;
      Source_Text       : constant String := "Alpha needle" & ASCII.LF & "needle again needle";
      Replaced_Text     : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);

      Editor.Project_Search.Set_Replace_Text
        (Search, "pin" & ASCII.LF & "line");
      Assert (not Editor.Project_Search.Replace_Text_Is_Valid (Search),
              "project replacement text should reject multiline text");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);
      Assert (Status = Editor.Project_Search.Project_Replace_Invalid_Replacement_Text,
              "multiline replacement text should fail preview generation clearly");
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "invalid replacement text must not leave preview rows");

      Replaced_Text := To_Unbounded_String
        (Editor.Project_Search.Apply_Included_Replacements_To_Text
           (State             => Search,
            Relative_Path     => "a.txt",
            Text              => Source_Text,
            Changed           => Changed,
            Replacement_Count => Replacement_Count));
      Assert (not Changed,
              "invalid replacement text should not report a dirtying change");
      Assert (Replacement_Count = 0,
              "invalid replacement text should not apply candidate rows");
      Assert (To_String (Replaced_Text) = Source_Text,
              "invalid replacement text should preserve source text exactly");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Multiline_Replacement_Text_Is_Rejected;


   procedure Test_Empty_Replace_Text_Activates_Mode
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Search : Editor.Project_Search.Project_Search_State;
   begin
      Assert (not Editor.Project_Search.Replace_Mode_Active (Search),
              "replace mode should start inactive");

      Editor.Project_Search.Set_Replace_Text (Search, "");

      Assert (Editor.Project_Search.Replace_Mode_Active (Search),
              "explicit empty replacement text should activate replace mode");
      Assert (Editor.Project_Search.Replace_Text (Search) = "",
              "explicit empty replacement text should remain empty");
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "explicit empty replacement text should not synthesize preview rows");
   end Test_Empty_Replace_Text_Activates_Mode;

   procedure Test_Replace_Preview_Clears_On_Search_Identity_Change
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root    : constant String := Temp_Path ("replace_identity_root");
      Tree    : Editor.File_Tree.File_Tree_State;
      Search  : Editor.Project_Search.Project_Search_State;
      Options : constant Editor.Project_Search.Project_Search_Options := (others => <>);
      Status  : Editor.Project_Search.Project_Replace_Preview_Status;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Project_Search.Set_Query (Search, "needle");
      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Editor.Project_Search.Set_Replace_Text (Search, "pin");
      Editor.Project_Search.Generate_Replace_Preview (Search, Status);
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) > 0,
              "setup should have a replacement preview");

      Editor.Project_Search.Set_Query (Search, "plain");
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "query change should clear the replacement preview");
      Assert (Editor.Project_Search.Replace_Text (Search) = "pin",
              "query change should not silently rewrite transient replacement text");

      Editor.Project_Search.Search_Project (Search, Tree, Read_Text'Access, Options);
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "rerun search should not resurrect stale preview rows");

      Editor.Project_Search.Clear (Search);
      Assert (Editor.Project_Search.Replace_Text (Search) = "",
              "clear should remove transient replacement text");
      Assert (Editor.Project_Search.Replace_Preview_Count (Search) = 0,
              "clear should remove transient replacement preview rows");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Replace_Preview_Clears_On_Search_Identity_Change;

   overriding procedure Register_Tests
     (T : in out Project_Search_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Replace_Preview_And_Inclusion_State'Access,
         "generates bounded replace previews and controls inclusion state");
      Register_Routine
        (T, Test_Apply_Included_Replacements_To_Text'Access,
         "applies included replacements in deterministic end-exclusive ranges");
      Register_Routine
        (T, Test_Replace_Selection_Follows_Result_Movement'Access,
         "keeps replacement preview selection synchronized with result movement");
      Register_Routine
        (T, Test_Multiline_Replacement_Text_Is_Rejected'Access,
         "rejects multiline project replacement text");
      Register_Routine
        (T, Test_Replace_Preview_Clears_On_Search_Identity_Change'Access,
         "clears transient replace preview state across search identity changes");
      Register_Routine
        (T, Test_Empty_Replace_Text_Activates_Mode'Access,
         "explicit empty replacement text activates replace mode");
      Register_Routine
        (T, Test_Command_Surface_Extends_Project_Search_Modes'Access,
         "exposes no-payload Project Search mode/filter commands");
      Register_Routine
        (T, Test_Next_Previous_Available_Without_Selected_Result'Access,
         "next/previous result navigation works without a selected row");
      Register_Routine
        (T, Test_Whole_Word_Search_Mode'Access,
         "supports bounded whole-word Project Search matching");
      Register_Routine
        (T, Test_Include_Exclude_Path_Filters'Access,
         "supports transient include and exclude Project Search path filters");
      Register_Routine
        (T, Test_Path_Filter_Wildcards'Access,
         "supports bounded simple wildcard Project Search path filters");
      Register_Routine
        (T, Test_Path_Filter_Lists'Access,
         "supports transient Project Search include/exclude filter lists");
      Register_Routine
        (T, Test_Regex_Project_Search_Mode'Access,
         "supports bounded regex Project Search matching when Ada_Regexp is available");
      Register_Routine
        (T, Test_Tree_Search_Reports_Binary_Files'Access,
         "File Tree-backed Project Search reports binary skipped candidates");
      Register_Routine
        (T, Test_Known_Project_Search_Preserves_Project_Root_Bounds'Access,
         "keeps known-project search inside project root bounds");

      Register_Routine
        (T, Test_Tree_Search_Reports_Missing_And_Large_Files'Access,
         "File Tree-backed Project Search reports missing and large skipped candidates");
      Register_Routine
        (T, Test_Buffer_Edit_Marks_Project_Search_Stale'Access,
         "marks retained Project Search results stale after buffer edits");
      Register_Routine
        (T, Test_Invalid_Run_Clears_Project_Search_Results'Access,
         "invalid project search runs clear transient rows");
      Register_Routine
        (T, Test_Stale_Project_Search_Activation_Is_Unavailable'Access,
         "stale project search activation is unavailable");
      Register_Routine
        (T, Test_Canonical_Source_And_Render_Final_Freeze'Access,
         "Project Search canonical source and render final freeze");
      Register_Routine
        (T, Test_Operation_Query_Selection_Prompt_Final_Freeze'Access,
         "Project Search operation query selection prompt final freeze");
      Register_Routine
        (T, Test_Route_Audit_Lifecycle_Persistence_Final_Freeze'Access,
         "Project Search route audit lifecycle persistence final freeze");
      Register_Routine
        (T, Test_Canonical_Ownership_Cleanup'Access,
         "Project Search canonical ownership cleanup");
      Register_Routine
        (T, Test_Query_Selection_Prompt_Source_Target_Cleanup'Access,
         "Project Search query selection prompt cleanup");
      Register_Routine
        (T, Test_Route_Audit_And_Persistence_Cleanup'Access,
         "Project Search route audit and persistence cleanup");
      Register_Routine
        (T, Test_Direct_Lifecycle_Observation_Reliability'Access,
         "Project Search direct lifecycle observation reliability");
      Register_Routine
        (T, Test_Failure_And_Blocked_Observation_Preservation'Access,
         "Project Search failure and blocked observation preservation");
      Register_Routine
        (T, Test_Query_Selection_And_Prompt_Reliability'Access,
         "Project Search query selection and prompt reliability");
      Register_Routine
        (T, Test_Route_Audit_And_Persistence_State_Exclusion'Access,
         "Project Search route audit and persistence state exclusion");
      Register_Routine
        (T, Test_Retained_Source_Lifecycle_Observation'Access,
         "Project Search retained-source file lifecycle observation");
      Register_Routine
        (T, Test_Query_Selection_And_Target_Prompt_Boundary'Access,
         "Project Search query selection and prompt boundary");
      Register_Routine
        (T, Test_Route_Audit_Alias_And_State_Exclusion'Access,
         "Project Search route audit alias and state exclusion");
      Register_Routine
        (T, Test_Initial_Clear_And_Query'Access,
         "initializes, clears, and stores project search queries");
      Register_Routine
        (T, Test_Empty_Query_And_No_Files'Access,
         "reports empty-query and no-files project search statuses");
      Register_Routine
        (T, Test_Literal_Search_Grouping_And_Order'Access,
         "finds ordered literal project search matches and groups them by file");
      Register_Routine
        (T, Test_Selection_Case_And_Limits'Access,
         "handles selection movement, metadata, stale state, and result limits");
      Register_Routine
        (T, Test_Zero_Result_Query_Marks_Stale'Access,
         "marks retained zero-result Project Search queries stale after File Tree mutations");
      Register_Routine
        (T, Test_Zero_Result_Replace_Preview_Marks_Stale'Access,
         "marks retained zero-result replace previews stale after File Tree mutations");
      Register_Routine
        (T, Test_Result_Navigation_Helpers'Access,
         "selects first/last/path results and derives selected directories");
      Register_Routine
        (T, Test_Command_Surface_Stable_Names'Access,
         "exposes stable Project Search command names");
      Register_Routine
        (T, Test_Known_Project_File_Search'Access,
         "searches session-local known project files without refreshing");
      Register_Routine
        (T, Test_Limits_And_Binary_Skips'Access,
         "applies bounded file search and deterministic skip counts");
      Register_Routine
        (T, Test_Rerun_Preserves_Selection_By_Path_Line'Access,
         "preserves Project Search selection across reruns by path and line");
      Register_Routine
        (T, Test_Search_Options_Filter_And_Clear_Results'Access,
         "filters Project Search by scope, kind, and case without stale results");
      Register_Routine
        (T, Test_Summary_Counts_And_Skips'Access,
         "keeps Project Search summary counts coherent");
      Register_Routine
        (T, Test_Noop_And_Precondition_Preserve_Summary'Access,
         "preserves summaries for no-op and precondition paths");
      Register_Routine
        (T, Test_Match_Columns_And_Previews'Access,
         "stores match columns, previews, ranges, and clears preview metadata");
      Register_Routine
        (T, Test_Query_Run_Navigate_And_Cleanup_Workflow'Access,
         "covers query/run/navigation and option cleanup workflow coherence");
      Register_Routine
        (T, Test_Scoped_Kind_Case_And_Independence_Counts'Access,
         "covers scoped, kind-filtered, and case-sensitive Project Search counts");
      Register_Routine
        (T, Test_Selected_Directory_Scope_And_Refresh_Cleanup'Access,
         "covers selected-result directory scoping and refresh-style cleanup");
      Register_Routine
        (T, Test_Stale_Skipped_Truncated_And_Lifecycle_Cleanup'Access,
         "covers stale files, skipped/truncated summaries, and lifecycle cleanup");
   end Register_Tests;

end Editor.Project_Search.Tests;
