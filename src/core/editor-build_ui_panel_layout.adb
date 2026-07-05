package body Editor.Build_UI_Panel_Layout is

   function Displayed_Suppressed_Row_Count
     (Text_Viewport_Height : Natural;
      Cell_H               : Natural;
      Action_Count         : Natural;
      Suppressed_Count     : Natural) return Natural
   is
      Panel_Rows : constant Natural :=
        (if Cell_H = 0 then 0 else Text_Viewport_Height / Cell_H);
      Suppressed_Header : constant Natural :=
        (if Suppressed_Count = 0 then 0 else 1);
      Reserved_Action_Rows : constant Natural :=
        (if Action_Count = 0 then 0 else Natural'Min (3, Action_Count));
      Fixed_Rows : constant Natural := 2 + Suppressed_Header + Reserved_Action_Rows;
      Available : Natural := 0;
   begin
      if Suppressed_Count = 0 or else Suppressed_Header = 0 then
         return 0;
      end if;

      if Panel_Rows > Fixed_Rows then
         Available := Panel_Rows - Fixed_Rows;
      elsif Panel_Rows > 3 then
         Available := 1;
      else
         Available := 0;
      end if;

      return Natural'Min (Suppressed_Count, Available);
   end Displayed_Suppressed_Row_Count;

   function Layout
     (Viewport_Width       : Natural;
      Text_Viewport_Y      : Natural;
      Text_Viewport_Height : Natural;
      Cell_H               : Natural;
      Action_Count         : Natural;
      Suppressed_Count     : Natural) return Build_UI_Panel_Geometry
   is
      Width : constant Natural := Natural'Min (420, Viewport_Width);
      Suppressed_Header : constant Natural :=
        (if Suppressed_Count = 0 then 0 else 1);
      Suppressed_Header_Row : constant Natural :=
        (if Suppressed_Count = 0 then 0 else 2);
      Suppressed_Start_Row : constant Natural :=
        (if Suppressed_Count = 0 then 0 else Suppressed_Header_Row + 1);
      Action_Start_Row : constant Natural :=
        2 + Suppressed_Header + Suppressed_Count;
      Total_Rows : constant Natural :=
        Natural'Max (3, 2 + Action_Count + Suppressed_Header + Suppressed_Count);
      H : constant Natural :=
        (if Cell_H = 0 then 0
         else Natural'Min (Text_Viewport_Height, Total_Rows * Cell_H));
   begin
      return
        (X => Integer (Viewport_Width) - Integer (Width),
         Y => Integer (Text_Viewport_Y),
         W => Width,
         H => H,
         Total_Rows => Total_Rows,
         Action_Start_Row => Action_Start_Row,
         Action_Count => Action_Count,
         Suppressed_Header_Row => Suppressed_Header_Row,
         Suppressed_Start_Row => Suppressed_Start_Row,
         Suppressed_Count => Suppressed_Count);
   end Layout;

   function Visible_Row_Count
     (Geometry : Build_UI_Panel_Geometry;
      Cell_H   : Natural) return Natural
   is
   begin
      if Cell_H = 0 then
         return 0;
      else
         return Geometry.H / Cell_H;
      end if;
   end Visible_Row_Count;

   function Hit_Test
     (Geometry : Build_UI_Panel_Geometry;
      Cell_H   : Natural;
      X        : Integer;
      Y        : Integer) return Build_UI_Panel_Hit
   is
      Row : Natural := 0;
      Visible_Rows : constant Natural := Visible_Row_Count (Geometry, Cell_H);
   begin
      if Cell_H = 0
        or else Geometry.W = 0
        or else Geometry.H = 0
        or else X < Geometry.X
        or else X >= Geometry.X + Integer (Geometry.W)
        or else Y < Geometry.Y
        or else Y >= Geometry.Y + Integer (Geometry.H)
      then
         return (Zone => Outside_Build_UI_Panel, Row => 0);
      end if;

      Row := Natural ((Y - Geometry.Y) / Integer (Cell_H));
      if Row >= Visible_Rows then
         return (Zone => Outside_Build_UI_Panel, Row => 0);
      elsif Row = 0 then
         return (Zone => Build_UI_Panel_Header, Row => 0);
      elsif Row = 1 then
         return (Zone => Build_UI_Panel_Status, Row => 0);
      elsif Row >= Geometry.Action_Start_Row
        and then Row < Geometry.Action_Start_Row + Geometry.Action_Count
      then
         return
           (Zone => Build_UI_Panel_Action_Row,
            Row  => Row - Geometry.Action_Start_Row + 1);
      elsif Geometry.Suppressed_Header_Row /= 0
        and then Row = Geometry.Suppressed_Header_Row
      then
         return (Zone => Build_UI_Panel_Suppressed_Header, Row => 0);
      elsif Geometry.Suppressed_Start_Row /= 0
        and then Row >= Geometry.Suppressed_Start_Row
        and then Row < Geometry.Suppressed_Start_Row + Geometry.Suppressed_Count
      then
         return
           (Zone => Build_UI_Panel_Suppressed_Row,
            Row  => Row - Geometry.Suppressed_Start_Row + 1);
      else
         return (Zone => Build_UI_Panel_Background, Row => 0);
      end if;
   end Hit_Test;

end Editor.Build_UI_Panel_Layout;
