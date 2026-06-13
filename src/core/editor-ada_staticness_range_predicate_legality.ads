with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Overload_Resolution_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;

package Editor.Ada_Staticness_Range_Predicate_Legality is

   --  Pass1110 compiler-grade staticness/range/predicate legality layer.
   --  This package consolidates Ada legality checks whose answer depends on
   --  static-expression availability, discrete range membership, subtype
   --  predicate metadata, and already-classified assignment/return/conversion/
   --  overload outcomes.  It is snapshot-owned and projection-free: no parsing,
   --  file IO, save/reload, dirty-state mutation, compiler invocation, command
   --  registration, keybinding/workspace mutation, or render-side analysis.

   subtype Assignment_Legality_Id is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Id;
   subtype Assignment_Legality_Status is
     Editor.Ada_Assignment_Legality.Assignment_Legality_Status;
   subtype Return_Legality_Id is
     Editor.Ada_Return_Legality.Return_Legality_Id;
   subtype Return_Legality_Status is
     Editor.Ada_Return_Legality.Return_Legality_Status;
   subtype Semantic_Legality_Id is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Id;
   subtype Semantic_Legality_Status is
     Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Status;
   subtype Overload_Legality_Id is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Id;
   subtype Overload_Legality_Status is
     Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Status;

   type Static_Context_Id is new Natural;
   No_Static_Context : constant Static_Context_Id := 0;

   type Static_Legality_Id is new Natural;
   No_Static_Legality : constant Static_Legality_Id := 0;

   type Static_Context_Kind is
     (Static_Context_Range_Constraint,
      Static_Context_Discrete_Choice,
      Static_Context_Case_Choice,
      Static_Context_Discriminant_Constraint,
      Static_Context_Array_Index_Constraint,
      Static_Context_Object_Initialization,
      Static_Context_Assignment,
      Static_Context_Return,
      Static_Context_Conversion,
      Static_Context_Qualified_Expression,
      Static_Context_Predicate_Check,
      Static_Context_Overload_Actual,
      Static_Context_Generic_Actual,
      Static_Context_Representation_Item,
      Static_Context_Unknown);

   type Predicate_Policy is
     (Predicate_Not_Present,
      Predicate_Static_Known_True,
      Predicate_Static_Known_False,
      Predicate_Dynamic,
      Predicate_Unresolved,
      Predicate_Non_Static_Required,
      Predicate_Unknown);

   type Static_Legality_Status is
     (Static_Legality_Not_Checked,
      Static_Legality_Static_Range_Compatible,
      Static_Legality_Static_Predicate_Compatible,
      Static_Legality_Dynamic_Predicate_Required,
      Static_Legality_Static_Discrete_Choice_Compatible,
      Static_Legality_Static_Constraint_Compatible,
      Static_Legality_Linked_Assignment_Compatible,
      Static_Legality_Linked_Return_Compatible,
      Static_Legality_Linked_Semantic_Compatible,
      Static_Legality_Linked_Overload_Compatible,
      Static_Legality_Requires_Static_Expression,
      Static_Legality_Non_Static_Expression,
      Static_Legality_Unresolved_Static_Name,
      Static_Legality_Malformed_Static_Expression,
      Static_Legality_Static_Division_By_Zero,
      Static_Legality_Static_Cycle,
      Static_Legality_Unsupported_Static_Attribute,
      Static_Legality_Range_Violation,
      Static_Legality_Null_Range,
      Static_Legality_Choice_Out_Of_Range,
      Static_Legality_Duplicate_Static_Choice,
      Static_Legality_Choice_Coverage_Gap,
      Static_Legality_Predicate_Static_Failure,
      Static_Legality_Predicate_Unresolved,
      Static_Legality_Predicate_Non_Static_Where_Static_Required,
      Static_Legality_Linked_Assignment_Error,
      Static_Legality_Linked_Return_Error,
      Static_Legality_Linked_Semantic_Error,
      Static_Legality_Linked_Overload_Error,
      Static_Legality_Universal_Numeric_Unresolved,
      Static_Legality_Indeterminate);

   type Static_Legality_Context_Info is record
      Id                  : Static_Context_Id := No_Static_Context;
      Kind                : Static_Context_Kind := Static_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Subtype_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Requires_Static     : Boolean := False;
      Static_Status       : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Static_Integer_Value : Long_Long_Integer := 0;
      Has_Static_Range    : Boolean := False;
      Static_First        : Long_Long_Integer := 0;
      Static_Last         : Long_Long_Integer := 0;
      Choice_Count        : Natural := 0;
      Duplicate_Choice_Count : Natural := 0;
      Coverage_Gap_Count  : Natural := 0;
      Predicate           : Predicate_Policy := Predicate_Not_Present;
      Is_Universal_Numeric : Boolean := False;
      Assignment          : Assignment_Legality_Id :=
        Editor.Ada_Assignment_Legality.No_Assignment_Legality;
      Assignment_Status   : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Item         : Return_Legality_Id :=
        Editor.Ada_Return_Legality.No_Return_Legality;
      Return_Status       : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Item       : Semantic_Legality_Id :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.No_Semantic_Legality;
      Semantic_Status     : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Overload_Item       : Overload_Legality_Id :=
        Editor.Ada_Overload_Resolution_Legality.No_Overload_Legality;
      Overload_Status     : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
   end record;

   type Static_Legality_Info is record
      Id                  : Static_Legality_Id := No_Static_Legality;
      Context             : Static_Context_Id := No_Static_Context;
      Kind                : Static_Context_Kind := Static_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Expression_Node     : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Static_Legality_Status := Static_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Subtype_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Static_Status       : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Static_Integer_Value : Long_Long_Integer := 0;
      Static_First        : Long_Long_Integer := 0;
      Static_Last         : Long_Long_Integer := 0;
      Predicate           : Predicate_Policy := Predicate_Not_Present;
      Assignment_Status   : Assignment_Legality_Status :=
        Editor.Ada_Assignment_Legality.Assignment_Legality_Not_Checked;
      Return_Status       : Return_Legality_Status :=
        Editor.Ada_Return_Legality.Return_Legality_Not_Checked;
      Semantic_Status     : Semantic_Legality_Status :=
        Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Not_Checked;
      Overload_Status     : Overload_Legality_Status :=
        Editor.Ada_Overload_Resolution_Legality.Overload_Legality_Not_Checked;
      Choice_Count        : Natural := 0;
      Duplicate_Choice_Count : Natural := 0;
      Coverage_Gap_Count  : Natural := 0;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Static_Legality_Context_Model is private;
   type Static_Legality_Result_Set is private;
   type Static_Legality_Model is private;

   procedure Clear (Model : in out Static_Legality_Context_Model);
   procedure Add_Context
     (Model : in out Static_Legality_Context_Model;
      Info  : Static_Legality_Context_Info);

   function Context_Count (Model : Static_Legality_Context_Model) return Natural;
   function Context_At
     (Model : Static_Legality_Context_Model;
      Index : Positive) return Static_Legality_Context_Info;
   function Fingerprint (Model : Static_Legality_Context_Model) return Natural;

   function Build
     (Contexts : Static_Legality_Context_Model) return Static_Legality_Model;

   function Legality_Count (Model : Static_Legality_Model) return Natural;
   function Legality_At
     (Model : Static_Legality_Model;
      Index : Positive) return Static_Legality_Info;

   function First_For_Node
     (Model : Static_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Static_Legality_Info;
   function Rows_For_Status
     (Model  : Static_Legality_Model;
      Status : Static_Legality_Status) return Static_Legality_Result_Set;
   function Rows_For_Kind
     (Model : Static_Legality_Model;
      Kind  : Static_Context_Kind) return Static_Legality_Result_Set;
   function Rows_For_Subtype
     (Model        : Static_Legality_Model;
      Subtype_Name : String) return Static_Legality_Result_Set;
   function Rows_For_Predicate
     (Model     : Static_Legality_Model;
      Predicate : Predicate_Policy) return Static_Legality_Result_Set;

   function Result_Count (Results : Static_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Static_Legality_Result_Set;
      Index   : Positive) return Static_Legality_Info;

   function Count_Status
     (Model  : Static_Legality_Model;
      Status : Static_Legality_Status) return Natural;
   function Count_Kind
     (Model : Static_Legality_Model;
      Kind  : Static_Context_Kind) return Natural;
   function Count_Predicate
     (Model     : Static_Legality_Model;
      Predicate : Predicate_Policy) return Natural;

   function Legal_Count (Model : Static_Legality_Model) return Natural;
   function Error_Count (Model : Static_Legality_Model) return Natural;
   function Static_Required_Error_Count (Model : Static_Legality_Model) return Natural;
   function Range_Error_Count (Model : Static_Legality_Model) return Natural;
   function Predicate_Error_Count (Model : Static_Legality_Model) return Natural;
   function Linked_Error_Count (Model : Static_Legality_Model) return Natural;
   function Universal_Numeric_Unresolved_Count (Model : Static_Legality_Model) return Natural;
   function Indeterminate_Count (Model : Static_Legality_Model) return Natural;
   function Fingerprint (Model : Static_Legality_Model) return Natural;

   function Has_Legality (Info : Static_Legality_Info) return Boolean;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Legality_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Static_Legality_Info);

   type Static_Legality_Context_Model is record
      Contexts : Context_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

   type Static_Legality_Result_Set is record
      Items : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Static_Legality_Model is record
      Items : Legality_Vectors.Vector;
      Legal_Total : Natural := 0;
      Error_Total : Natural := 0;
      Static_Required_Total : Natural := 0;
      Range_Error_Total : Natural := 0;
      Predicate_Error_Total : Natural := 0;
      Linked_Error_Total : Natural := 0;
      Universal_Numeric_Total : Natural := 0;
      Indeterminate_Total : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Staticness_Range_Predicate_Legality;
