with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Remaining_Gap_Remediation_Pass1378;

package body Test_Ada_RM_Remaining_Gap_Remediation_Case_1378 is

   package Audit renames Editor.Ada_RM_Remaining_Gap_Remediation_Pass1378;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Release_Readiness;
   use type Audit.Remediated_Gap_Family;
   use type Audit.Exception_Context;
   use type Audit.Exception_Form;
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
      Form : Audit.Exception_Form := Audit.Exception_Finalization_Compatible)
      return Audit.Remediation_Row is
      Row : Audit.Remediation_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Remaining_Exception_Handler_Reraise_Finalization_Edge;
      Row.Family := Matrix.Family_Exceptions_Finalization;
      Row.Owner := Matrix.Slice_Exception_Finalization;
      Row.Previous_Readiness := Inventory.Blocked_By_Partial_RM_Coverage;
      Row.Previous_Remediation := Remediation.State_Partial;
      Row.Target_Remediation := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Expected := Expected;
      Row.Consumer := Consumers.Consumer_Diagnostics;
      Row.Context := Audit.Context_Exception_Propagation;
      Row.Form := Form;
      Row.Source_File := To_Unbounded_String ("src/exception-handler-finalization.adb");
      Row.Concrete_Subrule :=
        To_Unbounded_String
          ("exception handlers, reraise legality, exception propagation, controlled finalization, and task/abort finalization must preserve one canonical exception/finalization result");
      Row.Candidate_Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Remaining_Gap_Remediation_Pass1378");
      Row.Candidate_Pass := To_Unbounded_String ("Pass1378");
      Row.Blocker_Family :=
        To_Unbounded_String ("RM.Exceptions.Finalization.Handler_Reraise_Propagation");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Remediation_Model;
      Id : Natural;
      Status : Audit.Remediation_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Remediation_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1378 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1378 precision classification");
   end Expect_Status;

   procedure Test_Exception_Finalization_Gap_Remediated

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Audit.Add_Row (Input, Base_Row (1, Precision.Class_Legal,
                                      Audit.Exception_Finalization_Compatible));

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Exception_Reraise_Outside_Handler);
      Row.Reraise_Outside_Handler := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Exception_Runtime_Propagation_Check);
      Row.Runtime_Exception_Propagation_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Indeterminate,
                       Audit.Exception_Missing_Handler_Evidence);
      Row.Handler_Evidence_Present := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Gap_Remediated (Results),
              "pass1378 should close the selected exception finalization gap");
      Assert (Results.Remediated_Count = 1, "legal count");
      Assert (Results.Illegal_Count = 1, "illegal count");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check count");
      Assert (Results.Indeterminate_Count = 1, "indeterminate count");

      Expect_Status (Results, 1, Audit.Status_Legal_Exception_Finalization_Agreement,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Illegal_Reraise_Outside_Handler,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Exception_Propagation_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Missing_Handler_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Exception_Finalization_Gap_Remediated;

   procedure Test_Exception_Finalization_Static_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (10);
      Row.Duplicate_Handler_Choice := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (11);
      Row.Unreachable_Handler_Choice := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (12);
      Row.Handler_Kind_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (13);
      Row.Controlled_Finalize_Profile_Mismatch := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (14);
      Row.Finalization_Order_Hazard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (15);
      Row.Task_Abort_Finalization_Hazard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (16);
      Row.Consumer_Surface_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Duplicate_Handler_Choice,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Unreachable_Handler_Choice,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Handler_Kind_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Controlled_Finalize_Profile_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Finalization_Order_Hazard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Task_Abort_Finalization_Hazard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Consumer_Surface_Disagreement,
                     Precision.Class_Illegal);
   end Test_Exception_Finalization_Static_Rejections;

   procedure Test_Runtime_And_Indeterminate_Exception_Finalization

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Remediation_Input;
      Results : Audit.Remediation_Model;
      Row : Audit.Remediation_Row;
   begin
      Row := Base_Row (20, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Exception_Runtime_Propagation_Check);
      Row.Runtime_Exception_Propagation_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (21, Precision.Class_Indeterminate,
                       Audit.Exception_Private_View_Indeterminate);
      Row.Private_Full_View_Available := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (22, Precision.Class_Indeterminate,
                       Audit.Exception_Stale_Finalization_Evidence);
      Row.Stale_Finalization_Evidence := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Runtime_Exception_Propagation_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 21, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 22, Audit.Status_Indeterminate_Stale_Finalization_Evidence,
                     Precision.Class_Indeterminate);
   end Test_Runtime_And_Indeterminate_Exception_Finalization;

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
      Row.Finalization_Fingerprint := 1;
      Row.Expected_Finalization_Fingerprint := 2;
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
      Expect_Status (Results, 36, Audit.Status_Finalization_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Inventory_And_Fingerprint_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Exception_Finalization_Gap_Remediated'Access,
         "exception handler finalization gap remediated");
      Register_Routine
        (T, Test_Exception_Finalization_Static_Rejections'Access,
         "exception finalization static rejections");
      Register_Routine
        (T, Test_Runtime_And_Indeterminate_Exception_Finalization'Access,
         "runtime and indeterminate exception finalization cases");
      Register_Routine
        (T, Test_Inventory_And_Fingerprint_Gates'Access,
         "inventory and fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Remaining_Gap_Remediation_Case_1378;
