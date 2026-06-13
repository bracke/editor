with Editor.Layout;

package Editor.Scrollbars is

   type Scrollbar_Orientation is
     (Vertical_Scrollbar,
      Horizontal_Scrollbar);

   type Scrollbar_Config is record
      Enabled        : Boolean := True;
      Thickness      : Natural := 12;
      Min_Thumb_Size : Natural := 24;
   end record;

   type Scrollbar_Rect is record
      X : Float := 0.0;
      Y : Float := 0.0;
      W : Float := 0.0;
      H : Float := 0.0;
   end record;

   type Scrollbar_Geometry is record
      Visible : Boolean := False;
      Track   : Scrollbar_Rect;
      Thumb   : Scrollbar_Rect;
   end record;

   type Scrollbar_Hit is
     (No_Scrollbar_Hit,
      Scrollbar_Track_Hit,
      Scrollbar_Thumb_Hit);

   function Current return Scrollbar_Config;

   procedure Set_Current
     (Config : Scrollbar_Config);

   procedure Reset;

   procedure Set_Enabled
     (Enabled : Boolean);

   function Enabled return Boolean;

   function Reserved_Right
     (Config : Scrollbar_Config) return Natural;

   function Reserved_Bottom
     (Config : Scrollbar_Config) return Natural;

   function Effective_Viewport_Width
     (Viewport_Width : Natural;
      Config         : Scrollbar_Config) return Natural;

   function Effective_Viewport_Height
     (Viewport_Height : Natural;
      Config          : Scrollbar_Config) return Natural;

   function Vertical_Geometry
     (Layout          : Editor.Layout.Layout_Config;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      Total_Rows      : Natural;
      Visible_Rows    : Natural;
      Scroll_Y        : Natural;
      Config          : Scrollbar_Config) return Scrollbar_Geometry;

   function Horizontal_Geometry
     (Layout          : Editor.Layout.Layout_Config;
      Text_Left       : Natural;
      Text_Width      : Natural;
      Viewport_Height : Natural;
      Total_Cols      : Natural;
      Visible_Cols    : Natural;
      Scroll_X        : Natural;
      Config          : Scrollbar_Config) return Scrollbar_Geometry;

   function Hit_Test
     (Geometry : Scrollbar_Geometry;
      X        : Natural;
      Y        : Natural) return Scrollbar_Hit;

   function Scroll_Y_For_Thumb_Y
     (Geometry       : Scrollbar_Geometry;
      Total_Rows     : Natural;
      Visible_Rows   : Natural;
      Desired_Thumb_Y : Natural) return Natural;

   function Scroll_X_For_Thumb_X
     (Geometry        : Scrollbar_Geometry;
      Total_Cols      : Natural;
      Visible_Cols    : Natural;
      Desired_Thumb_X : Natural) return Natural;

end Editor.Scrollbars;
