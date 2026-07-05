with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Expression_Types;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_View_Aware_Compatibility;

package Editor.Ada_Conversion_Access_Aggregate_Legality is

   --  Wide compiler-grade semantic legality building block for Case 1101.
   --  The package covers three closely related expression legality families in
   --  one pass: conversions, access/allocator/null-exclusion checks, and
   --  aggregate/container-aggregate structural legality.  It is intentionally
   --  snapshot-owned and fixture-friendly so parser consumers can feed resolved
   --  semantic facts without render-side parsing, file IO, command mutation, or
   --  workspace/render mutation.

   type Semantic_Context_Id is new Natural;
   No_Semantic_Context : constant Semantic_Context_Id := 0;

   type Semantic_Legality_Id is new Natural;
   No_Semantic_Legality : constant Semantic_Legality_Id := 0;

   type Semantic_Context_Kind is
     (Semantic_Context_Conversion,
      Semantic_Context_Qualified_Expression,
      Semantic_Context_Access_Conversion,
      Semantic_Context_Access_Parameter,
      Semantic_Context_Allocator,
      Semantic_Context_Null_Assignment,
      Semantic_Context_Aggregate,
      Semantic_Context_Array_Aggregate,
      Semantic_Context_Record_Aggregate,
      Semantic_Context_Container_Aggregate,
      Semantic_Context_Unknown);

   type Access_Kind is
     (Access_Kind_None,
      Access_Kind_Object,
      Access_Kind_Subprogram,
      Access_Kind_Anonymous_Object,
      Access_Kind_Anonymous_Subprogram,
      Access_Kind_Unknown);

   type Semantic_Legality_Status is
     (Semantic_Legality_Not_Checked,
      Semantic_Legality_Legal_Conversion,
      Semantic_Legality_Legal_Qualified_Expression,
      Semantic_Legality_Legal_Access_Conversion,
      Semantic_Legality_Legal_Access_Parameter,
      Semantic_Legality_Legal_Allocator,
      Semantic_Legality_Legal_Aggregate,
      Semantic_Legality_Legal_Container_Aggregate,
      Semantic_Legality_Numeric_Conversion,
      Semantic_Legality_Tagged_Conversion,
      Semantic_Legality_Class_Wide_Conversion,
      Semantic_Legality_Static_Range_Compatible,
      Semantic_Legality_Target_Unresolved,
      Semantic_Legality_Operand_Unresolved,
      Semantic_Legality_Incompatible_Type,
      Semantic_Legality_Private_View_Barrier,
      Semantic_Legality_Limited_View_Barrier,
      Semantic_Legality_Cross_Unit_Unresolved_View,
      Semantic_Legality_Static_Range_Violation,
      Semantic_Legality_Null_Exclusion_Violation,
      Semantic_Legality_Access_Kind_Mismatch,
      Semantic_Legality_Accessibility_Indeterminate,
      Semantic_Legality_Illegal_Access_Conversion,
      Semantic_Legality_Allocator_Designated_Subtype_Mismatch,
      Semantic_Legality_Aggregate_Missing_Component,
      Semantic_Legality_Aggregate_Duplicate_Component,
      Semantic_Legality_Aggregate_Component_Type_Mismatch,
      Semantic_Legality_Aggregate_Positional_After_Named,
      Semantic_Legality_Aggregate_Index_Coverage_Error,
      Semantic_Legality_Container_Aggregate_Missing_Aspect,
      Semantic_Legality_Universal_Numeric_Unresolved,
      Semantic_Legality_Indeterminate);

   type Semantic_Context_Info is record
      Id                  : Semantic_Context_Id := No_Semantic_Context;
      Kind                : Semantic_Context_Kind := Semantic_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operand_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Operand_Subtype     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Access       : Access_Kind := Access_Kind_None;
      Operand_Access      : Access_Kind := Access_Kind_None;
      Target_Is_Null_Excluding : Boolean := False;
      Operand_Is_Null_Literal  : Boolean := False;
      Is_Numeric_Target   : Boolean := False;
      Is_Numeric_Operand  : Boolean := False;
      Is_Tagged_Target    : Boolean := False;
      Is_Tagged_Operand   : Boolean := False;
      Target_Is_Class_Wide : Boolean := False;
      Operand_Is_Class_Wide : Boolean := False;
      Operand_Is_Universal_Numeric : Boolean := False;
      Operand_Static_Status : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Operand_Static_Integer_Value : Long_Long_Integer := 0;
      Target_Has_Static_Range : Boolean := False;
      Target_Static_First     : Long_Long_Integer := 0;
      Target_Static_Last      : Long_Long_Integer := 0;
      Requires_Accessibility_Check : Boolean := False;
      Accessibility_Known_Compatible : Boolean := False;
      Aggregate_Component_Count : Natural := 0;
      Aggregate_Expected_Component_Count : Natural := 0;
      Aggregate_Has_Duplicate_Component : Boolean := False;
      Aggregate_Has_Component_Type_Mismatch : Boolean := False;
      Aggregate_Has_Positional_After_Named : Boolean := False;
      Aggregate_Has_Index_Coverage_Error : Boolean := False;
      Container_Has_Required_Aspect : Boolean := True;
      View_Status         : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status :=
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Fingerprint         : Natural := 0;
   end record;

   type Semantic_Legality_Info is record
      Id                  : Semantic_Legality_Id := No_Semantic_Legality;
      Context             : Semantic_Context_Id := No_Semantic_Context;
      Kind                : Semantic_Context_Kind := Semantic_Context_Unknown;
      Node                : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Target_Node         : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Operand_Node        : Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.No_Node;
      Status              : Semantic_Legality_Status := Semantic_Legality_Not_Checked;
      Message             : Ada.Strings.Unbounded.Unbounded_String;
      Detail              : Ada.Strings.Unbounded.Unbounded_String;
      Target_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Operand_Subtype     : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Access       : Access_Kind := Access_Kind_None;
      Operand_Access      : Access_Kind := Access_Kind_None;
      View_Status         : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Status :=
        Editor.Ada_View_Aware_Compatibility.View_Compatibility_Not_Checked;
      Start_Line          : Positive := 1;
      Start_Column        : Positive := 1;
      End_Line            : Positive := 1;
      End_Column          : Positive := 1;
      Source_Fingerprint  : Natural := 0;
      Fingerprint         : Natural := 0;
   end record;

   type Semantic_Context_Model is private;
   type Semantic_Legality_Result_Set is private;
   type Semantic_Legality_Model is private;

   procedure Clear (Model : in out Semantic_Context_Model);
   procedure Add_Context
     (Model   : in out Semantic_Context_Model;
      Context : Semantic_Context_Info);

   function Context_Count (Model : Semantic_Context_Model) return Natural;
   function Context_At
     (Model : Semantic_Context_Model;
      Index : Positive) return Semantic_Context_Info;
   function Fingerprint (Model : Semantic_Context_Model) return Natural;

   function Build_Contexts_From_Expression_Types
     (Expressions : Editor.Ada_Expression_Types.Expression_Type_Model)
      return Semantic_Context_Model;

   function Build (Contexts : Semantic_Context_Model) return Semantic_Legality_Model;

   function Legality_Count (Model : Semantic_Legality_Model) return Natural;
   function Legality_At
     (Model : Semantic_Legality_Model;
      Index : Positive) return Semantic_Legality_Info;

   function First_For_Context
     (Model   : Semantic_Legality_Model;
      Context : Semantic_Context_Id) return Semantic_Legality_Info;
   function First_For_Node
     (Model : Semantic_Legality_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Semantic_Legality_Info;
   function Results_For_Status
     (Model  : Semantic_Legality_Model;
      Status : Semantic_Legality_Status) return Semantic_Legality_Result_Set;
   function Rows_For_Kind
     (Model : Semantic_Legality_Model;
      Kind  : Semantic_Context_Kind) return Semantic_Legality_Result_Set;

   function Result_Count (Results : Semantic_Legality_Result_Set) return Natural;
   function Result_At
     (Results : Semantic_Legality_Result_Set;
      Index   : Positive) return Semantic_Legality_Info;

   function Count_Status
     (Model  : Semantic_Legality_Model;
      Status : Semantic_Legality_Status) return Natural;
   function Count_Kind
     (Model : Semantic_Legality_Model;
      Kind  : Semantic_Context_Kind) return Natural;

   function Compatible_Count (Model : Semantic_Legality_Model) return Natural;
   function Error_Count (Model : Semantic_Legality_Model) return Natural;
   function Warning_Count (Model : Semantic_Legality_Model) return Natural;
   function Conversion_Count (Model : Semantic_Legality_Model) return Natural;
   function Access_Count (Model : Semantic_Legality_Model) return Natural;
   function Aggregate_Count (Model : Semantic_Legality_Model) return Natural;
   function Static_Range_Violation_Count (Model : Semantic_Legality_Model) return Natural;
   function Null_Exclusion_Violation_Count (Model : Semantic_Legality_Model) return Natural;
   function Access_Kind_Mismatch_Count (Model : Semantic_Legality_Model) return Natural;
   function Accessibility_Indeterminate_Count (Model : Semantic_Legality_Model) return Natural;
   function Aggregate_Error_Count (Model : Semantic_Legality_Model) return Natural;
   function Universal_Numeric_Unresolved_Count (Model : Semantic_Legality_Model) return Natural;

   function Has_Legality (Info : Semantic_Legality_Info) return Boolean;
   function Fingerprint (Model : Semantic_Legality_Model) return Natural;

private
   package Context_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Context_Info);
   package Legality_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Semantic_Legality_Info);

   type Semantic_Context_Model is record
      Items             : Context_Vectors.Vector;
      Model_Fingerprint : Natural := 0;
   end record;

   type Semantic_Legality_Result_Set is record
      Items       : Legality_Vectors.Vector;
      Fingerprint : Natural := 0;
   end record;

   type Semantic_Legality_Model is record
      Items                         : Legality_Vectors.Vector;
      Compatible_Total              : Natural := 0;
      Error_Total                   : Natural := 0;
      Warning_Total                 : Natural := 0;
      Conversion_Total              : Natural := 0;
      Access_Total                  : Natural := 0;
      Aggregate_Total               : Natural := 0;
      Static_Range_Violation_Total  : Natural := 0;
      Null_Exclusion_Violation_Total : Natural := 0;
      Access_Kind_Mismatch_Total    : Natural := 0;
      Accessibility_Indeterminate_Total : Natural := 0;
      Aggregate_Error_Total         : Natural := 0;
      Universal_Numeric_Unresolved_Total : Natural := 0;
      Model_Fingerprint             : Natural := 0;
   end record;

end Editor.Ada_Conversion_Access_Aggregate_Legality;
