with Ada.Strings.Unbounded;

package body Editor.Ada_RM_Gap_Burn_Down_Pass1366 is

   pragma Suppress (Overflow_Check);
   use type Remediation.Remediation_State;
   use type Matrix.Coverage_Level;
   use type Precision.Precision_Classification;
   use type Consumers.Semantic_Consumer;
   use type Matrix.RM_Family;
   use type Matrix.Implementing_Slice;
   use type Final_Gate.Final_Verdict;


   use Ada.Strings.Unbounded;

   procedure Add_Blocker
     (Result : in out Extraction_Entry;
      Status : Extraction_Status) is
   begin
      if Result.Status = Status_Not_Checked then
         Result.Status := Status;
      else
         Result.Status := Status_Multiple_Blockers;
      end if;
      Result.Blocker_Count := Result.Blocker_Count + 1;
   end Add_Blocker;

   function Expected_For_Status
     (Status : Extraction_Status) return Precision_Classification is
   begin
      case Status is
         when Status_Ready
            | Status_Ready_With_Warnings =>
            return Precision.Class_Legal;
         when Status_Ready_With_Runtime_Checks =>
            return Precision.Class_Legal_With_Runtime_Check;
         when Status_Missing_Checker_Actionable =>
            return Precision.Class_Missing_Checker;
         when Status_Partial_Coverage_Actionable =>
            return Precision.Class_Partial_Coverage;
         when Status_Evidence_Blocker_Extracted
            | Status_Project_Blocker_Extracted
            | Status_Consumer_Disagreement_Actionable
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
         when Status_Vague_Partial_Row
            | Status_Missing_Subrule_Name
            | Status_Missing_Candidate_Owner
            | Status_Missing_RM_Family_Mapping
            | Status_Orphan_Missing_Checker
            | Status_Indeterminate_Misclassified_As_RM_Gap
            | Status_Stale_State_Counted_As_RM_Gap
            | Status_Cancelled_State_Counted_As_RM_Gap
            | Status_Budget_State_Counted_As_RM_Gap
            | Status_Consumer_Gap_Hidden
            | Status_Final_Clean_With_Remaining_Gaps
            | Status_Non_Source_Shaped_Report
            | Status_Nondeterministic_Report =>
            return Precision.Class_Illegal;
         when Status_Not_Checked
            | Status_Multiple_Blockers =>
            return Precision.Class_Unknown;
      end case;
   end Expected_For_Status;

   function Is_Actionable_Status (Status : Extraction_Status) return Boolean is
   begin
      return Status in Status_Ready
        | Status_Ready_With_Runtime_Checks
        | Status_Ready_With_Warnings
        | Status_Evidence_Blocker_Extracted
        | Status_Project_Blocker_Extracted
        | Status_Missing_Checker_Actionable
        | Status_Partial_Coverage_Actionable
        | Status_Consumer_Disagreement_Actionable;
   end Is_Actionable_Status;

   procedure Check_Report_Shape
     (Row : Extraction_Row;
      Result : in out Extraction_Entry) is
   begin
      if not Row.Source_Shaped_Report then
         Add_Blocker (Result, Status_Non_Source_Shaped_Report);
      end if;
      if not Row.Deterministic_Report then
         Add_Blocker (Result, Status_Nondeterministic_Report);
      end if;
      if not Row.Maps_To_RM_Family or else Row.Family = Matrix.Family_Unknown then
         Add_Blocker (Result, Status_Missing_RM_Family_Mapping);
      end if;
   end Check_Report_Shape;

   procedure Check_Gap_Ownership
     (Row : Extraction_Row;
      Result : in out Extraction_Entry) is
   begin
      if Row.Gap = Gap_Remaining_Partial_Coverage then
         if Row.Remediation_Value /= Remediation.State_Partial
           or else Row.Coverage /= Matrix.Coverage_Partial
           or else not Row.Concrete_Subrules_Named
           or else Length (Row.Missing_Subrule) = 0
         then
            Add_Blocker (Result, Status_Vague_Partial_Row);
         end if;
      end if;

      if Row.Gap = Gap_Remaining_Partial_Coverage
        and then not Row.Concrete_Subrules_Named
      then
         Add_Blocker (Result, Status_Missing_Subrule_Name);
      end if;

      if Row.Gap = Gap_Remaining_Missing_Checker then
         if Row.Remediation_Value /= Remediation.State_Missing
           or else Row.Coverage /= Matrix.Coverage_None
           or else not Row.Missing_Checker_Owned
         then
            Add_Blocker (Result, Status_Orphan_Missing_Checker);
         end if;
      end if;

      if Row.Gap in Gap_Remaining_Partial_Coverage | Gap_Remaining_Missing_Checker then
         if not Row.Candidate_Owner_Named
           or else Row.Owner = Matrix.Slice_Unknown
           or else Length (Row.Candidate_Implementing_Package) = 0
           or else Length (Row.Candidate_Pass) = 0
         then
            Add_Blocker (Result, Status_Missing_Candidate_Owner);
         end if;
      end if;
   end Check_Gap_Ownership;

   procedure Check_Evidence_Separation
     (Row : Extraction_Row;
      Result : in out Extraction_Entry) is
   begin
      if Row.Gap = Gap_Remaining_Indeterminate_Evidence then
         if not Row.Indeterminate_Is_Evidence_Blocker
           or else not Row.Evidence_Blocker_Not_RM_Gap
         then
            Add_Blocker (Result, Status_Indeterminate_Misclassified_As_RM_Gap);
         end if;
      end if;

      if not Row.Stale_Not_Counted_As_RM_Gap
        or else Row.Verdict = Final_Gate.Verdict_Stale
      then
         Add_Blocker (Result, Status_Stale_State_Counted_As_RM_Gap);
      end if;
      if not Row.Cancelled_Not_Counted_As_RM_Gap
        or else Row.Verdict = Final_Gate.Verdict_Cancelled
      then
         Add_Blocker (Result, Status_Cancelled_State_Counted_As_RM_Gap);
      end if;
      if not Row.Budget_Not_Counted_As_RM_Gap
        or else Row.Verdict = Final_Gate.Verdict_Budget_Exceeded
      then
         Add_Blocker (Result, Status_Budget_State_Counted_As_RM_Gap);
      end if;
   end Check_Evidence_Separation;

   procedure Check_Consumer_And_Final_State
     (Row : Extraction_Row;
      Result : in out Extraction_Entry) is
   begin
      if Row.Gap = Gap_Remaining_Consumer_Surfacing
        and then not Row.Consumer_Gap_Exposed
      then
         Add_Blocker (Result, Status_Consumer_Gap_Hidden);
      end if;

      if Row.Final_Readiness_Marked_Clean
        and then Row.Remaining_Partial_Or_Missing
      then
         Add_Blocker (Result, Status_Final_Clean_With_Remaining_Gaps);
      end if;
   end Check_Consumer_And_Final_State;

   procedure Check_Fingerprints
     (Row : Extraction_Row;
      Result : in out Extraction_Entry) is
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

   function Status_For_Readiness
     (Readiness : Release_Readiness) return Extraction_Status is
   begin
      case Readiness is
         when Ready => return Status_Ready;
         when Ready_With_Runtime_Checks => return Status_Ready_With_Runtime_Checks;
         when Ready_With_Warnings => return Status_Ready_With_Warnings;
         when Blocked_By_Evidence => return Status_Evidence_Blocker_Extracted;
         when Blocked_By_Project_State => return Status_Project_Blocker_Extracted;
         when Blocked_By_Missing_RM_Checker => return Status_Missing_Checker_Actionable;
         when Blocked_By_Partial_RM_Coverage => return Status_Partial_Coverage_Actionable;
         when Blocked_By_Consumer_Disagreement => return Status_Consumer_Disagreement_Actionable;
         when Readiness_Unknown => return Status_Indeterminate;
      end case;
   end Status_For_Readiness;

   function Fingerprint (Row : Extraction_Row) return Natural is
   begin
      return Row.Id
        + Natural (Extraction_Gap'Pos (Row.Gap))
        + Natural (Release_Readiness'Pos (Row.Readiness))
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

   function Evaluate (Row : Extraction_Row) return Extraction_Entry is
      Result : Extraction_Entry;
   begin
      Result.Id := Row.Id;
      Result.Gap := Row.Gap;
      Result.Family := Row.Family;
      Result.Readiness := Row.Readiness;
      Result.Result_Fingerprint := Fingerprint (Row);

      Check_Report_Shape (Row, Result);
      Check_Gap_Ownership (Row, Result);
      Check_Evidence_Separation (Row, Result);
      Check_Consumer_And_Final_State (Row, Result);
      Check_Fingerprints (Row, Result);

      if Result.Status = Status_Not_Checked then
         Result.Status := Status_For_Readiness (Row.Readiness);
      end if;

      return Result;
   end Evaluate;

   procedure Add_Row (Input : in out Extraction_Input; Row : Extraction_Row) is
   begin
      Input.Rows.Append (Row);
   end Add_Row;

   function Build (Input : Extraction_Input) return Extraction_Model is
      Results : Extraction_Model;
      Item : Extraction_Entry;
   begin
      Results.Total_Rows := Natural (Input.Rows.Length);
      for Row of Input.Rows loop
         Item := Evaluate (Row);
         Results.Entries.Append (Item);
         Results.Audit_Fingerprint := Results.Audit_Fingerprint
           + Item.Result_Fingerprint
           + Natural (Extraction_Status'Pos (Item.Status))
           + Item.Blocker_Count;

         case Item.Status is
            when Status_Ready => Results.Ready_Count := Results.Ready_Count + 1;
            when Status_Ready_With_Runtime_Checks =>
               Results.Runtime_Check_Count := Results.Runtime_Check_Count + 1;
            when Status_Ready_With_Warnings =>
               Results.Warning_Count := Results.Warning_Count + 1;
            when Status_Evidence_Blocker_Extracted =>
               Results.Evidence_Blocked_Count := Results.Evidence_Blocked_Count + 1;
            when Status_Project_Blocker_Extracted =>
               Results.Project_Blocked_Count := Results.Project_Blocked_Count + 1;
            when Status_Missing_Checker_Actionable =>
               Results.Missing_Checker_Count := Results.Missing_Checker_Count + 1;
            when Status_Partial_Coverage_Actionable =>
               Results.Partial_Coverage_Count := Results.Partial_Coverage_Count + 1;
            when Status_Consumer_Disagreement_Actionable =>
               Results.Consumer_Disagreement_Count :=
                 Results.Consumer_Disagreement_Count + 1;
            when others =>
               Results.Invalid_Count := Results.Invalid_Count + 1;
         end case;
      end loop;
      return Results;
   end Build;

   function Count (Results : Extraction_Model) return Natural is
   begin
      return Natural (Results.Entries.Length);
   end Count;

   function Result_At
     (Results : Extraction_Model;
      Index : Positive) return Extraction_Entry is
   begin
      return Results.Entries.Element (Index - 1);
   end Result_At;

   function Result_For
     (Results : Extraction_Model;
      Id : Natural) return Extraction_Entry is
   begin
      for Item of Results.Entries loop
         if Item.Id = Id then
            return Item;
         end if;
      end loop;
      return (others => <>);
   end Result_For;

   function Remaining_Gap_Inventory_Extracted
     (Results : Extraction_Model) return Boolean is
   begin
      if Count (Results) = 0 or else Results.Invalid_Count /= 0 then
         return False;
      end if;

      for Item of Results.Entries loop
         if not Is_Actionable_Status (Item.Status)
           or else Item.Blocker_Count /= 0
         then
            return False;
         end if;
      end loop;

      return Results.Ready_Count > 0
        and then Results.Runtime_Check_Count > 0
        and then Results.Warning_Count > 0
        and then Results.Evidence_Blocked_Count > 0
        and then Results.Project_Blocked_Count > 0
        and then Results.Missing_Checker_Count > 0
        and then Results.Partial_Coverage_Count > 0
        and then Results.Consumer_Disagreement_Count > 0;
   end Remaining_Gap_Inventory_Extracted;

end Editor.Ada_RM_Gap_Burn_Down_Pass1366;
