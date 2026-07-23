package Editor.Outline_Extractor.Detail_Parsing is

   function Numeric_Suffix (Text : String; Start : Positive) return Natural;

   function Detail_Start_Line (Detail : String) return Natural;

   function Detail_End_Line (Detail : String) return Natural;

   function End_Line_Detail
     (Start_Line : Natural;
      End_Line   : Natural;
      Form       : String) return String;

   function Detail_Form (Detail : String) return String;

   function Primary_Detail_Form (Detail : String) return String;

end Editor.Outline_Extractor.Detail_Parsing;
