package body Editor.Ada_RM_Gap_Burn_Down_Pass1365 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;


   procedure Add_Blocker
     (Result : in out Final_Entry;
      Status : Final_Status) is
   begin
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      else
         Result.Status := Status_Multiple_Blockers;
      end if;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Is_Ready_Status (Status : Final_Status) return Boolean is
   begin
      return Status in Status_Final_Clean
        | Status_Final_Illegal
        | Status_Final_Runtime_Checks
        | Status_Final_Warning_Only
        | Status_Final_Indeterminate
        | Status_Final_Partial
        | Status_Final_Missing_Checker
        | Status_Final_Cancelled
        | Status_Final_Superseded
        | Status_Final_Budget_Exceeded
        | Status_Final_Project_Blocked
        | Status_Final_Recovery_Blocked;
   end Is_Ready_Status;

   function Expected_For_Status
     (Status : Final_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Final_Clean
            | Status_Final_Warning_Only
            | Status_Final_Cancelled
            | Status_Final_Superseded
            | Status_Final_Budget_Exceeded =>
            return Precision.Class_Legal;
         when Status_Final_Runtime_Checks =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Final_Illegal
            | Status_Illegal_Clean_With_Partial_Or_Missing
            | Status_Illegal_Clean_With_Blockers
            | Status_Illegal_Hard_Diagnostic_From_Indeterminate
            | Status_Illegal_Runtime_Check_As_Hard
            | Status_Illegal_Warning_As_Hard
            | Status_Illegal_Stale_Row_Consumed
            | Status_Illegal_Cancelled_Row_Consumed
            | Status_Illegal_Budget_Row_Consumed_As_Current
            | Status_Illegal_Consumer_Verdict_Disagreement
            | Status_Illegal_Build_Diagnostic_Conflated
            | Status_Illegal_Noncanonical_Model_Used
            | Status_Illegal_Unbalanced_Regression_Evidence
            | Status_Illegal_Diagnostic_Order_Unstable
            | Status_Illegal_Blocker_Family_Unnormalized
            | Status_Illegal_Secondary_Evidence_Unstable
            | Status_Illegal_Error_Identity_Churn =>
            return Precision.Class_Illegal;
         when Status_Final_Partial =>
            return Precision.Class_Partial_Coverage;
         when Status_Final_Missing_Checker =>
            return Precision.Class_Missing_Checker;
         when Status_Final_Indeterminate
            | Status_Final_Project_Blocked
            | Status_Final_Recovery_Blocked
            | Status_Missing_RM_Coverage_Evidence
            | Status_Missing_Remediation_Evidence
            | Status_Missing_Consumer_Readiness
            | Status_Missing_Project_Snapshot_Closure
            | Status_Missing_Source_Shaped_Evidence
            | Status_Source_Fingerprint_Mismatch
            | Status_AST_Fingerprint_Mismatch
            | Status_Type_Fingerprint_Mismatch
            | Status_Profile_Fingerprint_Mismatch
            | Status_Unit_Fingerprint_Mismatch
            | Status_Project_Index_Fingerprint_Mismatch
            | Status_Closure_Fingerprint_Mismatch
            | Status_Substitution_Fingerprint_Mismatch
            | Status_Effect_Fingerprint_Mismatch
            | Status_Policy_Fingerprint_Mismatch
            | Status_Recovery_Fingerprint_Mismatch
            | Status_Consumer_Fingerprint_Mismatch
            | Status_Request_Fingerprint_Mismatch
            | Status_Indeterminate =>
            return Precision.Class_Indeterminate;
         when Status_Not_Checked
            | Status_Multiple_Blockers =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   procedure Check_Evidence_Gates
     (Row : Final_Row;
      Result : in out Final_Entry) is
   begin
      if not Row.Source_Shaped_Evidence then
         Add_Blocker (Result, Status_Missing_Source_Shaped_Evidence);
      end if;
      if not Row.RM_Coverage_Evidence then
         Add_Blocker (Result, Status_Missing_RM_Coverage_Evidence);
      end if;
      if not Row.Remediation_Evidence then
         Add_Blocker (Result, Status_Missing_Remediation_Evidence);
      end if;
      if not Row.Consumer_Readiness then
         Add_Blocker (Result, Status_Missing_Consumer_Readiness);
      end if;
      if not Row.Project_Snapshot_Closed then
         Add_Blocker (Result, Status_Missing_Project_Snapshot_Closure);
      end if;
      if not Row.Balanced_Regression_Evidence then
         Add_Blocker (Result, Status_Illegal_Unbalanced_Regression_Evidence);
      end if;
   end Check_Evidence_Gates;

   procedure Check_Final_Classification
     (Row : Final_Row;
      Result : in out Final_Entry) is
   begin
      if Row.Verdict = Verdict_Clean and then Row.Partial_Or_Missing_Remains then
         Add_Blocker (Result, Status_Illegal_Clean_With_Partial_Or_Missing);
      end if;
      if Row.Verdict = Verdict_Clean and then Row.Illegal_Blockers_Remain then
         Add_Blocker (Result, Status_Illegal_Clean_With_Blockers);
      end if;
      if Row.Hard_Diagnostic_From_Indeterminate then
         Add_Blocker (Result, Status_Illegal_Hard_Diagnostic_From_Indeterminate);
      end if;
      if Row.Runtime_Check_Emitted_As_Hard
        or else not Row.Runtime_Check_Evidence_Preserved
      then
         Add_Blocker (Result, Status_Illegal_Runtime_Check_As_Hard);
      end if;
      if Row.Warning_Only_Emitted_As_Hard
        or else not Row.Warning_Only_Evidence_Preserved
      then
         Add_Blocker (Result, Status_Illegal_Warning_As_Hard);
      end if;
      if not Row.Indeterminate_Evidence_Preserved then
         Add_Blocker (Result, Status_Illegal_Hard_Diagnostic_From_Indeterminate);
      end if;
      if Row.Stale_Row_Consumed then
         Add_Blocker (Result, Status_Illegal_Stale_Row_Consumed);
      end if;
      if Row.Cancelled_Row_Consumed then
         Add_Blocker (Result, Status_Illegal_Cancelled_Row_Consumed);
      end if;
      if Row.Budget_Row_Consumed_As_Current then
         Add_Blocker (Result, Status_Illegal_Budget_Row_Consumed_As_Current);
      end if;
   end Check_Final_Classification;

   procedure Check_Consumers_And_Model
     (Row : Final_Row;
      Result : in out Final_Entry) is
   begin
      if not Row.Consumer_Verdict_Agreement then
         Add_Blocker (Result, Status_Illegal_Consumer_Verdict_Disagreement);
      end if;
      if not Row.Build_Diagnostic_Separated then
         Add_Blocker (Result, Status_Illegal_Build_Diagnostic_Conflated);
      end if;
      if not Row.Canonical_Entity_Model
        or else not Row.Canonical_Type_Model
        or else not Row.Canonical_Profile_Model
        or else not Row.Canonical_Unit_Model
        or else not Row.Canonical_Effect_Model
      then
         Add_Blocker (Result, Status_Illegal_Noncanonical_Model_Used);
      end if;
      if not Row.Deterministic_Diagnostic_Order then
         Add_Blocker (Result, Status_Illegal_Diagnostic_Order_Unstable);
      end if;
      if not Row.Blocker_Family_Normalized then
         Add_Blocker (Result, Status_Illegal_Blocker_Family_Unnormalized);
      end if;
      if not Row.Secondary_Evidence_Deterministic then
         Add_Blocker (Result, Status_Illegal_Secondary_Evidence_Unstable);
      end if;
      if not Row.Error_Identity_Preserved then
         Add_Blocker (Result, Status_Illegal_Error_Identity_Churn);
      end if;
   end Check_Consumers_And_Model;

   procedure Check_Fingerprints
     (Row : Final_Row;
      Result : in out Final_Entry) is
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
      if Row.Unit_Fingerprint /= Row.Expected_Unit_Fingerprint then
         Add_Blocker (Result, Status_Unit_Fingerprint_Mismatch);
      end if;
      if Row.Project_Index_Fingerprint /= Row.Expected_Project_Index_Fingerprint then
         Add_Blocker (Result, Status_Project_Index_Fingerprint_Mismatch);
      end if;
      if Row.Closure_Fingerprint /= Row.Expected_Closure_Fingerprint then
         Add_Blocker (Result, Status_Closure_Fingerprint_Mismatch);
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
      if Row.Recovery_Fingerprint /= Row.Expected_Recovery_Fingerprint then
         Add_Blocker (Result, Status_Recovery_Fingerprint_Mismatch);
      end if;
      if Row.Consumer_Fingerprint /= Row.Expected_Consumer_Fingerprint then
         Add_Blocker (Result, Status_Consumer_Fingerprint_Mismatch);
      end if;
      if Row.Request_Fingerprint /= Row.Expected_Request_Fingerprint then
         Add_Blocker (Result, Status_Request_Fingerprint_Mismatch);
      end if;
   end Check_Fingerprints;

   function Fingerprint (Row : Final_Row) return Natural is
   begin
      return Row.Id
        + Natural (Final_Gap'Pos (Row.Gap))
        + Natural (Final_Verdict'Pos (Row.Verdict))
        + Row.Source_Fingerprint
        + Row.AST_Fingerprint
        + Row.Type_Fingerprint
        + Row.Profile_Fingerprint
        + Row.Unit_Fingerprint
        + Row.Project_Index_Fingerprint
        + Row.Closure_Fingerprint
        + Row.Substitution_Fingerprint
        + Row.Effect_Fingerprint
        + Row.Policy_Fingerprint
        + Row.Recovery_Fingerprint
        + Row.Consumer_Fingerprint
        + Row.Request_Fingerprint;
   end Fingerprint;

   function Status_For_Verdict (Verdict : Final_Verdict) return Final_Status is
   begin
      case Verdict is
         when Verdict_Clean => return Status_Final_Clean;
         when Verdict_Illegal => return Status_Final_Illegal;
         when Verdict_Runtime_Checks => return Status_Final_Runtime_Checks;
         when Verdict_Warning_Only => return Status_Final_Warning_Only;
         when Verdict_Indeterminate => return Status_Final_Indeterminate;
         when Verdict_Partial => return Status_Final_Partial;
         when Verdict_Missing_Checker => return Status_Final_Missing_Checker;
         when Verdict_Cancelled => return Status_Final_Cancelled;
         when Verdict_Superseded => return Status_Final_Superseded;
         when Verdict_Budget_Exceeded => return Status_Final_Budget_Exceeded;
         when Verdict_Project_Blocked => return Status_Final_Project_Blocked;
         when Verdict_Recovery_Blocked => return Status_Final_Recovery_Blocked;
         when Verdict_Stale => return Status_Illegal_Stale_Row_Consumed;
         when Verdict_Unknown => return Status_Indeterminate;
      end case;
   end Status_For_Verdict;

   function Evaluate (Row : Final_Row) return Final_Entry is
      Result : Final_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Consumer := Row.Consumer;
      Result.Verdict := Row.Verdict;
      Result.Result_Fingerprint := Fingerprint (Row);

      Check_Evidence_Gates (Row, Result);
      Check_Final_Classification (Row, Result);
      Check_Consumers_And_Model (Row, Result);
      Check_Fingerprints (Row, Result);

      if Result.Status = Status_Not_Checked then
         Result.Status := Status_For_Verdict (Row.Verdict);
      end if;

      return Result;
   end Evaluate;

   procedure Add_Row (Input : in out Final_Input; Row : Final_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Final_Input) return Final_Model is
      Results : Final_Model;
      Item : Final_Entry;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := Evaluate (Row);
         Results.Entries.Append (Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint
           + Natural (Final_Status'Pos (Item.Status))
           + Item.Blocker_Count;

         case Item.Status is
            when Status_Final_Clean => Results.Clean_Count := Results.Clean_Count + 1;
            when Status_Final_Illegal => Results.Illegal_Count := Results.Illegal_Count + 1;
            when Status_Final_Runtime_Checks => Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Status_Final_Warning_Only => Results.Warning_Count := Results.Warning_Count + 1;
            when Status_Final_Indeterminate => Results.Indeterminate_Count := Results.Indeterminate_Count + 1;
            when Status_Final_Partial => Results.Partial_Count := Results.Partial_Count + 1;
            when Status_Final_Missing_Checker => Results.Missing_Checker_Count := Results.Missing_Checker_Count + 1;
            when Status_Final_Cancelled => Results.Cancelled_Count := Results.Cancelled_Count + 1;
            when Status_Final_Superseded => Results.Superseded_Count := Results.Superseded_Count + 1;
            when Status_Final_Budget_Exceeded => Results.Budget_Count := Results.Budget_Count + 1;
            when Status_Final_Project_Blocked => Results.Project_Blocked_Count := Results.Project_Blocked_Count + 1;
            when Status_Final_Recovery_Blocked => Results.Recovery_Blocked_Count := Results.Recovery_Blocked_Count + 1;
            when Status_Illegal_Stale_Row_Consumed => Results.Stale_Count := Results.Stale_Count + 1;
            when others => null;
         end case;
      end loop;
      return Results;
   end Build;

   function Count (Results : Final_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At (Results : Final_Model; Index : Positive) return Final_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For (Results : Final_Model; Id : Natural) return Final_Entry is
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Final_Readiness_Gate_Closed (Results : Final_Model) return Boolean is
   begin
      if Count (Results) = 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if not Is_Ready_Status (Item.Status) or else Item.Blocker_Count /= 0 then
            return False;
         end if;
      end loop;

      return Results.Clean_Count > 0
        and then Results.Illegal_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Warning_Count > 0
        and then Results.Indeterminate_Count > 0
        and then Results.Partial_Count > 0
        and then Results.Missing_Checker_Count > 0
        and then Results.Cancelled_Count > 0
        and then Results.Superseded_Count > 0
        and then Results.Budget_Count > 0
        and then Results.Project_Blocked_Count > 0
        and then Results.Recovery_Blocked_Count > 0;
   end Final_Readiness_Gate_Closed;

end Editor.Ada_RM_Gap_Burn_Down_Pass1365;
