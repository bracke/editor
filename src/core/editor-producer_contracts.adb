with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;

package body Editor.Producer_Contracts is

   function Accepted return Producer_Result is
   begin
      return (Status       => Producer_Accepted,
              Row_Accepted => True,
              Target_Kept  => True);
   end Accepted;

   function Accepted_Untargeted return Producer_Result is
   begin
      return (Status       => Producer_Accepted_Untargeted,
              Row_Accepted => True,
              Target_Kept  => False);
   end Accepted_Untargeted;

   function Rejected_Empty_Text return Producer_Result is
   begin
      return (Status       => Producer_Rejected_Empty_Text,
              Row_Accepted => False,
              Target_Kept  => False);
   end Rejected_Empty_Text;

   function Rejected_Invalid_State return Producer_Result is
   begin
      return (Status       => Producer_Rejected_Invalid_State,
              Row_Accepted => False,
              Target_Kept  => False);
   end Rejected_Invalid_State;

   function Normalize_Producer_Text (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Both);
   end Normalize_Producer_Text;

   function Normalize_Producer_Source (Source : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Source, Both);
   end Normalize_Producer_Source;

end Editor.Producer_Contracts;
