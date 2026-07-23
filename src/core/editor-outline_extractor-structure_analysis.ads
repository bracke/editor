with Editor.Outline;

package Editor.Outline_Extractor.Structure_Analysis is

   function Form_Needs_Body_Begin (Form : String) return Boolean;

   function Last_Label_Word (Label : String) return String;

   function Lowercase_Text (Text : String) return String;

   function Closing_Line_Name (Lower_Line : String) return String;

   function Closing_Line_Qualifier (Lower_Line : String) return String;

   function Root_End_Matches
     (Lower_Line             : String;
      Expected_Lowercase     : String;
      Expected_Close_Keyword : String := "") return Boolean;

   function Expected_End_Keyword
     (Item : Editor.Outline.Outline_Item;
      Form : String) return String;

   function Is_Structure_End_Keyword (Name : String) return Boolean;

   function Structure_Close_Keyword_For_Open (Lower_Line : String) return String;

   function Structure_Name_For_Open (Lower_Line : String) return String;

   function Stack_End_Matches
     (Lower_Line             : String;
      Expected_Close_Keyword : String;
      Expected_Name          : String) return Boolean;

   function Is_Code_Line_Close (Lower_Line : String) return Boolean;

   function Item_May_Have_Structure_Range
     (Item : Editor.Outline.Outline_Item) return Boolean;

end Editor.Outline_Extractor.Structure_Analysis;
