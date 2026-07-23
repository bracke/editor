with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;

package Editor.Ada_Declaration_Parser.Attribute_Value_Helpers is

   function Is_Stream_Operational_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Stream_Input_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Operational_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Interfacing_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Link_Name_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Import_Export_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Convention_Attribute
     (Name : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Is_Convention_Identifier (Text : String) return Boolean;

   function Is_Static_Boolean_Value (Text : String) return Boolean;

   function Is_Static_True_Value (Text : String) return Boolean;

   function Is_Static_False_Value (Text : String) return Boolean;

   function Is_Known_Convention_Identifier (Text : String) return Boolean;

   type Numeric_Name_Predicate is access function (Name : String) return Boolean;

   function Has_Static_Numeric_Tokens
     (Text                  : String;
      Is_Known_Numeric_Name : not null Numeric_Name_Predicate) return Boolean;

   function Is_Static_String_Literal (Text : String) return Boolean;

   function Is_Raw_Numeric_Literal (Text : String) return Boolean;

   function Is_Static_Numeric_Value (Text : String) return Boolean;

   function Is_Positive_Static_Natural_Value (Text : String) return Boolean;

   function Is_Storage_Pool_Value (Text : String) return Boolean;

   function Is_Address_Null_Value (Text : String) return Boolean;

   function Is_Address_Attribute_Reference (Text : String) return Boolean;

   function Is_Address_Conversion_Call (Text : String) return Boolean;

   function Is_Address_Name_Reference (Text : String) return Boolean;

   function Is_Address_Compatible_Expression (Text : String) return Boolean;

   function Is_Interfacing_Attribute_Target
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Kind           : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

   function Operational_Handler_Name (Text : String) return String;

  function Operational_Handler_Is_Compatible
     (Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Handler_Kind   : Editor.Ada_Language_Model.Symbol_Kind) return Boolean;

end Editor.Ada_Declaration_Parser.Attribute_Value_Helpers;
