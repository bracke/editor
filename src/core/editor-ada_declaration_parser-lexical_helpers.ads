package Editor.Ada_Declaration_Parser.Lexical_Helpers is

   function Lower (S : String) return String;
   function Trim (S : String) return String;
   function Is_Word_Char (C : Character) return Boolean;
   function Is_Static_Space (C : Character) return Boolean;
   function Trim_Static_Space (Text : String) return String;
   function Normalize_Character_Pos_Static_Operands
     (Text : String) return String;
   function Normalize_Static_Attribute_Spacing
     (Text : String) return String;
   function Starts_With (Text, Prefix : String) return Boolean;
   function Starts_With_Word (Text, Word : String) return Boolean;
   function Segment_Before (Text, Marker : String) return String;
   function Segment_After (Text, Marker : String) return String;
   function Contains (Text, Fragment : String) return Boolean;
   function Ends_With (Text, Suffix : String) return Boolean;
   function Has_Null_Exclusion (Line : String) return Boolean;
   function Has_Token (Line, Token : String) return Boolean;
   function Token_Source_Position (Line, Token : String) return Natural;
   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
