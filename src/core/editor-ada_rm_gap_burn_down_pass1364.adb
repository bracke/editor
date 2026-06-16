package body Editor.Ada_RM_Gap_Burn_Down_Pass1364 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Blocker
     (Result : in out Burn_Down_Entry;
      Status : Burn_Down_Status) is
   begin
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      else
         Result.Status := Status_Multiple_Blockers;
      end if;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean is
   begin
      return Status in Status_Legal_Normalized_Diagnostic
        | Status_Legal_Runtime_Check_Surface
        | Status_Legal_Warning_Only_Surface
        | Status_Legal_Indeterminate_Surface
        | Status_Legal_Deduplicated_Ordered
        | Status_Legal_Incrementally_Stable;
   end Is_Valid_Status;

   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Legal_Normalized_Diagnostic
            | Status_Legal_Deduplicated_Ordered
            | Status_Legal_Incrementally_Stable =>
            return Precision.Class_Legal;
         when Status_Legal_Runtime_Check_Surface =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Legal_Warning_Only_Surface =>
            return Precision.Class_Legal;
         when Status_Legal_Indeterminate_Surface
            | Status_Missing_Remediation_Evidence
            | Status_Missing_Matrix_Coverage
            | Status_Missing_Implementing_Package
            | Status_No_New_Legality_Rule
            | Status_Coverage_Not_Updated_To_Covered
            | Status_Regression_Corpus_Not_Balanced
            | Status_Semantic_Result_Unconsumed
            | Status_Consumer_Not_Reached
            | Status_Source_Shaped_Evidence_Missing
            | Status_Unstable_Blocker_Family
            | Status_Diagnostic_Row_Missing
            | Status_Smallest_Source_Span_Missing
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Project_Index_Fingerprint_Mismatch
            | Status_Closure_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Request_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Illegal_Duplicate_Canonical_Diagnostic
            | Status_Illegal_Duplicate_Blocker_Spelling
            | Status_Illegal_Generic_Fallback_Blocker
            | Status_Illegal_Precise_Blocker_Missing
            | Status_Illegal_Hard_Diagnostic_From_Indeterminate
            | Status_Illegal_Runtime_Check_Emitted_As_Hard
            | Status_Illegal_Warning_Only_Emitted_As_Hard
            | Status_Illegal_Whole_Declaration_Span_Used
            | Status_Illegal_Cross_Unit_Evidence_Span_Missing
            | Status_Illegal_Recovered_Syntax_Complete_Span_Pretended
            | Status_Illegal_Nondeterministic_Diagnostic_Order
            | Status_Illegal_Primary_Secondary_Order_Inverted
            | Status_Illegal_Consumer_Reclassified_State
            | Status_Illegal_Build_Diagnostic_Conflated
            | Status_Illegal_Unchanged_Error_Blocker_Churn
            | Status_Illegal_Source_Span_Drift
            | Status_Illegal_Stale_Diagnostic_Reused
            | Status_Illegal_Stale_Consumer_State_Reused =>
            return Precision.Class_Illegal;
         when Status_Not_Checked
            | Status_Gap_Burned_Down
            | Status_Unexpected_Classification
            | Status_Multiple_Blockers =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Check_Audit_Gates
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
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
      if not Row.Stable_Blocker_Family then
         Add_Blocker (Result, Status_Unstable_Blocker_Family);
      end if;
      if not Row.Diagnostic_Row_Present then
         Add_Blocker (Result, Status_Diagnostic_Row_Missing);
      end if;
   end Check_Audit_Gates;

   procedure Check_Blocker_Normalization
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Duplicate_Canonical_Diagnostic then
         Add_Blocker (Result, Status_Illegal_Duplicate_Canonical_Diagnostic);
      end if;
      if Row.Duplicate_Blocker_Spelling
        or else Row.Blocker = Blocker_Duplicate_Spelling
      then
         Add_Blocker (Result, Status_Illegal_Duplicate_Blocker_Spelling);
      end if;
      if Row.Generic_Fallback_Used_When_Precise_Exists
        or else Row.Blocker = Blocker_Generic_Fallback
      then
         Add_Blocker (Result, Status_Illegal_Generic_Fallback_Blocker);
      end if;
      if Row.Precise_Blocker_Available and then not Row.Precise_Blocker_Used then
         Add_Blocker (Result, Status_Illegal_Precise_Blocker_Missing);
      end if;
      if Row.Hard_Diagnostic_From_Indeterminate then
         Add_Blocker (Result, Status_Illegal_Hard_Diagnostic_From_Indeterminate);
      end if;
      if Row.Runtime_Check_Emitted_As_Hard then
         Add_Blocker (Result, Status_Illegal_Runtime_Check_Emitted_As_Hard);
      end if;
      if Row.Warning_Only_Emitted_As_Hard then
         Add_Blocker (Result, Status_Illegal_Warning_Only_Emitted_As_Hard);
      end if;
   end Check_Blocker_Normalization;

   procedure Check_Source_Span
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if Row.Smallest_Source_Span_Available and then not Row.Smallest_Source_Span_Used then
         Add_Blocker (Result, Status_Smallest_Source_Span_Missing);
      end if;
      if Row.Span = Span_Whole_Declaration
        and then Row.Smallest_Source_Span_Available
      then
         Add_Blocker (Result, Status_Illegal_Whole_Declaration_Span_Used);
      end if;
      if Row.Diagnostic_Kind in Role_Cross_Unit_Local_Reference
        | Role_Cross_Unit_Target_Evidence
        and then not Row.Cross_Unit_Target_Span_Preserved
      then
         Add_Blocker (Result, Status_Illegal_Cross_Unit_Evidence_Span_Missing);
      end if;
      if Row.Span = Span_Recovered_Partial
        and then Row.Recovered_Syntax_Has_Complete_Span
      then
         Add_Blocker
           (Result, Status_Illegal_Recovered_Syntax_Complete_Span_Pretended);
      end if;
   end Check_Source_Span;

   procedure Check_Ordering_And_Consumers
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
      if not Row.Duplicate_Deduplicated then
         Add_Blocker (Result, Status_Illegal_Duplicate_Canonical_Diagnostic);
      end if;
      if not Row.Deterministic_Diagnostic_Order then
         Add_Blocker (Result, Status_Illegal_Nondeterministic_Diagnostic_Order);
      end if;
      if not Row.Primary_Before_Secondary then
         Add_Blocker (Result, Status_Illegal_Primary_Secondary_Order_Inverted);
      end if;
      if not Row.Consumer_State_Consistent or else Row.Consumer_Reclassified_State then
         Add_Blocker (Result, Status_Illegal_Consumer_Reclassified_State);
      end if;
      if Row.Build_Diagnostic_Conflated then
         Add_Blocker (Result, Status_Illegal_Build_Diagnostic_Conflated);
      end if;
      if not Row.Unchanged_Error_Blocker_Identity_Preserved then
         Add_Blocker (Result, Status_Illegal_Unchanged_Error_Blocker_Churn);
      end if;
      if not Row.Source_Span_Moved_Deterministically then
         Add_Blocker (Result, Status_Illegal_Source_Span_Drift);
      end if;
      if Row.Stale_Diagnostic_Reused then
         Add_Blocker (Result, Status_Illegal_Stale_Diagnostic_Reused);
      end if;
      if Row.Stale_Consumer_State_Reused then
         Add_Blocker (Result, Status_Illegal_Stale_Consumer_State_Reused);
      end if;
   end Check_Ordering_And_Consumers;

   procedure Check_Fingerprints
     (Row : Burn_Down_Row;
      Result : in out Burn_Down_Entry) is
   begin
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
      if Row.Project_Index_Fingerprint /= Row.Expected_Project_Index_Fingerprint then
         Add_Blocker (Result, Status_Project_Index_Fingerprint_Mismatch);
      end if;
      if Row.Closure_Fingerprint /= Row.Expected_Closure_Fingerprint then
         Add_Blocker (Result, Status_Closure_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
      if Row.Request_Fingerprint /= Row.Expected_Request_Fingerprint then
         Add_Blocker (Result, Status_Request_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Base_Fingerprint (Row : Burn_Down_Row) return Natural is
   begin
      return Row.Id
        + Natural (Burn_Down_Gap'Pos (Row.Gap))
        + Natural (Span_Kind'Pos (Row.Span))
        + Natural (Blocker_Precision'Pos (Row.Blocker))
        + Natural (Diagnostic_Role'Pos (Row.Diagnostic_Kind))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Project_Index_Fingerprint
        + Row.Closure_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Request_Fingerprint;
   end Base_Fingerprint;

   function Evaluate (Row : Burn_Down_Row) return Burn_Down_Entry is
      Result : Burn_Down_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Owner := Row.Owner;
      Result.Consumer := Row.Consumer;
      Result.Expected := Row.Expected;
      Result.Span := Row.Span;
      Result.Blocker := Row.Blocker;
      Result.Diagnostic_Kind := Row.Diagnostic_Kind;
      Result.Result_Fingerprint := Base_Fingerprint (Row);

      Check_Audit_Gates (Row, Result);
      Check_Blocker_Normalization (Row, Result);
      Check_Source_Span (Row, Result);
      Check_Ordering_And_Consumers (Row, Result);
      Check_Fingerprints (Row, Result);

      if Result.Status = Status_Not_Checked then
         case Row.Expected is
            when Precision.Class_Legal =>
               if Row.Gap = Gap_Diagnostic_Deduplication_Ordering then
                  Result.Status := Status_Legal_Deduplicated_Ordered;
               elsif Row.Gap = Gap_Incremental_Diagnostic_Stability then
                  Result.Status := Status_Legal_Incrementally_Stable;
               else
                  Result.Status := Status_Legal_Normalized_Diagnostic;
               end if;
            when Precision.Class_Legal_With_Runtime_Check =>
               Result.Status := Status_Legal_Runtime_Check_Surface;
            when Precision.Class_Indeterminate
               | Precision.Class_Partial_Coverage
               | Precision.Class_Missing_Checker =>
               Result.Status := Status_Legal_Indeterminate_Surface;
            when Precision.Class_Illegal =>
               if Row.Blocker = Blocker_Warning_Only then
                  Result.Status := Status_Legal_Warning_Only_Surface;
               else
                  Result.Status := Status_Legal_Normalized_Diagnostic;
               end if;
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

         case Item.Status is
            when Status_Legal_Normalized_Diagnostic =>
               Results.Normalized_Count := Results.Normalized_Count + 1;
            when Status_Legal_Runtime_Check_Surface =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Status_Legal_Warning_Only_Surface =>
               Results.Warning_Only_Count := Results.Warning_Only_Count + 1;
            when Status_Legal_Indeterminate_Surface =>
               Results.Indeterminate_Surface_Count :=
                 Results.Indeterminate_Surface_Count + 1;
            when Status_Legal_Deduplicated_Ordered =>
               Results.Deduplicated_Ordering_Count :=
                 Results.Deduplicated_Ordering_Count + 1;
            when Status_Legal_Incrementally_Stable =>
               Results.Incremental_Stability_Count :=
                 Results.Incremental_Stability_Count + 1;
            when others =>
               null;
         end case;

         Classification := Expected_For_Status (Item.Status);
         case Classification is
            when Precision.Class_Illegal =>
               Results.Illegal_Count := Results.Illegal_Count + 1;
            when Precision.Class_Indeterminate =>
               Results.Blocked_Count := Results.Blocked_Count + 1;
            when others =>
               null;
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

   function Diagnostic_Blocker_Source_Span_Gap_Closed
     (Results : Burn_Down_Model) return Boolean is
      Saw_Target_Gap : Boolean := False;
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if Item.Gap = Gap_Diagnostic_Blocker_Source_Span_Closure then
            Saw_Target_Gap := True;
         end if;
         if Item.Blocker_Count /= 0 and then Is_Valid_Status (Item.Status) then
            return False;
         end if;
      end loop;

      return Saw_Target_Gap
        and then Results.Normalized_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Warning_Only_Count > 0
        and then Results.Indeterminate_Surface_Count > 0
        and then Results.Deduplicated_Ordering_Count > 0
        and then Results.Incremental_Stability_Count > 0
        and then Results.Consumer_Count > 0;
   end Diagnostic_Blocker_Source_Span_Gap_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1364;
