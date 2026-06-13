with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Editor.State;

package body Editor.Feature_Targets is

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Both);
   end Trim_Image;

   function Validate_Buffer_Target_For_Feature_Row
     (S      : Editor.State.State_Type;
      Buffer : Natural;
      Line   : Natural;
      Column : Natural) return Feature_Row_Target_Validation
   is
      Live : constant Boolean :=
        Editor.State.Has_Active_Buffer (S)
        and then Buffer /= 0
        and then Buffer = S.Active_Buffer_Token
        and then Line > 0
        and then Column > 0
        and then Line <= Editor.State.Line_Count (S);
   begin
      if Live then
         return (Valid  => True,
                 Buffer => Buffer,
                 Line   => Line,
                 Column => Column);
      else
         return (Valid  => False,
                 Buffer => 0,
                 Line   => 0,
                 Column => 0);
      end if;
   end Validate_Buffer_Target_For_Feature_Row;

   function Build_Target_Display_Label
     (Source : String;
      Line   : Natural;
      Column : Natural) return String
   is
      Clean_Source : constant String := Ada.Strings.Fixed.Trim (Source, Both);
      Position     : constant String := Trim_Image (Line) & ":" & Trim_Image (Column);
   begin
      if Clean_Source'Length = 0 then
         return Position;
      else
         return Clean_Source & ":" & Position;
      end if;
   end Build_Target_Display_Label;

end Editor.Feature_Targets;
