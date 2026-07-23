with Ada.Strings.Unbounded;
with Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation is

   package Phase_Types renames
     Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;

   type Context (Node_Capacity : Positive) is record
      Static                   : Phase_Types.Static_Projection_Context;
      Static_Declaration_Infos : Phase_Types.Static_Declaration_Info_Table (1 .. Node_Capacity);
      Static_Declaration_Count : Natural := 0;
      Static_Metadata_Applied  : Boolean := False;
   end record;

   type String_Query is access function (Text : String) return Boolean;
   type String_String_Query is access function
     (Left  : String;
      Right : String) return Boolean;
   type String_To_String is access function (Text : String) return String;
   type String_Procedure is access procedure (Text : String);
   type String_String_Procedure is access procedure
     (Left  : String;
      Right : String);
   type String_String_String_Procedure is access procedure
     (First  : String;
      Second : String;
      Third  : String);
   type Static_Natural_Parser is access procedure
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural);
   type Static_Integer_Parser is access procedure
     (Text  : String;
      Valid : out Boolean;
      Value : out Integer);
   type Static_Discrete_Position_Query is access function
     (Type_Name    : String;
      Default_Text : String;
      Position     : out Natural) return Boolean;
   type Static_String_Default_Query is access function
     (Default_Text : String;
      Image_Text   : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;
   type Static_String_Bound_Query is access function
     (Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean;

   type Operations is record
      Is_Static_Numeric_Value : not null String_Query;
      Parse_Static_Natural : not null Static_Natural_Parser;
      Parse_Static_Integer : not null Static_Integer_Parser;
      Static_Constant_Default_Compatible : not null String_String_Query;
      Static_Discrete_Default_Position : not null Static_Discrete_Position_Query;
      Is_Simple_Static_Type_Name : not null String_Query;
      Normalize_Character_Pos_Static_Operands : not null String_To_String;
      Static_String_Default_Value : not null Static_String_Default_Query;
      Static_String_Bound_Value : not null Static_String_Bound_Query;
   end record;

   procedure Run
     (Phase                  : in out Context;
      Declaration_Is_Complete : Boolean;
      Tree                   : Editor.Ada_Syntax_Tree.Tree_Type;
      Source_Text            : String;
      Actions                : Operations);

   function Static_Numeric_Name_Exists
     (Phase : Context;
      Name  : String) return Boolean;

   procedure Register_Static_Numeric_Name
     (Phase : in out Context;
      Name  : String);

   function Static_Named_Number_Value
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean;

   function Static_Integer_Name_Value
     (Phase : Context;
      Name  : String;
      Value : out Integer) return Boolean;

   procedure Register_Static_Named_Number
     (Phase                   : in out Context;
      Name                    : String;
      Text                    : String;
      Parse_Static_Natural    : not null Static_Natural_Parser;
      Parse_Static_Integer    : not null Static_Integer_Parser;
      Is_Static_Numeric_Value : not null String_Query);

   function Canonical_Static_Type_Name (Name : String) return String;

   procedure Store_Static_Subtype_Alias
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String);

   function Static_Subtype_Root
     (Phase : Context;
      Name  : String) return String;

   procedure Store_Static_Type_Range
     (Phase      : in out Context;
      Name       : String;
      Low_Value  : Integer;
      High_Value : Integer;
      Is_Modular : Boolean := False);

   procedure Register_Static_Type_Range_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String);

   function Static_Type_Range
     (Phase    : Context;
      Name     : String;
      Has_Low  : out Boolean;
      Low      : out Integer;
      Has_High : out Boolean;
      High     : out Integer) return Boolean;

   function Static_Value_In_Type_Range
     (Phase     : Context;
      Type_Name : String;
      Value     : Natural) return Boolean;

   function Static_Type_Is_Modular
     (Phase : Context;
      Name  : String) return Boolean;

   function Static_Type_Modulus
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean;

   function Static_Type_Is_Character
     (Phase : Context;
      Name  : String) return Boolean;

   procedure Register_Static_Character_Type
     (Phase : in out Context;
      Name  : String);

   procedure Register_Static_Enumeration_Literal
     (Phase        : in out Context;
      Type_Name    : String;
      Literal_Name : String;
      Position     : Natural);

   procedure Register_Static_Enumeration_Type
     (Phase        : in out Context;
      Name         : String;
      Subtype_Text : String);

   procedure Register_Static_Discrete_Literals_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String);

   function Static_Enumeration_Literal_Position
     (Phase        : Context;
      Type_Name    : String;
      Literal_Name : String;
      Position     : out Natural) return Boolean;

   function Static_Enumeration_Position_Image
     (Phase      : Context;
      Type_Name  : String;
      Position   : Natural;
      Image_Text : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Static_Discrete_Constant_Position
     (Phase     : Context;
      Type_Name : String;
      Name      : String;
      Position  : out Natural) return Boolean;

   function Static_Character_Constant_Position
     (Phase    : Context;
      Name     : String;
      Position : out Natural) return Boolean;

   procedure Register_Static_Discrete_Constant
     (Phase                            : in out Context;
      Name                             : String;
      Type_Name                        : String;
      Default_Text                     : String;
      Static_Discrete_Default_Position : not null Static_Discrete_Position_Query);

   procedure Store_Static_String_Subtype_Bounds_Values
     (Phase      : in out Context;
      Name       : String;
      First      : Integer;
      Last       : Integer);

   procedure Copy_Static_String_Subtype_Bounds_From_Base
     (Phase     : in out Context;
      Name      : String;
      Base_Name : String);

   function Static_String_Subtype_Length_Compatible
     (Phase      : Context;
      Type_Name  : String;
      Image_Text : Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Static_String_Subtype_Bound_Value
     (Phase     : Context;
      Type_Name : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean;

   function Static_String_Subtype_Bounds
     (Phase     : Context;
      Type_Name : String;
      First     : out Integer;
      Last      : out Integer) return Boolean;

   function Static_String_Constant_Value
     (Phase      : Context;
      Name       : String;
      Image_Text : out Ada.Strings.Unbounded.Unbounded_String) return Boolean;

   function Static_String_Constant_Bound_Value
     (Phase     : Context;
      Name      : String;
      Attr_Name : String;
      Bound     : out Natural) return Boolean;

   function Static_String_Constant_Range
     (Phase : Context;
      Name  : String;
      First : out Natural;
      Last  : out Natural) return Boolean;

   procedure Store_Static_String_Constant
     (Phase      : in out Context;
      Name       : String;
      Image_Text : Ada.Strings.Unbounded.Unbounded_String;
      Has_First  : Boolean;
      First      : Natural;
      Has_Last   : Boolean;
      Last       : Natural);

   function Static_Type_Width
     (Phase : Context;
      Name  : String;
      Value : out Natural) return Boolean;

   function Static_Attribute_Value
     (Phase     : Context;
      Name      : String;
      Attribute : String;
      Value     : out Natural) return Boolean;

   procedure Register_Static_Attribute_Value
     (Phase     : in out Context;
      Name      : String;
      Attribute : String;
      Value     : Natural);

   procedure Register_Static_Representation_Attribute_Value
     (Phase     : in out Context;
      Name      : String;
      Attribute : String;
      Value     : Natural);

   function Static_Metadata_Is_Applied (Phase : Context) return Boolean;

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Target_Derivation;
