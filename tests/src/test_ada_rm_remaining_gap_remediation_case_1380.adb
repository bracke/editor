with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1380;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1380 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1380;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Tasking_Context;
   use type Audit.Tasking_Form;
   use type Audit.Remediation_Status;
   use type Audit.Remediation_Row;
   use type Audit.Remediation_Input;
   use type Audit.Remediation_Entry;
   use type Audit.Remediation_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;
   package Inventory renames Audit.Inventory;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Remaining_Gap_Remediation");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification := Precision.Class_Legal;
      Form : Audit.Tasking_Form := Audit.Tasking_Protected_Requeue_Select_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Protected_Requeue_Select_Finalization_Edge;
      Row.Family := Matrix.Family_Tasking_Protected_Synchronized;
      Row.Owner := Matrix.Slice_Tasking_Protected;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_Requeue;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/protected-requeue-select-finalization.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("protected entry requeue, select coverage, termination, abort/finalization, runtime queue checks, and consumers must preserve one canonical tasking result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1380");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1380");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Tasking.Protected.Requeue.Select.Finalization");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1380 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1380 precision classification");
   end Expect_Status;

   procedure Test_Tasking_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Tasking_Protected_Requeue_Select_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Tasking_Illegal_Requeue_Target_Profile);
      Row.Requeue_Target_Profile_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Tasking_Runtime_Entry_Queue_Check);
      Row.Runtime_Entry_Queue_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Tasking_Missing_Effect_Evidence);
      Row.Effect_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1380 should close the selected protected/requeue/select gap");
      Assert (Results.Remediated_Count >= 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Tasking_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Requeue_Target_Profile,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Entry_Queue_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Effect_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Tasking_Gap_Remediated;

   procedure Test_Static_Tasking_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Protected_Barrier_Side_Effect := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Select_Coverage_Missing := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Terminate_Dependency_Unsafe := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Abort_Finalization_Hazard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Protected_Barrier_Side_Effect,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Select_Coverage,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Terminate_Dependency,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Abort_Finalization_Hazard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_Static_Tasking_Rejections;

   procedure Test_Runtime_And_Indeterminate_Tasking

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Tasking_Runtime_Entry_Queue_Check);
      Row.Runtime_Entry_Queue_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Indeterminate,
                       Audit.Tasking_Private_View_Indeterminate);
      Row.Private_Full_View_Available := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Tasking_Stale_Effect_Evidence);
      Row.Stale_Effect_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Runtime_Entry_Queue_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 21, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Indeterminate_Stale_Effect_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Runtime_And_Indeterminate_Tasking;

   procedure Test_Inventory_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (30);
      Row.Inventory_Row_From_Pass1366 := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (31);
      Row.Named_Concrete_Subrule := False;
      Row.Concrete_Subrule := Null_Unbounded_String;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (32);
      Row.Coverage_Promoted_To_Covered := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (33);
      Row.Final_Gate_No_Longer_Reports_Gap := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (34);
      Row.Runtime_Check_Test_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (35);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (36);
      Row.Effect_Fingerprint := 1;
      Row.Expected_Effect_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Missing_Pass1366_Inventory_Row,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 31, Audit.Status_Missing_Concrete_Subrule_Name,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 32, Audit.Status_Coverage_Not_Promoted,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 33, Audit.Status_Final_Gate_Still_Reports_Gap,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 34, Audit.Status_Regression_Corpus_Not_Balanced,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 35, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 36, Audit.Status_Effect_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Tasking_Gap_Remediated'Access,
         "protected requeue/select/finalization gap remediated");
      Register_Routine
        (T, Test_Static_Tasking_Rejections'Access,
         "static tasking rejections");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Tasking'Access,
         "runtime and indeterminate tasking cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1380;
