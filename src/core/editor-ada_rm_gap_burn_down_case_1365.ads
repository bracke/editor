with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1365 is

   --  Case 1365 is the twenty-third RM gap burn-down case.  It closes the
   --  final semantic readiness gate by collapsing coverage, remediation,
   --  precision, project snapshot, diagnostic, consumer, cancellation, and
   --  budget evidence into one deterministic snapshot-level verdict.  The
   --  gate does not claim a source snapshot is clean while partial, missing,
   --  stale, cancelled, superseded, or budget-exceeded evidence remains.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Final_Gap is
     (Gap_Final_Readiness_Release_Gate,
      Gap_RM_Coverage_Remediation_Closure,
      Gap_Consumer_Readiness_Closure,
      Gap_Precision_Classification_Closure,
      Gap_Project_Snapshot_Closure,
      Gap_Deterministic_Final_Ordering,
      Gap_Unknown);

   type Final_Verdict is
     (Verdict_Clean,
      Verdict_Illegal,
      Verdict_Runtime_Checks,
      Verdict_Warning_Only,
      Verdict_Indeterminate,
      Verdict_Partial,
      Verdict_Missing_Checker,
      Verdict_Cancelled,
      Verdict_Superseded,
      Verdict_Budget_Exceeded,
      Verdict_Project_Blocked,
      Verdict_Recovery_Blocked,
      Verdict_Stale,
      Verdict_Unknown);

   type Final_Status is
     (Status_Not_Checked,
      Status_Final_Clean,
      Status_Final_Illegal,
      Status_Final_Runtime_Checks,
      Status_Final_Warning_Only,
      Status_Final_Indeterminate,
      Status_Final_Partial,
      Status_Final_Missing_Checker,
      Status_Final_Cancelled,
      Status_Final_Superseded,
      Status_Final_Budget_Exceeded,
      Status_Final_Project_Blocked,
      Status_Final_Recovery_Blocked,
      Status_Illegal_Clean_With_Partial_Or_Missing,
      Status_Illegal_Clean_With_Blockers,
      Status_Illegal_Hard_Diagnostic_From_Indeterminate,
      Status_Illegal_Runtime_Check_As_Hard,
      Status_Illegal_Warning_As_Hard,
      Status_Illegal_Stale_Row_Consumed,
      Status_Illegal_Cancelled_Row_Consumed,
      Status_Illegal_Budget_Row_Consumed_As_Current,
      Status_Illegal_Consumer_Verdict_Disagreement,
      Status_Illegal_Build_Diagnostic_Conflated,
      Status_Illegal_Noncanonical_Model_Used,
      Status_Illegal_Unbalanced_Regression_Evidence,
      Status_Illegal_Diagnostic_Order_Unstable,
      Status_Illegal_Blocker_Family_Unnormalized,
      Status_Illegal_Secondary_Evidence_Unstable,
      Status_Illegal_Error_Identity_Churn,
      Status_Missing_RM_Coverage_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Consumer_Readiness,
      Status_Missing_Project_Snapshot_Closure,
      Status_Missing_Source_Shaped_Evidence,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Project_Index_Fingerprint_Mismatch,
      Status_Closure_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Recovery_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Request_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Final_Row is record
      Id : Natural := 0;
      Gap : Final_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Coverage : Coverage_Level := Matrix.Coverage_Unknown;
      Remediation_Value : Remediation_State := Remediation.State_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Verdict : Final_Verdict := Verdict_Unknown;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;

      Source_Shaped_Evidence : Boolean := True;
      RM_Coverage_Evidence : Boolean := True;
      Remediation_Evidence : Boolean := True;
      Consumer_Readiness : Boolean := True;
      Project_Snapshot_Closed : Boolean := True;
      Balanced_Regression_Evidence : Boolean := True;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Warning_Only_Evidence_Preserved : Boolean := True;
      Indeterminate_Evidence_Preserved : Boolean := True;
      Canonical_Entity_Model : Boolean := True;
      Canonical_Type_Model : Boolean := True;
      Canonical_Profile_Model : Boolean := True;
      Canonical_Unit_Model : Boolean := True;
      Canonical_Effect_Model : Boolean := True;
      Consumer_Verdict_Agreement : Boolean := True;
      Build_Diagnostic_Separated : Boolean := True;
      Deterministic_Diagnostic_Order : Boolean := True;
      Blocker_Family_Normalized : Boolean := True;
      Secondary_Evidence_Deterministic : Boolean := True;
      Error_Identity_Preserved : Boolean := True;

      Partial_Or_Missing_Remains : Boolean := False;
      Illegal_Blockers_Remain : Boolean := False;
      Hard_Diagnostic_From_Indeterminate : Boolean := False;
      Runtime_Check_Emitted_As_Hard : Boolean := False;
      Warning_Only_Emitted_As_Hard : Boolean := False;
      Stale_Row_Consumed : Boolean := False;
      Cancelled_Row_Consumed : Boolean := False;
      Budget_Row_Consumed_As_Current : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Project_Index_Fingerprint : Natural := 0;
      Expected_Project_Index_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
      Recovery_Fingerprint : Natural := 0;
      Expected_Recovery_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
      Request_Fingerprint : Natural := 0;
      Expected_Request_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Final_Row);

   type Final_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Final_Entry is record
      Id : Natural := 0;
      Gap : Final_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Verdict : Final_Verdict := Verdict_Unknown;
      Status : Final_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Final_Entry);

   type Final_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Clean_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Warning_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Partial_Count : Natural := 0;
      Missing_Checker_Count : Natural := 0;
      Cancelled_Count : Natural := 0;
      Superseded_Count : Natural := 0;
      Budget_Count : Natural := 0;
      Project_Blocked_Count : Natural := 0;
      Recovery_Blocked_Count : Natural := 0;
      Stale_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Final_Input; Row : Final_Row);
   function Build (Input : Final_Input) return Final_Model;
   function Count (Results : Final_Model) return Natural;
   function Result_At (Results : Final_Model; Index : Positive) return Final_Entry;
   function Result_For (Results : Final_Model; Id : Natural) return Final_Entry;
   function Expected_For_Status (Status : Final_Status) return Precision_Classification;
   function Final_Readiness_Gate_Closed (Results : Final_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1365;
