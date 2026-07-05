with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Editor.File_Tree;
with Editor.File_Tree_View;
with Editor.Layout;
with Editor.Panels;

package body Editor.File_Tree_View.Tests is

   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree_View.File_Tree_View_Zone;
   use type Editor.File_Tree_View.File_Tree_Action;

   package Stream_IO renames Ada.Streams.Stream_IO;

   procedure Disable_File_Tree_Panel
     (Layout : in out Editor.Layout.Layout_Config)
   is
      Panels : Editor.Panels.Panel_Set := Layout.Panels;
      Config : Editor.Panels.Panel_Config :=
        Editor.Panels.Config (Panels, Editor.Panels.File_Tree_Panel);
   begin
      Config.Enabled := False;
      Editor.Panels.Set_Config
        (Panels, Editor.Panels.File_Tree_Panel, Config);
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.File_Tree_Panel, False);
      Layout.Panels := Panels;
      Layout.File_Tree_View.Enabled := False;
   end Disable_File_Tree_Panel;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "view_" & Name);
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

   procedure Build_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (A_Dir);
      Write_Bytes (Ada.Directories.Compose (A_Dir, "nested.txt"), "nested");
      Write_Bytes (Ada.Directories.Compose (Root, "a.txt"), "a");
   end Build_Fixture;

   procedure Cleanup_Fixture (Root : String) is
      A_Dir : constant String := Ada.Directories.Compose (Root, "a_dir");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (A_Dir, "nested.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_Dir_If_Exists (A_Dir);
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   function Default_Geometry (Rows : Natural := 8)
     return Editor.File_Tree_View.File_Tree_Geometry
   is
   begin
      return
        (X      => 0,
         Y      => 0,
         Width  => 400,
         Height => Rows * Editor.Layout.Cell_H);
   end Default_Geometry;

   overriding function Name
     (T : File_Tree_View_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.File_Tree_View");
   end Name;

   procedure Test_Default_Enabled_And_Width
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Disabled : Editor.File_Tree_View.File_Tree_View_Config := Config;
   begin
      Assert (Editor.File_Tree_View.Enabled (Config),
              "file tree view must be enabled by default");
      Assert (Editor.File_Tree_View.Width_In_Pixels (Config, 9) = 28 * 9,
              "Width_In_Pixels must use font-derived cell width");

      Disabled.Enabled := False;
      Assert (Editor.File_Tree_View.Width_In_Columns (Disabled) = 0,
              "disabled file tree view must report zero width columns");
      Assert (Editor.File_Tree_View.Width_In_Pixels (Disabled, 9) = 0,
              "disabled file tree view must report zero width pixels");
   end Test_Default_Enabled_And_Width;

   procedure Test_Width_Clamping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
   begin
      Config.Default_Width_In_Columns := 4;
      Assert (Editor.File_Tree_View.Width_In_Columns (Config) = 16,
              "view width must clamp to the configured minimum");

      Config.Default_Width_In_Columns := 100;
      Assert (Editor.File_Tree_View.Width_In_Columns (Config) = 60,
              "view width must clamp to the configured maximum");
   end Test_Width_Clamping;

   procedure Test_Width_State_Clamping_And_Disabled_Effective_Width
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      State  : Editor.File_Tree_View.File_Tree_View_State :=
        (Width_In_Columns => 28, others => <>);
      Disabled : Editor.File_Tree_View.File_Tree_View_Config := Config;
   begin
      Assert (Editor.File_Tree_View.Clamp_Width_In_Columns (Config, 1) = 16,
              "Clamp_Width_In_Columns must clamp below minimum");
      Assert (Editor.File_Tree_View.Clamp_Width_In_Columns (Config, 100) = 60,
              "Clamp_Width_In_Columns must clamp above maximum");
      Assert (Editor.File_Tree_View.Clamp_Width_In_Columns (Config, 32) = 32,
              "Clamp_Width_In_Columns must preserve in-range widths");

      Editor.File_Tree_View.Set_Width_In_Columns (State, Config, 4);
      Assert (State.Width_In_Columns = 16,
              "Set_Width_In_Columns must store the clamped minimum");

      Editor.File_Tree_View.Set_Width_In_Columns (State, Config, 44);
      Disabled.Enabled := False;
      Assert (Editor.File_Tree_View.Effective_Width_In_Columns
                (Disabled, State) = 0,
              "disabled file tree must have zero effective width");

      Disabled.Enabled := True;
      Assert (Editor.File_Tree_View.Effective_Width_In_Columns
                (Disabled, State) = 44,
              "re-enabled file tree must preserve the stored width");
   end Test_Width_State_Clamping_And_Disabled_Effective_Width;

   procedure Test_Resized_Format_Row_Text_Truncation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Node : Editor.File_Tree.File_Tree_Node_Summary :=
        (Id            => 1,
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.File_Node,
         Name          => To_Unbounded_String ("very_long_file_name.adb"),
         Absolute_Path => Null_Unbounded_String,
         Relative_Path => To_Unbounded_String ("very_long_file_name.adb"),
         Depth         => 1,
         Is_Expanded   => False,
         Has_Children  => False);
      Narrow : constant String :=
        Editor.File_Tree_View.Format_Row_Text (Config, Node, 10);
      Wide : constant String :=
        Editor.File_Tree_View.Format_Row_Text (Config, Node, 18);
   begin
      Assert (Narrow'Length = 10,
              "narrow resized sidebar text must be clipped to narrow width");
      Assert (Wide'Length = 18,
              "wide resized sidebar text must be clipped to wide width");
      Assert (Wide'Length > Narrow'Length,
              "wider resized sidebar must expose more label columns");
   end Test_Resized_Format_Row_Text_Truncation;

   procedure Test_Truncate_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.File_Tree_View.Truncate_Label ("main.adb", 8) = "main.adb",
              "Truncate_Label must preserve labels that fit");
      Assert (Editor.File_Tree_View.Truncate_Label ("abcdefghij", 7) = "abcd...",
              "Truncate_Label must append deterministic ellipsis when too long");
      Assert (Editor.File_Tree_View.Truncate_Label ("abcdefghij", 2) = "..",
              "Truncate_Label must handle very small widths deterministically");
      Assert (Editor.File_Tree_View.Truncate_Label ("abcdefghij", 0) = "",
              "Truncate_Label must return empty text for zero columns");
   end Test_Truncate_Label;

   procedure Test_Format_Row_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Dir : Editor.File_Tree.File_Tree_Node_Summary :=
        (Id            => 1,
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.Directory_Node,
         Name          => To_Unbounded_String ("src"),
         Absolute_Path => Null_Unbounded_String,
         Relative_Path => To_Unbounded_String ("src"),
         Depth         => 1,
         Is_Expanded   => True,
         Has_Children  => True);
      File : Editor.File_Tree.File_Tree_Node_Summary := Dir;
   begin
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Dir, 24) = "  - [dir] src",
              "expanded directory row must include indentation and '-' marker");

      Dir.Is_Expanded := False;
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Dir, 24) = "  + [dir] src",
              "collapsed directory row must include indentation and '+' marker");

      File.Kind := Editor.File_Tree.File_Node;
      File.Name := To_Unbounded_String ("main.adb");
      File.Depth := 2;
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, File, 24) = "      [file] main.adb",
              "file row must reserve marker spacing and respect indentation");
   end Test_Format_Row_Text;


   procedure Test_Format_Row_Text_Does_Not_Exceed_Width
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Node : Editor.File_Tree.File_Tree_Node_Summary :=
        (Id            => 1,
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.File_Node,
         Name          => To_Unbounded_String ("very_long_file_name.adb"),
         Absolute_Path => Null_Unbounded_String,
         Relative_Path => To_Unbounded_String ("very_long_file_name.adb"),
         Depth         => 3,
         Is_Expanded   => False,
         Has_Children  => False);
   begin
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Node, 0) = "",
              "zero-width file tree row text must be empty");
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Node, 4)'Length = 4,
              "row text must not exceed width when indentation consumes the row");
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Node, 10)'Length = 10,
              "row text must not exceed width when label is truncated");
   end Test_Format_Row_Text_Does_Not_Exceed_Width;

   procedure Test_Layout_Disabled_Width
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : Editor.Layout.Layout_Config := Editor.Layout.Current;
   begin
      Assert (Editor.Layout.File_Tree_Width (Layout) > 0,
              "default layout must reserve a file tree sidebar");
      Disable_File_Tree_Panel (Layout);
      Assert (Editor.Layout.File_Tree_Width (Layout) = 0,
              "disabled file tree view must reserve zero layout width");
   end Test_Layout_Disabled_Width;



   procedure Test_Layout_Splitter_Geometry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Layout : Editor.Layout.Layout_Config := Editor.Layout.Current;
      Viewport_Height : constant Natural := 480;
      Splitter_X : constant Integer :=
        Editor.Layout.File_Tree_Splitter_X (Layout);
      Splitter_Y : constant Integer :=
        Editor.Layout.File_Tree_Splitter_Y (Layout);
   begin
      Assert (Splitter_X = Editor.Layout.File_Tree_Right (Layout),
              "splitter x must equal the file tree right edge");
      Assert (Splitter_Y = Integer (Editor.Layout.Tab_Bar_Height (Layout)),
              "splitter y must start below the tab bar");
      Assert (Editor.Layout.File_Tree_Splitter_Height
                (Layout, Viewport_Height) =
              Editor.Layout.Text_Viewport_Height (Layout, Viewport_Height),
              "splitter height must end above the status bar");
      Assert (Editor.Layout.Editor_Body_X (Layout) =
              Natural (Editor.Layout.File_Tree_Right (Layout))
              + Editor.Layout.File_Tree_Splitter_Width (Layout),
              "editor body x must include file tree and splitter widths");
      Assert (Editor.Layout.Is_In_File_Tree_Splitter
                (Layout, Splitter_X, Splitter_Y, Viewport_Height),
              "splitter must be hit-testable inside its rectangle");

      Disable_File_Tree_Panel (Layout);
      Assert (Editor.Layout.File_Tree_Splitter_Width (Layout) = 0,
              "disabled file tree must have zero splitter width");
      Assert (not Editor.Layout.Is_In_File_Tree_Splitter
                (Layout, Splitter_X, Splitter_Y, Viewport_Height),
              "disabled file tree splitter must not be hit-testable");
   end Test_Layout_Splitter_Geometry;




   procedure Test_Layout_Gutter_And_Text_Shift_With_Resize
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Narrow : Editor.Layout.Layout_Config;
      Wide   : Editor.Layout.Layout_Config;
      Lines  : constant Natural := 128;
      Step_Delta  : constant Natural := 20 * Editor.Layout.Cell_W;
   begin
      Editor.File_Tree_View.Reset;
      Editor.File_Tree_View.Set_Current_Width_In_Columns (20);
      Narrow := Editor.Layout.Current;

      Editor.File_Tree_View.Set_Current_Width_In_Columns (40);
      Wide := Editor.Layout.Current;

      Assert
        (Natural (Editor.Layout.Gutter_Left (Wide)) =
         Natural (Editor.Layout.Gutter_Left (Narrow)) + Step_Delta,
         "gutter x must shift only through layout when the sidebar is resized");
      Assert
        (Editor.Layout.Text_Origin_X (Wide, Lines) =
         Editor.Layout.Text_Origin_X (Narrow, Lines) + Step_Delta,
         "text origin x must shift only through layout when the sidebar is resized");
      Assert
        (Editor.Layout.Text_Viewport_Width (Wide, Lines, 900) + Step_Delta =
         Editor.Layout.Text_Viewport_Width (Narrow, Lines, 900),
         "text viewport width must shrink by the sidebar resize delta");
      Assert
        (Editor.Layout.Text_Viewport_Width (Wide, Lines, 1) = 0,
         "very narrow windows must clamp text viewport width to zero");

      Editor.File_Tree_View.Reset;
   end Test_Layout_Gutter_And_Text_Shift_With_Resize;

   procedure Test_Hit_Test_Visible_Rows_And_Background
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("hit_root");
      Tree : Editor.File_Tree.File_Tree_State;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
      A_Dir : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      A_Dir := Editor.File_Tree.Find_By_Path (Tree, "a_dir", Found);
      Assert (Found, "fixture must contain a_dir");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, 4, 4);
      Assert (Hit.Zone = Editor.File_Tree_View.File_Tree_Row_Zone
              or else Hit.Zone = Editor.File_Tree_View.File_Tree_Expansion_Zone
              or else Hit.Zone = Editor.File_Tree_View.File_Tree_Label_Zone,
              "first visible row must hit a row-specific zone");
      Assert (Hit.Row = 1, "first visible row must report display row one");
      Assert (Hit.Node_Id = Editor.File_Tree.Root (Tree),
              "first visible row must map to root node");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, 4, Editor.Layout.Cell_H + 4);
      Assert (Hit.Row = 2, "second visible row must report display row two");
      Assert (Hit.Node_Id = A_Dir, "second visible row must map to a_dir");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, 4, 6 * Editor.Layout.Cell_H + 1);
      Assert (Hit.Zone = Editor.File_Tree_View.File_Tree_Background_Zone,
              "clicks below rendered rows but inside sidebar must hit background");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry (Rows => 1), Config, Tree, 4, Editor.Layout.Cell_H + 1);
      Assert (Hit.Zone = Editor.File_Tree_View.Outside_File_Tree,
              "Y outside sidebar height must be outside file tree");

      Cleanup_Fixture (Root);
   end Test_Hit_Test_Visible_Rows_And_Background;

   procedure Test_Hit_Test_Zones_And_Disabled
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("zone_root");
      Tree : Editor.File_Tree.File_Tree_State;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Disabled : Editor.File_Tree_View.File_Tree_View_Config := Config;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
      Cell_W : constant Positive := Editor.Layout.Cell_W;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree,
         Cell_W + 1, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.File_Tree_Expansion_Zone,
              "directory marker column must hit expansion zone");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree,
         (3 * Cell_W) + 1, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.File_Tree_Label_Zone,
              "directory label columns must hit label zone");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree,
         (3 * Cell_W) + 1, 2 * Editor.Layout.Cell_H + 1);
      Assert (Hit.Zone /= Editor.File_Tree_View.File_Tree_Expansion_Zone,
              "file marker area must not hit expansion zone");

      Disabled.Enabled := False;
      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Disabled, Tree, 1, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.Outside_File_Tree,
              "disabled file tree must not hit-test");

      Cleanup_Fixture (Root);
   end Test_Hit_Test_Zones_And_Disabled;



   procedure Test_Hit_Test_Outside_Empty_And_Hidden_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("outside_root");
      Tree : Editor.File_Tree.File_Tree_State;
      Empty_Tree : Editor.File_Tree.File_Tree_State;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
      Nested_Id : Editor.File_Tree.File_Tree_Node_Id;
      Found : Boolean := False;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Nested_Id := Editor.File_Tree.Find_By_Path (Tree, "a_dir/nested.txt", Found);
      Assert (Found, "fixture must contain hidden nested child");

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, -1, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.Outside_File_Tree,
              "X before file tree must be outside");
      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, 1, -1);
      Assert (Hit.Zone = Editor.File_Tree_View.Outside_File_Tree,
              "Y before file tree must be outside");
      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree, 401, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.Outside_File_Tree,
              "X after file tree must be outside");

      --  a_dir is collapsed in the fixture, so nested.txt exists in the model
      --  but must not be hit-testable through any visible row.
      for Row in 1 .. Editor.File_Tree.Visible_Row_Count (Tree) loop
         Hit := Editor.File_Tree_View.Hit_Test
           (Default_Geometry, Config, Tree,
            5 * Editor.Layout.Cell_W,
            (Row - 1) * Editor.Layout.Cell_H + 1);
         Assert (Hit.Node_Id /= Nested_Id,
                 "collapsed descendants must not be exposed by hit-testing");
      end loop;

      Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Empty_Tree, 1, 1);
      Assert (Hit.Zone = Editor.File_Tree_View.File_Tree_Background_Zone,
              "empty enabled file tree must consume sidebar clicks as background");

      Cleanup_Fixture (Root);
   end Test_Hit_Test_Outside_Empty_And_Hidden_Rows;

   procedure Test_Action_For_Hit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("action_root");
      Tree : Editor.File_Tree.File_Tree_State;
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Dir_Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
      File_Hit : Editor.File_Tree_View.File_Tree_Hit_Result;
      Background_Hit : constant Editor.File_Tree_View.File_Tree_Hit_Result :=
        (Zone => Editor.File_Tree_View.File_Tree_Background_Zone,
         Row => 0,
         Node_Id => Editor.File_Tree.No_File_Tree_Node);
      Invalid_Hit : constant Editor.File_Tree_View.File_Tree_Hit_Result :=
        (Zone => Editor.File_Tree_View.File_Tree_Label_Zone,
         Row => 1,
         Node_Id => Editor.File_Tree.File_Tree_Node_Id'Last);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Dir_Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree,
         Editor.Layout.Cell_W + 1, 1);
      Assert (Editor.File_Tree_View.Action_For_Hit (Tree, Dir_Hit) =
              Editor.File_Tree_View.Toggle_Directory_Action,
              "directory hit must map to toggle action");

      File_Hit := Editor.File_Tree_View.Hit_Test
        (Default_Geometry, Config, Tree,
         (5 * Editor.Layout.Cell_W) + 1, 2 * Editor.Layout.Cell_H + 1);
      Assert (Editor.File_Tree_View.Action_For_Hit (Tree, File_Hit) =
              Editor.File_Tree_View.Open_File_Action,
              "file hit must map to open action");

      Assert (Editor.File_Tree_View.Action_For_Hit (Tree, Background_Hit) =
              Editor.File_Tree_View.No_File_Tree_Action,
              "background hit must map to no action");
      Assert (Editor.File_Tree_View.Action_For_Hit (Tree, Invalid_Hit) =
              Editor.File_Tree_View.No_File_Tree_Action,
              "invalid node hit must map to no action");

      Cleanup_Fixture (Root);
   end Test_Action_For_Hit;



   procedure Test_Default_Selection_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      View : Editor.File_Tree_View.File_Tree_View_State;
   begin
      Assert (Editor.File_Tree_View.Selected_Row_Index (View) = 0,
              "new file tree view state must have no selected row");
      Assert (Editor.File_Tree_View.Top_Row (View) = 1,
              "new file tree view state must start at top row 1");
   end Test_Default_Selection_State;

   procedure Test_Selection_And_Row_Mapping
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("selection_root");
      Tree : Editor.File_Tree.File_Tree_State;
      View : Editor.File_Tree_View.File_Tree_View_State;
      Found : Boolean := False;
      Node  : Editor.File_Tree.File_Tree_Node_Id;
      Row   : Natural;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);

      Editor.File_Tree_View.Ensure_Valid_Selection (View, Tree);
      Assert (Editor.File_Tree_View.Selected_Row_Index (View) = 1,
              "valid non-empty file tree should select the first visible row");

      Editor.File_Tree_View.Move_Selection
        (View, Tree, Editor.File_Tree_View.Next_Row);
      Assert (Editor.File_Tree_View.Selected_Row_Index (View) = 2,
              "moving down should select the next visible row");

      Node := Editor.File_Tree_View.Node_For_Row (Tree, 2, Found);
      Assert (Found and then Node /= Editor.File_Tree.No_File_Tree_Node,
              "Node_For_Row should map visible row 2 to a node");
      Row := Editor.File_Tree_View.Row_For_Node (Tree, Node, Found);
      Assert (Found and then Row = 2,
              "Row_For_Node should map the selected node back to row 2");

      Editor.File_Tree_View.Move_Selection
        (View, Tree, Editor.File_Tree_View.Previous_Row);
      Editor.File_Tree_View.Move_Selection
        (View, Tree, Editor.File_Tree_View.Previous_Row);
      Assert (Editor.File_Tree_View.Selected_Row_Index (View) = 1,
              "moving up at the first row must clamp");

      Cleanup_Fixture (Root);
   end Test_Selection_And_Row_Mapping;

   procedure Test_Selected_Row_Visibility
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("visibility_root");
      Tree : Editor.File_Tree.File_Tree_State;
      View : Editor.File_Tree_View.File_Tree_View_State;
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.File_Tree_View.Set_Selected_Row_Index (View, 3);
      Editor.File_Tree_View.Ensure_Selected_Row_Visible (View, Tree, 2);
      Assert (Editor.File_Tree_View.Top_Row (View) = 2,
              "selected row below the visible window should scroll down");
      Editor.File_Tree_View.Set_Selected_Row_Index (View, 1);
      Editor.File_Tree_View.Ensure_Selected_Row_Visible (View, Tree, 2);
      Assert (Editor.File_Tree_View.Top_Row (View) = 1,
              "selected row above the visible window should scroll up");
      Cleanup_Fixture (Root);
   end Test_Selected_Row_Visibility;


   procedure Test_Safe_Display_Label_And_Empty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : Editor.File_Tree_View.File_Tree_View_Config;
      Folder : Editor.File_Tree.File_Tree_Node_Summary :=
        (Id            => 1,
         Parent        => Editor.File_Tree.No_File_Tree_Node,
         Kind          => Editor.File_Tree.Directory_Node,
         Name          => Null_Unbounded_String,
         Absolute_Path => Null_Unbounded_String,
         Relative_Path => Null_Unbounded_String,
         Depth         => 0,
         Is_Expanded   => False,
         Has_Children  => False);
      File : Editor.File_Tree.File_Tree_Node_Summary := Folder;
   begin
      File.Kind := Editor.File_Tree.File_Node;

      Assert (Editor.File_Tree_View.Empty_State_Text = "No project files",
              "empty file tree state must use deterministic user-facing text");
      Assert (Editor.File_Tree_View.Safe_Display_Label (Folder) = "<unnamed folder>",
              "empty directory labels must use a safe fallback");
      Assert (Editor.File_Tree_View.Safe_Display_Label (File) = "<unnamed file>",
              "empty file labels must use a safe fallback");
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, Folder, 32) = "+ [dir] <unnamed folder>",
              "formatted empty directory row must include the safe folder fallback");
      Assert (Editor.File_Tree_View.Format_Row_Text (Config, File, 32) = "  [file] <unnamed file>",
              "formatted empty file row must include the safe file fallback");
   end Test_Safe_Display_Label_And_Empty_State;

   overriding procedure Register_Tests
     (T : in out File_Tree_View_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Default_Enabled_And_Width'Access,
         "Default Enabled And Width");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Width_Clamping'Access,
         "Width Clamping");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Width_State_Clamping_And_Disabled_Effective_Width'Access,
         "Width State Clamping And Disabled Effective Width");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Resized_Format_Row_Text_Truncation'Access,
         "Resized Format Row Text Truncation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Truncate_Label'Access,
         "Truncate Label");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Row_Text'Access,
         "Format Row Text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Format_Row_Text_Does_Not_Exceed_Width'Access,
         "Format Row Text Does Not Exceed Width");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Layout_Disabled_Width'Access,
         "Layout Disabled Width");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Layout_Splitter_Geometry'Access,
         "Layout Splitter Geometry");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Layout_Gutter_And_Text_Shift_With_Resize'Access,
         "Layout Gutter And Text Shift With Resize");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Visible_Rows_And_Background'Access,
         "Hit Test Rows And Background");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Zones_And_Disabled'Access,
         "Hit Test Zones And Disabled");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Hit_Test_Outside_Empty_And_Hidden_Rows'Access,
         "Hit Test Outside Empty And Hidden Rows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Action_For_Hit'Access,
         "Action For Hit");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Default_Selection_State'Access,
         "default file tree keyboard selection state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selection_And_Row_Mapping'Access,
         "file tree selection movement and row mapping");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Row_Visibility'Access,
         "file tree selected row visibility");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Safe_Display_Label_And_Empty_State'Access,
         "safe file tree display labels and empty state");
   end Register_Tests;

end Editor.File_Tree_View.Tests;
