with Ada.Strings.Unbounded;
with Editor.Outline;
with Editor.Outline_Extractor;

package Editor.Outline_Extractor.Line_Analysis.Structure_Labels is

   function Leading_Block_Label (Line : String) return String;

   function Strip_Leading_Block_Label (Line : String) return String;

   function Normalize_Structure_Line (Lower_Line : String) return String;

   function Declaration_Form
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return String;

   function Line_Closes_Block (Lower_Line : String) return Boolean;

   function Detail_Text
     (Line_Number : Positive;
      Form        : String) return String;

   function Label_Text
     (Prefix : String;
      Name   : String;
      Form   : String) return String;

   procedure Append_Item
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Kind        : Editor.Outline.Outline_Item_Kind;
      Prefix      : String;
      Name        : String;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Form        : String := "");

   procedure Update_Item_Form
     (Result : in out Editor.Outline_Extractor.Extraction_Result;
      Index  : Natural;
      Form   : String);

   function Append_Marker_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive) return Boolean;

end Editor.Outline_Extractor.Line_Analysis.Structure_Labels;
