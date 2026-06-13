with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Static_Expressions is

   --  Compiler-grade static-expression staging layer.  This package evaluates
   --  a deliberately small, deterministic Ada static-expression subset from a
   --  parser-owned snapshot: integer and real literals, named-number/static-constant
   --  references, fixed-point delta/range metadata, parentheses, unary +/- and
   --  numeric operators +, -, *, /; integer-only contexts additionally stage rem and mod.  Unsupported constructs remain non-static or unresolved so
   --  later legality passes can produce precise diagnostics without cascading.

   type Static_Value_Status is
     (Static_Value_Not_Checked,
      Static_Value_Integer,
      Static_Value_Real,
      Static_Value_Unresolved_Name,
      Static_Value_Non_Static,
      Static_Value_Malformed,
      Static_Value_Division_By_Zero,
      Static_Value_Cycle,
      Static_Value_Static_Attribute,
      Static_Value_Enumeration_Literal,
      Static_Value_Modular_Integer,
      Static_Value_Modular_Overflow,
      Static_Value_Fixed_Point,
      Static_Value_Fixed_Delta_Mismatch,
      Static_Value_Fixed_Range_Error,
      Static_Value_Unsupported_Attribute);

   type Static_Value_Info is record
      Status              : Static_Value_Status := Static_Value_Not_Checked;
      Integer_Value       : Long_Long_Integer := 0;
      Real_Value          : Long_Float := 0.0;
      Expression_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Text     : Ada.Strings.Unbounded.Unbounded_String;
      Referenced_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Prefix   : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Literal_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Literal_Position   : Long_Long_Integer := 0;
      Modular_Type_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Modulus_Value      : Long_Long_Integer := 0;
      Fixed_Type_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Delta_Value        : Long_Float := 0.0;
      Fingerprint         : Natural := 0;
   end record;


   type Static_Fixed_Type_Id is new Natural;
   No_Static_Fixed_Type : constant Static_Fixed_Type_Id := 0;

   type Static_Fixed_Type_Info is record
      Id                    : Static_Fixed_Type_Id := No_Static_Fixed_Type;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region                : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Delta_Text            : Ada.Strings.Unbounded.Unbounded_String;
      Digits_Text           : Ada.Strings.Unbounded.Unbounded_String;
      First_Text            : Ada.Strings.Unbounded.Unbounded_String;
      Last_Text             : Ada.Strings.Unbounded.Unbounded_String;
      Delta_Value           : Static_Value_Info;
      Digits_Value          : Static_Value_Info;
      First_Value           : Static_Value_Info;
      Last_Value            : Static_Value_Info;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;


   type Static_Modular_Type_Id is new Natural;
   No_Static_Modular_Type : constant Static_Modular_Type_Id := 0;

   type Static_Modular_Type_Info is record
      Id                    : Static_Modular_Type_Id := No_Static_Modular_Type;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region                : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name                  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Modulus_Text          : Ada.Strings.Unbounded.Unbounded_String;
      Modulus_Value         : Static_Value_Info;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Static_Enumeration_Literal_Id is new Natural;
   No_Static_Enumeration_Literal : constant Static_Enumeration_Literal_Id := 0;

   type Static_Enumeration_Literal_Info is record
      Id                    : Static_Enumeration_Literal_Id := No_Static_Enumeration_Literal;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region                : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Type_Name             : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Type_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Literal_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Literal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Position              : Long_Long_Integer := 0;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Static_Type_Bound_Id is new Natural;
   No_Static_Type_Bound : constant Static_Type_Bound_Id := 0;

   type Static_Type_Bound_Info is record
      Id              : Static_Type_Bound_Id := No_Static_Type_Bound;
      Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      First_Text      : Ada.Strings.Unbounded.Unbounded_String;
      Last_Text       : Ada.Strings.Unbounded.Unbounded_String;
      First_Value     : Static_Value_Info;
      Last_Value      : Static_Value_Info;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Static_Binding_Id is new Natural;
   No_Static_Binding : constant Static_Binding_Id := 0;

   type Static_Binding_Kind is
     (Static_Binding_Named_Number,
      Static_Binding_Constant,
      Static_Binding_Unsupported);

   type Static_Binding_Info is record
      Id              : Static_Binding_Id := No_Static_Binding;
      Kind            : Static_Binding_Kind := Static_Binding_Unsupported;
      Node            : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Region          : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Name            : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Name : Ada.Strings.Unbounded.Unbounded_String;
      Expression_Text : Ada.Strings.Unbounded.Unbounded_String;
      Value           : Static_Value_Info;
      Start_Line      : Positive := 1;
      End_Line        : Positive := 1;
      Fingerprint     : Natural := 0;
   end record;

   type Static_Model is private;

   procedure Clear (Model : in out Static_Model);

   function Build
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model) return Static_Model;

   function Has_Static_Bindings (Model : Static_Model) return Boolean;
   function Static_Binding_Count (Model : Static_Model) return Natural;
   function Static_Binding_At (Model : Static_Model; Index : Positive) return Static_Binding_Info;

   function Static_Type_Bound_Count (Model : Static_Model) return Natural;
   function Static_Type_Bound_At
     (Model : Static_Model; Index : Positive) return Static_Type_Bound_Info;

   function Static_Fixed_Type_Count (Model : Static_Model) return Natural;
   function Static_Fixed_Type_At
     (Model : Static_Model; Index : Positive) return Static_Fixed_Type_Info;

   function Lookup_Fixed_Type
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Fixed_Type_Id;

   function Static_Fixed_Type
     (Model : Static_Model;
      Id    : Static_Fixed_Type_Id) return Static_Fixed_Type_Info;

   function Quantize_Fixed_Value
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name  : String;
      Expression : String) return Static_Value_Info;

   function Static_Modular_Type_Count (Model : Static_Model) return Natural;
   function Static_Modular_Type_At
     (Model : Static_Model; Index : Positive) return Static_Modular_Type_Info;

   function Static_Enumeration_Literal_Count (Model : Static_Model) return Natural;
   function Static_Enumeration_Literal_At
     (Model : Static_Model; Index : Positive) return Static_Enumeration_Literal_Info;

   function Lookup_Modular_Type
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Modular_Type_Id;

   function Static_Modular_Type
     (Model : Static_Model;
      Id    : Static_Modular_Type_Id) return Static_Modular_Type_Info;

   function Reduce_Modular_Integer
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name  : String;
      Expression : String) return Static_Value_Info;

   function Lookup_Enumeration_Literal
     (Model     : Static_Model;
      Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name : String;
      Literal   : String) return Static_Enumeration_Literal_Id;

   function Lookup_Enumeration_Literal_By_Position
     (Model     : Static_Model;
      Region    : Editor.Ada_Declarative_Regions.Region_Id;
      Type_Name : String;
      Position  : Long_Long_Integer) return Static_Enumeration_Literal_Id;

   function Static_Enumeration_Literal
     (Model : Static_Model;
      Id    : Static_Enumeration_Literal_Id) return Static_Enumeration_Literal_Info;

   function Lookup_Static_Binding
     (Model  : Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Static_Binding_Id;

   function Static_Binding
     (Model : Static_Model;
      Id    : Static_Binding_Id) return Static_Binding_Info;

   function Evaluate_Integer_Expression
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) return Static_Value_Info;

   function Evaluate_Numeric_Expression
     (Model      : Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Expression : String) return Static_Value_Info;

   function Is_Static_Integer (Value : Static_Value_Info) return Boolean;
   function Is_Static_Real (Value : Static_Value_Info) return Boolean;
   function Is_Static_Numeric (Value : Static_Value_Info) return Boolean;
   function Is_Decided (Value : Static_Value_Info) return Boolean;
   function Fingerprint (Model : Static_Model) return Natural;

private
   package Binding_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Binding_Info);

   package Type_Bound_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Type_Bound_Info);

   package Fixed_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Fixed_Type_Info);

   package Modular_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Modular_Type_Info);

   package Enumeration_Literal_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Enumeration_Literal_Info);

   type Static_Model is record
      Regions            : Editor.Ada_Declarative_Regions.Region_Model;
      Bindings           : Binding_Vectors.Vector;
      Type_Bounds        : Type_Bound_Vectors.Vector;
      Fixed_Types        : Fixed_Type_Vectors.Vector;
      Modular_Types      : Modular_Type_Vectors.Vector;
      Enumeration_Literals : Enumeration_Literal_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Static_Expressions;
