with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
use type Ada.Directories.File_Kind;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Panel_Focus;
with Editor.Project;
with Editor.State;
with Editor.Buffers;
with Editor.Executor;
with Editor.Commands;
with Editor.Messages;
with Editor.Feature_Diagnostics;
with Editor.Quick_Open;
with Text_Buffer;

package body Editor.File_Tree.Tests is

   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.File_Tree.File_Tree_Scan_Status;
   use type Editor.Commands.Command_Availability_Status;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Current_Directory, "phase55_" & Name);
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

   procedure Remove_Any_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         case Ada.Directories.Kind (Path) is
            when Ada.Directories.Ordinary_File =>
               Ada.Directories.Delete_File (Path);
            when Ada.Directories.Directory =>
               Ada.Directories.Delete_Tree (Path);
            when Ada.Directories.Special_File =>
               null;
         end case;
      end if;
   exception
      when others =>
         null;
   end Remove_Any_If_Exists;

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

   procedure Build_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
      B_Dir : constant String := Ada.Directories.Compose (Root, "b_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "z.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (B_Dir);
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (A_Dir);
      Ada.Directories.Create_Directory (B_Dir);
      Write_Bytes (Ada.Directories.Compose (A_Dir, "nested.txt"), "nested");
      Write_Bytes (Ada.Directories.Compose (Root, "z.txt"), "z");
      Write_Bytes (Ada.Directories.Compose (Root, "a.txt"), "a");
   end Build_Fixture;

   procedure Cleanup_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
      B_Dir : constant String := Ada.Directories.Compose (Root, "b_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "z.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (B_Dir);
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   function Node_Name
     (Tree : Editor.File_Tree.File_Tree_State;
      Id   : Editor.File_Tree.File_Tree_Node_Id) return String
   is
   begin
      return To_String (Editor.File_Tree.Node (Tree, Id).Name);
   end Node_Name;

   overriding function Name
     (T : File_Tree_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.File_Tree");
   end Name;

   procedure Test_Clear_And_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant String := Temp_Path ("missing_root");
      File_P  : constant String := Temp_Path ("regular_root.txt");
      Tree    : Editor.File_Tree.File_Tree_State;
      Result  : Editor.File_Tree.File_Tree_Scan_Result;
   begin
      Remove_File_If_Exists (File_P);
      if Ada.Directories.Exists (Missing) then
         Ada.Directories.Delete_Directory (Missing);
      end if;

      Tree := Editor.File_Tree.Scan_Project ("");
      Result := Editor.File_Tree.Scan_Status (Tree);
      Assert (Result.Status = Editor.File_Tree.File_Tree_Invalid_Root,
              "Scan_Project must reject an empty root path");
      Assert (Editor.File_Tree.Is_Empty (Tree),
              "Rejected scans must leave the tree empty");

      Tree := Editor.File_Tree.Scan_Project (Missing);
      Result := Editor.File_Tree.Scan_Status (Tree);
      Assert (Result.Status = Editor.File_Tree.File_Tree_Root_Not_Found,
              "Scan_Project must reject a missing root path");

      Write_Bytes (File_P, "file");
      Tree := Editor.File_Tree.Scan_Project (File_P);
      Result := Editor.File_Tree.Scan_Status (Tree);
      Assert (Result.Status = Editor.File_Tree.File_Tree_Root_Not_Directory,
              "Scan_Project must reject a regular-file root");

      Editor.File_Tree.Clear (Tree);
      Assert (Editor.File_Tree.Is_Empty (Tree),
              "Clear must empty the file tree");
      Assert (Editor.File_Tree.Root (Tree) = Editor.File_Tree.No_File_Tree_Node,
              "Clear must reset the root node id");

      Remove_File_If_Exists (File_P);
   end Test_Clear_And_Validation;

   procedure Test_Scan_Order_And_Root
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("scan_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      Root_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row_1  : Editor.File_Tree.Visible_File_Tree_Row;
      Row_2  : Editor.File_Tree.Visible_File_Tree_Row;
      Row_3  : Editor.File_Tree.Visible_File_Tree_Row;
      Row_4  : Editor.File_Tree.Visible_File_Tree_Row;
      Row_5  : Editor.File_Tree.Visible_File_Tree_Row;
      Second_Tree : Editor.File_Tree.File_Tree_State;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Root_Id := Editor.File_Tree.Root (Tree);

      Assert (Editor.File_Tree.Scan_Status (Tree).Status = Editor.File_Tree.File_Tree_Scan_Ok,
              "Scan_Project must accept a directory root");
      Assert (Editor.File_Tree.Node_Count (Tree) = 6,
              "Fixture scan must include root, two directories, and three files");
      Assert (Root_Id /= Editor.File_Tree.No_File_Tree_Node,
              "Root node id must be valid");
      Assert (Editor.File_Tree.Node (Tree, Root_Id).Kind = Editor.File_Tree.Directory_Node,
              "Root node must be a directory");
      Assert (Editor.File_Tree.Node (Tree, Root_Id).Depth = 0,
              "Root node depth must be zero");
      Assert (To_String (Editor.File_Tree.Node (Tree, Root_Id).Relative_Path) = ".",
              "Root node relative path must be dot");
      Assert (Editor.File_Tree.Node (Tree, Root_Id).Is_Expanded,
              "Root node must be expanded by default");

      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 5,
              "Initial visible rows must include root and collapsed root children");
      Row_1 := Editor.File_Tree.Visible_Row (Tree, 1);
      Row_2 := Editor.File_Tree.Visible_Row (Tree, 2);
      Row_3 := Editor.File_Tree.Visible_Row (Tree, 3);
      Row_4 := Editor.File_Tree.Visible_Row (Tree, 4);
      Row_5 := Editor.File_Tree.Visible_Row (Tree, 5);
      Assert (Row_1.Node_Id = Root_Id,
              "Visible row one must be the root node");
      Assert (Node_Name (Tree, Row_2.Node_Id) = "a_dir",
              "Directories must sort alphabetically before files");
      Assert (Node_Name (Tree, Row_3.Node_Id) = "b_dir",
              "Second directory must sort alphabetically");
      Assert (Node_Name (Tree, Row_4.Node_Id) = "a.txt",
              "Files must sort alphabetically after directories");
      Assert (Node_Name (Tree, Row_5.Node_Id) = "z.txt",
              "Final file must sort alphabetically");
      Assert (not Editor.File_Tree.Node (Tree, Row_2.Node_Id).Is_Expanded,
              "Child directories must be collapsed by default");

      Second_Tree := Editor.File_Tree.Scan_Project (Root);
      Assert (Node_Name (Second_Tree, Editor.File_Tree.Visible_Row (Second_Tree, 2).Node_Id) =
              Node_Name (Tree, Row_2.Node_Id),
              "Repeated scans must produce stable deterministic first child order");
      Assert (Node_Name (Second_Tree, Editor.File_Tree.Visible_Row (Second_Tree, 5).Node_Id) =
              Node_Name (Tree, Row_5.Node_Id),
              "Repeated scans must produce stable deterministic final child order");

      Cleanup_Fixture (Root);
   end Test_Scan_Order_And_Root;

   procedure Test_Expansion_And_Lookup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root     : constant String := Temp_Path ("expand_root");
      Nested   : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "a_dir"), "nested.txt");
      Tree     : Editor.File_Tree.File_Tree_State;
      Found    : Boolean := False;
      Root_Id  : Editor.File_Tree.File_Tree_Node_Id;
      A_Dir    : Editor.File_Tree.File_Tree_Node_Id;
      Nested_Id : Editor.File_Tree.File_Tree_Node_Id;
      Row_Id   : Editor.File_Tree.File_Tree_Node_Id;
      File_Id  : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Root_Id := Editor.File_Tree.Find_By_Path (Tree, ".", Found);
      Assert (Found and then Root_Id = Editor.File_Tree.Root (Tree),
              "Find_By_Path must find the root by project-relative dot path");

      A_Dir := Editor.File_Tree.Find_By_Path (Tree, "a_dir", Found);
      Assert (Found, "Find_By_Path must find a project-relative directory path");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 5,
              "Collapsed child directory must hide descendants");

      Editor.File_Tree.Toggle_Expanded (Tree, A_Dir);
      Assert (Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Toggle_Expanded must expand a directory");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 6,
              "Expanded child directory must reveal its nested file");

      Nested_Id := Editor.File_Tree.Find_By_Path (Tree, Nested, Found);
      Assert (Found, "Find_By_Path must find a nested absolute file path");
      Assert (Editor.File_Tree.Node (Tree, Nested_Id).Kind = Editor.File_Tree.File_Node,
              "Nested file must have File_Node kind");

      Row_Id := Editor.File_Tree.Node_At_Visible_Row (Tree, 3, Found);
      Assert (Found and then Row_Id /= Editor.File_Tree.No_File_Tree_Node,
              "Node_At_Visible_Row must resolve visible rows");

      File_Id := Editor.File_Tree.Find_By_Path (Tree, "a.txt", Found);
      Assert (Found, "Find_By_Path must find root-level project-relative files");
      Editor.File_Tree.Toggle_Expanded (Tree, File_Id);
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 6,
              "Toggle_Expanded on a file must be a no-op");

      Editor.File_Tree.Toggle_Expanded (Tree, A_Dir);
      Assert (not Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Toggle_Expanded again must collapse a directory");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 5,
              "Toggled collapse must hide descendants again");

      Editor.File_Tree.Set_Expanded (Tree, A_Dir, True);
      Assert (Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Set_Expanded True must expand a directory");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 6,
              "Set_Expanded True must rebuild visible rows");

      Editor.File_Tree.Set_Expanded (Tree, A_Dir, False);
      Assert (not Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Set_Expanded False must collapse a directory");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 5,
              "Collapsing must hide descendants again");

      Editor.File_Tree.Set_Expanded (Tree, Editor.File_Tree.File_Tree_Node_Id'Last, True);
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 5,
              "Set_Expanded on an invalid id must not corrupt visible rows");

      Nested_Id := Editor.File_Tree.Find_By_Path (Tree, "missing.txt", Found);
      Assert (not Found and then Nested_Id = Editor.File_Tree.No_File_Tree_Node,
              "Find_By_Path must reject missing paths deterministically");
      Nested_Id := Editor.File_Tree.Node_At_Visible_Row (Tree, 99, Found);
      Assert (not Found and then Nested_Id = Editor.File_Tree.No_File_Tree_Node,
              "Node_At_Visible_Row must reject out-of-range rows");

      Cleanup_Fixture (Root);
   end Test_Expansion_And_Lookup;


   procedure Test_File_Node_Iteration
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("file_nodes_root");
      Tree   : Editor.File_Tree.File_Tree_State;
      First  : Editor.File_Tree.File_Tree_Node_Summary;
      Second : Editor.File_Tree.File_Tree_Node_Summary;
      Third  : Editor.File_Tree.File_Tree_Node_Summary;
      Dir_Id : Editor.File_Tree.File_Tree_Node_Id;
      Found  : Boolean := False;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Assert (Editor.File_Tree.File_Node_Count (Tree) = 3,
              "File_Node_Count must count files only");

      First := Editor.File_Tree.File_Node_At (Tree, 1);
      Second := Editor.File_Tree.File_Node_At (Tree, 2);
      Third := Editor.File_Tree.File_Node_At (Tree, 3);
      Assert (First.Kind = Editor.File_Tree.File_Node
              and then Second.Kind = Editor.File_Tree.File_Node
              and then Third.Kind = Editor.File_Tree.File_Node,
              "File_Node_At must return only file summaries");
      Assert (To_String (First.Relative_Path) < To_String (Second.Relative_Path)
              or else To_String (Second.Relative_Path) < To_String (Third.Relative_Path),
              "File node iteration order must be deterministic");

      Dir_Id := Editor.File_Tree.Find_By_Path (Tree, "a_dir", Found);
      Assert (Found and then not Editor.File_Tree.Is_File_Node (Tree, Dir_Id),
              "Is_File_Node must reject directory nodes");
      Assert (Editor.File_Tree.Is_File_Node (Tree, First.Id),
              "Is_File_Node must accept file nodes");

      Editor.File_Tree.Set_Expanded (Tree, Dir_Id, False);
      Assert (Editor.File_Tree.File_Node_Count (Tree) = 3,
              "collapsed directories must not hide files from file-node iteration");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_File_Node_Iteration;


   procedure Test_Phase533_Open_Selected_Requires_File_Node
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("phase533_open_file_only");
      S      : Editor.State.State_Type;
      Opened : Editor.Project.Project_Open_Result;
      A      : Editor.Commands.Command_Availability;
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      --  Row 2 is a real directory in the deterministic fixture.  Phase 533
      --  keeps directory expansion on the directory commands only; open-selected
      --  must not silently treat a directory/status row as a file activation.
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 2);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_File_Tree_Open_Selected);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "Phase 533 File Tree open-selected must reject directory rows");
      Assert (Editor.Commands.Unavailable_Reason (A) =
                "Selected row is not a file",
              "Phase 545 File Tree open-selected should use canonical file-only activation wording");

      --  Row 4 is a real root-level file; it remains activatable through the
      --  canonical file-open path.
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 4);
      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_File_Tree_Open_Selected);
      Assert (A.Status = Editor.Commands.Command_Available,
              "Phase 533 File Tree open-selected must accept real file rows");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase533_Open_Selected_Requires_File_Node;


   procedure Test_Phase545_Collapse_All_And_Expand_Ancestors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase545_collapse_expand");
      Nested    : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "a_dir"), "nested.txt");
      Tree      : Editor.File_Tree.File_Tree_State;
      Found     : Boolean := False;
      Root_Id   : Editor.File_Tree.File_Tree_Node_Id;
      A_Dir     : Editor.File_Tree.File_Tree_Node_Id;
      Nested_Id : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Root_Id := Editor.File_Tree.Root (Tree);
      A_Dir := Editor.File_Tree.Find_By_Path (Tree, "a_dir", Found);
      Assert (Found, "Phase 545 fixture must contain nested directory");
      Nested_Id := Editor.File_Tree.Find_By_Path (Tree, Nested, Found);
      Assert (Found, "Phase 545 fixture must contain nested file");

      Editor.File_Tree.Set_Expanded (Tree, A_Dir, True);
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) > 1,
              "Phase 545 setup should expose expanded child rows");

      Editor.File_Tree.Collapse_All (Tree);
      Assert (not Editor.File_Tree.Node (Tree, Root_Id).Is_Expanded,
              "Phase 545 collapse-all must collapse the project root");
      Assert (not Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Phase 545 collapse-all must collapse descendant directories");
      Assert (Editor.File_Tree.Visible_Row_Count (Tree) = 1,
              "Phase 545 collapsed root should leave only the root row visible");

      Editor.File_Tree.Expand_Ancestors (Tree, Nested_Id);
      Assert (Editor.File_Tree.Node (Tree, Root_Id).Is_Expanded,
              "Phase 545 expand-ancestors must reopen the project root");
      Assert (Editor.File_Tree.Node (Tree, A_Dir).Is_Expanded,
              "Phase 545 expand-ancestors must reopen nested parents");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase545_Collapse_All_And_Expand_Ancestors;


   procedure Test_Phase545_Preserve_Hidden_Expansion_On_Refresh
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase545_preserve_expansion");
      Old_Tree   : Editor.File_Tree.File_Tree_State;
      New_Tree   : Editor.File_Tree.File_Tree_State;
      Found      : Boolean := False;
      Root_Id    : Editor.File_Tree.File_Tree_Node_Id;
      A_Dir      : Editor.File_Tree.File_Tree_Node_Id;
      New_Root   : Editor.File_Tree.File_Tree_Node_Id;
      New_A_Dir  : Editor.File_Tree.File_Tree_Node_Id;
   begin
      Build_Fixture (Root);
      Old_Tree := Editor.File_Tree.Scan_Project (Root);
      Root_Id := Editor.File_Tree.Root (Old_Tree);
      A_Dir := Editor.File_Tree.Find_By_Path (Old_Tree, "a_dir", Found);
      Assert (Found, "Phase 545 fixture must contain a_dir");

      Editor.File_Tree.Set_Expanded (Old_Tree, A_Dir, True);
      Editor.File_Tree.Set_Expanded (Old_Tree, Root_Id, False);
      Assert (not Editor.File_Tree.Node (Old_Tree, Root_Id).Is_Expanded,
              "Phase 545 setup should keep root collapsed");
      Assert (Editor.File_Tree.Node (Old_Tree, A_Dir).Is_Expanded,
              "Phase 545 setup should keep hidden child directory expanded");

      New_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.File_Tree.Preserve_Expanded_Paths_From
        (Tree   => New_Tree,
         Source => Old_Tree);

      New_Root := Editor.File_Tree.Root (New_Tree);
      New_A_Dir := Editor.File_Tree.Find_By_Path (New_Tree, "a_dir", Found);
      Assert (Found, "Phase 545 refreshed fixture must contain a_dir");
      Assert (not Editor.File_Tree.Node (New_Tree, New_Root).Is_Expanded,
              "Phase 545 refresh preservation must retain collapsed root state");
      Assert (Editor.File_Tree.Node (New_Tree, New_A_Dir).Is_Expanded,
              "Phase 545 refresh preservation must retain hidden expanded descendants");
      Assert (Editor.File_Tree.Visible_Row_Count (New_Tree) = 1,
              "Phase 545 hidden expansion should not force collapsed parents open");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase545_Preserve_Hidden_Expansion_On_Refresh;


   procedure Test_Phase545_Node_Kind_Labels
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.File_Tree.Kind_Label (Editor.File_Tree.File_Node) = "file",
              "Phase 545 file kind label should be stable for render/outcomes");
      Assert (Editor.File_Tree.Kind_Label (Editor.File_Tree.Directory_Node) = "directory",
              "Phase 545 directory kind label should be stable for render/outcomes");
   end Test_Phase545_Node_Kind_Labels;


   procedure Test_Phase572_Delete_Empty_Directory_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root  : constant String := Temp_Path ("phase572_delete_empty_dir");
      Empty : constant String := Ada.Directories.Compose (Root, "b_dir");
      Full  : constant String := Ada.Directories.Compose (Root, "a_dir");
      S     : Editor.State.State_Type;
      Opened : Editor.Project.Project_Open_Result;
      Cmd   : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Cmd.Text := To_Unbounded_String ("confirm");

      --  Row 2 is a_dir and contains nested.txt.  Phase 572 baseline policy
      --  must reject recursive deletion and leave the directory intact.
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 2);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Ada.Directories.Exists (Full),
              "Phase 572 must not recursively delete non-empty directories");

      --  Row 3 is b_dir in the deterministic fixture.  Empty directory
      --  deletion is allowed after explicit confirmation and refresh.
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 3);
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (not Ada.Directories.Exists (Empty),
              "Phase 572 must delete explicitly confirmed empty directories");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Phase572_Delete_Empty_Directory_Only;


   procedure Test_Phase572_Delete_Rejects_Hidden_File_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_hidden_nonempty_dir");
      Hidden    : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "b_dir"), ".keep");
      B_Dir     : constant String := Ada.Directories.Compose (Root, "b_dir");
      S         : Editor.State.State_Type;
      Opened    : Editor.Project.Project_Open_Result;
      Found     : Boolean := False;
      Row_Found : Boolean := False;
      Msg_Found : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row       : Natural := 0;
      Msg       : Editor.Messages.Editor_Message;
      Cmd       : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Write_Bytes (Hidden, "hidden");
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "b_dir", Found);
      Assert (Found, "Phase 572 hidden-file delete setup must find directory row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 hidden-file delete setup must map directory row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Directory is not empty",
              "Phase 572 directory delete must reject hidden-file-only directories as non-empty");
      Assert (Ada.Directories.Exists (Hidden),
              "Phase 572 hidden-file non-empty reject must leave hidden child intact");
      Assert (Ada.Directories.Exists (B_Dir),
              "Phase 572 hidden-file non-empty reject must leave directory intact");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Delete_Rejects_Hidden_File_Directory;


   procedure Test_Phase572_Rejects_Stale_Kind_Replacements
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase572_stale_kind");
      Stale_File  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Renamed     : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      Stale_Dir   : constant String := Ada.Directories.Compose (Root, "b_dir");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Found       : Boolean := False;
      Row_Found   : Boolean := False;
      Node        : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row         : Natural := 0;
      Rename_Cmd  : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Delete_Cmd  : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 setup must find stale file row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must map stale file row");
      Ada.Directories.Delete_File (Stale_File);
      Ada.Directories.Create_Directory (Stale_File);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Rename_Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Assert (Ada.Directories.Exists (Stale_File)
              and then Ada.Directories.Kind (Stale_File) = Ada.Directories.Directory,
              "Phase 572 rename must reject stale file rows replaced by directories");
      Assert (not Ada.Directories.Exists (Renamed),
              "Phase 572 stale replacement rename must not create target");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "b_dir", Found);
      Assert (Found, "Phase 572 setup must find stale directory row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must map stale directory row");
      Ada.Directories.Delete_Directory (Stale_Dir);
      Write_Bytes (Stale_Dir, "replacement file");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Assert (Ada.Directories.Exists (Stale_Dir)
              and then Ada.Directories.Kind (Stale_Dir) = Ada.Directories.Ordinary_File,
              "Phase 572 delete must reject stale directory rows replaced by files");

      Remove_Any_If_Exists (Stale_File);
      Remove_Any_If_Exists (Stale_Dir);
      Remove_Any_If_Exists (Renamed);
      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Stale_File);
         Remove_Any_If_Exists (Stale_Dir);
         Remove_Any_If_Exists (Renamed);
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Rejects_Stale_Kind_Replacements;


   procedure Test_Phase572_Project_Root_And_Same_Name_Guards
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_root_same_name");
      File_Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Msg_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Msg        : Editor.Messages.Editor_Message;
      Delete_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Root)
              and then Ada.Directories.Kind (Root) = Ada.Directories.Directory,
              "Phase 572 must never delete the project root");
      Assert (Msg_Found and then To_String (Msg.Text) = "Cannot delete project root",
              "Phase 572 project-root delete must report the explicit root guard");

      Editor.Messages.Clear (S.Messages);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 setup must find same-name rename file row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must map same-name rename row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Rename_Cmd.Text := To_Unbounded_String ("a.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (File_Path),
              "Phase 572 same-name rename must leave the source file in place");
      Assert (Msg_Found and then To_String (Msg.Text) = "Rename target is unchanged",
              "Phase 572 same-name rename must not be reported as a conflict");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Project_Root_And_Same_Name_Guards;


   procedure Test_Phase572_Missing_Source_Message_Precedes_Canonical_Guard
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_missing_source_message");
      File_Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Msg_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Msg        : Editor.Messages.Editor_Message;
      Delete_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 setup must find missing-source file row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must map missing-source row");
      Ada.Directories.Delete_File (File_Path);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Rename_Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Target no longer exists.",
              "Phase 572 rename must report missing selected source before canonical boundary checks");

      Editor.Messages.Clear (S.Messages);
      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Target no longer exists.",
              "Phase 572 delete must report missing selected source before canonical boundary checks");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Missing_Source_Message_Precedes_Canonical_Guard;


   procedure Test_Phase572_Create_Rejects_Drive_Relative_Text_At_Execution
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_drive_relative_create");
      File_Path  : constant String := Ada.Directories.Compose (Root, "C:tmp.txt");
      Dir_Path   : constant String := Ada.Directories.Compose (Root, "D:generated");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Msg_Found  : Boolean := False;
      Msg        : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);

      Create_File_Cmd.Text := To_Unbounded_String ("C:tmp.txt");
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Invalid file name",
              "Phase 572 create-file execution must reject drive-relative text as invalid syntax");
      Assert (not Ada.Directories.Exists (File_Path),
              "Phase 572 drive-relative create-file text must not become an in-project filename");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := To_Unbounded_String ("D:generated");
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Invalid directory name",
              "Phase 572 create-directory execution must reject drive-relative text as invalid syntax");
      Assert (not Ada.Directories.Exists (Dir_Path),
              "Phase 572 drive-relative create-directory text must not become an in-project directory");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Create_Rejects_Drive_Relative_Text_At_Execution;




   procedure Test_Phase572_Create_Rejects_Absolute_Text_As_Project_Relative
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_absolute_create");
      Outside_File : constant String :=
        Ada.Directories.Compose
          (Ada.Directories.Current_Directory, "phase572_absolute_outside.adb");
      Outside_Dir : constant String :=
        Ada.Directories.Compose
          (Ada.Directories.Current_Directory, "phase572_absolute_outside_dir");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Msg_Found  : Boolean := False;
      Msg        : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
   begin
      Remove_File_If_Exists (Outside_File);
      Remove_Any_If_Exists (Outside_Dir);
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);

      Create_File_Cmd.Text := To_Unbounded_String (Outside_File);
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert
        (Msg_Found
         and then To_String (Msg.Text) = "Target path must be project-relative",
         "Phase 572 absolute create-file execution must match prompt input-model wording");
      Assert (not Ada.Directories.Exists (Outside_File),
              "Phase 572 absolute create-file text must not create an outside file");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := To_Unbounded_String (Outside_Dir);
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert
        (Msg_Found
         and then To_String (Msg.Text) = "Target path must be project-relative",
         "Phase 572 absolute create-directory execution must match prompt input-model wording");
      Assert (not Ada.Directories.Exists (Outside_Dir),
              "Phase 572 absolute create-directory text must not create an outside directory");

      Cleanup_Fixture (Root);
      Remove_File_If_Exists (Outside_File);
      Remove_Any_If_Exists (Outside_Dir);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         Remove_File_If_Exists (Outside_File);
         Remove_Any_If_Exists (Outside_Dir);
         raise;
   end Test_Phase572_Create_Rejects_Absolute_Text_As_Project_Relative;

   procedure Test_Phase572_Create_Rejects_Traversal_As_Invalid_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_traversal_create");
      File_Path  : constant String := Ada.Directories.Compose (Root, "blocked.txt");
      Dir_Path   : constant String := Ada.Directories.Compose (Root, "blocked_dir");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Msg_Found  : Boolean := False;
      Msg        : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);

      Create_File_Cmd.Text := To_Unbounded_String ("a_dir/../blocked.txt");
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Invalid file name",
              "Phase 572 create-file traversal must be invalid input, not a boundary-only fallback");
      Assert (not Ada.Directories.Exists (File_Path),
              "Phase 572 traversal create-file text must not create the normalized target");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := To_Unbounded_String ("a_dir/../blocked_dir");
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Invalid directory name",
              "Phase 572 create-directory traversal must be invalid input, not a boundary-only fallback");
      Assert (not Ada.Directories.Exists (Dir_Path),
              "Phase 572 traversal create-directory text must not create the normalized target");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Create_Rejects_Traversal_As_Invalid_Input;


   procedure Test_Phase572_Create_Rejects_Stale_Selected_Base
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_stale_create_base");
      A_Dir      : constant String := Ada.Directories.Compose (Root, "a_dir");
      Nested     : constant String := Ada.Directories.Compose (A_Dir, "nested.txt");
      Replacement_File : constant String := A_Dir;
      Child_Dir  : constant String := Ada.Directories.Compose (A_Dir, "child");
      Explicit_File : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "b_dir"), "explicit_from_stale.adb");
      Explicit_Dir : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "b_dir"), "explicit_child");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Msg_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Msg        : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "Phase 572 setup must find selected directory row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must map selected directory row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Ada.Directories.Delete_File (Nested);
      Ada.Directories.Delete_Directory (A_Dir);

      Create_File_Cmd.Text := To_Unbounded_String ("new_from_stale.adb");
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "File Tree item is stale.",
              "Phase 572 create-file must reject a missing selected directory as stale");
      Assert (not Ada.Directories.Exists (Ada.Directories.Compose (Root, "new_from_stale.adb")),
              "Phase 572 stale selected directory create-file must not fall back to project root");

      Editor.Messages.Clear (S.Messages);
      Create_File_Cmd.Text := To_Unbounded_String ("b_dir/explicit_from_stale.adb");
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Explicit_File),
              "Phase 572 explicit project-relative create-file must not be blocked by an unrelated stale selected directory");
      Assert (Msg_Found and then To_String (Msg.Text) = "File created.",
              "Phase 572 explicit project-relative create-file should complete through the normal success path");

      Ada.Directories.Create_Directory (A_Dir);
      Write_Bytes (Nested, "nested");
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a_dir", Found);
      Assert (Found, "Phase 572 setup must re-find selected directory row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 setup must re-map selected directory row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Ada.Directories.Delete_File (Nested);
      Ada.Directories.Delete_Directory (A_Dir);
      Write_Bytes (Replacement_File, "replacement");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := To_Unbounded_String ("child");
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "File Tree item is stale.",
              "Phase 572 create-directory must reject a selected directory row replaced by a file");
      Assert (Ada.Directories.Exists (Replacement_File)
              and then Ada.Directories.Kind (Replacement_File) = Ada.Directories.Ordinary_File,
              "Phase 572 stale-kind create-directory rejection must leave the replacement file intact");
      Assert (not Ada.Directories.Exists (Child_Dir),
              "Phase 572 stale-kind create-directory rejection must not create below the stale target");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := To_Unbounded_String ("b_dir/explicit_child");
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Explicit_Dir)
              and then Ada.Directories.Kind (Explicit_Dir) = Ada.Directories.Directory,
              "Phase 572 explicit project-relative create-directory must not be blocked by an unrelated stale selected directory");
      Assert (Msg_Found and then To_String (Msg.Text) = "Directory created.",
              "Phase 572 explicit project-relative create-directory should complete through the normal success path");

      Remove_Any_If_Exists (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Create_Rejects_Stale_Selected_Base;




   procedure Test_Phase572_Operation_Outcome_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root        : constant String := Temp_Path ("phase572_outcome_messages");
      Created     : constant String := Ada.Directories.Compose (Root, "created.adb");
      Created_Dir : constant String := Ada.Directories.Compose (Root, "created_dir");
      Renamed     : constant String := Ada.Directories.Compose (Root, "renamed.txt");
      S           : Editor.State.State_Type;
      Opened      : Editor.Project.Project_Open_Result;
      Found       : Boolean := False;
      Row_Found   : Boolean := False;
      Msg_Found   : Boolean := False;
      Node        : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row         : Natural := 0;
      Msg         : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Delete_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);
      Create_File_Cmd.Text := To_Unbounded_String ("created.adb");
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Created),
              "Phase 572 create-file outcome setup must create the file");
      Assert (Msg_Found and then To_String (Msg.Text) = "File created.",
              "Phase 572 create-file should use the concise expected outcome message");

      Editor.Messages.Clear (S.Messages);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);
      Create_Dir_Cmd.Text := To_Unbounded_String ("created_dir");
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Created_Dir)
              and then Ada.Directories.Kind (Created_Dir) = Ada.Directories.Directory,
              "Phase 572 create-directory outcome setup must create the directory");
      Assert (Msg_Found and then To_String (Msg.Text) = "Directory created.",
              "Phase 572 create-directory should use the concise expected outcome message");

      Editor.Messages.Clear (S.Messages);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 outcome setup must find file to rename");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 outcome setup must map file row to rename");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Rename_Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Ada.Directories.Exists (Renamed),
              "Phase 572 rename outcome setup must rename the file");
      Assert (Msg_Found and then To_String (Msg.Text) = "File renamed.",
              "Phase 572 rename should use the concise expected outcome message");

      Editor.Messages.Clear (S.Messages);
      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "renamed.txt", Found);
      Assert (Found, "Phase 572 outcome setup must find renamed file");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 outcome setup must map renamed file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (not Ada.Directories.Exists (Renamed),
              "Phase 572 delete outcome setup must delete the file");
      Assert (Msg_Found and then To_String (Msg.Text) = "File deleted.",
              "Phase 572 delete should use the concise expected outcome message");

      Remove_Any_If_Exists (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Operation_Outcome_Messages;


   procedure Test_Phase572_Dirty_Open_Buffer_Block_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_dirty_block_messages");
      File_Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Msg_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Msg        : Editor.Messages.Editor_Message;
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Delete_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Editor.Executor.Execute_Open_File (S, File_Path);
      Text_Buffer.Set_Text (S.Buffer, "a dirty edit");
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 dirty-block setup must find selected file row");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 dirty-block setup must map selected file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Rename_Cmd.Text := To_Unbounded_String ("renamed.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Dirty buffer preserved.",
              "Phase 579 rename dirty-buffer guard should report preserved dirty buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "a dirty edit",
              "Phase 579 dirty-blocked rename must preserve active dirty buffer text");
      Assert (S.File_Info.Dirty,
              "Phase 579 dirty-blocked rename must keep the buffer dirty");
      Assert (Ada.Directories.Exists (File_Path),
              "Phase 572 dirty-blocked rename must leave the source file in place");

      Editor.Messages.Clear (S.Messages);
      Delete_Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Delete cancelled.",
              "Phase 572 unconfirmed delete must stop at confirmation before dirty-buffer impact checks");
      Assert (Ada.Directories.Exists (File_Path),
              "Phase 572 unconfirmed dirty delete must leave the source file in place");

      Editor.Messages.Clear (S.Messages);
      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Dirty buffer preserved.",
              "Phase 579 confirmed delete dirty-buffer guard should report preserved dirty buffer text");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = "a dirty edit",
              "Phase 579 dirty-blocked delete must preserve active dirty buffer text");
      Assert (S.File_Info.Dirty,
              "Phase 579 dirty-blocked delete must keep the buffer dirty");
      Assert (Ada.Directories.Exists (File_Path),
              "Phase 572 dirty-blocked delete must leave the source file in place");

      Remove_Any_If_Exists (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Dirty_Open_Buffer_Block_Messages;


   procedure Test_Phase572_Mutation_Marks_Path_Diagnostics_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_diag_path_stale");
      File_Path  : constant String := Ada.Directories.Compose (Root, "a.txt");
      Other_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Error,
         "old path diagnostic",
         File_Path,
         Source_Kind => Editor.Feature_Diagnostics.File_Diagnostic_Source);
      Editor.Feature_Diagnostics.Add_Diagnostic
        (S.Feature_Diagnostics,
         Editor.Feature_Diagnostics.Diagnostic_Warning,
         "unaffected diagnostic",
         Other_Path,
         Source_Kind => Editor.Feature_Diagnostics.File_Diagnostic_Source);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 diagnostics stale setup must find renamed file");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 diagnostics stale setup must map file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Rename_Cmd.Text := To_Unbounded_String ("renamed_diag.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);

      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 2,
              "Phase 572 path-stale diagnostics should preserve diagnostic rows");
      Assert (Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 1),
              "Phase 572 rename/delete should mark diagnostics targeting the old path stale");
      Assert (not Editor.Feature_Diagnostics.Item_Is_Stale (S.Feature_Diagnostics, 2),
              "Phase 572 rename/delete should not stale diagnostics for unrelated paths");

      Remove_Any_If_Exists (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Mutation_Marks_Path_Diagnostics_Stale;


   procedure Test_Phase572_Empty_Execution_Uses_Name_Guidance
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root       : constant String := Temp_Path ("phase572_empty_execution_guidance");
      S          : Editor.State.State_Type;
      Opened     : Editor.Project.Project_Open_Result;
      Found      : Boolean := False;
      Row_Found  : Boolean := False;
      Msg_Found  : Boolean := False;
      Node       : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row        : Natural := 0;
      Msg        : Editor.Messages.Editor_Message;
      Create_File_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Create_Dir_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_Directory);
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Create_File_Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Create_File_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Enter a name.",
              "Phase 572 empty create-file execution must use name guidance");

      Editor.Messages.Clear (S.Messages);
      Create_Dir_Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Create_Dir_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Enter a name.",
              "Phase 572 empty create-directory execution must use name guidance");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 empty rename setup must find file node");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 empty rename setup must map file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Editor.Messages.Clear (S.Messages);
      Rename_Cmd.Text := Null_Unbounded_String;
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);
      Assert (Msg_Found and then To_String (Msg.Text) = "Enter a name.",
              "Phase 572 empty rename execution must use name guidance");
      Assert (Ada.Directories.Exists (Ada.Directories.Compose (Root, "a.txt")),
              "Phase 572 empty rename execution must not mutate the source file");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Empty_Execution_Uses_Name_Guidance;


   procedure Test_Phase572_Rename_Path_Fragment_Execution_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_rename_fragment_execution");
      File_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      S         : Editor.State.State_Type;
      Opened    : Editor.Project.Project_Open_Result;
      Found     : Boolean := False;
      Row_Found : Boolean := False;
      Msg_Found : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row       : Natural := 0;
      Msg       : Editor.Messages.Editor_Message;
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 rename fragment setup must find file node");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 rename fragment setup must map file row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);

      Rename_Cmd.Text := To_Unbounded_String ("src/renamed.adb");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Msg := Editor.Messages.Active_Message (S.Messages, Msg_Found);

      Assert (Msg_Found
              and then To_String (Msg.Text) = "Rename expects a single new name",
              "Phase 572 direct rename execution must explain leaf-name-only input");
      Assert (Ada.Directories.Exists (File_Path),
              "Phase 572 path-fragment rename execution must leave source intact");
      Assert (not Ada.Directories.Exists
                (Ada.Directories.Compose (Root, "src/renamed.adb")),
              "Phase 572 path-fragment rename execution must not create a target");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Rename_Path_Fragment_Execution_Message;


   procedure Test_Phase572_Mutations_Mark_Quick_Open_Stale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("phase572_quick_open_stale");
      Created   : constant String := Ada.Directories.Compose (Root, "quick_new.adb");
      Renamed   : constant String := Ada.Directories.Compose (Root, "quick_renamed.txt");
      S         : Editor.State.State_Type;
      Opened    : Editor.Project.Project_Open_Result;
      Config    : Editor.Quick_Open.Quick_Open_Config;
      Found     : Boolean := False;
      Row_Found : Boolean := False;
      Node      : Editor.File_Tree.File_Tree_Node_Id :=
        Editor.File_Tree.No_File_Tree_Node;
      Row       : Natural := 0;
      Create_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Create_File);
      Rename_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Rename_Selected);
      Delete_Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id
          (Editor.Commands.Command_File_Tree_Delete_Selected);
   begin
      Build_Fixture (Root);
      Editor.State.Init (S);
      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (S.Project, Opened);
      S.File_Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Panel_Focus.Focus_File_Tree (S.Panel_Focus);
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, 1);

      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "a");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.File_Tree, Config);
      Editor.Quick_Open.Open (S.Quick_Open);
      Assert (not Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 setup should start with fresh Quick Open results");
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) > 0,
              "Phase 572 setup should have Quick Open candidates");

      Create_Cmd.Text := To_Unbounded_String ("quick_new.adb");
      Editor.Executor.Execute_No_Log (S, Create_Cmd);
      Assert (Ada.Directories.Exists (Created),
              "Phase 572 Quick Open stale setup must create the file");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "Phase 572 File Tree mutation must preserve open Quick Open UI state");
      Assert (Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 create-file must mark open Quick Open results stale");
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) = 0,
              "Phase 572 stale open Quick Open results must not expose old candidates");
      Assert (Editor.Quick_Open.Known_Count (S.Quick_Open) = 0,
              "Phase 572 stale Quick Open projection must clear retained known count");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S.Quick_Open) = 0,
              "Phase 572 stale Quick Open projection must clear retained filtered count");

      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.File_Tree, Config);
      Assert (not Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 Quick Open recompute should clear stale state");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "a.txt", Found);
      Assert (Found, "Phase 572 Quick Open stale setup must find rename source");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 Quick Open stale setup must map rename row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Rename_Cmd.Text := To_Unbounded_String ("quick_renamed.txt");
      Editor.Executor.Execute_No_Log (S, Rename_Cmd);
      Assert (Ada.Directories.Exists (Renamed),
              "Phase 572 Quick Open stale setup must rename the file");
      Assert (Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 rename must mark Quick Open results stale");
      Assert (Editor.Quick_Open.Known_Count (S.Quick_Open) = 0,
              "Phase 572 rename stale Quick Open projection must clear known count");

      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.File_Tree, Config);
      Assert (not Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 Quick Open recompute should clear stale state after rename");

      Node := Editor.File_Tree.Find_By_Path (S.File_Tree, "quick_renamed.txt", Found);
      Assert (Found, "Phase 572 Quick Open stale setup must find delete source");
      Row := Editor.File_Tree_View.Row_For_Node (S.File_Tree, Node, Row_Found);
      Assert (Row_Found, "Phase 572 Quick Open stale setup must map delete row");
      Editor.File_Tree_View.Set_Selected_Row_Index (S.File_Tree_View, Row);
      Delete_Cmd.Text := To_Unbounded_String ("confirm");
      Editor.Executor.Execute_No_Log (S, Delete_Cmd);
      Assert (not Ada.Directories.Exists (Renamed),
              "Phase 572 Quick Open stale setup must delete the file");
      Assert (Editor.Quick_Open.Results_Are_Stale (S.Quick_Open),
              "Phase 572 delete must mark Quick Open results stale");
      Assert (Editor.Quick_Open.Known_Count (S.Quick_Open) = 0,
              "Phase 572 delete stale Quick Open projection must clear known count");

      Cleanup_Fixture (Root);
   exception
      when others =>
         Remove_Any_If_Exists (Root);
         raise;
   end Test_Phase572_Mutations_Mark_Quick_Open_Stale;


   overriding procedure Register_Tests
     (T : in out File_Tree_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_And_Validation'Access,
         "Clear And Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scan_Order_And_Root'Access,
         "Scan Order And Root");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Expansion_And_Lookup'Access,
         "Expansion And Lookup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Node_Iteration'Access,
         "File Node Iteration");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase533_Open_Selected_Requires_File_Node'Access,
         "Phase 533 open selected requires file node");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase545_Collapse_All_And_Expand_Ancestors'Access,
         "Phase 545 collapse all and expand ancestors");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase545_Preserve_Hidden_Expansion_On_Refresh'Access,
         "Phase 545 preserve hidden expansion on refresh");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase545_Node_Kind_Labels'Access,
         "Phase 545 node kind labels");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Delete_Empty_Directory_Only'Access,
         "Phase 572 delete empty directory only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Delete_Rejects_Hidden_File_Directory'Access,
         "Phase 572 delete rejects hidden-file-only directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rejects_Stale_Kind_Replacements'Access,
         "Phase 572 rejects stale kind replacements");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Project_Root_And_Same_Name_Guards'Access,
         "Phase 572 project root and same-name guards");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Missing_Source_Message_Precedes_Canonical_Guard'Access,
         "Phase 572 missing source message before canonical guard");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Create_Rejects_Drive_Relative_Text_At_Execution'Access,
         "Phase 572 create rejects drive-relative text at execution");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Create_Rejects_Traversal_As_Invalid_Input'Access,
         "Phase 572 create rejects traversal as invalid input");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Create_Rejects_Absolute_Text_As_Project_Relative'Access,
         "Phase 572 create rejects absolute text as project-relative");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Create_Rejects_Stale_Selected_Base'Access,
         "Phase 572 create rejects stale selected base");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Operation_Outcome_Messages'Access,
         "Phase 572 operation outcome messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Dirty_Open_Buffer_Block_Messages'Access,
         "Phase 572 dirty open buffer block messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Mutation_Marks_Path_Diagnostics_Stale'Access,
         "Phase 572 mutation marks path diagnostics stale");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Empty_Execution_Uses_Name_Guidance'Access,
         "Phase 572 empty execution uses name guidance");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Rename_Path_Fragment_Execution_Message'Access,
         "Phase 572 rename path fragment execution message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase572_Mutations_Mark_Quick_Open_Stale'Access,
         "Phase 572 mutations mark Quick Open stale");
   end Register_Tests;

end Editor.File_Tree.Tests;
