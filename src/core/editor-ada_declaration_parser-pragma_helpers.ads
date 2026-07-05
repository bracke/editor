package Editor.Ada_Declaration_Parser.Pragma_Helpers is

   function Matching_Pragma_Close_Pos
     (Line : String; Open_Pos : Natural) return Natural;

   function Is_Pragma_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean;

   function Pragma_Code_Preserving_Literals (Line : String) return String;
   function Pragma_Target (Line : String) return String;
   function Pragma_Name_Of (Line : String) return String;
   function Pragma_Argument_Count (Line : String) return Natural;
   function Pragma_Argument (Line : String; Index : Positive) return String;
   function Top_Level_Pragma_Association_Arrow (Arg : String) return Natural;
   function Pragma_Argument_Name (Arg : String) return String;
   function Pragma_Argument_Value (Arg : String) return String;
   function Named_Pragma_Argument (Line, Name : String) return String;

   function Interfacing_Pragma_Value
     (Line                : String;
      Name                : String;
      Positional_Fallback : Positive) return String;

end Editor.Ada_Declaration_Parser.Pragma_Helpers;
