with Editor.Layout;

package Editor.Minimap is

   type Minimap_Config is record
      Enabled       : Boolean := True;
      Width         : Natural := 96;
      Padding_Left  : Natural := 8;
      Padding_Right : Natural := 8;
   end record;

   type Minimap_Line_Info is record
      Row         : Natural := 0;
      Start_Y     : Float := 0.0;
      Height      : Float := 1.0;
      Has_Text    : Boolean := False;
      Text_Length : Natural := 0;
   end record;

   type Minimap_Line_Info_Array is array (Natural range <>) of Minimap_Line_Info;

   function Current return Minimap_Config;

   procedure Set_Current
     (Config : Minimap_Config);


   procedure Set_Enabled
     (Enabled : Boolean);

   function Enabled return Boolean;

   function Reserved_Width
     (Config : Minimap_Config) return Natural;

   function Left_X
     (Layout         : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Config         : Minimap_Config) return Float;

   function Right_X
     (Layout         : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Config         : Minimap_Config) return Float;

   function Contains_Point
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      Config          : Minimap_Config) return Boolean;

   function Row_For_Y
     (Y                : Natural;
      Total_Line_Count : Natural;
      Layout           : Editor.Layout.Layout_Config;
      Viewport_Height  : Natural;
      Config           : Minimap_Config) return Natural;

   function Row_Y
     (Document_Row : Natural;
      Line_Count   : Natural;
      Viewport_H   : Natural) return Float;

   function Sample_Row
     (Pixel_Y        : Natural;
      Line_Count     : Natural;
      Minimap_Height : Natural) return Natural;

   function Viewport_Marker_Y
     (Visible_First_Row : Natural;
      Line_Count        : Natural;
      Viewport_H        : Natural) return Float;

   function Viewport_Marker_Height
     (Visible_Row_Count : Natural;
      Line_Count        : Natural;
      Viewport_H        : Natural) return Float;

end Editor.Minimap;
