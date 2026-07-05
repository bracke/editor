package body Editor.Ada_RM_Gap_Burn_Down_Case_1357 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry is
      Empty : Burn_Down_Entry;
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return Empty;
   end Result_For;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in
        Status_Gap_Burned_Down
        | Status_Legal_Gap_Burned_Down
        | Status_Runtime_Overflow_Check_Preserved
        | Status_Runtime_Range_Check_Preserved
        | Status_Illegal_Canonical_Operator_Disagreement
        | Status_Illegal_Predefined_Operator_Unavailable
        | Status_Illegal_Predefined_Operator_Visibility_Disagreement
        | Status_Illegal_Universal_Resolution_Disagreement
        | Status_Illegal_Expected_Type_Resolution_Lost
        | Status_Illegal_Static_Evaluation_Overload_Disagreement
        | Status_Illegal_User_Defined_Operator_Ambiguity
        | Status_Illegal_No_Visible_Operator
        | Status_Illegal_Primitive_Operator_Preference_Lost
        | Status_Illegal_Use_Type_Operator_Visibility_Lost
        | Status_Illegal_Callable_Profile_Disagreement
        | Status_Illegal_Generic_Formal_Operator_Substitution_Lost
        | Status_Illegal_Modular_Operand_Incompatible
        | Status_Illegal_Fixed_Point_Operand_Incompatible
        | Status_Illegal_Floating_Operand_Incompatible
        | Status_Illegal_Integer_Operand_Incompatible
        | Status_Illegal_Real_Operand_Incompatible
        | Status_Illegal_Array_String_Operator_Incompatible
        | Status_Illegal_Access_Equality_Incompatible
        | Status_Illegal_Tagged_Equality_Evidence_Lost
        | Status_Illegal_Enumeration_Ordering_Evidence_Lost
        | Status_Illegal_Static_Division_By_Zero
        | Status_Illegal_Exponent_Not_Natural
        | Status_Illegal_Static_Overflow
        | Status_Illegal_Assignment_Conversion_Numeric_Disagreement
        | Status_Illegal_Subtype_Range_Predicate_Disagreement
        | Status_Illegal_Generic_Replay_Numeric_Disagreement
        | Status_Illegal_Contract_Predicate_Numeric_Disagreement
        | Status_Illegal_Diagnostics_Numeric_Disagreement
        | Status_Illegal_Colouring_Numeric_Disagreement
        | Status_Illegal_Outline_Declaration_Numeric_Disagreement
        | Status_Illegal_Navigation_Target_Numeric_Disagreement
        | Status_Illegal_Hover_Numeric_Disagreement
        | Status_Illegal_Diagnostic_Bridge_Numeric_Disagreement
        | Status_Indeterminate_Private_View
        | Status_Indeterminate_Limited_View
        | Status_Indeterminate_Incomplete_View
        | Status_Indeterminate_Generic_Formal_View
        | Status_Indeterminate_Missing_Full_View
        | Status_Indeterminate_Missing_Cross_Unit_Evidence
        | Status_Indeterminate_Missing_Operator_Evidence
        | Status_Indeterminate_Missing_Type_Evidence
        | Status_Indeterminate_Missing_Expected_Type_Evidence
        | Status_Indeterminate_Missing_Static_Evidence
        | Status_Indeterminate_Missing_Overload_Evidence
        | Status_Indeterminate_Missing_Profile_Evidence
        | Status_Indeterminate_Missing_Generic_Substitution_Evidence
        | Status_Indeterminate_Missing_Effect_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Runtime_Overflow_Check_Preserved
            | Status_Runtime_Range_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Canonical_Operator_Disagreement
            | Status_Illegal_Predefined_Operator_Unavailable
            | Status_Illegal_Predefined_Operator_Visibility_Disagreement
            | Status_Illegal_Universal_Resolution_Disagreement
            | Status_Illegal_Expected_Type_Resolution_Lost
            | Status_Illegal_Static_Evaluation_Overload_Disagreement
            | Status_Illegal_User_Defined_Operator_Ambiguity
            | Status_Illegal_No_Visible_Operator
            | Status_Illegal_Primitive_Operator_Preference_Lost
            | Status_Illegal_Use_Type_Operator_Visibility_Lost
            | Status_Illegal_Callable_Profile_Disagreement
            | Status_Illegal_Generic_Formal_Operator_Substitution_Lost
            | Status_Illegal_Modular_Operand_Incompatible
            | Status_Illegal_Fixed_Point_Operand_Incompatible
            | Status_Illegal_Floating_Operand_Incompatible
            | Status_Illegal_Integer_Operand_Incompatible
            | Status_Illegal_Real_Operand_Incompatible
            | Status_Illegal_Array_String_Operator_Incompatible
            | Status_Illegal_Access_Equality_Incompatible
            | Status_Illegal_Tagged_Equality_Evidence_Lost
            | Status_Illegal_Enumeration_Ordering_Evidence_Lost
            | Status_Illegal_Static_Division_By_Zero
            | Status_Illegal_Exponent_Not_Natural
            | Status_Illegal_Static_Overflow
            | Status_Illegal_Assignment_Conversion_Numeric_Disagreement
            | Status_Illegal_Subtype_Range_Predicate_Disagreement
            | Status_Illegal_Generic_Replay_Numeric_Disagreement
            | Status_Illegal_Contract_Predicate_Numeric_Disagreement
            | Status_Illegal_Diagnostics_Numeric_Disagreement
            | Status_Illegal_Colouring_Numeric_Disagreement
            | Status_Illegal_Outline_Declaration_Numeric_Disagreement
            | Status_Illegal_Navigation_Target_Numeric_Disagreement
            | Status_Illegal_Hover_Numeric_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Numeric_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Operator_Evidence
            | Status_Indeterminate_Missing_Type_Evidence
            | Status_Indeterminate_Missing_Expected_Type_Evidence
            | Status_Indeterminate_Missing_Static_Evidence
            | Status_Indeterminate_Missing_Overload_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
            | Status_Indeterminate_Missing_Generic_Substitution_Evidence
            | Status_Indeterminate_Missing_Effect_Evidence
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when others =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Add_Blocker
     (Result : in out Burn_Down_Entry;
      Status : Burn_Down_Status) is
   begin
      Result.Blocker_Count := Result.Blocker_Count + 1;
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      elsif not Row.Remediation_Entry_Present then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      elsif not Row.Matrix_Coverage_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage);
      elsif not Row.Implementing_Package_Present then
         Add_Blocker (Result, Status_Missing_Implementing_Package);
      elsif not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      elsif not Row.Coverage_Entry_Updated_To_Covered then
         Add_Blocker (Result, Status_Coverage_Not_Updated_To_Covered);
      elsif not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      elsif not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      elsif not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      elsif not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Audit_Gates;

   procedure Check_Indeterminate_Evidence
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Private_View then
         Add_Blocker (Result, Status_Indeterminate_Private_View);
      elsif Row.Limited_View then
         Add_Blocker (Result, Status_Indeterminate_Limited_View);
      elsif Row.Incomplete_View then
         Add_Blocker (Result, Status_Indeterminate_Incomplete_View);
      elsif Row.Generic_Formal_View then
         Add_Blocker (Result, Status_Indeterminate_Generic_Formal_View);
      elsif Row.Missing_Full_View then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View);
      elsif Row.Missing_Cross_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Cross_Unit_Evidence);
      elsif Row.Missing_Operator_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Operator_Evidence);
      elsif Row.Missing_Type_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Type_Evidence);
      elsif Row.Missing_Expected_Type_Evidence then
         Add_Blocker
           (Result, Status_Indeterminate_Missing_Expected_Type_Evidence);
      elsif Row.Missing_Static_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Static_Evidence);
      elsif Row.Missing_Overload_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Overload_Evidence);
      elsif Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      elsif Row.Missing_Generic_Substitution_Evidence then
         Add_Blocker
           (Result, Status_Indeterminate_Missing_Generic_Substitution_Evidence);
      elsif Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Numeric_Rules
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Same_Canonical_Operator then
         Add_Blocker (Result, Status_Illegal_Canonical_Operator_Disagreement);
      elsif not Row.Predefined_Operator_Available then
         Add_Blocker (Result, Status_Illegal_Predefined_Operator_Unavailable);
      elsif not Row.Predefined_Operator_Visibility_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Predefined_Operator_Visibility_Disagreement);
      elsif not Row.Universal_Resolution_Agrees then
         Add_Blocker (Result, Status_Illegal_Universal_Resolution_Disagreement);
      elsif not Row.Expected_Type_Resolution_Preserved then
         Add_Blocker (Result, Status_Illegal_Expected_Type_Resolution_Lost);
      elsif not Row.Static_Evaluation_Agrees_With_Overload then
         Add_Blocker
           (Result, Status_Illegal_Static_Evaluation_Overload_Disagreement);
      elsif Row.User_Defined_Operator_Ambiguous then
         Add_Blocker (Result, Status_Illegal_User_Defined_Operator_Ambiguity);
      elsif Row.No_Visible_Operator then
         Add_Blocker (Result, Status_Illegal_No_Visible_Operator);
      elsif not Row.Primitive_Operator_Preference_Preserved then
         Add_Blocker (Result, Status_Illegal_Primitive_Operator_Preference_Lost);
      elsif not Row.Use_Type_Operator_Visibility_Preserved then
         Add_Blocker (Result, Status_Illegal_Use_Type_Operator_Visibility_Lost);
      elsif not Row.Callable_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Callable_Profile_Disagreement);
      elsif not Row.Generic_Formal_Operator_Substitution_Preserved then
         Add_Blocker
           (Result, Status_Illegal_Generic_Formal_Operator_Substitution_Lost);
      elsif not Row.Modular_Operand_Compatible then
         Add_Blocker (Result, Status_Illegal_Modular_Operand_Incompatible);
      elsif not Row.Fixed_Point_Operand_Compatible then
         Add_Blocker (Result, Status_Illegal_Fixed_Point_Operand_Incompatible);
      elsif not Row.Floating_Operand_Compatible then
         Add_Blocker (Result, Status_Illegal_Floating_Operand_Incompatible);
      elsif not Row.Integer_Operand_Compatible then
         Add_Blocker (Result, Status_Illegal_Integer_Operand_Incompatible);
      elsif not Row.Real_Operand_Compatible then
         Add_Blocker (Result, Status_Illegal_Real_Operand_Incompatible);
      elsif not Row.Array_String_Operator_Compatible then
         Add_Blocker (Result, Status_Illegal_Array_String_Operator_Incompatible);
      elsif not Row.Access_Equality_Compatible then
         Add_Blocker (Result, Status_Illegal_Access_Equality_Incompatible);
      elsif not Row.Tagged_Equality_Preserved then
         Add_Blocker (Result, Status_Illegal_Tagged_Equality_Evidence_Lost);
      elsif not Row.Enumeration_Ordering_Preserved then
         Add_Blocker (Result, Status_Illegal_Enumeration_Ordering_Evidence_Lost);
      elsif Row.Static_Division_By_Zero then
         Add_Blocker (Result, Status_Illegal_Static_Division_By_Zero);
      elsif not Row.Exponent_Natural then
         Add_Blocker (Result, Status_Illegal_Exponent_Not_Natural);
      elsif Row.Static_Overflow then
         Add_Blocker (Result, Status_Illegal_Static_Overflow);
      elsif not Row.Assignment_Conversion_Numeric_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Assignment_Conversion_Numeric_Disagreement);
      elsif not Row.Subtype_Range_Predicate_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Subtype_Range_Predicate_Disagreement);
      elsif not Row.Generic_Replay_Numeric_Agrees then
         Add_Blocker (Result, Status_Illegal_Generic_Replay_Numeric_Disagreement);
      elsif not Row.Contract_Predicate_Numeric_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Contract_Predicate_Numeric_Disagreement);
      elsif Row.Runtime_Overflow_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Overflow_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      elsif Row.Runtime_Range_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result, Status_Runtime_Range_Check_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Numeric_Rules;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Numeric_Agrees then
         Add_Blocker (Result, Status_Illegal_Diagnostics_Numeric_Disagreement);
      elsif not Row.Consumer_Colouring_Agrees then
         Add_Blocker (Result, Status_Illegal_Colouring_Numeric_Disagreement);
      elsif not Row.Consumer_Declaration_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Outline_Declaration_Numeric_Disagreement);
      elsif not Row.Consumer_Target_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Navigation_Target_Numeric_Disagreement);
      elsif not Row.Consumer_Detail_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_Numeric_Disagreement);
      elsif not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Diagnostic_Bridge_Numeric_Disagreement);
      end if;
   end Check_Consumers;

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Evidence_Stale
        or else Row.Burn_Down_Fingerprint /= Row.Expected_Burn_Down_Fingerprint
      then
         Add_Blocker (Result, Status_Stale_Burn_Down_Fingerprint);
      end if;
      if Row.Source_Fingerprint /= Row.Expected_Source_Fingerprint then
         Add_Blocker (Result, Status_Source_Fingerprint_Mismatch);
      end if;
      if Row.AST_Fingerprint /= Row.Expected_AST_Fingerprint then
         Add_Blocker (Result, Status_AST_Fingerprint_Mismatch);
      end if;
      if Row.Operator_Fingerprint /= Row.Expected_Operator_Fingerprint then
         Add_Blocker (Result, Status_Operator_Fingerprint_Mismatch);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Expected_Type_Context_Fingerprint
        /= Row.Expected_Expected_Type_Context_Fingerprint
      then
         Add_Blocker (Result, Status_Expected_Type_Fingerprint_Mismatch);
      end if;
      if Row.Static_Fingerprint /= Row.Expected_Static_Fingerprint then
         Add_Blocker (Result, Status_Static_Fingerprint_Mismatch);
      end if;
      if Row.Overload_Fingerprint /= Row.Expected_Overload_Fingerprint then
         Add_Blocker (Result, Status_Overload_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Construct := Row.Construct;
      Result.Context := Row.Context;
      Result.Result_Fingerprint := Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Operator_Fingerprint
        + Row.Type_Fingerprint
        + Row.Expected_Type_Context_Fingerprint
        + Row.Static_Fingerprint
        + Row.Overload_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Id;

      Check_Audit_Gates (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Numeric_Rules (Row, Result);
      Check_Consumers (Row, Result);
      Check_Fingerprints (Row, Result);

      if Result.Status = Status_Not_Checked then
         Result.Status := Status_Legal_Gap_Burned_Down;
      end if;

      if Row.Expected /= Precision.Class_Unknown
        and then Expected_For_Status (Result.Status) /= Row.Expected
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
      end if;

      return Result;
   end Evaluate;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
      Item : Burn_Down_Entry;
      Classification : Precision_Classification;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := Evaluate (Row);
         Results.Entries.Append (Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint
           + Natural (Burn_Down_Status'Pos (Item.Status))
           + Item.Blocker_Count;

         if Item.Consumer /= Consumers.Consumer_Unknown then
            Results.Consumer_Count := Results.Consumer_Count + 1;
         end if;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Legal =>
               Results.Legal_Count := Results.Legal_Count + 1;
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Legal_With_Runtime_Check =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when others =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Predefined_Operation_Numeric_Model_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Predefined_Operation_Numeric_Model then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Predefined_Operation_Numeric_Model_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Case_1357;
