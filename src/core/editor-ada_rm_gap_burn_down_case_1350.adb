package body Editor.Ada_RM_Gap_Burn_Down_Case_1350 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Burn_Down_Row;

   function Count (Results : Burn_Down_Model) return Natural is
   begin
      return Natural (Results.Items.Length);
   end Count;

   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry is
   begin
      return Results.Items.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry is
   begin
      for R of Results.Items loop
         if R.Id = Id then
            return R;
         end if;
      end loop;

      return
        (Id => Id,
         Gap => Gap_Unknown,
         Family => Matrix.Family_Unknown,
         Owner => Matrix.Slice_Unknown,
         Previous_State => Remediation.State_Unknown,
         Promoted_State => Remediation.State_Unknown,
         Matrix_Level_After => Matrix.Coverage_Unknown,
         Consumer => Consumers.Consumer_Unknown,
         Classification => Precision.Class_Unknown,
         Status => Status_Not_Checked,
         Blocker_Count => 0,
         Entry_Fingerprint => 0);
   end Result_For;

   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean is
   begin
      return Count (Results) > 0
        and then Results.Invalid_Count = 0
        and then Results.Burned_Down_Count = Count (Results)
        and then Results.Legal_Count > 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Indeterminate_Count > 0;
   end RM_Gap_Burn_Down_Ready;

   function Subtype_Static_Predicate_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Subtype_Constraint_Static_Choice_Predicate
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Subtype_Static_Predicate_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Non_Discrete_Subtype
                     | Status_Illegal_Range_Bounds_Out_Of_Base
                     | Status_Illegal_Range_Lower_Greater_Than_Upper
                     | Status_Illegal_Modular_Modulus_Mismatch
                     | Status_Illegal_Floating_Digits_Constraint
                     | Status_Illegal_Fixed_Delta_Constraint
                     | Status_Illegal_Array_Index_Non_Discrete
                     | Status_Illegal_Discriminant_Constraint_Mismatch
                     | Status_Illegal_Static_Expression_Required
                     | Status_Illegal_Static_Divide_By_Zero
                     | Status_Illegal_Static_Exponent_Not_Natural
                     | Status_Illegal_Static_Universal_Resolution_Failed
                     | Status_Illegal_Static_Attribute_Prefix_Mismatch
                     | Status_Illegal_Choice_Type_Mismatch
                     | Status_Illegal_Non_Static_Choice
                     | Status_Illegal_Overlapping_Choices
                     | Status_Illegal_Incomplete_Case_Coverage
                     | Status_Illegal_Duplicate_Others
                     | Status_Illegal_Others_Placement
                     | Status_Illegal_Static_Predicate_Not_Static
                     | Status_Illegal_Static_Predicate_False_For_Subtype
                     | Status_Illegal_Aggregate_Static_Choice_Disagreement
                     | Status_Illegal_Assignment_Range_Evidence_Disagreement
                     | Status_Illegal_Loop_Discrete_Subtype_Disagreement
                     | Status_Illegal_Representation_Static_Position_Disagreement
                     | Status_Runtime_Range_Check_Preserved
                     | Status_Runtime_Bounds_Check_Preserved
                     | Status_Runtime_Predicate_Check_Preserved
                     | Status_Runtime_Membership_Check_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Static_Evidence
                     | Status_Indeterminate_Missing_Type_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Non_Discrete_Subtype
            | Status_Illegal_Range_Bounds_Out_Of_Base
            | Status_Illegal_Range_Lower_Greater_Than_Upper
            | Status_Illegal_Modular_Modulus_Mismatch
            | Status_Illegal_Floating_Digits_Constraint
            | Status_Illegal_Fixed_Delta_Constraint
            | Status_Illegal_Array_Index_Non_Discrete
            | Status_Illegal_Discriminant_Constraint_Mismatch
            | Status_Illegal_Static_Expression_Required
            | Status_Illegal_Static_Divide_By_Zero
            | Status_Illegal_Static_Exponent_Not_Natural
            | Status_Illegal_Static_Universal_Resolution_Failed
            | Status_Illegal_Static_Attribute_Prefix_Mismatch
            | Status_Illegal_Choice_Type_Mismatch
            | Status_Illegal_Non_Static_Choice
            | Status_Illegal_Overlapping_Choices
            | Status_Illegal_Incomplete_Case_Coverage
            | Status_Illegal_Duplicate_Others
            | Status_Illegal_Others_Placement
            | Status_Illegal_Static_Predicate_Not_Static
            | Status_Illegal_Static_Predicate_False_For_Subtype
            | Status_Illegal_Aggregate_Static_Choice_Disagreement
            | Status_Illegal_Assignment_Range_Evidence_Disagreement
            | Status_Illegal_Loop_Discrete_Subtype_Disagreement
            | Status_Illegal_Representation_Static_Position_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Runtime_Range_Check_Preserved
            | Status_Runtime_Bounds_Check_Preserved
            | Status_Runtime_Predicate_Check_Preserved
            | Status_Runtime_Membership_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Static_Evidence
            | Status_Indeterminate_Missing_Type_Evidence
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
      if Result.Status = Status_Not_Checked
        or else Is_Valid_Status (Result.Status)
      then
         Result.Status := Status;
      elsif Result.Status /= Status then
         Result.Status := Status_Multiple_Blockers;
      end if;
   end Add_Blocker;

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
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Static_Fingerprint /= Row.Expected_Static_Fingerprint then
         Add_Blocker (Result, Status_Static_Fingerprint_Mismatch);
      end if;
      if Row.Choice_Fingerprint /= Row.Expected_Choice_Fingerprint then
         Add_Blocker (Result, Status_Choice_Fingerprint_Mismatch);
      end if;
      if Row.Predicate_Fingerprint /= Row.Expected_Predicate_Fingerprint then
         Add_Blocker (Result, Status_Predicate_Fingerprint_Mismatch);
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

   function Rule_Status (Row : Burn_Down_Row) return Burn_Down_Status is
   begin
      if Row.Private_View_Barrier then
         return Status_Indeterminate_Private_View;
      elsif Row.Limited_View_Barrier then
         return Status_Indeterminate_Limited_View;
      elsif Row.Incomplete_View_Barrier then
         return Status_Indeterminate_Incomplete_View;
      elsif Row.Generic_Formal_View_Barrier then
         return Status_Indeterminate_Generic_Formal_View;
      elsif Row.Missing_Full_View_Evidence then
         return Status_Indeterminate_Missing_Full_View;
      elsif Row.Missing_Cross_Unit_Evidence then
         return Status_Indeterminate_Missing_Cross_Unit_Evidence;
      elsif Row.Missing_Static_Evidence then
         return Status_Indeterminate_Missing_Static_Evidence;
      elsif Row.Missing_Type_Evidence then
         return Status_Indeterminate_Missing_Type_Evidence;
      elsif not Row.Discrete_Subtype_Required_Satisfied then
         return Status_Illegal_Non_Discrete_Subtype;
      elsif not Row.Range_Bounds_Within_Base then
         return Status_Illegal_Range_Bounds_Out_Of_Base;
      elsif not Row.Range_Lower_LE_Upper then
         return Status_Illegal_Range_Lower_Greater_Than_Upper;
      elsif not Row.Modular_Modulus_Compatible then
         return Status_Illegal_Modular_Modulus_Mismatch;
      elsif not Row.Floating_Digits_Compatible then
         return Status_Illegal_Floating_Digits_Constraint;
      elsif not Row.Fixed_Delta_Compatible then
         return Status_Illegal_Fixed_Delta_Constraint;
      elsif not Row.Array_Index_Discrete then
         return Status_Illegal_Array_Index_Non_Discrete;
      elsif not Row.Discriminant_Constraint_Compatible then
         return Status_Illegal_Discriminant_Constraint_Mismatch;
      elsif not Row.Static_Expression_When_Required then
         return Status_Illegal_Static_Expression_Required;
      elsif Row.Static_Divide_By_Zero then
         return Status_Illegal_Static_Divide_By_Zero;
      elsif not Row.Static_Exponent_Natural then
         return Status_Illegal_Static_Exponent_Not_Natural;
      elsif not Row.Universal_Resolution_Agrees then
         return Status_Illegal_Static_Universal_Resolution_Failed;
      elsif not Row.Static_Attribute_Prefix_Compatible then
         return Status_Illegal_Static_Attribute_Prefix_Mismatch;
      elsif not Row.Choice_Type_Compatible then
         return Status_Illegal_Choice_Type_Mismatch;
      elsif not Row.Choice_Static_When_Required then
         return Status_Illegal_Non_Static_Choice;
      elsif Row.Choices_Overlap then
         return Status_Illegal_Overlapping_Choices;
      elsif not Row.Case_Coverage_Complete then
         return Status_Illegal_Incomplete_Case_Coverage;
      elsif Row.Duplicate_Others then
         return Status_Illegal_Duplicate_Others;
      elsif not Row.Others_Placement_Valid then
         return Status_Illegal_Others_Placement;
      elsif not Row.Static_Predicate_Is_Static then
         return Status_Illegal_Static_Predicate_Not_Static;
      elsif not Row.Static_Predicate_Holds then
         return Status_Illegal_Static_Predicate_False_For_Subtype;
      elsif Row.Range_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Range_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Bounds_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Bounds_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Predicate_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Predicate_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Membership_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Membership_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif not Row.Aggregate_Static_Choice_Consumes then
         return Status_Illegal_Aggregate_Static_Choice_Disagreement;
      elsif not Row.Assignment_Range_Predicate_Consumes then
         return Status_Illegal_Assignment_Range_Evidence_Disagreement;
      elsif not Row.Loop_Discrete_Subtype_Consumes then
         return Status_Illegal_Loop_Discrete_Subtype_Disagreement;
      elsif not Row.Representation_Static_Position_Consumes then
         return Status_Illegal_Representation_Static_Position_Disagreement;
      else
         return Status_Legal_Gap_Burned_Down;
      end if;
   end Rule_Status;

   procedure Check_Row
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
      Status : constant Burn_Down_Status := Rule_Status (Row);
      Classification : constant Precision_Classification := Expected_For_Status (Status);
   begin
      Result.Status := Status;
      Result.Classification := Classification;
      Result.Promoted_State := Row.Target_State;
      Result.Entry_Fingerprint :=
        1_350_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Static_Construct_Kind'Pos (Row.Construct)
        + Static_Context_Kind'Pos (Row.Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Static_Fingerprint
        + Row.Choice_Fingerprint
        + Row.Predicate_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Consumer_Fingerprint;

      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
      if not Row.Remediation_Entry_Present then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      end if;
      if not Row.Matrix_Coverage_Present then
         Add_Blocker (Result, Status_Missing_Matrix_Coverage);
      end if;
      if not Row.Implementing_Package_Present then
         Add_Blocker (Result, Status_Missing_Implementing_Package);
      end if;
      if not Row.New_Legality_Rule_Added then
         Add_Blocker (Result, Status_No_New_Legality_Rule);
      end if;
      if Row.Target_State /= Remediation.State_Covered
        or else Row.Matrix_Level_After /= Matrix.Coverage_Covered
        or else not Row.Coverage_Entry_Updated_To_Covered
      then
         Add_Blocker (Result, Status_Coverage_Not_Updated_To_Covered);
      end if;
      if not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Regression_Corpus_Not_Balanced);
      end if;
      if not Row.Semantic_Result_Consumed then
         Add_Blocker (Result, Status_Semantic_Result_Unconsumed);
      end if;
      if not Row.Consumer_Reached then
         Add_Blocker (Result, Status_Consumer_Not_Reached);
      end if;
      if not Row.Consumer_Subtype_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Subtype_Model_Disagreement);
      end if;
      if not Row.Consumer_Static_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Static_Model_Disagreement);
      end if;
      if not Row.Consumer_Choice_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Choice_Model_Disagreement);
      end if;
      if not Row.Consumer_Predicate_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Predicate_Model_Disagreement);
      end if;
      if not Row.Consumer_Diagnostic_Bridge_Agrees then
         Add_Blocker (Result, Status_Consumer_Diagnostic_Bridge_Disagreement);
      end if;
      if not Row.Stable_Blocker_Family
        and then Classification = Precision.Class_Illegal
      then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
      if Status = Status_Runtime_Check_Evidence_Lost then
         Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
      end if;
      if Row.Expected /= Precision.Class_Unknown
        and then Row.Expected /= Classification
      then
         Add_Blocker (Result, Status_Unexpected_Classification);
      end if;

      Check_Fingerprints (Row, Result);
   end Check_Row;

   procedure Count_Result
     (Results : in out Burn_Down_Model;
      Result : Burn_Down_Entry) is
   begin
      if Is_Valid_Status (Result.Status) then
         Results.Burned_Down_Count := Results.Burned_Down_Count + 1;
      else
         Results.Invalid_Count := Results.Invalid_Count + 1;
      end if;

      case Result.Classification is
         when Precision.Class_Legal =>
            Results.Legal_Count := Results.Legal_Count + 1;
         when Precision.Class_Illegal =>
            Results.Illegal_Count := Results.Illegal_Count + 1;
         when Precision.Class_Legal_With_Runtime_Check =>
            Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
         when Precision.Class_Indeterminate =>
            Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
         when others =>
            null;
      end case;

      Results.Audit_Fingerprint :=
        Results.Audit_Fingerprint
        + Result.Entry_Fingerprint
        + Burn_Down_Status'Pos (Result.Status)
        + Precision.Precision_Classification'Pos (Result.Classification)
        + Result.Blocker_Count;
   end Count_Result;

   function Build (Input : Burn_Down_Input) return Burn_Down_Model is
      Results : Burn_Down_Model;
   begin
      for Row of Input.Rows loop
         declare
            R : Burn_Down_Entry :=
              (Id => Row.Id,
               Gap => Row.Gap,
               Family => Row.Family,
               Owner => Row.Owner,
               Previous_State => Row.Previous_State,
               Promoted_State => Remediation.State_Unknown,
               Matrix_Level_After => Row.Matrix_Level_After,
               Consumer => Row.Consumer,
               Classification => Precision.Class_Unknown,
               Status => Status_Not_Checked,
               Blocker_Count => 0,
               Entry_Fingerprint => 0);
         begin
            Check_Row (Row, R);
            Results.Items.Append (R);
            Count_Result (Results, R);
         end;
      end loop;

      return Results;
   end Build;

end Editor.Ada_RM_Gap_Burn_Down_Case_1350;
