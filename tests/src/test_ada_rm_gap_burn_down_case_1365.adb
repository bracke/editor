with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Pass1365;

package body Test_Ada_RM_Gap_Burn_Down_Case_1365 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1365;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Final_Gap;
   use type Audit.Final_Verdict;
   use type Audit.Final_Status;
   use type Audit.Final_Row;
   use type Audit.Final_Input;
   use type Audit.Final_Entry;
   use type Audit.Final_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   function Base_Row
     (Id : Natural;
      Verdict : Audit.Final_Verdict;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Gap : Audit.Final_Gap := Audit.Gap_Final_Readiness_Release_Gate;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Final_Row is
      Row : Audit.Final_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Coverage := Matrix.Coverage_Covered;
      Row.Remediation_Value := Remediation.State_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Verdict := Verdict;
      Row.Source_File := To_Unbounded_String ("src/final-readiness.adb");
      Row.Blocker_Family := To_Unbounded_String ("RM.P1365.Final_Verdict");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1365");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Final_Model;
      Id : Natural;
      Status : Audit.Final_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Final_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1365 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1365 classification");
   end Expect_Status;

   procedure Test_Final_Readiness_Balanced_Verdicts

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Final_Input;
      Results : Audit.Final_Model;
   begin
      Audit.Add_Row (Input, Base_Row (1, Audit.Verdict_Clean, Precision.Class_Legal));
      Audit.Add_Row
        (Input, Base_Row (2, Audit.Verdict_Illegal, Precision.Class_Illegal,
                          Audit.Gap_Precision_Classification_Closure));
      Audit.Add_Row
        (Input, Base_Row (3, Audit.Verdict_Runtime_Checks,
                          Precision.Class_Legal_With_Runtime_Check));
      Audit.Add_Row
        (Input, Base_Row (4, Audit.Verdict_Warning_Only, Precision.Class_Legal));
      Audit.Add_Row
        (Input, Base_Row (5, Audit.Verdict_Indeterminate,
                          Precision.Class_Indeterminate));
      Audit.Add_Row
        (Input, Base_Row (6, Audit.Verdict_Partial,
                          Precision.Class_Partial_Coverage,
                          Audit.Gap_RM_Coverage_Remediation_Closure));
      Audit.Add_Row
        (Input, Base_Row (7, Audit.Verdict_Missing_Checker,
                          Precision.Class_Missing_Checker,
                          Audit.Gap_RM_Coverage_Remediation_Closure));
      Audit.Add_Row
        (Input, Base_Row (8, Audit.Verdict_Cancelled, Precision.Class_Legal,
                          Audit.Gap_Project_Snapshot_Closure));
      Audit.Add_Row
        (Input, Base_Row (9, Audit.Verdict_Superseded, Precision.Class_Legal,
                          Audit.Gap_Project_Snapshot_Closure));
      Audit.Add_Row
        (Input, Base_Row (10, Audit.Verdict_Budget_Exceeded,
                          Precision.Class_Legal,
                          Audit.Gap_Deterministic_Final_Ordering));
      Audit.Add_Row
        (Input, Base_Row (11, Audit.Verdict_Project_Blocked,
                          Precision.Class_Indeterminate,
                          Audit.Gap_Project_Snapshot_Closure));
      Audit.Add_Row
        (Input, Base_Row (12, Audit.Verdict_Recovery_Blocked,
                          Precision.Class_Indeterminate,
                          Audit.Gap_Project_Snapshot_Closure));

      Results := Audit.Build (Input);

      Assert (Audit.Final_Readiness_Gate_Closed (Results),
              "balanced final readiness gate closes");
      Assert (Results.Clean_Count = 1, "clean count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime check count");
      Assert (Results.Warning_Count = 1, "warning count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");
      Assert (Results.Partial_Count = 1, "partial count");
      Assert (Results.Missing_Checker_Count = 1, "missing checker count");
      Assert (Results.Cancelled_Count = 1, "cancelled count");
      Assert (Results.Superseded_Count = 1, "superseded count");
      Assert (Results.Budget_Count = 1, "budget count");
      Assert (Results.Project_Blocked_Count = 1, "project blocked count");
      Assert (Results.Recovery_Blocked_Count = 1, "recovery blocked count");

      Expect_Status (Results, 1, Audit.Status_Final_Clean, Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Final_Illegal, Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Final_Runtime_Checks,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Final_Warning_Only,
                     Precision.Class_Legal);
      Expect_Status (Results, 5, Audit.Status_Final_Indeterminate,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 6, Audit.Status_Final_Partial,
                     Precision.Class_Partial_Coverage);
      Expect_Status (Results, 7, Audit.Status_Final_Missing_Checker,
                     Precision.Class_Missing_Checker);
   end Test_Final_Readiness_Balanced_Verdicts;

   procedure Test_Final_Verdict_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Final_Input;
      Results : Audit.Final_Model;
      Row : Audit.Final_Row;
   begin
      Row := Base_Row (20, Audit.Verdict_Clean);
      Row.Partial_Or_Missing_Remains := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Audit.Verdict_Clean);
      Row.Illegal_Blockers_Remain := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Audit.Verdict_Indeterminate,
                       Precision.Class_Indeterminate);
      Row.Hard_Diagnostic_From_Indeterminate := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (23, Audit.Verdict_Runtime_Checks,
                       Precision.Class_Legal_With_Runtime_Check);
      Row.Runtime_Check_Emitted_As_Hard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (24, Audit.Verdict_Warning_Only);
      Row.Warning_Only_Emitted_As_Hard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (25, Audit.Verdict_Cancelled);
      Row.Cancelled_Row_Consumed := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (26, Audit.Verdict_Budget_Exceeded);
      Row.Budget_Row_Consumed_As_Current := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (27, Audit.Verdict_Stale, Precision.Class_Indeterminate);
      Row.Stale_Row_Consumed := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20,
                     Audit.Status_Illegal_Clean_With_Partial_Or_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 21, Audit.Status_Illegal_Clean_With_Blockers,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 22, Audit.Status_Illegal_Hard_Diagnostic_From_Indeterminate,
         Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Illegal_Runtime_Check_As_Hard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24, Audit.Status_Illegal_Warning_As_Hard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25, Audit.Status_Illegal_Cancelled_Row_Consumed,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 26, Audit.Status_Illegal_Budget_Row_Consumed_As_Current,
         Precision.Class_Illegal);
      Expect_Status (Results, 27, Audit.Status_Illegal_Stale_Row_Consumed,
                     Precision.Class_Illegal);
   end Test_Final_Verdict_Rejections;

   procedure Test_Consumer_Model_And_Ordering_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Final_Input;
      Results : Audit.Final_Model;
      Row : Audit.Final_Row;
   begin
      Row := Base_Row (30, Audit.Verdict_Illegal, Precision.Class_Illegal,
                       Audit.Gap_Consumer_Readiness_Closure);
      Row.Consumer_Verdict_Agreement := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31, Audit.Verdict_Illegal, Precision.Class_Illegal,
                       Audit.Gap_Consumer_Readiness_Closure,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Build_Diagnostic_Separated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32, Audit.Verdict_Clean);
      Row.Canonical_Type_Model := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33, Audit.Verdict_Clean,
                       Precision.Class_Legal,
                       Audit.Gap_Deterministic_Final_Ordering);
      Row.Deterministic_Diagnostic_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34, Audit.Verdict_Clean,
                       Precision.Class_Legal,
                       Audit.Gap_Deterministic_Final_Ordering);
      Row.Blocker_Family_Normalized := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35, Audit.Verdict_Clean,
                       Precision.Class_Legal,
                       Audit.Gap_Deterministic_Final_Ordering);
      Row.Secondary_Evidence_Deterministic := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36, Audit.Verdict_Clean,
                       Precision.Class_Legal,
                       Audit.Gap_Deterministic_Final_Ordering);
      Row.Error_Identity_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30,
                     Audit.Status_Illegal_Consumer_Verdict_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Build_Diagnostic_Conflated,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Noncanonical_Model_Used,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33,
                     Audit.Status_Illegal_Diagnostic_Order_Unstable,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34,
                     Audit.Status_Illegal_Blocker_Family_Unnormalized,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35,
                     Audit.Status_Illegal_Secondary_Evidence_Unstable,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Error_Identity_Churn,
                     Precision.Class_Illegal);
   end Test_Consumer_Model_And_Ordering_Rejections;

   procedure Test_Fingerprint_And_Evidence_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Final_Input;
      Results : Audit.Final_Model;
      Row : Audit.Final_Row;
   begin
      Row := Base_Row (40, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (41, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.RM_Coverage_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (42, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Remediation_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (43, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Consumer_Readiness := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (44, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Project_Snapshot_Closed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (45, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Balanced_Regression_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (46, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Source_Fingerprint := 1;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (47, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Project_Index_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (48, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Request_Fingerprint := 3;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (49, Audit.Verdict_Project_Blocked,
                       Precision.Class_Indeterminate);
      Row.Recovery_Fingerprint := 4;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40, Audit.Status_Missing_Source_Shaped_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 41, Audit.Status_Missing_RM_Coverage_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 42, Audit.Status_Missing_Remediation_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 43, Audit.Status_Missing_Consumer_Readiness,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 44, Audit.Status_Missing_Project_Snapshot_Closure,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 45,
                     Audit.Status_Illegal_Unbalanced_Regression_Evidence,
                     Precision.Class_Illegal);
      Expect_Status (Results, 46, Audit.Status_Source_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 47,
                     Audit.Status_Project_Index_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 48, Audit.Status_Request_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 49, Audit.Status_Recovery_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Fingerprint_And_Evidence_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Final_Readiness_Balanced_Verdicts'Access,
         "balanced final snapshot verdicts close release readiness gate");
      Register_Routine
        (T, Test_Final_Verdict_Rejections'Access,
         "final verdict rejects clean/stale/cancelled/budget misclassification");
      Register_Routine
        (T, Test_Consumer_Model_And_Ordering_Rejections'Access,
         "consumer, canonical model, and final ordering mismatches are rejected");
      Register_Routine
        (T, Test_Fingerprint_And_Evidence_Rejections'Access,
         "missing evidence and stale fingerprints block final readiness");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1365;
