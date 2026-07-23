with Ada.Strings.Unbounded;
with Editor.Ada_Language_Model;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Declaration_Parser.Static_Attribute_Registry;

package Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types is

   use Ada.Strings.Unbounded;
   use Editor.Ada_Language_Model;

   type Node_Symbol_Map is array (Positive range <>) of Symbol_Id;

   Max_Static_Named_Numbers : constant Positive := 512;
   type Static_Named_Number_Info is record
      Normalized_Name   : Unbounded_String;
      Has_Natural_Value : Boolean := False;
      Value             : Natural := 0;
      Has_Signed_Value  : Boolean := False;
      Signed_Value      : Integer := 0;
   end record;
   type Static_Named_Number_Table is
     array (Positive range 1 .. Max_Static_Named_Numbers) of Static_Named_Number_Info;

   Max_Static_Numeric_Names : constant Positive := 512;
   type Static_Numeric_Name_Table is
     array (Positive range 1 .. Max_Static_Numeric_Names) of Unbounded_String;

   Max_Static_Type_Ranges : constant Positive := 256;
   type Static_Type_Range_Info is record
      Normalized_Name : Unbounded_String;
      Has_Low         : Boolean := False;
      Low             : Integer := 0;
      Has_High        : Boolean := False;
      High            : Integer := 0;
      Is_Modular      : Boolean := False;
   end record;
   type Static_Type_Range_Table is
     array (Positive range 1 .. Max_Static_Type_Ranges) of Static_Type_Range_Info;

   Max_Static_Character_Types : constant Positive := 256;
   type Static_Character_Type_Table is
     array (Positive range 1 .. Max_Static_Character_Types) of Unbounded_String;

   Max_Static_Enumeration_Literals : constant Positive := 1024;
   type Static_Enumeration_Literal_Info is record
      Normalized_Type_Name    : Unbounded_String;
      Normalized_Literal_Name : Unbounded_String;
      Position                : Natural := 0;
   end record;
   type Static_Enumeration_Literal_Table is
     array (Positive range 1 .. Max_Static_Enumeration_Literals)
       of Static_Enumeration_Literal_Info;

   Max_Static_Discrete_Constants : constant Positive := 256;
   type Static_Discrete_Constant_Info is record
      Normalized_Name      : Unbounded_String;
      Normalized_Type_Name : Unbounded_String;
      Position             : Natural := 0;
   end record;
   type Static_Discrete_Constant_Table is
     array (Positive range 1 .. Max_Static_Discrete_Constants)
       of Static_Discrete_Constant_Info;

   Max_Static_String_Constants : constant Positive := 256;
   type Static_String_Constant_Info is record
      Normalized_Name : Unbounded_String;
      Image_Text      : Unbounded_String;
      Has_First       : Boolean := False;
      First           : Natural := 1;
      Has_Last        : Boolean := False;
      Last            : Natural := 0;
   end record;
   type Static_String_Constant_Table is
     array (Positive range 1 .. Max_Static_String_Constants)
       of Static_String_Constant_Info;

   Max_Static_String_Subtype_Bounds : constant Positive := 256;
   type Static_String_Subtype_Bound_Info is record
      Normalized_Name : Unbounded_String;
      Has_First       : Boolean := False;
      First           : Integer := 1;
      Has_Last        : Boolean := False;
      Last            : Integer := 0;
   end record;
   type Static_String_Subtype_Bound_Table is
     array (Positive range 1 .. Max_Static_String_Subtype_Bounds)
       of Static_String_Subtype_Bound_Info;

   Max_Static_Subtype_Aliases : constant Positive := 256;
   type Static_Subtype_Alias_Info is record
      Normalized_Name : Unbounded_String;
      Normalized_Base : Unbounded_String;
   end record;
   type Static_Subtype_Alias_Table is
     array (Positive range 1 .. Max_Static_Subtype_Aliases)
       of Static_Subtype_Alias_Info;

   type Static_Projection_Context is record
      Named_Numbers         : Static_Named_Number_Table;
      Named_Number_Count    : Natural := 0;
      Numeric_Names         : Static_Numeric_Name_Table;
      Numeric_Name_Count    : Natural := 0;
      Type_Ranges           : Static_Type_Range_Table;
      Type_Range_Count      : Natural := 0;
      Character_Types       : Static_Character_Type_Table;
      Character_Type_Count  : Natural := 0;
      Enumeration_Literals  : Static_Enumeration_Literal_Table;
      Enumeration_Literal_Count : Natural := 0;
      Discrete_Constants    : Static_Discrete_Constant_Table;
      Discrete_Constant_Count : Natural := 0;
      String_Constants      : Static_String_Constant_Table;
      String_Constant_Count  : Natural := 0;
      String_Subtype_Bounds  : Static_String_Subtype_Bound_Table;
      String_Subtype_Bound_Count : Natural := 0;
      Subtype_Aliases       : Static_Subtype_Alias_Table;
      Subtype_Alias_Count    : Natural := 0;
      Attributes            : Static_Attribute_Registry.Registry;
   end record;

   type Metadata_Fact_Info is record
      Kind                       : Editor.Ada_Syntax_Tree.Node_Kind;
      Node                       : Editor.Ada_Syntax_Tree.Node_Info;
      Node_Ref                   : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Owner                      : Symbol_Id := No_Symbol;
      Source_Span                : Editor.Ada_Syntax_Tree.Source_Range;
      Label_Text                 : Unbounded_String;
      Named_Aspect               : Unbounded_String;
      Value_Child                : Unbounded_String;
      Generic_Formal             : Unbounded_String;
      Generic_Actual             : Unbounded_String;
      Has_Generic_Association_Children : Boolean := False;
      Representation_Target_Text : Unbounded_String;
      Representation_Target_Id   : Symbol_Id := No_Symbol;
      Pragma_Name                : Unbounded_String;
      Pragma_Placement           : Pragma_Placement_Kind := Pragma_Placement_Kind'First;
      Pragma_Target_Name         : Unbounded_String;
      Pragma_Argument_Count      : Natural := 0;
      Pragma_Named_Argument_Count : Natural := 0;
   end record;
   type Metadata_Fact_Table is array (Positive range <>) of Metadata_Fact_Info;

   type Static_Declaration_Info is record
      Kind         : Editor.Ada_Syntax_Tree.Node_Kind;
      Name         : Unbounded_String;
      Subtype_Text : Unbounded_String;
      Default_Text : Unbounded_String;
   end record;
   type Static_Declaration_Info_Table is
     array (Positive range <>) of Static_Declaration_Info;

   procedure Require_Phase
     (Ready : Boolean;
      Name  : String);

end Editor.Ada_Declaration_Parser.Semantic_Phases_Engine_Layers_Projection_Worker_Model_Projection_Phase_Types;
