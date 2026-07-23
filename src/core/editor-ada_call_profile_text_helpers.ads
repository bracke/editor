with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Expression_Types.Status_Helpers;

package Editor.Ada_Call_Profile_Text_Helpers is

   function Trim (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Ada_Expression_Types.Status_Helpers.Normalize;

   function Contains (Text : String; Pattern : String) return Boolean
     renames Editor.Ada_Expression_Types.Status_Helpers.Contains;

   function Is_Name_Char (C : Character) return Boolean
     renames Editor.Ada_Declaration_Parser.Lexical_Helpers.Is_Name_Char;

   function Hash_Text (Text : String) return Natural;

   function Clean_Call_Name (Text : String) return String;

end Editor.Ada_Call_Profile_Text_Helpers;
