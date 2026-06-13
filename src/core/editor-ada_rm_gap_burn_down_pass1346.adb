package body Editor.Ada_RM_Gap_Burn_Down_Pass1346 is

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

   function Tagged_Interface_Dispatching_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Tagged_Interface_Dispatching_Contract_Effect
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Tagged_Interface_Dispatching_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Untagged_Parent_Extension
                     | Status_Illegal_Parent_Not_Visible
                     | Status_Illegal_Interface_Primitive_Not_Implemented
                     | Status_Illegal_Abstract_Primitive_Not_Implemented
                     | Status_Illegal_Synchronized_Interface_Mismatch
                     | Status_Illegal_Limited_Interface_Mismatch
                     | Status_Illegal_Null_Procedure_Profile
                     | Status_Illegal_Overriding_Indicator_Missing
                     | Status_Illegal_Overriding_Indicator_Not_Allowed
                     | Status_Illegal_Overriding_Profile_Nonconformant
                     | Status_Illegal_Parameter_Mode_Mismatch
                     | Status_Illegal_Result_Type_Mismatch
                     | Status_Illegal_Default_Conformance_Mismatch
                     | Status_Illegal_Null_Exclusion_Mismatch
                     | Status_Illegal_Convention_Mismatch
                     | Status_Illegal_Access_Subprogram_Profile_Mismatch
                     | Status_Illegal_Ambiguous_Dispatching_Call
                     | Status_Illegal_Static_Call_Where_Dispatching_Required
                     | Status_Illegal_Controlling_Operand_Mismatch
                     | Status_Illegal_Controlling_Result_Mismatch
                     | Status_Illegal_Interface_Dispatch_Target_Mismatch
                     | Status_Illegal_Classwide_Conversion_Root_Mismatch
                     | Status_Illegal_Tagged_View_Conversion_Incompatible
                     | Status_Illegal_Access_Classwide_Accessibility_Escape
                     | Status_Illegal_Pre_Post_Not_Propagated
                     | Status_Illegal_Global_Depends_Not_Propagated
                     | Status_Illegal_Refined_Effect_Not_Propagated
                     | Status_Illegal_Abstract_State_Constituent_Missing
                     | Status_Illegal_Dispatching_Effect_Join_Missing
                     | Status_Illegal_Volatile_Atomic_Effect_Lost
                     | Status_Runtime_Tagged_Accessibility_Check_Preserved
                     | Status_Runtime_Classwide_Conversion_Check_Preserved
                     | Status_Runtime_Dispatching_Predicate_Check_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Untagged_Parent_Extension
            | Status_Illegal_Parent_Not_Visible
            | Status_Illegal_Interface_Primitive_Not_Implemented
            | Status_Illegal_Abstract_Primitive_Not_Implemented
            | Status_Illegal_Synchronized_Interface_Mismatch
            | Status_Illegal_Limited_Interface_Mismatch
            | Status_Illegal_Null_Procedure_Profile
            | Status_Illegal_Overriding_Indicator_Missing
            | Status_Illegal_Overriding_Indicator_Not_Allowed
            | Status_Illegal_Overriding_Profile_Nonconformant
            | Status_Illegal_Parameter_Mode_Mismatch
            | Status_Illegal_Result_Type_Mismatch
            | Status_Illegal_Default_Conformance_Mismatch
            | Status_Illegal_Null_Exclusion_Mismatch
            | Status_Illegal_Convention_Mismatch
            | Status_Illegal_Access_Subprogram_Profile_Mismatch
            | Status_Illegal_Ambiguous_Dispatching_Call
            | Status_Illegal_Static_Call_Where_Dispatching_Required
            | Status_Illegal_Controlling_Operand_Mismatch
            | Status_Illegal_Controlling_Result_Mismatch
            | Status_Illegal_Interface_Dispatch_Target_Mismatch
            | Status_Illegal_Classwide_Conversion_Root_Mismatch
            | Status_Illegal_Tagged_View_Conversion_Incompatible
            | Status_Illegal_Access_Classwide_Accessibility_Escape
            | Status_Illegal_Pre_Post_Not_Propagated
            | Status_Illegal_Global_Depends_Not_Propagated
            | Status_Illegal_Refined_Effect_Not_Propagated
            | Status_Illegal_Abstract_State_Constituent_Missing
            | Status_Illegal_Dispatching_Effect_Join_Missing
            | Status_Illegal_Volatile_Atomic_Effect_Lost =>
            return Precision.Class_Illegal;
         when Status_Runtime_Tagged_Accessibility_Check_Preserved
            | Status_Runtime_Classwide_Conversion_Check_Preserved
            | Status_Runtime_Dispatching_Predicate_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
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
      elsif Row.Missing_Full_View then
         return Status_Indeterminate_Missing_Full_View;
      elsif Row.Missing_Cross_Unit_Evidence then
         return Status_Indeterminate_Missing_Cross_Unit_Evidence;
      elsif not Row.Tagged_Parent_Is_Tagged then
         return Status_Illegal_Untagged_Parent_Extension;
      elsif not Row.Parent_Visible then
         return Status_Illegal_Parent_Not_Visible;
      elsif not Row.Interface_Primitives_Implemented then
         return Status_Illegal_Interface_Primitive_Not_Implemented;
      elsif not Row.Concrete_Type_Implements_Abstract_Primitives then
         return Status_Illegal_Abstract_Primitive_Not_Implemented;
      elsif not Row.Synchronized_Interface_Compatible then
         return Status_Illegal_Synchronized_Interface_Mismatch;
      elsif not Row.Limited_Interface_Compatible then
         return Status_Illegal_Limited_Interface_Mismatch;
      elsif not Row.Null_Procedure_Profile_Conformant then
         return Status_Illegal_Null_Procedure_Profile;
      elsif Row.Overriding_Indicator_Missing then
         return Status_Illegal_Overriding_Indicator_Missing;
      elsif Row.Overriding_Indicator_Not_Allowed then
         return Status_Illegal_Overriding_Indicator_Not_Allowed;
      elsif not Row.Overriding_Profile_Conformant then
         return Status_Illegal_Overriding_Profile_Nonconformant;
      elsif not Row.Parameter_Modes_Conformant then
         return Status_Illegal_Parameter_Mode_Mismatch;
      elsif not Row.Result_Type_Conformant then
         return Status_Illegal_Result_Type_Mismatch;
      elsif not Row.Defaults_Conformant then
         return Status_Illegal_Default_Conformance_Mismatch;
      elsif not Row.Null_Exclusions_Conformant then
         return Status_Illegal_Null_Exclusion_Mismatch;
      elsif not Row.Convention_Conformant then
         return Status_Illegal_Convention_Mismatch;
      elsif not Row.Access_Subprogram_Profile_Conformant then
         return Status_Illegal_Access_Subprogram_Profile_Mismatch;
      elsif Row.Dispatching_Candidate_Set_Ambiguous then
         return Status_Illegal_Ambiguous_Dispatching_Call;
      elsif Row.Static_Call_Where_Dispatching_Required then
         return Status_Illegal_Static_Call_Where_Dispatching_Required;
      elsif not Row.Controlling_Operand_Compatible then
         return Status_Illegal_Controlling_Operand_Mismatch;
      elsif not Row.Controlling_Result_Compatible then
         return Status_Illegal_Controlling_Result_Mismatch;
      elsif not Row.Interface_Dispatch_Target_Compatible then
         return Status_Illegal_Interface_Dispatch_Target_Mismatch;
      elsif not Row.Classwide_Conversion_Root_Compatible then
         return Status_Illegal_Classwide_Conversion_Root_Mismatch;
      elsif not Row.Tagged_View_Conversion_Compatible then
         return Status_Illegal_Tagged_View_Conversion_Incompatible;
      elsif Row.Access_Classwide_Accessibility_Escape then
         return Status_Illegal_Access_Classwide_Accessibility_Escape;
      elsif not Row.Pre_Post_Propagated then
         return Status_Illegal_Pre_Post_Not_Propagated;
      elsif not Row.Global_Depends_Propagated then
         return Status_Illegal_Global_Depends_Not_Propagated;
      elsif not Row.Refined_Effects_Propagated then
         return Status_Illegal_Refined_Effect_Not_Propagated;
      elsif not Row.Abstract_State_Constituents_Present then
         return Status_Illegal_Abstract_State_Constituent_Missing;
      elsif not Row.Dispatching_Effect_Join_Present then
         return Status_Illegal_Dispatching_Effect_Join_Missing;
      elsif not Row.Volatile_Atomic_Effect_Preserved then
         return Status_Illegal_Volatile_Atomic_Effect_Lost;
      elsif Row.Runtime_Accessibility_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Tagged_Accessibility_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Runtime_Classwide_Conversion_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Classwide_Conversion_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif Row.Runtime_Dispatching_Predicate_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Dispatching_Predicate_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
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
        1_346_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Tagged_Construct_Kind'Pos (Row.Construct)
        + Dispatch_Context_Kind'Pos (Row.Dispatch_Context)
        + Contract_Effect_Context_Kind'Pos (Row.Effect_Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
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
      if not Row.Consumer_Tagged_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Tagged_Model_Disagreement);
      end if;
      if not Row.Consumer_Interface_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Interface_Model_Disagreement);
      end if;
      if not Row.Consumer_Dispatching_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Dispatching_Model_Disagreement);
      end if;
      if not Row.Consumer_Profile_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Profile_Model_Disagreement);
      end if;
      if not Row.Consumer_Contract_Effect_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Contract_Effect_Model_Disagreement);
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

end Editor.Ada_RM_Gap_Burn_Down_Pass1346;
