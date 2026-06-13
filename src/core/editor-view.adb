with Editor.Layout;
with Editor.Wrap;
with Editor.Render_Cache;
with Editor.Render_Model;
with Editor.Minimap;
with Editor.Cursor;
with Editor.Settings;
with Editor.Scrollbars;
with Ada.Containers; use Ada.Containers;

package body Editor.View is

   use type Editor.Wrap.Wrap_Mode;

   ------------------------------------------------------------------
   -- State
   ------------------------------------------------------------------

   Current_Scroll_X : Natural := 0;
   Current_Scroll_Y : Natural := 0;

   Current_Visual_Scroll_X : Float := 0.0;
   Current_Visual_Scroll_Y : Float := 0.0;

   Scroll_Smoothing_Rate : constant Float := 12.0;
   Scroll_Snap_Epsilon   : constant Float := 0.001;

   --  True after a direct viewport navigation action such as minimap
   --  click/drag.  While set, render-packet construction must not immediately
   --  pull the viewport back to the caret.
   User_Scroll_Y_Override : Boolean := False;

   Current_Wrap_Mode : Editor.Wrap.Wrap_Mode := Editor.Wrap.Wrap_None;

   Current_Viewport_W : Natural := 0;
   Current_Viewport_H : Natural := 0;

   Current_Time : Duration := 0.0;


   function Snapshot return View_State is
   begin
      return
        (Scroll_X        => Current_Scroll_X,
         Scroll_Y        => Current_Scroll_Y,
         Visual_Scroll_X => Current_Visual_Scroll_X,
         Visual_Scroll_Y => Current_Visual_Scroll_Y,
         User_Scroll_Y_Override => User_Scroll_Y_Override,
         Wrap_Mode       => Current_Wrap_Mode);
   end Snapshot;

   procedure Restore
     (State : View_State;
      Snap_Visual_To_Target : Boolean := True)
   is
   begin
      Current_Wrap_Mode := State.Wrap_Mode;
      Current_Scroll_X :=
        (if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then 0 else State.Scroll_X);
      Current_Scroll_Y := State.Scroll_Y;
      if Snap_Visual_To_Target then
         Current_Visual_Scroll_X := Float (Current_Scroll_X);
         Current_Visual_Scroll_Y := Float (Current_Scroll_Y);
      else
         Current_Visual_Scroll_X := State.Visual_Scroll_X;
         Current_Visual_Scroll_Y := State.Visual_Scroll_Y;
      end if;
      User_Scroll_Y_Override := State.User_Scroll_Y_Override;
      Editor.Render_Cache.Invalidate_All;
   end Restore;

   procedure Set_Current_Scroll_X (Value : Natural) is
      New_Value : constant Natural :=
        (if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then 0 else Value);
   begin
      if Current_Scroll_X /= New_Value then
         Current_Scroll_X := New_Value;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Set_Current_Scroll_X;

   procedure Set_Current_Scroll_Y (Value : Natural) is
   begin
      if Current_Scroll_Y /= Value then
         Current_Scroll_Y := Value;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Set_Current_Scroll_Y;

   procedure Sync_Visual_Scroll_To_Logical is
      New_X : constant Float := Float (Scroll_X);
      New_Y : constant Float := Float (Current_Scroll_Y);
   begin
      if Current_Visual_Scroll_X /= New_X
        or else Current_Visual_Scroll_Y /= New_Y
      then
         Current_Visual_Scroll_X := New_X;
         Current_Visual_Scroll_Y := New_Y;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Sync_Visual_Scroll_To_Logical;

   function Advance_Visual
     (Current        : Float;
      Target         : Float;
      Delta_Time_Sec : Float) return Float
   is
      Difference : constant Float := Target - Current;
      Factor     : Float := 0.0;
   begin
      if abs Difference <= Scroll_Snap_Epsilon then
         return Target;
      end if;

      if Delta_Time_Sec <= 0.0 then
         return Current;
      end if;

      Factor := Delta_Time_Sec * Scroll_Smoothing_Rate;
      if Factor > 1.0 then
         Factor := 1.0;
      end if;

      return Current + Difference * Factor;
   end Advance_Visual;

   ------------------------------------------------------------------
   -- Reset
   ------------------------------------------------------------------

   procedure Reset is
   begin
      Set_Current_Scroll_X (0);
      Current_Scroll_Y := 0;
      Current_Visual_Scroll_X := 0.0;
      Current_Visual_Scroll_Y := 0.0;
      User_Scroll_Y_Override := False;
      Current_Wrap_Mode := Editor.Wrap.Wrap_None;
      Current_Viewport_W := 0;
      Current_Viewport_H := 0;
      Current_Time := 0.0;
   end Reset;

   procedure Set_Scroll (X, Y : Natural) is
   begin
      if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         Set_Current_Scroll_X (0);
      else
         Set_Current_Scroll_X (X);
      end if;
      Set_Current_Scroll_Y (Y);
      Sync_Visual_Scroll_To_Logical;
      User_Scroll_Y_Override := False;
   end Set_Scroll;

   procedure Set_Scroll_Y_Clamped
     (Row_Count      : Natural;
      Viewport_Rows  : Natural;
      Desired_Scroll : Natural)
   is
      Max_Scroll : Natural := 0;
   begin
      if Row_Count > Viewport_Rows then
         Max_Scroll := Row_Count - Viewport_Rows;
      else
         Max_Scroll := 0;
      end if;

      declare
         New_Scroll_Y : constant Natural :=
           Natural'Min (Desired_Scroll, Max_Scroll);
      begin
         Set_Current_Scroll_Y (New_Scroll_Y);
         Sync_Visual_Scroll_To_Logical;
      end;

      User_Scroll_Y_Override := True;
   end Set_Scroll_Y_Clamped;

   procedure Set_Scroll_X_Clamped
     (Column_Count   : Natural;
      Viewport_Cols  : Natural;
      Desired_Scroll : Natural)
   is
      Max_Scroll : Natural := 0;
   begin
      if Column_Count > Viewport_Cols then
         Max_Scroll := Column_Count - Viewport_Cols;
      else
         Max_Scroll := 0;
      end if;

      Set_Current_Scroll_X (Natural'Min (Desired_Scroll, Max_Scroll));
      Sync_Visual_Scroll_To_Logical;
   end Set_Scroll_X_Clamped;

   procedure Clear_User_Scroll_Override is
   begin
      User_Scroll_Y_Override := False;
   end Clear_User_Scroll_Override;

   procedure Set_Wrap_Mode (Mode : Editor.Wrap.Wrap_Mode) is
   begin
      if Current_Wrap_Mode /= Mode then
         Current_Wrap_Mode := Mode;
         if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
            Set_Current_Scroll_X (0);
            Current_Visual_Scroll_X := 0.0;
         end if;
         User_Scroll_Y_Override := False;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Set_Wrap_Mode;

   function Wrap_Mode return Editor.Wrap.Wrap_Mode is
   begin
      return Current_Wrap_Mode;
   end Wrap_Mode;

   procedure Reset_Scroll is
   begin
      Set_Scroll (0,0);
   end Reset_Scroll;

   ------------------------------------------------------------------
   -- Viewport
   ------------------------------------------------------------------
   procedure Set_Viewport
    (Width  : Natural;
     Height : Natural) is
   begin
      if Current_Viewport_W /= Width or else Current_Viewport_H /= Height then
         Current_Viewport_W := Width;
         Current_Viewport_H := Height;
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Set_Viewport;

   function Viewport_Width return Natural is
   begin
      return Current_Viewport_W;
   end Viewport_Width;

   function Viewport_Height return Natural is
   begin
      return Current_Viewport_H;
   end Viewport_Height;


   ------------------------------------------------------------------
   -- Time (for caret blink)
   ------------------------------------------------------------------

   function Current_Time_Seconds return Duration is
   begin
      return Current_Time;
   end Current_Time_Seconds;

   procedure Set_Time_Seconds (Now : Duration) is
   begin
      Current_Time := Now;
   end Set_Time_Seconds;

   procedure Tick (Delta_Time_Sec : Float) is
      Old_X : constant Float := Current_Visual_Scroll_X;
      Old_Y : constant Float := Current_Visual_Scroll_Y;
   begin
      Current_Visual_Scroll_X :=
        Advance_Visual
          (Current        => Current_Visual_Scroll_X,
           Target         => Float (Scroll_X),
           Delta_Time_Sec => Delta_Time_Sec);

      Current_Visual_Scroll_Y :=
        Advance_Visual
          (Current        => Current_Visual_Scroll_Y,
           Target         => Float (Current_Scroll_Y),
           Delta_Time_Sec => Delta_Time_Sec);

      if Old_X /= Current_Visual_Scroll_X
        or else Old_Y /= Current_Visual_Scroll_Y
      then
         Editor.Render_Cache.Invalidate_All;
      end if;
   end Tick;

   function Caret_Visible return Boolean is
   begin
      return Editor.Cursor.Visible (Float (Current_Time));
   end Caret_Visible;

   ------------------------------------------------------------------
   -- Caret position helper
   --
   -- Uses the first caret in the render snapshot as the scroll anchor.
   ------------------------------------------------------------------

   procedure Caret_Row_Col
   (Snap : Editor.Render_Model.Render_Snapshot;
      Row  : out Natural;
      Col  : out Natural)
   is
   begin
      Row := Snap.Primary_Caret_Row;
      Col := Snap.Primary_Caret_Col;
   end Caret_Row_Col;

   ------------------------------------------------------------------
   -- Scroll update
   ------------------------------------------------------------------

   procedure Update_Scroll_For_Snapshot
     (Snap   : Editor.Render_Model.Render_Snapshot;
      Layout : Editor.Layout.Layout_Config)
   is
      Caret_Row : Natural := 0;
      Caret_Col : Natural := 0;

      Margin_Cols : constant Natural := 4;
      Margin_Rows : constant Natural := 2;

      Visible_Cols : Natural := 0;
      Visible_Rows : Natural := 0;
   begin
      ------------------------------------------------------------------
      -- Compute visible area in cells
      ------------------------------------------------------------------

      declare
         Total_Lines : Natural := 1;
      begin
         Total_Lines := Snap.Total_Line_Count;

         declare
            Minimap : constant Editor.Minimap.Minimap_Config :=
              Editor.Minimap.Current;
            Effective_Minimap_Enabled : constant Boolean :=
              Editor.Settings.Show_Minimap and then Minimap.Enabled;
            Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
              Editor.Scrollbars.Current;
            Effective_Viewport_W : constant Natural :=
              Editor.Scrollbars.Effective_Viewport_Width
                (Current_Viewport_W, Scrollbars);
         begin
            Visible_Cols :=
              (if Effective_Minimap_Enabled then
                  Editor.Layout.Text_Viewport_Width
                    (Layout, Total_Lines, Effective_Viewport_W,
                     Minimap.Enabled, Minimap.Width, Minimap.Padding_Left, Minimap.Padding_Right) / Editor.Layout.Cell_W
               else
                  Editor.Layout.Text_Visible_Column_Count
                    (Layout, Total_Lines, Effective_Viewport_W));
         end;
      end;

      declare
         Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
           Editor.Scrollbars.Current;
         Effective_Viewport_H : constant Natural :=
           Editor.Scrollbars.Effective_Viewport_Height
             (Current_Viewport_H, Scrollbars);
      begin
         Visible_Rows :=
           Editor.Layout.Visible_Row_Count (Layout, Effective_Viewport_H);
      end;

      ------------------------------------------------------------------
      -- Anchor on primary caret in snapshot
      ------------------------------------------------------------------

      Caret_Row_Col (Snap, Caret_Row, Caret_Col);

      ------------------------------------------------------------------
      -- Horizontal scroll
      ------------------------------------------------------------------

      if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         Set_Current_Scroll_X (0);
      elsif Visible_Cols > 0 then
         if Visible_Cols <= Margin_Cols * 2 then
            --  Constrained viewport: margins would consume the whole view.
            --  Keep the caret inside the exact visible column range.
            if Caret_Col < Current_Scroll_X then
               Set_Current_Scroll_X (Caret_Col);
            elsif Caret_Col >= Current_Scroll_X + Visible_Cols then
               Set_Current_Scroll_X (Caret_Col - Visible_Cols + 1);
            end if;

         elsif Caret_Col < Current_Scroll_X + Margin_Cols then
            if Caret_Col > Margin_Cols then
               Set_Current_Scroll_X (Caret_Col - Margin_Cols);
            else
               Set_Current_Scroll_X (0);
            end if;

         elsif Caret_Col >= Current_Scroll_X + Visible_Cols - Margin_Cols then
            Set_Current_Scroll_X
              (Caret_Col - (Visible_Cols - Margin_Cols));
         end if;
      else
         Set_Current_Scroll_X (0);
      end if;

      ------------------------------------------------------------------
      -- Vertical scroll
      ------------------------------------------------------------------

      if Visible_Rows > 0 then
         if User_Scroll_Y_Override then
            --  Preserve direct viewport navigation, such as minimap
            --  click/drag, during render-packet construction.  Without this
            --  guard the normal caret-following code would immediately snap
            --  the viewport back to the primary caret before the minimap
            --  viewport indicator can reflect the interaction.
            declare
               Max_Scroll_Y : Natural := 0;
            begin
               if Snap.Visible_Line_Count > Visible_Rows then
                  Max_Scroll_Y := Snap.Visible_Line_Count - Visible_Rows;
               end if;

               if Current_Scroll_Y > Max_Scroll_Y then
                  Set_Current_Scroll_Y (Max_Scroll_Y);
               end if;
            end;

         elsif Visible_Rows <= Margin_Rows * 2 then
            -- Small viewport: do not use margins.
            -- Just keep the caret inside the visible row range.
            if Caret_Row < Current_Scroll_Y then
               Set_Current_Scroll_Y (Caret_Row);

            elsif Caret_Row >= Current_Scroll_Y + Visible_Rows then
               Set_Current_Scroll_Y (Caret_Row - Visible_Rows + 1);
            end if;

         else
            -- Normal viewport: use margins.
            if Caret_Row < Current_Scroll_Y + Margin_Rows then
               if Caret_Row > Margin_Rows then
                  Set_Current_Scroll_Y (Caret_Row - Margin_Rows);
               else
                  Set_Current_Scroll_Y (0);
               end if;

            elsif Caret_Row >= Current_Scroll_Y + Visible_Rows - Margin_Rows then
               Set_Current_Scroll_Y
               (Caret_Row - (Visible_Rows - Margin_Rows));
            end if;
         end if;
      end if;

      if Current_Scroll_X > 0 then
         declare
            Max_Col : Natural := 0;
         begin
            for I in 1 .. Snap.Visible_Visual_Count loop
               Max_Col :=
                 Natural'Max (Max_Col, Snap.Visible_Visual_Rows (I).End_Col);
            end loop;

            --  Virtual carets may extend the effective horizontal content width.
            if Snap.Caret_Count > 0
            and then Snap.Caret_Virtual_Column (1) > 0
            then
               Max_Col :=
               Natural'Max
                  (Max_Col,
                  Snap.Caret_Virtual_Column (1));
            end if;

            if Visible_Cols > 0 then
               declare
                  Max_Scroll_X : Natural := 0;
               begin
                  if Max_Col > Visible_Cols then
                     Max_Scroll_X := Max_Col - Visible_Cols;
                  end if;

                  if Current_Scroll_X > Max_Scroll_X then
                     Set_Current_Scroll_X (Max_Scroll_X);
                  end if;
               end;
            end if;

            if Current_Viewport_W > 0 then
               declare
                  Total_Lines : Natural := 1;
                  Text_W      : Natural := 0;
               begin
                  Total_Lines := Snap.Total_Line_Count;

                  declare
                     Minimap : constant Editor.Minimap.Minimap_Config :=
                       Editor.Minimap.Current;
                     Effective_Minimap_Enabled : constant Boolean :=
                       Editor.Settings.Show_Minimap and then Minimap.Enabled;
                     Scrollbars : constant Editor.Scrollbars.Scrollbar_Config :=
                       Editor.Scrollbars.Current;
                     Effective_Viewport_W : constant Natural :=
                       Editor.Scrollbars.Effective_Viewport_Width
                         (Current_Viewport_W, Scrollbars);
                  begin
                     Text_W :=
                       (if Effective_Minimap_Enabled then
                           Editor.Layout.Text_Viewport_Width
                             (Layout, Total_Lines, Effective_Viewport_W,
                              Minimap.Enabled, Minimap.Width, Minimap.Padding_Left, Minimap.Padding_Right)
                        else
                           Editor.Layout.Text_Viewport_Width
                             (Layout, Total_Lines, Effective_Viewport_W));
                  end;

                  if Editor.Layout.Text_Cell_Width (Max_Col) <= Text_W then
                     Set_Current_Scroll_X (0);
                  end if;
               end;
            end if;
         end;
      end if;

      if Current_Wrap_Mode /= Editor.Wrap.Wrap_At_Viewport
      and then Current_Scroll_Y > 0 then
         declare
            Total_Rows : Natural := 1;
         begin
            Total_Rows := Snap.Visible_Line_Count;

            if Current_Viewport_H > 0
            and then Editor.Layout.Row_Block_Height (Total_Rows)
                     <= Editor.Layout.Text_Viewport_Height
                          (Layout,
                           Editor.Scrollbars.Effective_Viewport_Height
                             (Current_Viewport_H, Editor.Scrollbars.Current))
            then
               Set_Current_Scroll_Y (0);
            end if;
         end;
      end if;
   end Update_Scroll_For_Snapshot;

   ------------------------------------------------------------------
   -- Accessors
   ------------------------------------------------------------------

   function Scroll_X return Natural is
   begin
      if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         return 0;
      else
         return Current_Scroll_X;
      end if;
   end Scroll_X;

   function Scroll_Y return Natural is
   begin
      return Current_Scroll_Y;
   end Scroll_Y;

   function Visual_Scroll_X return Float is
   begin
      if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         return 0.0;
      else
         return Current_Visual_Scroll_X;
      end if;
   end Visual_Scroll_X;

   function Visual_Scroll_Y return Float is
   begin
      return Current_Visual_Scroll_Y;
   end Visual_Scroll_Y;

   function Visual_Screen_X
     (Layout     : Editor.Layout.Layout_Config;
      Line_Count : Natural;
      Col        : Natural) return Float
   is
      Logical_X : constant Natural := Scroll_X;
      Fractional_X : constant Float := Visual_Scroll_X - Float (Logical_X);
   begin
      return Editor.Layout.Text_Cell_X (Layout, Line_Count, Col, Logical_X)
        - Fractional_X * Float (Editor.Layout.Cell_W);
   end Visual_Screen_X;

   function Visual_Screen_Y
     (Layout      : Editor.Layout.Layout_Config;
      Visible_Row : Natural) return Float
   is
      Fractional_Y : constant Float :=
        Visual_Scroll_Y - Float (Current_Scroll_Y);
   begin
      return Editor.Layout.Row_Top_Y (Layout, Visible_Row)
        - Fractional_Y * Float (Editor.Layout.Cell_H);
   end Visual_Screen_Y;

   ------------------------------------------------------------------
   -- Auto-scroll for drag/select
   ------------------------------------------------------------------

   procedure Auto_Scroll_For_Point
     (X      : Natural;
      Y      : Natural;
      Layout : Editor.Layout.Layout_Config)
   is
      Left_Edge    : constant Natural := Layout.Origin_X;
      Top_Edge     : constant Natural := Layout.Origin_Y;
      Minimap     : constant Editor.Minimap.Minimap_Config :=
        Editor.Minimap.Current;
      Scrollbars  : constant Editor.Scrollbars.Scrollbar_Config :=
        Editor.Scrollbars.Current;
      Effective_W : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Width
          (Current_Viewport_W, Scrollbars);
      Effective_H : constant Natural :=
        Editor.Scrollbars.Effective_Viewport_Height
          (Current_Viewport_H, Scrollbars);
      Effective_Minimap_Enabled : constant Boolean :=
        Editor.Settings.Show_Minimap and then Minimap.Enabled;
      Right_Edge   : constant Natural :=
        (if Effective_Minimap_Enabled then
            Natural (Editor.Layout.Text_Viewport_Right
              (Layout, Effective_W, Minimap.Enabled, Minimap.Width, Minimap.Padding_Left, Minimap.Padding_Right))
         else
            Natural (Editor.Layout.Text_Right_X (Layout, Effective_W)));
      Bottom_Edge  : constant Natural :=
        Natural (Editor.Layout.View_Bottom_Y (Layout, Effective_H));

      Scroll_Step_X : constant Natural := 1;
      Scroll_Step_Y : constant Natural := 1;
   begin
      ----------------------------------------------------------------
      -- Horizontal
      ----------------------------------------------------------------
      if Current_Wrap_Mode = Editor.Wrap.Wrap_At_Viewport then
         Set_Current_Scroll_X (0);
      elsif X < Left_Edge then
         if Current_Scroll_X > Scroll_Step_X then
            Set_Current_Scroll_X (Current_Scroll_X - Scroll_Step_X);
         else
            Set_Current_Scroll_X (0);
         end if;

      elsif X >= Right_Edge then
         Set_Current_Scroll_X (Current_Scroll_X + Scroll_Step_X);
      end if;

      ----------------------------------------------------------------
      -- Vertical
      ----------------------------------------------------------------
      if Y < Top_Edge then
         if Current_Scroll_Y > Scroll_Step_Y then
            Set_Current_Scroll_Y (Current_Scroll_Y - Scroll_Step_Y);
         else
            Set_Current_Scroll_Y (0);
         end if;

      elsif Y >= Bottom_Edge then
         Set_Current_Scroll_Y (Current_Scroll_Y + Scroll_Step_Y);
      end if;
   end Auto_Scroll_For_Point;

end Editor.View;