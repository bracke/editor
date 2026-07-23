with Ada.Strings.Fixed;

package body Editor.Image_Helpers is

   function Trim_Image (Value : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Both);
   end Trim_Image;

   function Trim_Image (Value : Boolean) return String is
   begin
      return Ada.Strings.Fixed.Trim (Boolean'Image (Value), Ada.Strings.Both);
   end Trim_Image;

end Editor.Image_Helpers;
