package Editor.Ada_Declaration_Parser.Representation_Static_Values is

   type Parse_Dimension_Function is access function
     (Pos   : in out Natural;
      Value : out Integer) return Boolean;

   type Static_String_Bound_Value_Function is access function
     (Prefix_Text : String;
      Attr_Name   : String;
      Bound_Value : out Natural) return Boolean;

   procedure Parse_Static_Natural
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural);

   function Parse_Underscored_Natural
     (Text  : String;
      Value : out Natural) return Boolean;

   function Parse_Static_Unsigned_Numeric_Literal
     (Text  : String;
      Value : out Natural) return Boolean;

   function Natural_In_Integer_Range
     (Value    : Natural;
      Has_Low  : Boolean;
      Low      : Integer;
      Has_High : Boolean;
      High     : Integer) return Boolean;

   function Strip_Constant_Subtype_Prefix (Subtype_Text : String) return String;

   function Parse_Static_String_Bound_Primary
     (Text                      : String;
      Pos                       : in out Natural;
      Result                    : out Natural;
      Parse_Dimension           : not null Parse_Dimension_Function;
      Static_String_Bound_Value :
        not null Static_String_Bound_Value_Function) return Boolean;

end Editor.Ada_Declaration_Parser.Representation_Static_Values;
