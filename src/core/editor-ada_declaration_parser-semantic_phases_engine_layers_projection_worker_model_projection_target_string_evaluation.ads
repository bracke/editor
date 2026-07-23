with Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation is

   package Target_Derivation renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;

   type Static_Discrete_Image_Query is access function
     (Type_Name  : String;
      Position   : Natural;
      Image_Text : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;
   type Static_Discrete_Literal_Query is access function
     (Type_Name    : String;
      Literal_Text : String;
      Position     : out Natural) return Boolean;

   function Static_String_Bound_Value
     (Phase                       : Target_Derivation.Context;
      Name                        : String;
      Attr_Name                   : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Bound                       : out Natural) return Boolean;

   function Static_String_Element_Position
     (Phase                       : Target_Derivation.Context;
      Indexed_Text                : String;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value   : not null Target_Derivation.Static_String_Bound_Query;
      Position                    : out Natural) return Boolean;

   function Static_String_Slice_Value
     (Phase                       : Target_Derivation.Context;
      Slice_Text                  : String;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Static_String_Bound_Value   : not null Target_Derivation.Static_String_Bound_Query;
      Image_Text                  : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Static_String_Default_Value
     (Phase                            : Target_Derivation.Context;
      Default_Text                     : String;
      Parse_Static_Integer             : not null Target_Derivation.Static_Integer_Parser;
      Static_Discrete_Default_Position : not null Target_Derivation.Static_Discrete_Position_Query;
      Static_Discrete_Position_Image   : not null Static_Discrete_Image_Query;
      Image_Text                       : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Static_Discrete_Value_String_Position
     (Phase                            : Target_Derivation.Context;
      Type_Name                        : String;
      String_Text                      : String;
      Static_String_Default_Value      : not null Target_Derivation.Static_String_Default_Query;
      Static_Discrete_Literal_Position : not null Static_Discrete_Literal_Query;
      Static_Discrete_Default_Position : not null Target_Derivation.Static_Discrete_Position_Query;
      Position                         : out Natural) return Boolean;

   function Static_Integer_Value_String_Value
     (Phase                       : Target_Derivation.Context;
      Type_Name                   : String;
      String_Text                 : String;
      Static_String_Default_Value : not null Target_Derivation.Static_String_Default_Query;
      Parse_Static_Integer        : not null Target_Derivation.Static_Integer_Parser;
      Value                       : out Integer) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_String_Evaluation;
