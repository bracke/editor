package body Editor.Ada_RM_Gap_Burn_Down_Pass1349 is

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

   function Name_Visibility_Attribute_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if not RM_Gap_Burn_Down_Ready (Results) then
         return False;
      end if;

      for R of Results.Items loop
         if R.Gap = Gap_Name_Visibility_Attribute_Selector
           and then R.Promoted_State = Remediation.State_Covered
           and then R.Matrix_Level_After = Matrix.Coverage_Covered
         then
            Saw_Target_Gap := True;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Name_Visibility_Attribute_Gap_Closed;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Gap_Burned_Down
                     | Status_Legal_Gap_Burned_Down
                     | Status_Illegal_Private_Child_Visibility_Leak
                     | Status_Illegal_Name_Not_Directly_Visible
                     | Status_Illegal_Selected_Prefix_Not_Visible
                     | Status_Illegal_Selector_Missing
                     | Status_Illegal_Ambiguous_Selector
                     | Status_Illegal_Homograph_Conflict
                     | Status_Illegal_Use_Visible_Homograph
                     | Status_Illegal_Use_Type_Operator_Not_Visible
                     | Status_Illegal_Attribute_Prefix_Kind_Mismatch
                     | Status_Illegal_Attribute_Static_Requirement_Missing
                     | Status_Illegal_Attribute_Result_Type_Mismatch
                     | Status_Illegal_Dereference_Non_Access_Prefix
                     | Status_Illegal_Index_Count_Mismatch
                     | Status_Illegal_Array_Index_Type_Mismatch
                     | Status_Illegal_Generalized_Indexing_Profile_Missing
                     | Status_Illegal_Generalized_Indexing_Profile_Mismatch
                     | Status_Illegal_Component_Selection_Type_Mismatch
                     | Status_Illegal_Overload_Set_Mismatch
                     | Status_Illegal_Expected_Type_Lost
                     | Status_Illegal_Callable_Profile_Mismatch
                     | Status_Illegal_No_Visible_Candidate
                     | Status_Illegal_Ambiguous_Overload
                     | Status_Runtime_Null_Dereference_Check_Preserved
                     | Status_Runtime_Index_Bounds_Check_Preserved
                     | Status_Runtime_Generalized_Indexing_Check_Preserved
                     | Status_Indeterminate_Private_View
                     | Status_Indeterminate_Limited_View
                     | Status_Indeterminate_Incomplete_View
                     | Status_Indeterminate_Generic_Formal_View
                     | Status_Indeterminate_Missing_Full_View
                     | Status_Indeterminate_Missing_Cross_Unit_Evidence
                     | Status_Indeterminate_Missing_Overload_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Gap_Burned_Down | Status_Gap_Burned_Down =>
            return Precision.Class_Legal;
         when Status_Illegal_Private_Child_Visibility_Leak
            | Status_Illegal_Name_Not_Directly_Visible
            | Status_Illegal_Selected_Prefix_Not_Visible
            | Status_Illegal_Selector_Missing
            | Status_Illegal_Ambiguous_Selector
            | Status_Illegal_Homograph_Conflict
            | Status_Illegal_Use_Visible_Homograph
            | Status_Illegal_Use_Type_Operator_Not_Visible
            | Status_Illegal_Attribute_Prefix_Kind_Mismatch
            | Status_Illegal_Attribute_Static_Requirement_Missing
            | Status_Illegal_Attribute_Result_Type_Mismatch
            | Status_Illegal_Dereference_Non_Access_Prefix
            | Status_Illegal_Index_Count_Mismatch
            | Status_Illegal_Array_Index_Type_Mismatch
            | Status_Illegal_Generalized_Indexing_Profile_Missing
            | Status_Illegal_Generalized_Indexing_Profile_Mismatch
            | Status_Illegal_Component_Selection_Type_Mismatch
            | Status_Illegal_Overload_Set_Mismatch
            | Status_Illegal_Expected_Type_Lost
            | Status_Illegal_Callable_Profile_Mismatch
            | Status_Illegal_No_Visible_Candidate
            | Status_Illegal_Ambiguous_Overload =>
            return Precision.Class_Illegal;
         when Status_Runtime_Null_Dereference_Check_Preserved
            | Status_Runtime_Index_Bounds_Check_Preserved
            | Status_Runtime_Generalized_Indexing_Check_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Cross_Unit_Evidence
            | Status_Indeterminate_Missing_Overload_Evidence
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
      if Row.Entity_Fingerprint /= Row.Expected_Entity_Fingerprint then
         Add_Blocker (Result, Status_Entity_Fingerprint_Mismatch);
      end if;
      if Row.Type_Fingerprint /= Row.Expected_Type_Fingerprint then
         Add_Blocker (Result, Status_Type_Fingerprint_Mismatch);
      end if;
      if Row.Profile_Fingerprint /= Row.Expected_Profile_Fingerprint then
         Add_Blocker (Result, Status_Profile_Fingerprint_Mismatch);
      end if;
      if Row.View_Fingerprint /= Row.Expected_View_Fingerprint then
         Add_Blocker (Result, Status_View_Fingerprint_Mismatch);
      end if;
      if Row.Overload_Fingerprint /= Row.Expected_Overload_Fingerprint then
         Add_Blocker (Result, Status_Overload_Fingerprint_Mismatch);
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
      elsif Row.Missing_Overload_Evidence then
         return Status_Indeterminate_Missing_Overload_Evidence;
      elsif not Row.Private_Child_Visibility_Respected then
         return Status_Illegal_Private_Child_Visibility_Leak;
      elsif not Row.Direct_Visibility_Agrees then
         return Status_Illegal_Name_Not_Directly_Visible;
      elsif not Row.Selected_Prefix_Visible then
         return Status_Illegal_Selected_Prefix_Not_Visible;
      elsif not Row.Hiding_Homographs_Disambiguated then
         return Status_Illegal_Homograph_Conflict;
      elsif not Row.Use_Package_Homographs_Overloadable then
         return Status_Illegal_Use_Visible_Homograph;
      elsif not Row.Use_Type_Operators_Visible then
         return Status_Illegal_Use_Type_Operator_Not_Visible;
      elsif not Row.Selector_Exists then
         return Status_Illegal_Selector_Missing;
      elsif Row.Selector_Ambiguous then
         return Status_Illegal_Ambiguous_Selector;
      elsif not Row.Attribute_Prefix_Kind_Compatible then
         return Status_Illegal_Attribute_Prefix_Kind_Mismatch;
      elsif not Row.Attribute_Static_Requirement_Satisfied then
         return Status_Illegal_Attribute_Static_Requirement_Missing;
      elsif not Row.Attribute_Result_Type_Compatible then
         return Status_Illegal_Attribute_Result_Type_Mismatch;
      elsif not Row.Explicit_Dereference_Access_Prefix then
         return Status_Illegal_Dereference_Non_Access_Prefix;
      elsif not Row.Implicit_Dereference_Allowed then
         return Status_Illegal_Dereference_Non_Access_Prefix;
      elsif Row.Null_Dereference_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Null_Dereference_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif not Row.Index_Count_Compatible then
         return Status_Illegal_Index_Count_Mismatch;
      elsif not Row.Index_Type_Compatible then
         return Status_Illegal_Array_Index_Type_Mismatch;
      elsif Row.Index_Bounds_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Index_Bounds_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif not Row.Generalized_Indexing_Profile_Present then
         return Status_Illegal_Generalized_Indexing_Profile_Missing;
      elsif not Row.Generalized_Indexing_Profile_Compatible then
         return Status_Illegal_Generalized_Indexing_Profile_Mismatch;
      elsif Row.Generalized_Indexing_Runtime_Check then
         if Row.Runtime_Check_Evidence_Preserved then
            return Status_Runtime_Generalized_Indexing_Check_Preserved;
         else
            return Status_Runtime_Check_Evidence_Lost;
         end if;
      elsif not Row.Component_Selection_Type_Compatible then
         return Status_Illegal_Component_Selection_Type_Mismatch;
      elsif not Row.Overload_Set_Canonical then
         return Status_Illegal_Overload_Set_Mismatch;
      elsif not Row.Expected_Type_Propagated then
         return Status_Illegal_Expected_Type_Lost;
      elsif not Row.Callable_Profile_Agrees then
         return Status_Illegal_Callable_Profile_Mismatch;
      elsif not Row.Visible_Candidate_Present then
         return Status_Illegal_No_Visible_Candidate;
      elsif Row.Overload_Ambiguous then
         return Status_Illegal_Ambiguous_Overload;
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
        1_349_000
        + Row.Id
        + Burn_Down_Gap'Pos (Row.Gap)
        + Matrix.RM_Family'Pos (Row.Family)
        + Matrix.Implementing_Slice'Pos (Row.Owner)
        + Remediation.Remediation_State'Pos (Row.Previous_State)
        + Remediation.Remediation_State'Pos (Row.Target_State)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_Before)
        + Matrix.Coverage_Level'Pos (Row.Matrix_Level_After)
        + Name_Construct_Kind'Pos (Row.Construct)
        + Resolution_Context_Kind'Pos (Row.Context)
        + Precision.Precision_Classification'Pos (Row.Expected)
        + Row.Burn_Down_Fingerprint
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Entity_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.View_Fingerprint
        + Row.Overload_Fingerprint
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
      if not Row.Consumer_Name_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Name_Model_Disagreement);
      end if;
      if not Row.Consumer_Entity_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Entity_Model_Disagreement);
      end if;
      if not Row.Consumer_View_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_View_Model_Disagreement);
      end if;
      if not Row.Consumer_Attribute_Model_Agrees then
         Add_Blocker (Result, Status_Consumer_Attribute_Model_Disagreement);
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

end Editor.Ada_RM_Gap_Burn_Down_Pass1349;
