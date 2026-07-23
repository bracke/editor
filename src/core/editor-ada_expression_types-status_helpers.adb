with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Text_Helpers;

package body Editor.Ada_Expression_Types.Status_Helpers is

   function Trim (Text : String) return String
     renames Editor.Text_Helpers.Trim;

   function Normalize (Text : String) return String
     renames Editor.Text_Helpers.Normalize;

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

end Editor.Ada_Expression_Types.Status_Helpers;
