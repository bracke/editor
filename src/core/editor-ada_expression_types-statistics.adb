package body Editor.Ada_Expression_Types.Statistics is

   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;

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
      Result : Natural := 0;
   begin
      for I in 1 .. Natural (Model.Expressions.Length) loop
         declare
            Info : constant Expression_Type_Info :=
              Model.Expressions.Element (Positive (I));
         begin
            if Info.Conditional_Status = Conditional_Type_Branch_Unknown then
               Result := Result + 1;
            else
               Result := Result + Info.Conditional_Unknown_Branch_Count;
            end if;
         end;
      end loop;
      return Result;
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

end Editor.Ada_Expression_Types.Statistics;
