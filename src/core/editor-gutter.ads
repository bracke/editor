with Editor.Layout;
with Editor.Folding;

package Editor.Gutter is

   type Gutter_Zone is
     (Outside_Gutter,
      Marker_Zone,
      Fold_Marker_Zone,
      Line_Number_Zone);

   type Gutter_Hit_Result is record
      Zone : Gutter_Zone := Outside_Gutter;
      Row  : Natural := 0;
   end record;

   function Hit_Test
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Line_Count      : Natural;
      Viewport_Height : Natural) return Gutter_Zone;

   function Hit_Test_Result
     (X, Y            : Natural;
      Layout          : Editor.Layout.Layout_Config;
      Line_Count      : Natural;
      Viewport_Height : Natural;
      Scroll_Y        : Natural;
      Folding         : Editor.Folding.Folding_State) return Gutter_Hit_Result;

   function Visible_Row_For_Y
     (Y      : Natural;
      Layout : Editor.Layout.Layout_Config) return Natural;

   function Scrolled_Visible_Row_For_Y
     (Y        : Natural;
      Layout   : Editor.Layout.Layout_Config;
      Scroll_Y : Natural) return Natural;

   function Document_Row_For_Y
     (Y              : Natural;
      Layout         : Editor.Layout.Layout_Config;
      Scroll_Y       : Natural;
      Folding        : Editor.Folding.Folding_State;
      Document_Rows  : Natural) return Natural;

end Editor.Gutter;
