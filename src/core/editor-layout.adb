with Editor.Fonts;
with Editor.Status_Bar;
with Editor.Tab_Bar;
with Editor.File_Tree_View;
with Editor.Panels;
with Editor.Font_Config;

package body Editor.Layout is

   use type Editor.Panels.Panel_Id;

   function Cell_W return Positive is
   begin
      return Editor.Font_Config.Cell_W;
   end Cell_W;

   function Cell_H return Positive is
   begin
      return Editor.Font_Config.Cell_H;
   end Cell_H;

   function Current return Layout_Config is
      Result : constant Layout_Config :=
        (Origin_X => 0,
         Origin_Y => 0,
         Gutter_Left_Padding  => 0,
         Gutter_Right_Padding => Cell_W / 2,
         Text_Left_Padding    => Cell_W,
         Tab_Bar              =>
           (Enabled            => True,
            Show_Close_Buttons => True,
            Minimum_Tab_Width  => 8,
            Maximum_Tab_Width  => 24),
         File_Tree_View       => Editor.File_Tree_View.Current_Config,
         Panels               => Editor.Panels.Current,
         Status_Bar           => (Enabled => True));
   begin
      pragma Assert
        (Editor.Fonts.Font_Is_Monospace,
         "Editor requires a monospace font");

      pragma Assert
        (Float (Cell_W) >= Editor.Fonts.Monospace_Cell_Width,
         "Cell_W must be >= monospace font advance");

      return Result;
   end Current;

   function Digit_Count (N : Natural) return Natural is
      V : Natural := N;
      C : Natural := 1;
   begin
      while V >= 10 loop
         V := V / 10;
         C := C + 1;
      end loop;

      return C;
   end Digit_Count;

   function Gutter_Marker_Width return Natural is
   begin
      return Cell_W;
   end Gutter_Marker_Width;

   function Gutter_Fold_Width return Natural is
   begin
      return Cell_W;
   end Gutter_Fold_Width;

   function Non_Negative_Difference
     (Left  : Natural;
      Right : Natural) return Natural
   is
   begin
      if Left <= Right then
         return 0;
      else
         return Left - Right;
      end if;
   end Non_Negative_Difference;

   function Panel_Size_In_Pixels
     (Config : Layout_Config;
      Id     : Editor.Panels.Panel_Id) return Natural
   is
      Panel_Config : constant Editor.Panels.Panel_Config :=
        Editor.Panels.Config (Config.Panels, Id);
      Size : constant Natural :=
        Editor.Panels.Current_Size (Config.Panels, Id);
   begin
      if not Editor.Panels.Is_Visible (Config.Panels, Id) then
         return 0;
      end if;

      case Panel_Config.Size_Unit is
         when Editor.Panels.Columns =>
            return Size * Cell_W;
         when Editor.Panels.Rows =>
            return Size * Cell_H;
         when Editor.Panels.Pixels =>
            return Size;
      end case;
   end Panel_Size_In_Pixels;

   function Main_Area_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
      Reserved : constant Natural := Tab_Bar_Height (Config) + Status_Bar_Height (Config);
   begin
      if Viewport_Height <= Reserved then
         return 0;
      else
         return Viewport_Height - Reserved;
      end if;
   end Main_Area_Height;

   function Bottom_Panel_Reserved_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
      Panel_Config : constant Editor.Panels.Panel_Config :=
        Editor.Panels.Config (Config.Panels, Editor.Panels.Bottom_Panel);
      Body_H : constant Natural := Main_Area_Height (Config, Viewport_Height);
      Panel_H : constant Natural := Natural'Min
        (Panel_Size_In_Pixels (Config, Editor.Panels.Bottom_Panel), Body_H);
      Splitter_H : Natural := 0;
   begin
      if Panel_H = 0 or else not Editor.Panels.Is_Visible
        (Config.Panels, Editor.Panels.Bottom_Panel)
      then
         return 0;
      end if;

      if Panel_Config.Resizable and then Panel_Config.Splitter_Size_Pixels > 0 then
         Splitter_H := Natural'Min
           (Panel_Config.Splitter_Size_Pixels,
            Non_Negative_Difference (Body_H, Panel_H));
      end if;

      return Panel_H + Splitter_H;
   end Bottom_Panel_Reserved_Height;

   function Panel_Rect
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect
   is
      Panel_Config : constant Editor.Panels.Panel_Config :=
        Editor.Panels.Config (Config.Panels, Id);
      Body_Y : constant Integer := Integer (Config.Origin_Y + Tab_Bar_Height (Config));
      Body_H : constant Natural := Main_Area_Height (Config, Viewport_Height);
      Bottom_Reserved : constant Natural :=
        (if Id = Editor.Panels.Bottom_Panel then 0
         else Bottom_Panel_Reserved_Height (Config, Viewport_Height));
      Side_H : constant Natural := Non_Negative_Difference (Body_H, Bottom_Reserved);
      Size_Pixels : constant Natural := Panel_Size_In_Pixels (Config, Id);
      Effective_Size : constant Natural := Natural'Min (Size_Pixels, Viewport_Width);
   begin
      if not Editor.Panels.Is_Visible (Config.Panels, Id) then
         return (X => Integer (Config.Origin_X), Y => Body_Y, Width => 0, Height => 0);
      end if;

      case Panel_Config.Side is
         when Editor.Panels.Left_Side =>
            return (X => Integer (Config.Origin_X),
                    Y => Body_Y,
                    Width => Effective_Size,
                    Height => Side_H);
         when Editor.Panels.Right_Side =>
            return (X => Integer
                      (Config.Origin_X
                       + Non_Negative_Difference (Viewport_Width, Effective_Size)),
                    Y => Body_Y,
                    Width => Effective_Size,
                    Height => Side_H);
         when Editor.Panels.Bottom_Side =>
            declare
               Bottom_Size : constant Natural := Natural'Min (Size_Pixels, Body_H);
            begin
               return (X => Integer (Config.Origin_X),
                       Y => Integer
                         (Config.Origin_Y + Tab_Bar_Height (Config)
                          + Non_Negative_Difference (Body_H, Bottom_Size)),
                       Width => Viewport_Width,
                       Height => Bottom_Size);
            end;
      end case;
   end Panel_Rect;

   function Panel_Splitter_Rect
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect
   is
      Panel_Config : constant Editor.Panels.Panel_Config :=
        Editor.Panels.Config (Config.Panels, Id);
      Panel : constant Rect := Panel_Rect (Config, Id, Viewport_Width, Viewport_Height);
      Splitter : constant Natural := Panel_Config.Splitter_Size_Pixels;
   begin
      if Panel.Width = 0 or else Panel.Height = 0 or else Splitter = 0
        or else not Panel_Config.Resizable
      then
         return (X => Panel.X, Y => Panel.Y, Width => 0, Height => 0);
      end if;

      case Panel_Config.Side is
         when Editor.Panels.Left_Side =>
            return (X => Panel.X + Integer (Panel.Width),
                    Y => Panel.Y,
                    Width => Natural'Min (Splitter,
                      Non_Negative_Difference (Viewport_Width, Panel.Width)),
                    Height => Panel.Height);
         when Editor.Panels.Right_Side =>
            declare
               Effective_Splitter : constant Natural :=
                 Natural'Min (Splitter,
                   Non_Negative_Difference (Viewport_Width, Panel.Width));
            begin
               return (X => Panel.X - Integer (Effective_Splitter),
                       Y => Panel.Y,
                       Width => Effective_Splitter,
                       Height => Panel.Height);
            end;
         when Editor.Panels.Bottom_Side =>
            declare
               Body_Top : constant Integer :=
                 Integer (Config.Origin_Y + Tab_Bar_Height (Config));
               Available_Above : Natural := 0;
               Effective_Splitter : Natural := 0;
            begin
               if Panel.Y > Body_Top then
                  Available_Above := Natural (Panel.Y - Body_Top);
               end if;
               Effective_Splitter := Natural'Min (Splitter, Available_Above);
               return (X => Panel.X,
                       Y => Panel.Y - Integer (Effective_Splitter),
                       Width => Panel.Width,
                       Height => Effective_Splitter);
            end;
      end case;
   end Panel_Splitter_Rect;

   function Is_In_Panel
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean
   is
      R : constant Rect := Panel_Rect (Config, Id, Viewport_Width, Viewport_Height);
   begin
      return R.Width > 0 and then R.Height > 0
        and then X >= R.X
        and then X < R.X + Integer (R.Width)
        and then Y >= R.Y
        and then Y < R.Y + Integer (R.Height);
   end Is_In_Panel;

   function Is_In_Panel_Splitter
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean
   is
      R : constant Rect := Panel_Splitter_Rect (Config, Id, Viewport_Width, Viewport_Height);
   begin
      return R.Width > 0 and then R.Height > 0
        and then X >= R.X
        and then X < R.X + Integer (R.Width)
        and then Y >= R.Y
        and then Y < R.Y + Integer (R.Height);
   end Is_In_Panel_Splitter;

   function Editor_Body_Rect
     (Config          : Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect
   is
      Left_Panel    : constant Rect := Panel_Rect
        (Config, Editor.Panels.File_Tree_Panel, Viewport_Width, Viewport_Height);
      Left_Splitter : constant Rect := Panel_Splitter_Rect
        (Config, Editor.Panels.File_Tree_Panel, Viewport_Width, Viewport_Height);
      Right_Panel    : constant Rect := Panel_Rect
        (Config, Editor.Panels.Right_Sidebar_Panel, Viewport_Width, Viewport_Height);
      Right_Splitter : constant Rect := Panel_Splitter_Rect
        (Config, Editor.Panels.Right_Sidebar_Panel, Viewport_Width, Viewport_Height);
      Bottom_Panel    : constant Rect := Panel_Rect
        (Config, Editor.Panels.Bottom_Panel, Viewport_Width, Viewport_Height);
      Bottom_Splitter : constant Rect := Panel_Splitter_Rect
        (Config, Editor.Panels.Bottom_Panel, Viewport_Width, Viewport_Height);
      Left_Reserved   : constant Natural := Left_Panel.Width + Left_Splitter.Width;
      Right_Reserved  : constant Natural := Right_Panel.Width + Right_Splitter.Width;
      Bottom_Reserved : constant Natural := Bottom_Panel.Height + Bottom_Splitter.Height;
      Reserved_X      : constant Natural := Left_Reserved + Right_Reserved;
      Body_Y          : constant Integer := Integer (Config.Origin_Y + Tab_Bar_Height (Config));
      Body_H          : constant Natural := Main_Area_Height (Config, Viewport_Height);
   begin
      return (X => Integer (Config.Origin_X + Left_Reserved),
              Y => Body_Y,
              Width => Non_Negative_Difference (Viewport_Width, Reserved_X),
              Height => Non_Negative_Difference (Body_H, Bottom_Reserved));
   end Editor_Body_Rect;

   function File_Tree_X
     (Config : Layout_Config) return Integer
   is
   begin
      return Panel_Rect
        (Config, Editor.Panels.File_Tree_Panel, 0, 0).X;
   end File_Tree_X;

   function File_Tree_Y
     (Config : Layout_Config) return Integer
   is
   begin
      return Integer (Config.Origin_Y + Tab_Bar_Height (Config));
   end File_Tree_Y;

   function File_Tree_Width
     (Config : Layout_Config) return Natural
   is
   begin
      return Panel_Rect
        (Config, Editor.Panels.File_Tree_Panel, Natural'Last, Natural'Last).Width;
   end File_Tree_Width;

   function File_Tree_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
   begin
      return Text_Viewport_Height (Config, Viewport_Height);
   end File_Tree_Height;

   function File_Tree_Right
     (Config : Layout_Config) return Integer
   is
   begin
      return Integer (Config.Origin_X + File_Tree_Width (Config));
   end File_Tree_Right;

   function File_Tree_Splitter_X
     (Config : Layout_Config) return Integer
   is
   begin
      return Panel_Splitter_Rect
        (Config, Editor.Panels.File_Tree_Panel, Natural'Last, Natural'Last).X;
   end File_Tree_Splitter_X;

   function File_Tree_Splitter_Y
     (Config : Layout_Config) return Integer
   is
   begin
      return Panel_Splitter_Rect
        (Config, Editor.Panels.File_Tree_Panel, Natural'Last, Natural'Last).Y;
   end File_Tree_Splitter_Y;

   function File_Tree_Splitter_Width
     (Config : Layout_Config) return Natural
   is
   begin
      return Panel_Splitter_Rect
        (Config, Editor.Panels.File_Tree_Panel, Natural'Last, Natural'Last).Width;
   end File_Tree_Splitter_Width;

   function File_Tree_Splitter_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
   begin
      return Panel_Splitter_Rect
        (Config, Editor.Panels.File_Tree_Panel,
         Natural'Last, Viewport_Height).Height;
   end File_Tree_Splitter_Height;

   function File_Tree_Splitter_Right
     (Config : Layout_Config) return Integer
   is
   begin
      return File_Tree_Splitter_X (Config)
        + Integer (File_Tree_Splitter_Width (Config));
   end File_Tree_Splitter_Right;

   function Is_In_File_Tree_Splitter
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Height : Natural) return Boolean
   is
   begin
      return Is_In_Panel_Splitter
        (Config, Editor.Panels.File_Tree_Panel, X, Y,
         Natural'Last, Viewport_Height);
   end Is_In_File_Tree_Splitter;

   function Editor_Body_X
     (Config : Layout_Config) return Natural
   is
      Message_Body : constant Rect := Editor_Body_Rect (Config, Natural'Last, Natural'Last);
   begin
      if Message_Body.X <= 0 then
         return 0;
      else
         return Natural (Message_Body.X);
      end if;
   end Editor_Body_X;

   function Is_In_File_Tree
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Height : Natural) return Boolean
   is
   begin
      return Is_In_Panel
        (Config, Editor.Panels.File_Tree_Panel, X, Y,
         Natural'Last, Viewport_Height);
   end Is_In_File_Tree;

   function File_Tree_Max_Visible_Rows
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
   begin
      return File_Tree_Height (Config, Viewport_Height) / Cell_H;
   end File_Tree_Max_Visible_Rows;

   function Gutter_Marker_X
     (Config : Layout_Config) return Natural
   is
   begin
      return Editor_Body_X (Config) + Config.Gutter_Left_Padding;
   end Gutter_Marker_X;

   function Gutter_Fold_X
     (Config : Layout_Config) return Natural
   is
   begin
      return Gutter_Marker_X (Config) + Gutter_Marker_Width;
   end Gutter_Fold_X;

   function Marker_Zone_Visible
     (Config     : Layout_Config;
      Line_Count : Natural) return Boolean
   is
      Needed : constant Natural :=
        Config.Gutter_Left_Padding
        + Gutter_Marker_Width
        + Gutter_Fold_Width
        + Digit_Count (Line_Count) * Cell_W
        + Config.Gutter_Right_Padding;
   begin
      return Gutter_Width_For_Line_Count (Config, Line_Count) >= Needed;
   end Marker_Zone_Visible;

   function Gutter_Width_For_Line_Count
     (Config     : Layout_Config;
      Line_Count : Natural) return Natural
   is
   begin
      return Config.Gutter_Left_Padding
        + Gutter_Marker_Width
        + Gutter_Fold_Width
        + Digit_Count (Line_Count) * Cell_W
        + Config.Gutter_Right_Padding;
   end Gutter_Width_For_Line_Count;

   function Text_Origin_X
     (Config     : Layout_Config;
      Line_Count : Natural) return Natural
   is
   begin
      return Editor_Body_X (Config)
        + Gutter_Width_For_Line_Count (Config, Line_Count)
        + Config.Text_Left_Padding;
   end Text_Origin_X;

   function Gutter_Left
     (Config : Layout_Config) return Float
   is
   begin
      return Float (Editor_Body_X (Config));
   end Gutter_Left;

   function Gutter_Right
     (Config     : Layout_Config;
      Line_Count : Natural) return Float
   is
   begin
      return Float
        (Editor_Body_X (Config)
         + Gutter_Width_For_Line_Count (Config, Line_Count));
   end Gutter_Right;

   function Line_Number_Right_Edge
     (Config     : Layout_Config;
      Line_Count : Natural) return Float
   is
   begin
      return Gutter_Right (Config, Line_Count)
        - Float (Config.Gutter_Right_Padding);
   end Line_Number_Right_Edge;

   function Line_Number_Cell_X
     (Config           : Layout_Config;
      Line_Count       : Natural;
      Digit_From_Right : Natural) return Float
   is
   begin
      return Line_Number_Right_Edge (Config, Line_Count)
        - Float (Digit_From_Right + 1) * Float (Cell_W);
   end Line_Number_Cell_X;

   function Text_Right_X
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Float
   is
      Message_Body : constant Rect := Editor_Body_Rect (Config, Viewport_Width, Natural'Last);
   begin
      return Float (Message_Body.X + Integer (Message_Body.Width));
   end Text_Right_X;

   function Text_Viewport_Right
     (Config          : Layout_Config;
      Viewport_Width  : Natural;
      Minimap_Enabled : Boolean;
      Minimap_Width   : Natural;
      Padding_Left    : Natural;
      Padding_Right   : Natural) return Float
   is
      Message_Body     : constant Rect := Editor_Body_Rect (Config, Viewport_Width, Natural'Last);
      Right    : constant Natural := Natural (Message_Body.X + Integer (Message_Body.Width));
      Reserved : constant Natural := Padding_Left + Minimap_Width + Padding_Right;
   begin
      if not Minimap_Enabled or else Message_Body.Width <= Reserved then
         return Float (Right);
      end if;

      return Float (Right - Reserved);
   end Text_Viewport_Right;

   function Minimap_Left
     (Config         : Layout_Config;
      Viewport_Width : Natural;
      Minimap_Width  : Natural;
      Padding_Right  : Natural) return Float
   is
      Message_Body  : constant Rect := Editor_Body_Rect (Config, Viewport_Width, Natural'Last);
      Right : constant Natural := Natural (Message_Body.X + Integer (Message_Body.Width));
   begin
      if Message_Body.Width <= Minimap_Width + Padding_Right then
         return Float (Right);
      end if;

      return Float (Right - Padding_Right - Minimap_Width);
   end Minimap_Left;

   function Minimap_Right
     (Config         : Layout_Config;
      Viewport_Width : Natural;
      Padding_Right  : Natural) return Float
   is
      Message_Body  : constant Rect := Editor_Body_Rect (Config, Viewport_Width, Natural'Last);
      Right : constant Natural := Natural (Message_Body.X + Integer (Message_Body.Width));
   begin
      if Message_Body.Width <= Padding_Right then
         return Float (Right);
      end if;

      return Float (Right - Padding_Right);
   end Minimap_Right;

   function Text_Cell_X
     (Config     : Layout_Config;
      Line_Count : Natural;
      Column     : Natural;
      Scroll_X   : Natural) return Float
   is
   begin
      return Float (Text_Origin_X (Config, Line_Count))
        + Float (Column) * Float (Cell_W)
        - Float (Scroll_X) * Float (Cell_W);
   end Text_Cell_X;

   function Text_Cell_Width
     (Column_Count : Natural) return Natural
   is
   begin
      return Column_Count * Cell_W;
   end Text_Cell_Width;

   function Text_Visible_Column_Count
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural) return Natural
   is
   begin
      return Text_Viewport_Width (Config, Line_Count, Viewport_Width) / Cell_W;
   end Text_Visible_Column_Count;

   function Last_Visible_Text_Column
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural;
      Scroll_X       : Natural) return Natural
   is
      Columns : constant Natural :=
        Text_Visible_Column_Count (Config, Line_Count, Viewport_Width);
   begin
      if Viewport_Width = 0 then
         return Natural'Last;
      elsif Columns = 0 then
         return Scroll_X;
      else
         return Scroll_X + Columns;
      end if;
   end Last_Visible_Text_Column;

   function Text_Column_For_X
     (Config     : Layout_Config;
      Line_Count : Natural;
      X          : Natural;
      Scroll_X   : Natural) return Natural
   is
      Text_X : constant Natural := Text_Origin_X (Config, Line_Count);
   begin
      if X < Text_X then
         return 0;
      end if;

      return (X - Text_X) / Cell_W + Scroll_X;
   end Text_Column_For_X;

   function Tab_Bar_Height
     (Config : Layout_Config) return Natural
   is
   begin
      return Editor.Tab_Bar.Height_In_Rows (Config.Tab_Bar) * Cell_H;
   end Tab_Bar_Height;

   function Tab_Bar_Y
     (Config : Layout_Config) return Integer
   is
   begin
      return Integer (Config.Origin_Y);
   end Tab_Bar_Y;

   function Tab_Bar_Width
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Natural
   is
      pragma Unreferenced (Config);
   begin
      return Viewport_Width;
   end Tab_Bar_Width;

   function Text_Viewport_Y
     (Config : Layout_Config) return Integer
   is
   begin
      return Integer (Config.Origin_Y + Tab_Bar_Height (Config));
   end Text_Viewport_Y;

   function Row_Top_Y
     (Config      : Layout_Config;
      Visible_Row : Natural) return Float
   is
   begin
      return Float (Config.Origin_Y + Tab_Bar_Height (Config) + Visible_Row * Cell_H);
   end Row_Top_Y;

   function Row_For_Y
     (Config   : Layout_Config;
      Y        : Natural;
      Scroll_Y : Natural) return Natural
   is
      Top : constant Natural := Config.Origin_Y + Tab_Bar_Height (Config);
   begin
      if Y < Top then
         return 0;
      end if;

      return (Y - Top) / Cell_H + Scroll_Y;
   end Row_For_Y;

   function Status_Bar_Height
     (Config : Layout_Config) return Natural
   is
   begin
      return Editor.Status_Bar.Height_In_Rows (Config.Status_Bar) * Cell_H;
   end Status_Bar_Height;

   function Status_Bar_Y
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Integer
   is
      H : constant Natural := Status_Bar_Height (Config);
   begin
      if H = 0 then
         return Integer (Config.Origin_Y + Viewport_Height);
      elsif Viewport_Height <= H then
         return Integer (Config.Origin_Y);
      else
         return Integer (Config.Origin_Y + Viewport_Height - H);
      end if;
   end Status_Bar_Y;

   function Status_Bar_Width
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Natural
   is
      pragma Unreferenced (Config);
   begin
      return Viewport_Width;
   end Status_Bar_Width;

   function Is_In_Status_Bar
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean
   is
      H : constant Natural := Status_Bar_Height (Config);
      Left   : constant Integer := Integer (Config.Origin_X);
      Right  : constant Integer := Integer (Config.Origin_X + Viewport_Width);
      Top    : constant Integer := Status_Bar_Y (Config, Viewport_Height);
      Bottom : constant Integer := Integer (Config.Origin_Y + Viewport_Height);
   begin
      return H > 0
        and then X >= Left
        and then X < Right
        and then Y >= Top
        and then Y < Bottom;
   end Is_In_Status_Bar;

   function Text_Viewport_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
      Body_H : constant Natural := Main_Area_Height (Config, Viewport_Height);
   begin
      return Non_Negative_Difference
        (Body_H, Bottom_Panel_Reserved_Height (Config, Viewport_Height));
   end Text_Viewport_Height;

   function View_Bottom_Y
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Float
   is
   begin
      return Float (Config.Origin_Y + Tab_Bar_Height (Config) + Text_Viewport_Height (Config, Viewport_Height));
   end View_Bottom_Y;

   function Row_Block_Height
     (Row_Count : Natural) return Natural
   is
   begin
      return Row_Count * Cell_H;
   end Row_Block_Height;

   function Visible_Row_Count
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
   begin
      return Text_Viewport_Height (Config, Viewport_Height) / Cell_H;
   end Visible_Row_Count;

   function Last_Visible_Row
     (Scroll_Y        : Natural;
      Config          : Layout_Config;
      Viewport_Height : Natural) return Natural
   is
   begin
      return Scroll_Y + Visible_Row_Count (Config, Viewport_Height);
   end Last_Visible_Row;

   function Text_Viewport_Width
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural) return Natural
   is
      Left  : constant Natural := Text_Origin_X (Config, Line_Count);
      Message_Body  : constant Rect := Editor_Body_Rect (Config, Viewport_Width, Natural'Last);
      Right : constant Natural := Natural (Message_Body.X + Integer (Message_Body.Width));
   begin
      if Right <= Left then
         return 0;
      end if;

      return Right - Left;
   end Text_Viewport_Width;

   function Text_Viewport_Width
     (Config          : Layout_Config;
      Line_Count      : Natural;
      Viewport_Width  : Natural;
      Minimap_Enabled : Boolean;
      Minimap_Width   : Natural;
      Padding_Left    : Natural;
      Padding_Right   : Natural) return Natural
   is
      Left  : constant Natural := Text_Origin_X (Config, Line_Count);
      Right : constant Natural :=
        Natural (Text_Viewport_Right
          (Config, Viewport_Width, Minimap_Enabled, Minimap_Width,
           Padding_Left, Padding_Right));
   begin
      if Right <= Left then
         return 0;
      end if;

      return Right - Left;
   end Text_Viewport_Width;

end Editor.Layout;
