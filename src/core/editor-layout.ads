with Editor.Status_Bar;
with Editor.Tab_Bar;
with Editor.File_Tree_View;
with Editor.Panels;

package Editor.Layout is

   type Layout_Config is record
      Origin_X : Natural := 0;
      Origin_Y : Natural := 0;
      Gutter_Left_Padding  : Natural := 0;
      Gutter_Right_Padding : Natural := 5;
      Text_Left_Padding    : Natural := 10;
      Tab_Bar              : Editor.Tab_Bar.Tab_Bar_Config;
      File_Tree_View       : Editor.File_Tree_View.File_Tree_View_Config;
      Panels               : Editor.Panels.Panel_Set;
      Status_Bar           : Editor.Status_Bar.Status_Bar_Config;
   end record;

   function Current return Layout_Config;

   function Cell_W return Positive;
   function Cell_H return Positive;

   function Digit_Count (N : Natural) return Natural;

   function Gutter_Marker_Width return Natural;

   type Rect is record
      X      : Integer := 0;
      Y      : Integer := 0;
      Width  : Natural := 0;
      Height : Natural := 0;
   end record;

   function Panel_Rect
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect;

   function Panel_Splitter_Rect
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect;

   function Is_In_Panel
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean;

   function Is_In_Panel_Splitter
     (Config          : Layout_Config;
      Id              : Editor.Panels.Panel_Id;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean;

   function Editor_Body_Rect
     (Config          : Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Rect;

   function File_Tree_X
     (Config : Layout_Config) return Integer;

   function File_Tree_Y
     (Config : Layout_Config) return Integer;

   function File_Tree_Width
     (Config : Layout_Config) return Natural;

   function File_Tree_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function File_Tree_Right
     (Config : Layout_Config) return Integer;

   function File_Tree_Splitter_X
     (Config : Layout_Config) return Integer;

   function File_Tree_Splitter_Y
     (Config : Layout_Config) return Integer;

   function File_Tree_Splitter_Width
     (Config : Layout_Config) return Natural;

   function File_Tree_Splitter_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function File_Tree_Splitter_Right
     (Config : Layout_Config) return Integer;

   function Is_In_File_Tree_Splitter
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Height : Natural) return Boolean;

   function Editor_Body_X
     (Config : Layout_Config) return Natural;

   function Is_In_File_Tree
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Height : Natural) return Boolean;

   function File_Tree_Max_Visible_Rows
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function Gutter_Fold_Width return Natural;

   function Gutter_Marker_X
     (Config : Layout_Config) return Natural;

   function Gutter_Fold_X
     (Config : Layout_Config) return Natural;

   function Marker_Zone_Visible
     (Config     : Layout_Config;
      Line_Count : Natural) return Boolean;

   function Gutter_Width_For_Line_Count
     (Config     : Layout_Config;
      Line_Count : Natural) return Natural;

   function Text_Origin_X
     (Config     : Layout_Config;
      Line_Count : Natural) return Natural;

   function Gutter_Left
     (Config : Layout_Config) return Float;

   function Gutter_Right
     (Config     : Layout_Config;
      Line_Count : Natural) return Float;

   function Line_Number_Right_Edge
     (Config     : Layout_Config;
      Line_Count : Natural) return Float;

   function Line_Number_Cell_X
     (Config           : Layout_Config;
      Line_Count       : Natural;
      Digit_From_Right : Natural) return Float;

   function Text_Right_X
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Float;

   function Text_Viewport_Right
     (Config          : Layout_Config;
      Viewport_Width  : Natural;
      Minimap_Enabled : Boolean;
      Minimap_Width   : Natural;
      Padding_Left    : Natural;
      Padding_Right   : Natural) return Float;

   function Minimap_Left
     (Config         : Layout_Config;
      Viewport_Width : Natural;
      Minimap_Width  : Natural;
      Padding_Right  : Natural) return Float;

   function Minimap_Right
     (Config         : Layout_Config;
      Viewport_Width : Natural;
      Padding_Right  : Natural) return Float;

   function Text_Cell_X
     (Config     : Layout_Config;
      Line_Count : Natural;
      Column     : Natural;
      Scroll_X   : Natural) return Float;

   function Text_Cell_Width
     (Column_Count : Natural) return Natural;

   function Text_Visible_Column_Count
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural) return Natural;

   function Last_Visible_Text_Column
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural;
      Scroll_X       : Natural) return Natural;

   function Text_Column_For_X
     (Config     : Layout_Config;
      Line_Count : Natural;
      X          : Natural;
      Scroll_X   : Natural) return Natural;

   function Tab_Bar_Height
     (Config : Layout_Config) return Natural;

   function Tab_Bar_Y
     (Config : Layout_Config) return Integer;

   function Tab_Bar_Width
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Natural;

   function Text_Viewport_Y
     (Config : Layout_Config) return Integer;

   function Row_Top_Y
     (Config      : Layout_Config;
      Visible_Row : Natural) return Float;

   function Row_For_Y
     (Config   : Layout_Config;
      Y        : Natural;
      Scroll_Y : Natural) return Natural;

   function Status_Bar_Height
     (Config : Layout_Config) return Natural;

   function Status_Bar_Y
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Integer;

   function Status_Bar_Width
     (Config         : Layout_Config;
      Viewport_Width : Natural) return Natural;

   function Is_In_Status_Bar
     (Config          : Layout_Config;
      X               : Integer;
      Y               : Integer;
      Viewport_Width  : Natural;
      Viewport_Height : Natural) return Boolean;

   function Text_Viewport_Height
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function View_Bottom_Y
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Float;

   function Row_Block_Height
     (Row_Count : Natural) return Natural;

   function Visible_Row_Count
     (Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function Last_Visible_Row
     (Scroll_Y        : Natural;
      Config          : Layout_Config;
      Viewport_Height : Natural) return Natural;

   function Text_Viewport_Width
     (Config         : Layout_Config;
      Line_Count     : Natural;
      Viewport_Width : Natural) return Natural;

   function Text_Viewport_Width
     (Config          : Layout_Config;
      Line_Count      : Natural;
      Viewport_Width  : Natural;
      Minimap_Enabled : Boolean;
      Minimap_Width   : Natural;
      Padding_Left    : Natural;
      Padding_Right   : Natural) return Natural;

end Editor.Layout;
