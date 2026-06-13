with Editor.Layout;

package body Editor.Gutter is

   function Visible_Row_For_Y
     (Y      : Natural;
      Layout : Editor.Layout.Layout_Config) return Natural
   is
      Top : constant Natural := Natural (Editor.Layout.Text_Viewport_Y (Layout));
   begin
      if Y < Top then
         return 0;
      end if;

      return (Y - Top) / Editor.Layout.Cell_H;
   end Visible_Row_For_Y;

   function Scrolled_Visible_Row_For_Y
     (Y        : Natural;
      Layout   : Editor.Layout.Layout_Config;
      Scroll_Y : Natural) return Natural
   is
   begin
      return Visible_Row_For_Y (Y, Layout) + Scroll_Y;
   end Scrolled_Visible_Row_For_Y;

   function Hit_Test
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Line_Count      : Natural;
      Viewport_Height : Natural) return Gutter_Zone
   is
      Effective_Lines : constant Natural := Natural'Max (1, Line_Count);
      Gutter_Left     : constant Natural :=
        Natural (Editor.Layout.Gutter_Left (Layout));
      Gutter_Right    : constant Natural :=
        Natural (Editor.Layout.Gutter_Right (Layout, Effective_Lines));
      Top             : constant Natural :=
        Natural (Editor.Layout.Text_Viewport_Y (Layout));
      Height          : constant Natural :=
        Editor.Layout.Text_Viewport_Height (Layout, Viewport_Height);
      Marker_Left     : constant Natural :=
        Editor.Layout.Gutter_Marker_X (Layout);
      Marker_Right    : constant Natural :=
        Marker_Left + Editor.Layout.Gutter_Marker_Width;
      Fold_Left       : constant Natural :=
        Editor.Layout.Gutter_Fold_X (Layout);
      Fold_Right      : constant Natural :=
        Fold_Left + Editor.Layout.Gutter_Fold_Width;
   begin
      if Y < Top
        or else Y >= Top + Height
        or else X < Gutter_Left
        or else X >= Gutter_Right
      then
         return Outside_Gutter;
      end if;

      if Editor.Layout.Marker_Zone_Visible (Layout, Effective_Lines)
        and then X >= Marker_Left and then X < Marker_Right
      then
         return Marker_Zone;
      end if;

      if X >= Fold_Left and then X < Fold_Right then
         return Fold_Marker_Zone;
      end if;

      return Line_Number_Zone;
   end Hit_Test;


   function Hit_Test_Result
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Line_Count      : Natural;
      Viewport_Height : Natural;
      Scroll_Y        : Natural;
      Folding         : Editor.Folding.Folding_State) return Gutter_Hit_Result
   is
      Zone : constant Gutter_Zone :=
        Hit_Test
          (X               => X,
           Y               => Y,
           Layout          => Layout,
           Line_Count      => Line_Count,
           Viewport_Height => Viewport_Height);
      Row  : Natural := 0;
   begin
      if Zone /= Outside_Gutter then
         Row := Document_Row_For_Y
           (Y             => Y,
            Layout        => Layout,
            Scroll_Y      => Scroll_Y,
            Folding       => Folding,
            Document_Rows => Line_Count);
      end if;

      return (Zone => Zone, Row => Row);
   end Hit_Test_Result;

   function Document_Row_For_Y
     (Y              : Natural;
      Layout         : Editor.Layout.Layout_Config;
      Scroll_Y       : Natural;
      Folding        : Editor.Folding.Folding_State;
      Document_Rows  : Natural) return Natural
   is
      Visible_Count : constant Natural :=
        Natural'Max (1, Editor.Folding.Visible_Row_Count (Folding, Document_Rows));
      Visible_Row   : constant Natural :=
        Natural'Min
          (Scrolled_Visible_Row_For_Y (Y, Layout, Scroll_Y),
           Visible_Count - 1);
      Document_Row  : Natural := 0;
   begin
      if Document_Rows = 0 then
         return 0;
      end if;

      Document_Row := Editor.Folding.Visible_Row_To_Document_Row
        (Folding, Visible_Row);

      if Document_Row >= Document_Rows then
         return Document_Rows - 1;
      end if;

      return Document_Row;
   end Document_Row_For_Y;

end Editor.Gutter;
