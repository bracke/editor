with Editor.Outline_Extractor.Detail_Parsing;

package Editor.Outline_Extractor.Range_Analysis is

   procedure Remove_Object_Field_Duplicates
     (Result : in out Extraction_Result);

   procedure Normalize_Generic_Depths_From_Ranges
     (Result : in out Extraction_Result);

   procedure Normalize_Ranged_Child_Depths
     (Result : in out Extraction_Result);

   procedure Normalize_Depths_To_Nearest_Range
     (Result : in out Extraction_Result);

   procedure Normalize_Same_Line_Enum_Literal_Depths
     (Result : in out Extraction_Result);

end Editor.Outline_Extractor.Range_Analysis;
