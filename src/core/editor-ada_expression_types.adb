with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Use_Type_Operators;

package body Editor.Ada_Expression_Types is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
   use type Editor.Ada_Direct_Visibility.Lookup_Status;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
   use type Editor.Ada_Selected_Name_Resolution.Selected_Name_Status;
   use type Editor.Ada_Static_Expressions.Static_Value_Status;
   use type Editor.Ada_Static_Expressions.Static_Modular_Type_Id;
   use type Editor.Ada_Static_Expressions.Static_Fixed_Type_Id;
   use type Editor.Ada_Syntax_Tree.Node_Kind;
   use type Editor.Ada_Declarative_Regions.Region_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Direct_Visibility.Declaration_Kind;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Type_Graph.Compatibility_Status;
   use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;
   function To_String (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function Trim (Text : String) return String is
     (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

   function Normalize (Text : String) return String is
      T : constant String := Trim (Text);
      R : String (T'Range) := T;
   begin
      for I in R'Range loop
         R (I) := Ada.Characters.Handling.To_Lower (R (I));
      end loop;
      return R;
   end Normalize;

   function Contains (Text : String; Pattern : String) return Boolean is
   begin
      return Pattern /= "" and then Ada.Strings.Fixed.Index (Text, Pattern) /= 0;
   end Contains;

   function Hash_Mix
     (Seed       : Natural;
      Addend     : Long_Long_Integer;
      Multiplier : Long_Long_Integer := 131) return Natural
   is
   begin
      return Natural
        ((Long_Long_Integer (Seed) * Multiplier + Addend) mod 2_147_483_647);
   end Hash_Mix;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result := Hash_Mix (Result, Long_Long_Integer (Character'Pos (C)));
      end loop;
      return Result;
   end Hash_Text;

   function Conditional_Status_Text
     (Status : Conditional_Type_Inference_Status) return String is
   begin
      case Status is
         when Conditional_Type_Not_Checked => return "conditional_not_checked";
         when Conditional_Type_Not_Conditional => return "conditional_not_conditional";
         when Conditional_Type_Expected_Context => return "conditional_expected_context";
         when Conditional_Type_Branches_Compatible => return "conditional_branches_compatible";
         when Conditional_Type_Branch_Mismatch => return "conditional_branch_mismatch";
         when Conditional_Type_Branch_Unknown => return "conditional_branch_unknown";
         when Conditional_Type_Boolean_Result => return "conditional_boolean_result";
         when Conditional_Type_Reduction_Result => return "conditional_reduction_result";
         when Conditional_Type_Declare_Result => return "conditional_declare_result";
      end case;
   end Conditional_Status_Text;


   function Membership_Range_Status_Text
     (Status : Membership_Range_Inference_Status) return String is
   begin
      case Status is
         when Membership_Range_Not_Checked => return "membership_range_not_checked";
         when Membership_Range_Not_Membership_Or_Range => return "membership_range_not_membership_or_range";
         when Membership_Range_Membership_Compatible => return "membership_compatible";
         when Membership_Range_Membership_Mismatch => return "membership_mismatch";
         when Membership_Range_Membership_Unknown => return "membership_unknown";
         when Membership_Range_Range_Compatible => return "range_compatible";
         when Membership_Range_Range_Mismatch => return "range_mismatch";
         when Membership_Range_Range_Unknown => return "range_unknown";
         when Membership_Range_Boolean_Result => return "membership_range_boolean_result";
      end case;
   end Membership_Range_Status_Text;


   function Target_Name_Status_Text
     (Status : Target_Name_Inference_Status) return String is
   begin
      case Status is
         when Target_Name_Not_Checked => return "target_name_not_checked";
         when Target_Name_Not_Target_Name_Or_Update => return "target_name_not_target_name_or_update";
         when Target_Name_Context_Required => return "target_name_context_required";
         when Target_Name_Context_Propagated => return "target_name_context_propagated";
         when Target_Name_Delta_Update_Compatible => return "target_name_delta_update_compatible";
         when Target_Name_Delta_Update_Mismatch => return "target_name_delta_update_mismatch";
         when Target_Name_Delta_Update_Unknown => return "target_name_delta_update_unknown";
      end case;
   end Target_Name_Status_Text;


   function Indexed_Slice_Status_Text
     (Status : Indexed_Slice_Inference_Status) return String is
   begin
      case Status is
         when Indexed_Slice_Not_Checked => return "indexed_slice_not_checked";
         when Indexed_Slice_Not_Indexed_Or_Slice => return "indexed_slice_not_indexed_or_slice";
         when Indexed_Slice_Prefix_Resolved => return "indexed_slice_prefix_resolved";
         when Indexed_Slice_Prefix_Unresolved => return "indexed_slice_prefix_unresolved";
         when Indexed_Slice_Index_Compatible => return "indexed_slice_index_compatible";
         when Indexed_Slice_Index_Mismatch => return "indexed_slice_index_mismatch";
         when Indexed_Slice_Index_Unknown => return "indexed_slice_index_unknown";
         when Indexed_Slice_Result_Element => return "indexed_slice_result_element";
         when Indexed_Slice_Result_Array => return "indexed_slice_result_array";
         when Indexed_Slice_Result_Unknown => return "indexed_slice_result_unknown";
      end case;
   end Indexed_Slice_Status_Text;



   function Boolean_Context_Status_Text
     (Status : Boolean_Context_Inference_Status) return String is
   begin
      case Status is
         when Boolean_Context_Not_Checked => return "boolean_context_not_checked";
         when Boolean_Context_Not_Boolean_Context => return "boolean_context_not_boolean_context";
         when Boolean_Context_Expected_Boolean => return "boolean_context_expected_boolean";
         when Boolean_Context_Operand_Compatible => return "boolean_context_operand_compatible";
         when Boolean_Context_Operand_Mismatch => return "boolean_context_operand_mismatch";
         when Boolean_Context_Operand_Unknown => return "boolean_context_operand_unknown";
         when Boolean_Context_Short_Circuit_Compatible => return "boolean_context_short_circuit_compatible";
         when Boolean_Context_Short_Circuit_Mismatch => return "boolean_context_short_circuit_mismatch";
         when Boolean_Context_Condition_Compatible => return "boolean_context_condition_compatible";
         when Boolean_Context_Condition_Mismatch => return "boolean_context_condition_mismatch";
         when Boolean_Context_Condition_Unknown => return "boolean_context_condition_unknown";
      end case;
   end Boolean_Context_Status_Text;

   function Raise_No_Return_Status_Text
     (Status : Raise_No_Return_Inference_Status) return String is
   begin
      case Status is
         when Raise_No_Return_Not_Checked => return "raise_no_return_not_checked";
         when Raise_No_Return_Not_Raise => return "raise_no_return_not_raise";
         when Raise_No_Return_Raise_Expression => return "raise_expression";
         when Raise_No_Return_Raise_Statement => return "raise_statement";
         when Raise_No_Return_Exception_Target_Known => return "raise_exception_target_known";
         when Raise_No_Return_Exception_Target_Unknown => return "raise_exception_target_unknown";
         when Raise_No_Return_With_Message => return "raise_with_message";
         when Raise_No_Return_Message_Unknown => return "raise_message_unknown";
         when Raise_No_Return_No_Return_Call => return "no_return_call";
         when Raise_No_Return_Result_Context_Propagated => return "raise_result_context_propagated";
         when Raise_No_Return_Result_Context_Unknown => return "raise_result_context_unknown";
      end case;
   end Raise_No_Return_Status_Text;


   function Allocator_Status_Text
     (Status : Allocator_Type_Inference_Status) return String is
   begin
      case Status is
         when Allocator_Type_Not_Checked => return "allocator_not_checked";
         when Allocator_Type_Not_Allocator => return "allocator_not_allocator";
         when Allocator_Type_Target_Resolved => return "allocator_target_resolved";
         when Allocator_Type_Target_Unresolved => return "allocator_target_unresolved";
         when Allocator_Type_Malformed => return "allocator_malformed";
         when Allocator_Type_Expected_Access_Context => return "allocator_expected_access_context";
         when Allocator_Type_Expected_Not_Access => return "allocator_expected_not_access";
         when Allocator_Type_Designated_Compatible => return "allocator_designated_compatible";
         when Allocator_Type_Designated_Mismatch => return "allocator_designated_mismatch";
         when Allocator_Type_Designated_Unknown => return "allocator_designated_unknown";
         when Allocator_Type_Result_Known => return "allocator_result_known";
         when Allocator_Type_Result_Unknown => return "allocator_result_unknown";
      end case;
   end Allocator_Status_Text;




   function Universal_Numeric_Status_Text
     (Status : Universal_Numeric_Resolution_Status) return String is
   begin
      case Status is
         when Universal_Numeric_Not_Checked => return "universal_numeric_not_checked";
         when Universal_Numeric_Not_Universal => return "universal_numeric_not_universal";
         when Universal_Numeric_Expected_Context_Found => return "universal_numeric_expected_context_found";
         when Universal_Numeric_Integer_Resolved => return "universal_numeric_integer_resolved";
         when Universal_Numeric_Real_Resolved => return "universal_numeric_real_resolved";
         when Universal_Numeric_Modular_Resolved => return "universal_numeric_modular_resolved";
         when Universal_Numeric_Fixed_Resolved => return "universal_numeric_fixed_resolved";
         when Universal_Numeric_Range_Compatible => return "universal_numeric_range_compatible";
         when Universal_Numeric_Range_Error => return "universal_numeric_range_error";
         when Universal_Numeric_Expected_Mismatch => return "universal_numeric_expected_mismatch";
         when Universal_Numeric_Static_Unknown => return "universal_numeric_static_unknown";
      end case;
   end Universal_Numeric_Status_Text;



   function Dispatching_Call_Status_Text
     (Status : Dispatching_Call_Inference_Status) return String is
   begin
      case Status is
         when Dispatching_Call_Not_Checked => return "dispatching_call_not_checked";
         when Dispatching_Call_Not_Call => return "dispatching_call_not_call";
         when Dispatching_Call_Primitive_Target => return "dispatching_call_primitive_target";
         when Dispatching_Call_Class_Wide_Controlling_Operand => return "dispatching_call_class_wide_controlling_operand";
         when Dispatching_Call_Controlling_Result => return "dispatching_call_controlling_result";
         when Dispatching_Call_Static_Binding => return "dispatching_call_static_binding";
         when Dispatching_Call_Dynamic_Dispatch => return "dispatching_call_dynamic_dispatch";
         when Dispatching_Call_Target_Unresolved => return "dispatching_call_target_unresolved";
         when Dispatching_Call_Target_Ambiguous => return "dispatching_call_target_ambiguous";
         when Dispatching_Call_Controlling_Unknown => return "dispatching_call_controlling_unknown";
      end case;
   end Dispatching_Call_Status_Text;

   function Call_Actual_Type_Status_Text
     (Status : Call_Actual_Type_Resolution_Status) return String is
   begin
      case Status is
         when Call_Actual_Type_Not_Checked => return "call_actual_type_not_checked";
         when Call_Actual_Type_Not_Call => return "call_actual_type_not_call";
         when Call_Actual_Type_Unresolved_Call => return "call_actual_type_unresolved_call";
         when Call_Actual_Type_Ambiguous_Call => return "call_actual_type_ambiguous_call";
         when Call_Actual_Type_Profile_Unavailable => return "call_actual_type_profile_unavailable";
         when Call_Actual_Type_All_Compatible => return "call_actual_type_all_compatible";
         when Call_Actual_Type_Actual_Mismatch => return "call_actual_type_actual_mismatch";
         when Call_Actual_Type_Actual_Unknown => return "call_actual_type_actual_unknown";
      end case;
   end Call_Actual_Type_Status_Text;

   function Parameter_Association_Status_Text
     (Status : Parameter_Association_Inference_Status) return String is
   begin
      case Status is
         when Parameter_Association_Not_Checked => return "parameter_association_not_checked";
         when Parameter_Association_Not_Parameter => return "parameter_association_not_parameter";
         when Parameter_Association_Formal_Context_Found => return "parameter_association_formal_context_found";
         when Parameter_Association_Formal_Context_Unresolved => return "parameter_association_formal_context_unresolved";
         when Parameter_Association_Formal_Context_Ambiguous => return "parameter_association_formal_context_ambiguous";
         when Parameter_Association_Expected_Propagated => return "parameter_association_expected_propagated";
         when Parameter_Association_Compatible => return "parameter_association_compatible";
         when Parameter_Association_Mismatch => return "parameter_association_mismatch";
         when Parameter_Association_Unknown => return "parameter_association_unknown";
      end case;
   end Parameter_Association_Status_Text;


   function Dereference_Access_Status_Text
     (Status : Dereference_Access_Inference_Status) return String is
   begin
      case Status is
         when Dereference_Access_Not_Checked => return "dereference_access_not_checked";
         when Dereference_Access_Not_Dereference_Or_Access => return "dereference_access_not_dereference_or_access";
         when Dereference_Prefix_Resolved => return "dereference_prefix_resolved";
         when Dereference_Prefix_Unresolved => return "dereference_prefix_unresolved";
         when Dereference_Prefix_Not_Access_Type => return "dereference_prefix_not_access_type";
         when Dereference_Designated_Subtype_Known => return "dereference_designated_subtype_known";
         when Dereference_Designated_Subtype_Unknown => return "dereference_designated_subtype_unknown";
         when Access_Attribute_Target_Resolved => return "access_attribute_target_resolved";
         when Access_Attribute_Target_Unresolved => return "access_attribute_target_unresolved";
         when Access_Attribute_Result_Known => return "access_attribute_result_known";
         when Access_Attribute_Result_Unknown => return "access_attribute_result_unknown";
      end case;
   end Dereference_Access_Status_Text;


   function Attribute_Status_Text
     (Status : Attribute_Type_Inference_Status) return String is
   begin
      case Status is
         when Attribute_Type_Not_Checked => return "attribute_not_checked";
         when Attribute_Type_Not_Attribute => return "attribute_not_attribute";
         when Attribute_Type_Scalar_Bound => return "attribute_scalar_bound";
         when Attribute_Type_Range_Bound => return "attribute_range_bound";
         when Attribute_Type_Integer_Result => return "attribute_integer_result";
         when Attribute_Type_Boolean_Result => return "attribute_boolean_result";
         when Attribute_Type_String_Result => return "attribute_string_result";
         when Attribute_Type_Address_Result => return "attribute_address_result";
         when Attribute_Type_Size_Result => return "attribute_size_result";
         when Attribute_Type_Value_Result => return "attribute_value_result";
         when Attribute_Type_Callable_Result => return "attribute_callable_result";
         when Attribute_Type_Prefix_Unresolved => return "attribute_prefix_unresolved";
         when Attribute_Type_Unknown_Attribute => return "attribute_unknown_attribute";
         when Attribute_Type_Malformed => return "attribute_malformed";
      end case;
   end Attribute_Status_Text;

   function Operator_Status_Text
     (Status : Operator_Type_Inference_Status) return String is
   begin
      case Status is
         when Operator_Type_Not_Checked => return "operator_not_checked";
         when Operator_Type_Not_Operator => return "operator_not_operator";
         when Operator_Type_Resolved_Predefined => return "operator_resolved_predefined";
         when Operator_Type_Resolved_Visible => return "operator_resolved_visible";
         when Operator_Type_Ambiguous => return "operator_ambiguous";
         when Operator_Type_Operand_Mismatch => return "operator_operand_mismatch";
         when Operator_Type_Operand_Unknown => return "operator_operand_unknown";
         when Operator_Type_Result_Unknown => return "operator_result_unknown";
         when Operator_Type_Overload_Resolved => return "operator_overload_resolved";
         when Operator_Type_Overload_Ambiguous => return "operator_overload_ambiguous";
         when Operator_Type_Overload_Mismatch => return "operator_overload_mismatch";
         when Operator_Type_Overload_Unknown => return "operator_overload_unknown";
      end case;
   end Operator_Status_Text;


   function Concatenation_Status_Text
     (Status : Concatenation_Type_Inference_Status) return String is
   begin
      case Status is
         when Concatenation_Type_Not_Checked => return "concatenation_not_checked";
         when Concatenation_Type_Not_Concatenation => return "concatenation_not_concatenation";
         when Concatenation_Type_String_Compatible => return "concatenation_string_compatible";
         when Concatenation_Type_Array_Compatible => return "concatenation_array_compatible";
         when Concatenation_Type_Character_String_Compatible => return "concatenation_character_string_compatible";
         when Concatenation_Type_Expected_Context_Result => return "concatenation_expected_context_result";
         when Concatenation_Type_Operand_Mismatch => return "concatenation_operand_mismatch";
         when Concatenation_Type_Operand_Unknown => return "concatenation_operand_unknown";
         when Concatenation_Type_Result_Unknown => return "concatenation_result_unknown";
      end case;
   end Concatenation_Status_Text;

   function Aggregate_Status_Text
     (Status : Aggregate_Type_Inference_Status) return String is
   begin
      case Status is
         when Aggregate_Type_Not_Checked => return "aggregate_not_checked";
         when Aggregate_Type_Not_Aggregate => return "aggregate_not_aggregate";
         when Aggregate_Type_Context_Required => return "aggregate_context_required";
         when Aggregate_Type_Array_Context => return "aggregate_array_context";
         when Aggregate_Type_Record_Context => return "aggregate_record_context";
         when Aggregate_Type_Container_Context => return "aggregate_container_context";
         when Aggregate_Type_Delta_Context => return "aggregate_delta_context";
         when Aggregate_Type_Record_Components_Compatible => return "aggregate_record_components_compatible";
         when Aggregate_Type_Record_Component_Missing => return "aggregate_record_component_missing";
         when Aggregate_Type_Record_Component_Duplicate => return "aggregate_record_component_duplicate";
         when Aggregate_Type_Array_Elements_Compatible => return "aggregate_array_elements_compatible";
         when Aggregate_Type_Array_Element_Mismatch => return "aggregate_array_element_mismatch";
         when Aggregate_Type_Array_Element_Unknown => return "aggregate_array_element_unknown";
         when Aggregate_Type_Compatible => return "aggregate_compatible";
         when Aggregate_Type_Mismatch => return "aggregate_mismatch";
         when Aggregate_Type_Unknown => return "aggregate_unknown";
      end case;
   end Aggregate_Status_Text;


   function Conversion_Status_Text
     (Status : Conversion_Type_Inference_Status) return String is
   begin
      case Status is
         when Conversion_Type_Not_Checked => return "conversion_not_checked";
         when Conversion_Type_Not_Conversion => return "conversion_not_conversion";
         when Conversion_Type_Target_Resolved => return "conversion_target_resolved";
         when Conversion_Type_Target_Unresolved => return "conversion_target_unresolved";
         when Conversion_Type_Target_Ambiguous => return "conversion_target_ambiguous";
         when Conversion_Type_Operand_Compatible => return "conversion_operand_compatible";
         when Conversion_Type_Operand_Requires_Explicit_Conversion => return "conversion_operand_requires_explicit_conversion";
         when Conversion_Type_Operand_Mismatch => return "conversion_operand_mismatch";
         when Conversion_Type_Operand_Unknown => return "conversion_operand_unknown";
         when Conversion_Type_Malformed => return "conversion_malformed";
      end case;
   end Conversion_Status_Text;

   function Expected_Status_Text
     (Status : Expected_Type_Propagation_Status) return String is
   begin
      case Status is
         when Expected_Type_Not_Checked => return "expected_not_checked";
         when Expected_Type_No_Context => return "expected_no_context";
         when Expected_Type_Context_Found => return "expected_context_found";
         when Expected_Type_Propagated => return "expected_propagated";
         when Expected_Type_Compatible => return "expected_compatible";
         when Expected_Type_Mismatch => return "expected_mismatch";
         when Expected_Type_Unknown => return "expected_unknown";
      end case;
   end Expected_Status_Text;

   function Status_Text (Status : Expression_Type_Status) return String is
   begin
      case Status is
         when Expression_Type_Not_Checked => return "not_checked";
         when Expression_Type_Static_Integer => return "static_integer";
         when Expression_Type_Static_Real => return "static_real";
         when Expression_Type_String_Literal => return "string_literal";
         when Expression_Type_Boolean_Literal => return "boolean_literal";
         when Expression_Type_Null_Literal => return "null_literal";
         when Expression_Type_Name_Resolved => return "name_resolved";
         when Expression_Type_Name_Unresolved => return "name_unresolved";
         when Expression_Type_Name_Ambiguous => return "name_ambiguous";
         when Expression_Type_Selected_Name_Resolved => return "selected_name_resolved";
         when Expression_Type_Selected_Name_Unresolved => return "selected_name_unresolved";
         when Expression_Type_Selected_Name_Cross_Unit_Resolved => return "selected_name_cross_unit_resolved";
         when Expression_Type_Selected_Name_Cross_Unit_Limited => return "selected_name_cross_unit_limited";
         when Expression_Type_Selected_Name_Cross_Unit_Private => return "selected_name_cross_unit_private";
         when Expression_Type_Selected_Name_Cross_Unit_Unresolved => return "selected_name_cross_unit_unresolved";
         when Expression_Type_Call_Resolved => return "call_resolved";
         when Expression_Type_Call_Unresolved => return "call_unresolved";
         when Expression_Type_Call_Ambiguous => return "call_ambiguous";
         when Expression_Type_Operator_Numeric => return "operator_numeric";
         when Expression_Type_Operator_Boolean => return "operator_boolean";
         when Expression_Type_Operator_Concatenation => return "operator_concatenation";
         when Expression_Type_Operator_Unknown => return "operator_unknown";
         when Expression_Type_Qualified => return "qualified";
         when Expression_Type_Conversion => return "conversion";
         when Expression_Type_Aggregate => return "aggregate";
         when Expression_Type_Attribute => return "attribute";
         when Expression_Type_Dereference => return "dereference";
         when Expression_Type_Allocator => return "allocator";
         when Expression_Type_Raise => return "raise";
         when Expression_Type_No_Return_Call => return "no_return_call";
         when Expression_Type_Indexed_Component => return "indexed_component";
         when Expression_Type_Slice => return "slice";
         when Expression_Type_Indeterminate => return "indeterminate";
         when Expression_Type_Malformed => return "malformed";
      end case;
   end Status_Text;

   function Fingerprint_For (Info : Expression_Type_Info) return Natural is
   begin
      return Hash_Text
        (Natural'Image (Natural (Info.Node)) & ":" &
         Status_Text (Info.Status) & ":" &
         To_String (Info.Normalized_Text) & ":" &
         To_String (Info.Normalized_Subtype) & ":" &
         Natural'Image (Natural (Info.Selected_Name)) & ":" &
         Editor.Ada_Selected_Name_Resolution.Selected_Name_Status'Image (Info.Selected_Name_Status) & ":" &
         To_String (Info.Normalized_Cross_Unit_Selected_Target) & ":" &
         To_String (Info.Normalized_Cross_Unit_Selected_Selector) & ":" &
         Expected_Status_Text (Info.Expected_Status) & ":" &
         To_String (Info.Normalized_Expected_Subtype) & ":" &
         Operator_Status_Text (Info.Operator_Status) & ":" &
         To_String (Info.Operator_Symbol) & ":" &
         To_String (Info.Normalized_Left_Operand_Subtype) & ":" &
         To_String (Info.Normalized_Right_Operand_Subtype) & ":" &
         To_String (Info.Normalized_Operator_Result_Subtype) & ":" &
         Natural'Image (Info.Operator_Compatible_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Mismatched_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Unknown_Operand_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Candidate_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Selected_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Ambiguous_Count) & ":" &
         Natural'Image (Info.Operator_Overload_Mismatch_Count) & ":" &
         Concatenation_Status_Text (Info.Concatenation_Status) & ":" &
         To_String (Info.Normalized_Concatenation_Left_Subtype) & ":" &
         To_String (Info.Normalized_Concatenation_Right_Subtype) & ":" &
         To_String (Info.Normalized_Concatenation_Result_Subtype) & ":" &
         Natural'Image (Info.Concatenation_Compatible_Count) & ":" &
         Natural'Image (Info.Concatenation_Mismatch_Count) & ":" &
         Natural'Image (Info.Concatenation_Unknown_Count) & ":" &
         Aggregate_Status_Text (Info.Aggregate_Status) & ":" &
         To_String (Info.Normalized_Aggregate_Element_Subtype) & ":" &
         To_String (Info.Normalized_Aggregate_Index_Subtype) & ":" &
         Natural'Image (Info.Aggregate_Component_Count) & ":" &
         Natural'Image (Info.Aggregate_Named_Association_Count) & ":" &
         Natural'Image (Info.Aggregate_Positional_Association_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Compatible_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Missing_Count) & ":" &
         Natural'Image (Info.Aggregate_Record_Component_Duplicate_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Compatible_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Mismatch_Count) & ":" &
         Natural'Image (Info.Aggregate_Array_Element_Unknown_Count) & ":" &
         Natural'Image (Info.Aggregate_Mismatch_Count) & ":" &
         Natural'Image (Info.Aggregate_Unknown_Count) & ":" &
         Conversion_Status_Text (Info.Conversion_Status) & ":" &
         To_String (Info.Normalized_Conversion_Target_Subtype) & ":" &
         To_String (Info.Normalized_Conversion_Operand_Subtype) & ":" &
         Natural'Image (Info.Conversion_Compatible_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Explicit_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Mismatched_Operand_Count) & ":" &
         Natural'Image (Info.Conversion_Unknown_Operand_Count) & ":" &
         Conditional_Status_Text (Info.Conditional_Status) & ":" &
         Natural'Image (Info.Conditional_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Compatible_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Mismatched_Branch_Count) & ":" &
         Natural'Image (Info.Conditional_Unknown_Branch_Count) & ":" &
         To_String (Info.Normalized_Conditional_Result_Subtype) & ":" &
         Membership_Range_Status_Text (Info.Membership_Range_Status) & ":" &
         To_String (Info.Normalized_Membership_Test_Subtype) & ":" &
         To_String (Info.Normalized_Membership_Choice_Subtype) & ":" &
         To_String (Info.Normalized_Range_Low_Subtype) & ":" &
         To_String (Info.Normalized_Range_High_Subtype) & ":" &
         Natural'Image (Info.Membership_Compatible_Count) & ":" &
         Natural'Image (Info.Membership_Mismatch_Count) & ":" &
         Natural'Image (Info.Membership_Unknown_Count) & ":" &
         Natural'Image (Info.Range_Compatible_Count) & ":" &
         Natural'Image (Info.Range_Mismatch_Count) & ":" &
         Natural'Image (Info.Range_Unknown_Count) & ":" &
         Target_Name_Status_Text (Info.Target_Name_Status) & ":" &
         To_String (Info.Normalized_Target_Name_Expected_Subtype) & ":" &
         To_String (Info.Normalized_Target_Name_Source_Subtype) & ":" &
         Natural'Image (Info.Target_Name_Compatible_Count) & ":" &
         Natural'Image (Info.Target_Name_Mismatch_Count) & ":" &
         Natural'Image (Info.Target_Name_Unknown_Count) & ":" &
         Natural'Image (Info.Delta_Update_Count) & ":" &
         Indexed_Slice_Status_Text (Info.Indexed_Slice_Status) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Prefix_Subtype) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Index_Subtype) & ":" &
         To_String (Info.Normalized_Indexed_Slice_Result_Subtype) & ":" &
         Natural'Image (Info.Indexed_Slice_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Compatible_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Mismatched_Index_Count) & ":" &
         Natural'Image (Info.Indexed_Slice_Unknown_Index_Count) & ":" &
         Boolean_Context_Status_Text (Info.Boolean_Context_Status) & ":" &
         To_String (Info.Normalized_Boolean_Context_Expression_Subtype) & ":" &
         To_String (Info.Normalized_Boolean_Context_Expected_Subtype) & ":" &
         Natural'Image (Info.Boolean_Context_Compatible_Count) & ":" &
         Natural'Image (Info.Boolean_Context_Mismatch_Count) & ":" &
         Natural'Image (Info.Boolean_Context_Unknown_Count) & ":" &
         Dereference_Access_Status_Text (Info.Dereference_Access_Status) & ":" &
         To_String (Info.Normalized_Dereference_Prefix_Subtype) & ":" &
         To_String (Info.Normalized_Dereference_Designated_Subtype) & ":" &
         To_String (Info.Normalized_Access_Target_Subtype) & ":" &
         To_String (Info.Normalized_Access_Result_Subtype) & ":" &
         Allocator_Status_Text (Info.Allocator_Status) & ":" &
         To_String (Info.Normalized_Allocator_Target_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Expected_Access_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Designated_Subtype) & ":" &
         To_String (Info.Normalized_Allocator_Result_Subtype) & ":" &
         Raise_No_Return_Status_Text (Info.Raise_No_Return_Status) & ":" &
         To_String (Info.Normalized_Raise_Exception_Target) & ":" &
         To_String (Info.Normalized_Raise_Message_Subtype) & ":" &
         To_String (Info.Normalized_Raise_Result_Subtype) & ":" &
        Universal_Numeric_Status_Text (Info.Universal_Numeric_Status) & ":" &
        To_String (Info.Normalized_Universal_Numeric_Expected_Subtype) & ":" &
        To_String (Info.Normalized_Universal_Numeric_Result_Subtype) & ":" &
        Editor.Ada_Static_Expressions.Static_Value_Status'Image
          (Info.Universal_Numeric_Static_Status) & ":" &
        Long_Long_Integer'Image (Info.Universal_Numeric_Integer_Value) & ":" &
        Long_Float'Image (Info.Universal_Numeric_Real_Value) & ":" &
         Call_Actual_Type_Status_Text (Info.Call_Actual_Type_Status) & ":" &
         Natural'Image (Info.Call_Actual_Type_Compatible_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Mismatch_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Unknown_Count) & ":" &
         Natural'Image (Info.Call_Actual_Type_Candidate_Count) & ":" &
         Dispatching_Call_Status_Text (Info.Dispatching_Call_Status) & ":" &
         To_String (Info.Normalized_Dispatching_Call_Controlling_Subtype) & ":" &
         To_String (Info.Normalized_Dispatching_Call_Result_Subtype) & ":" &
         Natural'Image (Info.Dispatching_Call_Primitive_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Controlling_Operand_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Controlling_Result_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Ambiguous_Count) & ":" &
         Natural'Image (Info.Dispatching_Call_Unknown_Count) & ":" &
         Parameter_Association_Status_Text (Info.Parameter_Association_Status) & ":" &
         Natural'Image (Info.Parameter_Association_Position) & ":" &
         To_String (Info.Normalized_Parameter_Association_Formal_Name) & ":" &
         To_String (Info.Normalized_Parameter_Association_Formal_Subtype) & ":" &
         To_String (Info.Normalized_Parameter_Association_Actual_Subtype) & ":" &
         Attribute_Status_Text (Info.Attribute_Status) & ":" &
         To_String (Info.Normalized_Attribute_Name) & ":" &
         To_String (Info.Normalized_Attribute_Prefix) & ":" &
         To_String (Info.Normalized_Attribute_Result_Subtype) & ":" &
         Natural'Image (Info.Attribute_Static_Result_Count) & ":" &
         Natural'Image (Info.Attribute_String_Result_Count) & ":" &
         Natural'Image (Info.Attribute_Unknown_Count) & ":" &
         Natural'Image (Info.Candidate_Count));
   end Fingerprint_For;

   function Region_For_Line
     (Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Line    : Positive) return Editor.Ada_Declarative_Regions.Region_Id
   is
      Best       : Editor.Ada_Declarative_Regions.Region_Id := Editor.Ada_Declarative_Regions.No_Region;
      Best_Depth : Natural := 0;
   begin
      for I in 1 .. Editor.Ada_Declarative_Regions.Region_Count (Regions) loop
         declare
            R : constant Editor.Ada_Declarative_Regions.Region_Info :=
              Editor.Ada_Declarative_Regions.Region_At (Regions, I);
         begin
            if Line >= R.Start_Line and then Line <= R.End_Line and then
              (Best = Editor.Ada_Declarative_Regions.No_Region or else R.Depth >= Best_Depth)
            then
               Best := R.Id;
               Best_Depth := R.Depth;
            end if;
         end;
      end loop;
      return Best;
   end Region_For_Line;

   function Primary_Name (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      if T = "" then
         return "";
      end if;
      for I in T'Range loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z' or else
                 T (I) in '0' .. '9' or else T (I) = '_' or else T (I) = '.')
         then
            if I = T'First then
               return "";
            else
               return T (T'First .. I - 1);
            end if;
         end if;
      end loop;
      return T;
   end Primary_Name;

   function Prefix_Before (Text : String; Mark : Character) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = Mark then
            if I = T'First then
               return "";
            else
               return Trim (T (T'First .. I - 1));
            end if;
         end if;
      end loop;
      return "";
   end Prefix_Before;

   function Suffix_After (Text : String; Mark : Character) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = Mark then
            if I = T'Last then
               return "";
            else
               return Trim (T (I + 1 .. T'Last));
            end if;
         end if;
      end loop;
      return "";
   end Suffix_After;



   function Attribute_Name_From_Text (Text : String) return String is
      Raw : constant String := Suffix_After (Text, Character'Val (39));
      T   : constant String := Trim (Raw);
   begin
      if T = "" then
         return "";
      end if;
      for I in T'Range loop
         if not (T (I) in 'A' .. 'Z' or else T (I) in 'a' .. 'z' or else
                 T (I) in '0' .. '9' or else T (I) = '_')
         then
            if I = T'First then
               return "";
            else
               return T (T'First .. I - 1);
            end if;
         end if;
      end loop;
      return T;
   end Attribute_Name_From_Text;

   function Attribute_Prefix_From_Text (Text : String) return String is
   begin
      return Prefix_Before (Text, Character'Val (39));
   end Attribute_Prefix_From_Text;

   function Is_String_Literal (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      return T'Length >= 2 and then T (T'First) = '"' and then T (T'Last) = '"';
   end Is_String_Literal;

   function Is_Character_Literal_Text (Text : String) return Boolean is
      T : constant String := Trim (Text);
   begin
      return T'Length >= 3 and then T (T'First) = Character'Val (39) and then
        T (T'Last) = Character'Val (39);
   end Is_Character_Literal_Text;

   function Looks_Real (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, ".") or else Contains (T, "e+") or else
        Contains (T, "e-") or else Contains (T, "e");
   end Looks_Real;

   function Lookup_Selected_Status
     (Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Node     : Editor.Ada_Syntax_Tree.Node_Id)
      return Expression_Type_Status
   is
      pragma Unreferenced (Selected, Node);
   begin
      --  The selected-name package exposes pass-specific metadata, but this
      --  foundation keeps the dependency optional and classifies through the
      --  syntax/visibility path when callers use the simpler Build entry point.
      return Expression_Type_Selected_Name_Unresolved;
   end Lookup_Selected_Status;


   function Is_Universal_Compatible (Actual : String; Expected : String) return Boolean is
      A : constant String := Normalize (Actual);
      E : constant String := Normalize (Expected);
   begin
      return (A = "universal_integer" and then
              (E = "integer" or else E = "natural" or else E = "positive" or else
               Contains (E, "integer") or else Contains (E, "natural") or else
               Contains (E, "positive") or else Contains (E, "count")))
        or else (A = "universal_real" and then
                 (E = "float" or else E = "long_float" or else E = "duration" or else
                  Contains (E, "float") or else Contains (E, "real") or else
                  Contains (E, "duration")))
        or else (A = "universal_integer" and then
                 (E = "float" or else E = "long_float" or else E = "duration"));
   end Is_Universal_Compatible;

   function Is_Context_Dependent
     (Status : Expression_Type_Status) return Boolean is
   begin
      return Status = Expression_Type_Aggregate or else
        Status = Expression_Type_Qualified or else
        Status = Expression_Type_Conversion or else
        Status = Expression_Type_Indeterminate or else
        Status = Expression_Type_Operator_Numeric or else
        Status = Expression_Type_Operator_Concatenation or else
        Status = Expression_Type_Null_Literal or else
        Status = Expression_Type_Allocator;
   end Is_Context_Dependent;


   function Subtype_From_Declaration_Label (Label : String) return String is
      T : constant String := Trim (Label);
      Colon : Natural := 0;
      Assign : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = ':' then
            Colon := I;
            exit;
         end if;
      end loop;
      if Colon = 0 or else Colon = T'Last then
         return "";
      end if;
      for I in Colon + 1 .. T'Last loop
         if I < T'Last and then T (I) = ':' and then T (I + 1) = '=' then
            Assign := I;
            exit;
         elsif T (I) = ';' then
            Assign := I;
            exit;
         end if;
      end loop;
      if Assign = 0 then
         return Trim (T (Colon + 1 .. T'Last));
      elsif Assign > Colon + 1 then
         declare
            Raw : constant String := Trim (T (Colon + 1 .. Assign - 1));
            N : constant String := Normalize (Raw);
         begin
            if N'Length > 9 and then N (N'First .. N'First + 8) = "constant " then
               return Trim (Raw (Raw'First + 9 .. Raw'Last));
            else
               return Raw;
            end if;
         end;
      else
         return "";
      end if;
   end Subtype_From_Declaration_Label;

   procedure Apply_Syntax_Expected_Context
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Info : in out Expression_Type_Info)
   is
      N : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Info.Node);
      Parent : Editor.Ada_Syntax_Tree.Node_Info;
      Grand  : Editor.Ada_Syntax_Tree.Node_Info;
      Expected : Ada.Strings.Unbounded.Unbounded_String;
   begin
      if Info.Expected_Context /= Editor.Ada_Expected_Type_Contexts.No_Expected_Context then
         return;
      end if;
      if N.Parent = Editor.Ada_Syntax_Tree.No_Node then
         return;
      end if;

      Parent := Editor.Ada_Syntax_Tree.Node (Tree, N.Parent);
      if Parent.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Default and then
        Parent.Parent /= Editor.Ada_Syntax_Tree.No_Node
      then
         Grand := Editor.Ada_Syntax_Tree.Node (Tree, Parent.Parent);
         if Grand.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
           Grand.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
           Grand.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
         then
            Expected := To_Unbounded_String
              (Subtype_From_Declaration_Label (To_String (Grand.Label)));
         end if;
      elsif Parent.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
      then
         Expected := To_Unbounded_String
           (Subtype_From_Declaration_Label (To_String (Parent.Label)));
      end if;

      if To_String (Expected) /= "" then
         Info.Expected_Status := Expected_Type_Context_Found;
         Info.Expected_Subtype := Expected;
         Info.Normalized_Expected_Subtype := To_Unbounded_String (Normalize (To_String (Expected)));
         if To_String (Info.Normalized_Subtype) = "" or else
           To_String (Info.Normalized_Subtype) = "aggregate_context_required" or else
           Is_Context_Dependent (Info.Status)
         then
            Info.Expected_Status := Expected_Type_Propagated;
            Info.Inferred_Subtype := Expected;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         elsif To_String (Info.Normalized_Subtype) = To_String (Info.Normalized_Expected_Subtype) or else
           Is_Universal_Compatible
             (To_String (Info.Normalized_Subtype),
              To_String (Info.Normalized_Expected_Subtype))
         then
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      end if;
   end Apply_Syntax_Expected_Context;

   procedure Apply_Expected_Context
     (Info     : in out Expression_Type_Info;
      Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
   is
      Ctx : Editor.Ada_Expected_Type_Contexts.Expected_Context_Info :=
        Editor.Ada_Expected_Type_Contexts.Expected_Context_For_Node (Expected, Info.Node);
      Inferred : constant String := To_String (Info.Normalized_Subtype);
   begin
      if Ctx.Id = Editor.Ada_Expected_Type_Contexts.No_Expected_Context then
         Info.Expected_Status := Expected_Type_No_Context;
         return;
      end if;

      Info.Expected_Context := Ctx.Id;
      Info.Expected_Subtype := Ctx.Expected_Subtype;
      Info.Normalized_Expected_Subtype := Ctx.Normalized_Subtype;

      if Ctx.Status /= Editor.Ada_Expected_Type_Contexts.Expected_Context_Found then
         Info.Expected_Status := Expected_Type_Unknown;
      elsif To_String (Ctx.Normalized_Subtype) = "" then
         Info.Expected_Status := Expected_Type_Unknown;
      elsif Inferred = "" or else Inferred = "aggregate_context_required" or else
        Inferred = "attribute_result_unknown"
      then
         if Is_Context_Dependent (Info.Status) then
            Info.Expected_Status := Expected_Type_Propagated;
            Info.Inferred_Subtype := Ctx.Expected_Subtype;
            Info.Normalized_Subtype := Ctx.Normalized_Subtype;
         else
            Info.Expected_Status := Expected_Type_Unknown;
         end if;
      elsif Inferred = To_String (Ctx.Normalized_Subtype) or else
        Is_Universal_Compatible (Inferred, To_String (Ctx.Normalized_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
      elsif Is_Context_Dependent (Info.Status) then
         Info.Expected_Status := Expected_Type_Propagated;
         Info.Inferred_Subtype := Ctx.Expected_Subtype;
         Info.Normalized_Subtype := Ctx.Normalized_Subtype;
      else
         Info.Expected_Status := Expected_Type_Mismatch;
      end if;
   end Apply_Expected_Context;

   procedure Append
     (Model : in out Expression_Type_Model;
      Info  : in out Expression_Type_Info)
   is
   begin
      Info.Id := Expression_Type_Id (Natural (Model.Expressions.Length) + 1);
      Info.Fingerprint := Fingerprint_For (Info);
      Model.Expressions.Append (Info);
      Model.Result_Fingerprint :=
        Hash_Mix (Model.Result_Fingerprint, Long_Long_Integer (Info.Fingerprint));
   end Append;


   function Operator_Symbol_From_Text (Text : String) return String is
      T : constant String := Normalize (Text);
   begin
      if Contains (T, " and then ") then return "and then"; end if;
      if Contains (T, " or else ") then return "or else"; end if;
      if Contains (T, " and ") then return "and"; end if;
      if Contains (T, " or ") then return "or"; end if;
      if Contains (T, " xor ") then return "xor"; end if;
      if Contains (T, " not ") or else (T'Length >= 3 and then T (T'First .. T'First + 2) = "not") then return "not"; end if;
      if Contains (T, " /= ") or else Contains (T, "/=") then return "/="; end if;
      if Contains (T, " <= ") or else Contains (T, "<=") then return "<="; end if;
      if Contains (T, " >= ") or else Contains (T, ">=") then return ">="; end if;
      if Contains (T, " < ") then return "<"; end if;
      if Contains (T, " > ") then return ">"; end if;
      if Contains (T, " = ") then return "="; end if;
      if Contains (T, " mod ") then return "mod"; end if;
      if Contains (T, " rem ") then return "rem"; end if;
      if Contains (T, " ** ") or else Contains (T, "**") then return "**"; end if;
      if Contains (T, " * ") then return "*"; end if;
      if Contains (T, " / ") then return "/"; end if;
      if Contains (T, " & ") or else Contains (T, "&") then return "&"; end if;
      if Contains (T, " + ") or else (T'Length > 1 and then T (T'First) = '+') then return "+"; end if;
      if Contains (T, " - ") or else (T'Length > 1 and then T (T'First) = '-') then return "-"; end if;
      if Contains (T, " in ") or else Contains (T, " not in ") then return "in"; end if;
      return "";
   end Operator_Symbol_From_Text;

   function Is_Relational_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "=" or else S = "/=" or else S = "<" or else S = "<=" or else
        S = ">" or else S = ">=" or else S = "in";
   end Is_Relational_Operator;

   function Is_Boolean_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "and" or else S = "or" or else S = "xor" or else
        S = "and then" or else S = "or else" or else S = "not";
   end Is_Boolean_Operator;

   function Is_Numeric_Operator (Symbol : String) return Boolean is
      S : constant String := Normalize (Symbol);
   begin
      return S = "+" or else S = "-" or else S = "*" or else S = "/" or else
        S = "mod" or else S = "rem" or else S = "**";
   end Is_Numeric_Operator;

   function Is_Integer_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "integer" or else S = "natural" or else S = "positive" or else
        S = "universal_integer" or else Contains (S, "integer") or else
        Contains (S, "natural") or else Contains (S, "positive");
   end Is_Integer_Family;

   function Is_Real_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "float" or else S = "long_float" or else S = "universal_real" or else
        S = "duration" or else Contains (S, "float") or else Contains (S, "real") or else
        Contains (S, "duration");
   end Is_Real_Family;

   function Is_Numeric_Family (Subtype_Name : String) return Boolean is
   begin
      return Is_Integer_Family (Subtype_Name) or else Is_Real_Family (Subtype_Name);
   end Is_Numeric_Family;


   function Is_String_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "string" or else S = "wide_string" or else
        S = "wide_wide_string" or else Contains (S, "string");
   end Is_String_Family;

   function Is_Character_Family (Subtype_Name : String) return Boolean is
      S : constant String := Normalize (Subtype_Name);
   begin
      return S = "character" or else S = "wide_character" or else
        S = "wide_wide_character" or else Contains (S, "character");
   end Is_Character_Family;

   function Is_Array_Family
     (Types   : Editor.Ada_Type_Graph.Type_Model;
      Region  : Editor.Ada_Declarative_Regions.Region_Id;
      Subtype_Name : String) return Boolean
   is
      T : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Subtype_Name);
   begin
      if Is_String_Family (Subtype_Name) then
         return True;
      elsif T = Editor.Ada_Type_Graph.No_Type then
         return Contains (Normalize (Subtype_Name), "array");
      else
         return Editor.Ada_Type_Graph.Type_Node (Types, T).Category =
           Editor.Ada_Type_Graph.Type_Category_Array;
      end if;
   end Is_Array_Family;

   function Simple_Subtype_Compatible (Left : String; Right : String) return Boolean is
      NL : constant String := Normalize (Left);
      NR : constant String := Normalize (Right);
   begin
      return (NL /= "" and then NL = NR) or else
        (Is_Numeric_Family (Left) and then Is_Numeric_Family (Right)) or else
        Is_Universal_Compatible (NL, NR) or else Is_Universal_Compatible (NR, NL);
   end Simple_Subtype_Compatible;

   function Looks_Range_Choice (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, " .. ") or else Contains (T, " range ") or else
        Contains (T, "'range") or else Contains (T, "..");
   end Looks_Range_Choice;

   procedure Set_Boolean_Result (Info : in out Expression_Type_Info) is
   begin
      Info.Status := Expression_Type_Operator_Boolean;
      Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Subtype := To_Unbounded_String ("boolean");
      Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
   end Set_Boolean_Result;

   function Infer_Operand_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Parent     : Editor.Ada_Syntax_Tree.Node_Info;
      Child_Index : Positive) return String
   is
      pragma Unreferenced (Types);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Parent.Source_Span.Start_Line);
      Count  : constant Natural :=
        Editor.Ada_Syntax_Tree.Child_Count (Tree, Parent.Id);
   begin
      if Count >= Child_Index then
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Parent.Id, Child_Index);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            Text : constant String := Trim (To_String (Child.Label));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Literal then
               declare
                  V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                    Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Text);
               begin
                  if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                     return "Universal_Integer";
                  elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                     return "Universal_Real";
                  elsif Normalize (Text) = "true" or else Normalize (Text) = "false" then
                     return "Boolean";
                  elsif Is_String_Literal (Text) then
                     return "String";
                  elsif Is_Character_Literal_Text (Text) then
                     return "Character";
                  end if;
               end;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Name then
               declare
                  Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, Primary_Name (Text));
               begin
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     declare
                        Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                          Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
                        Subtype_Text : constant String :=
                          Subtype_From_Declaration_Label (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
                     begin
                        if Subtype_Text /= "" then
                           return Subtype_Text;
                        else
                           return To_String (Decl.Name);
                        end if;
                     end;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     return "ambiguous";
                  end if;
               end;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
               declare
                  Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
                    Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Child.Id);
               begin
                  if Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match then
                     return "call_result_known";
                  elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
                    Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
                  then
                     return "ambiguous";
                  end if;
               end;
            end if;
         end;
      end if;

      declare
         Text : constant String := Normalize (To_String (Parent.Label));
      begin
         if Contains (Text, "true") or else Contains (Text, "false") then
            return "Boolean";
         elsif Looks_Real (Text) then
            return "Universal_Real";
         elsif Text /= "" then
            declare
               V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                 Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Text);
            begin
               if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                  return "Universal_Integer";
               elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                  return "Universal_Real";
               end if;
            end;
         end if;
      end;
      return "";
   end Infer_Operand_Subtype;

   function Count_Commas (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         if C = ',' then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Commas;

   function Looks_Record_Aggregate (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, "=>") and then not Contains (T, " for ") and then
        not Contains (T, " of ");
   end Looks_Record_Aggregate;

   function Looks_Container_Aggregate (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, " for ") or else Contains (T, " of ") or else
        Contains (T, " use ") or else Contains (T, "=> <>");
   end Looks_Container_Aggregate;

   function Extract_Array_Element_Subtype (Expected : String) return String is
      T : constant String := Trim (Expected);
      N : constant String := Normalize (T);
      Mark : constant String := " of ";
      P : constant Natural := Ada.Strings.Fixed.Index (N, Mark);
   begin
      if P /= 0 and then P + Mark'Length <= T'Last then
         return Trim (T (P + Mark'Length .. T'Last));
      elsif Contains (N, "string") then
         return "Character";
      else
         return "";
      end if;
   end Extract_Array_Element_Subtype;

   function Extract_Array_Index_Subtype (Expected : String) return String is
      T : constant String := Trim (Expected);
      N : constant String := Normalize (T);
      L : constant Natural := Ada.Strings.Fixed.Index (N, "(");
      R : constant Natural := Ada.Strings.Fixed.Index (N, ")");
   begin
      if L /= 0 and then R > L then
         return Trim (T (L + 1 .. R - 1));
      else
         return "";
      end if;
   end Extract_Array_Index_Subtype;

   function Aggregate_Association_Name (Text : String) return String is
      T : constant String := Trim (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "=>");
   begin
      if P = 0 or else P <= T'First then
         return "";
      end if;
      declare
         Raw_Text : constant String := Trim (T (T'First .. P - 1));
         Dot : constant Natural := Ada.Strings.Fixed.Index (Raw_Text, ".");
      begin
         if Dot /= 0 and then Dot < Raw_Text'Last then
            return Trim (Raw_Text (Dot + 1 .. Raw_Text'Last));
         else
            return Raw_Text;
         end if;
      end;
   end Aggregate_Association_Name;

   function Aggregate_Association_Value (Text : String) return String is
      T : constant String := Trim (Text);
      P : constant Natural := Ada.Strings.Fixed.Index (T, "=>");
   begin
      if P = 0 or else P + 2 > T'Last then
         return T;
      else
         return Trim (T (P + 2 .. T'Last));
      end if;
   end Aggregate_Association_Value;

   function Type_Category_For_Subtype
     (Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Name   : String) return Editor.Ada_Type_Graph.Type_Category
   is
      Id : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Name);
   begin
      if Id = Editor.Ada_Type_Graph.No_Type then
         declare
            N : constant String := Normalize (Name);
         begin
            if Contains (N, "array") or else Contains (N, "string") then
               return Editor.Ada_Type_Graph.Type_Category_Array;
            elsif Contains (N, "record") then
               return Editor.Ada_Type_Graph.Type_Category_Record;
            else
               return Editor.Ada_Type_Graph.Type_Category_Unknown;
            end if;
         end;
      else
         return Editor.Ada_Type_Graph.Type_Node (Types, Id).Category;
      end if;
   end Type_Category_For_Subtype;

   function Record_Component_Known
     (Tree   : Editor.Ada_Syntax_Tree.Tree_Type;
      Types  : Editor.Ada_Type_Graph.Type_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Record_Subtype : String;
      Component_Name : String) return Boolean
   is
      Type_Id : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Record_Subtype);
      Target : constant String := Normalize (Component_Name);
   begin
      if Target = "" then
         return False;
      end if;
      if Type_Id = Editor.Ada_Type_Graph.No_Type then
         return False;
      end if;

      declare
         Root : constant Editor.Ada_Syntax_Tree.Node_Id :=
           Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).Node;
      begin
         if Root = Editor.Ada_Syntax_Tree.No_Node then
            return False;
         end if;
         for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
            declare
               N : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node_At (Tree, I);
               Name_Text : Ada.Strings.Unbounded.Unbounded_String;
            begin
               if N.Kind = Editor.Ada_Syntax_Tree.Node_Component_Declaration
                 and then N.Source_Span.Start_Line >= Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).Start_Line
                 and then N.Source_Span.End_Line <= Editor.Ada_Type_Graph.Type_Node (Types, Type_Id).End_Line
               then
                  Name_Text := To_Unbounded_String (Aggregate_Association_Name (To_String (N.Label)));
                  if To_String (Name_Text) = "" then
                     declare
                        L : constant String := To_String (N.Label);
                        Colon : constant Natural := Ada.Strings.Fixed.Index (L, ":");
                     begin
                        if Colon > L'First then
                           Name_Text := To_Unbounded_String (Trim (L (L'First .. Colon - 1)));
                        end if;
                     end;
                  end if;
                  if Normalize (To_String (Name_Text)) = Target then
                     return True;
                  end if;
               end if;
            end;
         end loop;
      end;
      return False;
   end Record_Component_Known;

   function Looks_Element_Compatible (Value_Text : String; Element_Subtype : String) return Boolean is
      V : constant String := Normalize (Trim (Value_Text));
      E : constant String := Normalize (Trim (Element_Subtype));
   begin
      if E = "" or else V = "" or else V = "<>" then
         return False;
      elsif E = "character" then
         return V'Length >= 3 and then V (V'First) = Character'Val (39) and then V (V'Last) = Character'Val (39);
      elsif E = "string" then
         return V'Length >= 2 and then V (V'First) = Character'Val (34) and then V (V'Last) = Character'Val (34);
      elsif Contains (E, "integer") or else Contains (E, "natural") or else Contains (E, "positive") then
         return not Looks_Real (V) and then V /= "true" and then V /= "false";
      elsif Contains (E, "float") or else Contains (E, "real") or else Contains (E, "fixed") then
         return Looks_Real (V) or else (V /= "true" and then V /= "false" and then V /= "null");
      elsif E = "boolean" then
         return V = "true" or else V = "false";
      else
         return True;
      end if;
   end Looks_Element_Compatible;


   function Extract_Designator_Before_Call (Text : String) return String is
      T : constant String := Trim (Text);
   begin
      for I in T'Range loop
         if T (I) = '(' then
            if I = T'First then
               return "";
            else
               return Trim (T (T'First .. I - 1));
            end if;
         end if;
      end loop;
      return "";
   end Extract_Designator_Before_Call;

   function Extract_First_Actual_Text (Text : String) return String is
      T : constant String := Trim (Text);
      L : Natural := 0;
      R : Natural := 0;
      Depth : Natural := 0;
   begin
      for I in T'Range loop
         if T (I) = '(' then
            L := I;
            exit;
         end if;
      end loop;
      if L = 0 or else L = T'Last then
         return "";
      end if;
      for I in L + 1 .. T'Last loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' then
            if Depth = 0 then
               R := I;
               exit;
            else
               Depth := Depth - 1;
            end if;
         elsif T (I) = ',' and then Depth = 0 then
            R := I;
            exit;
         end if;
      end loop;
      if R = 0 or else R <= L + 1 then
         return "";
      elsif T (R) = ',' or else T (R) = ')' then
         return Trim (T (L + 1 .. R - 1));
      else
         return "";
      end if;
   end Extract_First_Actual_Text;

   function Subtype_Compatible_By_Graph
     (Types    : Editor.Ada_Type_Graph.Type_Model;
      Region   : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String;
      Actual   : String) return Boolean
   is
      E : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected);
      A : constant Editor.Ada_Type_Graph.Type_Id :=
        Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Actual);
      C : Editor.Ada_Type_Graph.Compatibility_Status :=
        Editor.Ada_Type_Graph.Type_Compatibility_Not_Checked;
   begin
      if Normalize (Expected) = Normalize (Actual) then
         return True;
      elsif E = Editor.Ada_Type_Graph.No_Type or else A = Editor.Ada_Type_Graph.No_Type then
         return False;
      else
         C := Editor.Ada_Type_Graph.Compatibility (Types, E, A);
         return C = Editor.Ada_Type_Graph.Type_Compatibility_Exact_Type or else
           C = Editor.Ada_Type_Graph.Type_Compatibility_Subtype_Of or else
           C = Editor.Ada_Type_Graph.Type_Compatibility_Class_Wide;
      end if;
   end Subtype_Compatible_By_Graph;

   function Operand_Subtype_From_Text
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return String
   is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
        Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, T);
   begin
      if T = "" then
         return "";
      elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
         return "Universal_Integer";
      elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
         return "Universal_Real";
      elsif N = "true" or else N = "false" then
         return "Boolean";
      elsif N = "null" then
         return "universal_access";
      elsif Is_String_Literal (T) then
         return "String";
      elsif Is_Character_Literal_Text (T) then
         return "Character";
      else
         return "";
      end if;
   end Operand_Subtype_From_Text;

   procedure Apply_Conversion_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Tree);
      Text : constant String := To_String (Node.Label);
      Target_U : Ada.Strings.Unbounded.Unbounded_String;
      Operand_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Operand_U : Ada.Strings.Unbounded.Unbounded_String;
      Region : constant Editor.Ada_Declarative_Regions.Region_Id := Info.Region;
      Target_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Lookup : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      Info.Conversion_Status := Conversion_Type_Not_Conversion;
      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
         Target_U := To_Unbounded_String (Prefix_Before (Text, Character'Val (39)));
         Operand_Text_U := To_Unbounded_String (Suffix_After (Text, Character'Val (39)));
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
         Target_U := To_Unbounded_String (Extract_Designator_Before_Call (Text));
         Operand_Text_U := To_Unbounded_String (Extract_First_Actual_Text (Text));
      else
         return;
      end if;

      declare
         Target : constant String := To_String (Target_U);
         Operand_Text : constant String := To_String (Operand_Text_U);
      begin
      if Target = "" then
         Info.Conversion_Status := Conversion_Type_Malformed;
         return;
      end if;

      Info.Conversion_Target_Subtype := To_Unbounded_String (Target);
      Info.Normalized_Conversion_Target_Subtype := To_Unbounded_String (Normalize (Target));
      Target_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Target);
      if Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Info.Type_Id := Target_Type;
         Info.Status := (if Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
                            Expression_Type_Qualified else Expression_Type_Conversion);
         Info.Inferred_Subtype := To_Unbounded_String (Target);
         Info.Normalized_Subtype := To_Unbounded_String (Normalize (Target));
         Info.Conversion_Status := Conversion_Type_Target_Resolved;
      else
         Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
           (Visibility, Regions, Region, Target);
         Info.Candidate_Count := Lookup.Match_Count;
         if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Conversion_Status := Conversion_Type_Target_Ambiguous;
            Info.Status := Expression_Type_Name_Ambiguous;
            return;
         elsif Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
            Info.Conversion_Status := Conversion_Type_Target_Unresolved;
            return;
         end if;
      end if;

      Operand_U := To_Unbounded_String (Operand_Subtype_From_Text (Static, Region, Operand_Text));
      declare
         Operand : constant String := To_String (Operand_U);
      begin
      if Operand = "" and then Node.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression then
         --  Qualified expressions are context carriers; retain the resolved target even when
         --  the operand type is not locally derivable in this pass.
         Info.Conversion_Status := Conversion_Type_Target_Resolved;
         return;
      elsif Operand = "" then
         Info.Conversion_Status := Conversion_Type_Operand_Unknown;
         Info.Conversion_Unknown_Operand_Count := 1;
         return;
      end if;

      Info.Conversion_Operand_Subtype := To_Unbounded_String (Operand);
      Info.Normalized_Conversion_Operand_Subtype := To_Unbounded_String (Normalize (Operand));
      if Subtype_Compatible_By_Graph (Types, Region, Target, Operand) or else
        Normalize (Target) = Normalize (Operand) or else
        Is_Universal_Compatible (Normalize (Operand), Normalize (Target))
      then
         Info.Conversion_Status := Conversion_Type_Operand_Compatible;
         Info.Conversion_Compatible_Operand_Count := 1;
      elsif Is_Numeric_Family (Target) and then Is_Numeric_Family (Operand) then
         Info.Conversion_Status := Conversion_Type_Operand_Requires_Explicit_Conversion;
         Info.Conversion_Explicit_Operand_Count := 1;
      else
         Info.Conversion_Status := Conversion_Type_Operand_Mismatch;
         Info.Conversion_Mismatched_Operand_Count := 1;
      end if;
      end;
      end;
   end Apply_Conversion_Inference;

   procedure Apply_Aggregate_Inference
     (Tree    : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Types   : Editor.Ada_Type_Graph.Type_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text : constant String := To_String (Node.Label);
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Childs : constant Natural := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id);
      Named  : Natural := 0;
      Positional : Natural := 0;
      Element : constant String := Extract_Array_Element_Subtype (Expected);
      Index   : constant String := Extract_Array_Index_Subtype (Expected);
      Region  : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Expected_Category : constant Editor.Ada_Type_Graph.Type_Category :=
        Type_Category_For_Subtype (Types, Region, Expected);
      Record_Missing : Natural := 0;
      Record_Duplicate : Natural := 0;
      Record_Compatible : Natural := 0;
      Array_Compatible : Natural := 0;
      Array_Mismatch : Natural := 0;
      Array_Unknown : Natural := 0;
   begin
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Aggregate or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate)
      then
         Info.Aggregate_Status := Aggregate_Type_Not_Aggregate;
         return;
      end if;

      Info.Aggregate_Status := Aggregate_Type_Context_Required;
      Info.Aggregate_Component_Count :=
        (if Childs > 0 then Childs else Count_Commas (Text) + 1);

      for I in 1 .. Childs loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            CText : constant String := To_String (Child.Label);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
              Contains (CText, "=>")
            then
               Named := Named + 1;
            elsif Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
              Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
            then
               Positional := Positional + 1;
            end if;
         end;
      end loop;

      if Childs = 0 then
         if Contains (Text, "=>") then
            Named := Count_Commas (Text) + 1;
         elsif Trim (Text) /= "" then
            Positional := Count_Commas (Text) + 1;
         end if;
      end if;

      Info.Aggregate_Named_Association_Count := Named;
      Info.Aggregate_Positional_Association_Count := Positional;

      if NExpected = "" then
         Info.Aggregate_Unknown_Count := 1;
         return;
      end if;

      Info.Inferred_Subtype := Info.Expected_Subtype;
      Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
      Info.Aggregate_Element_Subtype := To_Unbounded_String (Element);
      Info.Normalized_Aggregate_Element_Subtype := To_Unbounded_String (Normalize (Element));
      Info.Aggregate_Index_Subtype := To_Unbounded_String (Index);
      Info.Normalized_Aggregate_Index_Subtype := To_Unbounded_String (Normalize (Index));

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate then
         Info.Aggregate_Status := Aggregate_Type_Delta_Context;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate or else
        Looks_Container_Aggregate (Text)
      then
         Info.Aggregate_Status := Aggregate_Type_Container_Context;
      elsif Contains (NExpected, "array") or else Contains (NExpected, "string") or else
        Element /= "" or else Positional > 0
      then
         Info.Aggregate_Status := Aggregate_Type_Array_Context;
      elsif Looks_Record_Aggregate (Text) or else Named > 0 then
         Info.Aggregate_Status := Aggregate_Type_Record_Context;
      else
         Info.Aggregate_Status := Aggregate_Type_Unknown;
         Info.Aggregate_Unknown_Count := 1;
      end if;

      if Expected_Category = Editor.Ada_Type_Graph.Type_Category_Record or else
        Info.Aggregate_Status = Aggregate_Type_Record_Context
      then
         for I in 1 .. Childs loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Name : constant String := Aggregate_Association_Name (To_String (Child.Label));
            begin
               if Name /= "" then
                  declare
                     Seen : Natural := 0;
                  begin
                     for J in 1 .. Childs loop
                        declare
                           Other_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                             Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, J);
                           Other : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node (Tree, Other_Id);
                        begin
                           if Normalize (Aggregate_Association_Name (To_String (Other.Label))) =
                             Normalize (Name)
                           then
                              Seen := Seen + 1;
                           end if;
                        end;
                     end loop;
                     if Seen > 1 then
                        Record_Duplicate := Record_Duplicate + 1;
                     elsif Record_Component_Known (Tree, Types, Region, Expected, Name) then
                        Record_Compatible := Record_Compatible + 1;
                     elsif Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected) /=
                       Editor.Ada_Type_Graph.No_Type
                     then
                        Record_Missing := Record_Missing + 1;
                     else
                        Info.Aggregate_Unknown_Count := Info.Aggregate_Unknown_Count + 1;
                     end if;
                  end;
               end if;
            end;
         end loop;

         Info.Aggregate_Record_Component_Compatible_Count := Record_Compatible;
         Info.Aggregate_Record_Component_Missing_Count := Record_Missing;
         Info.Aggregate_Record_Component_Duplicate_Count := Record_Duplicate;

         if Record_Duplicate > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Component_Duplicate;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Record_Duplicate;
         elsif Record_Missing > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Component_Missing;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Record_Missing;
         elsif Record_Compatible > 0 then
            Info.Aggregate_Status := Aggregate_Type_Record_Components_Compatible;
         end if;
      elsif Expected_Category = Editor.Ada_Type_Graph.Type_Category_Array or else
        Info.Aggregate_Status = Aggregate_Type_Array_Context
      then
         for I in 1 .. Childs loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Value : constant String := Aggregate_Association_Value (To_String (Child.Label));
            begin
               if Element = "" then
                  Array_Unknown := Array_Unknown + 1;
               elsif Looks_Element_Compatible (Value, Element) then
                  Array_Compatible := Array_Compatible + 1;
               else
                  Array_Mismatch := Array_Mismatch + 1;
               end if;
            end;
         end loop;

         if Childs = 0 and then Element /= "" and then Positional > 0 then
            Array_Unknown := Positional;
         end if;

         Info.Aggregate_Array_Element_Compatible_Count := Array_Compatible;
         Info.Aggregate_Array_Element_Mismatch_Count := Array_Mismatch;
         Info.Aggregate_Array_Element_Unknown_Count := Array_Unknown;

         if Array_Mismatch > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Element_Mismatch;
            Info.Aggregate_Mismatch_Count := Info.Aggregate_Mismatch_Count + Array_Mismatch;
         elsif Array_Unknown > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Element_Unknown;
            Info.Aggregate_Unknown_Count := Info.Aggregate_Unknown_Count + Array_Unknown;
         elsif Array_Compatible > 0 then
            Info.Aggregate_Status := Aggregate_Type_Array_Elements_Compatible;
         end if;
      end if;

      if Info.Aggregate_Status = Aggregate_Type_Array_Context and then Named > 0 and then
        not Contains (NExpected, "array") and then Element = ""
      then
         Info.Aggregate_Status := Aggregate_Type_Mismatch;
         Info.Aggregate_Mismatch_Count := 1;
      elsif Info.Aggregate_Status /= Aggregate_Type_Unknown
        and then Info.Aggregate_Status /= Aggregate_Type_Record_Component_Missing
        and then Info.Aggregate_Status /= Aggregate_Type_Record_Component_Duplicate
        and then Info.Aggregate_Status /= Aggregate_Type_Array_Element_Mismatch
        and then Info.Aggregate_Status /= Aggregate_Type_Array_Element_Unknown
        and then Info.Aggregate_Status /= Aggregate_Type_Record_Components_Compatible
        and then Info.Aggregate_Status /= Aggregate_Type_Array_Elements_Compatible
      then
         Info.Aggregate_Status := Aggregate_Type_Compatible;
      end if;
   end Apply_Aggregate_Inference;

   procedure Apply_Operator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Symbol : constant String := Operator_Symbol_From_Text (To_String (Node.Label));
      Left   : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 1);
      Right  : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 2);
      NL     : constant String := Normalize (Left);
      NR     : constant String := Normalize (Right);
      Has_Right : constant Boolean := Right /= "";
   begin
      Info.Operator_Status := Operator_Type_Not_Operator;
      if Symbol = "" then
         return;
      end if;

      Info.Operator_Status := Operator_Type_Not_Checked;
      Info.Operator_Symbol := To_Unbounded_String (Symbol);
      Info.Left_Operand_Subtype := To_Unbounded_String (Left);
      Info.Right_Operand_Subtype := To_Unbounded_String (Right);
      Info.Normalized_Left_Operand_Subtype := To_Unbounded_String (NL);
      Info.Normalized_Right_Operand_Subtype := To_Unbounded_String (NR);

      if Left = "ambiguous" or else Right = "ambiguous" then
         Info.Operator_Status := Operator_Type_Ambiguous;
         Info.Status := Expression_Type_Operator_Unknown;
         Info.Candidate_Count := 2;
         return;
      elsif Left = "" and then not (Symbol = "+" or else Symbol = "-" or else Symbol = "not") then
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      elsif Has_Right and then Right = "" then
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      end if;

      if Is_Boolean_Operator (Symbol) then
         if (Left = "" or else NL = "boolean") and then
           (not Has_Right or else NR = "boolean" or else Right = "")
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := (if Has_Right then 2 else 1);
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      elsif Is_Relational_Operator (Symbol) then
         if Has_Right and then (NL = NR or else
           (Is_Numeric_Family (Left) and then Is_Numeric_Family (Right)))
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := 2;
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         elsif not Has_Right or else Right = "" then
            Info.Operator_Status := Operator_Type_Operand_Unknown;
            Info.Operator_Unknown_Operand_Count := 1;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      elsif Is_Numeric_Operator (Symbol) then
         if (Left = "" or else Is_Numeric_Family (Left)) and then
           (not Has_Right or else Is_Numeric_Family (Right))
         then
            Info.Operator_Status := Operator_Type_Resolved_Predefined;
            Info.Operator_Compatible_Operand_Count := (if Has_Right then 2 else 1);
            if Is_Real_Family (Left) or else Is_Real_Family (Right) or else Looks_Real (To_String (Node.Label)) then
               Info.Operator_Result_Subtype := To_Unbounded_String ("Universal_Real");
               Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("universal_real");
            else
               Info.Operator_Result_Subtype := To_Unbounded_String ("Universal_Integer");
               Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("universal_integer");
            end if;
            Info.Status := Expression_Type_Operator_Numeric;
            Info.Inferred_Subtype := Info.Operator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
         else
            Info.Operator_Status := Operator_Type_Operand_Mismatch;
            Info.Operator_Mismatched_Operand_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      else
         Info.Operator_Status := Operator_Type_Result_Unknown;
         Info.Operator_Unknown_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
      end if;
   end Apply_Operator_Inference;


   function Lookup_Operand_Subtype_Text
     (Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
   is
      Literal : constant String := Operand_Subtype_From_Text (Static, Region, Text);
      Lookup  : Editor.Ada_Direct_Visibility.Lookup_Result;
   begin
      if Literal /= "" then
         return Literal;
      end if;

      Lookup := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, Region, Primary_Name (Text));
      if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
            Subtype_Text : constant String := "";
         begin
            if Subtype_Text /= "" then
               return Subtype_Text;
            else
               return To_String (Decl.Name);
            end if;
         end;
      elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
         return "ambiguous";
      else
         return "";
      end if;
   end Lookup_Operand_Subtype_Text;

   procedure Split_Concatenation_Text
     (Text  : String;
      Left  : out Ada.Strings.Unbounded.Unbounded_String;
      Right : out Ada.Strings.Unbounded.Unbounded_String)
   is
      T : constant String := Trim (Text);
      Depth : Natural := 0;
   begin
      Left := To_Unbounded_String ("");
      Right := To_Unbounded_String ("");
      for I in T'Range loop
         if T (I) = '(' then
            Depth := Depth + 1;
         elsif T (I) = ')' and then Depth > 0 then
            Depth := Depth - 1;
         elsif T (I) = '&' and then Depth = 0 then
            if I > T'First then
               Left := To_Unbounded_String (Trim (T (T'First .. I - 1)));
            end if;
            if I < T'Last then
               Right := To_Unbounded_String (Trim (T (I + 1 .. T'Last)));
            end if;
            return;
         end if;
      end loop;
   end Split_Concatenation_Text;

   procedure Apply_Concatenation_Inference
     (Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info)
   is
      Symbol : constant String := To_String (Info.Operator_Symbol);
      Left_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Right_Text_U : Ada.Strings.Unbounded.Unbounded_String;
      Left_U : Ada.Strings.Unbounded.Unbounded_String := Info.Left_Operand_Subtype;
      Right_U : Ada.Strings.Unbounded.Unbounded_String := Info.Right_Operand_Subtype;
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
   begin
      Info.Concatenation_Status := Concatenation_Type_Not_Concatenation;
      if Symbol /= "&" then
         return;
      end if;

      if To_String (Left_U) = "" or else To_String (Right_U) = "" then
         Split_Concatenation_Text (To_String (Info.Expression_Text), Left_Text_U, Right_Text_U);
         if To_String (Left_U) = "" then
            Left_U := To_Unbounded_String
              (Lookup_Operand_Subtype_Text
                 (Regions, Visibility, Static, Info.Region, To_String (Left_Text_U)));
         end if;
         if To_String (Right_U) = "" then
            Right_U := To_Unbounded_String
              (Lookup_Operand_Subtype_Text
                 (Regions, Visibility, Static, Info.Region, To_String (Right_Text_U)));
         end if;
      end if;

      declare
         Left   : constant String := To_String (Left_U);
         Right  : constant String := To_String (Right_U);
         NL     : constant String := Normalize (Left);
         NR     : constant String := Normalize (Right);
         Left_String : constant Boolean := Is_String_Family (NL);
         Right_String : constant Boolean := Is_String_Family (NR);
         Left_Char : constant Boolean := Is_Character_Family (NL);
         Right_Char : constant Boolean := Is_Character_Family (NR);
         Left_Array : constant Boolean := Is_Array_Family (Types, Info.Region, Left);
         Right_Array : constant Boolean := Is_Array_Family (Types, Info.Region, Right);
      begin
         Info.Concatenation_Status := Concatenation_Type_Result_Unknown;
         Info.Concatenation_Left_Subtype := Left_U;
         Info.Concatenation_Right_Subtype := Right_U;
         Info.Normalized_Concatenation_Left_Subtype := To_Unbounded_String (NL);
         Info.Normalized_Concatenation_Right_Subtype := To_Unbounded_String (NR);

      if Left = "" or else Right = "" or else Left = "ambiguous" or else Right = "ambiguous" then
         Info.Concatenation_Status := Concatenation_Type_Operand_Unknown;
         Info.Concatenation_Unknown_Count := 1;
         Info.Operator_Status := Operator_Type_Operand_Unknown;
         Info.Status := Expression_Type_Operator_Unknown;
         return;
      elsif (Left_String and then Right_String) or else
        (Left_String and then Right_Char) or else
        (Left_Char and then Right_String) or else
        (Left_Char and then Right_Char and then NExpected /= "")
      then
         if Left_Char and then Right_Char and then Is_String_Family (NExpected) then
            Info.Concatenation_Status := Concatenation_Type_Expected_Context_Result;
            Info.Concatenation_Result_Subtype := To_Unbounded_String (Expected);
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NExpected);
         else
            Info.Concatenation_Status :=
              (if Left_Char or else Right_Char then
                  Concatenation_Type_Character_String_Compatible
               else
                  Concatenation_Type_String_Compatible);
            Info.Concatenation_Result_Subtype := To_Unbounded_String ("String");
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String ("string");
         end if;
         Info.Concatenation_Compatible_Count := 1;
         Info.Operator_Status := Operator_Type_Resolved_Predefined;
         Info.Operator_Compatible_Operand_Count := 2;
         Info.Status := Expression_Type_Operator_Concatenation;
         Info.Operator_Result_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Operator_Result_Subtype := Info.Normalized_Concatenation_Result_Subtype;
         Info.Inferred_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Concatenation_Result_Subtype;
      elsif Left_Array and then Right_Array and then
        (NL = NR or else NExpected /= "")
      then
         Info.Concatenation_Status :=
           (if NExpected /= "" then Concatenation_Type_Expected_Context_Result
            else Concatenation_Type_Array_Compatible);
         if NExpected /= "" then
            Info.Concatenation_Result_Subtype := To_Unbounded_String (Expected);
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NExpected);
         else
            Info.Concatenation_Result_Subtype := Left_U;
            Info.Normalized_Concatenation_Result_Subtype := To_Unbounded_String (NL);
         end if;
         Info.Concatenation_Compatible_Count := 1;
         Info.Operator_Status := Operator_Type_Resolved_Predefined;
         Info.Operator_Compatible_Operand_Count := 2;
         Info.Status := Expression_Type_Operator_Concatenation;
         Info.Operator_Result_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Operator_Result_Subtype := Info.Normalized_Concatenation_Result_Subtype;
         Info.Inferred_Subtype := Info.Concatenation_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Concatenation_Result_Subtype;
      else
         Info.Concatenation_Status := Concatenation_Type_Operand_Mismatch;
         Info.Concatenation_Mismatch_Count := 1;
         Info.Operator_Status := Operator_Type_Operand_Mismatch;
         Info.Operator_Mismatched_Operand_Count := 1;
         Info.Status := Expression_Type_Operator_Unknown;
      end if;
      end;
   end Apply_Concatenation_Inference;


   procedure Apply_Operator_Overload_Resolution
     (Regions        : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility     : Editor.Ada_Direct_Visibility.Visibility_Model;
      Primitives     : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Info           : in out Expression_Type_Info;
      Use_Primitives : Boolean)
   is
      Symbol : constant String := To_String (Info.Operator_Symbol);
      NL     : constant String := To_String (Info.Normalized_Left_Operand_Subtype);
      NR     : constant String := To_String (Info.Normalized_Right_Operand_Subtype);
      Direct : Editor.Ada_Direct_Visibility.Lookup_Result :=
        (Status => Editor.Ada_Direct_Visibility.Lookup_Not_Found,
         Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
         Region => Info.Region,
         Match_Count => 0);
      Direct_Quoted : Editor.Ada_Direct_Visibility.Lookup_Result := Direct;
      Primitive : Editor.Ada_Direct_Visibility.Lookup_Result := Direct;
      Candidate_Count : Natural := 0;
      Primitive_Selected : Natural := 0;
      Primitive_Mismatched : Natural := 0;
      Operand_Known : constant Boolean := NL /= "" and then
        (NR /= "" or else Symbol = "+" or else Symbol = "-" or else Symbol = "not" or else Symbol = "abs");
   begin
      if Symbol = "" then
         return;
      end if;

      Direct := Editor.Ada_Direct_Visibility.Lookup_Visible
        (Visibility, Regions, Info.Region, Symbol);
      if Direct.Status = Editor.Ada_Direct_Visibility.Lookup_Not_Found then
         Direct_Quoted := Editor.Ada_Direct_Visibility.Lookup_Visible
           (Visibility, Regions, Info.Region, '"' & Symbol & '"');
      end if;

      if Use_Primitives then
         Primitive := Editor.Ada_Use_Type_Operators.Lookup_Operator
           (Primitives, Info.Region, Symbol);
      end if;

      Candidate_Count := Direct.Match_Count + Direct_Quoted.Match_Count + Primitive.Match_Count;
      Info.Operator_Overload_Candidate_Count := Candidate_Count;

      if Candidate_Count = 0 then
         return;
      end if;

      if Use_Primitives then
         for I in 1 .. Editor.Ada_Use_Type_Operators.Primitive_Use_Count (Primitives) loop
            declare
               P : constant Editor.Ada_Use_Type_Operators.Primitive_Use_Info :=
                 Editor.Ada_Use_Type_Operators.Primitive_Use_At (Primitives, I);
               PT : constant String := To_String (P.Normalized_Type_Name);
            begin
               if P.Clause_Region = Info.Region
                 and then P.Status = Editor.Ada_Use_Type_Operators.Primitive_Use_Found
                 and then P.Is_Operator
                 and then To_String (P.Normalized_Primitive) = Normalize (Symbol)
               then
                  if Operand_Known and then
                    (NL = PT or else NR = PT or else
                     (Is_Numeric_Family (NL) and then Is_Numeric_Family (PT)) or else
                     (Is_Numeric_Family (NR) and then Is_Numeric_Family (PT)))
                  then
                     Primitive_Selected := Primitive_Selected + 1;
                  elsif Operand_Known then
                     Primitive_Mismatched := Primitive_Mismatched + 1;
                  end if;
               end if;
            end;
         end loop;
      end if;

      if Primitive_Selected = 1 and then Direct.Match_Count = 0 and then Direct_Quoted.Match_Count = 0 then
         Info.Operator_Status := Operator_Type_Overload_Resolved;
         Info.Operator_Overload_Selected_Count := 1;
         Info.Operator_Compatible_Operand_Count := Natural'Max (Info.Operator_Compatible_Operand_Count, (if NR /= "" then 2 else 1));
         if Is_Relational_Operator (Symbol) or else Is_Boolean_Operator (Symbol) then
            Info.Status := Expression_Type_Operator_Boolean;
            Info.Operator_Result_Subtype := To_Unbounded_String ("Boolean");
            Info.Normalized_Operator_Result_Subtype := To_Unbounded_String ("boolean");
         elsif NL /= "" then
            Info.Status := Expression_Type_Operator_Numeric;
            Info.Operator_Result_Subtype := Info.Left_Operand_Subtype;
            Info.Normalized_Operator_Result_Subtype := Info.Normalized_Left_Operand_Subtype;
         else
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
         Info.Inferred_Subtype := Info.Operator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Operator_Result_Subtype;
      elsif Primitive_Selected > 1 or else Candidate_Count > 1 then
         Info.Operator_Status := Operator_Type_Overload_Ambiguous;
         Info.Operator_Overload_Ambiguous_Count := Candidate_Count;
         Info.Candidate_Count := Natural'Max (Info.Candidate_Count, Candidate_Count);
      elsif Primitive_Mismatched > 0 and then Primitive_Selected = 0 and then
        Direct.Match_Count = 0 and then Direct_Quoted.Match_Count = 0
      then
         Info.Operator_Status := Operator_Type_Overload_Mismatch;
         Info.Operator_Overload_Mismatch_Count := Primitive_Mismatched;
         Info.Operator_Mismatched_Operand_Count := Natural'Max (Info.Operator_Mismatched_Operand_Count, 1);
         Info.Status := Expression_Type_Operator_Unknown;
      elsif not Operand_Known then
         Info.Operator_Status := Operator_Type_Overload_Unknown;
         Info.Operator_Unknown_Operand_Count := Natural'Max (Info.Operator_Unknown_Operand_Count, 1);
      elsif Candidate_Count = 1 and then (Direct.Match_Count = 1 or else Direct_Quoted.Match_Count = 1) then
         Info.Operator_Status := Operator_Type_Overload_Unknown;
         Info.Operator_Overload_Selected_Count := 1;
      end if;
   end Apply_Operator_Overload_Resolution;


   function Infer_One
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info) return Expression_Type_Info;


   procedure Apply_Target_Name_Update_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Expected : Ada.Strings.Unbounded.Unbounded_String :=
        Info.Normalized_Expected_Subtype;
      Has_Source : Boolean := False;
   begin
      if To_String (Expected) = "" then
         declare
            Current : Editor.Ada_Syntax_Tree.Node_Id := Node.Parent;
         begin
            while Current /= Editor.Ada_Syntax_Tree.No_Node loop
               declare
                  Anc : constant Editor.Ada_Syntax_Tree.Node_Info :=
                    Editor.Ada_Syntax_Tree.Node (Tree, Current);
               begin
                  if Anc.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Default and then
                    Anc.Parent /= Editor.Ada_Syntax_Tree.No_Node
                  then
                     declare
                        Grand : constant Editor.Ada_Syntax_Tree.Node_Info :=
                          Editor.Ada_Syntax_Tree.Node (Tree, Anc.Parent);
                        Subtype_Text : constant String :=
                          Subtype_From_Declaration_Label (To_String (Grand.Label));
                     begin
                        if Subtype_Text /= "" then
                           Info.Expected_Subtype := To_Unbounded_String (Subtype_Text);
                           Info.Normalized_Expected_Subtype := To_Unbounded_String (Normalize (Subtype_Text));
                           Expected := Info.Normalized_Expected_Subtype;
                           exit;
                        end if;
                     end;
                  end if;
                  Current := Anc.Parent;
               end;
            end loop;
         end;
      end if;
      Info.Target_Name_Status := Target_Name_Not_Target_Name_Or_Update;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Target_Name then
         if To_String (Expected) = "" then
            Info.Target_Name_Status := Target_Name_Context_Required;
            Info.Target_Name_Unknown_Count := 1;
         else
            Info.Target_Name_Status := Target_Name_Context_Propagated;
            Info.Target_Name_Expected_Subtype := Info.Expected_Subtype;
            Info.Normalized_Target_Name_Expected_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Target_Name_Compatible_Count := 1;
         end if;
         return;
      end if;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate then
         Info.Delta_Update_Count := 1;
         Info.Target_Name_Expected_Subtype := Info.Expected_Subtype;
         Info.Normalized_Target_Name_Expected_Subtype := Info.Normalized_Expected_Subtype;

         if To_String (Expected) = "" then
            Info.Target_Name_Status := Target_Name_Context_Required;
            Info.Target_Name_Unknown_Count := 1;
            return;
         end if;

         for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child    : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Child_Info : constant Expression_Type_Info :=
                 Infer_One (Tree, Regions, Visibility, Types, Static, Calls, Child);
            begin
               if Child.Kind /= Editor.Ada_Syntax_Tree.Node_Target_Name and then
                 To_String (Child_Info.Normalized_Subtype) /= ""
               then
                  Has_Source := True;
                  Info.Target_Name_Source_Subtype := Child_Info.Inferred_Subtype;
                  Info.Normalized_Target_Name_Source_Subtype := Child_Info.Normalized_Subtype;
                  exit;
               end if;
            end;
         end loop;

         if not Has_Source then
            Info.Target_Name_Status := Target_Name_Delta_Update_Unknown;
            Info.Target_Name_Unknown_Count := 1;
         elsif To_String (Info.Normalized_Target_Name_Source_Subtype) = To_String (Expected) or else
           Is_Universal_Compatible (To_String (Info.Normalized_Target_Name_Source_Subtype), To_String (Expected))
         then
            Info.Target_Name_Status := Target_Name_Delta_Update_Compatible;
            Info.Target_Name_Compatible_Count := 1;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         else
            Info.Target_Name_Status := Target_Name_Delta_Update_Mismatch;
            Info.Target_Name_Mismatch_Count := 1;
         end if;
      end if;
   end Apply_Target_Name_Update_Inference;



   function Declaration_Definition_Text
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return String
   is
   begin
      for Index in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node) loop
         declare
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node
                (Tree, Editor.Ada_Syntax_Tree.Child_At (Tree, Node, Index));
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Declaration_Subtype then
               return Trim (To_String (Child.Label));
            end if;
         end;
      end loop;
      return "";
   end Declaration_Definition_Text;

   function Starts_With (Text : String; Prefix : String) return Boolean is
   begin
      return Text'Length >= Prefix'Length and then
        Text (Text'First .. Text'First + Prefix'Length - 1) = Prefix;
   end Starts_With;

   function Drop_Prefix (Text : String; Length : Natural) return String is
      T : constant String := Trim (Text);
   begin
      if T'Length <= Length then
         return "";
      else
         return Trim (T (T'First + Length .. T'Last));
      end if;
   end Drop_Prefix;

   function Strip_Access_Qualifiers (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
   begin
      if T = "" then
         return "";
      elsif Starts_With (N, "not null access") then
         return Drop_Prefix (T, 15);
      elsif Starts_With (N, "access all") then
         return Drop_Prefix (T, 10);
      elsif Starts_With (N, "access constant") then
         return Drop_Prefix (T, 15);
      elsif Starts_With (N, "access") then
         return Drop_Prefix (T, 6);
      else
         return "";
      end if;
   end Strip_Access_Qualifiers;

   function Designated_Subtype_For_Access_Type
     (Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Types : Editor.Ada_Type_Graph.Type_Model;
      Id    : Editor.Ada_Type_Graph.Type_Id) return String
   is
      use type Editor.Ada_Type_Graph.Type_Id;
      use type Editor.Ada_Type_Graph.Type_Category;
   use type Editor.Ada_Use_Type_Operators.Primitive_Use_Status;
   begin
      if Id = Editor.Ada_Type_Graph.No_Type then
         return "";
      end if;
      declare
         T : constant Editor.Ada_Type_Graph.Type_Info :=
           Editor.Ada_Type_Graph.Type_Node (Types, Id);
         Def : constant String := Declaration_Definition_Text (Tree, T.Node);
         Direct : constant String := Strip_Access_Qualifiers (Def);
      begin
         if T.Category /= Editor.Ada_Type_Graph.Type_Category_Access then
            return "";
         elsif Direct /= "" then
            return Direct;
         elsif To_String (T.Base_Subtype) /= "" then
            return Strip_Access_Qualifiers (To_String (T.Base_Subtype));
         else
            return "";
         end if;
      end;
   end Designated_Subtype_For_Access_Type;

   function Object_Subtype_For_Name
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Name       : String;
      Declaration : out Editor.Ada_Direct_Visibility.Declaration_Id;
      Candidates  : out Natural) return String
   is
      Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
        Editor.Ada_Direct_Visibility.Lookup_Visible
          (Visibility, Regions, Region, Primary_Name (Name));
   begin
      Declaration := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidates := Lookup.Match_Count;
      if Lookup.Status /= Editor.Ada_Direct_Visibility.Lookup_Found then
         return "";
      end if;
      Declaration := Lookup.Declaration;
      declare
         Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
         Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
         Subt : constant String := Subtype_From_Declaration_Label (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
      begin
         if Node.Kind = Editor.Ada_Syntax_Tree.Node_Object_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Constant_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Object_Declaration
         then
            return Subt;
         elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Declaration or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Subprogram_Body or else
           Node.Kind = Editor.Ada_Syntax_Tree.Node_Formal_Subprogram_Declaration
         then
            return "subprogram";
         else
            return Subt;
         end if;
      end;
   end Object_Subtype_For_Name;

   function Allocator_Target_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      New_Pos : Natural := 0;
      Start : Natural := 0;
      Stop  : Natural := 0;
      Depth : Natural := 0;
   begin
      if Starts_With (N, "new") then
         New_Pos := T'First;
      else
         New_Pos := Ada.Strings.Fixed.Index (N, " new ");
         if New_Pos /= 0 then
            New_Pos := New_Pos + 1;
         end if;
      end if;
      if New_Pos = 0 then
         return "";
      end if;
      Start := New_Pos + 3;
      while Start <= T'Last and then T (Start) = ' ' loop
         Start := Start + 1;
      end loop;
      if Start > T'Last then
         return "";
      end if;
      Stop := T'Last;
      for I in Start .. T'Last loop
         if T (I) = '(' then
            if Depth = 0 then
               Stop := I - 1;
               exit;
            else
               Depth := Depth + 1;
            end if;
         elsif T (I) = Character'Val (39) then
            Stop := I - 1;
            exit;
         elsif T (I) = ';' then
            Stop := I - 1;
            exit;
         end if;
      end loop;
      if Stop < Start then
         return "";
      else
         return Trim (T (Start .. Stop));
      end if;
   end Allocator_Target_From_Text;

   function Expected_Access_Designated_Subtype (Expected : String) return String is
   begin
      return Strip_Access_Qualifiers (Expected);
   end Expected_Access_Designated_Subtype;


   function Formal_List_Text (Label : String) return String is
      L : constant String := Label;
      Open_Paren  : Natural := 0;
      Close_Paren : Natural := 0;
   begin
      for I in L'Range loop
         if L (I) = '(' then
            Open_Paren := I;
            exit;
         end if;
      end loop;
      if Open_Paren = 0 or else Open_Paren = L'Last then
         return "";
      end if;
      for I in reverse Open_Paren + 1 .. L'Last loop
         if L (I) = ')' then
            Close_Paren := I;
            exit;
         end if;
      end loop;
      if Close_Paren = 0 or else Close_Paren <= Open_Paren + 1 then
         return "";
      end if;
      return L (Open_Paren + 1 .. Close_Paren - 1);
   end Formal_List_Text;

   function Count_Names_In_Formal (Names : String) return Natural is
      T : constant String := Trim (Names);
      Count : Natural := (if T = "" then 0 else 1);
   begin
      for C of T loop
         if C = ',' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Names_In_Formal;

   function Name_At_In_Formal (Names : String; Index : Positive) return String is
      T : constant String := Trim (Names);
      Start : Natural := T'First;
      Current : Positive := 1;
   begin
      for I in T'Range loop
         if T (I) = ',' then
            if Current = Index then
               return Trim (T (Start .. I - 1));
            end if;
            Current := Current + 1;
            Start := I + 1;
         end if;
      end loop;
      if Current = Index and then T /= "" then
         return Trim (T (Start .. T'Last));
      end if;
      return "";
   end Name_At_In_Formal;

   function Clean_Formal_Subtype (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Stop : Natural := 0;
      First : Natural := T'First;
   begin
      if T = "" then
         return "";
      end if;
      if N'Length >= 3 and then N (N'First .. N'First + 2) = "in " then
         First := T'First + 3;
         if N'Length >= 7 and then N (N'First .. N'First + 6) = "in out " then
            First := T'First + 7;
         end if;
      elsif N'Length >= 4 and then N (N'First .. N'First + 3) = "out " then
         First := T'First + 4;
      end if;
      for I in First .. T'Last loop
         if I < T'Last and then T (I) = ':' and then T (I + 1) = '=' then
            Stop := I;
            exit;
         elsif T (I) = ';' or else T (I) = ')' then
            Stop := I;
            exit;
         end if;
      end loop;
      if Stop = 0 then
         return Trim (T (First .. T'Last));
      elsif Stop > First then
         return Trim (T (First .. Stop - 1));
      else
         return "";
      end if;
   end Clean_Formal_Subtype;

   function Formal_Subtype_By_Position (Callable_Label : String; Position : Positive) return String is
      List : constant String := Formal_List_Text (Callable_Label);
      Start : Natural := (if List = "" then 0 else List'First);
      Pos : Natural := 0;
   begin
      if List = "" then
         return "";
      end if;
      for I in List'Range loop
         if List (I) = ';' then
            declare
               Part : constant String := Trim (List (Start .. I - 1));
               Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
            begin
               if Colon /= 0 then
                  declare
                     Names : constant String := Part (Part'First .. Colon - 1);
                     Cnt   : constant Natural := Count_Names_In_Formal (Names);
                  begin
                     if Position > Pos and then Position <= Pos + Cnt then
                        return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                     end if;
                     Pos := Pos + Cnt;
                  end;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;
      declare
         Part : constant String := Trim (List (Start .. List'Last));
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt   : constant Natural := Count_Names_In_Formal (Names);
            begin
               if Position > Pos and then Position <= Pos + Cnt then
                  return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
               end if;
            end;
         end if;
      end;
      return "";
   end Formal_Subtype_By_Position;

   function Formal_Subtype_By_Name (Callable_Label : String; Name : String) return String is
      List : constant String := Formal_List_Text (Callable_Label);
      NName : constant String := Normalize (Name);
      Start : Natural := (if List = "" then 0 else List'First);
   begin
      if List = "" or else NName = "" then
         return "";
      end if;
      for I in List'Range loop
         if List (I) = ';' then
            declare
               Part : constant String := Trim (List (Start .. I - 1));
               Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
            begin
               if Colon /= 0 then
                  declare
                     Names : constant String := Part (Part'First .. Colon - 1);
                     Cnt   : constant Natural := Count_Names_In_Formal (Names);
                  begin
                     for J in 1 .. Cnt loop
                        if Normalize (Name_At_In_Formal (Names, J)) = NName then
                           return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                        end if;
                     end loop;
                  end;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;
      declare
         Part : constant String := Trim (List (Start .. List'Last));
         Colon : constant Natural := Ada.Strings.Fixed.Index (Part, ":");
      begin
         if Colon /= 0 then
            declare
               Names : constant String := Part (Part'First .. Colon - 1);
               Cnt   : constant Natural := Count_Names_In_Formal (Names);
            begin
               for J in 1 .. Cnt loop
                  if Normalize (Name_At_In_Formal (Names, J)) = NName then
                     return Clean_Formal_Subtype (Part (Colon + 1 .. Part'Last));
                  end if;
               end loop;
            end;
         end if;
      end;
      return "";
   end Formal_Subtype_By_Name;

   function Named_Actual_Formal_Name (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow = 0 or else Arrow = Text'First then
         return "";
      end if;
      return Trim (Text (Text'First .. Arrow - 1));
   end Named_Actual_Formal_Name;

   function Actual_Expression_Text (Text : String) return String is
      Arrow : constant Natural := Ada.Strings.Fixed.Index (Text, "=>");
   begin
      if Arrow /= 0 and then Arrow + 2 <= Text'Last then
         return Trim (Text (Arrow + 2 .. Text'Last));
      end if;
      return Trim (Text);
   end Actual_Expression_Text;

   function Infer_Text_Subtype
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Region     : Editor.Ada_Declarative_Regions.Region_Id;
      Text       : String) return String
   is
      T : constant String := Trim (Text);
      NT : constant String := Normalize (T);
      pragma Unreferenced (Tree);
   begin
      if T = "" then
         return "";
      elsif NT = "true" or else NT = "false" then
         return "Boolean";
      elsif NT = "null" then
         return "null";
      elsif (T (T'First) = '"' and then T (T'Last) = '"') then
         return "String";
      elsif T (T'First) in '0' .. '9' then
         declare
            V : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
              Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, T);
         begin
            if V.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
               return "Universal_Integer";
            elsif V.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
               return "Universal_Real";
            end if;
         end;
      else
         declare
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Primary_Name (T));
         begin
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               declare
                  Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                    Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
               begin
                  return Subtype_From_Declaration_Label
                    (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
               end;
            end if;
         end;
      end if;
      return "";
   end Infer_Text_Subtype;

   function Actual_Position_In_Call
     (Tree : Editor.Ada_Syntax_Tree.Tree_Type;
      Call : Editor.Ada_Syntax_Tree.Node_Id;
      Node : Editor.Ada_Syntax_Tree.Node_Info) return Natural
   is
      Count : Natural := 0;
   begin
      if Call = Editor.Ada_Syntax_Tree.No_Node then
         return 0;
      end if;
      for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Call) loop
         declare
            Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
              Editor.Ada_Syntax_Tree.Child_At (Tree, Call, I);
            Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
         begin
            if Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
              Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
              Child.Kind = Editor.Ada_Syntax_Tree.Node_Association or else
              Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
            then
               Count := Count + 1;
               if Child.Id = Node.Id then
                  return Count;
               end if;
            end if;
         end;
      end loop;
      return 0;
   end Actual_Position_In_Call;



   function Callable_Result_Subtype (Callable_Label : String) return String is
      N : constant String := Normalize (Callable_Label);
      R : constant Natural := Ada.Strings.Fixed.Index (N, " return ");
      Original : constant String := Callable_Label;
   begin
      if R = 0 then
         return "";
      end if;
      declare
         Tail : constant String := Trim (Original (Original'First + R + 7 - 1 .. Original'Last));
         Semi : constant Natural := Ada.Strings.Fixed.Index (Tail, ";");
         Is_Pos : constant Natural := Ada.Strings.Fixed.Index (Normalize (Tail), " is");
         End_Pos : Natural := 0;
      begin
         if Semi /= 0 then
            End_Pos := Semi - 1;
         elsif Is_Pos /= 0 then
            End_Pos := Is_Pos - 1;
         else
            End_Pos := Tail'Length;
         end if;
         if End_Pos <= 0 then
            return "";
         end if;
         return Trim (Tail (Tail'First .. Tail'First + End_Pos - 1));
      end;
   end Callable_Result_Subtype;

   function Is_Class_Wide_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return Contains (N, "'class") or else Contains (N, " class");
   end Is_Class_Wide_Subtype;

   function Looks_Primitive_Call_Designator (Text : String) return Boolean is
      T : constant String := Normalize (Text);
   begin
      return Contains (T, ".") or else Contains (T, "(");
   end Looks_Primitive_Call_Designator;

   procedure Apply_Call_Actual_Type_Resolution
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Decl : Editor.Ada_Direct_Visibility.Declaration_Id := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count : Natural := 0;
      Compatible : Natural := 0;
      Mismatch : Natural := 0;
      Unknown : Natural := 0;
      Actual_Count : Natural := 0;
   begin
      Info.Call_Actual_Type_Status := Call_Actual_Type_Not_Call;
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      declare
         Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
           Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Node.Id);
      begin
         if Resolution.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration then
            Decl := Resolution.Declaration;
            Candidate_Count := Resolution.Candidate_Count;
         elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
           Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
         then
            Info.Call_Actual_Type_Status := Call_Actual_Type_Ambiguous_Call;
            Info.Call_Actual_Type_Candidate_Count := Resolution.Candidate_Count;
            return;
         end if;
      end;

      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         declare
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Extract_Designator_Before_Call (To_String (Node.Label)));
         begin
            Candidate_Count := Lookup.Match_Count;
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               Decl := Lookup.Declaration;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
               Info.Call_Actual_Type_Status := Call_Actual_Type_Ambiguous_Call;
               Info.Call_Actual_Type_Candidate_Count := Lookup.Match_Count;
               Info.Status := Expression_Type_Call_Ambiguous;
               Info.Candidate_Count := Lookup.Match_Count;
               return;
            else
               Info.Call_Actual_Type_Status := Call_Actual_Type_Unresolved_Call;
               Info.Status := Expression_Type_Call_Unresolved;
               return;
            end if;
         end;
      end if;

      Info.Call_Actual_Type_Selected_Declaration := Decl;
      Info.Call_Actual_Type_Candidate_Count := Candidate_Count;
      Info.Declaration := Decl;
      Info.Candidate_Count := Candidate_Count;

      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         for I in 1 .. Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) loop
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, I);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
               Formal_Name : constant String :=
                 (if Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
                    Named_Actual_Formal_Name (To_String (Child.Label)) else "");
               Formal_Subtype : constant String :=
                 (if Formal_Name /= "" then Formal_Subtype_By_Name (Label, Formal_Name)
                  else Formal_Subtype_By_Position (Label, Positive (I)));
               Actual_Subtype : constant String :=
                 Infer_Text_Subtype
                   (Tree, Regions, Visibility, Static, Region,
                    Actual_Expression_Text (To_String (Child.Label)));
            begin
               if Child.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
                 Child.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
                 Child.Kind = Editor.Ada_Syntax_Tree.Node_Association or else
                 Child.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
               then
                  Actual_Count := Actual_Count + 1;
                  if Formal_Subtype = "" or else Actual_Subtype = "" then
                     Unknown := Unknown + 1;
                  elsif Simple_Subtype_Compatible (Actual_Subtype, Formal_Subtype) then
                     Compatible := Compatible + 1;
                  else
                     Mismatch := Mismatch + 1;
                  end if;
               end if;
            end;
         end loop;
      end;

      Info.Call_Actual_Type_Compatible_Count := Compatible;
      Info.Call_Actual_Type_Mismatch_Count := Mismatch;
      Info.Call_Actual_Type_Unknown_Count := Unknown;

      if Actual_Count = 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_All_Compatible;
         Info.Status := Expression_Type_Call_Resolved;
      elsif Mismatch /= 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_Actual_Mismatch;
         Info.Status := Expression_Type_Call_Ambiguous;
      elsif Unknown /= 0 then
         Info.Call_Actual_Type_Status := Call_Actual_Type_Actual_Unknown;
         Info.Status := Expression_Type_Call_Unresolved;
      else
         Info.Call_Actual_Type_Status := Call_Actual_Type_All_Compatible;
         Info.Status := Expression_Type_Call_Resolved;
      end if;
   end Apply_Call_Actual_Type_Resolution;


   procedure Apply_Dispatching_Call_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      pragma Unreferenced (Region);
      Decl : constant Editor.Ada_Direct_Visibility.Declaration_Id :=
        Info.Call_Actual_Type_Selected_Declaration;
      Controlling_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Formal_One : Ada.Strings.Unbounded.Unbounded_String;
      Actual_One : Ada.Strings.Unbounded.Unbounded_String;
   begin
      Info.Dispatching_Call_Status := Dispatching_Call_Not_Call;
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      if Info.Call_Actual_Type_Status = Call_Actual_Type_Ambiguous_Call then
         Info.Dispatching_Call_Status := Dispatching_Call_Target_Ambiguous;
         Info.Dispatching_Call_Ambiguous_Count := 1;
         return;
      elsif Info.Call_Actual_Type_Status = Call_Actual_Type_Unresolved_Call or else
        Decl = Editor.Ada_Direct_Visibility.No_Declaration
      then
         Info.Dispatching_Call_Status := Dispatching_Call_Target_Unresolved;
         Info.Dispatching_Call_Unknown_Count := 1;
         return;
      end if;

      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         if not (D.Kind = Editor.Ada_Direct_Visibility.Declaration_Subprogram or else
                 D.Kind = Editor.Ada_Direct_Visibility.Declaration_Entry or else
                 D.Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Subprogram)
         then
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Unknown;
            Info.Dispatching_Call_Unknown_Count := 1;
            return;
         end if;

         Info.Dispatching_Call_Primitive_Count := 1;
         Formal_One := To_Unbounded_String (Formal_Subtype_By_Position (Label, 1));
         Result_Subtype := To_Unbounded_String (Callable_Result_Subtype (Label));

         if Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) >= 1 then
            declare
               Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
                 Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, 1);
               Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
                 Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
            begin
               Actual_One := To_Unbounded_String
                 (Infer_Text_Subtype
                    (Tree, Regions, Visibility, Static,
                     Region_For_Line (Regions, Child.Source_Span.Start_Line),
                     Actual_Expression_Text (To_String (Child.Label))));
            end;
         end if;

         if To_String (Actual_One) /= "" then
            Controlling_Subtype := Actual_One;
         else
            Controlling_Subtype := Formal_One;
         end if;

         Info.Dispatching_Call_Controlling_Subtype := Controlling_Subtype;
         Info.Normalized_Dispatching_Call_Controlling_Subtype :=
           To_Unbounded_String (Normalize (To_String (Controlling_Subtype)));
         Info.Dispatching_Call_Result_Subtype := Result_Subtype;
         Info.Normalized_Dispatching_Call_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Result_Subtype)));

         if Is_Class_Wide_Subtype (To_String (Formal_One)) or else
           Is_Class_Wide_Subtype (To_String (Actual_One)) then
            Info.Dispatching_Call_Status := Dispatching_Call_Dynamic_Dispatch;
            Info.Dispatching_Call_Controlling_Operand_Count := 1;
         elsif Is_Class_Wide_Subtype (To_String (Result_Subtype)) then
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Result;
            Info.Dispatching_Call_Controlling_Result_Count := 1;
         elsif Looks_Primitive_Call_Designator (To_String (Node.Label)) and then
           To_String (Formal_One) /= "" then
            Info.Dispatching_Call_Status := Dispatching_Call_Primitive_Target;
            Info.Dispatching_Call_Controlling_Operand_Count := 1;
         elsif To_String (Formal_One) /= "" or else To_String (Result_Subtype) /= "" then
            Info.Dispatching_Call_Status := Dispatching_Call_Static_Binding;
         else
            Info.Dispatching_Call_Status := Dispatching_Call_Controlling_Unknown;
            Info.Dispatching_Call_Unknown_Count := 1;
         end if;
      end;
   end Apply_Dispatching_Call_Inference;

   procedure Apply_Parameter_Association_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Parent : Editor.Ada_Syntax_Tree.Node_Info;
      Call   : Editor.Ada_Syntax_Tree.Node_Info;
      Assoc  : Editor.Ada_Syntax_Tree.Node_Info := Node;
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Formal_Name : Ada.Strings.Unbounded.Unbounded_String;
      Formal_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Actual_Text : constant String := Actual_Expression_Text (To_String (Node.Label));
      Decl : Editor.Ada_Direct_Visibility.Declaration_Id := Editor.Ada_Direct_Visibility.No_Declaration;
      Candidate_Count : Natural := 0;
   begin
      Info.Parameter_Association_Status := Parameter_Association_Not_Parameter;
      if Node.Parent = Editor.Ada_Syntax_Tree.No_Node then
         return;
      end if;
      Parent := Editor.Ada_Syntax_Tree.Node (Tree, Node.Parent);
      if Parent.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Association
      then
         Assoc := Parent;
         if Parent.Parent = Editor.Ada_Syntax_Tree.No_Node then
            return;
         end if;
         Call := Editor.Ada_Syntax_Tree.Node (Tree, Parent.Parent);
      elsif Parent.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
        Parent.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement
      then
         Call := Parent;
      else
         return;
      end if;
      if not (Call.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call or else
              Call.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement)
      then
         return;
      end if;

      Info.Parameter_Association_Call := Call.Id;
      Info.Parameter_Association_Position := Actual_Position_In_Call (Tree, Call.Id, Assoc);
      if Assoc.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association then
         Formal_Name := To_Unbounded_String (Named_Actual_Formal_Name (To_String (Assoc.Label)));
      end if;

      declare
         Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
           Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Call.Id);
      begin
         if Resolution.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration then
            Decl := Resolution.Declaration;
            Candidate_Count := Resolution.Candidate_Count;
         end if;
      end;
      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         declare
            Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
              Editor.Ada_Direct_Visibility.Lookup_Visible
                (Visibility, Regions, Region, Extract_Designator_Before_Call (To_String (Call.Label)));
         begin
            Candidate_Count := Lookup.Match_Count;
            if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
               Decl := Lookup.Declaration;
            elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
               Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Ambiguous;
               Info.Candidate_Count := Lookup.Match_Count;
               return;
            else
               Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Unresolved;
               return;
            end if;
         end;
      end if;

      Info.Candidate_Count := Candidate_Count;
      if Decl = Editor.Ada_Direct_Visibility.No_Declaration then
         Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Unresolved;
         return;
      end if;
      declare
         D : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
           Editor.Ada_Direct_Visibility.Declaration (Visibility, Decl);
         D_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, D.Node);
         Label : constant String := To_String (D_Node.Label);
      begin
         if To_String (Formal_Name) /= "" then
            Formal_Subtype := To_Unbounded_String
              (Formal_Subtype_By_Name (Label, To_String (Formal_Name)));
         elsif Info.Parameter_Association_Position /= 0 then
            Formal_Subtype := To_Unbounded_String
              (Formal_Subtype_By_Position (Label, Positive (Info.Parameter_Association_Position)));
         end if;
      end;

      if To_String (Formal_Subtype) = "" then
         Info.Parameter_Association_Status := Parameter_Association_Unknown;
         return;
      end if;

      Actual_Subtype := To_Unbounded_String
        (Infer_Text_Subtype (Tree, Regions, Visibility, Static, Region, Actual_Text));
      Info.Parameter_Association_Formal_Name := Formal_Name;
      Info.Normalized_Parameter_Association_Formal_Name :=
        To_Unbounded_String (Normalize (To_String (Formal_Name)));
      Info.Parameter_Association_Formal_Subtype := Formal_Subtype;
      Info.Normalized_Parameter_Association_Formal_Subtype :=
        To_Unbounded_String (Normalize (To_String (Formal_Subtype)));
      Info.Parameter_Association_Actual_Subtype := Actual_Subtype;
      Info.Normalized_Parameter_Association_Actual_Subtype :=
        To_Unbounded_String (Normalize (To_String (Actual_Subtype)));
      Info.Expected_Subtype := Formal_Subtype;
      Info.Normalized_Expected_Subtype := Info.Normalized_Parameter_Association_Formal_Subtype;
      Info.Expected_Status := Expected_Type_Context_Found;
      Info.Parameter_Association_Status := Parameter_Association_Formal_Context_Found;

      if To_String (Actual_Subtype) /= "" and then
        Simple_Subtype_Compatible (To_String (Actual_Subtype), To_String (Formal_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
         Info.Parameter_Association_Status := Parameter_Association_Compatible;
      elsif To_String (Info.Normalized_Subtype) /= "" and then
        Simple_Subtype_Compatible (To_String (Info.Normalized_Subtype), To_String (Formal_Subtype))
      then
         Info.Expected_Status := Expected_Type_Compatible;
         Info.Parameter_Association_Status := Parameter_Association_Compatible;
      elsif To_String (Actual_Subtype) = "" and then To_String (Info.Normalized_Subtype) = "" then
         Info.Expected_Status := Expected_Type_Propagated;
         Info.Inferred_Subtype := Formal_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         Info.Parameter_Association_Status := Parameter_Association_Expected_Propagated;
      else
         Info.Expected_Status := Expected_Type_Mismatch;
         Info.Parameter_Association_Status := Parameter_Association_Mismatch;
      end if;
   end Apply_Parameter_Association_Inference;


   function Is_Integer_Expected_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return N = "integer" or else N = "natural" or else N = "positive" or else
        Contains (N, "integer") or else Contains (N, "natural") or else
        Contains (N, "positive") or else Contains (N, "count") or else
        Contains (N, "range");
   end Is_Integer_Expected_Subtype;

   function Is_Real_Expected_Subtype (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return N = "float" or else N = "long_float" or else N = "duration" or else
        Contains (N, "float") or else Contains (N, "real") or else
        Contains (N, "duration");
   end Is_Real_Expected_Subtype;

   function Has_Static_Integer_Bounds
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Text   : String) return Boolean
   is
      NText : constant String := Normalize (Text);
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Static) loop
         declare
            Bound : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Static, Index);
         begin
            if To_String (Bound.Normalized_Name) = NText and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.First_Value) and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.Last_Value)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Static_Integer_Bounds;


   function Looks_Modular_Expected_Subtype
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return Boolean
   is
   begin
      return Editor.Ada_Static_Expressions.Lookup_Modular_Type (Static, Region, Text) /=
        Editor.Ada_Static_Expressions.No_Static_Modular_Type;
   end Looks_Modular_Expected_Subtype;

   function Looks_Fixed_Expected_Subtype
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Text   : String) return Boolean
   is
   begin
      return Editor.Ada_Static_Expressions.Lookup_Fixed_Type (Static, Region, Text) /=
        Editor.Ada_Static_Expressions.No_Static_Fixed_Type;
   end Looks_Fixed_Expected_Subtype;

   procedure Apply_Integer_Range_Metadata
     (Static : Editor.Ada_Static_Expressions.Static_Model;
      Region : Editor.Ada_Declarative_Regions.Region_Id;
      Expected : String;
      Value : Long_Long_Integer;
      Info : in out Expression_Type_Info)
   is
      pragma Unreferenced (Region);
      NExpected : constant String := Normalize (Expected);
   begin
      for Index in 1 .. Editor.Ada_Static_Expressions.Static_Type_Bound_Count (Static) loop
         declare
            Bound : constant Editor.Ada_Static_Expressions.Static_Type_Bound_Info :=
              Editor.Ada_Static_Expressions.Static_Type_Bound_At (Static, Index);
         begin
            if To_String (Bound.Normalized_Name) = NExpected and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.First_Value) and then
              Editor.Ada_Static_Expressions.Is_Static_Integer (Bound.Last_Value)
            then
               Info.Universal_Numeric_Has_Range := True;
               Info.Universal_Numeric_First_Value := Bound.First_Value.Integer_Value;
               Info.Universal_Numeric_Last_Value := Bound.Last_Value.Integer_Value;
               if Value < Bound.First_Value.Integer_Value or else
                 Value > Bound.Last_Value.Integer_Value
               then
                  Info.Universal_Numeric_Status := Universal_Numeric_Range_Error;
                  Info.Expected_Status := Expected_Type_Mismatch;
               elsif Info.Universal_Numeric_Status /= Universal_Numeric_Range_Error then
                  Info.Universal_Numeric_Status := Universal_Numeric_Range_Compatible;
               end if;
               return;
            end if;
         end;
      end loop;
   end Apply_Integer_Range_Metadata;

   procedure Apply_Universal_Numeric_Resolution
     (Static  : Editor.Ada_Static_Expressions.Static_Model;
      Regions : Editor.Ada_Declarative_Regions.Region_Model;
      Info    : in out Expression_Type_Info;
      Node    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Inferred : constant String := To_String (Info.Normalized_Subtype);
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Value : Editor.Ada_Static_Expressions.Static_Value_Info;
   begin
      Info.Universal_Numeric_Status := Universal_Numeric_Not_Universal;

      if Expected = "" or else NExpected = "" then
         return;
      end if;

      if Inferred /= "universal_integer" and then Inferred /= "universal_real" then
         return;
      end if;

      Info.Universal_Numeric_Status := Universal_Numeric_Expected_Context_Found;
      Info.Universal_Numeric_Expected_Subtype := Info.Expected_Subtype;
      Info.Normalized_Universal_Numeric_Expected_Subtype := Info.Normalized_Expected_Subtype;
      Value := Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression
        (Static, Region, To_String (Info.Expression_Text));
      Info.Universal_Numeric_Static_Status := Value.Status;
      Info.Universal_Numeric_Integer_Value := Value.Integer_Value;
      Info.Universal_Numeric_Real_Value := Value.Real_Value;

      if Inferred = "universal_integer" then
         if Looks_Modular_Expected_Subtype (Static, Region, Expected) then
            Info.Universal_Numeric_Status := Universal_Numeric_Modular_Resolved;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         elsif Is_Integer_Expected_Subtype (Expected) or else Has_Static_Integer_Bounds (Static, Expected) then
            Info.Universal_Numeric_Status := Universal_Numeric_Integer_Resolved;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
            if Editor.Ada_Static_Expressions.Is_Static_Integer (Value) then
               Apply_Integer_Range_Metadata (Static, Region, Expected, Value.Integer_Value, Info);
            elsif Value.Status /= Editor.Ada_Static_Expressions.Static_Value_Not_Checked then
               Info.Universal_Numeric_Status := Universal_Numeric_Static_Unknown;
            end if;
         elsif Is_Real_Expected_Subtype (Expected) or else Looks_Fixed_Expected_Subtype (Static, Region, Expected) then
            if Looks_Fixed_Expected_Subtype (Static, Region, Expected) then
               Info.Universal_Numeric_Status := Universal_Numeric_Fixed_Resolved;
            else
               Info.Universal_Numeric_Status := Universal_Numeric_Real_Resolved;
            end if;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Universal_Numeric_Status := Universal_Numeric_Expected_Mismatch;
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      elsif Inferred = "universal_real" then
         if Is_Real_Expected_Subtype (Expected) or else Looks_Fixed_Expected_Subtype (Static, Region, Expected) then
            if Looks_Fixed_Expected_Subtype (Static, Region, Expected) then
               Info.Universal_Numeric_Status := Universal_Numeric_Fixed_Resolved;
            else
               Info.Universal_Numeric_Status := Universal_Numeric_Real_Resolved;
            end if;
            Info.Universal_Numeric_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Universal_Numeric_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Expected_Status := Expected_Type_Compatible;
         else
            Info.Universal_Numeric_Status := Universal_Numeric_Expected_Mismatch;
            Info.Expected_Status := Expected_Type_Mismatch;
         end if;
      end if;
   end Apply_Universal_Numeric_Resolution;


   procedure Apply_Allocator_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Visibility);
      Text   : constant String := To_String (Node.Label);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Target : constant String := Allocator_Target_From_Text (Text);
      Expected : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Designated : Ada.Strings.Unbounded.Unbounded_String;
      Target_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
   begin
      Info.Allocator_Status := Allocator_Type_Not_Allocator;
      if Node.Kind /= Editor.Ada_Syntax_Tree.Node_Allocator then
         return;
      end if;

      Info.Status := Expression_Type_Allocator;
      if Target = "" then
         Info.Allocator_Status := Allocator_Type_Malformed;
         Info.Inferred_Subtype := To_Unbounded_String ("allocator_result_unknown");
         Info.Normalized_Subtype := To_Unbounded_String ("allocator_result_unknown");
         return;
      end if;

      Info.Allocator_Target_Subtype := To_Unbounded_String (Target);
      Info.Normalized_Allocator_Target_Subtype := To_Unbounded_String (Normalize (Target));
      Target_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Target);
      if Target_Type /= Editor.Ada_Type_Graph.No_Type then
         Info.Type_Id := Target_Type;
         Info.Allocator_Status := Allocator_Type_Target_Resolved;
      else
         --  Keep predefined and still-unindexed target subtype marks as staged
         --  subtype text.  A later full type checker can decide whether the
         --  target is a legal subtype mark; this pass should not drop useful
         --  allocator metadata merely because the type graph is incomplete.
         Info.Allocator_Status := Allocator_Type_Target_Unresolved;
      end if;

      if NExpected /= "" then
         Info.Allocator_Expected_Access_Subtype := Info.Expected_Subtype;
         Info.Normalized_Allocator_Expected_Access_Subtype := Info.Normalized_Expected_Subtype;
         Designated := To_Unbounded_String (Expected_Access_Designated_Subtype (Expected));
         if To_String (Designated) = "" then
            declare
               Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                 Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Expected);
            begin
               if Expected_Type /= Editor.Ada_Type_Graph.No_Type then
                  Designated := To_Unbounded_String
                    (Designated_Subtype_For_Access_Type (Tree, Types, Expected_Type));
               end if;
            end;
         end if;
         if To_String (Designated) = "" then
            Info.Allocator_Status := Allocator_Type_Expected_Not_Access;
            Info.Allocator_Result_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Normalized_Allocator_Result_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;
            return;
         end if;

         Info.Allocator_Designated_Subtype := Designated;
         Info.Normalized_Allocator_Designated_Subtype :=
           To_Unbounded_String (Normalize (To_String (Designated)));
         Info.Allocator_Result_Subtype := Info.Expected_Subtype;
         Info.Normalized_Allocator_Result_Subtype := Info.Normalized_Expected_Subtype;
         Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;

         if Normalize (Target) = Normalize (To_String (Designated)) or else
           Subtype_Compatible_By_Graph (Types, Region, To_String (Designated), Target)
         then
            Info.Allocator_Status := Allocator_Type_Designated_Compatible;
         else
            Info.Allocator_Status := Allocator_Type_Designated_Mismatch;
         end if;
      else
         Info.Allocator_Result_Subtype := To_Unbounded_String ("access " & Target);
         Info.Normalized_Allocator_Result_Subtype :=
           To_Unbounded_String (Normalize ("access " & Target));
         Info.Inferred_Subtype := Info.Allocator_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Allocator_Result_Subtype;
         Info.Allocator_Designated_Subtype := To_Unbounded_String (Target);
         Info.Normalized_Allocator_Designated_Subtype := To_Unbounded_String (Normalize (Target));
         Info.Allocator_Status := Allocator_Type_Result_Known;
      end if;
   end Apply_Allocator_Inference;




   function Looks_Like_Raise_Text (Text : String) return Boolean is
      N : constant String := Normalize (Text);
   begin
      return Starts_With (N, "raise") or else Contains (N, " raise ");
   end Looks_Like_Raise_Text;

   function Raise_Target_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Start : Natural := 0;
      Stop  : Natural := 0;
      With_Pos : Natural := 0;
   begin
      if Starts_With (N, "raise") then
         Start := T'First + 5;
      else
         Start := Ada.Strings.Fixed.Index (N, " raise ");
         if Start = 0 then
            return "";
         end if;
         Start := Start + 7;
      end if;
      while Start <= T'Last and then T (Start) = ' ' loop
         Start := Start + 1;
      end loop;
      if Start > T'Last then
         return "";
      end if;
      With_Pos := Ada.Strings.Fixed.Index (N, " with ");
      if With_Pos /= 0 and then With_Pos > Start then
         Stop := With_Pos - 1;
      else
         Stop := T'Last;
      end if;
      return Trim (T (Start .. Stop));
   end Raise_Target_From_Text;

   function Raise_Message_From_Text (Text : String) return String is
      T : constant String := Trim (Text);
      N : constant String := Normalize (T);
      Pos : constant Natural := Ada.Strings.Fixed.Index (N, " with ");
   begin
      if Pos = 0 or else Pos + 6 > T'Last then
         return "";
      end if;
      return Trim (T (Pos + 6 .. T'Last));
   end Raise_Message_From_Text;

   function Looks_Like_Boolean_Context (Kind : Editor.Ada_Syntax_Tree.Node_Kind; Text : String) return Boolean is
      Lower : constant String := Normalize (Text);
   begin
      return Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression
        or else Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression
        or else Contains (Lower, " and then ")
        or else Contains (Lower, " or else ")
        or else Contains (Lower, " not ")
        or else Contains (Lower, "if ")
        or else Contains (Lower, " while ")
        or else Contains (Lower, " when ")
        or else Contains (Lower, "exit when")
        or else Contains (Lower, "for all ")
        or else Contains (Lower, "for some ");
   end Looks_Like_Boolean_Context;

   function Boolean_Operand_Status (Subtype_Name : String) return Boolean_Context_Inference_Status is
      N : constant String := Normalize (Subtype_Name);
   begin
      if N = "boolean" or else N = "standard.boolean" then
         return Boolean_Context_Operand_Compatible;
      elsif N = "" or else N = "unknown" or else N = "indeterminate" then
         return Boolean_Context_Operand_Unknown;
      else
         return Boolean_Context_Operand_Mismatch;
      end if;
   end Boolean_Operand_Status;

   procedure Apply_Boolean_Context_Inference
     (Info : in out Expression_Type_Info;
      N    : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text : constant String := To_String (N.Label);
      Operand_Status : Boolean_Context_Inference_Status;
   begin
      Info.Boolean_Context_Status := Boolean_Context_Not_Boolean_Context;
      Info.Boolean_Context_Expected_Subtype := To_Unbounded_String ("Boolean");
      Info.Normalized_Boolean_Context_Expected_Subtype := To_Unbounded_String ("boolean");

      if not Looks_Like_Boolean_Context (N.Kind, Text) then
         return;
      end if;

      Info.Boolean_Context_Status := Boolean_Context_Expected_Boolean;

      if To_String (Info.Normalized_Subtype) /= "" then
         Info.Boolean_Context_Expression_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Boolean_Context_Expression_Subtype := Info.Normalized_Subtype;
      elsif To_String (Info.Normalized_Expected_Subtype) /= "" then
         Info.Boolean_Context_Expression_Subtype := Info.Expected_Subtype;
         Info.Normalized_Boolean_Context_Expression_Subtype := Info.Normalized_Expected_Subtype;
      else
         Info.Boolean_Context_Expression_Subtype := To_Unbounded_String ("unknown");
         Info.Normalized_Boolean_Context_Expression_Subtype := To_Unbounded_String ("unknown");
      end if;

      Operand_Status := Boolean_Operand_Status
        (To_String (Info.Normalized_Boolean_Context_Expression_Subtype));

      if Operand_Status = Boolean_Context_Operand_Compatible then
         Info.Boolean_Context_Compatible_Count := Info.Boolean_Context_Compatible_Count + 1;
         if N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
           Contains (Normalize (Text), " and then ") or else
           Contains (Normalize (Text), " or else ")
         then
            Info.Boolean_Context_Status := Boolean_Context_Short_Circuit_Compatible;
         else
            Info.Boolean_Context_Status := Boolean_Context_Condition_Compatible;
         end if;
      elsif Operand_Status = Boolean_Context_Operand_Mismatch then
         Info.Boolean_Context_Mismatch_Count := Info.Boolean_Context_Mismatch_Count + 1;
         if N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
           Contains (Normalize (Text), " and then ") or else
           Contains (Normalize (Text), " or else ")
         then
            Info.Boolean_Context_Status := Boolean_Context_Short_Circuit_Mismatch;
         else
            Info.Boolean_Context_Status := Boolean_Context_Condition_Mismatch;
         end if;
      else
         Info.Boolean_Context_Unknown_Count := Info.Boolean_Context_Unknown_Count + 1;
         Info.Boolean_Context_Status := Boolean_Context_Condition_Unknown;
      end if;
   end Apply_Boolean_Context_Inference;

   procedure Apply_Raise_No_Return_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text    : constant String := To_String (Node.Label);
      Target  : constant String := Raise_Target_From_Text (Text);
      Message : constant String := Raise_Message_From_Text (Text);
   begin
      Info.Raise_No_Return_Status := Raise_No_Return_Not_Raise;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement or else
        Looks_Like_Raise_Text (Text)
      then
         Info.Status := Expression_Type_Raise;
         if Node.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement then
            Info.Raise_No_Return_Status := Raise_No_Return_Raise_Statement;
         else
            Info.Raise_No_Return_Status := Raise_No_Return_Raise_Expression;
         end if;

         if Target /= "" then
            Info.Raise_Exception_Target := To_Unbounded_String (Target);
            Info.Normalized_Raise_Exception_Target := To_Unbounded_String (Normalize (Target));
            Info.Raise_No_Return_Status := Raise_No_Return_Exception_Target_Known;
         else
            Info.Raise_No_Return_Status := Raise_No_Return_Exception_Target_Unknown;
         end if;

         if Message /= "" then
            if Is_String_Literal (Message) then
               Info.Raise_Message_Subtype := To_Unbounded_String ("String");
               Info.Normalized_Raise_Message_Subtype := To_Unbounded_String ("string");
               Info.Raise_No_Return_Status := Raise_No_Return_With_Message;
            else
               Info.Raise_Message_Subtype := To_Unbounded_String ("message_expression_unknown");
               Info.Normalized_Raise_Message_Subtype := To_Unbounded_String ("message_expression_unknown");
               Info.Raise_No_Return_Status := Raise_No_Return_Message_Unknown;
            end if;
         end if;

         if To_String (Info.Normalized_Expected_Subtype) /= "" then
            Info.Raise_Result_Subtype := Info.Expected_Subtype;
            Info.Normalized_Raise_Result_Subtype := Info.Normalized_Expected_Subtype;
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            if Message = "" then
               Info.Raise_No_Return_Status := Raise_No_Return_Result_Context_Propagated;
            end if;
         else
            Info.Raise_Result_Subtype := To_Unbounded_String ("raise_result_context_unknown");
            Info.Normalized_Raise_Result_Subtype := To_Unbounded_String ("raise_result_context_unknown");
            Info.Inferred_Subtype := Info.Raise_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Raise_Result_Subtype;
            if Message = "" then
               Info.Raise_No_Return_Status := Raise_No_Return_Result_Context_Unknown;
            end if;
         end if;
         return;
      end if;

      if Info.Status = Expression_Type_Call_Resolved and then
        Info.Declaration /= Editor.Ada_Direct_Visibility.No_Declaration
      then
         declare
            Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
              Editor.Ada_Direct_Visibility.Declaration (Visibility, Info.Declaration);
            Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
              Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
            Decl_Text : constant String := Normalize (To_String (Decl_Node.Label));
         begin
            if Contains (Decl_Text, "no_return") or else Contains (Decl_Text, "noreturn") then
               Info.Status := Expression_Type_No_Return_Call;
               Info.Raise_No_Return_Status := Raise_No_Return_No_Return_Call;
            end if;
         end;
      end if;
   end Apply_Raise_No_Return_Inference;

   procedure Apply_Dereference_Access_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text   : constant String := To_String (Node.Label);
      NText  : constant String := Normalize (Text);
      Region : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
   begin
      Info.Dereference_Access_Status := Dereference_Access_Not_Dereference_Or_Access;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Explicit_Dereference then
         declare
            Mark : constant Natural := Ada.Strings.Fixed.Index (NText, ".all");
            Prefix : constant String :=
              (if Mark = 0 or else Mark <= Text'First then "" else Trim (Text (Text'First .. Mark - 1)));
            Decl : Editor.Ada_Direct_Visibility.Declaration_Id;
            Candidate_Count : Natural := 0;
            Prefix_Subtype : constant String :=
              Object_Subtype_For_Name
                (Tree, Regions, Visibility, Region, Prefix, Decl, Candidate_Count);
            Prefix_Type : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
            Designated : Ada.Strings.Unbounded.Unbounded_String;
         begin
            Info.Status := Expression_Type_Dereference;
            Info.Candidate_Count := Candidate_Count;
            if Prefix = "" or else Decl = Editor.Ada_Direct_Visibility.No_Declaration then
               Info.Dereference_Access_Status := Dereference_Prefix_Unresolved;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");
               return;
            end if;

            Info.Declaration := Decl;
            Info.Dereference_Prefix_Subtype := To_Unbounded_String (Prefix_Subtype);
            Info.Normalized_Dereference_Prefix_Subtype :=
              To_Unbounded_String (Normalize (Prefix_Subtype));
            Prefix_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix_Subtype);
            Info.Type_Id := Prefix_Type;
            if Prefix_Type = Editor.Ada_Type_Graph.No_Type and then
              Strip_Access_Qualifiers (Prefix_Subtype) /= ""
            then
               Designated := To_Unbounded_String (Strip_Access_Qualifiers (Prefix_Subtype));
            elsif Prefix_Type /= Editor.Ada_Type_Graph.No_Type then
               Designated := To_Unbounded_String
                 (Designated_Subtype_For_Access_Type (Tree, Types, Prefix_Type));
            end if;

            if Prefix_Type = Editor.Ada_Type_Graph.No_Type and then To_String (Designated) = "" then
               Info.Dereference_Access_Status := Dereference_Prefix_Not_Access_Type;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");
            elsif To_String (Designated) = "" then
               Info.Dereference_Access_Status := Dereference_Designated_Subtype_Unknown;
               Info.Inferred_Subtype := To_Unbounded_String ("dereference_designated_unknown");
               Info.Normalized_Subtype := To_Unbounded_String ("dereference_designated_unknown");
            else
               Info.Dereference_Access_Status := Dereference_Designated_Subtype_Known;
               Info.Dereference_Designated_Subtype := Designated;
               Info.Normalized_Dereference_Designated_Subtype :=
                 To_Unbounded_String (Normalize (To_String (Designated)));
               Info.Inferred_Subtype := Info.Dereference_Designated_Subtype;
               Info.Normalized_Subtype := Info.Normalized_Dereference_Designated_Subtype;
            end if;
         end;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Attribute_Reference then
         declare
            Prefix : constant String := Attribute_Prefix_From_Text (Text);
            Attr   : constant String := Normalize (Attribute_Name_From_Text (Text));
            Decl : Editor.Ada_Direct_Visibility.Declaration_Id;
            Candidate_Count : Natural := 0;
            Target_Subtype : constant String :=
              Object_Subtype_For_Name
                (Tree, Regions, Visibility, Region, Prefix, Decl, Candidate_Count);
            Result_Subtype : Ada.Strings.Unbounded.Unbounded_String;
         begin
            if not (Attr = "access" or else Attr = "unchecked_access" or else
                    Attr = "unrestricted_access")
            then
               return;
            end if;

            Info.Candidate_Count := Candidate_Count;
            if Decl = Editor.Ada_Direct_Visibility.No_Declaration or else Target_Subtype = "" then
               Info.Dereference_Access_Status := Access_Attribute_Target_Unresolved;
               Info.Access_Result_Subtype := To_Unbounded_String ("access_result_unknown");
               Info.Normalized_Access_Result_Subtype := To_Unbounded_String ("access_result_unknown");
               return;
            end if;

            Info.Declaration := Decl;
            Info.Dereference_Access_Status := Access_Attribute_Target_Resolved;
            Info.Access_Target_Subtype := To_Unbounded_String (Target_Subtype);
            Info.Normalized_Access_Target_Subtype :=
              To_Unbounded_String (Normalize (Target_Subtype));
            if Normalize (Target_Subtype) = "subprogram" then
               Result_Subtype := To_Unbounded_String ("access subprogram");
            else
               Result_Subtype := To_Unbounded_String ("access " & Target_Subtype);
            end if;
            Info.Access_Result_Subtype := Result_Subtype;
            Info.Normalized_Access_Result_Subtype :=
              To_Unbounded_String (Normalize (To_String (Result_Subtype)));
            Info.Attribute_Result_Subtype := Info.Access_Result_Subtype;
            Info.Normalized_Attribute_Result_Subtype := Info.Normalized_Access_Result_Subtype;
            Info.Inferred_Subtype := Info.Access_Result_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Access_Result_Subtype;
            Info.Dereference_Access_Status := Access_Attribute_Result_Known;
         end;
      end if;
   end Apply_Dereference_Access_Inference;


   procedure Apply_Indexed_Slice_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      pragma Unreferenced (Static, Calls);
      Text     : constant String := To_String (Node.Label);
      Prefix   : constant String := Extract_Designator_Before_Call (Text);
      Region   : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Prefix_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Prefix_Type    : Editor.Ada_Type_Graph.Type_Id := Editor.Ada_Type_Graph.No_Type;
      Element_Subtype : Ada.Strings.Unbounded.Unbounded_String;
      Index_Subtype   : Ada.Strings.Unbounded.Unbounded_String;
      Index_Count     : Natural := 0;
   begin
      Info.Indexed_Slice_Status := Indexed_Slice_Not_Indexed_Or_Slice;

      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Indexed_Component or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Slice)
      then
         return;
      end if;

      if Prefix = "" then
         Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Unresolved;
         Info.Indexed_Slice_Unknown_Index_Count := 1;
         return;
      end if;

      declare
         Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
           Editor.Ada_Direct_Visibility.Lookup_Visible
             (Visibility, Regions, Region, Primary_Name (Prefix));
      begin
         if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
            declare
               Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                 Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
               Subt : constant String := Subtype_From_Declaration_Label (To_String (Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node).Label));
            begin
               if Subt /= "" then
                  Prefix_Subtype := To_Unbounded_String (Subt);
                  Prefix_Type := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Subt);
               else
                  Prefix_Subtype := Decl.Name;
                  Prefix_Type := Editor.Ada_Type_Graph.Type_For_Declaration (Types, Lookup.Declaration);
               end if;
            end;
         elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
            Info.Indexed_Slice_Status := Indexed_Slice_Result_Unknown;
            Info.Candidate_Count := 2;
            Info.Indexed_Slice_Unknown_Index_Count := 1;
            return;
         else
            Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Unresolved;
            Info.Indexed_Slice_Unknown_Index_Count := 1;
            return;
         end if;
      end;

      Info.Indexed_Slice_Status := Indexed_Slice_Prefix_Resolved;
      Info.Indexed_Slice_Prefix_Subtype := Prefix_Subtype;
      Info.Normalized_Indexed_Slice_Prefix_Subtype :=
        To_Unbounded_String (Normalize (To_String (Prefix_Subtype)));
      Info.Type_Id := Prefix_Type;

      if Prefix_Type /= Editor.Ada_Type_Graph.No_Type then
         declare
            T : constant Editor.Ada_Type_Graph.Type_Info :=
              Editor.Ada_Type_Graph.Type_Node (Types, Prefix_Type);
            Base : constant String := To_String (T.Base_Subtype);
         begin
            if T.Category = Editor.Ada_Type_Graph.Type_Category_Array then
               Element_Subtype := To_Unbounded_String (Extract_Array_Element_Subtype (Base));
               Index_Subtype := To_Unbounded_String (Extract_Array_Index_Subtype (Base));
            elsif T.Category = Editor.Ada_Type_Graph.Type_Category_Subtype or else
              T.Category = Editor.Ada_Type_Graph.Type_Category_Derived
            then
               Element_Subtype := To_Unbounded_String (Extract_Array_Element_Subtype (Base));
               Index_Subtype := To_Unbounded_String (Extract_Array_Index_Subtype (Base));
            end if;
         end;
      end if;

      if To_String (Element_Subtype) = "" then
         Element_Subtype := To_Unbounded_String
           (Extract_Array_Element_Subtype (To_String (Prefix_Subtype)));
      end if;
      if To_String (Index_Subtype) = "" then
         Index_Subtype := To_Unbounded_String
           (Extract_Array_Index_Subtype (To_String (Prefix_Subtype)));
      end if;
      if To_String (Element_Subtype) = "" and then
        Contains (Normalize (To_String (Prefix_Subtype)), "string")
      then
         Element_Subtype := To_Unbounded_String ("Character");
         Index_Subtype := To_Unbounded_String ("Positive");
      end if;

      Info.Indexed_Slice_Index_Subtype := Index_Subtype;
      Info.Normalized_Indexed_Slice_Index_Subtype :=
        To_Unbounded_String (Normalize (To_String (Index_Subtype)));

      if Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) > 1 then
         Index_Count := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id) - 1;
      else
         Index_Count := Count_Commas (Text) + 1;
      end if;
      Info.Indexed_Slice_Index_Count := Index_Count;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Slice then
         Info.Status := Expression_Type_Slice;
         Info.Indexed_Slice_Result_Subtype := Prefix_Subtype;
         Info.Normalized_Indexed_Slice_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Prefix_Subtype)));
         Info.Inferred_Subtype := Info.Indexed_Slice_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Indexed_Slice_Result_Subtype;
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Array;
      elsif To_String (Element_Subtype) /= "" then
         Info.Status := Expression_Type_Indexed_Component;
         Info.Indexed_Slice_Result_Subtype := Element_Subtype;
         Info.Normalized_Indexed_Slice_Result_Subtype :=
           To_Unbounded_String (Normalize (To_String (Element_Subtype)));
         Info.Inferred_Subtype := Info.Indexed_Slice_Result_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Indexed_Slice_Result_Subtype;
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Element;
      else
         Info.Status := Expression_Type_Indexed_Component;
         Info.Inferred_Subtype := To_Unbounded_String ("indexed_result_unknown");
         Info.Normalized_Subtype := To_Unbounded_String ("indexed_result_unknown");
         Info.Indexed_Slice_Status := Indexed_Slice_Result_Unknown;
         Info.Indexed_Slice_Unknown_Index_Count := 1;
      end if;

      if To_String (Index_Subtype) = "" then
         Info.Indexed_Slice_Unknown_Index_Count := Info.Indexed_Slice_Unknown_Index_Count + 1;
      else
         Info.Indexed_Slice_Compatible_Index_Count := Index_Count;
         if Info.Indexed_Slice_Status = Indexed_Slice_Result_Element or else
           Info.Indexed_Slice_Status = Indexed_Slice_Result_Array
         then
            Info.Indexed_Slice_Status := Indexed_Slice_Index_Compatible;
         end if;
      end if;
   end Apply_Indexed_Slice_Inference;


   procedure Apply_Membership_Range_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text  : constant String := Normalize (To_String (Node.Label));
      Left  : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 1);
      Right : constant String :=
        Infer_Operand_Subtype (Tree, Regions, Visibility, Types, Static, Calls, Node, 2);
      NL    : constant String := Normalize (Left);
      NR    : constant String := Normalize (Right);
   begin
      Info.Membership_Range_Status := Membership_Range_Not_Membership_Or_Range;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression then
         Info.Membership_Range_Status := Membership_Range_Membership_Unknown;
         Info.Membership_Test_Subtype := To_Unbounded_String (Left);
         Info.Normalized_Membership_Test_Subtype := To_Unbounded_String (NL);
         Info.Membership_Choice_Subtype := To_Unbounded_String (Right);
         Info.Normalized_Membership_Choice_Subtype := To_Unbounded_String (NR);
         Set_Boolean_Result (Info);
         Info.Membership_Range_Status := Membership_Range_Boolean_Result;

         if Left = "" or else Right = "" then
            if Looks_Range_Choice (Text) and then (Left /= "" or else Right /= "") then
               Info.Membership_Range_Status := Membership_Range_Membership_Compatible;
               Info.Membership_Compatible_Count := 1;
            else
               Info.Membership_Range_Status := Membership_Range_Membership_Unknown;
               Info.Membership_Unknown_Count := 1;
            end if;
         elsif Simple_Subtype_Compatible (Left, Right) then
            Info.Membership_Range_Status := Membership_Range_Membership_Compatible;
            Info.Membership_Compatible_Count := 1;
            Info.Operator_Compatible_Operand_Count := 2;
         else
            Info.Membership_Range_Status := Membership_Range_Membership_Mismatch;
            Info.Membership_Mismatch_Count := 1;
            Info.Operator_Mismatched_Operand_Count := 1;
         end if;

      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Range_Expression then
         Info.Membership_Range_Status := Membership_Range_Range_Unknown;
         Info.Range_Low_Subtype := To_Unbounded_String (Left);
         Info.Range_High_Subtype := To_Unbounded_String (Right);
         Info.Normalized_Range_Low_Subtype := To_Unbounded_String (NL);
         Info.Normalized_Range_High_Subtype := To_Unbounded_String (NR);

         if Left = "" or else Right = "" then
            Info.Range_Unknown_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String ("range_bounds_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("range_bounds_unknown");
         elsif Simple_Subtype_Compatible (Left, Right) then
            Info.Membership_Range_Status := Membership_Range_Range_Compatible;
            Info.Range_Compatible_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String (Left);
            Info.Normalized_Subtype := To_Unbounded_String (NL);
         else
            Info.Membership_Range_Status := Membership_Range_Range_Mismatch;
            Info.Range_Mismatch_Count := 1;
            Info.Status := Expression_Type_Operator_Unknown;
         end if;
      end if;
   end Apply_Membership_Range_Inference;


   procedure Apply_Conditional_Inference
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Info       : in out Expression_Type_Info;
      Node       : Editor.Ada_Syntax_Tree.Node_Info)
   is
      Text      : constant String := To_String (Node.Label);
      Normal    : constant String := Normalize (Text);
      Expected  : constant String := To_String (Info.Expected_Subtype);
      NExpected : constant String := To_String (Info.Normalized_Expected_Subtype);
      Childs    : constant Natural := Editor.Ada_Syntax_Tree.Child_Count (Tree, Node.Id);
      Known     : Natural := 0;
      Unknown   : Natural := 0;
      Mismatch  : Natural := 0;
      First_Subtype : Ada.Strings.Unbounded.Unbounded_String;

      function Branch_Subtype (Child_Index : Positive) return String is
         Child_Id : constant Editor.Ada_Syntax_Tree.Node_Id :=
           Editor.Ada_Syntax_Tree.Child_At (Tree, Node.Id, Child_Index);
         Child : constant Editor.Ada_Syntax_Tree.Node_Info :=
           Editor.Ada_Syntax_Tree.Node (Tree, Child_Id);
      begin
         return Infer_Operand_Subtype
           (Tree, Regions, Visibility, Types, Static, Calls, Child, 1);
      end Branch_Subtype;
   begin
      if not (Node.Kind = Editor.Ada_Syntax_Tree.Node_Conditional_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Case_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression or else
              Node.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression)
      then
         Info.Conditional_Status := Conditional_Type_Not_Conditional;
         return;
      end if;

      Info.Status := Expression_Type_Indeterminate;
      Info.Conditional_Status := Conditional_Type_Branch_Unknown;
      Info.Conditional_Branch_Count := Childs;

      if Node.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression then
         Info.Conditional_Status := Conditional_Type_Boolean_Result;
         Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
         Info.Normalized_Subtype := To_Unbounded_String ("boolean");
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         Info.Conditional_Compatible_Branch_Count := 1;
         return;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression then
         Info.Conditional_Status := Conditional_Type_Reduction_Result;
         if NExpected /= "" then
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         elsif Contains (Normal, "parallel_reduce") or else Contains (Normal, "reduce") then
            Info.Inferred_Subtype := To_Unbounded_String ("reduction_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("reduction_result_unknown");
            Info.Conditional_Unknown_Branch_Count := 1;
         end if;
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         return;
      elsif Node.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression then
         Info.Conditional_Status := Conditional_Type_Declare_Result;
         if NExpected /= "" then
            Info.Inferred_Subtype := Info.Expected_Subtype;
            Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
            Info.Conditional_Compatible_Branch_Count := 1;
         else
            Info.Inferred_Subtype := To_Unbounded_String ("declare_expression_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("declare_expression_result_unknown");
            Info.Conditional_Unknown_Branch_Count := 1;
         end if;
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         return;
      end if;

      if NExpected /= "" then
         Info.Conditional_Status := Conditional_Type_Expected_Context;
         Info.Inferred_Subtype := Info.Expected_Subtype;
         Info.Normalized_Subtype := Info.Normalized_Expected_Subtype;
         Info.Conditional_Result_Subtype := Info.Expected_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Expected_Subtype;
      end if;

      if Childs = 0 then
         if NExpected /= "" then
            Info.Conditional_Compatible_Branch_Count := 1;
            Info.Conditional_Status := Conditional_Type_Branches_Compatible;
         else
            Info.Conditional_Unknown_Branch_Count := 1;
            Info.Inferred_Subtype := To_Unbounded_String ("conditional_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("conditional_result_unknown");
            Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
            Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
         end if;
         return;
      end if;

      for I in 1 .. Childs loop
         declare
            B : constant String := Branch_Subtype (I);
            NB : constant String := Normalize (B);
         begin
            if B = "" or else B = "ambiguous" then
               Unknown := Unknown + 1;
            elsif NExpected /= "" then
               if NB = NExpected or else Is_Universal_Compatible (NB, NExpected) then
                  Known := Known + 1;
               else
                  Mismatch := Mismatch + 1;
               end if;
            elsif To_String (First_Subtype) = "" then
               First_Subtype := To_Unbounded_String (B);
               Known := Known + 1;
            elsif NB = Normalize (To_String (First_Subtype)) or else
              (Is_Numeric_Family (B) and then Is_Numeric_Family (To_String (First_Subtype)))
            then
               Known := Known + 1;
            else
               Mismatch := Mismatch + 1;
            end if;
         end;
      end loop;

      Info.Conditional_Compatible_Branch_Count := Known;
      Info.Conditional_Mismatched_Branch_Count := Mismatch;
      Info.Conditional_Unknown_Branch_Count := Unknown;

      if Mismatch > 0 then
         Info.Conditional_Status := Conditional_Type_Branch_Mismatch;
      elsif Unknown > 0 then
         Info.Conditional_Status := Conditional_Type_Branch_Unknown;
      else
         Info.Conditional_Status := Conditional_Type_Branches_Compatible;
      end if;

      if NExpected = "" and then To_String (First_Subtype) /= "" then
         Info.Inferred_Subtype := First_Subtype;
         Info.Normalized_Subtype := To_Unbounded_String (Normalize (To_String (First_Subtype)));
         Info.Conditional_Result_Subtype := Info.Inferred_Subtype;
         Info.Normalized_Conditional_Result_Subtype := Info.Normalized_Subtype;
      end if;
   end Apply_Conditional_Inference;


   function Infer_One
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Node       : Editor.Ada_Syntax_Tree.Node_Info) return Expression_Type_Info
   is
      Label      : constant String := Trim (To_String (Node.Label));
      Normalized : constant String := Normalize (Label);
      Region     : constant Editor.Ada_Declarative_Regions.Region_Id :=
        Region_For_Line (Regions, Node.Source_Span.Start_Line);
      Info       : Expression_Type_Info;
   begin
      Info.Node := Node.Id;
      Info.Region := Region;
      Info.Expression_Text := To_Unbounded_String (Label);
      Info.Normalized_Text := To_Unbounded_String (Normalized);
      Info.Start_Line := Node.Source_Span.Start_Line;
      Info.End_Line := Node.Source_Span.End_Line;

      case Node.Kind is
         when Editor.Ada_Syntax_Tree.Node_Literal =>
            declare
               Value : constant Editor.Ada_Static_Expressions.Static_Value_Info :=
                 Editor.Ada_Static_Expressions.Evaluate_Numeric_Expression (Static, Region, Label);
            begin
               Info.Static_Status := Value.Status;
               if Value.Status = Editor.Ada_Static_Expressions.Static_Value_Integer then
                  Info.Status := Expression_Type_Static_Integer;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_integer");
               elsif Value.Status = Editor.Ada_Static_Expressions.Static_Value_Real then
                  Info.Status := Expression_Type_Static_Real;
                  Info.Inferred_Subtype := To_Unbounded_String ("Universal_Real");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_real");
               elsif Is_String_Literal (Label) then
                  Info.Status := Expression_Type_String_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("String");
                  Info.Normalized_Subtype := To_Unbounded_String ("string");
               elsif Normalized = "true" or else Normalized = "false" then
                  Info.Status := Expression_Type_Boolean_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("Boolean");
                  Info.Normalized_Subtype := To_Unbounded_String ("boolean");
               elsif Normalized = "null" then
                  Info.Status := Expression_Type_Null_Literal;
                  Info.Inferred_Subtype := To_Unbounded_String ("universal_access");
                  Info.Normalized_Subtype := To_Unbounded_String ("universal_access");
               else
                  Info.Status := Expression_Type_Indeterminate;
                  if Looks_Real (Label) then
                     Info.Inferred_Subtype := To_Unbounded_String ("Universal_Real");
                     Info.Normalized_Subtype := To_Unbounded_String ("universal_real");
                  end if;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Name =>
            declare
               Lookup : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                 Editor.Ada_Direct_Visibility.Lookup_Visible
                   (Visibility, Regions, Region, Primary_Name (Label));
            begin
               Info.Candidate_Count := Lookup.Match_Count;
               if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                  Info.Status := Expression_Type_Name_Resolved;
                  Info.Declaration := Lookup.Declaration;
                  declare
                     Decl : constant Editor.Ada_Direct_Visibility.Declaration_Info :=
                       Editor.Ada_Direct_Visibility.Declaration (Visibility, Lookup.Declaration);
                  begin
                     if Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Object or else
                       Decl.Kind = Editor.Ada_Direct_Visibility.Declaration_Formal_Object
                     then
                        declare
                           Decl_Node : constant Editor.Ada_Syntax_Tree.Node_Info :=
                             Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
                           Subtype_Text : constant String :=
                             Subtype_From_Declaration_Label (To_String (Decl_Node.Label));
                        begin
                           if Subtype_Text /= "" then
                              Info.Inferred_Subtype := To_Unbounded_String (Subtype_Text);
                              Info.Normalized_Subtype := To_Unbounded_String (Normalize (Subtype_Text));
                           else
                              Info.Inferred_Subtype := Decl.Name;
                              Info.Normalized_Subtype := Decl.Normalized;
                           end if;
                        end;
                     else
                        Info.Inferred_Subtype := Decl.Name;
                        Info.Normalized_Subtype := Decl.Normalized;
                     end if;
                     Info.Type_Id := Editor.Ada_Type_Graph.Type_For_Declaration (Types, Lookup.Declaration);
                  end;
               elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                  Info.Status := Expression_Type_Name_Ambiguous;
               else
                  Info.Status := Expression_Type_Name_Unresolved;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Selected_Name =>
            if Info.Status = Expression_Type_Selected_Name_Unresolved then
               declare
                  Selector : constant String := Suffix_After (Label, '.');
                  Lookup   : constant Editor.Ada_Direct_Visibility.Lookup_Result :=
                    Editor.Ada_Direct_Visibility.Lookup_Visible
                      (Visibility, Regions, Region, Selector);
               begin
                  Info.Candidate_Count := Lookup.Match_Count;
                  if Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Found then
                     Info.Status := Expression_Type_Selected_Name_Resolved;
                     Info.Declaration := Lookup.Declaration;
                  elsif Lookup.Status = Editor.Ada_Direct_Visibility.Lookup_Ambiguous then
                     Info.Status := Expression_Type_Name_Ambiguous;
                  else
                     Info.Status := Expression_Type_Selected_Name_Unresolved;
                  end if;
               end;
            end if;

         when Editor.Ada_Syntax_Tree.Node_Function_Call | Editor.Ada_Syntax_Tree.Node_Call_Statement =>
            if Node.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call then
               Apply_Conversion_Inference (Tree, Regions, Visibility, Types, Static, Info, Node);
            end if;
            if Info.Conversion_Status = Conversion_Type_Not_Conversion or else
              Info.Conversion_Status = Conversion_Type_Target_Unresolved
            then
               declare
                  Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
                    Editor.Ada_Call_Resolution.Resolution_For_Node (Calls, Node.Id);
               begin
                  Info.Call_Resolution := Resolution.Id;
                  Info.Candidate_Count := Resolution.Candidate_Count;
                  if Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match then
                     Info.Status := Expression_Type_Call_Resolved;
                     Info.Declaration := Resolution.Declaration;
                  elsif Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Pre_Profile or else
                    Resolution.Status = Editor.Ada_Call_Resolution.Call_Resolution_Ambiguous_Profile_Match
                  then
                     Info.Status := Expression_Type_Call_Ambiguous;
                  else
                     Info.Status := Expression_Type_Call_Unresolved;
                  end if;
               end;
            end if;

         when Editor.Ada_Syntax_Tree.Node_Operator_Expression |
              Editor.Ada_Syntax_Tree.Node_Unary_Expression |
              Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression |
              Editor.Ada_Syntax_Tree.Node_Membership_Expression =>
            Apply_Operator_Inference
              (Tree, Regions, Visibility, Types, Static, Calls, Info, Node);

         when Editor.Ada_Syntax_Tree.Node_Qualified_Expression =>
            declare
               Prefix : constant String := Prefix_Before (Label, Character'Val (39));
            begin
               Info.Status := Expression_Type_Qualified;
               Info.Inferred_Subtype := To_Unbounded_String (Prefix);
               Info.Normalized_Subtype := To_Unbounded_String (Normalize (Prefix));
               Info.Type_Id := Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix);
               Apply_Conversion_Inference (Tree, Regions, Visibility, Types, Static, Info, Node);
            end;

         when Editor.Ada_Syntax_Tree.Node_Aggregate |
              Editor.Ada_Syntax_Tree.Node_Delta_Aggregate |
              Editor.Ada_Syntax_Tree.Node_Container_Aggregate =>
            Info.Status := Expression_Type_Aggregate;
            Info.Inferred_Subtype := To_Unbounded_String ("aggregate_context_required");
            Info.Normalized_Subtype := To_Unbounded_String ("aggregate_context_required");

         when Editor.Ada_Syntax_Tree.Node_Indexed_Component =>
            Info.Status := Expression_Type_Indexed_Component;
            Info.Inferred_Subtype := To_Unbounded_String ("indexed_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("indexed_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Explicit_Dereference =>
            Info.Status := Expression_Type_Dereference;
            Info.Inferred_Subtype := To_Unbounded_String ("dereference_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("dereference_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Allocator =>
            Info.Status := Expression_Type_Allocator;
            Info.Inferred_Subtype := To_Unbounded_String ("allocator_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("allocator_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Slice =>
            Info.Status := Expression_Type_Slice;
            Info.Inferred_Subtype := To_Unbounded_String ("slice_result_unknown");
            Info.Normalized_Subtype := To_Unbounded_String ("slice_result_unknown");

         when Editor.Ada_Syntax_Tree.Node_Attribute_Reference =>
            Info.Status := Expression_Type_Attribute;
            declare
               Prefix : constant String := Attribute_Prefix_From_Text (Label);
               Attr   : constant String := Attribute_Name_From_Text (Label);
               NAttr  : constant String := Normalize (Attr);
               Prefix_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                 Editor.Ada_Type_Graph.Lookup_Type (Types, Region, Prefix);
            begin
               Info.Attribute_Name := To_Unbounded_String (Attr);
               Info.Normalized_Attribute_Name := To_Unbounded_String (NAttr);
               Info.Attribute_Prefix := To_Unbounded_String (Prefix);
               Info.Normalized_Attribute_Prefix := To_Unbounded_String (Normalize (Prefix));
               Info.Attribute_Prefix_Type := Prefix_Type;

               if Prefix = "" or else Attr = "" then
                  Info.Attribute_Status := Attribute_Type_Malformed;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               elsif Prefix_Type = Editor.Ada_Type_Graph.No_Type and then
                 not (NAttr = "access" or else NAttr = "unchecked_access" or else
                      NAttr = "unrestricted_access") and then
                 not (Normalize (Prefix) = "standard" or else Contains (Normalize (Prefix), "."))
               then
                  Info.Attribute_Status := Attribute_Type_Prefix_Unresolved;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               elsif NAttr = "first" or else NAttr = "last" then
                  Info.Attribute_Status := Attribute_Type_Scalar_Bound;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "range" then
                  Info.Attribute_Status := Attribute_Type_Range_Bound;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix & " range");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix & " range"));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "length" or else NAttr = "pos" or else
                 NAttr = "max_size_in_storage_elements" then
                  Info.Attribute_Status := Attribute_Type_Integer_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("universal_integer");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "val" or else NAttr = "succ" or else NAttr = "pred" then
                  Info.Attribute_Status := Attribute_Type_Value_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "image" or else NAttr = "wide_image" or else
                 NAttr = "wide_wide_image" or else NAttr = "img" then
                  Info.Attribute_Status := Attribute_Type_String_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("String");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("string");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_String_Result_Count := 1;
               elsif NAttr = "value" then
                  Info.Attribute_Status := Attribute_Type_Value_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String (Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize (Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "address" then
                  Info.Attribute_Status := Attribute_Type_Address_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("System.Address");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("system.address");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "size" or else NAttr = "object_size" or else
                 NAttr = "value_size" or else NAttr = "component_size" or else
                 NAttr = "alignment" or else NAttr = "storage_size" then
                  Info.Attribute_Status := Attribute_Type_Size_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Universal_Integer");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("universal_integer");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
                  Info.Attribute_Static_Result_Count := 1;
               elsif NAttr = "callable" or else NAttr = "terminated" then
                  Info.Attribute_Status := Attribute_Type_Boolean_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("Boolean");
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String ("boolean");
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               elsif NAttr = "access" or else NAttr = "unchecked_access" or else
                 NAttr = "unrestricted_access" then
                  Info.Attribute_Status := Attribute_Type_Callable_Result;
                  Info.Attribute_Result_Subtype := To_Unbounded_String ("access " & Prefix);
                  Info.Normalized_Attribute_Result_Subtype := To_Unbounded_String (Normalize ("access " & Prefix));
                  Info.Inferred_Subtype := Info.Attribute_Result_Subtype;
                  Info.Normalized_Subtype := Info.Normalized_Attribute_Result_Subtype;
               else
                  Info.Attribute_Status := Attribute_Type_Unknown_Attribute;
                  Info.Inferred_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Normalized_Subtype := To_Unbounded_String ("attribute_result_unknown");
                  Info.Attribute_Unknown_Count := 1;
               end if;
            end;

         when Editor.Ada_Syntax_Tree.Node_Parenthesized_Expression |
              Editor.Ada_Syntax_Tree.Node_Expression |
              Editor.Ada_Syntax_Tree.Node_Conditional_Expression |
              Editor.Ada_Syntax_Tree.Node_Case_Expression |
              Editor.Ada_Syntax_Tree.Node_Quantified_Expression |
              Editor.Ada_Syntax_Tree.Node_Declare_Expression |
              Editor.Ada_Syntax_Tree.Node_Reduction_Expression |
              Editor.Ada_Syntax_Tree.Node_Target_Name |
              Editor.Ada_Syntax_Tree.Node_Range_Expression =>
            Info.Status := Expression_Type_Indeterminate;

         when others =>
            Info.Status := Expression_Type_Not_Checked;
      end case;

      return Info;
   end Infer_One;

   procedure Clear (Model : in out Expression_Type_Model) is
   begin
      Model.Expressions.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;


   function Build_Internal
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Use_Selected : Boolean;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Use_Expected : Boolean;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Use_Primitives : Boolean)
      return Expression_Type_Model
   is
      Model : Expression_Type_Model;
   begin
      for I in 1 .. Editor.Ada_Syntax_Tree.Node_Count (Tree) loop
         declare
            N : constant Editor.Ada_Syntax_Tree.Node_Info := Editor.Ada_Syntax_Tree.Node_At (Tree, I);
         begin
            if N.Kind in Editor.Ada_Syntax_Tree.Node_Expression .. Editor.Ada_Syntax_Tree.Node_Allocator
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Call_Statement
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Raise_Statement
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Association
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Named_Association
              or else N.Kind = Editor.Ada_Syntax_Tree.Node_Positional_Association
            then
               declare
                  Info : Expression_Type_Info :=
                    Infer_One (Tree, Regions, Visibility, Types, Static, Calls, N);
               begin
                  if Use_Selected and then N.Kind = Editor.Ada_Syntax_Tree.Node_Selected_Name then
                     declare
                        S : constant Editor.Ada_Selected_Name_Resolution.Selected_Name_Info :=
                          Editor.Ada_Selected_Name_Resolution.Selected_Name_For_Node (Selected, N.Id);
                     begin
                        Info.Selected_Name := S.Id;
                        Info.Selected_Name_Status := S.Status;
                        Info.Cross_Unit_Selected_Target := S.Cross_Unit_Target;
                        Info.Cross_Unit_Selected_Path := S.Cross_Unit_Path;
                        Info.Cross_Unit_Selected_Selector := S.Selector;
                        Info.Normalized_Cross_Unit_Selected_Target :=
                          To_Unbounded_String (Normalize (To_String (S.Cross_Unit_Target)));
                        Info.Normalized_Cross_Unit_Selected_Selector := S.Normalized_Selector;

                        if S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Found then
                           Info.Status := Expression_Type_Selected_Name_Resolved;
                           Info.Declaration := S.Selector_Declaration;
                           Info.Candidate_Count := 1;
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Found or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Use_Prefix_Found
                        then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Resolved;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype :=
                             To_Unbounded_String
                               ("cross_unit_selected:" & To_String (S.Cross_Unit_Target) & "." &
                                To_String (S.Selector));
                           Info.Normalized_Subtype :=
                             To_Unbounded_String
                               (Normalize ("cross_unit_selected:" & To_String (S.Cross_Unit_Target) & "." &
                                           To_String (S.Selector)));
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Limited_Prefix then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Limited;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype := To_Unbounded_String ("limited_view_selected_name");
                           Info.Normalized_Subtype := To_Unbounded_String ("limited_view_selected_name");
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Private_Prefix then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Private;
                           Info.Candidate_Count := 1;
                           Info.Inferred_Subtype := To_Unbounded_String ("private_view_selected_name");
                           Info.Normalized_Subtype := To_Unbounded_String ("private_view_selected_name");
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Missing or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Ambiguous or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Cross_Unit_Prefix_Overflow
                        then
                           Info.Status := Expression_Type_Selected_Name_Cross_Unit_Unresolved;
                        elsif S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Selector_Ambiguous or else
                          S.Status = Editor.Ada_Selected_Name_Resolution.Selected_Name_Prefix_Ambiguous
                        then
                           Info.Status := Expression_Type_Name_Ambiguous;
                           Info.Candidate_Count := 2;
                        elsif S.Status /= Editor.Ada_Selected_Name_Resolution.Selected_Name_Not_Resolved then
                           Info.Status := Expression_Type_Selected_Name_Unresolved;
                        end if;
                     end;
                  end if;

                  if Use_Expected then
                     Apply_Expected_Context (Info, Expected);
                     if Info.Expected_Status = Expected_Type_No_Context or else
                       Info.Expected_Status = Expected_Type_Not_Checked
                     then
                        Apply_Syntax_Expected_Context (Tree, Info);
                        if Info.Expected_Status = Expected_Type_Not_Checked then
                           Info.Expected_Status := Expected_Type_No_Context;
                        end if;
                     end if;
                  else
                     Info.Expected_Status := Expected_Type_Not_Checked;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Operator_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Unary_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Short_Circuit_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression
                  then
                     Apply_Operator_Overload_Resolution
                       (Regions, Visibility, Primitives, Info, Use_Primitives);
                     Apply_Concatenation_Inference (Regions, Visibility, Types, Static, Info);
                  else
                     Info.Concatenation_Status := Concatenation_Type_Not_Concatenation;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Conditional_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Case_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Quantified_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Declare_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Reduction_Expression
                  then
                     Apply_Conditional_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Conditional_Status := Conditional_Type_Not_Conditional;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Membership_Expression or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Range_Expression
                  then
                     Apply_Membership_Range_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Membership_Range_Status := Membership_Range_Not_Membership_Or_Range;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Target_Name or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate
                  then
                     Apply_Target_Name_Update_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Target_Name_Status := Target_Name_Not_Target_Name_Or_Update;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Indexed_Component or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Slice
                  then
                     Apply_Indexed_Slice_Inference
                       (Tree, Regions, Visibility, Types, Static, Calls, Info, N);
                  else
                     Info.Indexed_Slice_Status := Indexed_Slice_Not_Indexed_Or_Slice;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Explicit_Dereference or else
                    (N.Kind = Editor.Ada_Syntax_Tree.Node_Attribute_Reference and then
                     (Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "access" or else
                      Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "unchecked_access" or else
                      Normalize (Attribute_Name_From_Text (To_String (N.Label))) = "unrestricted_access"))
                  then
                     Apply_Dereference_Access_Inference
                       (Tree, Regions, Visibility, Types, Info, N);
                  else
                     Info.Dereference_Access_Status := Dereference_Access_Not_Dereference_Or_Access;
                  end if;

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Allocator then
                     Apply_Allocator_Inference
                       (Tree, Regions, Visibility, Types, Info, N);
                  else
                     Info.Allocator_Status := Allocator_Type_Not_Allocator;
                  end if;

                  Apply_Raise_No_Return_Inference (Tree, Visibility, Info, N);

                  Apply_Call_Actual_Type_Resolution
                    (Tree, Regions, Visibility, Static, Calls, Info, N);

                  Apply_Dispatching_Call_Inference
                    (Tree, Regions, Visibility, Static, Info, N);

                  Apply_Parameter_Association_Inference
                    (Tree, Regions, Visibility, Static, Calls, Info, N);

                  Apply_Universal_Numeric_Resolution (Static, Regions, Info, N);

                  Apply_Boolean_Context_Inference (Info, N);

                  if N.Kind = Editor.Ada_Syntax_Tree.Node_Aggregate or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Delta_Aggregate or else
                    N.Kind = Editor.Ada_Syntax_Tree.Node_Container_Aggregate
                  then
                     Apply_Aggregate_Inference (Tree, Regions, Types, Info, N);
                  else
                     Info.Aggregate_Status := Aggregate_Type_Not_Aggregate;
                  end if;

                  if not (N.Kind = Editor.Ada_Syntax_Tree.Node_Qualified_Expression or else
                          N.Kind = Editor.Ada_Syntax_Tree.Node_Function_Call)
                  then
                     Info.Conversion_Status := Conversion_Type_Not_Conversion;
                  end if;

                  if N.Kind /= Editor.Ada_Syntax_Tree.Node_Attribute_Reference then
                     Info.Attribute_Status := Attribute_Type_Not_Attribute;
                  end if;

                  if Info.Status /= Expression_Type_Not_Checked then
                     Append (Model, Info);
                  end if;
               end;
            end if;
         end;
      end loop;
      return Model;
   end Build_Internal;

   function Build_With_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model
   is
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, True,
         Empty_Expected, False, Empty_Primitives, False);
   end Build_With_Selected_Names;

   function Build_With_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, True,
         Expected, True, Empty_Primitives, False);
   end Build_With_Selected_Names_And_Expected;


   function Build_With_Cross_Unit_Selected_Names
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model)
      return Expression_Type_Model
   is
   begin
      return Build_With_Selected_Names
        (Tree, Regions, Visibility, Types, Static, Calls, Selected);
   end Build_With_Cross_Unit_Selected_Names;

   function Build_With_Cross_Unit_Selected_Names_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Selected   : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
   begin
      return Build_With_Selected_Names_And_Expected
        (Tree, Regions, Visibility, Types, Static, Calls, Selected, Expected);
   end Build_With_Cross_Unit_Selected_Names_And_Expected;

   function Build_With_Operator_Uses
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Empty_Expected, False, Primitives, True);
   end Build_With_Operator_Uses;

   function Build_With_Operator_Uses_And_Expected
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Expected, True, Primitives, True);
   end Build_With_Operator_Uses_And_Expected;

   function Build_With_Expected_Contexts
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Expected   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Expected, True, Empty_Primitives, False);
   end Build_With_Expected_Contexts;

   function Build
     (Tree       : Editor.Ada_Syntax_Tree.Tree_Type;
      Regions    : Editor.Ada_Declarative_Regions.Region_Model;
      Visibility : Editor.Ada_Direct_Visibility.Visibility_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model;
      Static     : Editor.Ada_Static_Expressions.Static_Model;
      Calls      : Editor.Ada_Call_Resolution.Call_Resolution_Model)
      return Expression_Type_Model
   is
      Empty_Selected : Editor.Ada_Selected_Name_Resolution.Selected_Name_Model;
      Empty_Expected : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Empty_Primitives : Editor.Ada_Use_Type_Operators.Primitive_Use_Model;
   begin
      return Build_Internal
        (Tree, Regions, Visibility, Types, Static, Calls, Empty_Selected, False,
         Empty_Expected, False, Empty_Primitives, False);
   end Build;

   function Has_Expression_Types (Model : Expression_Type_Model) return Boolean is
   begin
      return not Model.Expressions.Is_Empty;
   end Has_Expression_Types;

   function Expression_Type_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Natural (Model.Expressions.Length);
   end Expression_Type_Count;

   function Expression_Type_At
     (Model : Expression_Type_Model;
      Index : Positive) return Expression_Type_Info is
   begin
      if Index > Natural (Model.Expressions.Length) then
         return (others => <>);
      end if;
      return Model.Expressions.Element (Index);
   end Expression_Type_At;

   function Expression_Type
     (Model : Expression_Type_Model;
      Id    : Expression_Type_Id) return Expression_Type_Info is
   begin
      if Id = No_Expression_Type or else Natural (Id) > Natural (Model.Expressions.Length) then
         return (others => <>);
      end if;
      return Model.Expressions.Element (Positive (Id));
   end Expression_Type;

   function Expression_Type_For_Node
     (Model : Expression_Type_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expression_Type_Info is
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         declare
            Info : constant Expression_Type_Info := Model.Expressions.Element (Positive (I));
         begin
            if Info.Node = Node then
               return Info;
            end if;
         end;
      end loop;
      return (others => <>);
   end Expression_Type_For_Node;

   function Count_Status
     (Model  : Expression_Type_Model;
      Status : Expression_Type_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Name_Resolved) +
        Count_Status (Model, Expression_Type_Selected_Name_Resolved) +
        Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Resolved) +
        Count_Status (Model, Expression_Type_Call_Resolved) +
        Count_Status (Model, Expression_Type_Qualified) +
        Count_Status (Model, Expression_Type_Conversion) +
        Count_Status (Model, Expression_Type_Operator_Concatenation) +
        Count_Status (Model, Expression_Type_Attribute) +
        Count_Status (Model, Expression_Type_Dereference) +
        Count_Status (Model, Expression_Type_Raise) +
        Count_Status (Model, Expression_Type_No_Return_Call);
   end Resolved_Count;

   function Unresolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Name_Unresolved) +
        Count_Status (Model, Expression_Type_Selected_Name_Unresolved) +
        Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Unresolved) +
        Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Limited) +
        Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Private) +
        Count_Status (Model, Expression_Type_Call_Unresolved);
   end Unresolved_Count;

   function Ambiguous_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Name_Ambiguous) +
        Count_Status (Model, Expression_Type_Call_Ambiguous);
   end Ambiguous_Count;

   function Static_Numeric_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Static_Integer) +
        Count_Status (Model, Expression_Type_Static_Real);
   end Static_Numeric_Count;

   function Operator_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Operator_Unknown);
   end Operator_Unknown_Count;



   function Cross_Unit_Selected_Name_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Cross_Unit_Selected_Name_Resolved_Count (Model) +
        Cross_Unit_Selected_Name_Limited_Count (Model) +
        Cross_Unit_Selected_Name_Private_Count (Model) +
        Cross_Unit_Selected_Name_Unresolved_Count (Model);
   end Cross_Unit_Selected_Name_Count;

   function Cross_Unit_Selected_Name_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Resolved);
   end Cross_Unit_Selected_Name_Resolved_Count;

   function Cross_Unit_Selected_Name_Limited_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Limited);
   end Cross_Unit_Selected_Name_Limited_Count;

   function Cross_Unit_Selected_Name_Private_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Private);
   end Cross_Unit_Selected_Name_Private_Count;

   function Cross_Unit_Selected_Name_Unresolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Selected_Name_Cross_Unit_Unresolved);
   end Cross_Unit_Selected_Name_Unresolved_Count;

   function Expected_Context_Count (Model : Expression_Type_Model) return Natural is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Expected_Context /=
           Editor.Ada_Expected_Type_Contexts.No_Expected_Context
         then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Expected_Context_Count;

   function Count_Expected_Status
     (Model  : Expression_Type_Model;
      Status : Expected_Type_Propagation_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Expected_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Expected_Status;

   function Expected_Propagated_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Expected_Status (Model, Expected_Type_Propagated) +
        Count_Expected_Status (Model, Expected_Type_Compatible);
   end Expected_Propagated_Count;

   function Expected_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Expected_Status (Model, Expected_Type_Mismatch);
   end Expected_Mismatch_Count;

   function Expected_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Expected_Status (Model, Expected_Type_Unknown);
   end Expected_Unknown_Count;


   function Count_Operator_Status
     (Model  : Expression_Type_Model;
      Status : Operator_Type_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Operator_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Operator_Status;

   function Operator_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Resolved_Predefined) +
        Count_Operator_Status (Model, Operator_Type_Resolved_Visible) +
        Count_Operator_Status (Model, Operator_Type_Overload_Resolved);
   end Operator_Resolved_Count;

   function Operator_Operand_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Operand_Mismatch);
   end Operator_Operand_Mismatch_Count;

   function Operator_Operand_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Operand_Unknown);
   end Operator_Operand_Unknown_Count;

   function Operator_Ambiguous_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Ambiguous) +
        Count_Operator_Status (Model, Operator_Type_Overload_Ambiguous);
   end Operator_Ambiguous_Count;

   function Operator_Overload_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Overload_Resolved);
   end Operator_Overload_Resolved_Count;

   function Operator_Overload_Ambiguous_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Overload_Ambiguous);
   end Operator_Overload_Ambiguous_Count;

   function Operator_Overload_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Overload_Mismatch);
   end Operator_Overload_Mismatch_Count;

   function Operator_Overload_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Operator_Status (Model, Operator_Type_Overload_Unknown);
   end Operator_Overload_Unknown_Count;

   function Count_Concatenation_Status
     (Model  : Expression_Type_Model;
      Status : Concatenation_Type_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Concatenation_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Concatenation_Status;

   function Concatenation_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Concatenation_Status (Model, Concatenation_Type_String_Compatible) +
        Count_Concatenation_Status (Model, Concatenation_Type_Array_Compatible) +
        Count_Concatenation_Status (Model, Concatenation_Type_Character_String_Compatible) +
        Count_Concatenation_Status (Model, Concatenation_Type_Expected_Context_Result);
   end Concatenation_Resolved_Count;

   function Concatenation_String_Result_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Concatenation_Status (Model, Concatenation_Type_String_Compatible) +
        Count_Concatenation_Status (Model, Concatenation_Type_Character_String_Compatible);
   end Concatenation_String_Result_Count;

   function Concatenation_Array_Result_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Concatenation_Status (Model, Concatenation_Type_Array_Compatible) +
        Count_Concatenation_Status (Model, Concatenation_Type_Expected_Context_Result);
   end Concatenation_Array_Result_Count;

   function Concatenation_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Concatenation_Status (Model, Concatenation_Type_Operand_Mismatch);
   end Concatenation_Mismatch_Count;

   function Concatenation_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Concatenation_Status (Model, Concatenation_Type_Operand_Unknown) +
        Count_Concatenation_Status (Model, Concatenation_Type_Result_Unknown);
   end Concatenation_Unknown_Count;

   function Count_Aggregate_Status
     (Model  : Expression_Type_Model;
      Status : Aggregate_Type_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Aggregate_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Aggregate_Status;

   function Aggregate_Context_Required_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Aggregate_Status (Model, Aggregate_Type_Context_Required);
   end Aggregate_Context_Required_Count;

   function Aggregate_Context_Resolved_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Aggregate_Status (Model, Aggregate_Type_Compatible) +
        Count_Aggregate_Status (Model, Aggregate_Type_Array_Context) +
        Count_Aggregate_Status (Model, Aggregate_Type_Record_Context) +
        Count_Aggregate_Status (Model, Aggregate_Type_Container_Context) +
        Count_Aggregate_Status (Model, Aggregate_Type_Delta_Context) +
        Count_Aggregate_Status (Model, Aggregate_Type_Record_Components_Compatible) +
        Count_Aggregate_Status (Model, Aggregate_Type_Array_Elements_Compatible);
   end Aggregate_Context_Resolved_Count;

   function Aggregate_Record_Component_Compatible_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Record_Component_Compatible_Count;
      end loop;
      return Result;
   end Aggregate_Record_Component_Compatible_Count;

   function Aggregate_Record_Component_Missing_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Record_Component_Missing_Count;
      end loop;
      return Result;
   end Aggregate_Record_Component_Missing_Count;

   function Aggregate_Record_Component_Duplicate_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Record_Component_Duplicate_Count;
      end loop;
      return Result;
   end Aggregate_Record_Component_Duplicate_Count;

   function Aggregate_Array_Element_Compatible_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Array_Element_Compatible_Count;
      end loop;
      return Result;
   end Aggregate_Array_Element_Compatible_Count;

   function Aggregate_Array_Element_Mismatch_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Array_Element_Mismatch_Count;
      end loop;
      return Result;
   end Aggregate_Array_Element_Mismatch_Count;

   function Aggregate_Array_Element_Unknown_Count
     (Model : Expression_Type_Model) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Aggregate_Array_Element_Unknown_Count;
      end loop;
      return Result;
   end Aggregate_Array_Element_Unknown_Count;

   function Aggregate_Mismatch_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Aggregate_Status (Model, Aggregate_Type_Mismatch) +
        Count_Aggregate_Status (Model, Aggregate_Type_Record_Component_Missing) +
        Count_Aggregate_Status (Model, Aggregate_Type_Record_Component_Duplicate) +
        Count_Aggregate_Status (Model, Aggregate_Type_Array_Element_Mismatch);
   end Aggregate_Mismatch_Count;

   function Aggregate_Unknown_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Aggregate_Status (Model, Aggregate_Type_Unknown) +
        Count_Aggregate_Status (Model, Aggregate_Type_Array_Element_Unknown);
   end Aggregate_Unknown_Count;


   function Count_Conversion_Status
     (Model  : Expression_Type_Model;
      Status : Conversion_Type_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Conversion_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Conversion_Status;

   function Conversion_Target_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conversion_Status (Model, Conversion_Type_Target_Resolved) +
        Count_Conversion_Status (Model, Conversion_Type_Operand_Compatible) +
        Count_Conversion_Status (Model, Conversion_Type_Operand_Requires_Explicit_Conversion) +
        Count_Conversion_Status (Model, Conversion_Type_Operand_Mismatch) +
        Count_Conversion_Status (Model, Conversion_Type_Operand_Unknown);
   end Conversion_Target_Resolved_Count;

   function Conversion_Compatible_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conversion_Status (Model, Conversion_Type_Operand_Compatible);
   end Conversion_Compatible_Count;

   function Conversion_Explicit_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conversion_Status (Model, Conversion_Type_Operand_Requires_Explicit_Conversion);
   end Conversion_Explicit_Count;

   function Conversion_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conversion_Status (Model, Conversion_Type_Operand_Mismatch);
   end Conversion_Mismatch_Count;

   function Conversion_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conversion_Status (Model, Conversion_Type_Operand_Unknown) +
        Count_Conversion_Status (Model, Conversion_Type_Target_Unresolved) +
        Count_Conversion_Status (Model, Conversion_Type_Target_Ambiguous) +
        Count_Conversion_Status (Model, Conversion_Type_Malformed);
   end Conversion_Unknown_Count;


   function Count_Conditional_Status
     (Model  : Expression_Type_Model;
      Status : Conditional_Type_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Conditional_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Conditional_Status;

   function Conditional_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conditional_Status (Model, Conditional_Type_Expected_Context) +
        Count_Conditional_Status (Model, Conditional_Type_Branches_Compatible) +
        Count_Conditional_Status (Model, Conditional_Type_Boolean_Result) +
        Count_Conditional_Status (Model, Conditional_Type_Reduction_Result) +
        Count_Conditional_Status (Model, Conditional_Type_Declare_Result);
   end Conditional_Resolved_Count;

   function Conditional_Branch_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conditional_Status (Model, Conditional_Type_Branch_Mismatch);
   end Conditional_Branch_Mismatch_Count;

   function Conditional_Branch_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conditional_Status (Model, Conditional_Type_Branch_Unknown);
   end Conditional_Branch_Unknown_Count;

   function Conditional_Reduction_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conditional_Status (Model, Conditional_Type_Reduction_Result);
   end Conditional_Reduction_Count;

   function Conditional_Declare_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Conditional_Status (Model, Conditional_Type_Declare_Result);
   end Conditional_Declare_Count;


   function Count_Membership_Range_Status
     (Model  : Expression_Type_Model;
      Status : Membership_Range_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Membership_Range_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Membership_Range_Status;

   function Membership_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Membership_Compatible) +
        Count_Membership_Range_Status (Model, Membership_Range_Boolean_Result);
   end Membership_Resolved_Count;

   function Membership_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Membership_Mismatch);
   end Membership_Mismatch_Count;

   function Membership_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Membership_Unknown);
   end Membership_Unknown_Count;

   function Range_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Range_Compatible);
   end Range_Resolved_Count;

   function Range_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Range_Mismatch);
   end Range_Mismatch_Count;

   function Range_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Membership_Range_Status (Model, Membership_Range_Range_Unknown);
   end Range_Unknown_Count;


   function Count_Attribute_Status
     (Model  : Expression_Type_Model;
      Status : Attribute_Type_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Attribute_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Attribute_Status;

   function Count_Target_Name_Status
     (Model  : Expression_Type_Model;
      Status : Target_Name_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Target_Name_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Target_Name_Status;

   function Target_Name_Context_Propagated_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Target_Name_Status (Model, Target_Name_Context_Propagated);
   end Target_Name_Context_Propagated_Count;

   function Target_Name_Context_Required_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Target_Name_Status (Model, Target_Name_Context_Required);
   end Target_Name_Context_Required_Count;

   function Target_Name_Update_Compatible_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Target_Name_Status (Model, Target_Name_Delta_Update_Compatible);
   end Target_Name_Update_Compatible_Count;

   function Target_Name_Update_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Target_Name_Status (Model, Target_Name_Delta_Update_Mismatch);
   end Target_Name_Update_Mismatch_Count;

   function Target_Name_Update_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Target_Name_Status (Model, Target_Name_Delta_Update_Unknown) +
        Count_Target_Name_Status (Model, Target_Name_Context_Required);
   end Target_Name_Update_Unknown_Count;


   function Count_Indexed_Slice_Status
     (Model  : Expression_Type_Model;
      Status : Indexed_Slice_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Indexed_Slice_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Indexed_Slice_Status;

   function Indexed_Slice_Prefix_Resolved_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Indexed_Slice_Status (Model, Indexed_Slice_Prefix_Resolved) +
        Count_Indexed_Slice_Status (Model, Indexed_Slice_Index_Compatible) +
        Count_Indexed_Slice_Status (Model, Indexed_Slice_Result_Element) +
        Count_Indexed_Slice_Status (Model, Indexed_Slice_Result_Array);
   end Indexed_Slice_Prefix_Resolved_Count;

   function Indexed_Slice_Index_Compatible_Count
     (Model : Expression_Type_Model) return Natural is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Indexed_Slice_Compatible_Index_Count;
      end loop;
      return Result;
   end Indexed_Slice_Index_Compatible_Count;

   function Indexed_Slice_Index_Mismatch_Count
     (Model : Expression_Type_Model) return Natural is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Indexed_Slice_Mismatched_Index_Count;
      end loop;
      return Result;
   end Indexed_Slice_Index_Mismatch_Count;

   function Indexed_Slice_Index_Unknown_Count
     (Model : Expression_Type_Model) return Natural is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         Result := Result +
           Model.Expressions.Element (Positive (I)).Indexed_Slice_Unknown_Index_Count;
      end loop;
      return Result;
   end Indexed_Slice_Index_Unknown_Count;

   function Indexed_Slice_Result_Element_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Indexed_Component);
   end Indexed_Slice_Result_Element_Count;

   function Indexed_Slice_Result_Array_Count
     (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Slice);
   end Indexed_Slice_Result_Array_Count;


   function Count_Dereference_Access_Status
     (Model  : Expression_Type_Model;
      Status : Dereference_Access_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Dereference_Access_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Dereference_Access_Status;

   function Dereference_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dereference_Access_Status (Model, Dereference_Designated_Subtype_Known);
   end Dereference_Resolved_Count;

   function Dereference_Target_Error_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dereference_Access_Status (Model, Dereference_Prefix_Not_Access_Type);
   end Dereference_Target_Error_Count;

   function Dereference_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dereference_Access_Status (Model, Dereference_Prefix_Unresolved) +
        Count_Dereference_Access_Status (Model, Dereference_Designated_Subtype_Unknown);
   end Dereference_Unknown_Count;

   function Access_Result_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dereference_Access_Status (Model, Access_Attribute_Result_Known);
   end Access_Result_Resolved_Count;

   function Access_Result_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dereference_Access_Status (Model, Access_Attribute_Target_Unresolved) +
        Count_Dereference_Access_Status (Model, Access_Attribute_Result_Unknown);
   end Access_Result_Unknown_Count;

   function Count_Allocator_Status
     (Model  : Expression_Type_Model;
      Status : Allocator_Type_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Allocator_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Allocator_Status;

   function Allocator_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Allocator_Status (Model, Allocator_Type_Result_Known) +
        Count_Allocator_Status (Model, Allocator_Type_Designated_Compatible);
   end Allocator_Resolved_Count;

   function Allocator_Target_Error_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Allocator_Status (Model, Allocator_Type_Target_Unresolved) +
        Count_Allocator_Status (Model, Allocator_Type_Malformed) +
        Count_Allocator_Status (Model, Allocator_Type_Expected_Not_Access) +
        Count_Allocator_Status (Model, Allocator_Type_Designated_Mismatch);
   end Allocator_Target_Error_Count;

   function Allocator_Designated_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Allocator_Status (Model, Allocator_Type_Designated_Compatible) +
        Count_Allocator_Status (Model, Allocator_Type_Result_Known);
   end Allocator_Designated_Resolved_Count;

   function Allocator_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Allocator_Status (Model, Allocator_Type_Result_Unknown) +
        Count_Allocator_Status (Model, Allocator_Type_Designated_Unknown);
   end Allocator_Unknown_Count;



   function Count_Universal_Numeric_Status
     (Model  : Expression_Type_Model;
      Status : Universal_Numeric_Resolution_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Universal_Numeric_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Universal_Numeric_Status;

   function Universal_Numeric_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Universal_Numeric_Status (Model, Universal_Numeric_Integer_Resolved) +
        Count_Universal_Numeric_Status (Model, Universal_Numeric_Real_Resolved) +
        Count_Universal_Numeric_Status (Model, Universal_Numeric_Modular_Resolved) +
        Count_Universal_Numeric_Status (Model, Universal_Numeric_Fixed_Resolved) +
        Count_Universal_Numeric_Status (Model, Universal_Numeric_Range_Compatible);
   end Universal_Numeric_Resolved_Count;

   function Universal_Numeric_Range_Error_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Universal_Numeric_Status (Model, Universal_Numeric_Range_Error);
   end Universal_Numeric_Range_Error_Count;

   function Universal_Numeric_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Universal_Numeric_Status (Model, Universal_Numeric_Expected_Mismatch);
   end Universal_Numeric_Mismatch_Count;

   function Universal_Numeric_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Universal_Numeric_Status (Model, Universal_Numeric_Static_Unknown);
   end Universal_Numeric_Unknown_Count;




   function Count_Boolean_Context_Status
     (Model  : Expression_Type_Model;
      Status : Boolean_Context_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Boolean_Context_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Boolean_Context_Status;

   function Boolean_Context_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Boolean_Context_Status (Model, Boolean_Context_Expected_Boolean) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Compatible) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Mismatch) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Unknown) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Short_Circuit_Compatible) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Short_Circuit_Mismatch) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Compatible) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Mismatch) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Unknown);
   end Boolean_Context_Count;

   function Boolean_Context_Compatible_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Compatible) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Short_Circuit_Compatible) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Compatible);
   end Boolean_Context_Compatible_Count;

   function Boolean_Context_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Mismatch) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Short_Circuit_Mismatch) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Mismatch);
   end Boolean_Context_Mismatch_Count;

   function Boolean_Context_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Boolean_Context_Status (Model, Boolean_Context_Operand_Unknown) +
        Count_Boolean_Context_Status (Model, Boolean_Context_Condition_Unknown);
   end Boolean_Context_Unknown_Count;

   function Count_Raise_No_Return_Status
     (Model  : Expression_Type_Model;
      Status : Raise_No_Return_Inference_Status) return Natural
   is
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Raise_No_Return_Status = Status then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Raise_No_Return_Status;

   function Raise_Expression_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Status (Model, Expression_Type_Raise);
   end Raise_Expression_Count;

   function Raise_No_Return_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Raise_No_Return_Status (Model, Raise_No_Return_Raise_Expression) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Raise_Statement) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Exception_Target_Known) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_With_Message) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Message_Unknown) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_No_Return_Call) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Result_Context_Propagated);
   end Raise_No_Return_Count;

   function Raise_Message_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Raise_No_Return_Status (Model, Raise_No_Return_With_Message) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Message_Unknown);
   end Raise_Message_Count;

   function Raise_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Raise_No_Return_Status (Model, Raise_No_Return_Exception_Target_Unknown) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Message_Unknown) +
        Count_Raise_No_Return_Status (Model, Raise_No_Return_Result_Context_Unknown);
   end Raise_Unknown_Count;

   function Count_Call_Actual_Type_Status
     (Model  : Expression_Type_Model;
      Status : Call_Actual_Type_Resolution_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Call_Actual_Type_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Call_Actual_Type_Status;

   function Call_Actual_Type_Compatible_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Call_Actual_Type_Status (Model, Call_Actual_Type_All_Compatible);
   end Call_Actual_Type_Compatible_Count;

   function Call_Actual_Type_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Call_Actual_Type_Status (Model, Call_Actual_Type_Actual_Mismatch);
   end Call_Actual_Type_Mismatch_Count;

   function Call_Actual_Type_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Call_Actual_Type_Status (Model, Call_Actual_Type_Actual_Unknown) +
        Count_Call_Actual_Type_Status (Model, Call_Actual_Type_Unresolved_Call) +
        Count_Call_Actual_Type_Status (Model, Call_Actual_Type_Profile_Unavailable);
   end Call_Actual_Type_Unknown_Count;

   function Call_Actual_Type_Ambiguous_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Call_Actual_Type_Status (Model, Call_Actual_Type_Ambiguous_Call);
   end Call_Actual_Type_Ambiguous_Count;


   function Count_Dispatching_Call_Status
     (Model  : Expression_Type_Model;
      Status : Dispatching_Call_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Dispatching_Call_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Dispatching_Call_Status;

   function Dispatching_Call_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dispatching_Call_Status (Model, Dispatching_Call_Primitive_Target) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Class_Wide_Controlling_Operand) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Controlling_Result) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Static_Binding) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Dynamic_Dispatch);
   end Dispatching_Call_Resolved_Count;

   function Dispatching_Call_Dynamic_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dispatching_Call_Status (Model, Dispatching_Call_Dynamic_Dispatch) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Class_Wide_Controlling_Operand);
   end Dispatching_Call_Dynamic_Count;

   function Dispatching_Call_Static_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dispatching_Call_Status (Model, Dispatching_Call_Static_Binding) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Primitive_Target);
   end Dispatching_Call_Static_Count;

   function Dispatching_Call_Ambiguous_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dispatching_Call_Status (Model, Dispatching_Call_Target_Ambiguous);
   end Dispatching_Call_Ambiguous_Count;

   function Dispatching_Call_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Dispatching_Call_Status (Model, Dispatching_Call_Target_Unresolved) +
        Count_Dispatching_Call_Status (Model, Dispatching_Call_Controlling_Unknown);
   end Dispatching_Call_Unknown_Count;

   function Count_Parameter_Association_Status
     (Model  : Expression_Type_Model;
      Status : Parameter_Association_Inference_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         if Model.Expressions.Element (Positive (I)).Parameter_Association_Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Parameter_Association_Status;

   function Parameter_Association_Context_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Parameter_Association_Status (Model, Parameter_Association_Formal_Context_Found) +
        Count_Parameter_Association_Status (Model, Parameter_Association_Expected_Propagated) +
        Count_Parameter_Association_Status (Model, Parameter_Association_Compatible) +
        Count_Parameter_Association_Status (Model, Parameter_Association_Mismatch);
   end Parameter_Association_Context_Count;

   function Parameter_Association_Propagated_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Parameter_Association_Status (Model, Parameter_Association_Expected_Propagated);
   end Parameter_Association_Propagated_Count;

   function Parameter_Association_Mismatch_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Parameter_Association_Status (Model, Parameter_Association_Mismatch);
   end Parameter_Association_Mismatch_Count;

   function Parameter_Association_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Parameter_Association_Status (Model, Parameter_Association_Unknown) +
        Count_Parameter_Association_Status (Model, Parameter_Association_Formal_Context_Unresolved) +
        Count_Parameter_Association_Status (Model, Parameter_Association_Formal_Context_Ambiguous);
   end Parameter_Association_Unknown_Count;

   function Attribute_Resolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Attribute_Status (Model, Attribute_Type_Scalar_Bound) +
        Count_Attribute_Status (Model, Attribute_Type_Range_Bound) +
        Count_Attribute_Status (Model, Attribute_Type_Integer_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Boolean_Result) +
        Count_Attribute_Status (Model, Attribute_Type_String_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Address_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Size_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Value_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Callable_Result);
   end Attribute_Resolved_Count;

   function Attribute_Static_Result_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Attribute_Status (Model, Attribute_Type_Scalar_Bound) +
        Count_Attribute_Status (Model, Attribute_Type_Integer_Result) +
        Count_Attribute_Status (Model, Attribute_Type_Size_Result);
   end Attribute_Static_Result_Count;

   function Attribute_String_Result_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Attribute_Status (Model, Attribute_Type_String_Result);
   end Attribute_String_Result_Count;

   function Attribute_Unknown_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Attribute_Status (Model, Attribute_Type_Unknown_Attribute) +
        Count_Attribute_Status (Model, Attribute_Type_Malformed);
   end Attribute_Unknown_Count;

   function Attribute_Prefix_Unresolved_Count (Model : Expression_Type_Model) return Natural is
   begin
      return Count_Attribute_Status (Model, Attribute_Type_Prefix_Unresolved);
   end Attribute_Prefix_Unresolved_Count;

   function Fingerprint (Model : Expression_Type_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Expression_Types;
