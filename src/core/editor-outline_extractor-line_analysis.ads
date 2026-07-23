with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Outline;

package Editor.Outline_Extractor.Line_Analysis is

   function First_Non_Blank_Column (Line : String) return Natural;

   function Trim_Code_Whitespace (Line : String) return String;

   function Tabs_As_Spaces (Text : String) return String;

   function Starts_With
     (Text   : String;
      Prefix : String) return Boolean;

   function Ends_With
     (Text   : String;
      Suffix : String) return Boolean;

   function Kind_For_Label
     (Label : String) return Editor.Outline.Outline_Item_Kind;

   function Has_File_Extension (Text : String) return Boolean;

   function Is_Word_Char (C : Character) return Boolean;

   function Starts_With_Word
     (Lower_Line : String;
      Word       : String) return Boolean;

   function Starts_With_Keyword
     (Lower_Line : String;
      Keyword    : String) return Boolean;

   function Starts_With_Phrase
     (Lower_Line : String;
      Phrase     : String) return Boolean;

   function Declaration_Target_Column (Line : String) return Natural;

   function Looks_Like_Record_Field_Line (Lower_Line : String) return Boolean;

   function Record_Field_Name (Line : String) return String;

   procedure Append_Record_Field_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      In_Record_Type : Boolean;
      Depth       : Natural;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String);

   function First_Colon (Line : String) return Natural;

   function Declaration_Name_List_Before_Colon (Line : String) return String;

   function Generic_Formal_Prefix (Lower_Line : String) return String;

   function Generic_Formal_Name (Trimmed : String; Lower_Line : String) return String;

   procedure Append_Generic_Formal_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Depth       : Natural;
      Raw_Line    : String;
      Line_Number : Positive;
      Lower_Line  : String;
      Trimmed     : String);

   function Looks_Like_Exception_Declaration (Lower_Line : String) return Boolean;

   function Looks_Like_Constant_Declaration (Lower_Line : String) return Boolean;

   function Looks_Like_Object_Declaration (Lower_Line : String) return Boolean;

   function First_Enumeration_List_Column (Line : String) return Natural;

   procedure Append_Discriminants_From_Type_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural);

   procedure Append_Enumeration_Literals_From_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive;
      Depth       : Natural;
      Start_At    : Natural);

   procedure Append_Marker_Source_Line
     (Result      : in out Editor.Outline_Extractor.Extraction_Result;
      Raw_Line    : String;
      Line_Number : Positive);

   procedure Append_Marker_Lines
     (Result : in out Editor.Outline_Extractor.Extraction_Result;
      Text   : String);

   function Looks_Like_Ada_Line (Trimmed : String) return Boolean;

   function Looks_Like_Ada_Buffer
     (Text         : String;
      Buffer_Label : String) return Boolean;

   function Is_Name_Character
     (C         : Character;
      Allow_Dot : Boolean) return Boolean;

   function Read_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean) return String;

   function Read_Function_Name
     (Text      : String;
      Start     : Positive;
      Allow_Dot : Boolean) return String;

   function Has_Code_Character
     (Lower_Line : String;
      Target     : Character) return Boolean;

   function Has_Token
     (Lower_Line : String;
      Token      : String) return Boolean;

   function Has_Token_Is (Lower_Line : String) return Boolean;

   function Has_Is_Followed_By
     (Lower_Line : String;
      Token      : String) return Boolean;

   function Has_Renames (Lower_Line : String) return Boolean;

   function Has_Is_Followed_By_Open_Paren
     (Lower_Line : String) return Boolean;

   function Looks_Like_Expression_Function (Lower_Line : String) return Boolean;

   function Looks_Like_Enumeration_Type_Line
     (Lower_Line : String) return Boolean;

   function Declaration_Header_Ends (Lower_Line : String) return Boolean;

   function Header_Starts_With_Function (Header : String) return Boolean;

   function Header_Starts_With_Procedure (Header : String) return Boolean;

   function Header_Is_Subprogram_Body (Header : String) return Boolean;

   function Is_Code_Line_Open (Lower_Line : String) return Boolean;

   function Open_Line_Needs_Body_Begin (Lower_Line : String) return Boolean;

   function Declaration_Header_Starts_Construct
     (Lower_Line : String) return Boolean;

   function Header_Start_Needs_Body_Begin
     (Lower_Line : String) return Boolean;

   function Is_Code_Line_Inline_Balanced_Open
     (Lower_Line : String) return Boolean;

   function Declaration_Waits_For_Record_End
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean;

   function Declaration_Waits_For_Instantiation_End
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean;

   function Pending_Declaration_Ends_With_Is (Lower_Line : String) return Boolean;

   function Declaration_Could_Be_Split_Instantiation
     (Lower_Line : String;
      Kind       : Editor.Outline.Outline_Item_Kind) return Boolean;

   function Line_Ends_Record (Lower_Line : String) return Boolean;

   function Pending_Type_Record_Still_Open
     (Combined_Lower : String;
      Lower_Line     : String;
      Pending_Kind   : Editor.Outline.Outline_Item_Kind) return Boolean;

   function Declaration_Opens_Block (Lower_Line : String) return Boolean;

   function Is_Generic_Formal_Line (Lower_Line : String) return Boolean;

   function Strip_Overriding_Prefix (Line : String) return String;

   function Strip_Abstract_Prefix (Line : String) return String;

   function Strip_Private_Package_Prefix (Line : String) return String;

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

end Editor.Outline_Extractor.Line_Analysis;
