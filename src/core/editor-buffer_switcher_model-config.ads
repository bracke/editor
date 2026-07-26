package Editor.Buffer_Switcher_Model.Config is

   type Buffer_Switcher_Config is record
      Max_Visible_Results      : Natural := 12;
      Query_Field_Min_Columns  : Natural := 24;
      Overlay_Width_In_Columns : Natural := 72;
      Row_Height_In_Rows       : Natural := 1;
      Header_Height_In_Rows    : Natural := 1;
      Field_Height_In_Rows     : Natural := 1;
      Result_Padding_Columns   : Natural := 1;
      Preview_Max_Lines        : Natural := 7;
   end record;

end Editor.Buffer_Switcher_Model.Config;
