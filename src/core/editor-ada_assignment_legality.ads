with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;
with Editor.Ada_View_Aware_Compatibility;

package Editor.Ada_Assignment_Legality is

   --  Compiler-grade assignment and object-initialization legality building
   --  block.  This package consumes snapshot-owned expression type metadata,
   --  subtype compatibility helpers, static numeric metadata, the type graph,
   --  and optional private/limited view compatibility metadata to classify Ada
   --  assignment-like contexts.  It performs no parsing, file IO, buffer
   --  mutation, command/keybinding/workspace mutation, or render-side work.

   subtype Expression_Type_Id is Editor.Ada_Expression_Types.Expression_Type_Id;

   type Assignment_Context_Id is new Natural;
   No_Assignment_Context : constant Assignment_Context_Id := 0;

   type Assignment_Legality_Id is new Natural;
   No_Assignment_Legality : constant Assignment_Legality_Id := 0;

   type Assignment_Context_Kind is
     (Assignment_Context_Assignment_Statement,
      Assignment_Context_Object_Initialization,
      Assignment_Context_Default_Initialization,
      Assignment_Context_Extended_Return_Object,
      Assignment_Context_Parameter_Default,
      Assignment_Context_Unknown);

   type Assignment_Target_Mode is
     (Assignment_Target_Variable,
      Assignment_Target_Constant,
      Assignment_Target_In_Formal,
      Assignment_Target_Out_Formal,
      Assignment_Target_In_Out_Formal,
      Assignment_Target_Unknown);

   type Assignment_Legality_Status is
     (Assignment_Legality_Not_Checked,
      Assignment_Legality_Compatible,
      Assignment_Legality_Class_Wide_Compatible,
      Assignment_Legality_Static_Range_Compatible,
      Assignment_Legality_Incompatible_Subtype,
      Assignment_Legality_Class_Wide_Incompatible,
      Assignment_Legality_Target_Unresolved,
      Assignment_Legality_Source_Unresolved,
      Assignment_Legality_Private_View_Barrier,
      Assignment_Legality_Limited_View_Barrier,
      Assignment_Legality_Cross_Unit_Unresolved_View,
      Assignment_Legality_Assignment_To_Constant,
      Assignment_Legality_Assignment_To_In_Formal,
      Assignment_Legality_Null_Exclusion_Violation,
      Assignment_Legality_Static_Range_Violation,
      Assignment_Legality_Universal_Numeric_Unresolved,
      Assignment_Legality_Indeterminate);

   type Assignment_Context_Info is record
      Id                  : Assignment_Context_Id := No_Assignment_Context;
      Kind                : Assignment_Context_Kind := Assignment_Context_Unknown;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Expression   : Expression_Type_Id := Editor.Ada_Expression_Types.No_Expression_Type;
      Target_Mode         : Assignment_Target_Mode := Assignment_Target_Unknown;
      Target_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Source_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Source_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Is_Null_Excluding : Boolean := False;
      Target_Is_Class_Wide     : Boolean := False;
      Source_Is_Class_Wide     : Boolean := False;
      Source_Is_Null_Literal   : Boolean := False;
      Source_Is_Universal_Numeric : Boolean := False;
      Source_Static_Status : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Source_Static_Integer_Value : Long_Long_Integer := 0;
      Target_Has_Static_Range : Boolean := False;
      Target_Static_First     : Long_Long_Integer := 0;
      Target_Static_Last      : Long_Long_Integer := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Assignment_Legality_Info is record
      Id                  : Assignment_Legality_Id := No_Assignment_Legality;
      Context             : Assignment_Context_Id := No_Assignment_Context;
      Kind                : Assignment_Context_Kind := Assignment_Context_Unknown;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Source_Expression   : Expression_Type_Id := Editor.Ada_Expression_Types.No_Expression_Type;
      Target_Mode         : Assignment_Target_Mode := Assignment_Target_Unknown;
      Status              : Assignment_Legality_Status := Assignment_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Source_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Source_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Subtype_Status      : Editor.Ada_Subtype_Compatibility.Compatibility_Status :=
        Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Not_Checked;
      View_Status         : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status :=
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked;
      Target_Is_Null_Excluding : Boolean := False;
      Target_Is_Class_Wide     : Boolean := False;
      Source_Is_Class_Wide     : Boolean := False;
      Source_Is_Null_Literal   : Boolean := False;
      Source_Is_Universal_Numeric : Boolean := False;
      Source_Static_Status : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Source_Static_Integer_Value : Long_Long_Integer := 0;
      Target_Has_Static_Range : Boolean := False;
      Target_Static_First     : Long_Long_Integer := 0;
      Target_Static_Last      : Long_Long_Integer := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Assignment_Context_Model is private;
   type Assignment_Legality_Result_Set is private;
   type Assignment_Legality_Model is private;

   procedure Clear (Model : in out Assignment_Context_Model);

   procedure Add_Context
     (Model   : in out Assignment_Context_Model;
      Context : Assignment_Context_Info);

   function Context_Count (Model : Assignment_Context_Model) return Natural;
   function Context_At
     (Model : Assignment_Context_Model;
      Index : Positive) return Assignment_Context_Info;
   function Fingerprint (Model : Assignment_Context_Model) return Natural;

   function Build
     (Contexts   : Assignment_Context_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Assignment_Legality_Model;

   function Build_With_View_Compatibility
     (Contexts    : Assignment_Context_Model;
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views       : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model)
      return Assignment_Legality_Model;

   function Legality_Count (Model : Assignment_Legality_Model) return Natural;
   function Legality_At
     (Model : Assignment_Legality_Model;
      Index : Positive) return Assignment_Legality_Info;

   function First_For_Context
     (Model   : Assignment_Legality_Model;
      Context : Assignment_Context_Id) return Assignment_Legality_Info;

   function First_For_Source_Expression
     (Model      : Assignment_Legality_Model;
      Expression : Expression_Type_Id) return Assignment_Legality_Info;

   function First_For_Target_Node
     (Model : Assignment_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Assignment_Legality_Info;

   function Results_For_Status
     (Model  : Assignment_Legality_Model;
      Status : Assignment_Legality_Status) return Assignment_Legality_Result_Set;

   function Result_Count (Results : Assignment_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Assignment_Legality_Result_Set;
      Index   : Positive) return Assignment_Legality_Info;

   function Count_Status
     (Model  : Assignment_Legality_Model;
      Status : Assignment_Legality_Status) return Natural;

   function Compatible_Count (Model : Assignment_Legality_Model) return Natural;
   function Error_Count (Model : Assignment_Legality_Model) return Natural;
   function Warning_Count (Model : Assignment_Legality_Model) return Natural;
   function Info_Count (Model : Assignment_Legality_Model) return Natural;
   function Target_Unresolved_Count (Model : Assignment_Legality_Model) return Natural;
   function Source_Unresolved_Count (Model : Assignment_Legality_Model) return Natural;
   function Incompatible_Count (Model : Assignment_Legality_Model) return Natural;
   function Private_View_Barrier_Count (Model : Assignment_Legality_Model) return Natural;
   function Limited_View_Barrier_Count (Model : Assignment_Legality_Model) return Natural;
   function Null_Exclusion_Violation_Count (Model : Assignment_Legality_Model) return Natural;
   function Static_Range_Violation_Count (Model : Assignment_Legality_Model) return Natural;
   function Universal_Numeric_Unresolved_Count (Model : Assignment_Legality_Model) return Natural;
   function Constant_Target_Count (Model : Assignment_Legality_Model) return Natural;
   function In_Formal_Target_Count (Model : Assignment_Legality_Model) return Natural;
   function Has_Legality (Info : Assignment_Legality_Info) return Boolean;
   function Fingerprint (Model : Assignment_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Assignment_Context_Info);

   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Assignment_Legality_Info);

   type Assignment_Context_Model is record
      Items             : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Assignment_Legality_Result_Set is record
      Items       : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Assignment_Legality_Model is record
      Items             : Legality_Vectors.Vector;
      Compatible_Total  : Natural := 0;
      Error_Total       : Natural := 0;
      Warning_Total     : Natural := 0;
      Info_Total        : Natural := 0;
      Target_Unresolved_Total : Natural := 0;
      Source_Unresolved_Total : Natural := 0;
      Incompatible_Total      : Natural := 0;
      Private_View_Barrier_Total : Natural := 0;
      Limited_View_Barrier_Total : Natural := 0;
      Null_Exclusion_Violation_Total : Natural := 0;
      Static_Range_Violation_Total   : Natural := 0;
      Universal_Numeric_Unresolved_Total : Natural := 0;
      Constant_Target_Total : Natural := 0;
      In_Formal_Target_Total : Natural := 0;
      Model_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Assignment_Legality;
