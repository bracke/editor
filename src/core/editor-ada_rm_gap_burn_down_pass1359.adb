package body Editor.Ada_RM_Gap_Burn_Down_Pass1359 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in
        Status_Gap_Burned_Down
        | Status_Legal_Source_Unit_Closure
        | Status_Runtime_Check_Final_Verdict_Preserved
        | Status_Illegal_Source_Unit_Canonical_Closure_Failed
        | Status_Illegal_Context_Closure_Disagreement
        | Status_Illegal_Private_Full_View_Disagreement
        | Status_Illegal_Body_Spec_Conformance_Disagreement
        | Status_Illegal_Elaboration_Closure_Disagreement
        | Status_Illegal_Representation_Freezing_Disagreement
        | Status_Illegal_Contract_Flow_Disagreement
        | Status_Illegal_Generic_Substitution_Not_Propagated
        | Status_Illegal_Generic_Body_Replay_Disagreement
        | Status_Illegal_Overload_Profile_Disagreement
        | Status_Illegal_Literal_Operator_Substitution_Disagreement
        | Status_Illegal_Tagged_Interface_Disagreement
        | Status_Illegal_Dispatching_Effect_Join_Missing
        | Status_Illegal_Class_Wide_Conversion_Disagreement
        | Status_Illegal_Concurrent_Shared_State_Disagreement
        | Status_Illegal_Protected_Barrier_Disagreement
        | Status_Illegal_Parallel_Iterator_Disagreement
        | Status_Illegal_Finalization_Abort_Disagreement
        | Status_Illegal_Representation_Consumer_Disagreement
        | Status_Illegal_RM_Coverage_Remediation_Missing
        | Status_Illegal_Balanced_Regression_Missing
        | Status_Illegal_Partial_Evidence_Precision_Lost
        | Status_Illegal_Consumer_Final_Verdict_Conflict
        | Status_Illegal_Diagnostics_Final_Verdict_Disagreement
        | Status_Illegal_Colouring_Final_Verdict_Disagreement
        | Status_Illegal_Outline_Final_Verdict_Disagreement
        | Status_Illegal_Navigation_Final_Verdict_Disagreement
        | Status_Illegal_Hover_Final_Verdict_Disagreement
        | Status_Illegal_Diagnostic_Bridge_Final_Verdict_Disagreement
        | Status_Indeterminate_Private_View
        | Status_Indeterminate_Limited_View
        | Status_Indeterminate_Incomplete_View
        | Status_Indeterminate_Generic_Formal_View
        | Status_Indeterminate_Missing_Full_View
        | Status_Indeterminate_Missing_Source_Unit_Evidence
        | Status_Indeterminate_Missing_AST_Evidence
        | Status_Indeterminate_Missing_Type_Evidence
        | Status_Indeterminate_Missing_Profile_Evidence
        | Status_Indeterminate_Missing_Unit_Evidence
        | Status_Indeterminate_Missing_Substitution_Evidence
        | Status_Indeterminate_Missing_Effect_Evidence
        | Status_Indeterminate_Missing_Policy_Evidence
        | Status_Indeterminate_Missing_Consumer_Evidence;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Gap_Burned_Down
            | Status_Legal_Source_Unit_Closure =>
            return Precision.Class_Legal;
         when Status_Runtime_Check_Final_Verdict_Preserved
            | Status_Runtime_Check_Evidence_Lost =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Illegal_Source_Unit_Canonical_Closure_Failed
            | Status_Illegal_Context_Closure_Disagreement
            | Status_Illegal_Private_Full_View_Disagreement
            | Status_Illegal_Body_Spec_Conformance_Disagreement
            | Status_Illegal_Elaboration_Closure_Disagreement
            | Status_Illegal_Representation_Freezing_Disagreement
            | Status_Illegal_Contract_Flow_Disagreement
            | Status_Illegal_Generic_Substitution_Not_Propagated
            | Status_Illegal_Generic_Body_Replay_Disagreement
            | Status_Illegal_Overload_Profile_Disagreement
            | Status_Illegal_Literal_Operator_Substitution_Disagreement
            | Status_Illegal_Tagged_Interface_Disagreement
            | Status_Illegal_Dispatching_Effect_Join_Missing
            | Status_Illegal_Class_Wide_Conversion_Disagreement
            | Status_Illegal_Concurrent_Shared_State_Disagreement
            | Status_Illegal_Protected_Barrier_Disagreement
            | Status_Illegal_Parallel_Iterator_Disagreement
            | Status_Illegal_Finalization_Abort_Disagreement
            | Status_Illegal_Representation_Consumer_Disagreement
            | Status_Illegal_RM_Coverage_Remediation_Missing
            | Status_Illegal_Balanced_Regression_Missing
            | Status_Illegal_Partial_Evidence_Precision_Lost
            | Status_Illegal_Consumer_Final_Verdict_Conflict
            | Status_Illegal_Diagnostics_Final_Verdict_Disagreement
            | Status_Illegal_Colouring_Final_Verdict_Disagreement
            | Status_Illegal_Outline_Final_Verdict_Disagreement
            | Status_Illegal_Navigation_Final_Verdict_Disagreement
            | Status_Illegal_Hover_Final_Verdict_Disagreement
            | Status_Illegal_Diagnostic_Bridge_Final_Verdict_Disagreement =>
            return Precision.Class_Illegal;
         when Status_Indeterminate_Private_View
            | Status_Indeterminate_Limited_View
            | Status_Indeterminate_Incomplete_View
            | Status_Indeterminate_Generic_Formal_View
            | Status_Indeterminate_Missing_Full_View
            | Status_Indeterminate_Missing_Source_Unit_Evidence
            | Status_Indeterminate_Missing_AST_Evidence
            | Status_Indeterminate_Missing_Type_Evidence
            | Status_Indeterminate_Missing_Profile_Evidence
            | Status_Indeterminate_Missing_Unit_Evidence
            | Status_Indeterminate_Missing_Substitution_Evidence
            | Status_Indeterminate_Missing_Effect_Evidence
            | Status_Indeterminate_Missing_Policy_Evidence
            | Status_Indeterminate_Missing_Consumer_Evidence
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
      if not Row.Coverage_Entry_Updated_To_Covered then
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
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Source_Shaped_Evidence_Missing);
      end if;
      if not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
   end Check_Audit_Gates;

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
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
      end if;
      if Row.Substitution_Fingerprint /= Row.Expected_Substitution_Fingerprint then
         Add_Blocker (Result, Status_Substitution_Fingerprint_Mismatch);
      end if;
      if Row.Effect_Fingerprint /= Row.Expected_Effect_Fingerprint then
         Add_Blocker (Result, Status_Effect_Fingerprint_Mismatch);
      end if;
      if Row.Policy_Fingerprint /= Row.Expected_Policy_Fingerprint then
         Add_Blocker (Result, Status_Policy_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   procedure Check_Indeterminate_Evidence
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Private_View then
         Add_Blocker (Result, Status_Indeterminate_Private_View);
      end if;
      if Row.Limited_View then
         Add_Blocker (Result, Status_Indeterminate_Limited_View);
      end if;
      if Row.Incomplete_View then
         Add_Blocker (Result, Status_Indeterminate_Incomplete_View);
      end if;
      if Row.Generic_Formal_View then
         Add_Blocker (Result, Status_Indeterminate_Generic_Formal_View);
      end if;
      if Row.Missing_Full_View then
         Add_Blocker (Result, Status_Indeterminate_Missing_Full_View);
      end if;
      if Row.Missing_Source_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Source_Unit_Evidence);
      end if;
      if Row.Missing_AST_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_AST_Evidence);
      end if;
      if Row.Missing_Type_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Type_Evidence);
      end if;
      if Row.Missing_Profile_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Profile_Evidence);
      end if;
      if Row.Missing_Unit_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Unit_Evidence);
      end if;
      if Row.Missing_Substitution_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Substitution_Evidence);
      end if;
      if Row.Missing_Effect_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Effect_Evidence);
      end if;
      if Row.Missing_Policy_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Policy_Evidence);
      end if;
      if Row.Missing_Consumer_Evidence then
         Add_Blocker (Result, Status_Indeterminate_Missing_Consumer_Evidence);
      end if;
   end Check_Indeterminate_Evidence;

   procedure Check_Source_Unit_Closure
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Canonical_Closure_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Source_Unit_Canonical_Closure_Failed);
      end if;
      if not Row.Context_Closure_Agrees then
         Add_Blocker (Result, Status_Illegal_Context_Closure_Disagreement);
      end if;
      if not Row.Private_Full_View_Agrees then
         Add_Blocker (Result, Status_Illegal_Private_Full_View_Disagreement);
      end if;
      if not Row.Body_Spec_Conformance_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Body_Spec_Conformance_Disagreement);
      end if;
      if not Row.Elaboration_Closure_Agrees then
         Add_Blocker (Result, Status_Illegal_Elaboration_Closure_Disagreement);
      end if;
      if not Row.Representation_Freezing_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Representation_Freezing_Disagreement);
      end if;
      if not Row.Contract_Flow_Agrees then
         Add_Blocker (Result, Status_Illegal_Contract_Flow_Disagreement);
      end if;
      if not Row.Generic_Substitution_Propagated then
         Add_Blocker
           (Result, Status_Illegal_Generic_Substitution_Not_Propagated);
      end if;
      if not Row.Generic_Body_Replay_Agrees then
         Add_Blocker (Result, Status_Illegal_Generic_Body_Replay_Disagreement);
      end if;
      if not Row.Overload_Profile_Agrees then
         Add_Blocker (Result, Status_Illegal_Overload_Profile_Disagreement);
      end if;
      if not Row.Literal_Operator_Substitution_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Literal_Operator_Substitution_Disagreement);
      end if;
      if not Row.Tagged_Interface_Agrees then
         Add_Blocker (Result, Status_Illegal_Tagged_Interface_Disagreement);
      end if;
      if not Row.Dispatching_Effect_Join_Present then
         Add_Blocker
           (Result, Status_Illegal_Dispatching_Effect_Join_Missing);
      end if;
      if not Row.Class_Wide_Conversion_Agrees then
         Add_Blocker (Result, Status_Illegal_Class_Wide_Conversion_Disagreement);
      end if;
      if not Row.Concurrent_Shared_State_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Concurrent_Shared_State_Disagreement);
      end if;
      if not Row.Protected_Barrier_Agrees then
         Add_Blocker (Result, Status_Illegal_Protected_Barrier_Disagreement);
      end if;
      if not Row.Parallel_Iterator_Agrees then
         Add_Blocker (Result, Status_Illegal_Parallel_Iterator_Disagreement);
      end if;
      if not Row.Finalization_Abort_Agrees then
         Add_Blocker (Result, Status_Illegal_Finalization_Abort_Disagreement);
      end if;
      if not Row.Representation_Consumer_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Representation_Consumer_Disagreement);
      end if;
      if not Row.RM_Coverage_Remediation_Present then
         Add_Blocker (Result,
                      Status_Illegal_RM_Coverage_Remediation_Missing);
      end if;
      if not Row.Balanced_Final_Regression_Evidence then
         Add_Blocker (Result, Status_Illegal_Balanced_Regression_Missing);
      end if;
      if not Row.Partial_Evidence_Precision_Preserved then
         Add_Blocker (Result,
                      Status_Illegal_Partial_Evidence_Precision_Lost);
      end if;
      if Row.Runtime_Check_Final_Verdict then
         if Row.Runtime_Check_Evidence_Preserved then
            Add_Blocker (Result,
                         Status_Runtime_Check_Final_Verdict_Preserved);
         else
            Add_Blocker (Result, Status_Runtime_Check_Evidence_Lost);
         end if;
      end if;
   end Check_Source_Unit_Closure;

   procedure Check_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Consumer_Final_Verdict_Agrees then
         Add_Blocker (Result, Status_Illegal_Consumer_Final_Verdict_Conflict);
      end if;
      if not Row.Diagnostics_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Diagnostics_Final_Verdict_Disagreement);
      end if;
      if not Row.Colouring_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Colouring_Final_Verdict_Disagreement);
      end if;
      if not Row.Outline_Agrees then
         Add_Blocker (Result,
                      Status_Illegal_Outline_Final_Verdict_Disagreement);
      end if;
      if not Row.Navigation_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Navigation_Final_Verdict_Disagreement);
      end if;
      if not Row.Hover_Agrees then
         Add_Blocker (Result, Status_Illegal_Hover_Final_Verdict_Disagreement);
      end if;
      if not Row.Bridge_Agrees then
         Add_Blocker
           (Result, Status_Illegal_Diagnostic_Bridge_Final_Verdict_Disagreement);
      end if;
   end Check_Consumers;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Unit_Kind := Row.Unit_Kind;
      Result.Context := Row.Context;
      Result.Result_Fingerprint :=
        Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Source_Unit_Kind'Pos (Row.Unit_Kind))
        + Natural (Closure_Context_Kind'Pos (Row.Context))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Unit_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Policy_Fingerprint
        + Row.Consumer_Fingerprint;

      Check_Audit_Gates (Row, Result);
      Check_Fingerprints (Row, Result);
      Check_Indeterminate_Evidence (Row, Result);
      Check_Source_Unit_Closure (Row, Result);
      Check_Consumers (Row, Result);

      if Result.Status = Status_Not_Checked then
         case Row.Expected is
            when Precision.Class_Legal =>
               Result.Status := Status_Legal_Source_Unit_Closure;
            when Precision.Class_Legal_With_Runtime_Check =>
               Result.Status := Status_Runtime_Check_Evidence_Lost;
            when Precision.Class_Illegal =>
               Result.Status := Status_Unexpected_Classification;
            when Precision.Class_Indeterminate =>
               Result.Status := Status_Indeterminate;
            when others =>
               Result.Status := Status_Unexpected_Classification;
         end case;
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
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Source_Unit_Semantic_Closure_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Source_Unit_Semantic_Closure then
            Saw_Target_Gap := True;
         end if;
         if not Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap;
   end Source_Unit_Semantic_Closure_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1359;
