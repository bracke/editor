with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Panels;
with Editor.File_Tree_View;
with Editor.Layout;

package body Editor.Panels.Tests is

   use type Editor.Panels.Panel_Id;
   use type Editor.Panels.Bottom_Panel_Content;

   function Name
     (T : Panels_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Panels.Tests");
   end Name;

   procedure Test_Initialize_Defaults_File_Tree_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
   begin
      Editor.File_Tree_View.Reset;
      Editor.Panels.Initialize_Defaults (Panels);

      Assert
        (Editor.Panels.Is_Visible
           (Panels, Editor.Panels.File_Tree_Panel),
         "default file tree panel should be visible when file tree view is enabled");
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.File_Tree_Panel) = 28,
         "default file tree panel should preserve the Phase 58 default width");
      Assert
        (not Editor.Panels.Is_Visible
           (Panels, Editor.Panels.Right_Sidebar_Panel),
         "right sidebar placeholder must be invisible by default");
      Assert
        (not Editor.Panels.Is_Visible
           (Panels, Editor.Panels.Bottom_Panel),
         "bottom Problems panel must be hidden by default");
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.Bottom_Panel) = 8,
         "bottom Problems panel should preserve its default row size while hidden");
      Assert
        (Editor.Panels.Config
           (Panels, Editor.Panels.Bottom_Panel).Resizable,
         "bottom Problems panel splitter should be resizable by default");
   end Test_Initialize_Defaults_File_Tree_Visible;

   procedure Test_Clamp_Size
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config : constant Editor.Panels.Panel_Config :=
        (Enabled              => True,
         Side                 => Editor.Panels.Left_Side,
         Default_Size         => 28,
         Minimum_Size         => 16,
         Maximum_Size         => 60,
         Splitter_Size_Pixels => 4,
         Size_Unit            => Editor.Panels.Columns,
         Resizable            => True);
   begin
      Assert (Editor.Panels.Clamp_Size (Config, 1) = 16,
              "Clamp_Size should clamp below minimum");
      Assert (Editor.Panels.Clamp_Size (Config, 70) = 60,
              "Clamp_Size should clamp above maximum");
      Assert (Editor.Panels.Clamp_Size (Config, 32) = 32,
              "Clamp_Size should keep in-range sizes unchanged");
   end Test_Clamp_Size;

   procedure Test_Set_Visible_Preserves_Size
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
   begin
      Editor.File_Tree_View.Reset;
      Editor.Panels.Initialize_Defaults (Panels);
      Editor.Panels.Set_Current_Size
        (Panels, Editor.Panels.File_Tree_Panel, 36);
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.File_Tree_Panel, False);

      Assert
        (not Editor.Panels.Is_Visible
           (Panels, Editor.Panels.File_Tree_Panel),
         "hidden file tree panel should not be visible");
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.File_Tree_Panel) = 36,
         "hiding a panel must not lose its stored size");

      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.File_Tree_Panel, True);
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.File_Tree_Panel) = 36,
         "showing a panel should restore its stored size");
   end Test_Set_Visible_Preserves_Size;

   procedure Test_Left_Resize_Delta
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
   begin
      Editor.File_Tree_View.Reset;
      Editor.Panels.Initialize_Defaults (Panels);
      Editor.Panels.Begin_Resize
        (Panels, Editor.Panels.File_Tree_Panel, Mouse_X => 100, Mouse_Y => 10);
      Assert (Editor.Panels.Resize_Active (Panels),
              "Begin_Resize should activate resize capture");

      Editor.Panels.Update_Resize
        (Panels, Mouse_X => 124, Mouse_Y => 10, Cell_Width => 8, Cell_Height => 16);
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.File_Tree_Panel) = 31,
         "dragging a left panel right by three cells should increase size");

      Editor.Panels.Update_Resize
        (Panels, Mouse_X => 84, Mouse_Y => 10, Cell_Width => 8, Cell_Height => 16);
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.File_Tree_Panel) = 26,
         "dragging a left panel left by two cells should decrease from start size");

      Editor.Panels.End_Resize (Panels);
      Assert (not Editor.Panels.Resize_Active (Panels),
              "End_Resize should clear resize capture");
   end Test_Left_Resize_Delta;


   procedure Test_Right_And_Bottom_Resize_Deltas
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
      Right_Config : constant Editor.Panels.Panel_Config :=
        (Enabled              => True,
         Side                 => Editor.Panels.Right_Side,
         Default_Size         => 20,
         Minimum_Size         => 5,
         Maximum_Size         => 40,
         Splitter_Size_Pixels => 4,
         Size_Unit            => Editor.Panels.Columns,
         Resizable            => True);
      Bottom_Config : constant Editor.Panels.Panel_Config :=
        (Enabled              => True,
         Side                 => Editor.Panels.Bottom_Side,
         Default_Size         => 10,
         Minimum_Size         => 3,
         Maximum_Size         => 20,
         Splitter_Size_Pixels => 4,
         Size_Unit            => Editor.Panels.Rows,
         Resizable            => True);
   begin
      Editor.Panels.Initialize_Defaults (Panels);

      Editor.Panels.Set_Config
        (Panels, Editor.Panels.Right_Sidebar_Panel, Right_Config);
      Editor.Panels.Set_Current_Size
        (Panels, Editor.Panels.Right_Sidebar_Panel, 20);
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.Right_Sidebar_Panel, True);
      Editor.Panels.Begin_Resize
        (Panels, Editor.Panels.Right_Sidebar_Panel, Mouse_X => 200, Mouse_Y => 10);
      Editor.Panels.Update_Resize
        (Panels, Mouse_X => 176, Mouse_Y => 10, Cell_Width => 8, Cell_Height => 16);
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.Right_Sidebar_Panel) = 23,
         "dragging a right panel left should increase its size");
      Editor.Panels.End_Resize (Panels);

      Editor.Panels.Set_Config
        (Panels, Editor.Panels.Bottom_Panel, Bottom_Config);
      Editor.Panels.Set_Current_Size
        (Panels, Editor.Panels.Bottom_Panel, 10);
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Begin_Resize
        (Panels, Editor.Panels.Bottom_Panel, Mouse_X => 20, Mouse_Y => 200);
      Editor.Panels.Update_Resize
        (Panels, Mouse_X => 20, Mouse_Y => 168, Cell_Width => 8, Cell_Height => 16);
      Assert
        (Editor.Panels.Current_Size
           (Panels, Editor.Panels.Bottom_Panel) = 12,
         "dragging a bottom panel upward should increase its row size");
      Editor.Panels.End_Resize (Panels);
   end Test_Right_And_Bottom_Resize_Deltas;


   procedure Test_Bottom_Panel_Layout_Reserves_Height
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
      Layout : Editor.Layout.Layout_Config;
      Body_Closed : Editor.Layout.Rect;
      Body_Open : Editor.Layout.Rect;
      Bottom : Editor.Layout.Rect;
      Splitter : Editor.Layout.Rect;
      View_W : constant Natural := 800;
      View_H : constant Natural := 600;
   begin
      Editor.Panels.Initialize_Defaults (Panels);
      Editor.Panels.Set_Current (Panels);
      Layout := Editor.Layout.Current;
      Body_Closed := Editor.Layout.Editor_Body_Rect (Layout, View_W, View_H);

      Editor.Panels.Set_Visible (Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Set_Current (Panels);
      Layout := Editor.Layout.Current;
      Body_Open := Editor.Layout.Editor_Body_Rect (Layout, View_W, View_H);
      Bottom := Editor.Layout.Panel_Rect
        (Layout, Editor.Panels.Bottom_Panel, View_W, View_H);
      Splitter := Editor.Layout.Panel_Splitter_Rect
        (Layout, Editor.Panels.Bottom_Panel, View_W, View_H);

      Assert (Bottom.Height = 8 * Editor.Layout.Cell_H,
              "visible bottom panel must reserve its configured row height");
      Assert (Bottom.Y + Integer (Bottom.Height)
              = Editor.Layout.Status_Bar_Y (Layout, View_H),
              "bottom panel must sit immediately above the status bar");
      Assert (Splitter.Y + Integer (Splitter.Height) = Bottom.Y,
              "bottom splitter must sit immediately above the bottom panel");
      Assert (Body_Open.Height + Bottom.Height + Splitter.Height
              = Body_Closed.Height,
              "editor body height must shrink by bottom panel plus splitter");
      Assert (Body_Open.Y = Body_Closed.Y,
              "bottom panel must not move the top of the editor body");

      Editor.Panels.Initialize_Defaults (Panels);
      Editor.Panels.Set_Current (Panels);
   end Test_Bottom_Panel_Layout_Reserves_Height;



   procedure Test_Bottom_Content_Switching_Preserves_Geometry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Panels : Editor.Panels.Panel_Set;
      Layout : Editor.Layout.Layout_Config;
      Problems_Rect : Editor.Layout.Rect;
      Search_Rect   : Editor.Layout.Rect;
      View_W : constant Natural := 800;
      View_H : constant Natural := 600;
   begin
      Editor.Panels.Initialize_Defaults (Panels);
      Assert
        (Editor.Panels.Active_Bottom_Content (Panels) = Editor.Panels.Problems_Content,
         "bottom panel content should default to Problems");

      Editor.Panels.Set_Visible (Panels, Editor.Panels.Bottom_Panel, True);
      Editor.Panels.Set_Current_Size (Panels, Editor.Panels.Bottom_Panel, 11);
      Editor.Panels.Set_Bottom_Content (Panels, Editor.Panels.Problems_Content);
      Editor.Panels.Set_Current (Panels);
      Layout := Editor.Layout.Current;
      Problems_Rect := Editor.Layout.Panel_Rect
        (Layout, Editor.Panels.Bottom_Panel, View_W, View_H);

      Editor.Panels.Set_Bottom_Content (Panels, Editor.Panels.Search_Results_Content);
      Editor.Panels.Set_Current (Panels);
      Layout := Editor.Layout.Current;
      Search_Rect := Editor.Layout.Panel_Rect
        (Layout, Editor.Panels.Bottom_Panel, View_W, View_H);

      Assert
        (Editor.Panels.Active_Bottom_Content (Panels) = Editor.Panels.Search_Results_Content,
         "Set_Bottom_Content should switch active bottom panel content to Search Results");
      Assert
        (Editor.Panels.Current_Size (Panels, Editor.Panels.Bottom_Panel) = 11,
         "switching bottom panel content should preserve shared bottom panel size");
      Assert
        (Problems_Rect.X = Search_Rect.X
         and then Problems_Rect.Y = Search_Rect.Y
         and then Problems_Rect.Width = Search_Rect.Width
         and then Problems_Rect.Height = Search_Rect.Height,
         "Problems and Search Results should share the same bottom panel geometry");

      Editor.Panels.Initialize_Defaults (Panels);
      Editor.Panels.Set_Current (Panels);
   end Test_Bottom_Content_Switching_Preserves_Geometry;


   procedure Register_Tests
     (T : in out Panels_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Initialize_Defaults_File_Tree_Visible'Access,
         "Phase 59 initializes generic panel defaults");
      Register_Routine
        (T, Test_Clamp_Size'Access,
         "Phase 59 clamps panel sizes");
      Register_Routine
        (T, Test_Set_Visible_Preserves_Size'Access,
         "Phase 59 panel visibility preserves size");
      Register_Routine
        (T, Test_Left_Resize_Delta'Access,
         "Phase 59 left panel resize delta uses cell snapping");
      Register_Routine
        (T, Test_Right_And_Bottom_Resize_Deltas'Access,
         "Phase 59 right and bottom resize deltas are deterministic");
      Register_Routine
        (T, Test_Bottom_Panel_Layout_Reserves_Height'Access,
         "Phase 60 bottom panel layout reserves height through Editor.Layout");
      Register_Routine
        (T, Test_Bottom_Content_Switching_Preserves_Geometry'Access,
         "Phase 73 bottom panel content switching preserves geometry and shared size");
   end Register_Tests;

end Editor.Panels.Tests;
