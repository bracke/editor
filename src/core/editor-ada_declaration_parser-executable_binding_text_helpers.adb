with Editor.Text_Helpers;
with Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

package body Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers is

   use Editor.Text_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

   function Last_Selected_Part (Name : String) return String
     renames Editor.Ada_Declaration_Parser.Legality_Profile_Helpers.Last_Selected_Name_Part;

   function Leading_Name (Text : String) return String is
      Work : constant String := Trim (Text);
   begin
      if Work = "" then
         return "";
      elsif not ((Work (Work'First) >= 'A' and then Work (Work'First) <= 'Z')
                 or else (Work (Work'First) >= 'a' and then Work (Work'First) <= 'z'))
      then
         return "";
      end if;

      return Read_Name (Work, Work'First, True);
   end Leading_Name;

end Editor.Ada_Declaration_Parser.Executable_Binding_Text_Helpers;
