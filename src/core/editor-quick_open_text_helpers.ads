package Editor.Quick_Open_Text_Helpers is

   function Normalize_For_Compare (Text : String) return String;

   function Base_Name (Path : String) return String;

   function Extension_Of (Path : String) return String;

   function Is_Ada_File (Path : String) return Boolean;

   function Is_Doc_File (Path : String) return Boolean;

   function Is_Test_File (Path : String) return Boolean;

   function In_Path_Scope (Path, Scope : String) return Boolean;

   function Is_Term_Boundary (Ch : Character) return Boolean;

   function Has_Whitespace (Text : String) return Boolean;

   function Ordered_Characters_Match
     (Pattern : String;
      Text    : String) return Boolean;

   function Ordered_Basename_Fuzzy_Match
     (Pattern : String;
      Text    : String) return Boolean;

   function Ordered_Terms_Match
     (Query       : String;
      Path        : String;
      Prefix_Only : Boolean) return Boolean;

   function Segment_Contains
     (Path : String;
      Term : String;
      Prefix_Only : Boolean) return Boolean;

end Editor.Quick_Open_Text_Helpers;
