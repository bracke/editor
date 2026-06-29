with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Call_Resolution;
with Editor.Ada_Expected_Type_Contexts;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Project_Index;
with Editor.Ada_Selected_Name_Resolution;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;
with Editor.Ada_Use_Type_Operators;

package Editor.Ada_Expression_Types is

   --  Compiler-grade expression type inference foundation.  This package
   --  derives deterministic, snapshot-owned type-shape metadata for expression
   --  nodes without invoking a compiler, touching files, or mutating editor
   --  state.  The first layer classifies literals, names, selected names, calls,
   --  operator/unary/parenthesized expressions, qualified expressions,
   --  conversions, aggregates, and attribute references.  Unresolved and
   --  ambiguous cases are preserved explicitly for later overload/type checking
   --  passes instead of being accepted silently.

   type Expected_Type_Propagation_Status is
     (Expected_Type_Not_Checked,
      Expected_Type_No_Context,
      Expected_Type_Context_Found,
      Expected_Type_Propagated,
      Expected_Type_Compatible,
      Expected_Type_Mismatch,
      Expected_Type_Unknown);

   type Operator_Type_Inference_Status is
     (Operator_Type_Not_Checked,
      Operator_Type_Not_Operator,
      Operator_Type_Resolved_Predefined,
      Operator_Type_Resolved_Visible,
      Operator_Type_Ambiguous,
      Operator_Type_Operand_Mismatch,
      Operator_Type_Operand_Unknown,
      Operator_Type_Result_Unknown,
      Operator_Type_Overload_Resolved,
      Operator_Type_Overload_Ambiguous,
      Operator_Type_Overload_Mismatch,
      Operator_Type_Overload_Unknown);

   type Concatenation_Type_Inference_Status is
     (Concatenation_Type_Not_Checked,
      Concatenation_Type_Not_Concatenation,
      Concatenation_Type_String_Compatible,
      Concatenation_Type_Array_Compatible,
      Concatenation_Type_Character_String_Compatible,
      Concatenation_Type_Expected_Context_Result,
      Concatenation_Type_Operand_Mismatch,
      Concatenation_Type_Operand_Unknown,
      Concatenation_Type_Result_Unknown);

   type Aggregate_Type_Inference_Status is
     (Aggregate_Type_Not_Checked,
      Aggregate_Type_Not_Aggregate,
      Aggregate_Type_Context_Required,
      Aggregate_Type_Array_Context,
      Aggregate_Type_Record_Context,
      Aggregate_Type_Container_Context,
      Aggregate_Type_Delta_Context,
      Aggregate_Type_Record_Components_Compatible,
      Aggregate_Type_Record_Component_Missing,
      Aggregate_Type_Record_Component_Duplicate,
      Aggregate_Type_Array_Elements_Compatible,
      Aggregate_Type_Array_Element_Mismatch,
      Aggregate_Type_Array_Element_Unknown,
      Aggregate_Type_Compatible,
      Aggregate_Type_Mismatch,
      Aggregate_Type_Unknown);

   type Conversion_Type_Inference_Status is
     (Conversion_Type_Not_Checked,
      Conversion_Type_Not_Conversion,
      Conversion_Type_Target_Resolved,
      Conversion_Type_Target_Unresolved,
      Conversion_Type_Target_Ambiguous,
      Conversion_Type_Operand_Compatible,
      Conversion_Type_Operand_Requires_Explicit_Conversion,
      Conversion_Type_Operand_Mismatch,
      Conversion_Type_Operand_Unknown,
      Conversion_Type_Malformed);


   type Conditional_Type_Inference_Status is
     (Conditional_Type_Not_Checked,
      Conditional_Type_Not_Conditional,
      Conditional_Type_Expected_Context,
      Conditional_Type_Branches_Compatible,
      Conditional_Type_Branch_Mismatch,
      Conditional_Type_Branch_Unknown,
      Conditional_Type_Boolean_Result,
      Conditional_Type_Reduction_Result,
      Conditional_Type_Declare_Result);

   type Membership_Range_Inference_Status is
     (Membership_Range_Not_Checked,
      Membership_Range_Not_Membership_Or_Range,
      Membership_Range_Membership_Compatible,
      Membership_Range_Membership_Mismatch,
      Membership_Range_Membership_Unknown,
      Membership_Range_Range_Compatible,
      Membership_Range_Range_Mismatch,
      Membership_Range_Range_Unknown,
      Membership_Range_Boolean_Result);


   type Target_Name_Inference_Status is
     (Target_Name_Not_Checked,
      Target_Name_Not_Target_Name_Or_Update,
      Target_Name_Context_Required,
      Target_Name_Context_Propagated,
      Target_Name_Delta_Update_Compatible,
      Target_Name_Delta_Update_Mismatch,
      Target_Name_Delta_Update_Unknown);

   type Indexed_Slice_Inference_Status is
     (Indexed_Slice_Not_Checked,
      Indexed_Slice_Not_Indexed_Or_Slice,
      Indexed_Slice_Prefix_Resolved,
      Indexed_Slice_Prefix_Unresolved,
      Indexed_Slice_Index_Compatible,
      Indexed_Slice_Index_Mismatch,
      Indexed_Slice_Index_Unknown,
      Indexed_Slice_Result_Element,
      Indexed_Slice_Result_Array,
      Indexed_Slice_Result_Unknown);


   type Boolean_Context_Inference_Status is
     (Boolean_Context_Not_Checked,
      Boolean_Context_Not_Boolean_Context,
      Boolean_Context_Expected_Boolean,
      Boolean_Context_Operand_Compatible,
      Boolean_Context_Operand_Mismatch,
      Boolean_Context_Operand_Unknown,
      Boolean_Context_Short_Circuit_Compatible,
      Boolean_Context_Short_Circuit_Mismatch,
      Boolean_Context_Condition_Compatible,
      Boolean_Context_Condition_Mismatch,
      Boolean_Context_Condition_Unknown);

   type Raise_No_Return_Inference_Status is
     (Raise_No_Return_Not_Checked,
      Raise_No_Return_Not_Raise,
      Raise_No_Return_Raise_Expression,
      Raise_No_Return_Raise_Statement,
      Raise_No_Return_Exception_Target_Known,
      Raise_No_Return_Exception_Target_Unknown,
      Raise_No_Return_With_Message,
      Raise_No_Return_Message_Unknown,
      Raise_No_Return_No_Return_Call,
      Raise_No_Return_Result_Context_Propagated,
      Raise_No_Return_Result_Context_Unknown);

   type Allocator_Type_Inference_Status is
     (Allocator_Type_Not_Checked,
      Allocator_Type_Not_Allocator,
      Allocator_Type_Target_Resolved,
      Allocator_Type_Target_Unresolved,
      Allocator_Type_Malformed,
      Allocator_Type_Expected_Access_Context,
      Allocator_Type_Expected_Not_Access,
      Allocator_Type_Designated_Compatible,
      Allocator_Type_Designated_Mismatch,
      Allocator_Type_Designated_Unknown,
      Allocator_Type_Result_Known,
      Allocator_Type_Result_Unknown);

   type Universal_Numeric_Resolution_Status is
     (Universal_Numeric_Not_Checked,
      Universal_Numeric_Not_Universal,
      Universal_Numeric_Expected_Context_Found,
      Universal_Numeric_Integer_Resolved,
      Universal_Numeric_Real_Resolved,
      Universal_Numeric_Modular_Resolved,
      Universal_Numeric_Fixed_Resolved,
      Universal_Numeric_Range_Compatible,
      Universal_Numeric_Range_Error,
      Universal_Numeric_Expected_Mismatch,
      Universal_Numeric_Static_Unknown);



   type Dispatching_Call_Inference_Status is
     (Dispatching_Call_Not_Checked,
      Dispatching_Call_Not_Call,
      Dispatching_Call_Primitive_Target,
      Dispatching_Call_Class_Wide_Controlling_Operand,
      Dispatching_Call_Controlling_Result,
      Dispatching_Call_Static_Binding,
      Dispatching_Call_Dynamic_Dispatch,
      Dispatching_Call_Target_Unresolved,
      Dispatching_Call_Target_Ambiguous,
      Dispatching_Call_Controlling_Unknown);

   type Call_Actual_Type_Resolution_Status is
     (Call_Actual_Type_Not_Checked,
      Call_Actual_Type_Not_Call,
      Call_Actual_Type_Unresolved_Call,
      Call_Actual_Type_Ambiguous_Call,
      Call_Actual_Type_Profile_Unavailable,
      Call_Actual_Type_All_Compatible,
      Call_Actual_Type_Actual_Mismatch,
      Call_Actual_Type_Actual_Unknown);

   type Parameter_Association_Inference_Status is
     (Parameter_Association_Not_Checked,
      Parameter_Association_Not_Parameter,
      Parameter_Association_Formal_Context_Found,
      Parameter_Association_Formal_Context_Unresolved,
      Parameter_Association_Formal_Context_Ambiguous,
      Parameter_Association_Expected_Propagated,
      Parameter_Association_Compatible,
      Parameter_Association_Mismatch,
      Parameter_Association_Unknown);

   type Dereference_Access_Inference_Status is
     (Dereference_Access_Not_Checked,
      Dereference_Access_Not_Dereference_Or_Access,
      Dereference_Prefix_Resolved,
      Dereference_Prefix_Unresolved,
      Dereference_Prefix_Not_Access_Type,
      Dereference_Designated_Subtype_Known,
      Dereference_Designated_Subtype_Unknown,
      Access_Attribute_Target_Resolved,
      Access_Attribute_Target_Unresolved,
      Access_Attribute_Result_Known,
      Access_Attribute_Result_Unknown);


   type Attribute_Type_Inference_Status is
     (Attribute_Type_Not_Checked,
      Attribute_Type_Not_Attribute,
      Attribute_Type_Scalar_Bound,
      Attribute_Type_Range_Bound,
      Attribute_Type_Integer_Result,
      Attribute_Type_Boolean_Result,
      Attribute_Type_String_Result,
      Attribute_Type_Address_Result,
      Attribute_Type_Size_Result,
      Attribute_Type_Value_Result,
      Attribute_Type_Callable_Result,
      Attribute_Type_Prefix_Unresolved,
      Attribute_Type_Unknown_Attribute,
      Attribute_Type_Malformed);

   type Expression_Type_Status is
     (Expression_Type_Not_Checked,
      Expression_Type_Static_Integer,
      Expression_Type_Static_Real,
      Expression_Type_String_Literal,
      Expression_Type_Boolean_Literal,
      Expression_Type_Null_Literal,
      Expression_Type_Name_Resolved,
      Expression_Type_Name_Unresolved,
      Expression_Type_Name_Ambiguous,
      Expression_Type_Selected_Name_Resolved,
      Expression_Type_Selected_Name_Unresolved,
      Expression_Type_Selected_Name_Cross_Unit_Resolved,
      Expression_Type_Selected_Name_Cross_Unit_Limited,
      Expression_Type_Selected_Name_Cross_Unit_Private,
      Expression_Type_Selected_Name_Cross_Unit_Unresolved,
      Expression_Type_Call_Resolved,
      Expression_Type_Call_Unresolved,
      Expression_Type_Call_Ambiguous,
      Expression_Type_Operator_Numeric,
      Expression_Type_Operator_Boolean,
      Expression_Type_Operator_Concatenation,
      Expression_Type_Operator_Unknown,
      Expression_Type_Qualified,
      Expression_Type_Conversion,
      Expression_Type_Aggregate,
      Expression_Type_Attribute,
      Expression_Type_Dereference,
      Expression_Type_Allocator,
      Expression_Type_Raise,
      Expression_Type_No_Return_Call,
      Expression_Type_Indexed_Component,
      Expression_Type_Slice,
      Expression_Type_Indeterminate,
      Expression_Type_Malformed);

   type Expression_Type_Id is new Natural;
   No_Expression_Type : constant Expression_Type_Id := 0;

   type Expression_Type_Info is record
      Id                    : Expression_Type_Id := No_Expression_Type;
      Node                  : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Region                : Editor.Ada_Declarative_Regions.Region_Id :=
        Editor.Ada_Declarative_Regions.No_Region;
      Declaration           : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Type_Id               : Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.No_Type;
      Call_Resolution       : Editor.Ada_Call_Resolution.Call_Resolution_Id :=
        Editor.Ada_Call_Resolution.No_Call_Resolution;
      Selected_Name         : Editor.Ada_Selected_Name_Resolution.Selected_Name_Id :=
        Editor.Ada_Selected_Name_Resolution.No_Selected_Name;
      Selected_Name_Status  : Editor.Ada_Selected_Name_Resolution.Selected_Name_Status :=
        Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved;
      Cross_Unit_Selected_Target : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Selected_Path   : Ada.Strings.Unbounded.Unbounded_String;
      Cross_Unit_Selected_Selector : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Cross_Unit_Selected_Target : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Cross_Unit_Selected_Selector : Ada.Strings.Unbounded.Unbounded_String;
      Status                : Expression_Type_Status := Expression_Type_Not_Checked;
      Expression_Text       : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Text       : Ada.Strings.Unbounded.Unbounded_String;
      Inferred_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Subtype    : Ada.Strings.Unbounded.Unbounded_String;
      Static_Status         : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Expected_Context      : Editor.Ada_Expected_Type_Contexts.Expected_Context_Id :=
        Editor.Ada_Expected_Type_Contexts.No_Expected_Context;
      Expected_Status       : Expected_Type_Propagation_Status :=
        Expected_Type_Not_Checked;
      Expected_Subtype      : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Operator_Status       : Operator_Type_Inference_Status :=
        Operator_Type_Not_Checked;
      Operator_Symbol       : Ada.Strings.Unbounded.Unbounded_String;
      Left_Operand_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Right_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Left_Operand_Subtype  : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Right_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Operator_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Operator_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Operator_Compatible_Operand_Count : Natural := 0;
      Operator_Mismatched_Operand_Count : Natural := 0;
      Operator_Unknown_Operand_Count    : Natural := 0;
      Operator_Overload_Candidate_Count  : Natural := 0;
      Operator_Overload_Selected_Count   : Natural := 0;
      Operator_Overload_Ambiguous_Count  : Natural := 0;
      Operator_Overload_Mismatch_Count   : Natural := 0;
      Concatenation_Status : Concatenation_Type_Inference_Status :=
        Concatenation_Type_Not_Checked;
      Concatenation_Left_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Concatenation_Right_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Concatenation_Left_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Concatenation_Right_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Concatenation_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Concatenation_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Concatenation_Compatible_Count : Natural := 0;
      Concatenation_Mismatch_Count : Natural := 0;
      Concatenation_Unknown_Count : Natural := 0;
      Aggregate_Status      : Aggregate_Type_Inference_Status :=
        Aggregate_Type_Not_Checked;
      Aggregate_Element_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Aggregate_Element_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Aggregate_Index_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Aggregate_Index_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Aggregate_Component_Count : Natural := 0;
      Aggregate_Named_Association_Count : Natural := 0;
      Aggregate_Positional_Association_Count : Natural := 0;
      Aggregate_Record_Component_Compatible_Count : Natural := 0;
      Aggregate_Record_Component_Missing_Count : Natural := 0;
      Aggregate_Record_Component_Duplicate_Count : Natural := 0;
      Aggregate_Array_Element_Compatible_Count : Natural := 0;
      Aggregate_Array_Element_Mismatch_Count : Natural := 0;
      Aggregate_Array_Element_Unknown_Count : Natural := 0;
      Aggregate_Mismatch_Count : Natural := 0;
      Aggregate_Unknown_Count  : Natural := 0;
      Conversion_Status    : Conversion_Type_Inference_Status :=
        Conversion_Type_Not_Checked;
      Conversion_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Conversion_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Conversion_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Conversion_Operand_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Conversion_Compatible_Operand_Count : Natural := 0;
      Conversion_Explicit_Operand_Count   : Natural := 0;
      Conversion_Mismatched_Operand_Count : Natural := 0;
      Conversion_Unknown_Operand_Count    : Natural := 0;
      Conditional_Status : Conditional_Type_Inference_Status :=
        Conditional_Type_Not_Checked;
      Conditional_Branch_Count : Natural := 0;
      Conditional_Compatible_Branch_Count : Natural := 0;
      Conditional_Mismatched_Branch_Count : Natural := 0;
      Conditional_Unknown_Branch_Count : Natural := 0;
      Conditional_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Conditional_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Membership_Range_Status : Membership_Range_Inference_Status :=
        Membership_Range_Not_Checked;
      Membership_Test_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Membership_Test_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Membership_Choice_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Membership_Choice_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Range_Low_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Range_High_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Range_Low_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Range_High_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Membership_Compatible_Count : Natural := 0;
      Membership_Mismatch_Count : Natural := 0;
      Membership_Unknown_Count : Natural := 0;
      Range_Compatible_Count : Natural := 0;
      Range_Mismatch_Count : Natural := 0;
      Range_Unknown_Count : Natural := 0;
      Target_Name_Status : Target_Name_Inference_Status :=
        Target_Name_Not_Checked;
      Target_Name_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name_Source_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Target_Name_Source_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Target_Name_Compatible_Count : Natural := 0;
      Target_Name_Mismatch_Count : Natural := 0;
      Target_Name_Unknown_Count : Natural := 0;
      Delta_Update_Count : Natural := 0;
      Indexed_Slice_Status : Indexed_Slice_Inference_Status :=
        Indexed_Slice_Not_Checked;
      Indexed_Slice_Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Indexed_Slice_Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Indexed_Slice_Index_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Indexed_Slice_Index_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Indexed_Slice_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Indexed_Slice_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Indexed_Slice_Index_Count : Natural := 0;
      Indexed_Slice_Compatible_Index_Count : Natural := 0;
      Indexed_Slice_Mismatched_Index_Count : Natural := 0;
      Indexed_Slice_Unknown_Index_Count : Natural := 0;
      Boolean_Context_Status : Boolean_Context_Inference_Status :=
        Boolean_Context_Not_Checked;
      Boolean_Context_Expression_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Boolean_Context_Expression_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Boolean_Context_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Boolean_Context_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Boolean_Context_Compatible_Count : Natural := 0;
      Boolean_Context_Mismatch_Count : Natural := 0;
      Boolean_Context_Unknown_Count : Natural := 0;
      Dereference_Access_Status : Dereference_Access_Inference_Status :=
        Dereference_Access_Not_Checked;
      Dereference_Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dereference_Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Dereference_Designated_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dereference_Designated_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Access_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Access_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Access_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Access_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Allocator_Status : Allocator_Type_Inference_Status :=
        Allocator_Type_Not_Checked;
      Allocator_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Allocator_Target_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Allocator_Expected_Access_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Allocator_Expected_Access_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Allocator_Designated_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Allocator_Designated_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Allocator_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Allocator_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Raise_No_Return_Status : Raise_No_Return_Inference_Status :=
        Raise_No_Return_Not_Checked;
      Raise_Exception_Target : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Raise_Exception_Target : Ada.Strings.Unbounded.Unbounded_String;
      Raise_Message_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Raise_Message_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Raise_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Raise_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Universal_Numeric_Status : Universal_Numeric_Resolution_Status :=
        Universal_Numeric_Not_Checked;
      Universal_Numeric_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Universal_Numeric_Expected_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Universal_Numeric_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Universal_Numeric_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Universal_Numeric_Static_Status : Editor.Ada_Static_Expressions.Static_Value_Status :=
        Editor.Ada_Static_Expressions.Static_Value_Not_Checked;
      Universal_Numeric_Integer_Value : Long_Long_Integer := 0;
      Universal_Numeric_Real_Value : Long_Float := 0.0;
      Universal_Numeric_Has_Range : Boolean := False;
      Universal_Numeric_First_Value : Long_Long_Integer := 0;
      Universal_Numeric_Last_Value : Long_Long_Integer := 0;
      Parameter_Association_Status : Parameter_Association_Inference_Status :=
        Parameter_Association_Not_Checked;
      Call_Actual_Type_Status : Call_Actual_Type_Resolution_Status :=
        Call_Actual_Type_Not_Checked;
      Call_Actual_Type_Compatible_Count : Natural := 0;
      Call_Actual_Type_Mismatch_Count : Natural := 0;
      Call_Actual_Type_Unknown_Count : Natural := 0;
      Call_Actual_Type_Candidate_Count : Natural := 0;
      Call_Actual_Type_Selected_Declaration : Editor.Ada_Direct_Visibility.Declaration_Id :=
        Editor.Ada_Direct_Visibility.No_Declaration;
      Dispatching_Call_Status : Dispatching_Call_Inference_Status :=
        Dispatching_Call_Not_Checked;
      Dispatching_Call_Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dispatching_Call_Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Dispatching_Call_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Dispatching_Call_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Dispatching_Call_Primitive_Count : Natural := 0;
      Dispatching_Call_Controlling_Operand_Count : Natural := 0;
      Dispatching_Call_Controlling_Result_Count : Natural := 0;
      Dispatching_Call_Ambiguous_Count : Natural := 0;
      Dispatching_Call_Unknown_Count : Natural := 0;
      Parameter_Association_Call : Editor.Ada_Syntax_Tree.Node_Id :=
        Editor.Ada_Syntax_Tree.No_Node;
      Parameter_Association_Position : Natural := 0;
      Parameter_Association_Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Parameter_Association_Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Parameter_Association_Formal_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Parameter_Association_Formal_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Parameter_Association_Actual_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Parameter_Association_Actual_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Status    : Attribute_Type_Inference_Status :=
        Attribute_Type_Not_Checked;
      Attribute_Name      : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Prefix    : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Attribute_Name : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Attribute_Prefix : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Normalized_Attribute_Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Attribute_Prefix_Type : Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.No_Type;
      Attribute_Static_Result_Count : Natural := 0;
      Attribute_String_Result_Count : Natural := 0;
      Attribute_Unknown_Count       : Natural := 0;
      Candidate_Count       : Natural := 0;
      Start_Line            : Positive := 1;
      End_Line              : Positive := 1;
      Fingerprint           : Natural := 0;
   end record;

   type Expression_Type_Model is private;

   procedure Clear (Model : in out Expression_Type_Model);

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expression_Type_Model;

   function Build_With_Expected_Contexts
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model;

   function Build_With_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model;

   function Build_With_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model;


   function Build_With_Cross_Unit_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model;

   function Build_With_Cross_Unit_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model;

   function Build_With_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model;

   function Build_With_Project_Cross_Unit_Selected_Names_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Index      : Editor.Ada_Project_Index.Index_State)
      return Expression_Type_Model;

   function Build_With_Operator_Uses
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model)
      return Expression_Type_Model;

   function Build_With_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model;

   function Has_Expression_Types (Model : Expression_Type_Model) return Boolean;
   function Expression_Type_Count (Model : Expression_Type_Model) return Natural;
   function Expression_Type_At
     (Model : Expression_Type_Model;
      Index : Positive) return Expression_Type_Info;
   function Expression_Type
     (Model : Expression_Type_Model;
      Id    : Expression_Type_Id) return Expression_Type_Info;
   function Expression_Type_For_Node
     (Model : Expression_Type_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Type_Info;

   function Count_Status
     (Model  : Expression_Type_Model;
      Status : Expression_Type_Status) return Natural;
   function Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Unresolved_Count (Model : Expression_Type_Model) return Natural;
   function Ambiguous_Count (Model : Expression_Type_Model) return Natural;
   function Static_Numeric_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Cross_Unit_Selected_Name_Count (Model : Expression_Type_Model) return Natural;
   function Cross_Unit_Selected_Name_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Cross_Unit_Selected_Name_Limited_Count (Model : Expression_Type_Model) return Natural;
   function Cross_Unit_Selected_Name_Private_Count (Model : Expression_Type_Model) return Natural;
   function Cross_Unit_Selected_Name_Unresolved_Count (Model : Expression_Type_Model) return Natural;
   function Expected_Context_Count (Model : Expression_Type_Model) return Natural;
   function Expected_Propagated_Count (Model : Expression_Type_Model) return Natural;
   function Expected_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Expected_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Operand_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Operand_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Ambiguous_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Overload_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Overload_Ambiguous_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Overload_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Operator_Overload_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Concatenation_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Concatenation_String_Result_Count (Model : Expression_Type_Model) return Natural;
   function Concatenation_Array_Result_Count (Model : Expression_Type_Model) return Natural;
   function Concatenation_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Concatenation_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Context_Required_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Context_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Record_Component_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Record_Component_Missing_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Record_Component_Duplicate_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Array_Element_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Array_Element_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Array_Element_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Aggregate_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Conversion_Target_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Conversion_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Conversion_Explicit_Count (Model : Expression_Type_Model) return Natural;
   function Conversion_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Conversion_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Conditional_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Conditional_Branch_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Conditional_Branch_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Conditional_Reduction_Count (Model : Expression_Type_Model) return Natural;
   function Conditional_Declare_Count (Model : Expression_Type_Model) return Natural;
   function Membership_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Membership_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Membership_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Range_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Range_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Range_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Target_Name_Context_Propagated_Count (Model : Expression_Type_Model) return Natural;
   function Target_Name_Context_Required_Count (Model : Expression_Type_Model) return Natural;
   function Target_Name_Update_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Target_Name_Update_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Target_Name_Update_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Prefix_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Index_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Index_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Index_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Result_Element_Count (Model : Expression_Type_Model) return Natural;
   function Indexed_Slice_Result_Array_Count (Model : Expression_Type_Model) return Natural;
   function Dereference_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Dereference_Target_Error_Count (Model : Expression_Type_Model) return Natural;
   function Dereference_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Access_Result_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Access_Result_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Allocator_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Allocator_Target_Error_Count (Model : Expression_Type_Model) return Natural;
   function Allocator_Designated_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Allocator_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Universal_Numeric_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Universal_Numeric_Range_Error_Count (Model : Expression_Type_Model) return Natural;
   function Universal_Numeric_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Universal_Numeric_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Boolean_Context_Count (Model : Expression_Type_Model) return Natural;
   function Boolean_Context_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Boolean_Context_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Boolean_Context_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Raise_Expression_Count (Model : Expression_Type_Model) return Natural;
   function Raise_No_Return_Count (Model : Expression_Type_Model) return Natural;
   function Raise_Message_Count (Model : Expression_Type_Model) return Natural;
   function Raise_Unknown_Count (Model : Expression_Type_Model) return Natural;

   function Call_Actual_Type_Compatible_Count (Model : Expression_Type_Model) return Natural;
   function Call_Actual_Type_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Call_Actual_Type_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Call_Actual_Type_Ambiguous_Count (Model : Expression_Type_Model) return Natural;
   function Dispatching_Call_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Dispatching_Call_Dynamic_Count (Model : Expression_Type_Model) return Natural;
   function Dispatching_Call_Static_Count (Model : Expression_Type_Model) return Natural;
   function Dispatching_Call_Ambiguous_Count (Model : Expression_Type_Model) return Natural;
   function Dispatching_Call_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Parameter_Association_Context_Count (Model : Expression_Type_Model) return Natural;
   function Parameter_Association_Propagated_Count (Model : Expression_Type_Model) return Natural;
   function Parameter_Association_Mismatch_Count (Model : Expression_Type_Model) return Natural;
   function Parameter_Association_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Attribute_Resolved_Count (Model : Expression_Type_Model) return Natural;
   function Attribute_Static_Result_Count (Model : Expression_Type_Model) return Natural;
   function Attribute_String_Result_Count (Model : Expression_Type_Model) return Natural;
   function Attribute_Unknown_Count (Model : Expression_Type_Model) return Natural;
   function Attribute_Prefix_Unresolved_Count (Model : Expression_Type_Model) return Natural;
   function Fingerprint (Model : Expression_Type_Model) return Natural;

private
   package Expression_Type_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Expression_Type_Info);

   type Expression_Type_Model is record
      Expressions        : Expression_Type_Vectors.Vector;
      Result_Fingerprint : Natural := 0;
   end record;

end Editor.Ada_Expression_Types;
