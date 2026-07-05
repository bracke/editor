with Editor.Folding;
with Editor.Input_Bridge.Pointer_Routing;
with Editor.Input_Bridge.Pointer_State;
with Editor.Layout;
with Editor.Minimap;
with Editor.Render_Cache;
with Editor.Scrollbars;
with Editor.Settings;
with Editor.View;

package body Editor.Input_Bridge.Pointer_Scroll_Handlers is

   use type Editor.Scrollbars.Scrollbar_Hit;

   function Is_Minimap_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Minimap_Pointer_Command (Kind);
   end Is_Minimap_Pointer_Command;

   function Is_Minimap_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Minimap_Drag_Command (Kind);
   end Is_Minimap_Drag_Command;

   procedure Scroll_From_Minimap_Y
     (S : in out Editor.State.State_Type;
      Y : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Document_Rows : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (S));
      Row_Count     : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (S.Folding, Document_Rows));
      Scrollbars    : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Raw_Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Effective_H   : constant Natural :=
        (if Raw_Effective_H = 0 then Editor.View.Viewport_Height else Raw_Effective_H);
      Minimap_H     : constant Natural :=
        Natural'Max
          (Editor.Layout.Cell_H,
           Editor.Layout.Text_Viewport_Height (Layout, Effective_H));
      Viewport_Rows : constant Natural :=
        Natural'Max (1, Editor.Layout.Visible_Row_Count (Layout, Effective_H));
      Target_Document_Row : Natural :=
        Editor.Minimap.Row_For_Y
          (Y                => Y,
           Total_Line_Count => Document_Rows,
           Layout           => Layout,
           Viewport_Height  => Minimap_H,
           Config           => Config);
      Desired_Row   : Natural := 0;
      Found         : Boolean := False;
   begin
      if Target_Document_Row >= Document_Rows then
         Target_Document_Row := Document_Rows - 1;
      end if;

      if Editor.Folding.Is_Row_Hidden
           (S.Folding, Target_Document_Row)
      then
         Target_Document_Row :=
           Editor.Folding.Fold_Start_For_Hidden_Row
             (S.Folding, Target_Document_Row, Found);
      end if;

      Desired_Row :=
        Editor.Folding.Document_Row_To_Visible_Row
          (S.Folding, Target_Document_Row, Found);

      if not Found then
         Desired_Row := 0;
      end if;

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Row_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired_Row);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Minimap_Y;

   function Handle_Minimap_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
      Layout : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Scrollbars);
      Raw_Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Scrollbars);
      Effective_H : constant Natural :=
        Natural'Max
          (Editor.Layout.Cell_H,
           Editor.Layout.Text_Viewport_Height
             (Layout,
              (if Raw_Effective_H = 0 then Editor.View.Viewport_Height else Raw_Effective_H)));
   begin
      if not Is_Minimap_Pointer_Command (Cmd.Kind) then
         Pointer_State.Set_Minimap_Drag_Active (False);
         return False;
      end if;

      if not Config.Enabled or else not Editor.Settings.Show_Minimap then
         Pointer_State.Set_Minimap_Drag_Active (False);
         return False;
      end if;

      if Is_Minimap_Drag_Command (Cmd.Kind)
        and then Pointer_State.Minimap_Drag_Active
      then
         Scroll_From_Minimap_Y (S, Cmd.Click_Y);
         return True;
      end if;

      Pointer_State.Set_Minimap_Drag_Active (False);

      if Editor.Minimap.Contains_Point
           (X               => Cmd.Click_X,
            Y               => Cmd.Click_Y,
            Layout          => Layout,
            Viewport_Width  => Effective_W,
            Viewport_Height => Effective_H,
            Config          => Config)
      then
         Pointer_State.Set_Minimap_Drag_Active (True);
         Scroll_From_Minimap_Y (S, Cmd.Click_Y);
         return True;
      end if;

      return False;
   end Handle_Minimap_Pointer;

   function Is_Scrollbar_Pointer_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Scrollbar_Pointer_Command (Kind);
   end Is_Scrollbar_Pointer_Command;

   function Is_Scrollbar_Drag_Command
     (Kind : Editor.Commands.Command_Kind) return Boolean
   is
   begin
      return Pointer_Routing.Is_Scrollbar_Drag_Command (Kind);
   end Is_Scrollbar_Drag_Command;

   procedure Scroll_From_Vertical_Thumb
     (S : in out Editor.State.State_Type;
      Y : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Row_Count     : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (S.Folding, Editor.State.Line_Count (S)));
      Effective_H   : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Config);
      Viewport_Rows : constant Natural :=
        Editor.Layout.Visible_Row_Count (Layout, Effective_H);
      Geometry      : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Vertical_Geometry
          (Layout          => Layout,
           Viewport_Width  => Editor.View.Viewport_Width,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Scroll_Y        => Editor.View.Scroll_Y,
           Config          => Config);
      Desired_Top   : Natural := 0;
      Desired_Row   : Natural := 0;
   begin
      if Y > Pointer_State.Scrollbar_Drag_Offset then
         Desired_Top := Y - Pointer_State.Scrollbar_Drag_Offset;
      else
         Desired_Top := 0;
      end if;

      Desired_Row :=
        Editor.Scrollbars.Scroll_Y_For_Thumb_Y
          (Geometry        => Geometry,
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Desired_Thumb_Y => Desired_Top);

      Editor.View.Set_Scroll_Y_Clamped
        (Row_Count      => Row_Count,
         Viewport_Rows  => Viewport_Rows,
         Desired_Scroll => Desired_Row);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Vertical_Thumb;

   procedure Scroll_From_Horizontal_Thumb
     (S                       : in out Editor.State.State_Type;
      X                       : Natural;
      Max_Visible_Line_Length : Natural)
   is
      Layout        : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config        : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Minimap       : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Effective_W   : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Config);
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Line_Count    : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (S));
      Text_Left     : constant Natural :=
        Editor.Layout.Text_Origin_X (Layout, Line_Count);
      Text_W        : constant Natural :=
        (if Effective_Minimap_Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout, Line_Count, Effective_W,
               Minimap.Enabled, Minimap.Width,
               Minimap.Padding_Left, Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width (Layout, Line_Count, Effective_W));
      Visible_Cols  : constant Natural := Text_W / Editor.Layout.Cell_W;
      Total_Cols    : constant Natural := Max_Visible_Line_Length;
      Geometry      : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Horizontal_Geometry
          (Layout          => Layout,
           Text_Left       => Text_Left,
           Text_Width      => Text_W,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Scroll_X        => Editor.View.Scroll_X,
           Config          => Config);
      Desired_Left : Natural := 0;
      Desired_Col  : Natural := 0;
   begin
      if X > Pointer_State.Scrollbar_Drag_Offset then
         Desired_Left := X - Pointer_State.Scrollbar_Drag_Offset;
      else
         Desired_Left := 0;
      end if;

      Desired_Col :=
        Editor.Scrollbars.Scroll_X_For_Thumb_X
          (Geometry        => Geometry,
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Desired_Thumb_X => Desired_Left);

      Editor.View.Set_Scroll_X_Clamped
        (Column_Count   => Total_Cols,
         Viewport_Cols  => Visible_Cols,
         Desired_Scroll => Desired_Col);
      Editor.Render_Cache.Invalidate_All;
   end Scroll_From_Horizontal_Thumb;

   function Handle_Scrollbar_Pointer
     (S                       : in out Editor.State.State_Type;
      Cmd                     : Editor.Commands.Command;
      Max_Visible_Line_Length : Natural) return Boolean
   is
      Layout      : constant Editor.Layout.Layout_Config := Editor.Layout.Current;
      Config      : constant Editor.Scrollbars.Scrollbar_Config := Editor.Scrollbars.Current;
      Row_Count   : constant Natural :=
        Natural'Max
          (1, Editor.Folding.Visible_Row_Count
                (S.Folding, Editor.State.Line_Count (S)));
      Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Editor.View.Viewport_Height, Config);
      Viewport_Rows : constant Natural :=
        Editor.Layout.Visible_Row_Count (Layout, Effective_H);
      Vertical    : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Vertical_Geometry
          (Layout          => Layout,
           Viewport_Width  => Editor.View.Viewport_Width,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Rows      => Row_Count,
           Visible_Rows    => Viewport_Rows,
           Scroll_Y        => Editor.View.Scroll_Y,
           Config          => Config);
      Minimap     : constant Editor.Minimap.Minimap_Config := Editor.Minimap.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Editor.View.Viewport_Width, Config);
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Line_Count  : constant Natural :=
        Natural'Max (1, Editor.State.Line_Count (S));
      Text_Left   : constant Natural := Editor.Layout.Text_Origin_X (Layout, Line_Count);
      Text_W      : constant Natural :=
        (if Effective_Minimap_Enabled then
            Editor.Layout.Text_Viewport_Width
              (Layout, Line_Count, Effective_W,
               Minimap.Enabled, Minimap.Width,
               Minimap.Padding_Left, Minimap.Padding_Right)
         else
            Editor.Layout.Text_Viewport_Width (Layout, Line_Count, Effective_W));
      Visible_Cols : constant Natural := Text_W / Editor.Layout.Cell_W;
      Total_Cols   : constant Natural := Max_Visible_Line_Length;
      Horizontal   : constant Editor.Scrollbars.Scrollbar_Geometry :=
        Editor.Scrollbars.Horizontal_Geometry
          (Layout          => Layout,
           Text_Left       => Text_Left,
           Text_Width      => Text_W,
           Viewport_Height => Editor.Layout.Text_Viewport_Height
                                (Layout, Editor.View.Viewport_Height),
           Total_Cols      => Total_Cols,
           Visible_Cols    => Visible_Cols,
           Scroll_X        => Editor.View.Scroll_X,
           Config          => Config);
      Hit : Editor.Scrollbars.Scrollbar_Hit;
   begin
      if not Is_Scrollbar_Pointer_Command (Cmd.Kind) then
         Pointer_State.Clear_Scrollbar_Drag;
         return False;
      end if;

      if not Config.Enabled then
         Pointer_State.Clear_Scrollbar_Drag;
         return False;
      end if;

      if Is_Scrollbar_Drag_Command (Cmd.Kind) and then Pointer_State.Scrollbar_Drag_Active then
         case Pointer_State.Scrollbar_Drag_Orientation is
            when Editor.Scrollbars.Vertical_Scrollbar =>
               Scroll_From_Vertical_Thumb (S, Cmd.Click_Y);
            when Editor.Scrollbars.Horizontal_Scrollbar =>
               Scroll_From_Horizontal_Thumb (S, Cmd.Click_X, Max_Visible_Line_Length);
         end case;
         return True;
      end if;

      Pointer_State.Clear_Scrollbar_Drag;

      Hit := Editor.Scrollbars.Hit_Test (Vertical, Cmd.Click_X, Cmd.Click_Y);
      if Hit = Editor.Scrollbars.Scrollbar_Thumb_Hit then
         Pointer_State.Start_Scrollbar_Drag
           (Editor.Scrollbars.Vertical_Scrollbar,
            (if Cmd.Click_Y > Natural (Vertical.Thumb.Y)
             then Cmd.Click_Y - Natural (Vertical.Thumb.Y)
             else 0));
         return True;
      elsif Hit = Editor.Scrollbars.Scrollbar_Track_Hit then
         if Float (Cmd.Click_Y) < Vertical.Thumb.Y then
            Editor.View.Set_Scroll_Y_Clamped
              (Row_Count, Viewport_Rows,
               (if Editor.View.Scroll_Y > Viewport_Rows
                then Editor.View.Scroll_Y - Viewport_Rows
                else 0));
         else
            Editor.View.Set_Scroll_Y_Clamped
              (Row_Count, Viewport_Rows,
               Editor.View.Scroll_Y + Viewport_Rows);
         end if;
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      Hit := Editor.Scrollbars.Hit_Test (Horizontal, Cmd.Click_X, Cmd.Click_Y);
      if Hit = Editor.Scrollbars.Scrollbar_Thumb_Hit then
         Pointer_State.Start_Scrollbar_Drag
           (Editor.Scrollbars.Horizontal_Scrollbar,
            (if Cmd.Click_X > Natural (Horizontal.Thumb.X)
             then Cmd.Click_X - Natural (Horizontal.Thumb.X)
             else 0));
         return True;
      elsif Hit = Editor.Scrollbars.Scrollbar_Track_Hit then
         if Float (Cmd.Click_X) < Horizontal.Thumb.X then
            Editor.View.Set_Scroll_X_Clamped
              (Total_Cols, Visible_Cols,
               (if Editor.View.Scroll_X > Visible_Cols
                then Editor.View.Scroll_X - Visible_Cols
                else 0));
         else
            Editor.View.Set_Scroll_X_Clamped
              (Total_Cols, Visible_Cols,
               Editor.View.Scroll_X + Visible_Cols);
         end if;
         Editor.Render_Cache.Invalidate_All;
         return True;
      end if;

      return False;
   end Handle_Scrollbar_Pointer;

end Editor.Input_Bridge.Pointer_Scroll_Handlers;
