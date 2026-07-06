with Editor.Buffers;
with Editor.Build_UI;
with Editor.Build_UI_Panel_Layout;
with Editor.Command_Palette;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Command_Palette_Projection;
with Editor.Feature_Panel;
with Editor.Feature_Diagnostics;
with Editor.File_Tree_View;
with Editor.Layout;
with Editor.Panels;
with Editor.Problems;
with Editor.Project_Search;
with Editor.Render_Cache;
with Editor.Search_Results;
with Editor.State;
with Editor.Theme;
with Editor.View;
with Editor.Input_Bridge.Build_UI_Projection;
with Text_Buffer;

package body Editor.Input_Bridge.Wheel_Handlers is

   use type Editor.Build_UI_Panel_Layout.Build_UI_Panel_Zone;
   use type Editor.Panels.Bottom_Panel_Content;

   function Wheel_Row_Delta (Delta_Y : Integer) return Integer is
   begin
      if Delta_Y = 0 then
         return 0;
      elsif Delta_Y > 0 then
         return -3 * Delta_Y;
      else
         return -3 * Delta_Y;
      end if;
   end Wheel_Row_Delta;

   function Wheel_Column_Delta (Delta_X : Integer) return Integer is
   begin
      return 3 * Delta_X;
   end Wheel_Column_Delta;

   function Longest_Line_Column_Count
     (S : Editor.State.State_Type) return Natural
   is
      Count : constant Natural := Editor.State.Line_Count (S);
      Max   : Natural := 0;
   begin
      if Count = 0 then
         return 0;
      end if;

      for Row in 0 .. Count - 1 loop
         declare
            First : constant Editor.Cursors.Cursor_Index :=
              Editor.State.Line_Start (S, Row);
            Last  : constant Editor.Cursors.Cursor_Index :=
              Text_Buffer.Line_End_Index (S.Buffer, Row);
         begin
            if Last >= First then
               Max := Natural'Max (Max, Natural (Last - First));
            end if;
         end;
      end loop;
      return Max;
   end Longest_Line_Column_Count;

   procedure Scroll_Editor_By
     (S       : Editor.State.State_Type;
      Delta_X : Integer;
      Delta_Y : Integer)
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Rows   : constant Natural := Editor.State.Line_Count (S);
      View_H : constant Natural :=
        (if Editor.Layout.Cell_H = 0 then 1
         else Natural'Max
           (1,
            Editor.Layout.Text_Viewport_Height
              (Layout, Editor.View.Viewport_Height) / Editor.Layout.Cell_H));
      View_W : constant Natural :=
        Natural'Max
          (1,
           Editor.Layout.Text_Visible_Column_Count
             (Layout, Rows, Editor.View.Viewport_Width));
      New_Y  : Integer := Integer (Editor.View.Scroll_Y) + Wheel_Row_Delta (Delta_Y);
      New_X  : Integer := Integer (Editor.View.Scroll_X) + Wheel_Column_Delta (Delta_X);
   begin
      if New_Y < 0 then
         New_Y := 0;
      end if;
      if New_X < 0 then
         New_X := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Rows,
         Viewport_Rows  => View_H,
         Desired_Scroll => Natural (New_Y));
      Editor.View.Set_Scroll_X_Clamped
        (Column_Count   => Longest_Line_Column_Count (S),
         Viewport_Cols  => View_W,
         Desired_Scroll => Natural (New_X));
      Editor.Render_Cache.Invalidate_All;
   end Scroll_Editor_By;

   function Point_In_Rect
     (X : Natural;
      Y : Natural;
      R : Editor.Layout.Rect) return Boolean
   is
   begin
      return Integer (X) >= R.X
        and then Integer (Y) >= R.Y
        and then Integer (X) < R.X + Integer (R.Width)
        and then Integer (Y) < R.Y + Integer (R.Height);
   end Point_In_Rect;

   function Handle_Command_Palette_Wheel
     (S       : in out Editor.State.State_Type;
      X       : Natural;
      Y       : Natural;
      Delta_Y : Integer) return Boolean
   is
      Palette : constant Editor.Command_Palette.Palette_State :=
        Editor.Command_Palette.Current;
      Layout  : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Config : constant Editor.Command_Palette.Command_Palette_Config :=
        Editor.Command_Palette.Current_Config;
      Snapshot : Editor.Command_Palette.Command_Palette_Snapshot;
      Margin : constant Natural := Editor.Theme.Palette_Margin;
      Max_W  : constant Natural := Editor.Theme.Palette_Max_Width;
      Width  : Natural := Max_W;
      Top_Y  : Natural := 0;
      Visible_Count : Natural := 0;
      Height : Natural := 0;
      Rect   : Editor.Layout.Rect;
   begin
      if not Palette.Open then
         return False;
      end if;

      Editor.Executor.Command_Palette_Projection.Command_Palette_Candidates (S, Candidates);
      Editor.Command_Palette.Reconcile_Selection (Candidates);
      Snapshot := Editor.Command_Palette.Build_Snapshot (Candidates, Config);

      if Editor.View.Viewport_Width <= Margin * 2 then
         Width := Editor.View.Viewport_Width;
      else
         Width := Natural'Min (Max_W, Editor.View.Viewport_Width - Margin * 2);
      end if;

      Top_Y := Natural'Min
        (Natural'Max
           (0,
            Natural
              (Float (Layout.Origin_Y)
               + Float'Max
                 (Editor.Theme.Palette_Top_Min_Offset,
                  Float (Editor.View.Viewport_Height)
                  * Editor.Theme.Palette_Top_Fraction))),
         Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height)));

      declare
         Status_Y : constant Natural :=
           Natural (Editor.Layout.Status_Bar_Y (Layout, Editor.View.Viewport_Height));
         Available_H : constant Natural :=
           (if Status_Y > Top_Y then Status_Y - Top_Y else 0);
         Base_H : constant Natural :=
           2 * Editor.Layout.Cell_H + Natural (Editor.Theme.Palette_Outer_Padding_Y);
         Space_For_Rows : constant Natural :=
           (if Editor.Layout.Cell_H /= 0 and then Available_H > Base_H
            then (Available_H - Base_H) / Editor.Layout.Cell_H
            else 0);
      begin
         Visible_Count := Natural'Min
           (Natural'Min (Config.Max_Visible_Rows, Space_For_Rows),
            Editor.Command_Palette.Row_Count (Snapshot));
      end;

      Height := (2 + Visible_Count) * Editor.Layout.Cell_H
        + Natural (Editor.Theme.Palette_Outer_Padding_Y);
      Rect :=
        (X      => Layout.Origin_X + Integer ((Editor.View.Viewport_Width - Width) / 2),
         Y      => Integer (Top_Y),
         Width  => Width,
         Height => Height);

      if not Point_In_Rect (X, Y, Rect) then
         return False;
      end if;

      Editor.Command_Palette.Scroll_By (Snapshot, Visible_Count, Wheel_Row_Delta (Delta_Y));
      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Command_Palette_Wheel;

   function Handle_Build_UI_Wheel
     (S       : in out Editor.State.State_Type;
      X       : Natural;
      Y       : Natural;
      Delta_Y : Integer) return Boolean
   is
      Projection : constant Editor.Input_Bridge.Build_UI_Projection.Build_UI_Panel_Input_Projection :=
        Editor.Input_Bridge.Build_UI_Projection.Current (S);
      Rect : constant Editor.Layout.Rect :=
        (X      => Projection.Geometry.X,
         Y      => Projection.Geometry.Y,
         Width  => Projection.Geometry.W,
         Height => Projection.Geometry.H);
      Hit : Editor.Build_UI_Panel_Layout.Build_UI_Panel_Hit;
   begin
      if not Projection.Snapshot.Visible or else not Point_In_Rect (X, Y, Rect) then
         return False;
      end if;

      Hit := Editor.Build_UI_Panel_Layout.Hit_Test
        (Projection.Geometry, Editor.Layout.Cell_H, Integer (X), Integer (Y));

      if Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Row
        or else Hit.Zone = Editor.Build_UI_Panel_Layout.Build_UI_Panel_Suppressed_Header
      then
         Editor.Feature_Diagnostics.Scroll_Suppressed_Diagnostics
           (S.Feature_Diagnostics,
            Projection.Displayed_Suppressed_Count,
            Wheel_Row_Delta (Delta_Y));
      else
         Editor.Build_UI.Scroll_Action_Rows
           (S.Build_UI,
            Projection.Action_Count,
            Projection.Visible_Action_Rows,
            Wheel_Row_Delta (Delta_Y));
      end if;
      Editor.Render_Cache.Invalidate_All;
      return True;
   end Handle_Build_UI_Wheel;

   procedure Handle_Wheel
     (S       : in out Editor.State.State_Type;
      X       : Natural;
      Y       : Natural;
      Delta_X : Integer;
      Delta_Y : Integer)
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Bottom : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.Bottom_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      File_Rect : constant Editor.Layout.Rect :=
        Editor.Layout.Panel_Rect
          (Layout,
           Editor.Panels.File_Tree_Panel,
           Editor.View.Viewport_Width,
           Editor.View.Viewport_Height);
      Feature_Width  : constant Natural :=
        Natural'Min (280, Editor.View.Viewport_Width);
      Feature_Rect : constant Editor.Layout.Rect :=
        (X      => Integer (Editor.View.Viewport_Width) - Integer (Feature_Width),
         Y      => Editor.Layout.Text_Viewport_Y (Layout),
         Width  => Feature_Width,
         Height => Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height));
      Text_Rect : constant Editor.Layout.Rect :=
        (X      => Integer (Editor.Layout.Text_Origin_X
                     (Layout, Editor.State.Line_Count (S))),
         Y      => Editor.Layout.Text_Viewport_Y (Layout),
         Width  => Editor.Layout.Text_Viewport_Width
                     (Layout,
                      Editor.State.Line_Count (S),
                      Editor.View.Viewport_Width),
         Height => Editor.Layout.Text_Viewport_Height
                     (Layout, Editor.View.Viewport_Height));
   begin
      if Delta_X = 0 and then Delta_Y = 0 then
         return;
      end if;

      if Handle_Command_Palette_Wheel (S, X, Y, Delta_Y) then
         return;
      end if;

      if Handle_Build_UI_Wheel (S, X, Y, Delta_Y) then
         return;
      end if;

      if Editor.Layout.Is_In_Status_Bar
           (Config          => Layout,
            X               => Integer (X),
            Y               => Integer (Y),
            Viewport_Width  => Editor.View.Viewport_Width,
            Viewport_Height => Editor.View.Viewport_Height)
      then
         return;
      end if;

      if Point_In_Rect (X, Y, File_Rect)
        and then Editor.Panels.Is_Visible
          (S.Panels, Editor.Panels.File_Tree_Panel)
      then
         Editor.File_Tree_View.Scroll_By
           (S.File_Tree_View,
            S.File_Tree,
            (if Editor.Layout.Cell_H = 0 then 1
             else Natural'Max (1, File_Rect.Height / Editor.Layout.Cell_H)),
            Wheel_Row_Delta (Delta_Y));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Point_In_Rect (X, Y, Feature_Rect)
        and then Editor.Feature_Panel.Is_Visible (S.Feature_Panel)
      then
         declare
            Rows : Natural :=
              (if Editor.Layout.Cell_H = 0 then 1
               else Natural'Max (1, Feature_Rect.Height / Editor.Layout.Cell_H));
         begin
            if Rows > 1 then
               Rows := Rows - 1;
            end if;
            Editor.Feature_Panel.Set_Visible_Row_Count
              (S.Feature_Panel, Rows);
         end;
         Editor.Feature_Panel.Scroll_By
           (S.Feature_Panel, Wheel_Row_Delta (Delta_Y));
         Editor.Render_Cache.Invalidate_All;
         return;
      end if;

      if Point_In_Rect (X, Y, Bottom)
        and then Editor.Panels.Is_Visible
          (S.Panels, Editor.Panels.Bottom_Panel)
      then
         declare
            Rows : Natural :=
              (if Editor.Layout.Cell_H = 0 then 1
               else Natural'Max (1, Bottom.Height / Editor.Layout.Cell_H));
         begin
            if Rows > 1 then
               Rows := Rows - 1;
            end if;

            if Editor.Panels.Active_Bottom_Content (S.Panels) =
              Editor.Panels.Search_Results_Content
            then
               declare
                  Full : constant Editor.Search_Results.Search_Results_Snapshot :=
                    Editor.Search_Results.Build_Snapshot
                      (S.Project_Search, (others => <>),
                       Editor.Buffers.Global_Registry_For_UI);
               begin
                  Editor.Search_Results.Scroll_By
                    (S.Search_Results_View, Full, Rows,
                     Wheel_Row_Delta (Delta_Y));
               end;
               Editor.Render_Cache.Invalidate_All;
               return;
            elsif Editor.Panels.Active_Bottom_Content (S.Panels) =
              Editor.Panels.Problems_Content
            then
               declare
                  Full : constant Editor.Problems.Problems_Snapshot :=
                    Editor.Problems.Build_Snapshot (S.Diagnostics);
               begin
                  Editor.Problems.Scroll_By
                    (S.Problems_View, Full, Rows,
                     Wheel_Row_Delta (Delta_Y));
               end;
               Editor.Render_Cache.Invalidate_All;
               return;
            end if;
         end;
      end if;

      if Point_In_Rect (X, Y, Text_Rect) then
         Scroll_Editor_By (S, Delta_X, Delta_Y);
      end if;
   end Handle_Wheel;

end Editor.Input_Bridge.Wheel_Handlers;
