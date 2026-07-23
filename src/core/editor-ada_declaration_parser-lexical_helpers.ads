package Editor.Ada_Declaration_Parser.Lexical_Helpers is

   function Is_Name_Start (C : Character) return Boolean;
   function Is_Name_Char (C : Character) return Boolean;
   function Is_Static_Space (C : Character) return Boolean;
   procedure Skip_Blanks (Text : String; Pos : in out Natural);
   function Normalize_Character_Pos_Static_Operands
     (Text : String) return String;
   function Normalize_Static_Attribute_Spacing
     (Text : String) return String;
   function Starts_At_Word
     (Text  : String;
      Pos   : Natural;
      Word  : String) return Boolean;
   function Word_At
     (Text  : String;
      Pos   : Natural;
      Word  : String) return Boolean;
   function Next_Non_Blank
     (Text  : String;
      From  : Natural) return Natural;
   function Segment_Before (Text, Marker : String) return String;
   function Segment_After (Text, Marker : String) return String;
   function Is_Declaration_Or_Metadata_Line (Line : String) return Boolean;
   function Is_Executable_Scan_Keyword (Name : String) return Boolean;
   function Is_Executable_Declaration_Line
     (LWork : String) return Boolean;
   function Starts_With_Subprogram_Keyword (Text : String) return Boolean;
   function Has_Null_Exclusion (Line : String) return Boolean;
   function Has_Code_Char (Line : String; C : Character) return Boolean;
   function Declaration_Colon_Position (Line : String) return Natural;
   function Has_Declaration_Colon (Line : String) return Boolean;
   function Has_Token (Line, Token : String) return Boolean;
   function Token_Source_Position (Line, Token : String) return Natural;
   function Has_Token_Pair
     (Line, First_Token, Second_Token : String) return Boolean;
   function Has_Object_Constant_Qualifier (Line : String) return Boolean;

end Editor.Ada_Declaration_Parser.Lexical_Helpers;
