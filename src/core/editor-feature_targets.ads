with Editor.State;

package Editor.Feature_Targets is

   type Feature_Row_Target_Validation is record
      Valid  : Boolean := False;
      Buffer : Natural := 0;
      Line   : Natural := 0;
      Column : Natural := 0;
   end record;

   function Validate_Buffer_Target_For_Feature_Row
     (S      : Editor.State.State_Type;
      Buffer : Natural;
      Line   : Natural;
      Column : Natural) return Feature_Row_Target_Validation;

   function Build_Target_Display_Label
     (Source : String;
      Line   : Natural;
      Column : Natural) return String;

end Editor.Feature_Targets;
