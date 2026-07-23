with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Legality_Profile_Helpers is

   function First_Paren_Segment (Text : String) return String;

   function Last_Selected_Name_Part (Name : String) return String;

   function Formal_Count (Profile : String) return Natural;

   function Formal_Text
     (Profile : String;
      Index   : Positive) return String;

   function Second_Formal_Text (Profile : String) return String;

   function Formal_Declaration_After_Colon (Formal : String) return String;

   function Strip_Default_Expression (Text : String) return String;

   function Strip_Leading_Formal_Keyword
     (Text    : String;
      Keyword : String) return String;

   function Formal_Subtype_Mark (Formal : String) return String;

   function Is_Stream_Formal (Formal : String) return Boolean;

   function Has_Stream_Formal (Profile : String) return Boolean;

   function Has_Return_Profile (Profile : String) return Boolean;

   function Local_Ends_With (Text, Suffix : String) return Boolean;

   function Return_Profile_Matches_Target
     (Profile     : String;
      Target_Name : String) return Boolean;

   function Subtype_Mark_Matches_Target
     (Subtype_Mark : String;
      Target_Name  : String) return Boolean;

   function Stream_Handler_Profile_Is_Compatible
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name    : String;
      Profile        : String) return Boolean;

   function Stream_Handler_Mode_Is_Compatible
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Profile        : String) return Boolean;

end Editor.Ada_Declaration_Parser.Legality_Profile_Helpers;
