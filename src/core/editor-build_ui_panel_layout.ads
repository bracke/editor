package Editor.Build_UI_Panel_Layout is

   type Build_UI_Panel_Zone is
     (Outside_Build_UI_Panel,
      Build_UI_Panel_Header,
      Build_UI_Panel_Status,
      Build_UI_Panel_Action_Row,
      Build_UI_Panel_Suppressed_Header,
      Build_UI_Panel_Suppressed_Row,
      Build_UI_Panel_Background);

   type Build_UI_Panel_Geometry is record
      X : Integer := 0;
      Y : Integer := 0;
      W : Natural := 0;
      H : Natural := 0;
      Total_Rows : Natural := 0;
      Action_Start_Row : Natural := 2;
      Action_Count : Natural := 0;
      Suppressed_Header_Row : Natural := 0;
      Suppressed_Start_Row : Natural := 0;
      Suppressed_Count : Natural := 0;
   end record;

   type Build_UI_Panel_Hit is record
      Zone : Build_UI_Panel_Zone := Outside_Build_UI_Panel;
      Row  : Natural := 0;
   end record;

   function Layout
     (Viewport_Width       : Natural;
      Text_Viewport_Y      : Natural;
      Text_Viewport_Height : Natural;
      Cell_H               : Natural;
      Action_Count         : Natural;
      Suppressed_Count     : Natural) return Build_UI_Panel_Geometry;

   function Displayed_Suppressed_Row_Count
     (Text_Viewport_Height : Natural;
      Cell_H               : Natural;
      Action_Count         : Natural;
      Suppressed_Count     : Natural) return Natural;

   function Visible_Row_Count
     (Geometry : Build_UI_Panel_Geometry;
      Cell_H   : Natural) return Natural;

   function Hit_Test
     (Geometry : Build_UI_Panel_Geometry;
      Cell_H   : Natural;
      X        : Integer;
      Y        : Integer) return Build_UI_Panel_Hit;

end Editor.Build_UI_Panel_Layout;
