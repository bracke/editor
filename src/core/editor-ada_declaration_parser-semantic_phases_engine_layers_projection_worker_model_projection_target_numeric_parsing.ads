package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing is

   type String_To_String is access function (Text : String) return String;
   type Natural_Query is access function
     (Name  : String;
      Value : out Natural) return Boolean;
   type Integer_Query is access function
     (Name  : String;
      Value : out Integer) return Boolean;
   type Static_String_Bound_Query is access function
     (Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean;
   type Static_Discrete_Position_Query is access function
     (Type_Name    : String;
      Default_Text : String;
      Position     : out Natural) return Boolean;
   type Static_Type_Range_Query is access function
     (Name     : String;
      Has_Low  : out Boolean;
      Low      : out Integer;
      Has_High : out Boolean;
      High     : out Integer) return Boolean;
   type Static_Value_Range_Query is access function
     (Type_Name : String;
      Value     : Natural) return Boolean;
   type Static_Integer_Value_Query is access function
     (Type_Name   : String;
      String_Text : String;
      Value       : out Integer) return Boolean;
   type Static_Attribute_Value_Query is access function
     (Name      : String;
      Attr_Name : String;
      Value     : out Natural) return Boolean;

   type Operations is record
      Clean_Metadata_Name : not null String_To_String;
      Static_String_Bound_Value : not null Static_String_Bound_Query;
      Static_Discrete_Default_Position : not null Static_Discrete_Position_Query;
      Static_Discrete_Literal_Position : not null Static_Discrete_Position_Query;
      Static_Discrete_Constant_Position : not null Static_Discrete_Position_Query;
      Static_Value_In_Type_Range : not null Static_Value_Range_Query;
      Static_Discrete_Value_String_Position : not null Static_Discrete_Position_Query;
      Static_Integer_Value_String_Value : not null Static_Integer_Value_Query;
      Static_Type_Range : not null Static_Type_Range_Query;
      Static_Type_Modulus : not null Natural_Query;
      Static_Type_Width : not null Natural_Query;
      Static_Attribute_Value : not null Static_Attribute_Value_Query;
      Static_Named_Number_Value : not null Natural_Query;
      Static_Integer_Name_Value : not null Integer_Query;
      Static_String_Subtype_Bound_Value : not null Static_String_Bound_Query;
      Static_String_Constant_Bound_Value : not null Static_String_Bound_Query;
      Static_Subtype_Root : not null String_To_String;
   end record;

   procedure Parse_Static_Natural
     (Ops   : Operations;
      Text  : String;
      Valid : out Boolean;
      Value : out Natural);

   procedure Parse_Static_Integer
     (Ops   : Operations;
      Text  : String;
      Valid : out Boolean;
      Value : out Integer);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Numeric_Parsing;
